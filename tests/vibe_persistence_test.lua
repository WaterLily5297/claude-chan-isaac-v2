-- Lifecycle regression: entity data disappears when a run is continued.
local root = arg[1]
local callbacks, players = {}, {}
local risk = { state = {} }
local mod = { AddCallback = function(_, id, fn) callbacks[id] = fn end }
function mod:AddPriorityCallback(id, _, fn) callbacks[id] = fn end
ModCallbacks = setmetatable({}, { __index = function(_, key) return key end })
CallbackPriority = {EARLY=-100,LATE=1000}
DamageFlag = {DAMAGE_FAKE=1<<21,DAMAGE_NO_PENALTIES=1<<28}
EntityType = { ENTITY_PLAYER = 1 }
TearFlags = { TEAR_HOMING = 1, TEAR_PIERCING = 2, TEAR_SPECTRAL = 4, TEAR_POISON = 8, TEAR_SLOW = 16 }
function include(name)
    if name == "scripts.constants" then return { Item = { VIBE_CODING = 743 } } end
    return dofile(root .. "/" .. name:gsub("%.", "/") .. ".lua")
end
function RNG() return { SetSeed = function() end } end
function GetPtrHash(entity) return entity.identity end
Isaac = { GetPlayer = function(i) return players[i + 1] end }
function Game() return {
    GetNumPlayers = function() return #players end,
    GetSeeds = function() return { GetStartSeed = function() return 123 end } end,
    GetHUD = function() return { ShowItemText = function() end } end,
} end
local function player(id)
    return { identity = id, coins = 40, data = {},
        ToPlayer = function(self) return self end,
        GetData = function(self) return self.data end,
        GetNumCoins = function(self) return self.coins end,
        HasCollectible = function() return true end,
        AddCoins = function(self, amount) self.coins = self.coins + amount end }
end
local function fire(id, ...) callbacks[id](mod, ...) end
local function startModule()
    callbacks = {}
    dofile(root .. "/scripts/items/vibe_coding.lua"):Init(mod, risk)
end
players = { player(1), player(2) }
startModule()
fire("MC_POST_NEW_LEVEL") -- Engine startup ordering, before GAME_STARTED.
fire("MC_POST_GAME_STARTED", false)
fire("MC_ENTITY_TAKE_DMG", players[1])

-- Keep only the shared run state; discard every player and module-local value.
-- This is a stub persistence boundary, not an engine JSON or restart test.
players = { player(3), player(4) }
startModule()
fire("MC_POST_NEW_LEVEL")
assert(players[1].coins == 40, "startup must not charge before saved state loads")
fire("MC_POST_GAME_STARTED", true)
fire("MC_POST_NEW_LEVEL")
assert(players[1].coins == 30, "continue must retain the previous floor's bill condition")
assert(players[2].coins == 40, "one player's damage must not charge another player")
fire("MC_POST_NEW_LEVEL")
assert(players[1].coins == 30, "a new no-hit floor must waive the bill")
fire("MC_ENTITY_TAKE_DMG", players[2])
fire("MC_POST_NEW_LEVEL")
assert(players[2].coins == 30, "each player's own damage must be tracked")

fire("MC_ENTITY_TAKE_DMG", players[1])
fire("MC_PRE_GAME_EXIT", false)
fire("MC_POST_NEW_LEVEL")
assert(players[1].coins == 30, "startup must not charge using the previous run's state")
risk.state = {} -- Risk resets the shared state before Vibe Coding starts a new run.
fire("MC_POST_GAME_STARTED", false)
fire("MC_POST_NEW_LEVEL")
assert(players[1].coins == 30, "a new run must not inherit the previous run's mistakes")

-- A slot's mark follows its live owner within the floor (F6).
players = { player(5), player(6) }
fire("MC_POST_GAME_STARTED", false)
fire("MC_ENTITY_TAKE_DMG", players[1])
players[1] = player(7) -- a different entity now holds slot 0
fire("MC_POST_NEW_LEVEL")
assert(players[1].coins == 40, "a replacement must not pay the departed player's bill")
local hurt, clean = player(8), player(9)
players = { hurt, clean }
fire("MC_POST_NEW_LEVEL")
fire("MC_ENTITY_TAKE_DMG", hurt)
players = { clean, hurt } -- reordered slots
fire("MC_POST_NEW_LEVEL")
assert(hurt.coins == 30 and clean.coins == 40, "reordered players keep their own floor record")
print("OK: Vibe Coding continue, startup ordering, per-player billing, fresh runs and live slot owners")
