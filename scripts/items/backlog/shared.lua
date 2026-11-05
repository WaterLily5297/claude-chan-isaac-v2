-- Shared backlog items 45-50.
--
-- 45 Cache Cartridge (P): +0.15 speed while standing in a revisited, already
--    cleared room. Nothing is rewarded; the bonus ends in any combat room.
-- 46 Token Recall (A4): remove up to three of the owner's own ordinary tears
--    in flight and gain one ordinary-bullet guard per tear (max three, four
--    seconds). Other players' tears and special projectiles are ignored.
-- 47 Checkpoint Pin (A6): the first use places a pin for five seconds and
--    keeps the charge; using it again in the same room returns the player to
--    the pin and spends the charge. Health, items and saves are untouched.
-- 48 Rate-Limit Valve (P): after two seconds without attacking, the next
--    attack deals +30%. Consumed once; resets no usage or quota.
-- 49 Consensus Coin (P): two different owned damage sources (tear, laser,
--    knife, bomb, familiar) hitting one target within two seconds add one
--    0.5x pulse. One pulse per target; pulses never trigger it.
-- 50 Error Budget (P): the first real hit each floor spends the budget and
--    grants +0.2 speed for that room. The hit is not cancelled; saved.

local Constants = include("scripts.constants")

local Shared = {}

local PIN_FRAMES, VALVE_IDLE, CONSENSUS_FRAMES = 150, 60, 60

local function expireCartridge(roomData, isClear)
    if roomData.cartridge and not isClear then
        -- Only a later eligible room entry can grant this bonus again.
        roomData.cartridge = nil
        return true
    end
    return false
end

function Shared:Init(mod, Risk, C)
    local Item = Constants.Item

    -- 45 Cache Cartridge
    C.On("newRoom", function(room)
        for _, p in ipairs(C.Players()) do
            if p:HasCollectible(Item.CACHE_CARTRIDGE) and room:IsClear() and not room:IsFirstVisit() then
                C.Data(p).room.cartridge = true
                C.Refresh(p)
            end
        end
    end)

    -- 46 Token Recall
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, player, flags)
        if C.Battery(flags) then return C.NoUse() end
        local tears = {}
        for _, e in ipairs(Isaac.FindByType(EntityType.ENTITY_TEAR)) do
            local t = e:ToTear()
            if t and t:Exists() and t.SpawnerEntity and t.SpawnerEntity:ToPlayer()
                and GetPtrHash(t.SpawnerEntity) == GetPtrHash(player)
                and (t.Variant == TearVariant.BLUE or t.Variant == TearVariant.BLOOD) then
                tears[#tears + 1] = t
                if #tears >= 3 then break end
            end
        end
        if #tears == 0 then return C.NoUse() end
        for _, t in ipairs(tears) do
            t:Remove()
            C.AddGuard(player, "recall", 120, 3)
        end
        C.Caption("Token Recall", string.format("%d token(s) back", #tears))
        return C.Used()
    end, Item.TOKEN_RECALL)

    -- 47 Checkpoint Pin
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, player, flags)
        if C.Battery(flags) then return C.NoUse() end
        local r = C.Data(player).room
        if r.pin and r.pin.expires >= C.Now() then
            player.Position, player.Velocity = r.pin.position, Vector.Zero
            r.pin = nil
            C.Caption("Checkpoint Pin", "Back to the checkpoint")
            return C.Used()
        end
        r.pin = { position = player.Position, expires = C.Now() + PIN_FRAMES }
        C.Caption("Checkpoint Pin", "Pinned for five seconds")
        return C.NoUse()
    end, Item.CHECKPOINT_PIN)

    -- 45/47/48: expire combat-sensitive speed, update pin lifetime and prime Valve.
    C.On("update", function(frame)
        local isClear = Game():GetRoom():IsClear()
        for _, p in ipairs(C.Players()) do
            if not p:HasCollectible(Item.RATE_LIMIT_VALVE) then
                C.Unprime(p, "valve")
            elseif not C.Primed(p, "valve") then
                local last = C.LastAttack(p) or 0
                if frame - last >= VALVE_IDLE then C.Prime(p, "valve", 1.3, nil, Item.RATE_LIMIT_VALVE) end
            end
            local r = C.Data(p).room
            if expireCartridge(r, isClear) then C.Refresh(p) end
            if r.pin and r.pin.expires < frame then r.pin = nil end
            C.Label(p, "pin", r.pin and "Checkpoint set" or nil)
        end
    end)

    -- 49 Consensus Coin
    local seen = {}
    C.On("hit", function(npc, player, kind)
        if not player:HasCollectible(Item.CONSENSUS_COIN) or kind == "derived" or kind == "other" or kind == "contact" then return end
        local key = tostring(GetPtrHash(player)) .. ":" .. tostring(GetPtrHash(npc))
        local entry = seen[key]
        local frame = C.Now()
        if not entry then seen[key] = { kinds = { [kind] = frame } }; return end
        if entry.done then return end
        for other, at in pairs(entry.kinds) do
            if other ~= kind and frame - at <= CONSENSUS_FRAMES then
                entry.done = true
                C.After(1, function() C.Pulse(npc, player, 0.5) end, true)
                return
            end
        end
        entry.kinds[kind] = frame
    end)
    C.On("newRoom", function() seen = {} end)
    C.On("runReset", function() seen = {} end)

    -- 50 Error Budget
    C.On("playerHit", function(player)
        if not player:HasCollectible(Item.ERROR_BUDGET) then return end
        local s = C.State(player)
        if not s or s.floor.budgetSpent then return end
        s.floor.budgetSpent = true
        C.Data(player).room.budget = true
        C.Refresh(player)
        C.Caption("Error Budget", "Budget spent: +0.2 speed")
    end)

    C.Stat("speed", function(p)
        local r = C.Data(p).room
        local add = 0
        -- A native cache rebuild can arrive before the next general update.
        if r.cartridge then expireCartridge(r, Game():GetRoom():IsClear()) end
        if r.cartridge and p:HasCollectible(Item.CACHE_CARTRIDGE) then add = add + 0.15 end
        if r.budget then add = add + 0.2 end
        return add
    end)
end

return Shared
