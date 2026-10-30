-- Normal Llama: Please Stay Open. Spend a Release to share blue flies.
-- Fictional gameplay; no claim about any company's future release policy.
-- Saved per player; duplicate Llamas own separate budgets.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Tools = include("scripts.characters.target_tools")
local Llama = {}

local RELEASE_START, RELEASE_CAP = 1, 2
local CLEARS_PER_RELEASE = 2
local SHARED_FLIES, SOLO_FLIES, BIRTHRIGHT_FLIES = 2, 4, 2
local MAX_RECIPIENTS = 4
local BASE_DAMAGE = 0.95

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, releases=RELEASE_START, clears=0, awards={}}
end
local function valid(s)
    if type(s) ~= "table" or s.version ~= 1 or not integer(s.releases, 0, RELEASE_CAP)
        or not integer(s.clears, 0, CLEARS_PER_RELEASE - 1) or type(s.awards) ~= "table" then return false end
    for k, v in pairs(s.awards) do
        if type(k) ~= "string" or v ~= true then return false end
    end
    return true
end

function Llama:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Llama-chan", false)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isLlama(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.llamaRelease) ~= "table" then Risk.state.llamaRelease = {} end
        return Risk.state.llamaRelease
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
            if isLlama(p) then
                if previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then all[key] = nil end
                if not valid(all[key]) then all[key] = fresh() end
                local b = bindings[pointer]
                if not b or b.seed ~= p.InitSeed or b.slot ~= key then
                    b = {seed=p.InitSeed, slot=key, armed={}}
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
        if not ready or not isLlama(p) then return end
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
            if s.floor ~= nil then s.awards = {}; b.armed = {} end
            s.floor = floor
        end
    end
    local function release(p)
        local recipients = {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local ally = Isaac.GetPlayer(i)
            if Tools.Active(ally) and #recipients < MAX_RECIPIENTS then recipients[#recipients + 1] = ally end
        end
        local each = #recipients == 1 and SOLO_FLIES or SHARED_FLIES
        for _, ally in ipairs(recipients) do ally:AddBlueFlies(each, ally.Position, nil) end
        if p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
            p:AddBlueFlies(BIRTHRIGHT_FLIES, p.Position, nil)
        end
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.llamaRelease = {} end
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
            if p:IsDead() then drop:Forget(p); return end
            if combat then b.armed[room] = true end
            if drop:Poll(p, s.releases > 0,
                "No Releases left") then
                if combat then
                    drop:Refuse(p, "Release between fights")
                else
                    s.releases = s.releases - 1
                    release(p)
                    Game():GetHUD():ShowItemText("Llama-chan", "Released")
                end
            end
        end)
    end)
    -- Release progress comes only from unique combat clears, never from flies.
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not ready or not next(bindings) then return end
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            if p:IsDead() or not b.armed[room] or s.awards[room] then return end
            s.awards[room] = true
            s.clears = s.clears + 1
            if s.clears >= CLEARS_PER_RELEASE then
                s.clears = 0
                s.releases = math.min(RELEASE_CAP, s.releases + 1)
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag == CacheFlag.CACHE_DAMAGE and binding(p) then p.Damage = p.Damage * BASE_DAMAGE end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s = b.state
            local text = string.format("Llama-chan: Releases %d/%d  Next %d/%d", s.releases, RELEASE_CAP,
                s.clears, CLEARS_PER_RELEASE)
            if s.releases > 0 and not Game():GetRoom():IsClear() then text = text.."  Between fights" end
            HudLayout.DrawPlayer(HudText, i, text, 0.65, 1, 0.5, 0.9)
        end)
    end)
end

return Llama
