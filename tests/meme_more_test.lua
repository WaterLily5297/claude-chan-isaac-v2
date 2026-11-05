-- Boundary tests for meme extras batch 4/5: As an AI Language Model, System Prompt
-- Leak, Disgrace Loop, Rolled Back, Seahorse Emoji, Temperature Dial, Deep Research.
-- Stubs model callback inputs and saved state only, not native effects.
local root = arg[1]
function include(name) return dofile(root .. "/" .. name:gsub("%.", "/") .. ".lua") end
local items = { ["Seahorse Emoji"] = 910, ["Temperature Dial"] = 911, ["Deep Research"] = 912 }
local trinkets = { ["As an AI Language Model"] = 210, ["System Prompt Leak"] = 211, ["Disgrace Loop"] = 212 }
Isaac = {
    GetItemIdByName = function(n) return items[n] or 800 end,
    GetTrinketIdByName = function(n) return trinkets[n] or 190 end,
    GetPillEffectByName = function(n) return n == "Rolled Back" and 61 or 50 end,
    GetPlayerTypeByName = function() return 41 end,
}
ModCallbacks = setmetatable({}, { __index = function(_, k) return k end })
CacheFlag = { CACHE_DAMAGE = 1, CACHE_FIREDELAY = 2, CACHE_SHOTSPEED = 4, CACHE_RANGE = 8,
    CACHE_SPEED = 16, CACHE_LUCK = 1024 }
DamageFlag = { DAMAGE_EXPLOSION = 1 << 2, DAMAGE_FAKE = 1 << 21, DAMAGE_NO_PENALTIES = 1 << 28 }
EntityFlag = { FLAG_FRIENDLY = 1 }
EntityType = { ENTITY_PLAYER = 1 }
UseFlag = { USE_CARBATTERY = 32 }
PillColor = { PILL_GIANT_FLAG = 2048 }
TearFlags = { TEAR_HOMING = 1, TEAR_PIERCING = 2, TEAR_SPECTRAL = 4, TEAR_SLOW = 8, TEAR_POISON = 16,
    TEAR_FREEZE = 32, TEAR_CHARM = 64, TEAR_CONFUSION = 128, TEAR_WIGGLE = 256, TEAR_BOOMERANG = 512 }
CollectibleType = { COLLECTIBLE_BOOK_OF_BELIAL = 34, COLLECTIBLE_NECRONOMICON = 35 }
function GetPtrHash(e) return e.hash end
function EntityRef(e) return { Entity = e } end

local floorSeed, curses, removed, compass, maps, blue, captions = 1, 0, {}, 0, 0, 0, {}
local entities = {}
function Isaac.GetRoomEntities() return entities end
function Game() return {
    GetNumPlayers = function() return #PLAYERS end,
    GetLevel = function() return {
        GetDungeonPlacementSeed = function() return floorSeed end,
        GetStage = function() return 1 end, GetStageType = function() return 0 end,
        GetCurses = function() return curses end,
        RemoveCurses = function(_, c) removed[#removed + 1] = c; curses = curses & ~c end,
        ApplyCompassEffect = function() compass = compass + 1 end,
        ApplyMapEffect = function() maps = maps + 1 end,
        ApplyBlueMapEffect = function() blue = blue + 1 end,
    } end,
    GetHUD = function() return { ShowItemText = function(_, a) captions[#captions + 1] = a end } end,
} end

local function player(hash)
    local p = { hash = hash, trinkets = {}, items = {}, data = {}, Position = {},
        Damage = 3.5, MaxFireDelay = 10, MoveSpeed = 1, TearRange = 260, ShotSpeed = 1, Luck = 0 }
    function p:ToPlayer() return self end
    function p:HasTrinket(id) return self.trinkets[id] == true end
    function p:HasCollectible(id) return self.items[id] == true end
    function p:GetData() return self.data end
    function p:AddCacheFlags() end
    function p:EvaluateItems()
        self.Damage, self.MaxFireDelay, self.MoveSpeed, self.TearRange, self.ShotSpeed, self.Luck = 3.5, 10, 1, 260, 1, 0
        for _, f in pairs(CacheFlag) do
            for _, cb in ipairs(CALLBACKS) do if cb.id == "MC_EVALUATE_CACHE" then cb.fn(MOD, self, f) end end
        end
    end
    return p
end
local p1, p2 = player(1), player(2)
PLAYERS = { p1, p2 }
function Isaac.GetPlayer(i) return PLAYERS[i + 1] end
CALLBACKS = {}
MOD = { AddCallback = function(_, id, fn, filter) CALLBACKS[#CALLBACKS + 1] = { id = id, fn = fn, filter = filter } end }
-- Registration order only; tests/disgrace_order_test.lua covers priority dispatch.
CallbackPriority = {EARLY=-100, LATE = 100 }
function MOD:AddPriorityCallback(id, _, fn, filter) self:AddCallback(id, fn, filter) end
local function fire(id, filter, ...)
    local result
    for _, cb in ipairs(CALLBACKS) do
        if cb.id == id and (cb.filter == nil or filter == nil or cb.filter == filter) then
            local r = cb.fn(MOD, ...); if r ~= nil then result = r end
        end
    end
    return result
end
local Risk = { state = {} }
local Refusal = include("scripts.items.ai_language_model")
Refusal:Init(MOD, Risk)
include("scripts.items.prompt_leak"):Init(MOD, Risk)
include("scripts.items.disgrace_loop"):Init(MOD)
include("scripts.items.rolled_back"):Init(MOD)
include("scripts.items.seahorse_emoji"):Init(MOD)
local Dial = include("scripts.items.temperature_dial")
Dial:Init(MOD, Risk)
include("scripts.items.deep_research"):Init(MOD)

-- As an AI Language Model -----------------------------------------------------------
assert(Refusal.Pick(0) == nil and Refusal.Pick(2) == nil and Refusal.Pick(2 | 8) == 8 and Refusal.Pick(1 | 64) == 1)
curses = 2 | 64
fire("MC_POST_NEW_ROOM"); assert(#removed == 0, "no holder")
p2.trinkets[210] = true
fire("MC_POST_NEW_ROOM"); assert(#removed == 1 and removed[1] == 64 and curses == 2, "Labyrinth kept")
curses = 2 | 1; fire("MC_POST_NEW_ROOM"); assert(#removed == 1, "once per floor")
floorSeed = 2; curses = 2; fire("MC_POST_NEW_ROOM"); assert(#removed == 1, "Labyrinth-only floor refuses nothing")
curses = 4; fire("MC_POST_NEW_ROOM"); assert(#removed == 2 and removed[2] == 4, "nothing spent while no curse was removable")
print("PASS As an AI Language Model: curse pick, Labyrinth kept, once per floor, holder only")

-- System Prompt Leak -------------------------------------------------------------------
p1.trinkets[211] = true
fire("MC_POST_NEW_ROOM"); fire("MC_POST_NEW_ROOM"); assert(compass == 1, "once per floor")
floorSeed = 3; fire("MC_POST_NEW_ROOM"); assert(compass == 2, "each new floor")
print("PASS System Prompt Leak: once per floor and floor reset")

-- Disgrace Loop ---------------------------------------------------------------------------
local function npc(opts)
    local n = { frozen = nil }
    function n:ToNPC() return self end
    function n:IsVulnerableEnemy() return not opts.invulnerable end
    function n:HasEntityFlags() return opts.friendly or false end
    function n:AddFreeze(ref, f) self.frozen = f; self.by = ref.Entity end
    return n
end
local foe, friend, rockish = npc({}), npc({ friendly = true }), npc({ invulnerable = true })
entities = { foe, friend, rockish }
local function hit(p, flags) return fire("MC_ENTITY_TAKE_DMG", 1, p, 1, flags or 0) end
hit(p1); assert(foe.frozen == nil, "non-holder")
p1.trinkets[212] = true
hit(p1, DamageFlag.DAMAGE_NO_PENALTIES); hit(p1, DamageFlag.DAMAGE_FAKE)
assert(foe.frozen == nil, "self-damage and fake damage never trigger")
assert(hit(p1) == nil, "hit is not cancelled")
assert(foe.frozen == 45 and foe.by == p1 and friend.frozen == nil and rockish.frozen == nil)
foe.frozen = nil; hit(p1); assert(foe.frozen == nil, "once per room")
fire("MC_POST_NEW_ROOM"); hit(p1); assert(foe.frozen == 45, "new room re-arms")
foe.frozen = nil; fire("MC_POST_NEW_ROOM")
hit(p1, DamageFlag.DAMAGE_EXPLOSION | DamageFlag.DAMAGE_NO_PENALTIES)
assert(foe.frozen == nil, "a penalty-free blast neither triggers nor spends the room")
hit(p1, DamageFlag.DAMAGE_EXPLOSION); assert(foe.frozen == 45, "own bomb blasts carry a penalty, so they count as real hits")
print("PASS Disgrace Loop: real hits only, owner, eligibility, once per room, hit kept")

-- Rolled Back -----------------------------------------------------------------------------------
fire("MC_USE_PILL", 61, 61, p1, 0)
assert(p1.Damage == 4.5 and math.abs(p1.MaxFireDelay - 7.8) < 1e-9 and math.abs(p1.MoveSpeed - 1.2) < 1e-9)
assert(p1.TearRange == 300 and math.abs(p1.ShotSpeed - 1.1) < 1e-9 and p1.Luck == 1)
p2:EvaluateItems(); assert(p2.Damage == 3.5, "owner only")
fire("MC_POST_NEW_ROOM"); assert(p1.Damage == 3.5 and p1.data.ccRolledBack == nil, "rolled back next room")
fire("MC_USE_PILL", 61, 61, p1, 0, 5 | 2048); assert(p1.Damage == 5.5, "horse doubles")
fire("MC_USE_PILL", 61, 61, p1, 0); assert(p1.Damage == 5.5, "capped at double")
fire("MC_POST_NEW_ROOM")
print("PASS Rolled Back: one-room stats, owner, horse, cap and rollback")

-- Seahorse Emoji ---------------------------------------------------------------------------------
local made = {}
local function addWisp(self, id)
    local w = { id = id, alive = true, owner = self }
    function w:Exists() return self.alive end
    function w:Remove() self.alive = false end
    made[#made + 1] = w
    return w
end
p1.AddWisp, p2.AddWisp = addWisp, addWisp
local rng = { RandomInt = function(_, n) return n - 1 end }
local function use(id, p, flags) return fire("MC_USE_ITEM", id, id, rng, p, flags or 0) end
assert(use(910, p1).Discharge and #made == 1 and (made[1].id == 34 or made[1].id == 35))
assert(not use(910, p1, 32).Discharge and #made == 1, "Car Battery adds none")
assert(use(910, p1).Discharge and #made == 2 and not made[1].alive and made[2].alive, "replaces")
fire("MC_POST_NEW_ROOM"); assert(not made[2].alive, "vanishes on room exit")
-- F10 offline lifecycle: per-player ownership, a wisp that already died, game exit.
assert(use(910, p1).Discharge and use(910, p2).Discharge and #made == 4)
assert(made[3].owner == p1 and made[4].owner == p2 and made[3].alive and made[4].alive, "one wisp each")
assert(use(910, p2).Discharge and #made == 5 and made[3].alive and not made[4].alive, "replacing one player's wisp keeps the other's")
made[3].alive = false
assert(use(910, p1).Discharge and #made == 6 and made[6].alive, "a wisp killed in combat is simply replaced")
fire("MC_PRE_GAME_EXIT", nil, true)
assert(not made[5].alive and not made[6].alive, "game exit removes every tracked wisp")
fire("MC_POST_NEW_ROOM"); assert(#made == 6, "nothing is recreated after exit")
print("PASS Seahorse Emoji: one wisp per player, replace, Car Battery, room exit, co-op and game exit")

-- Temperature Dial ---------------------------------------------------------------------------------
p2.items[911] = true
p2:EvaluateItems(); assert(math.abs(p2.Damage - 3.85) < 1e-9, "starts at temperature 0")
local function tear(owner)
    local t = { SpawnerEntity = owner, flags = 0 }
    function t:AddTearFlags(f) self.flags = self.flags | f end
    return t
end
local draws = 0
function p2:GetCollectibleRNG(id) assert(id == 911)
    return { RandomInt = function(_, n) draws = draws + 1; return (draws - 1) % n end } end
local cold = tear(p2); fire("MC_POST_FIRE_TEAR", nil, cold); assert(cold.flags == 0 and draws == 0)
assert(use(911, p2).Discharge and p2.Damage == 3.5, "temperature 1 drops the bonus")
local a, b = tear(p2), tear(p2)
fire("MC_POST_FIRE_TEAR", nil, a); fire("MC_POST_FIRE_TEAR", nil, b)
assert(a.flags == TearFlags.TEAR_HOMING and b.flags == TearFlags.TEAR_PIERCING, "one native flag per tear")
assert(Risk.state.memeExtras.players["1"].temperature == 1, "saved per player")
assert(not use(911, p2, 32).Discharge and Risk.state.memeExtras.players["1"].temperature == 1, "Car Battery does not toggle back")
local other = tear(p1); fire("MC_POST_FIRE_TEAR", nil, other); assert(other.flags == 0)
assert(use(911, p2).Discharge and math.abs(p2.Damage - 3.85) < 1e-9)
print("PASS Temperature Dial: saved toggle, cold damage, hot flags, owner and Car Battery")

-- Deep Research -----------------------------------------------------------------------------------
assert(use(912, p1).Discharge and maps == 1 and blue == 1 and compass == 3)
assert(not use(912, p1, 32).Discharge and maps == 1)
print("PASS Deep Research: full reveal once per use, Car Battery no-op")
