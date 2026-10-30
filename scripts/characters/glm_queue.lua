-- Normal GLM: Number in Queue. Unique clears advance the Queue; at three, DROP
-- redeems an Access Pass for the next new hostile rooms. No real purchases or
-- real-time waiting. Saved per player; the room bonus ends on room exit.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local GLM = {}

local QUEUE_MAX = 3
local PASS_ROOMS, BIRTHRIGHT_ROOMS = 2, 3
local BONUS = 1.2

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, queue=0, pass=0, awards={}, seen={}}
end
local function keys(t)
    if type(t) ~= "table" then return false end
    for k, v in pairs(t) do
        if type(k) ~= "string" or v ~= true then return false end
    end
    return true
end
-- pass: new hostile rooms left on the Access Pass; activeRoom: the room it is boosting now.
local function valid(s)
    return type(s) == "table" and s.version == 1 and integer(s.queue, 0, QUEUE_MAX)
        and integer(s.pass, 0, BIRTHRIGHT_ROOMS) and keys(s.awards) and keys(s.seen)
        and (s.activeRoom == nil or type(s.activeRoom) == "string")
end

function GLM:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("GLM-chan", false)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isGLM(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.glmQueue) ~= "table" then Risk.state.glmQueue = {} end
        return Risk.state.glmQueue
    end
    local function roomKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..tostring(level:GetCurrentRoomDesc().SpawnSeed)
    end
    local function floorKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..level:GetStage()..":"..level:GetStageType()
    end
    local function refresh(p)
        p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        p:EvaluateItems()
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if isGLM(p) then
                local b = bindings[pointer]
                local sameOwner = b and b.seed == p.InitSeed
                -- Read the old slot before rebuilding the map: cyclic moves
                -- retain this owner's saved progress and transient ability.
                local s = all[sameOwner and b.slot or key]
                if not sameOwner and previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then s = nil end
                if not valid(s) then s = fresh() end
                if not sameOwner then
                    b = {seed=p.InitSeed, slot=key, armed={}}
                end
                b.slot = key; b.state = s; nextBindings[pointer] = b
            end
            nextSlots[key] = {pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do all[key] = nil end
        for _, b in pairs(nextBindings) do all[b.slot] = b.state end
        bindings, slots = nextBindings, nextSlots
    end
    local function binding(p)
        if not ready or not isGLM(p) then return end
        local b = bindings[GetPtrHash(p)]
        if b and b.seed == p.InitSeed then return b end
    end
    local function each(fn)
        for i = 0, Game():GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            local b = binding(p)
            if b then fn(p, b, i) end
        end
    end
    local function observeFloor(b)
        local s, floor = b.state, floorKey()
        if s.floor ~= floor then
            if s.floor ~= nil then s.awards = {}; s.seen = {}; b.armed = {} end
            s.floor = floor
        end
    end
    local function boosted(s)
        return s.activeRoom ~= nil and s.activeRoom == roomKey()
    end
    -- The Queue pauses while any part of the pass is unused or boosting this room.
    local function passActive(s)
        return s.pass > 0 or boosted(s)
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.glmQueue = {} end
        bind()
        each(function(p, b) observeFloor(b); refresh(p) end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        if not next(bindings) then return end
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            observeFloor(b)
            if s.activeRoom and s.activeRoom ~= room then s.activeRoom = nil; refresh(p) end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() drop:Reset() end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not ready then return end
        bind()
        if not next(bindings) then return end
        if Game():IsPaused() then drop:Reset(); return end
        local combat = not Game():GetRoom():IsClear()
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            observeFloor(b)
            if p:IsDead() then drop:Forget(p); return end
            if drop:Poll(p, s.queue >= QUEUE_MAX and not passActive(s),
                passActive(s) and "Access Pass active" or "Queue below 3/3") then
                s.queue = 0
                s.pass = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_ROOMS or PASS_ROOMS
                Game():GetHUD():ShowItemText("GLM-chan", "Access granted")
            end
            if combat then
                b.armed[room] = true
                -- Only a newly entered hostile room uses a pass room; revisits never do.
                if not s.seen[room] then
                    s.seen[room] = true
                    if s.queue == QUEUE_MAX and not passActive(s) then
                        s.queue = QUEUE_MAX - 1
                        Game():GetHUD():ShowItemText("GLM-chan", "Missed the call: Queue 2/3")
                    end
                    if s.pass > 0 then
                        s.pass = s.pass - 1
                        s.activeRoom = room
                        refresh(p)
                    end
                end
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not ready or not next(bindings) then return end
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            if p:IsDead() or not b.armed[room] or s.awards[room] then return end
            s.awards[room] = true
            if not passActive(s) then s.queue = math.min(QUEUE_MAX, s.queue + 1) end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag ~= CacheFlag.CACHE_DAMAGE then return end
        local b = binding(p)
        if b and boosted(b.state) then p.Damage = p.Damage * BONUS end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() or not next(bindings) then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s = b.state
            local text
            if boosted(s) then text = string.format("GLM-chan: Access active  %d room(s) left", s.pass)
            elseif s.pass > 0 then text = string.format("GLM-chan: Access %d room(s)", s.pass)
            elseif s.queue >= QUEUE_MAX then text = "GLM-chan: Ticket ready! Tap DROP before next fight"
            else text = string.format("GLM-chan: Number in queue %d/%d", s.queue, QUEUE_MAX) end
            HudLayout.DrawPlayer(HudText, i, text, 0.3, 0.95, 0.7, 0.9)
        end)
    end)
end

return GLM
