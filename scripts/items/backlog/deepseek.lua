-- DeepSeek family backlog items 05-08.
--
-- 05 Rice Cooker (A4): a three-second lunch through the shared meal service
--    (shooting blocked, movement kept, still vulnerable), then the next
--    attack within seven seconds deals 2x. No healing or invulnerability.
--    Busy eating keeps the charge; Car Battery cannot double the meal.
-- 06 One Bowl Only (P): the first red-heart pickup actually consumed in each
--    room grants one ordinary-bullet guard (max one, three grants per floor).
-- 07 Wengu Clock (A3): for six seconds, two seconds without attacking primes
--    +30% damage on the next attack. The window never extends.
-- 08 Seven-Second Memory (P): the first attack hit marks that enemy for seven
--    seconds; a different attack hitting it again adds one 0.5x pulse and
--    clears the mark. Seven-second cooldown; one mark at a time.

local Constants = include("scripts.constants")

local DeepSeek = {}

local MEAL, RICE_WINDOW = 90, 210
local CLOCK_WINDOW, CLOCK_IDLE = 180, 60
local MEMORY = 210

function DeepSeek:Init(mod, Risk, C, MealBreak)
    local Item = Constants.Item

    -- 05 Rice Cooker
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, player, flags)
        if C.Battery(flags) or not MealBreak or MealBreak:Remaining(player) > 0
            or not MealBreak:Start(player, MEAL) then return C.NoUse() end
        -- MealBreak saves the lockout, so the pending reward is saved too:
        -- Continue during lunch must not keep the lockout and lose the prime.
        local s = C.State(player)
        if s then s.riceCooker = true end
        C.Data(player).riceMeal = true
        C.Caption("Rice Cooker", "Lunch first, then a double shot")
        return C.Used()
    end, Item.RICE_COOKER)
    C.On("started", function()
        for _, p in ipairs(C.Players()) do
            local s = C.Peek(p)
            if s and s.riceCooker == true then C.Data(p).riceMeal = true end
        end
    end)
    C.On("update", function()
        for _, p in ipairs(C.Players()) do
            local d = C.Data(p)
            if d.riceMeal and MealBreak:Remaining(p) <= 0 then
                d.riceMeal = nil
                local s = C.Peek(p)
                if s then s.riceCooker = nil end
                -- MealBreak also clears its timer on death. Cancellation is
                -- not completion and must not bank a reward for revival.
                if not p:IsDead() then C.Prime(p, "rice", 2, RICE_WINDOW) end
            end
            C.Label(p, "rice", C.Primed(p, "rice") and "Rice: 2x ready" or nil)
        end
    end)

    -- 06 One Bowl Only
    local pending = {}
    C.On("runReset", function() pending = {} end)
    mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, function(_, pickup, collider)
        local player = collider and collider:ToPlayer()
        if not player or not player:HasCollectible(Item.ONE_BOWL) then return nil end
        if pickup.Variant ~= PickupVariant.PICKUP_HEART or not player:CanPickRedHearts() then return nil end
        local red = { [HeartSubType.HEART_FULL] = true, [HeartSubType.HEART_HALF] = true,
            [HeartSubType.HEART_DOUBLEPACK] = true, [HeartSubType.HEART_SCARED] = true }
        if red[pickup.SubType] then
            pending[GetPtrHash(player)] = { player = player, hearts = player:GetHearts(), frame = C.Now() }
        end
        return nil
    end)
    C.On("update", function(frame)
        for hash, p in pairs(pending) do
            if p.player:GetHearts() > p.hearts then
                pending[hash] = nil
                local d, s = C.Data(p.player), C.State(p.player)
                local grants = s and C.Num(s.floor.bowls, 0, 0, 3) or 3
                if not d.room.bowl and grants < 3 and C.AddGuard(p.player, "bowl", 60 * 60 * 10, 1) then
                    d.room.bowl = true
                    s.floor.bowls = grants + 1
                    C.Caption("One Bowl Only", "Guard ready")
                end
            elseif frame > p.frame then
                -- Hearts are added during the collision, so one update is enough.
                pending[hash] = nil
            end
        end
    end)

    -- 07 Wengu Clock
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, player, flags)
        if C.Battery(flags) then return C.NoUse() end
        local d = C.Data(player)
        if d.clockUntil and d.clockUntil >= C.Now() then return C.NoUse() end
        d.clockUntil, d.clockIdle = C.Now() + CLOCK_WINDOW, C.Now()
        C.Caption("Wengu Clock", "Rest two seconds, then strike")
        return C.Used()
    end, Item.WENGU_CLOCK)
    C.On("attack", function(player)
        local d = C.Data(player)
        if d.clockUntil then d.clockIdle = C.Now() end
    end)
    C.On("update", function(frame)
        for _, p in ipairs(C.Players()) do
            local d = C.Data(p)
            if d.clockUntil then
                if frame > d.clockUntil then
                    d.clockUntil = nil
                elseif frame - d.clockIdle >= CLOCK_IDLE and not C.Primed(p, "wengu") then
                    C.Prime(p, "wengu", 1.3, d.clockUntil - frame)
                end
            end
            if d.clockUntil or C.Primed(p, "wengu") then
                C.Label(p, "clock", C.Primed(p, "wengu") and "Wengu: +30% ready" or "Wengu: resting")
            else
                C.Label(p, "clock", nil)
            end
        end
    end)

    -- 08 Seven-Second Memory
    C.On("hit", function(npc, player, _, attackId)
        if not attackId or not player:HasCollectible(Item.SEVEN_SECOND_MEMORY) then return end
        local d = C.Data(player)
        local m = d.memory
        local frame = C.Now()
        if m and m.expires < frame then d.memory = nil; m = nil end
        if not m then
            if (d.memoryCooldown or 0) <= frame then
                d.memory = { hash = GetPtrHash(npc), attack = attackId, expires = frame + MEMORY }
            end
        elseif m.hash == GetPtrHash(npc) and m.attack ~= attackId then
            d.memory = nil
            d.memoryCooldown = frame + MEMORY
            C.After(1, function() C.Pulse(npc, player, 0.5) end, true)
        end
    end)
    C.On("newRoom", function()
        for _, p in ipairs(C.Players()) do C.Data(p).memory = nil end
    end)
end

return DeepSeek
