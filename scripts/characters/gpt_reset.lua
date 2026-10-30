-- Tainted GPT: Reset Watcher. A Credits allowance with a banked Tibo reset.
-- A fictional reset restores an allowance; it does not claim that real quota
-- resets fix model quality. Saved per player; no real time and no network.
local SaveSync = include("scripts.save_sync")
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local PaidAttacks = include("scripts.characters.paid_attacks")
local Reset = {}

local CREDITS, BIRTHRIGHT_CREDITS = 80, 100
local CLEARS_PER_RESET = 3
local FULL_SEND_DAMAGE = 1.5

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, credits=CREDITS, fullSend=false, clears=0, ready=false, awards={}}
end
local function valid(s)
    if type(s) ~= "table" or s.version ~= 1 or not integer(s.credits, 0, BIRTHRIGHT_CREDITS)
        or type(s.fullSend) ~= "boolean" or not integer(s.clears, 0, CLEARS_PER_RESET - 1)
        or type(s.ready) ~= "boolean" or type(s.awards) ~= "table" then return false end
    for k, v in pairs(s.awards) do
        if type(k) ~= "string" or v ~= true then return false end
    end
    return true
end
local function cap(p)
    return p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_CREDITS or CREDITS
end

function Reset:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("GPT-chan", true)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isTainted(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.gptReset) ~= "table" then Risk.state.gptReset = {} end
        return Risk.state.gptReset
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
            if isTainted(p) then
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
    SaveSync.Register(Risk, "character.gpt_reset", function()
        if ready then bind() end
    end)

    local function binding(p)
        if not ready or not isTainted(p) then return end
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
    -- Credits and progress carry across floors; only unique-clear keys reset.
    local function observeFloor(b)
        local s, floor = b.state, floorKey()
        if s.floor ~= floor then
            if s.floor ~= nil then s.awards = {}; b.armed = {} end
            s.floor = floor
        end
    end
    local function owner(entity)
        if not entity then return end
        local spawner = entity.SpawnerEntity or entity.Parent
        return spawner and spawner:ToPlayer()
    end
    -- One payment per same-frame attack, whatever mix of weapons fired it.
    local function pay(p)
        local b = binding(p)
        if not b or p:IsDead() then return end
        local s, now = b.state, Game():GetFrameCount()
        if b.paid == now or not s.fullSend then return end
        b.paid = now
        s.credits = math.max(0, s.credits - 1)
        if s.credits == 0 then
            s.fullSend = false
            Game():GetHUD():ShowItemText("GPT-chan", "Out of credits: Standard")
            refresh(p)
        end
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.gptReset = {} end
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
        each(function(_, b) observeFloor(b) end)
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
            s.credits = math.min(s.credits, cap(p))
            if p:IsDead() then drop:Forget(p); return end
            if combat then b.armed[room] = true end
            if drop:Poll(p, true) then
                if s.ready and not combat then
                    -- Combat keeps the refill banked and still allows mode toggles.
                    s.ready = false; s.credits = cap(p)
                    Game():GetHUD():ShowItemText("Tibo", "Limits reset")
                elseif s.fullSend or s.credits > 0 then
                    s.fullSend = not s.fullSend
                    Game():GetHUD():ShowItemText("GPT-chan", s.fullSend and "Full Send" or "Standard")
                    refresh(p)
                else
                    drop:Refuse(p, s.ready and "Claim reset between fights" or "No Credits left")
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
            -- Room progress pauses while a reset is banked.
            if s.ready then return end
            s.clears = s.clears + 1
            if s.clears >= CLEARS_PER_RESET then
                s.clears = 0; s.ready = true
                Game():GetHUD():ShowItemText("Tibo", "Reset Ready")
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        if not ready or not next(bindings) or not tear:Exists() then return end
        local data = tear:GetData()
        if data.ccThoughtDerived or data.ccResetSeen then return end
        data.ccResetSeen = true
        pay(owner(tear))
    end)
    mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, function(_, laser)
        if not ready or not next(bindings) then return end
        if laser.Parent and laser.Parent.Type == EntityType.ENTITY_LASER then return end
        pay(owner(laser))
    end)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(_, bomb)
        if not ready or not next(bindings) or not bomb.IsFetus then return end
        pay(owner(bomb))
    end)
    -- Held beams, knife throws, melee swings and Epic Fetus rockets pay too,
    -- so Full Send's 1.5x is never free on a non-tear build.
    PaidAttacks.Observe(mod, function(p) if ready and next(bindings) then pay(p) end end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag ~= CacheFlag.CACHE_DAMAGE then return end
        local b = binding(p)
        if b and b.state.fullSend then p.Damage = p.Damage * FULL_SEND_DAMAGE end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s = b.state
            local text = string.format("Credits %d/%d  %s  ", s.credits, cap(p), s.fullSend and "Full Send" or "Standard")
            text = text..(s.ready and (Game():GetRoom():IsClear() and "Tibo: Reset Ready" or "Tibo: after combat")
                or string.format("Next Reset %d/%d", s.clears, CLEARS_PER_RESET))
            HudLayout.DrawPlayer(HudText, i, text, 0.3, 0.85, 0.6, 0.9)
        end)
    end)
end

return Reset
