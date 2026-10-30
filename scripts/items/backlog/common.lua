-- Shared services for the fifty-row collectible backlog (docs/EXPANSION_DESIGN.md).
--
-- One instance is created in main.lua and passed to every family module, so
-- event lists, guards and timers are shared. Everything uses native engine
-- data: no weapon, sprite, tear flag or collision rule is replaced.
--
-- Attacks: a tear volley (all tears a player fires in one update), a laser,
-- a thrown knife or a Dr. Fetus bomb is one attack. Primed bonuses are not
-- written into entity damage; each entity of the boosted attack is leased a
-- multiplier for at most ATTACK_LEASE frames, applied when it actually hits.
-- That keeps other damage writers and continuous weapons bounded.
--
-- Saved state lives in Risk.state.backlog, keyed by player slot, versioned,
-- with a floor-scoped sub-table. No entity reference is ever saved. Slot
-- tables follow their live owner within a session (scripts/items/slot_owners.lua).

local SlotOwners = include("scripts.items.slot_owners")

local Common = {}

local VERSION = 1
local ATTACK_LEASE = 120

local function now() return Game():GetFrameCount() end
Common.Now = now

function Common.FloorKey()
    local level = Game():GetLevel()
    return tostring(level:GetDungeonPlacementSeed()) .. ":" .. level:GetStage() .. ":" .. level:GetStageType()
end

function Common.RoomKey()
    local desc = Game():GetLevel():GetCurrentRoomDesc()
    return Common.FloorKey() .. "/" .. tostring(desc and desc.SafeGridIndex or -1)
end

function Common.Players()
    local list = {}
    for i = 0, Game():GetNumPlayers() - 1 do list[#list + 1] = Isaac.GetPlayer(i) end
    return list
end

local function slot(player)
    local hash = GetPtrHash(player)
    for i = 0, Game():GetNumPlayers() - 1 do
        if GetPtrHash(Isaac.GetPlayer(i)) == hash then return tostring(i) end
    end
end

local function directOwner(entity)
    if not entity then return nil end
    local player = entity:ToPlayer()
    if player then return player end
    local familiar = entity:ToFamiliar()
    if familiar then return familiar.Player, true end
end

-- Return the owner and whether the source belongs to a familiar. Only direct
-- spawner/parent relationships count; do not guess through projectile ancestry.
-- An unowned familiar must not fall through and borrow a different parent.
function Common.Owner(entity)
    if not entity then return nil end
    local player, familiar = directOwner(entity)
    if player or familiar then return player, familiar end
    player, familiar = directOwner(entity.SpawnerEntity)
    if player or familiar then return player, familiar end
    return directOwner(entity.Parent)
end

function Common.Hostile(npc)
    return npc ~= nil and npc:Exists() and not npc:IsDead() and npc:IsVulnerableEnemy()
        and not npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
end

local function enemies()
    local list = {}
    for _, e in ipairs(Isaac.GetRoomEntities()) do
        local npc = e:ToNPC()
        if Common.Hostile(npc) then list[#list + 1] = npc end
    end
    return list
end
Common.Enemies = enemies

-- Up to `max` hostile enemies within `radius`, nearest first, index as tie-break.
function Common.Nearby(position, radius, max, accept)
    local list = {}
    for _, npc in ipairs(enemies()) do
        local d = (npc.Position - position):LengthSquared()
        if d <= radius * radius and (not accept or accept(npc)) then list[#list + 1] = { npc = npc, d = d } end
    end
    table.sort(list, function(a, b)
        if a.d ~= b.d then return a.d < b.d end
        return a.npc.Index < b.npc.Index
    end)
    local out = {}
    for i = 1, math.min(max or #list, #list) do out[i] = list[i].npc end
    return out
end

function Common.NearestEnemy(position, radius, accept)
    return Common.Nearby(position, radius, 1, accept)[1]
end

-- Ordinary hostile bullets only, like Summary Stapler: no special variants or
-- flags, a living non-friendly NPC spawner.
function Common.OrdinaryBullet(entity)
    local bullet = entity:ToProjectile()
    if not bullet or not bullet:Exists() or bullet:IsDead()
        or bullet.Variant ~= 0 or bullet.SubType ~= 0
        or bullet.ProjectileFlags ~= 0 or bullet.ChangeFlags ~= 0 then return nil end
    local owner = bullet.SpawnerEntity and bullet.SpawnerEntity:ToNPC()
    if not owner or owner:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
        or bullet:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then return nil end
    return bullet
end

function Common.Bullets(position, radius, max)
    local list = {}
    for _, e in ipairs(Isaac.GetRoomEntities()) do
        local b = Common.OrdinaryBullet(e)
        if b then
            local d = (b.Position - position):LengthSquared()
            if d <= radius * radius then list[#list + 1] = { b = b, d = d } end
        end
    end
    table.sort(list, function(x, y)
        if x.d ~= y.d then return x.d < y.d end
        return x.b.Index < y.b.Index
    end)
    local out = {}
    for i = 1, math.min(max or #list, #list) do out[i] = list[i].b end
    return out
end

function Common.Aim(player)
    local direction = player:GetShootingInput()
    if direction:LengthSquared() > 0 then return direction:Normalized() end
    local directions = {
        [Direction.LEFT] = Vector(-1, 0), [Direction.UP] = Vector(0, -1),
        [Direction.RIGHT] = Vector(1, 0), [Direction.DOWN] = Vector(0, 1),
    }
    return directions[player:GetHeadDirection()] or Vector(0, 1)
end

-- Adds charge to the primary active when it is an ordinary, not-full,
-- room-charged item. Timed, zero-charge and special actives never benefit.
function Common.AddCharge(player, amount)
    local slotId = ActiveSlot.SLOT_PRIMARY
    local id = player:GetActiveItem(slotId)
    if not id or id <= 0 then return false end
    local config = Isaac.GetItemConfig():GetCollectible(id)
    if not config or config.MaxCharges <= 0 or config.ChargeType ~= 0 then return false end
    local charge = player:GetActiveCharge(slotId)
    if charge >= config.MaxCharges then return false end
    player:SetActiveCharge(math.min(config.MaxCharges, charge + amount), slotId)
    return true
end

function Common.Caption(title, line)
    Game():GetHUD():ShowItemText(title, line or "")
end

function Common.NoUse()
    return { Discharge = false, Remove = false, ShowAnim = false }
end

function Common.Used()
    return { Discharge = true, Remove = false, ShowAnim = true }
end

function Common.Battery(flags)
    return (flags & UseFlag.USE_CARBATTERY) ~= 0
end

function Common:Init(mod, Risk)
    local listeners = {}
    local stats = { damage = {}, speed = {}, range = {}, shotspeed = {} }
    local leases, volleys, guards, timers, helpers, labels = {}, {}, {}, {}, {}, {}
    local pendingUse, hitThisRoom, lastAttack = {}, {}, {}
    local dealing = false
    local started = false
    local owners = SlotOwners.New()

    local function savedPlayers()
        local all = Risk.state.backlog
        if type(all) ~= "table" or all.version ~= VERSION or type(all.players) ~= "table" then return nil end
        owners:Observe(all.players)
        return all.players
    end

    function self.On(name, fn)
        listeners[name] = listeners[name] or {}
        table.insert(listeners[name], fn)
    end
    local function emit(name, ...)
        for _, fn in ipairs(listeners[name] or {}) do fn(...) end
    end

    -- Saved per-player table. `floor` is reset whenever the floor changes.
    function self.State(player)
        local key = slot(player)
        if not key then return nil end
        local players = savedPlayers()
        if not players then
            Risk.state.backlog = { version = VERSION, players = {}, cleared = {} }
            players = savedPlayers()
        end
        local s = players[key]
        if type(s) ~= "table" then s = {}; players[key] = s end
        local floor = Common.FloorKey()
        if s.floorKey ~= floor or type(s.floor) ~= "table" then
            local previous, old = s.floorKey, s.floor
            s.floorKey, s.floor = floor, {}
            if previous ~= nil and type(old) == "table" then emit("floorChanged", player, s, old) end
        end
        return s
    end

    -- Existing saved table only; never creates state for players without it.
    function self.Peek(player)
        local players, key = savedPlayers(), slot(player)
        if not players or not key or type(players[key]) ~= "table" then return nil end
        return self.State(player)
    end

    -- Safe number read from saved state.
    function self.Num(v, default, low, high)
        if type(v) ~= "number" or v ~= v then return default end
        if low and v < low then return default end
        if high and v > high then return default end
        return v
    end

    -- Transient per-player table, room-scoped part cleared on each new room.
    function self.Data(player)
        local data = player:GetData()
        data.ccBacklog = data.ccBacklog or { room = {} }
        return data.ccBacklog
    end

    -- Stat registry: fn(player) returns a multiplier (damage) or an addition.
    function self.Stat(kind, fn) table.insert(stats[kind], fn) end
    function self.Refresh(player)
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SPEED
            | CacheFlag.CACHE_RANGE | CacheFlag.CACHE_SHOTSPEED)
        player:EvaluateItems()
    end
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if flag == CacheFlag.CACHE_DAMAGE then
            local m = 1
            for _, fn in ipairs(stats.damage) do m = m * (fn(player) or 1) end
            if m ~= 1 then player.Damage = player.Damage * m end
        elseif flag == CacheFlag.CACHE_SPEED then
            local add = 0
            for _, fn in ipairs(stats.speed) do add = add + (fn(player) or 0) end
            if add ~= 0 then player.MoveSpeed = player.MoveSpeed + add end
        elseif flag == CacheFlag.CACHE_RANGE then
            local add = 0
            for _, fn in ipairs(stats.range) do add = add + (fn(player) or 0) end
            if add ~= 0 then player.TearRange = player.TearRange + add end
        elseif flag == CacheFlag.CACHE_SHOTSPEED then
            local add = 0
            for _, fn in ipairs(stats.shotspeed) do add = add + (fn(player) or 0) end
            if add ~= 0 then player.ShotSpeed = player.ShotSpeed + add end
        end
    end)

    -- Primed bonuses for the player's next attack. Passive rewards may require
    -- continued ownership; completed active rewards omit requiredItem.
    local function availablePrime(player, prime, frame)
        return (not prime.expires or prime.expires >= frame)
            and (not prime.requiredItem or player:HasCollectible(prime.requiredItem))
    end
    function self.Prime(player, key, mult, frames, requiredItem)
        local d = self.Data(player)
        d.primes = d.primes or {}
        d.primes[key] = { mult = mult, expires = frames and (now() + frames) or nil,
            requiredItem = requiredItem }
    end
    function self.Primed(player, key)
        local d = self.Data(player)
        local p = d.primes and d.primes[key]
        return p ~= nil and availablePrime(player, p, now())
    end
    function self.Unprime(player, key)
        local d = self.Data(player)
        if d.primes then d.primes[key] = nil end
    end

    function self.LastAttack(player) return lastAttack[GetPtrHash(player)] end

    local function attack(player, kind, entity)
        local hash, frame = GetPtrHash(player), now()
        local volley = volleys[hash]
        if not volley or volley.frame ~= frame then
            -- A new attack: resolve and consume primes once for the whole volley.
            local d = self.Data(player)
            local mult = 1
            for key, p in pairs(d.primes or {}) do
                -- Inventory can change between an update and the attack. Once
                -- resolved, the volley/weapon lease keeps its original factor.
                if availablePrime(player, p, frame) then mult = mult * p.mult end
                d.primes[key] = nil
            end
            volley = { frame = frame, mult = mult, id = tostring(hash) .. ":" .. frame }
            volleys[hash] = volley
            lastAttack[hash] = frame
            emit("attack", player, kind, entity, volley.id)
        end
        leases[GetPtrHash(entity)] = { id = volley.id, mult = volley.mult, kind = kind,
            owner = hash, expires = frame + ATTACK_LEASE }
    end
    self.attack = attack

    local function laserParent(entity)
        if entity and entity.Type == EntityType.ENTITY_LASER and entity.Parent
            and entity.Parent.Type == EntityType.ENTITY_LASER then return entity.Parent end
    end
    local childLaserKey = {}
    local function childLaser(entity)
        if not entity or entity.Type ~= EntityType.ENTITY_LASER then return false end
        local data = entity:GetData()
        if laserParent(entity) then data[childLaserKey] = true end
        -- Keep the classification if the engine clears a removed parent.
        return data[childLaserKey] == true
    end
    local function liveLease(entity)
        local hash = GetPtrHash(entity)
        local lease = leases[hash]
        if lease and lease.expires < now() then leases[hash] = nil; return nil end
        return lease
    end
    local function inheritLaserLease(laser)
        local current, seen, owner = laser, {}, nil
        while current do
            local hash = GetPtrHash(current)
            if seen[hash] then return nil end
            seen[hash] = true
            local lease = liveLease(current)
            local player, familiar = Common.Owner(current)
            if familiar then return nil end
            local spawner = current.SpawnerEntity
            if spawner and not spawner:ToPlayer() then
                if spawner.Type ~= EntityType.ENTITY_LASER then return nil end
                local parent = laserParent(current)
                if not lease and (not parent or GetPtrHash(spawner) ~= GetPtrHash(parent)) then return nil end
                local sourcePlayer, sourceFamiliar = Common.Owner(spawner)
                if sourceFamiliar then return nil end
                if sourcePlayer then
                    if player and GetPtrHash(player) ~= GetPtrHash(sourcePlayer) then return nil end
                    player = sourcePlayer
                end
            end
            if player then
                local pointer = GetPtrHash(player)
                if owner and owner ~= pointer then return nil end
                owner = pointer
            end
            if lease then
                if lease.kind ~= "laser" or (owner and owner ~= lease.owner) then return nil end
                -- Keep the parent's attack identity, resolved multiplier and
                -- original expiry, even if the parent later disappears.
                leases[GetPtrHash(laser)] = lease
                return lease
            end
            current = laserParent(current)
        end
        -- A child seen first may retry later; never pay for a missing parent.
    end

    -- Fire a native tear that is not an attack itself (no primes, no events).
    function self.FireDerived(player, velocity, mult, position)
        -- FireTear dispatches synchronously. Earlier consumers (including Opus)
        -- need this owner-scoped marker before our tear callback can mark it.
        local data = player:GetData()
        local previous = data.ccDerivedTearDepth
        data.ccDerivedTearDepth = (previous or 0) + 1
        local ok, tear = pcall(player.FireTear, player, position or player.Position,
            velocity, false, true, false, player, mult)
        data.ccDerivedTearDepth = previous
        if not ok then error(tear, 0) end
        if tear then leases[GetPtrHash(tear)] = { id = "derived", mult = 1, kind = "derived",
            owner = GetPtrHash(player), expires = now() + ATTACK_LEASE } end
        return tear
    end

    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
        if player and (player:GetData().ccDerivedTearDepth or 0) > 0 then
            -- Mark before character consumers; another player's synchronous
            -- attack must not inherit this helper's exemption.
            tear:GetData().ccThoughtDerived = true
            return
        end
        if tear:GetData().ccThoughtDerived then return end
        if player then attack(player, "tear", tear) end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, function(_, laser)
        -- Parent may disappear before the first update. Retain a known child
        -- and any already resolved bonus without creating a primary attack.
        if childLaser(laser) then inheritLaserLease(laser) end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, function(_, laser)
        if childLaser(laser) then inheritLaserLease(laser); return end
        if laser.FrameCount ~= 1 then return end
        local player = laser.SpawnerEntity and laser.SpawnerEntity:ToPlayer()
        if player then attack(player, "laser", laser) end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE, function(_, knife)
        local data = knife:GetData()
        local flying = knife:IsFlying()
        if flying and not data.ccBacklogFlying then
            local player, familiar = Common.Owner(knife)
            if player and not familiar then attack(player, "knife", knife) end
        end
        data.ccBacklogFlying = flying
    end)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, function(_, bomb)
        if bomb.FrameCount ~= 1 or not bomb.IsFetus then return end
        local player = bomb.SpawnerEntity and bomb.SpawnerEntity:ToPlayer()
        if player then attack(player, "bomb", bomb) end
    end)

    -- Target damage modifiers: fn(npc, player, lease) returns a multiplier.
    local modifiers = {}
    function self.TargetModifier(fn) table.insert(modifiers, fn) end

    -- One extra hit that is never an attack, a lease or a modifier input.
    function self.Pulse(npc, player, mult)
        if not Common.Hostile(npc) then return end
        dealing = true
        npc:TakeDamage(player.Damage * mult, 0, EntityRef(player), 0)
        dealing = false
    end

    local function realHit(flags)
        return ((flags or 0) & (DamageFlag.DAMAGE_FAKE | DamageFlag.DAMAGE_NO_PENALTIES)) == 0
    end
    local function enemySource(source)
        local e = source and source.Entity
        if not e then return nil end
        if e.Type == EntityType.ENTITY_PROJECTILE then return e end
        local npc = e:ToNPC()
        if npc and not npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then return e end
    end
    self.EnemySource = enemySource

    -- Guards absorb one ordinary hostile bullet hit each.
    function self.AddGuard(player, key, frames, max)
        local hash = GetPtrHash(player)
        guards[hash] = guards[hash] or {}
        local list = guards[hash]
        local count = 0
        for _, g in ipairs(list) do if g.key == key and g.expires >= now() then count = count + 1 end end
        if count >= (max or 1) then return false end
        list[#list + 1] = { key = key, expires = now() + frames }
        return true
    end
    function self.Guards(player, key)
        local count = 0
        for _, g in ipairs(guards[GetPtrHash(player)] or {}) do
            if (not key or g.key == key) and g.expires >= now() then count = count + 1 end
        end
        return count
    end

    -- Contact blockers cancel a player hit before any hit event is emitted.
    local blockers = {}
    function self.BlockContact(fn) table.insert(blockers, fn) end

    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, countdown)
        if dealing then return nil end
        local player = entity:ToPlayer()
        if player then
            local e = source and source.Entity
            if e then
                for _, fn in ipairs(blockers) do if fn(player, e) then return false end end
            end
            local enemy = enemySource(source)
            local list = guards[GetPtrHash(player)]
            if list and #list > 0 and enemy and realHit(flags) and Common.OrdinaryBullet(enemy) then
                for i, g in ipairs(list) do
                    if g.expires >= now() then
                        table.remove(list, i)
                        enemy:Remove()
                        emit("guarded", player, g.key)
                        return false
                    end
                end
            end
            if realHit(flags) then
                hitThisRoom[GetPtrHash(player)] = true
                if enemy then emit("playerHit", player, enemy, amount) end
            end
            return nil
        end
        local npc = entity:ToNPC()
        if not npc or npc:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then return nil end
        local src = source and source.Entity
        local owner, familiar = Common.Owner(src)
        local lease
        if childLaser(src) then
            lease = inheritLaserLease(src)
            if lease then
                -- A child may name its laser spawner instead of the player.
                -- Only a current owner matching the resolved lease can use it.
                local inherited
                for _, p in ipairs(Common.Players()) do
                    if GetPtrHash(p) == lease.owner then inherited = p; break end
                end
                if inherited then owner, familiar = inherited, false else lease = nil end
            end
        elseif src then lease = liveLease(src) end
        if not owner then return nil end
        local kind = lease and lease.kind or (familiar and "familiar") or (src:ToPlayer() and "contact") or "other"
        local mult = lease and lease.mult or 1
        for _, fn in ipairs(modifiers) do mult = mult * (fn(npc, owner, kind, lease) or 1) end
        emit("hit", npc, owner, kind, lease and lease.id ~= "derived" and lease.id or nil, amount * mult)
        if mult ~= 1 and mult > 0 then
            dealing = true
            npc:TakeDamage(amount * mult, flags, source, countdown)
            dealing = false
            return false
        end
        return nil
    end)

    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
        local npc = entity:ToNPC()
        if npc then emit("kill", npc) end
    end)

    -- Timers count gameplay updates (paused frames do not run POST_UPDATE).
    function self.After(frames, fn, roomScoped)
        timers[#timers + 1] = { at = now() + frames, fn = fn, room = roomScoped }
    end

    -- Temporary helpers created by backlog items (decoys, wisps), never vanilla familiars.
    function self.AddHelper(player, entity, kind)
        local hash = GetPtrHash(player)
        helpers[hash] = helpers[hash] or {}
        table.insert(helpers[hash], { ref = EntityPtr(entity), kind = kind })
    end
    function self.Helpers(player)
        local out, list = {}, helpers[GetPtrHash(player)] or {}
        for i = #list, 1, -1 do
            local e = list[i].ref.Ref
            if e and e:Exists() then table.insert(out, 1, { entity = e, kind = list[i].kind })
            else table.remove(list, i) end
        end
        return out
    end

    function self.Label(player, key, text)
        labels[GetPtrHash(player)] = labels[GetPtrHash(player)] or {}
        labels[GetPtrHash(player)][key] = text
    end

    function self.HitThisRoom(player) return hitThisRoom[GetPtrHash(player)] == true end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        -- Module-local effects must not rely on NEW_ROOM arriving after start.
        -- This is cleanup only: never synthesize a room-entry reward event.
        emit("runReset")
        started = true
        owners:Reset()
        leases, volleys, guards, timers, helpers, labels, pendingUse, hitThisRoom, lastAttack = {}, {}, {}, {}, {}, {}, {}, {}, {}
        for _, p in ipairs(Common.Players()) do p:GetData().ccBacklog = nil end
        emit("started", continued)
        for _, p in ipairs(Common.Players()) do self.Refresh(p) end
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        started = false
        emit("runReset")
        owners:Reset()
        timers, pendingUse = {}, {}
    end)

    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        leases, volleys, hitThisRoom = {}, {}, {}
        for i = #timers, 1, -1 do if timers[i].room then table.remove(timers, i) end end
        for _, p in ipairs(Common.Players()) do
            local d = self.Data(p)
            local hadRoom = next(d.room) ~= nil
            d.room = {}
            labels[GetPtrHash(p)] = nil
            if hadRoom then self.Refresh(p) end
        end
        if not started then return end
        emit("newRoom", Game():GetRoom())
    end)

    -- Settle floor-scoped state for every player as soon as a floor begins.
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        local players = started and savedPlayers()
        if not players then return end
        for _, p in ipairs(Common.Players()) do
            local key = slot(p)
            if key and players[key] then self.State(p) end
        end
    end)

    -- Unique clears are only tracked while someone holds an item that uses them.
    local clearItems = {}
    function self.WatchClears(id) clearItems[#clearItems + 1] = id end
    local function anyClearHolder()
        for _, p in ipairs(Common.Players()) do
            for _, id in ipairs(clearItems) do if id > 0 and p:HasCollectible(id) then return true end end
        end
        return false
    end

    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not started or not anyClearHolder() then return end
        local all = Risk.state.backlog
        if type(all) ~= "table" or all.version ~= VERSION then
            if #Common.Players() > 0 then self.State(Isaac.GetPlayer(0)) end
            all = Risk.state.backlog
        end
        if type(all.cleared) ~= "table" or all.clearedFloor ~= Common.FloorKey() then
            all.cleared, all.clearedFloor = {}, Common.FloorKey()
        end
        local key = Common.RoomKey()
        if all.cleared[key] then return end
        all.cleared[key] = true
        emit("uniqueClear", function(player) return not hitThisRoom[GetPtrHash(player)] end)
    end)

    mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function(_, id, _, player, flags, slotId)
        -- Only a real slot can lose charge; Void and similar uses report -1.
        if not player or Common.Battery(flags) or (flags & UseFlag.USE_OWNED) == 0
            or not slotId or slotId < 0 then return nil end
        local config = Isaac.GetItemConfig():GetCollectible(id)
        if not config or config.MaxCharges <= 0 or config.ChargeType ~= 0 then return nil end
        pendingUse[#pendingUse + 1] = { player = player, id = id, slot = slotId,
            charge = player:GetActiveCharge(slotId) + player:GetBatteryCharge(slotId),
            item = player:GetActiveItem(slotId), frame = now() }
        return nil
    end)

    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not started then return end
        -- Notice a changed slot owner before anything saves, and give both
        -- players of a moved table the stats of their own state.
        if savedPlayers() then
            for key in pairs(owners:TakeMoved()) do
                local p = Isaac.GetPlayer(tonumber(key))
                if p then self.Refresh(p) end
            end
        end
        local frame = now()
        -- Include The Battery's second bar; moving charge between bars is not a use.
        for i = #pendingUse, 1, -1 do
            local u = pendingUse[i]
            local after = u.player:GetActiveCharge(u.slot) + u.player:GetBatteryCharge(u.slot)
            if u.player:GetActiveItem(u.slot) ~= u.item or after < u.charge then
                table.remove(pendingUse, i)
                emit("activeUsed", u.player, u.id, Game():GetRoom():IsClear())
            elseif frame - u.frame > 1 then
                table.remove(pendingUse, i)
            end
        end
        for i = #timers, 1, -1 do
            local t = timers[i]
            if t.at <= frame then table.remove(timers, i); t.fn() end
        end
        emit("update", frame)
    end)

    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not started or not Game():GetHUD():IsVisible() then return end
        for _, p in ipairs(Common.Players()) do
            local list = labels[GetPtrHash(p)]
            if list then
                local pos = Isaac.WorldToScreen(p.Position)
                local y = pos.Y + 6
                for _, text in pairs(list) do
                    Isaac.RenderText(text, pos.X - 3 * #text, y, 1, 1, 1, 0.8)
                    y = y + 10
                end
            end
        end
    end)

    return self
end

return Common
