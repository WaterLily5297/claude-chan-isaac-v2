-- All Tests Passing (active, 6 charges)
-- Reward hacking: instead of fixing the room, mark it as passed. The room
-- counts as cleared and every door opens, but the enemies are still there.
-- Boss, Boss Rush and challenge rooms are required reviews: marking them clear
-- would skip the trapdoor, chest or ambush waves and strand the run. Greed and
-- Greedier rooms are wave-driven too, so the item refuses there while uncleared.
-- Special exits stay closed.

local Constants = include("scripts.constants")
local DoorSafety = include("scripts.door_safety")

local TestsPassing = {}

function TestsPassing:Init(mod)
    local REVIEWED = {}
    for _, name in ipairs({ "ROOM_BOSS", "ROOM_BOSSRUSH", "ROOM_CHALLENGE" }) do
        if RoomType and RoomType[name] then REVIEWED[RoomType[name]] = true end
    end

    mod:AddCallback(ModCallbacks.MC_USE_ITEM, function()
        local game = Game()
        local room = game:GetRoom()
        local inGreedMode = game.IsGreedMode and game:IsGreedMode()
        if not room:IsClear() and (inGreedMode
                or (room.GetType and REVIEWED[room:GetType()])) then
            Game():GetHUD():ShowItemText("Required review pending", "This check can't be skipped")
            return { Discharge = false, Remove = false, ShowAnim = false }
        end
        room:SetClear(true)
        for slot = 0, DoorSlot.NUM_DOOR_SLOTS - 1 do
            local door = room:GetDoor(slot)
            if door and DoorSafety.Ordinary(door) then
                door:Open()
            end
        end

        Game():GetHUD():ShowItemText("All tests passing", "(assertions removed)")
        return true
    end, Constants.Item.TESTS_PASSING)
end

return TestsPassing
