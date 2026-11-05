-- Items that force doors or delete pickups must not break run progression:
-- special exits keep their native requirements, run-ending pickups survive,
-- and All Tests Passing cannot skip required waves. Callback stubs only.
local root = arg[1]
function include(name) return dofile(root .. "/" .. name:gsub("%.", "/") .. ".lua") end
local ids = { ["--dangerously-skip-permissions"] = 741, ["All Tests Passing"] = 742 }
Isaac = {
    GetItemIdByName = function(n) return ids[n] or 800 end,
    GetTrinketIdByName = function() return 190 end,
    GetPillEffectByName = function() return 50 end,
    GetPlayerTypeByName = function() return 41 end,
}
ModCallbacks = setmetatable({}, { __index = function(_, k) return k end })
DoorSlot = { NUM_DOOR_SLOTS = 8 }
RoomType = { ROOM_DEFAULT = 1, ROOM_TREASURE = 4, ROOM_BOSS = 5, ROOM_SECRET = 7, ROOM_SUPERSECRET = 8,
    ROOM_CHALLENGE = 11, ROOM_BOSSRUSH = 17, ROOM_ULTRASECRET = 29 }
PickupVariant = { PICKUP_COIN = 20, PICKUP_LOCKEDCHEST = 60, PICKUP_COLLECTIBLE = 100, PICKUP_BIGCHEST = 340,
    PICKUP_TROPHY = 370, PICKUP_BED = 380, PICKUP_MOMSCHEST = 390 }

local doors, entities, roomType, clear, captions, greedMode = {}, {}, 1, false, {}, 0
local clearCalls = 0
local room = {
    GetDoor = function(_, slot) return doors[slot] end,
    GetType = function() return roomType end,
    IsClear = function() return clear end,
    SetClear = function(_, v) clearCalls = clearCalls + 1; clear = v end,
}
local player = { HasCollectible = function(_, id) return id == 741 end }
function Isaac.GetPlayer() return player end
function Isaac.GetRoomEntities() return entities end
function Game() return {
    GetRoom = function() return room end,
    GetNumPlayers = function() return 1 end,
    IsGreedMode = function() return greedMode == 1 or greedMode == 2 end,
    GetSeeds = function() return { GetStartSeed = function() return 1 end } end,
    GetHUD = function() return { ShowItemText = function(_, a) captions[#captions + 1] = a end } end,
} end
local rolls = {}
function RNG() return { SetSeed = function() end, RandomFloat = function() return table.remove(rolls, 1) or 0.9 end } end

local callbacks = {}
local mod = { AddCallback = function(_, id, fn, param) callbacks[#callbacks + 1] = { id = id, fn = fn, param = param } end }
local function fire(id, ...)
    local result
    for _, c in ipairs(callbacks) do
        if c.id == id then local r = c.fn(nil, ...); if r ~= nil then result = r end end
    end
    return result
end
include("scripts.items.skip_permissions"):Init(mod)
include("scripts.items.tests_passing"):Init(mod)

local function door(index, kind, locked)
    local d = { TargetRoomIndex = index, TargetRoomType = kind, locked = locked, opened = false }
    function d:IsLocked() return self.locked end
    function d:TryUnlock() self.locked = false end
    function d:Open() self.opened = true end
    return d
end

-- --dangerously-skip-permissions -------------------------------------------------------------
local treasure, megaSatan, bossRush, secretExit, secret = door(12, 4, true), door(-7, 5, true),
    door(-5, 17, true), door(-10, 1, true), door(30, 7, true)
doors = { [0] = treasure, [1] = megaSatan, [2] = bossRush, [3] = secretExit, [4] = secret }
entities = {}
fire("MC_POST_GAME_STARTED", false)
fire("MC_POST_NEW_ROOM")
assert(not treasure.locked, "an ordinary key door unlocks")
assert(megaSatan.locked and bossRush.locked and secretExit.locked, "special exits keep their requirements")
assert(secret.locked, "secret rooms stay behind their walls")
print("PASS skip-permissions: ordinary locks open, special exits and secret rooms do not")

local removed = {}
local function pickup(variant)
    local p = { Variant = variant }
    function p:ToPickup() return self end
    function p:Remove() removed[#removed + 1] = self.Variant end
    function p:TryOpenChest() end
    return p
end
doors = {}
entities = { pickup(20), pickup(100), pickup(340), pickup(370), pickup(380), pickup(390) }
rolls = { 0.05 }
fire("MC_POST_NEW_ROOM")
assert(#removed == 1 and removed[1] == 20, "rm -rf deletes ordinary pickups only: " .. table.concat(removed, ","))
print("PASS skip-permissions: rm -rf spares pedestals, big chests, trophies, beds and Mom's chest")

-- All Tests Passing ---------------------------------------------------------------------------
for _, kind in ipairs({ 5, 17, 11 }) do
    roomType, clear, captions = kind, false, {}
    doors = { [0] = door(3, 1, false) }
    local result = fire("MC_USE_ITEM", 742, nil, player)
    assert(type(result) == "table" and result.Discharge == false, "refused with charge kept in room type " .. kind)
    assert(clear == false and not doors[0].opened, "an uncleared required room stays uncleared")
end
roomType, clear = 1, false
local exit, normal = door(-8, 1, false), door(3, 1, false)
doors = { [0] = normal, [1] = exit, [2] = door(31, 8, false) }
assert(fire("MC_USE_ITEM", 742, nil, player) == true)
assert(clear and normal.opened and not exit.opened and not doors[2].opened, "only ordinary doors open")

-- Greed and Greedier share IsGreedMode()'s documented true result.
-- These are supplied API states, not an emulation of native wave timing.
for _, mode in ipairs({ { value = 1, name = "Greed" }, { value = 2, name = "Greedier" } }) do
    for _, kind in ipairs({ 1, 5 }) do
        greedMode, roomType, clear, captions = mode.value, kind, false, {}
        local greedDoor = door(3, 1, false)
        doors = { [0] = greedDoor }
        local before = clearCalls
        for attempt = 1, 2 do
            local result = fire("MC_USE_ITEM", 742, nil, player)
            assert(type(result) == "table" and result.Discharge == false,
                mode.name .. " wave keeps the active charge")
            assert(result.Remove == false and result.ShowAnim == false,
                mode.name .. " refusal neither removes nor animates the item")
            assert(not clear and not greedDoor.opened and clearCalls == before,
                mode.name .. " refusal must not mutate clear state or doors")
            assert(#captions == attempt and captions[attempt] == "Required review pending",
                mode.name .. " refusal explains the preserved charge")
        end

        -- Once the supplied room is clear, the existing safe-door behavior
        -- still runs. The guard is not a permanent mode-wide item ban.
        clear = true
        local specialExit = door(-8, 1, false)
        doors[1] = specialExit
        assert(fire("MC_USE_ITEM", 742, nil, player) == true,
            mode.name .. " cleared room permits use")
        assert(greedDoor.opened and not specialExit.opened and clearCalls == before + 1,
            mode.name .. " cleared room opens only eligible doors")
    end
end
greedMode = 0

roomType, clear = 1, false
doors = { [0] = door(3, 1, false) }
assert(fire("MC_USE_ITEM", 742, nil, player) == true and clear and doors[0].opened,
    "returning to an ordinary run must not retain the mode refusal")

roomType, clear = 5, true
assert(fire("MC_USE_ITEM", 742, nil, player) == true, "a cleared boss room is no longer guarded")
print("PASS All Tests Passing: refuses boss, Boss Rush, challenge and Greed-mode waves; opens ordinary doors only")
