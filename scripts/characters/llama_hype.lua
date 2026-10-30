-- Tainted Llama: Still Waiting. Save up Hype, then spend it all on a short-lived
-- helper that fires weak native tears. Fictional gameplay; no claim about any
-- company's release plans. Saved per player: Hype and unique clears. The helper is transient.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Tools = include("scripts.characters.target_tools")
local Hype = {}

local BASE_DAMAGE = 0.9
local HYPE_CAP = 3
local FRAMES_PER_HYPE, BIRTHRIGHT_FRAMES = 120, 150 -- Four seconds; five with Birthright.
local SHOT_FRAMES = 30 -- One tear per second.
local TEAR_DAMAGE = 0.5
local RANGE = 400
local OWNER_RANGE = 120
local TEAR_SPEED = 10

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, hype=0, cleared={}}
end
local function valid(s)
    if type(s) ~= "table" or s.version ~= 1 or not integer(s.hype, 0, HYPE_CAP) or type(s.cleared) ~= "table" then return false end
    for k, v in pairs(s.cleared) do
        if type(k) ~= "string" or v ~= true then return false end
    end
    return true
end

function Hype:Init(mod, Risk, Backlog)
    local id = Isaac.GetPlayerTypeByName("Llama-chan", true)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isTainted(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.llamaHype) ~= "table" then Risk.state.llamaHype = {} end
        return Risk.state.llamaHype
    end
    local function roomKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..tostring(level:GetCurrentRoomDesc().SpawnSeed)
    end
    local function floorKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..level:GetStage()..":"..level:GetStageType()
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if isTainted(p) then
                if previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then all[key] = nil end
                if not valid(all[key]) then all[key] = fresh() end
                local b = bindings[pointer]
                if not b or b.seed ~= p.InitSeed or b.slot ~= key then
                    b = {seed=p.InitSeed, slot=key, armed={}, frame=Game():GetFrameCount()}
                end
                b.state = all[key]; nextBindings[pointer] = b
            else
                all[key] = nil
            end
            nextSlots[key] = {pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do if not nextSlots[key] then all[key] = nil end end
        bindings, slots = nextBindings, nextSlots
    end
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
    local function observeFloor(b)
        local s, floor = b.state, floorKey()
        if s.floor ~= floor then
            if s.floor ~= nil then s.cleared = {}; b.armed = {} end
            s.floor = floor
        end
    end
    -- The helper stays where it was placed and aims at the nearest enemy.
    local function shoot(p, helper)
        local target = Tools.Nearest(helper.position, RANGE)
        if not target then return end
        local dir = (target.Position - helper.position):Normalized()
        -- Share the helper scope before native tear callbacks can bill Opus or
        -- consume attack primes; keep the helper's own position and effects.
        local tear = Backlog.FireDerived(p, dir * (TEAR_SPEED * p.ShotSpeed), TEAR_DAMAGE, helper.position)
        if tear then tear:GetData().ccLlamaHelper = true end
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.llamaHype = {} end
        bind()
        each(function(p, b) observeFloor(b); p:AddCacheFlags(CacheFlag.CACHE_DAMAGE); p:EvaluateItems() end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        each(function(_, b) b.helper = nil; observeFloor(b) end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() drop:Reset() end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not ready then return end
        bind()
        if not next(bindings) then return end
        local now = Game():GetFrameCount()
        if Game():IsPaused() then
            drop:Reset()
            each(function(_, b) b.frame = now end)
            return
        end
        local combat = not Game():GetRoom():IsClear()
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            observeFloor(b)
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            local advanced = now > b.frame
            b.frame = now
            if combat then b.armed[room] = true end
            local helper = b.helper
            if helper and advanced then
                helper.remaining = helper.remaining - 1
                helper.shot = helper.shot + 1
                if helper.shot >= SHOT_FRAMES then
                    helper.shot = 0
                    if p.Position:Distance(helper.position) <= OWNER_RANGE then shoot(p, helper) end
                end
                if helper.remaining <= 0 then b.helper = nil end
            end
            -- Spending all Hype replaces any helper and its remaining time.
            if drop:Poll(p, s.hype > 0,
                "No Hype yet") then
                local per = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_FRAMES or FRAMES_PER_HYPE
                b.helper = {position=p.Position, remaining=s.hype * per, shot=0}
                s.hype = 0
                Game():GetHUD():ShowItemText("Llama-chan", "Still waiting...")
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not ready or not next(bindings) then return end
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            if p:IsDead() or not b.armed[room] or s.cleared[room] then return end
            s.cleared[room] = true
            s.hype = math.min(HYPE_CAP, s.hype + 1)
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag == CacheFlag.CACHE_DAMAGE and binding(p) then p.Damage = p.Damage * BASE_DAMAGE end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() or not next(bindings) then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local text = string.format("Llama-chan: Hype %d/%d", b.state.hype, HYPE_CAP)
            if b.helper then text = text..string.format("  Helper %ds", math.ceil(b.helper.remaining / 30)) end
            if b.helper and p.Position:Distance(b.helper.position) > OWNER_RANGE then text = text.."  Return to demo" end
            HudLayout.DrawPlayer(HudText, i, text, 0.6, 0.95, 0.45, 0.9)
        end)
    end)
end

return Hype
