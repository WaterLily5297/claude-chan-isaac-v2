-- Paid-attack observer for allowance forms. Each form bills tear volleys,
-- laser starts and Dr. Fetus bombs itself; this adds the native attacks those
-- callbacks miss, so no weapon fires for free:
--   * each further 0.2-second window of a held repeated-hit beam,
--   * each 0.2-second window of a Ludovico tear while its owner fires,
--   * each knife throw, each melee swing hitbox and each Epic Fetus rocket.
-- pay(player, entity) is called once per such attack with the weapon entity
-- that made it; the form deduplicates per frame.
-- Familiar-owned weapons resolve to no player and are never billed.
local Tools = include("scripts.characters.target_tools")

local Paid = {}
local WINDOW = Tools.WINDOW_FRAMES
-- Older API builds lack the enum; 4 is the documented swing-hitbox subtype.
local CLUB_HITBOX = KnifeSubType and KnifeSubType.CLUB_HITBOX or 4

local function player(entity)
    if not entity then return end
    if entity.SpawnerEntity then return entity.SpawnerEntity:ToPlayer() end
    return entity.Parent and entity.Parent:ToPlayer()
end
local function knifeOwner(knife)
    local weapon = knife.Parent
    if weapon and weapon.Type == EntityType.ENTITY_KNIFE then return player(weapon) end
    return player(knife)
end
local function rocketOwner(rocket)
    local spawner = rocket.SpawnerEntity
    if spawner and spawner.Type == EntityType.ENTITY_EFFECT and spawner.Variant == EffectVariant.TARGET then
        return player(spawner)
    end
    return player(rocket)
end
local function ludovico(entity)
    return TearFlags and TearFlags.TEAR_LUDOVICO and entity.HasTearFlags
        and entity:HasTearFlags(TearFlags.TEAR_LUDOVICO) or false
end

function Paid.Observe(mod, pay, ignoreLaser, shareLaserWindow)
    -- Entity-local, transient identity per subscriber. A shared marker lets
    -- Opus consume the event before character meters, even without the item.
    local key = {}
    local childLaserKey = {}
    local function rememberChild(laser)
        if laser.Parent and laser.Parent.Type == EntityType.ENTITY_LASER then
            laser:GetData()[childLaserKey] = true
        end
    end
    -- Continuous windows are per player, so two held beams share one window.
    local windows = {}
    local function window(p, entity)
        if not p then return end
        local now, pointer = Game():GetFrameCount(), GetPtrHash(p)
        local last = windows[pointer]
        if not last or now < last.frame or now - last.frame >= WINDOW then
            last = {frame=now}
            windows[pointer] = last
            last.decision = pay(p, entity)
        end
        -- Optional effect sharing is separate from payment. Only eligible
        -- primary held lasers reach this hook; each subscriber owns its result.
        if shareLaserWindow and entity.Type == EntityType.ENTITY_LASER then
            shareLaserWindow(p, entity, last.decision)
        end
    end
    local function once(entity, p)
        local data = entity:GetData()
        if data[key] then return end
        data[key] = true
        if p then pay(p, entity) end
    end
    local function reset() windows = {} end

    mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, function(_, laser)
        rememberChild(laser)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, function(_, laser)
        -- Parent may disappear before the first paid window. Classification
        -- lasts with this entity, including across observer window resets.
        rememberChild(laser)
        if laser:GetData()[childLaserKey] then return end
        if Game():IsPaused() then return end
        -- A subscriber can retain child classification after Parent disappears.
        -- Ignore it before consuming that subscriber's per-player window.
        if ignoreLaser and ignoreLaser(laser) then return end
        local circle = laser.IsCircleLaser and laser:IsCircleLaser()
        if laser.DisableFollowParent and not circle then return end
        -- Single-hit beams and released rings are paid in full at their start.
        if laser.OneHit or (circle and not ludovico(laser)) then return end
        -- The first window is the start payment.
        if (laser.FrameCount or 0) < WINDOW then return end
        window(player(laser), laser)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, function(_, tear)
        if Game():IsPaused() or (tear.FrameCount or 0) < WINDOW or not ludovico(tear) then return end
        if tear:GetData().ccThoughtDerived then return end
        local p = player(tear)
        if p and p:GetShootingInput():LengthSquared() > 0 then window(p, tear) end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, function(_, knife)
        if Game():IsPaused() then return end
        if knife.SubType == CLUB_HITBOX then once(knife, knifeOwner(knife)); return end
        local data = knife:GetData()
        if data.ccThoughtDerived then return end
        -- One throw is one attack; the knife resting on the player is free.
        if not knife:IsFlying() then data[key] = nil; return end
        once(knife, player(knife))
    end)
    if EffectVariant and EffectVariant.ROCKET then
        mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, function(_, rocket)
            if Game():IsPaused() then return end
            once(rocket, rocketOwner(rocket))
        end, EffectVariant.ROCKET)
    end
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, reset)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, reset)
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, reset)
end

return Paid
