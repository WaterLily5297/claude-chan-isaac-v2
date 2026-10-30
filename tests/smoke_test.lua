-- Minimal stub of the Isaac API to smoke-test the mod's callbacks.
local root = arg[1]
package.path = root .. "/?.lua;" .. package.path

local callbacks = {}
local saved
local mod = {}
function mod:AddCallback(id, fn, param)
    table.insert(callbacks, { id = id, fn = fn, param = param, priority = 0, order = #callbacks + 1 })
end
function mod:AddPriorityCallback(id, priority, fn, param)
    self:AddCallback(id, fn, param)
    callbacks[#callbacks].priority = priority
end
function mod:SaveData(s) saved = s end
function mod:HasData() return saved ~= nil end
function mod:LoadData() return saved end
function RegisterMod() return mod end
function GetPtrHash(entity) return entity end

function include(name)
    return dofile(root .. "/" .. name:gsub("%.", "/") .. ".lua")
end

-- Snapshot stub preserves nested run-state tables without sharing references.
-- Real JSON serialization remains an engine acceptance check.
package.preload.json = function()
    local snapshots = {}
    local function copy(value)
        if type(value) ~= "table" then return value end
        local result = {}
        for key, entry in pairs(value) do result[key] = copy(entry) end
        return result
    end
    return {
        encode = function(t)
            snapshots[#snapshots + 1] = copy(t)
            return tostring(#snapshots)
        end,
        decode = function(s)
            return copy(assert(snapshots[tonumber(s)], "invalid snapshot"))
        end,
    }
end

DoorSlot = { NUM_DOOR_SLOTS = 8 }
TearFlags = { TEAR_HOMING = "homing", TEAR_PIERCING = "piercing", TEAR_SPECTRAL = "spectral", TEAR_POISON = "poison", TEAR_SLOW = "slow" }
PickupVariant = { PICKUP_COLLECTIBLE = 100, PICKUP_LOCKEDCHEST = 60, PICKUP_COIN = 20 }
ModCallbacks = setmetatable({}, { __index = function(_, k) return k end })
CallbackPriority = { DEFAULT = 0, LATE = 1000 }
EffectVariant = { TARGET = 30, ROCKET = 31 }
EntityType = { ENTITY_PLAYER = 1, ENTITY_TEAR = 2, ENTITY_PROJECTILE = 9, ENTITY_CLOTTY = 15 }
CacheFlag = { CACHE_DAMAGE = 1, CACHE_RANGE = 2, CACHE_SHOTSPEED = 4, CACHE_SPEED = 8, CACHE_TEARCOLOR = 16, CACHE_FIREDELAY = 32, CACHE_FLYING = 64 }
ActiveSlot = { SLOT_PRIMARY = 0, SLOT_POCKET = 2 }
UseFlag = { USE_CARBATTERY = 32 }
EntityFlag = { FLAG_FRIENDLY = 1, FLAG_CHARM = 256 }
DamageFlag = { DAMAGE_EXPLOSION = 4, DAMAGE_RED_HEARTS = 32, DAMAGE_IV_BAG = 4096, DAMAGE_FAKE = 2097152, DAMAGE_NO_PENALTIES = 268435456 }
function Color(...) return { ... } end
SoundEffect = { SOUND_POWERUP_SPEWER = 132 }
function SFXManager() return { Play = function(_, id) print("  SFX:", id) end } end
Vector = { Zero = { 0, 0 } }
Input = { IsActionPressed = function() return false end }
CollectibleType = { COLLECTIBLE_BIRTHRIGHT = 619 }
ButtonAction = { ACTION_MAP = 11, ACTION_SHOOTLEFT = 4, ACTION_SHOOTRIGHT = 5,
    ACTION_SHOOTUP = 6, ACTION_SHOOTDOWN = 7 }
InputHook = { IS_ACTION_PRESSED = 0, IS_ACTION_TRIGGERED = 1, GET_ACTION_VALUE = 2 }
function EntityRef(e) return e end

local items = { ["Ban Hammer"] = 733, ["Residential IP"] = 734, ["Compact"] = 735, ["You're Absolutely Right!"] = 736, ["9.9 Yuan Relay"] = 737, ["Ultrathink"] = 738, ["1M Context"] = 739, ["Silent Update"] = 740, ["--dangerously-skip-permissions"] = 741, ["All Tests Passing"] = 742, ["Vibe Coding"] = 743, ["Banked Reset"] = 744, ["Subagent Swarm"] = 745, ["The Constitution"] = 746, ["Support Ticket"] = 748, ["Opus Mode"] = 747, ["Lunch Break"] = 749 }
local playerItems = {}
items["Summary Stapler"] = 750
Isaac = {}
function Isaac.GetItemIdByName(n) return items[n] or -1 end
function Isaac.GetTrinketIdByName(n) return ({ ["529 Overloaded"] = 190, ["Hardcoded Output"] = 191, ["Thinking Cleared"] = 192, ["Welcome Notice"] = 193, ["Status Page"] = 194, ["Appeal Form"] = 195 })[n] or -1 end
ROOMFRAME, ROOMCLEAR = 0, false
function Isaac.GetPillEffectByName(n) return ({ ["Cat-girl Mode"] = 50, ["Brb, Getting Food"] = 51 })[n] or -1 end
function Isaac.GetPlayerTypeByName(n, tainted)
    local ids = { ["Claude-chan"] = 41, ["DeepSeek-chan"] = 42 }
    return ids[n] and ids[n] + (tainted and 100 or 0) or -1
end
function Isaac.GetScreenHeight() return 270 end
function Isaac.RenderText(s) print("  HUD: " .. s) end
local pdata = {}
local player = { HasCollectible = function(_, id) return playerItems[id] end,
    GetPlayerType = function() return 41 end, GetData = function() return pdata end,
    SetPocketActiveItem = function(self, id) self.pocket = id end,
    FireDelay = 0, charge = 4, coins = 40, hearts = 2, MaxFireDelay = 10,
    AddHearts = function(self, n) self.hearts = self.hearts + n end, soul = 0,
    AddSoulHearts = function(self, n) self.soul = self.soul + n end,
    GetNumCoins = function(self) return self.coins end, AddCoins = function(self, n) self.coins = self.coins + n end,
    GetActiveCharge = function(self) return self.charge end, SetActiveCharge = function(self, c) self.charge = c end, HasTrinket = function(_, id) return HELD_TRINKET == id end,
    TearRange = 260, ShotSpeed = 1, MoveSpeed = 1, Damage = 3.5,
    AddCacheFlags = function() end,
    EvaluateItems = function(self) self.Damage = 3.5; for _, cb in ipairs(callbacks) do if cb.id == "MC_EVALUATE_CACHE" then cb.fn(mod, self, CacheFlag.CACHE_DAMAGE) end end end }
player.ToPlayer = function(self) return self end
player.Position = {X=0,Y=0,Distance=function(self, other)
    return math.sqrt((self.X-other.X)^2+(self.Y-other.Y)^2)
end}
player.IsDead = function() return false end
player.InitSeed, player.ControllerIndex = 1, 0
player.AreControlsEnabled = function() return true end
player.GetShootingInput = function() return { LengthSquared = function() return 0 end } end
player.GetMovementInput = function() return { LengthSquared = function() return 0 end } end
player.TryRemoveTrinket = function(_, id) if HELD_TRINKET == id then HELD_TRINKET = nil; return true end return false end
function Isaac.GetPlayer() return player end

local spawned = 0
local npcSeed = 1000
local function makeNpc(boss)
    local data = {}
    npcSeed = npcSeed + 1
    local npc = { InitSeed=npcSeed, Type = 10, Variant = 0, SubType = 0, Position = {X=50,Y=0}, MaxHitPoints = 10, HitPoints = 10, CanShutDoors = true }
    function npc:ToNPC() return self end
    function npc:Exists() return not self.removed end
    function npc:IsEnemy() return true end
    function npc:IsVulnerableEnemy() return true end
    function npc:IsBoss() return boss end
    function npc:HasEntityFlags(f) return f == EntityFlag.FLAG_CHARM and self.charmed ~= nil end
    function npc:IsDead() return self.dead == true end
    function npc:GetData() return data end
    function npc:TakeDamage(d) self.HitPoints = self.HitPoints - d end
    function npc:Kill() self.dead = true end
    function npc:AddConfusion(_, f) self.confused = f end
    function npc:AddCharmed(_, f) self.charmed = f end
    function npc:AddFreeze(_, f) self.frozen = (self.frozen or 0) + 1 end
    function npc:AddSlowing(_, f) self.slowed = f end
    return npc
end
local roomEntities = {}
SPAWNED = {}
function Isaac.GetFreeNearPosition(p) return p end
function Isaac.Spawn(t, v, st, pos, vel)
    spawned = spawned + 1
    if t == 15 then local n = makeNpc(false); n.Type = 15; SPAWNED[#SPAWNED + 1] = n; return n end
    if t == 2 then
        local tr = { vel = vel }
        function tr:ToTear() return self end
        function tr:ResetSpriteScale() self.spriteScale=self.Scale end
        local data={}; function tr:GetData() return data end
        return tr
    end
    return makeNpc(false)
end
function Isaac.GetRoomEntities() return roomEntities end

local stage = 1
function RNG()
    local r = { s = 1 }
    function r:SetSeed(s) assert(s > 0); self.s = s end
    function r:RandomInt(n) self.s = (self.s * 1103515245 + 12345) % 2147483648; return self.s % n end
    function r:RandomFloat() return self:RandomInt(10000) / 10000 end
    return r
end
local hudVisible = true
function Game()
    return {
        GetNumPlayers = function() return 1 end,
        GetLevel = function() return { GetStage = function() return stage end,
            GetStageType = function() return 0 end, GetDungeonPlacementSeed = function() return 77 end,
            GetCurrentRoomDesc = function() return { SpawnSeed = 1, SafeGridIndex = 84 } end } end,
        GetSeeds = function() return { GetStartSeed = function() return 123456 end } end,
        GetHUD = function() return {
            IsVisible = function() return hudVisible end,
            ShowItemText = function(_, a, b) print("  ITEMTEXT: " .. a .. " / " .. b) end,
        } end,
        ShakeScreen = function() end,
        GetFrameCount = function() return FRAME end,
        IsPaused = function() return false end,
        GetRoom = function() return { IsFirstVisit = function() return FIRSTVISIT ~= false end, GetDoor = function(_, slot) return DOORS[slot] end, SetClear = function(_, v) ROOMCLEAR = v end, IsClear = function() return ROOMCLEAR end, GetFrameCount = function() return ROOMFRAME end, GetCenterPos = function() return { 0, 0 } end } end,
    }
end

local function fire(id, param, ...)
    if id == "MC_POST_FIRE_TEAR" then
        local tear = ...
        -- Shared entity API for the lightweight tear fixtures below.
        tear.Exists = tear.Exists or function(self) return not self.removed end
        local data={}; tear.GetData=tear.GetData or function() return data end
    end
    local ret
    local selected = {}
    for _, cb in ipairs(callbacks) do
        if cb.id == id and (cb.param == nil or param == nil or cb.param == param) then
            selected[#selected + 1] = cb
        end
    end
    table.sort(selected, function(a, b)
        if a.priority == b.priority then return a.order < b.order end
        return a.priority < b.priority
    end)
    for _, cb in ipairs(selected) do ret = cb.fn(mod, ...) or ret end
    return ret
end

FRAME = 0
local realInclude = include
include = function(name) local m = realInclude(name); if name == "scripts.risk" and not RISK_REF then RISK_REF = m end; return m end
dofile(root .. "/main.lua")

local hasRuntimeProbe = false
for _, callback in ipairs(callbacks) do
    if callback.id == "ClaudeChan:RunRuntimeProbe" then hasRuntimeProbe = true end
end
assert(hasRuntimeProbe, "main.lua must finish registration after optional integrations")

-- Verify the new active is actually registered through the entry point.
assert(fire("MC_USE_ITEM", 750, 750, nil, player, 0).Discharge == false,
    "Summary Stapler must preserve charge in an empty room")
include = realInclude
local Risk = include("scripts.risk") -- fresh copy just for reading constants; real state lives in main's instance

print("== new run")
fire("MC_POST_NEW_LEVEL")          -- fires before game start: should be ignored
fire("MC_POST_GAME_STARTED", nil, false)
fire("MC_POST_RENDER")

print("== floors 2..8, take a hit each floor")
for s = 2, 8 do
    stage = s
    fire("MC_POST_NEW_LEVEL")
    fire("MC_POST_NEW_ROOM")
    fire("MC_ENTITY_TAKE_DMG", EntityType.ENTITY_PLAYER, player)
end
fire("MC_POST_RENDER")

print("== clean room clear")
fire("MC_POST_NEW_ROOM"); fire("MC_PRE_SPAWN_CLEAN_AWARD"); fire("MC_POST_RENDER")

print("== enemy scaling")
local e = makeNpc(false); fire("MC_POST_NPC_INIT", nil, e)
print("  enemy HP 10 ->", e.MaxHitPoints)

print("== hydra (50 kills)")
for _ = 1, 50 do fire("MC_POST_ENTITY_KILL", nil, makeNpc(false)) end
print("  respawned:", spawned)

print("== ban hammer")
local normal, boss = makeNpc(false), makeNpc(true)
boss.HitPoints = 100
roomEntities = { normal, boss }
local before = spawned
print("  use returns", fire("MC_USE_ITEM", 733, 733, nil, player))
print("  normal dead:", normal.dead, "boss HP:", boss.HitPoints)
fire("MC_POST_ENTITY_KILL", nil, normal)
print("  banned enemy respawned:", spawned > before)

print("== residential ip")
playerItems[734] = true
fire("MC_POST_PEFFECT_UPDATE", nil, player)
fire("MC_POST_PEFFECT_UPDATE", nil, player) -- must apply only once
fire("MC_POST_RENDER")

print("== save / continue")
fire("MC_PRE_GAME_EXIT", nil, true)
fire("MC_POST_RENDER") -- not started: no output
fire("MC_POST_NEW_LEVEL")
fire("MC_POST_GAME_STARTED", nil, true)
fire("MC_POST_RENDER")

print("== claude-chan")
print("  pocket item:", player.pocket)
for _, f in pairs(CacheFlag) do fire("MC_EVALUATE_CACHE", nil, player, f) end
print("  range/shotspeed/speed:", player.TearRange, player.ShotSpeed, player.MoveSpeed, "tearcolor set:", player.TearColor ~= nil)
FRAME = 0
local fired, limitedAt = 0, nil
for f = 1, 900 do
    FRAME = f
    if f % 11 == 0 then
        local tear = { SpawnerEntity = player, CollisionDamage = 3.5 }
        fire("MC_POST_FIRE_TEAR", nil, tear)
        fired = fired + 1
        if pdata.ccUsage.limited > 0 and not limitedAt then limitedAt = f end
        if pdata.ccUsage.limited > 0 and pdata.ccUsage.limited < 150 and not shownWeak then
            shownWeak = true; print("  limited tear damage:", tear.CollisionDamage)
        end
    end
    fire("MC_POST_PEFFECT_UPDATE", nil, player)
    if f == limitedAt then fire("MC_POST_RENDER") end
end
print("  hit usage limit at frame", limitedAt, "(" .. (limitedAt or 0) / 30 .. "s of firing)")
fire("MC_POST_RENDER")

print("== compact")
local proj = { Type = 9, ToNPC = function() return nil end, Remove = function(self) self.removed = true end }
local foe = makeNpc(false); foe.Type = 10
roomEntities = { proj, foe }
pdata.ccUsage.limited = 0; pdata.ccUsage.value = 10
fire("MC_USE_ITEM", 735, 735, nil, player)
print("  projectile removed:", proj.removed, "enemy confused:", foe.confused, "usage:", pdata.ccUsage.value)
assert(pdata.ccUsage.value == 60, "Compact costs Claude 50 usage")
fire("MC_USE_ITEM", 735, 735, nil, player, UseFlag.USE_CARBATTERY)
assert(pdata.ccUsage.value == 60, "Car Battery's repeat use must not bill Compact again")
-- F1: reaching 100 through Compact starts Limited at once, with the same
-- countdown as the attack path above; below 100 it stays a plain cost.
assert(pdata.ccUsage.limited == 0, "Compact below the cap must not start Limited")
fire("MC_USE_ITEM", 735, 735, nil, player)
assert(pdata.ccUsage.value == 100 and pdata.ccUsage.limited == 150, "Compact reaching 100 starts Limited")
FRAME = FRAME + 1; fire("MC_POST_PEFFECT_UPDATE", nil, player)
assert(player.Damage < 3.5, "the Limited penalty applies on the next update")
fire("MC_USE_ITEM", 735, 735, nil, player)
assert(pdata.ccUsage.limited == 149, "Compact during Limited neither bills nor restarts it")
pdata.ccUsage.limited = 0; pdata.ccUsage.value = 0
FRAME = FRAME + 1; fire("MC_POST_PEFFECT_UPDATE", nil, player)
assert(player.Damage == 3.5, "clearing Limited restores damage")

print("== absolutely right")
playerItems[736] = true
local shooter = makeNpc(false)
local bullet = { Type = 9, SpawnerEntity = shooter, ToNPC = function() return nil end }
fire("MC_ENTITY_TAKE_DMG", EntityType.ENTITY_PLAYER, player, 1, 0, { Entity = bullet })
print("  shooter charmed:", shooter.charmed)

print("== 9.9 yuan relay")
local r0 = Risk and nil
playerItems[737] = true
fire("MC_POST_PEFFECT_UPDATE", nil, player); fire("MC_POST_PEFFECT_UPDATE", nil, player)
local swaps, rooms = 0, 40
for _ = 1, rooms do fire("MC_POST_NEW_ROOM"); if player.Damage < 3.5 then swaps = swaps + 1 end end
print("  swapped rooms:", swaps .. "/" .. rooms, "damage now:", player.Damage)
fire("MC_POST_RENDER")

print("== ultrathink")
playerItems[737] = nil
fire("MC_POST_NEW_ROOM"); player:EvaluateItems()
local base = player.Damage
for _ = 1, 5 do fire("MC_USE_ITEM", 738, 738, nil, player); print("  damage:", player.Damage) end
fire("MC_POST_NEW_ROOM"); print("  after leaving room:", player.Damage, "(base " .. base .. ")")

print("== 1m context")
playerItems[739] = true
player.TearRange = 260; fire("MC_EVALUATE_CACHE", nil, player, CacheFlag.CACHE_RANGE)
print("  range:", player.TearRange)
local tdata = {}
local tear = { SpawnerEntity = player, CollisionDamage = 3.5, FrameCount = 0, GetData = function() return tdata end }
for _, f in ipairs({0, 30, 60, 90, 120}) do tear.FrameCount = f; fire("MC_POST_TEAR_UPDATE", nil, tear); print("  frame " .. f .. " damage:", tear.CollisionDamage) end

print("== 529 overloaded")
local victim = makeNpc(false); roomEntities = { victim }
HELD_TRINKET = 190
for f = 0, 1799 do ROOMFRAME = f; fire("MC_POST_UPDATE") end
print("  outages in 60s:", victim.frozen, "player fire delay:", player.FireDelay)
ROOMCLEAR = true; victim.frozen = 0
for f = 0, 1799 do ROOMFRAME = f; fire("MC_POST_UPDATE") end
print("  outages in cleared room:", victim.frozen)

print("== silent update")
playerItems[739] = nil; playerItems[740] = true
for st = 1, 5 do stage = st; fire("MC_POST_NEW_LEVEL"); print(string.format("  floor %d damage: %.2f", st, player.Damage)) end

print("== skip permissions")
playerItems[740] = nil; playerItems[741] = true
local unlocked, opened, removed, rooms = 0, 0, 0, 100
for _ = 1, rooms do
    DOORS = { [0] = { locked = true, IsLocked = function(self) return self.locked end, TryUnlock = function(self) self.locked = false; unlocked = unlocked + 1 end } }
    local function pk(v) return { Variant = v, ToPickup = function(self) return self end, Remove = function() removed = removed + 1 end, TryOpenChest = function() opened = opened + 1 end } end
    roomEntities = { pk(60), pk(20), pk(100) }
    fire("MC_POST_NEW_ROOM")
end
print("  doors unlocked:", unlocked, "chests opened:", opened, "pickups deleted:", removed, "(over " .. rooms .. " rooms)")

print("== tests passing")
playerItems[741] = nil
ROOMCLEAR = false
local opened = 0
DOORS = { [0] = { Open = function() opened = opened + 1 end }, [3] = { Open = function() opened = opened + 1 end } }
fire("MC_USE_ITEM", 742, 742, nil, player)
print("  room clear:", ROOMCLEAR, "doors opened:", opened)

print("== hardcoded output")
HELD_TRINKET = 191
local strong = { SpawnerEntity = player, CollisionDamage = 12 }
fire("MC_POST_FIRE_TEAR", nil, strong)
print("  12 damage tear ->", strong.CollisionDamage)

print("== thinking cleared")
HELD_TRINKET = 192; DOORS = {}; roomEntities = {}
fire("MC_POST_NEW_ROOM"); print("  damage:", player.Damage, "charge:", player.charge)
fire("MC_POST_NEW_ROOM"); print("  damage:", player.Damage, "charge:", player.charge)
HELD_TRINKET = nil
fire("MC_POST_NEW_ROOM"); print("  dropped -> damage:", player.Damage, "charge:", player.charge)

print("== vibe coding")
HELD_TRINKET = nil; playerItems[743] = true
local counts, bugs = {}, 0
for _ = 1, 200 do
    local t = { SpawnerEntity = player, Velocity = 10, CollisionDamage = 3.5, AddTearFlags = function(_, f) counts[f] = (counts[f] or 0) + 1 end }
    fire("MC_POST_FIRE_TEAR", nil, t)
    if t.Velocity == -10 then bugs = bugs + 1 end
end
local parts = {}
for k, v in pairs(counts) do parts[#parts + 1] = k .. "=" .. v end
table.sort(parts)
print("  effects:", table.concat(parts, " "), "bugs:", bugs)
stage = 6; fire("MC_POST_NEW_LEVEL")
print("  coins after bill:", player.coins)

print("== banked reset")
playerItems[743] = nil
pdata.ccUsage.value = 100; pdata.ccUsage.limited = 120
fire("MC_USE_ITEM", 744, 744, nil, player)
print("  usage:", pdata.ccUsage.value, "limited:", pdata.ccUsage.limited)
fire("MC_POST_RENDER")

print("== subagent swarm")
playerItems[745] = true
local before = spawned
pdata.ccUsage.value = 0
local main = { SpawnerEntity = player, CollisionDamage = 3.5, Variant = 0, Position = {}, Color = "c",
    Scale = 1, TearFlags = 0, Height = -10, FallingSpeed = 0, FallingAcceleration = 0.5,
    HomingFriction = 0, KnockbackMultiplier = 1,
    Velocity = { Rotated = function(_, a) return "rotated " .. a end } }
fire("MC_POST_FIRE_TEAR", nil, main)
print("  subagent tears spawned:", spawned - before, "usage per shot:", pdata.ccUsage.value)

print("== pills")
playerItems[745] = nil
fire("MC_POST_NEW_ROOM"); player:EvaluateItems()
local d0 = player.Damage
local fd0 = player.MaxFireDelay
player.EvaluateItems = function(self)
    self.Damage = 3.5; self.MaxFireDelay = 10
    for _, cb in ipairs(callbacks) do if cb.id == "MC_EVALUATE_CACHE" then cb.fn(mod, self, CacheFlag.CACHE_DAMAGE); cb.fn(mod, self, CacheFlag.CACHE_FIREDELAY) end end
end
fire("MC_USE_PILL", 50, 50, player)
print("  cat-girl: damage", player.Damage, "fire delay", player.MaxFireDelay)
fire("MC_POST_NEW_ROOM"); print("  next room: damage", player.Damage, "fire delay", player.MaxFireDelay)
player.FireDelay = 0
fire("MC_USE_PILL", 51, 51, player)
print("  food: hearts", player.hearts, "fire delay", player.FireDelay)

print("== welcome notice")
HELD_TRINKET = 193
local grunt, bossy = makeNpc(false), makeNpc(true)
bossy.HitPoints = 100
roomEntities = { grunt, bossy }
fire("MC_USE_ITEM", 733, 733, nil, player)
print("  grunt charmed:", grunt.charmed, "grunt dead:", grunt.dead, "boss HP:", bossy.HitPoints)

print("== misbans")
HELD_TRINKET = nil
local list = {}
for i = 1, 30 do list[i] = makeNpc(false) end
roomEntities = list
fire("MC_USE_ITEM", 733, 733, nil, player)
fire("MC_POST_RENDER")
-- Car Battery's same-frame second use must not re-ban the dead list (more misbans).
local riskBefore = RISK_REF.state.risk
fire("MC_USE_ITEM", 733, 733, nil, player, UseFlag.USE_CARBATTERY)
assert(RISK_REF.state.risk == riskBefore, "Car Battery re-banned already banned enemies")
print("  car battery second use bans nobody twice: ok")

print("== status page")
playerItems[734] = nil
HELD_TRINKET = 194
fire("MC_POST_NEW_ROOM")
fire("MC_ENTITY_TAKE_DMG", EntityType.ENTITY_PLAYER, player, 1, 0, {})
fire("MC_POST_RENDER")

print("== relay slime")
HELD_TRINKET = nil; ROOMCLEAR = false
local rooms = 0
while #SPAWNED == 0 and rooms < 50 do rooms = rooms + 1; fire("MC_POST_NEW_ROOM") end
print("  first slime after", rooms, "rooms; scale", SPAWNED[1].Scale, "HP", SPAWNED[1].MaxHitPoints, "risk", Risk and "" or "")
local i = 1
while i <= #SPAWNED do fire("MC_POST_ENTITY_KILL", nil, SPAWNED[i]); i = i + 1 end
local gens = {}
for _, n in ipairs(SPAWNED) do local g = n:GetData().ccRelaySlime; gens[g] = (gens[g] or 0) + 1 end
print("  total slimes:", #SPAWNED, "gen0/1/2:", gens[0], gens[1], gens[2])

print("== constitution")
HELD_TRINKET = nil; playerItems[746] = true
fire("MC_POST_PEFFECT_UPDATE", nil, player); fire("MC_POST_PEFFECT_UPDATE", nil, player)
print("  soul hearts:", player.soul)
-- the real game stops at the first callback that returns a value
local function hit()
    for _, cb in ipairs(callbacks) do
        if cb.id == "MC_ENTITY_TAKE_DMG" and (cb.param == nil or cb.param == 1) then
            local r = cb.fn(mod, player, 1, 0, {}, 0)
            if r ~= nil then return r end
        end
    end
end
stage = 7; fire("MC_POST_NEW_LEVEL")
print("  first hit returns:", hit(), "second hit returns:", hit())
player:EvaluateItems()
print("  damage:", player.Damage)

print("== agentic transformation")
for k in pairs(playerItems) do playerItems[k] = nil end
player.CanFly = false
player.EvaluateItems = function(self)
    self.Damage = 3.5; self.MaxFireDelay = 10; self.CanFly = false
    for _, cb in ipairs(callbacks) do if cb.id == "MC_EVALUATE_CACHE" then
        for _, f in ipairs({ CacheFlag.CACHE_DAMAGE, CacheFlag.CACHE_FIREDELAY, CacheFlag.CACHE_FLYING }) do cb.fn(mod, self, f) end
    end end
end
for _, id in ipairs({ 738, 735 }) do playerItems[id] = true; fire("MC_POST_PEFFECT_UPDATE", nil, player) end
print("  2 items -> fly:", player.CanFly)
playerItems[743] = true; fire("MC_POST_PEFFECT_UPDATE", nil, player); fire("MC_POST_PEFFECT_UPDATE", nil, player)
print("  3 items -> fly:", player.CanFly, "fire delay:", player.MaxFireDelay, "damage:", player.Damage)

print("== suspended + appeal")
for k in pairs(playerItems) do playerItems[k] = nil end
player.EvaluateItems = function(self)
    self.Damage = 3.5
    for _, cb in ipairs(callbacks) do if cb.id == "MC_EVALUATE_CACHE" then cb.fn(mod, self, CacheFlag.CACHE_DAMAGE) end end
end
local R = RISK_REF
HELD_TRINKET = nil
R.state.risk = 80; player:EvaluateItems()
R:Add(15); print("  no appeal: risk", R.state.risk, "suspended", R:IsSuspended(), "damage", player.Damage)
R:Add(-20); print("  risk drops:", R.state.risk, "damage", player.Damage)
HELD_TRINKET = 195; R.state.risk = 85
R:Add(10); print("  with appeal: risk", R.state.risk, "trinket left", HELD_TRINKET, "damage", player.Damage)

print("== opus mode")
HELD_TRINKET = nil
for k in pairs(playerItems) do playerItems[k] = nil end
RISK_REF.state.risk = 10; player:EvaluateItems()
local function pd() for k in pairs(pdata) do if k:find("^ccAgentic") or k:find("^ccThinking") then pdata[k] = nil end end end
pd()
playerItems[747] = true; player.coins = 2
fire("MC_POST_PEFFECT_UPDATE", nil, player); player:EvaluateItems()
print("  coins 2 -> damage", player.Damage)
for _ = 1, 20 do fire("MC_POST_FIRE_TEAR", nil, { SpawnerEntity = player, CollisionDamage = 3.5 }) end
fire("MC_POST_PEFFECT_UPDATE", nil, player)
print("  after 20 tears: coins", player.coins, "damage", player.Damage)
player.coins = 1; fire("MC_POST_PEFFECT_UPDATE", nil, player)
print("  picked up a coin: damage", player.Damage)

print("== bugfix regressions")
do
    -- Constitution must not refuse self-inflicted damage, and must keep its block.
    for k in pairs(playerItems) do playerItems[k] = nil end
    playerItems[746] = true
    fire("MC_POST_NEW_LEVEL")
    local function hit(flags)
        for _, cb in ipairs(callbacks) do
            if cb.id == "MC_ENTITY_TAKE_DMG" and (cb.param == nil or cb.param == 1) then
                local r = cb.fn(mod, player, 1, flags, {}, 0)
                if r ~= nil then return r end
            end
        end
    end
    assert(hit(DamageFlag.DAMAGE_IV_BAG) == nil, "IV Bag damage must go through")
    assert(RISK_REF.state.constitution.players["0"].used == false, "self-damage must not use the block")
    assert(hit(DamageFlag.DAMAGE_NO_PENALTIES) == nil, "penalty-free damage must go through")
    assert(RISK_REF.state.constitution.players["0"].used == false, "penalty-free damage must not use the block")
    local cooldown
    player.SetMinDamageCooldown = function(_, frames) cooldown = frames end
    assert(hit(0) == false, "a real hit is still refused")
    assert(cooldown == 60, "a refused hit grants hurt invincibility")
    player.SetMinDamageCooldown = nil
    print("  constitution ignores self-damage and grants i-frames: ok")

    -- A banned Relay Slime must not split.
    local before = #SPAWNED
    local slime = makeNpc(false); slime:GetData().ccRelaySlime = 0; slime:GetData().ccBanned = true
    fire("MC_POST_ENTITY_KILL", nil, slime)
    assert(#SPAWNED == before, "banned slime split")
    print("  banned relay slime does not split: ok")

    -- Thinking Cleared only drains a charge on a room's first visit.
    playerItems[746] = nil
    HELD_TRINKET = 192; player.charge = 4
    FIRSTVISIT = false; fire("MC_POST_NEW_ROOM")
    assert(player.charge == 4, "revisit drained a charge")
    FIRSTVISIT = true; fire("MC_POST_NEW_ROOM")
    assert(player.charge == 3, "first visit should drain one charge")
    HELD_TRINKET = nil
    print("  thinking cleared drains only on first visits: ok")
end

print("== characters v0.5")
do
    local R = RISK_REF
    for k in pairs(playerItems) do playerItems[k] = nil end
    HELD_TRINKET = nil
    local realType = player.GetPlayerType

    -- DeepSeek-chan alone: no proxy, no IP, no risk.
    player.GetPlayerType = function() return 42 end
    R.state.risk = 60
    assert(not R:IsActive() and R:Get() == 0 and not R:IsSuspended(), "DeepSeek-only run must read risk 0")
    R:Add(30); assert(R.state.risk == 60, "risk must not change while asleep")
    local npcHP = makeNpc(false); fire("MC_POST_NPC_INIT", nil, npcHP)
    assert(npcHP.MaxHitPoints == 10, "no enemy scaling for DeepSeek-chan")
    player.GetPlayerType = function() return 142 end
    assert(not R:IsActive(), "tainted DeepSeek-chan connects directly too")
    player.GetPlayerType = realType
    assert(R:IsActive() and R:Get() == 60, "Claude-chan brings the risk system back")
    print("  DeepSeek-chan direct connection: ok")

    -- Claude-chan account age.
    R.state.risk = 10; R.state.claudeUsage["0"].age = 0
    stage = 2; fire("MC_POST_NEW_LEVEL"); stage = 3; fire("MC_POST_NEW_LEVEL")
    assert(R.state.claudeUsage["0"].age == 0 and R.state.claudeUsage["0"].review.phase == "waiting",
        "later floors offer review instead of automatic age")
    R.state.claudeUsage["0"].age = 2 -- Earned-age cache/suspension control; kill order has its own module regression.
    player.EvaluateItems = function(self)
        self.Damage = 3.5
        for _, cb in ipairs(callbacks) do if cb.id == "MC_EVALUATE_CACHE" then cb.fn(mod, self, CacheFlag.CACHE_DAMAGE) end end
    end
    for k in pairs(pdata) do if k:find("^cc") and k ~= "ccUsage" then pdata[k] = nil end end
    player:EvaluateItems(); assert(math.abs(player.Damage - 3.9) < 1e-9, "account age adds +0.2 per floor")
    R.state.risk = 95
    fire("MC_POST_PEFFECT_UPDATE", nil, player)
    assert(R.state.claudeUsage["0"].age == 0, "suspension resets account age (banned again)")
    R.state.risk = 10
    print("  Claude-chan account age: ok")

    -- Tainted Claude-chan Appeal Pending quota + Banked Reset.
    player.GetPlayerType = function() return 141 end
    fire("MC_POST_UPDATE")
    local appeal = R.state.claudeAppeal["0"]
    assert(appeal and appeal.quota == 220 and appeal.pages == 2, "tainted Claude binds a full allowance")
    appeal.quota = 1
    local last = { SpawnerEntity = player, CollisionDamage = 4 }
    fire("MC_POST_FIRE_TEAR", nil, last); assert(appeal.quota == 0 and last.CollisionDamage == 4)
    fire("MC_USE_ITEM", 744, 744, nil, player); assert(appeal.quota == 220, "Banked Reset refills the quota")
    appeal.quota = 100; stage = 4; fire("MC_POST_NEW_LEVEL"); fire("MC_POST_NEW_ROOM")
    assert(appeal.quota == 220, "a new floor refills the quota")
    player.GetPlayerType = realType
    print("  tainted Claude-chan appeal quota: ok")

    -- Lunch Break.
    for _ = 1, 90 do FRAME = FRAME + 1; fire("MC_POST_UPDATE") end
    local hearts, foe = player.hearts, makeNpc(false)
    roomEntities = { foe }; player.FireDelay = 0
    fire("MC_USE_ITEM", 749, 749, nil, player)
    assert(player.hearts == hearts + 2 and player.FireDelay == 90 and foe.slowed == 90)
    print("  Lunch Break: ok")
    -- Expire the separate food penalty before the independent outage scenario.
    for _ = 1, 90 do FRAME = FRAME + 1; fire("MC_POST_UPDATE") end

    -- 529 Overloaded: manual coding at 50% instead of no shooting.
    HELD_TRINKET = 190; ROOMCLEAR = false; roomEntities = { makeNpc(false) }
    FRAME = 5000; player.FireDelay = 0
    ROOMFRAME = 599; fire("MC_POST_UPDATE")
    assert(player.FireDelay == 0, "you can still shoot during an outage")
    local manual = { SpawnerEntity = player, CollisionDamage = 4 }
    for _, cb in ipairs(callbacks) do
        if cb.id == "MC_POST_FIRE_TEAR" and debug.getinfo(cb.fn, "S").source:find("overloaded") then cb.fn(mod, manual) end
    end
    assert(manual.CollisionDamage == 2, "manual coding deals 50%")
    HELD_TRINKET = nil
    print("  529 Overloaded manual coding: ok")

    -- Vibe Coding: make no mistakes waives the bill.
    playerItems[743] = true; player.coins = 40
    stage = 5; fire("MC_POST_NEW_LEVEL"); assert(player.coins == 40, "no hit on the floor: bill waived")
    fire("MC_ENTITY_TAKE_DMG", EntityType.ENTITY_PLAYER, player, 1, 0, {})
    stage = 6; fire("MC_POST_NEW_LEVEL"); assert(player.coins == 30, "a hit on the floor: bill charged")
    playerItems[743] = nil
    print("  Vibe Coding make no mistakes: ok")
end
print("OK")
