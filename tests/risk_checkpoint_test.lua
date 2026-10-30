-- Run state is checkpointed once per floor, after every floor callback, so a
-- continue after a crash never loads a different run's mod state.
local root = arg[1]
local callbacks, saved, saves = {}, nil, 0
function include(name)
    if name == "scripts.hud_text" then return { T = function(_, k) return k end, Draw = function() end } end
    return dofile(root .. "/" .. name:gsub("%.", "/") .. ".lua")
end
package.preload.json = function()
    local store = {}
    return {
        encode = function(t) store[#store + 1] = t.risk; return tostring(#store) end,
        decode = function(s) return { risk = store[tonumber(s)] } end,
    }
end
Isaac = { GetItemIdByName = function() return -1 end, GetTrinketIdByName = function() return -1 end,
    GetPillEffectByName = function() return -1 end, GetPlayerTypeByName = function() return -1 end }
function Isaac.GetPlayer() return nil end
ModCallbacks = setmetatable({}, { __index = function(_, k) return k end })
CacheFlag = { CACHE_DAMAGE = 1 }
CallbackPriority = {EARLY=-100, DEFAULT = 0, LATE = 1000 }
DamageFlag = { DAMAGE_FAKE = 1 << 21, DAMAGE_NO_PENALTIES = 1 << 28 }
EntityType = { ENTITY_PLAYER = 1 }
function RNG() return { SetSeed = function() end, RandomInt = function() return 0 end, RandomFloat = function() return 1 end } end
function Game() return {
    GetNumPlayers = function() return 0 end,
    GetLevel = function() return { GetStage = function() return 1 end } end,
    GetSeeds = function() return { GetStartSeed = function() return 1 end } end,
} end
local mod = { AddCallback = function(_, id, fn) callbacks[id] = callbacks[id] or {}; table.insert(callbacks[id], fn) end }
function mod:AddPriorityCallback(id, _, fn) self:AddCallback(id, fn) end
function mod:SaveData(s) saved = s; saves = saves + 1 end
function mod:HasData() return saved ~= nil end
function mod:LoadData() return saved end
local function fire(id, ...) for _, fn in ipairs(callbacks[id] or {}) do fn(mod, ...) end end

local Risk = include("scripts.risk")
Risk:Init(mod)

-- The first floor's NEW_LEVEL arrives before the run starts: no checkpoint.
fire("MC_POST_NEW_LEVEL"); fire("MC_POST_GAME_STARTED", false); fire("MC_POST_UPDATE")
assert(saves == 0, "no checkpoint before the run has started")

-- A later floor: modules change state in their own NEW_LEVEL callbacks, then
-- the next update saves once.
fire("MC_POST_NEW_LEVEL")
assert(saves == 0, "the checkpoint waits for the next update")
Risk.state.risk = 37 -- a later module's floor callback
fire("MC_POST_UPDATE"); fire("MC_POST_UPDATE")
assert(saves == 1, "one checkpoint per floor")

-- Simulated crash: no PRE_GAME_EXIT. Continue loads the floor checkpoint.
Risk.state.risk = 99
fire("MC_POST_GAME_STARTED", true)
assert(Risk.state.risk == 37, "continue after a crash restores the floor checkpoint")

-- Exiting cancels a pending checkpoint; dying (shouldSave false) does not save.
fire("MC_POST_NEW_LEVEL"); fire("MC_PRE_GAME_EXIT", false); fire("MC_POST_UPDATE")
assert(saves == 1, "a run that ended does not checkpoint afterwards")
print("PASS risk checkpoint: once per floor, after floor callbacks, restored on continue")
