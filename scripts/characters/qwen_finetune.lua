-- Tainted Qwen: Final Final Fine-Tune. Pick a build between fights; clearing rooms
-- with all three builds earns a floor bonus. The joke is community enthusiasm for
-- variants and derivatives, not a claim that any product is copied. Saved per player.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local FireRate = include("scripts.fire_rate")
local FineTune = {}

local BUILDS = {
    {name="Heavy", damage=1.3, interval=1.2},
    {name="Tiny", damage=0.85, interval=0.8},
    {name="Balanced", damage=1, interval=1},
}
local AWARD_CAP = 3
local AWARD_DAMAGE, BIRTHRIGHT_DAMAGE = 0.2, 0.3
local ALL_BUILDS = 7 -- One bit per build.
local PIN_CLEARS = 2

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=2, build=3, used=0, awards=0, cleared={}, pinned=0}
end
local function valid(s)
    if type(s) ~= "table" or (s.version ~= 1 and s.version ~= 2) or not integer(s.build, 1, #BUILDS)
        or not integer(s.used, 0, ALL_BUILDS - 1) or not integer(s.awards, 0, AWARD_CAP)
        or type(s.cleared) ~= "table"
        or (s.version == 2 and not integer(s.pinned, 0, PIN_CLEARS)) then return false end
    for k, v in pairs(s.cleared) do
        if type(k) ~= "string" or v ~= true then return false end
    end
    return true
end

function FineTune:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Qwen-chan", true)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isTainted(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.qwenFineTune) ~= "table" then Risk.state.qwenFineTune = {} end
        return Risk.state.qwenFineTune
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
        p:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_FIREDELAY)
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
                if s.version == 1 then s.version = 2; s.pinned = 0 end
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
    -- A new floor clears the checklist and the floor bonus.
    local function observeFloor(p, b)
        local s, floor = b.state, floorKey()
        if s.floor ~= floor then
            local changed = s.floor ~= nil
            if changed then
                s.cleared = {}; s.used = 0; s.awards = 0; b.armed = {}
                s.build = 3; s.pinned = 0
            end
            s.floor = floor
            if changed then refresh(p) end
        end
    end
    local function count(used)
        local n = 0
        for bit = 0, #BUILDS - 1 do if used & (1 << bit) ~= 0 then n = n + 1 end end
        return n
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.qwenFineTune = {} end
        bind()
        each(function(p, b) observeFloor(p, b); refresh(p) end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        each(function(p, b) observeFloor(p, b) end)
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
            observeFloor(p, b)
            if p:IsDead() then drop:Forget(p); return end
            if combat then b.armed[room] = true end
            -- A new choice commits to two new combat clears, even in safe rooms.
            if drop:Poll(p, not combat,
                "Change build between fights") then
                if s.pinned > 0 then
                    drop:Refuse(p, "Pinned: clear "..s.pinned.." new rooms")
                else
                    s.build = s.build % #BUILDS + 1; s.pinned = PIN_CLEARS
                    refresh(p)
                    Game():GetHUD():ShowItemText("Qwen-chan", BUILDS[s.build].name.." build")
                end
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
            s.pinned = math.max(0, s.pinned - 1)
            if s.awards >= AWARD_CAP then return end
            s.used = s.used | (1 << (s.build - 1))
            if s.used == ALL_BUILDS then
                s.used = 0
                s.awards = s.awards + 1
                refresh(p)
                Game():GetHUD():ShowItemText("Qwen-chan", "Final final version")
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        local b = binding(p)
        if not b then return end
        local s, build = b.state, BUILDS[b.state.build]
        if flag == CacheFlag.CACHE_DAMAGE then
            local per = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_DAMAGE or AWARD_DAMAGE
            p.Damage = (p.Damage + s.awards * per) * build.damage
        elseif flag == CacheFlag.CACHE_FIREDELAY then
            p.MaxFireDelay = FireRate.ScaleInterval(p.MaxFireDelay, build.interval)
        end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() or not next(bindings) then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s = b.state
            local text = string.format("Qwen-chan: %s  Variants %d/%d  Awards %d/%d", BUILDS[s.build].name,
                count(s.used), #BUILDS, s.awards, AWARD_CAP)
            if s.pinned > 0 then text = text..string.format("  Pinned: %d clears", s.pinned) end
            HudLayout.DrawPlayer(HudText, i, text, 0.75, 0.45, 1, 0.9)
        end)
    end)
end

return FineTune
