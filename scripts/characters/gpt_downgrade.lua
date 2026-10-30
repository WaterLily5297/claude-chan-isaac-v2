-- Normal GPT: Same Name, Smaller Brain. Verified / Fallback routing with a Sanity Check.
-- Saved per-player status, Routing and unique clears. No proxy, IP or risk mechanics.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Tools = include("scripts.characters.target_tools")
local Choices = include("scripts.characters.attack_choices")
local Gpt = {}

local VERIFIED_DAMAGE, FALLBACK_DAMAGE = 1.15, 0.8
local ROUTING_CAP = 3
local CHECK_RADIUS = 200
local CHECK_HITS, BIRTHRIGHT_HITS = 3, 2

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, verified=true, routing=0, awards={}}
end
local function needed(p)
    return p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_HITS or CHECK_HITS
end

function Gpt:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("GPT-chan", false)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isGpt(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.gptRouting) ~= "table" then Risk.state.gptRouting = {} end
        return Risk.state.gptRouting
    end
    local function valid(s)
        if type(s) ~= "table" or s.version ~= 1 or type(s.verified) ~= "boolean"
            or not integer(s.routing, 0, ROUTING_CAP) or type(s.awards) ~= "table" then return false end
        if s.checkRoom ~= nil and type(s.checkRoom) ~= "string" then return false end
        for k, v in pairs(s.awards) do
            if type(k) ~= "string" or v ~= true then return false end
        end
        return true
    end
    local function roomKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..tostring(level:GetCurrentRoomDesc().SpawnSeed)
    end
    local function refresh(p)
        p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        p:EvaluateItems()
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous, kind = GetPtrHash(p), slots[key], p:GetPlayerType()
            local changed = not previous or previous.pointer ~= pointer
                or previous.seed ~= p.InitSeed or previous.kind ~= kind
            if id >= 0 and kind == id then
                local b = bindings[pointer]
                local sameOwner = b and b.seed == p.InitSeed
                -- Read the old slot before rebuilding the map: cyclic moves
                -- retain this owner's saved progress and transient ability.
                local s = all[sameOwner and b.slot or key]
                if not sameOwner and previous and changed then s = nil end
                if not valid(s) then s = fresh() end
                if not sameOwner then
                    b = {seed=p.InitSeed, slot=key, armed={}}
                end
                b.slot = key; b.state = s; nextBindings[pointer] = b
            end
            -- Keep the immutable identity snapshot while this slot is unchanged.
            nextSlots[key] = changed and {pointer=pointer, seed=p.InitSeed, kind=kind} or previous
        end
        for key in pairs(all) do all[key] = nil end
        for _, b in pairs(nextBindings) do all[b.slot] = b.state end
        bindings, slots = nextBindings, nextSlots
    end
    local function binding(p)
        if not ready or not isGpt(p) then return end
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
    local function observeFloor(p, b)
        local s, level = b.state, Game():GetLevel()
        local floor = tostring(level:GetDungeonPlacementSeed())..":"..level:GetStage()..":"..level:GetStageType()
        if s.floor ~= floor then
            -- Every floor starts Verified; continue on the same floor does not.
            if s.floor ~= nil then
                local changed = not s.verified
                s.verified = true; s.routing = 0; s.awards = {}; s.checkRoom = nil
                b.check = nil; b.armed = {}
                if changed then refresh(p) end
            end
            s.floor = floor
        end
    end
    local function verify(p, b)
        b.state.verified = true; b.state.routing = 0; b.check = nil
        Game():GetHUD():ShowItemText("GPT-chan", "Verified")
        refresh(p)
    end
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.gptRouting = {} end
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
        -- Leaving the room fails an unfinished check; Fallback remains.
        each(function(p, b) b.check = nil; observeFloor(p, b) end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() drop:Reset() end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not ready then return end
        bind()
        if Game():IsPaused() then drop:Reset(); return end
        if not next(bindings) then return end
        local combat = not Game():GetRoom():IsClear()
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            observeFloor(p, b)
            if p:IsDead() then drop:Forget(p); return end
            if combat then
                b.armed[room] = true
                if s.verified and s.routing >= ROUTING_CAP then
                    s.verified = false
                    Game():GetHUD():ShowItemText("GPT-chan", "Fallback: same name, smaller brain")
                    refresh(p)
                end
            end
            if b.check then
                local target = b.check.ref.Ref
                if not target or not target:Exists() or target:IsDead() or not target:IsVulnerableEnemy()
                    or target:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then b.check = nil
                else
                    local previous = b.check.count
                    -- Birthright lowers the current completion threshold, not historical clamps.
                    b.check.count = Choices.Resolve(b.check.choices, CHECK_HITS)
                    if b.check.count < previous then
                        Game():GetHUD():ShowItemText("GPT-chan", "Contradiction: focus the marked target")
                    end
                    if b.check.count >= needed(p) then verify(p, b) end
                end
            end
            local canCheck = not s.verified and s.checkRoom ~= room and b.check == nil
            if drop:Poll(p, canCheck,
                s.verified and "Already Verified" or b.check and "Check in progress" or "Check spent this room") then
                local target = Tools.Nearest(p.Position, CHECK_RADIUS)
                -- No target means no attempt is spent.
                if target then
                    s.checkRoom = room
                    b.check = {ref=EntityPtr(target), hash=GetPtrHash(target), choices=Choices.New(), count=0}
                    Game():GetHUD():ShowItemText("GPT-chan", "Sanity Check")
                else
                    drop:Refuse(p, "No target in range")
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
            if s.verified then s.routing = math.min(ROUTING_CAP, s.routing + 1) end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        if not ready or not next(bindings) then return end
        if not tear:Exists() or not binding(Tools.Owner(tear)) then return end
        Tools.MarkVolley(tear, Game():GetFrameCount())
    end)
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, _, _, source)
        if not ready or not next(bindings) or Game():IsPaused() then return end
        local src = source and source.Entity
        local data = src and src.GetData and src:GetData()
        if data and (data.ccLlamaHelper or data.ccThoughtDerived) then return end
        local p = Tools.Owner(src)
        local b = binding(p)
        if not b or not b.check or not entity:IsVulnerableEnemy()
            or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then return end
        local now = Game():GetFrameCount()
        local target = GetPtrHash(entity) == b.check.hash
        if target then b.check.credit = now end
        local key = Tools.AttackKey(src, now)
        if not key then return end
        Choices.Record(b.check.choices, key, target)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
        if not ready or not next(bindings) then return end
        local now = Game():GetFrameCount()
        each(function(p, b)
            local check = b.check
            if check and GetPtrHash(entity) == check.hash and check.credit and now - check.credit <= 1 then
                verify(p, b)
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag ~= CacheFlag.CACHE_DAMAGE then return end
        local b = binding(p)
        if b then p.Damage = p.Damage * (b.state.verified and VERIFIED_DAMAGE or FALLBACK_DAMAGE) end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s = b.state
            local text
            if s.verified then
                text = string.format("GPT-chan: Verified  Routing %d/%d", s.routing, ROUTING_CAP)
            elseif b.check then
                text = string.format("GPT-chan: Fallback  Check %d/%d", b.check.count, needed(p))
            else
                text = "GPT-chan: Fallback  "..(s.checkRoom == roomKey() and "Check failed" or "DROP: Sanity Check")
            end
            HudLayout.DrawPlayer(HudText, i, text, 0.4, 1, 0.75, 0.9)
        end)
    end)
end

return Gpt
