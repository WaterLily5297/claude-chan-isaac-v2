-- Grok family backlog items 17-20.
--
-- 17 Is This True? (A3): challenge the nearest enemy within 220 units for six
--    seconds: the owner deals +35% damage to it and -15% to everything else.
--    Killing it during the challenge returns one charge. No target keeps it.
-- 18 Live Wire (P): +0.15 speed while an ordinary hostile bullet is within 100
--    units. No stacking, nothing stored; cache refresh only on change.
-- 19 Quote Retort (P): after real enemy damage, the next attack within four
--    seconds deals +50%. One hit only; fake and self-damage never count.
-- 20 Community Note (P): three distinct attacks hitting one enemy expose it
--    for three seconds (+15% owner damage). One exposure per target, at most
--    six per room. Derived hits never count.

local Constants = include("scripts.constants")

local Grok = {}

local CHALLENGE_FRAMES, CHALLENGE_RANGE = 180, 220
local WIRE_RANGE, RETORT_FRAMES = 100, 120
local NOTE_HITS, NOTE_FRAMES, NOTE_MAX = 3, 90, 6

function Grok:Init(mod, Risk, C)
    local Item = Constants.Item

    -- 17 Is This True?
    mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, player, flags, slot)
        if C.Battery(flags) then return C.NoUse() end
        local target = C.NearestEnemy(player.Position, CHALLENGE_RANGE)
        if not target then return C.NoUse() end
        C.Data(player).room.challenge = { hash = GetPtrHash(target), expires = C.Now() + CHALLENGE_FRAMES, slot = slot }
        target:SetColor(Color(1, 1, 1, 1, 0.35, 0.1, 0.1), CHALLENGE_FRAMES, 1, false, false)
        C.Caption("Is this true?", "Fact-check in progress")
        return C.Used()
    end, Item.IS_THIS_TRUE)
    C.On("kill", function(npc)
        for _, p in ipairs(C.Players()) do
            local c = C.Data(p).room.challenge
            if c and c.hash == GetPtrHash(npc) and c.expires >= C.Now() then
                C.Data(p).room.challenge = nil
                -- A use outside a slot (Void, wisps, -1) refunds nothing.
                local slot = c.slot or ActiveSlot.SLOT_PRIMARY
                if slot >= 0 and p:GetActiveItem(slot) == Item.IS_THIS_TRUE then
                    p:SetActiveCharge(math.min(3, p:GetActiveCharge(slot) + 1), slot)
                end
                C.Caption("Is this true?", "Confirmed. +1 charge")
            end
        end
    end)

    -- 20 Community Note state
    local notes = {}

    C.TargetModifier(function(npc, player)
        local m = 1
        local c = C.Data(player).room.challenge
        if c and c.expires >= C.Now() then
            m = m * (c.hash == GetPtrHash(npc) and 1.35 or 0.85)
        end
        local n = notes[GetPtrHash(player)]
        local exposed = n and n.exposed[GetPtrHash(npc)]
        if exposed and exposed >= C.Now() and player:HasCollectible(Item.COMMUNITY_NOTE) then m = m * 1.15 end
        return m
    end)

    -- 18 Live Wire
    C.Stat("speed", function(p)
        return (p:HasCollectible(Item.LIVE_WIRE) and C.Data(p).wire) and 0.15 or 0
    end)

    -- 19 Quote Retort
    C.On("playerHit", function(player)
        if player:HasCollectible(Item.QUOTE_RETORT) then C.Prime(player, "retort", 1.5, RETORT_FRAMES) end
    end)

    C.On("hit", function(npc, player, _, attackId)
        if not attackId or not player:HasCollectible(Item.COMMUNITY_NOTE) then return end
        local key = GetPtrHash(player)
        local n = notes[key]
        if not n then n = { hits = {}, exposed = {}, count = 0 }; notes[key] = n end
        local target = GetPtrHash(npc)
        if n.exposed[target] or n.count >= NOTE_MAX then return end
        n.hits[target] = n.hits[target] or {}
        local h = n.hits[target]
        if h[attackId] then return end
        h[attackId] = true
        h.n = (h.n or 0) + 1
        if h.n >= NOTE_HITS then
            n.exposed[target] = C.Now() + NOTE_FRAMES
            n.count = n.count + 1
            npc:SetColor(Color(1, 1, 1, 1, 0.1, 0.2, 0.4), NOTE_FRAMES, 1, false, false)
        end
    end)
    C.On("newRoom", function() notes = {} end)
    C.On("runReset", function() notes = {} end)

    C.On("update", function(frame)
        if frame % 5 ~= 0 then return end
        local roomEntities
        for _, p in ipairs(C.Players()) do
            if p:HasCollectible(Item.LIVE_WIRE) then
                local d = C.Data(p)
                -- Existence is enough: avoid a sorted result per owner. Share
                -- this observation only until a callback can change the room.
                roomEntities = roomEntities or Isaac.GetRoomEntities()
                local near = false
                for _, entity in ipairs(roomEntities) do
                    local bullet = C.OrdinaryBullet(entity)
                    if bullet and (bullet.Position - p.Position):LengthSquared() <= WIRE_RANGE * WIRE_RANGE then
                        near = true
                        break
                    end
                end
                if near ~= (d.wire == true) then
                    d.wire = near or nil
                    C.Refresh(p)
                    roomEntities = nil -- Cache callbacks may spawn or remove bullets.
                end
            end
            if C.Primed(p, "retort") then C.Label(p, "retort", "Retort +50% ready") else C.Label(p, "retort", nil) end
        end
    end)
end

return Grok
