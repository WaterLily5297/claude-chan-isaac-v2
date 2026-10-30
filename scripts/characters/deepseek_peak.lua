-- Tainted DeepSeek: Wenfeng / Wengu. Peak / Valley compute scheduling.
-- Saved per-player Compute, phase and mode. No proxy, IP or risk mechanics.
-- Tear volleys buy two half-damage forks. Every other native attack (laser
-- starts and 0.2-second beam windows, knife throws, melee swings, Dr. Fetus
-- bombs, Epic Fetus rockets) buys the same-priced "off-peak boost" instead:
-- that attack's hits deal 1.3x, re-dealt once behind a recursion guard.
local C = include("scripts.constants")
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local TearFork = include("scripts.tear_fork")
local PaidAttacks = include("scripts.characters.paid_attacks")
local Peak = {}

local PHASE_FRAMES = 360 -- Twelve active-combat seconds.
local START_COMPUTE, CAP, BIRTHRIGHT_CAP = 12, 24, 32
local RESERVATION = 4
local REGEN_FRAMES = 10 -- Three Compute per second.
local COST = {valley=2, peak=4}
local TOGGLE_FRAMES = 30
local FORK_SPREAD, FORK_DAMAGE = 12, 0.5
local BOOST_DAMAGE = 1.3 -- Two half-damage forks, landed on one target.
local WINDOW = 6
local BOOST = "ccPeakBoost"

local function tainted(p)
    return p and C.Player.DEEPSEEK_CHAN_B >= 0 and p:GetPlayerType() == C.Player.DEEPSEEK_CHAN_B
end
local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=2, compute=START_COMPUTE, reserved=0, regen=0, phase="valley", remaining=PHASE_FRAMES, saving=false}
end
local function cap(p)
    return p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_CAP or CAP
end

function Peak:Init(mod, Risk)
    local ready, bindings, slots = false, {}, {}
    local laserKey, laserEpoch = {}, {}
    local drop = DropTap.New()
    local function laserParent(entity)
        local parent = entity.Parent
        return parent and parent.Type == EntityType.ENTITY_LASER and parent or nil
    end
    local function laserInfo(entity)
        local data = entity:GetData()
        if not data[laserKey] then data[laserKey] = {} end
        local info, parent = data[laserKey], laserParent(entity)
        if parent and not info.child then
            info.child = true; info.lease = nil
            info.parentHash = GetPtrHash(parent)
        end
        return info
    end
    local function allStates()
        if type(Risk.state.deepseekPeak) ~= "table" then Risk.state.deepseekPeak = {} end
        return Risk.state.deepseekPeak
    end
    local function valid(s)
        return type(s) == "table" and (s.version == 1 or s.version == 2) and integer(s.compute, 0, BIRTHRIGHT_CAP)
            and integer(s.regen, 0, REGEN_FRAMES - 1) and COST[s.phase] ~= nil
            and integer(s.remaining, 1, PHASE_FRAMES) and type(s.saving) == "boolean"
            and (s.version == 1 or (integer(s.reserved, 0, RESERVATION) and s.compute + s.reserved <= BIRTHRIGHT_CAP))
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if tainted(p) then
                if previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then all[key] = nil end
                if not valid(all[key]) then all[key] = fresh() end
                if all[key].version == 1 then all[key].version = 2; all[key].reserved = 0 end
                local b = bindings[pointer]
                if not b or b.seed ~= p.InitSeed or b.slot ~= key then
                    b = {seed=p.InitSeed, slot=key, frame=Game():GetFrameCount(), clock=0, toggleReady=0}
                end
                b.state = all[key]; nextBindings[pointer] = b
            else
                -- Observed character changes discard the former form's Compute.
                all[key] = nil
            end
            nextSlots[key] = {pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do if not nextSlots[key] then all[key] = nil end end
        bindings, slots = nextBindings, nextSlots
    end
    local function binding(p)
        if not ready or not tainted(p) then return end
        local b = bindings[GetPtrHash(p)]
        if b and b.seed == p.InitSeed then return b end
    end
    local function refund(p, s)
        s.compute = math.min(cap(p), s.compute + s.reserved)
        s.reserved = 0
    end
    local function observeFloor(p, s)
        local level = Game():GetLevel()
        local floor = tostring(level:GetDungeonPlacementSeed())..":"..level:GetStage()..":"..level:GetStageType()
        if s.floor ~= floor then
            -- Every floor starts in Valley; Compute carries over.
            if s.floor ~= nil then
                refund(p, s); s.phase = "valley"; s.remaining = PHASE_FRAMES; s.regen = 0
            end
            s.floor = floor
        end
    end
    local function each(fn)
        for i = 0, Game():GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            local b = binding(p)
            if b then fn(p, b, i) end
        end
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; laserEpoch = {}; drop:Reset()
        if not continued then Risk.state.deepseekPeak = {} end
        bind()
        each(function(p, b) observeFloor(p, b.state) end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; laserEpoch = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        laserEpoch = {}
        drop:Reset()
        if not ready then return end
        bind()
        each(function(p, b) b.volley = nil; observeFloor(p, b.state) end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() drop:Reset() end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not ready then return end
        bind()
        local now = Game():GetFrameCount()
        if Game():IsPaused() then
            drop:Reset()
            each(function(_, b) b.frame = now end)
            return
        end
        local combat = not Game():GetRoom():IsClear()
        each(function(p, b)
            local s = b.state
            observeFloor(p, s)
            s.compute = math.min(s.compute, cap(p) - s.reserved)
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            local advanced = now > b.frame
            if now < b.frame then b.volley = nil; drop:Forget(p) end
            b.frame = now
            if advanced then
                b.clock = b.clock + 1
                -- Empty rooms freeze both the schedule and Valley recovery.
                if combat then
                    s.remaining = s.remaining - 1
                    if s.remaining <= 0 then
                        s.phase = s.phase == "valley" and "peak" or "valley"
                        if s.phase == "peak" then
                            s.reserved = math.min(RESERVATION, s.compute)
                            s.compute = s.compute - s.reserved
                        else refund(p, s) end
                        s.remaining = PHASE_FRAMES; s.regen = 0
                    end
                    local firing = p:GetShootingInput():LengthSquared() > 0
                        or (b.volley and b.volley.frame == now)
                    if s.phase == "valley" and not firing and s.compute < cap(p) then
                        s.regen = s.regen + 1
                        if s.regen >= REGEN_FRAMES then s.regen = 0; s.compute = s.compute + 1 end
                    else
                        s.regen = 0
                    end
                end
            end
            if drop:Poll(p, true) then
                if b.clock >= b.toggleReady then
                    s.saving = not s.saving; b.toggleReady = b.clock + TOGGLE_FRAMES
                else
                    drop:Refuse(p, "Toggle cooling down")
                end
            end
        end)
    end)
    -- One payment per frame, shared by every tear and weapon in it.
    local function charge(b)
        local s, now = b.state, Game():GetFrameCount()
        if not b.volley or b.volley.frame ~= now then
            local cost = COST[s.phase]
            local paid = not s.saving and s.compute >= cost
            if paid then s.compute = s.compute - cost end
            b.volley = {frame=now, forks=paid}
        end
        return b.volley.forks
    end
    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        local data = tear:Exists() and tear:GetData()
        if not data or data.ccThoughtDerived or data.ccPeakSeen then return end
        local p = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
        local b = binding(p)
        if not b or p:IsDead() or Game():IsPaused() then return end
        data.ccPeakSeen = true
        -- One volley is one payment; every tear in a paid volley forks once.
        if not charge(b) then return end
        for _, angle in ipairs({-FORK_SPREAD, FORK_SPREAD}) do
            local fork = Isaac.Spawn(EntityType.ENTITY_TEAR, tear.Variant, 0, tear.Position,
                tear.Velocity:Rotated(angle), p):ToTear()
            if fork then TearFork.Copy(tear, fork, FORK_DAMAGE) end
        end
    end)
    -- Non-tear attacks: a paid attack marks its weapon until the attack ends
    -- (the window for a held beam, the flight for a knife throw, otherwise the
    -- entity's life); an unpaid one clears the mark.
    local function boost(p, entity, lasting)
        local b = binding(p)
        if not b or not entity or p:IsDead() or Game():IsPaused() then return end
        if entity.Type == EntityType.ENTITY_TEAR then return end -- Tears fork instead.
        local info = entity.Type == EntityType.ENTITY_LASER and laserInfo(entity)
        if info and info.child then return end
        local now = Game():GetFrameCount()
        local expires = charge(b) and (lasting and math.huge or now + WINDOW) or nil
        if info then
            if not info.lease or info.lease.epoch ~= laserEpoch or info.lease.binding ~= b then
                info.lease = {epoch=laserEpoch, binding=b}
            end
            -- Children share this decision, including later unpaid windows.
            info.lease.expires = expires
            return {epoch=laserEpoch, binding=b, expires=expires}
        else
            entity:GetData()[BOOST] = expires
        end
    end
    local function owner(entity)
        local spawner = entity and (entity.SpawnerEntity or entity.Parent)
        return spawner and spawner:ToPlayer()
    end
    local function laserLease(laser)
        local current, seen, children, explicit = laser, {}, {}, nil
        while current do
            local info, parent = laserInfo(current), laserParent(current)
            if seen[info] then return end
            seen[info] = true
            if parent and not parent:Exists() then
                if info.parentHash ~= GetPtrHash(parent) then return end
                parent = nil -- Use a resolved decision, never despawned GetData.
            end
            local p = owner(current)
            local spawner = current.SpawnerEntity
            if spawner and not spawner:ToPlayer() then
                if spawner.Type ~= EntityType.ENTITY_LASER then return end
                if parent then
                    if GetPtrHash(spawner) ~= GetPtrHash(parent) then return end
                elseif info.child and info.lease and info.parentHash == GetPtrHash(spawner) then
                    -- Validate a surviving former parent; a removed one leaves
                    -- only the cached decision, never an engine reference.
                    if spawner:Exists() then parent = spawner end
                else return end
            end
            if p then
                local b = binding(p)
                if not b or (explicit and explicit ~= b) then return end
                explicit = b
            end
            if info.child and parent then
                children[info] = GetPtrHash(parent)
                current = parent
            else
                local lease = info.lease
                if not lease or lease.epoch ~= laserEpoch then return end
                local index = tonumber(lease.binding.slot)
                local holder = index < Game():GetNumPlayers() and Isaac.GetPlayer(index)
                if binding(holder) ~= lease.binding or (explicit and explicit ~= lease.binding) then return end
                for child, parentHash in pairs(children) do
                    child.lease, child.parentHash = lease, parentHash
                end
                return lease
            end
        end
        -- Child-first callbacks may retry; never synthesize the parent's cost.
    end
    mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, function(_, laser)
        if not ready then return end
        if laserInfo(laser).child then laserLease(laser); return end
        local circle = laser.IsCircleLaser and laser:IsCircleLaser()
        boost(owner(laser), laser, laser.OneHit or circle)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, function(_, laser)
        if ready and not Game():IsPaused() and laserInfo(laser).child then laserLease(laser) end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(_, bomb)
        if ready and bomb.IsFetus then boost(owner(bomb), bomb, true) end
    end)
    PaidAttacks.Observe(mod, function(p, entity)
        if not ready then return end
        return boost(p, entity, entity and entity.Type ~= EntityType.ENTITY_LASER)
    end, function(laser)
        return laserInfo(laser).child
    end, function(p, laser, decision)
        local b = binding(p)
        if not decision or not b or p:IsDead() or decision.epoch ~= laserEpoch or decision.binding ~= b then return end
        local info = laserInfo(laser)
        if info.child then return end
        if not info.lease or info.lease.epoch ~= laserEpoch or info.lease.binding ~= b then
            info.lease = {epoch=laserEpoch, binding=b}
        end
        -- Reuse this owner's paid window without charging again or moving its
        -- deadline. An unpaid decision also clears a sibling's previous bonus.
        info.lease.expires = decision.expires
    end)
    local redealing = false
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, target, amount, flags, source, countdown)
        if redealing or not ready or target:ToPlayer() then return end
        local weapon = source and source.Entity
        if not weapon or not weapon.GetData then return end
        local mark
        if weapon.Type == EntityType.ENTITY_LASER then
            local lease = laserLease(weapon)
            mark = lease and lease.expires
        else mark = weapon:GetData()[BOOST] end
        if not mark or Game():GetFrameCount() > mark then return end
        -- A knife's throw ends when it returns; resting contact is unpaid.
        if weapon.Type == EntityType.ENTITY_KNIFE and weapon.IsFlying
            and weapon.SubType ~= (KnifeSubType and KnifeSubType.CLUB_HITBOX or 4)
            and not weapon:IsFlying() then return end
        redealing = true
        target:TakeDamage(amount * BOOST_DAMAGE, flags, source, countdown)
        redealing = false
        return false
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s = b.state
            local text = string.format("Compute %d/%d  %s %.1fs  %s", s.compute, cap(p),
                s.phase == "peak" and "Peak" or "Valley", s.remaining / 30, s.saving and "Saving" or "Forks On")
            if s.reserved > 0 then text = text..string.format("  Reserved %d", s.reserved) end
            HudLayout.DrawPlayer(HudText, i, text, 0.45, 1, 0.95, 1)
        end)
    end)
end

return Peak
