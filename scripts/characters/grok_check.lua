-- Normal Grok: Is This True? A once-per-room fact check on one enemy.
-- Saved per-player room flags only; the live check is transient. Grok and the
-- parody account Gork remain distinct; this is a fictional gameplay role.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Tools = include("scripts.characters.target_tools")
local Grok = {}

local CHECK_RADIUS = 220
local CHECK_FRAMES = 180 -- Six seconds.
local LOST_SIGHT_FRAMES = 30
local CHECK_HITS = 3
local TARGET_DAMAGE, OTHER_DAMAGE = 1.3, 0.9
local VERIFIED_SPEED = 0.15
local BULLET_RADIUS, BULLETS = 120, 3

local function fresh()
    return {version=1}
end
local function valid(s)
    return type(s) == "table" and s.version == 1
        and (s.checkRoom == nil or type(s.checkRoom) == "string")
        and (s.verifiedRoom == nil or type(s.verifiedRoom) == "string")
end

function Grok:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Grok-chan", false)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local redealing = false
    local function isGrok(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.grokCheck) ~= "table" then Risk.state.grokCheck = {} end
        return Risk.state.grokCheck
    end
    local function roomKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..tostring(level:GetCurrentRoomDesc().SpawnSeed)
    end
    local function refresh(p)
        p:AddCacheFlags(CacheFlag.CACHE_SPEED)
        p:EvaluateItems()
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if isGrok(p) then
                if previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then all[key] = nil end
                if not valid(all[key]) then all[key] = fresh() end
                local b = bindings[pointer]
                if not b or b.seed ~= p.InitSeed or b.slot ~= key then
                    b = {seed=p.InitSeed, slot=key, frame=Game():GetFrameCount()}
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
        if not ready or not isGrok(p) then return end
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
    local function clearBullets(p)
        local found = {}
        for _, e in ipairs(Isaac.FindInRadius(p.Position, BULLET_RADIUS, EntityPartition.BULLET)) do
            if e:ToProjectile() and e:Exists() then found[#found + 1] = e end
        end
        table.sort(found, function(a, b) return p.Position:Distance(a.Position) < p.Position:Distance(b.Position) end)
        for i = 1, math.min(BULLETS, #found) do found[i]:Remove() end
    end
    local function verify(p, b)
        b.check = nil
        b.state.verifiedRoom = roomKey()
        Game():GetHUD():ShowItemText("Grok-chan", "Verified")
        if p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then clearBullets(p) end
        refresh(p)
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.grokCheck = {} end
        bind()
        each(function(p) refresh(p) end)
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
        -- Room effects end on exit; the speed bonus belongs to the verified room.
        each(function(p, b)
            b.check = nil
            if b.state.verifiedRoom and b.state.verifiedRoom ~= room then
                b.state.verifiedRoom = nil; refresh(p)
            end
        end)
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
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            local advanced = now > b.frame
            b.frame = now
            if b.check then
                local target = b.check.ref.Ref
                if not target or not target:Exists() or target:IsDead()
                    or not target:IsVulnerableEnemy() or target:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                    b.check = nil
                elseif advanced then
                    b.check.remaining = b.check.remaining - 1
                    b.check.obscured = Game():GetRoom():CheckLine(p.Position, target.Position, 3)
                        and 0 or (b.check.obscured or 0) + 1
                    -- Timeout gives nothing.
                    if b.check.obscured >= LOST_SIGHT_FRAMES then
                        b.check = nil
                        Game():GetHUD():ShowItemText("Grok-chan", "Lost sight: unverified")
                    elseif b.check.remaining <= 0 then b.check = nil end
                end
            end
            if drop:Poll(p, combat and s.checkRoom ~= room and b.check == nil,
                not combat and "Needs combat" or b.check and "Check in progress" or "Check spent this room") then
                local target = Tools.Nearest(p.Position, CHECK_RADIUS)
                -- No target means the room's check is not spent.
                if target then
                    s.checkRoom = room
                    b.check = {ref=EntityPtr(target), hash=GetPtrHash(target),
                        remaining=CHECK_FRAMES, hits={}, count=0}
                    Game():GetHUD():ShowItemText("Grok-chan", "Is this true?")
                else
                    drop:Refuse(p, "No target in range")
                end
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        if not ready or not next(bindings) or not tear:Exists() then return end
        if binding(Tools.Owner(tear)) then Tools.MarkVolley(tear, Game():GetFrameCount()) end
    end)
    -- While a check runs, owner damage is re-dealt once: 1.3x to the target, 0.9x to others.
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, countdown)
        if redealing or not ready or not next(bindings) then return end
        local src = source and source.Entity
        local p = Tools.Owner(src)
        local b = binding(p)
        if not b or not b.check or not entity:IsEnemy() then return end
        local check, now = b.check, Game():GetFrameCount()
        local onTarget = GetPtrHash(entity) == check.hash
        if onTarget then
            check.credit = now
            local key = Tools.AttackKey(src, now)
            if key and not check.hits[key] then
                check.hits[key] = true
                check.count = check.count + 1
            end
        end
        redealing = true
        entity:TakeDamage(amount * (onTarget and TARGET_DAMAGE or OTHER_DAMAGE), flags, source, countdown)
        redealing = false
        if onTarget and check.count >= CHECK_HITS and b.check == check then verify(p, b) end
        return false
    end)
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
        if not ready or not next(bindings) then return end
        local now = Game():GetFrameCount()
        each(function(p, b)
            local check = b.check
            if check and GetPtrHash(entity) == check.hash then
                if check.credit and now - check.credit <= 1 then verify(p, b) else b.check = nil end
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag ~= CacheFlag.CACHE_SPEED then return end
        local b = binding(p)
        if b and b.state.verifiedRoom and b.state.verifiedRoom == roomKey() then
            p.MoveSpeed = p.MoveSpeed + VERIFIED_SPEED
        end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() or not next(bindings) then return end
        local room = roomKey()
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s, text = b.state, nil
            if b.check then
                text = string.format("Grok-chan: Check %d/%d  %ds", b.check.count, CHECK_HITS,
                    math.ceil(b.check.remaining / 30))
                if (b.check.obscured or 0) > 0 then text = text.."  Restore sight" end
            elseif s.verifiedRoom == room then text = "Grok-chan: Verified"
            elseif s.checkRoom == room then text = "Grok-chan: Unverified"
            else text = "Grok-chan: DROP: Is this true?" end
            HudLayout.DrawPlayer(HudText, i, text, 1, 0.3, 0.35, 0.9)
        end)
    end)
end

return Grok
