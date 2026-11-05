-- Vibe Coding (passive)
-- Every tear gets a random effect (homing, piercing, spectral, poison or slow),
-- and 5% of tears are bugs that fly backwards. Each new floor the API bill
-- arrives and you lose a quarter of your coins, unless you "made no
-- mistakes" (took no hit) on the floor you just left: then it's waived.

local Constants = include("scripts.constants")
local SlotOwners = include("scripts.items.slot_owners")
local SaveSync = include("scripts.save_sync")

local VibeCoding = {}

local BUG_CHANCE = 0.05
local BILL_SHARE = 0.25

local EFFECTS = {
    TearFlags.TEAR_HOMING,
    TearFlags.TEAR_PIERCING,
    TearFlags.TEAR_SPECTRAL,
    TearFlags.TEAR_POISON,
    TearFlags.TEAR_SLOW,
}

function VibeCoding:Init(mod, Risk)
    local rng = RNG()
    local started = false
    local owners = SlotOwners.New()

    -- Saved by player slot; a slot's mark follows its live owner (F6).
    local function mistakes()
        if type(Risk.state.vibeMistakes) ~= "table" then Risk.state.vibeMistakes = {} end
        owners:Observe(Risk.state.vibeMistakes)
        return Risk.state.vibeMistakes
    end

    SaveSync.Register(Risk, "vibeMistakes", function()
        if started and type(Risk.state.vibeMistakes) == "table" then owners:Observe(Risk.state.vibeMistakes) end
    end)

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
        rng:SetSeed(math.max(1, Game():GetSeeds():GetStartSeed() + 1986), 35)
        owners:Reset()
        started = true -- Risk has already reset or loaded the shared run state.
    end)

    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        started = false
        owners:Reset()
    end)

    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
        if not player or not player:HasCollectible(Constants.Item.VIBE_CODING) then
            return
        end

        if rng:RandomFloat() < BUG_CHANCE then
            tear.Velocity = tear.Velocity * -1
        else
            tear:AddTearFlags(EFFECTS[rng:RandomInt(#EFFECTS) + 1])
        end
    end)

    -- Observe after ordinary blockers (including backlog shields). Cancelled,
    -- fake and no-penalty damage must not spoil the floor's billing waiver.
    mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.LATE, function(_, entity, _, flags)
        local player = entity:ToPlayer()
        if not player or not started then return end
        if ((flags or 0) & (DamageFlag.DAMAGE_FAKE | DamageFlag.DAMAGE_NO_PENALTIES)) ~= 0 then return end
        local hit = mistakes()
        for i = 0, Game():GetNumPlayers() - 1 do
            if GetPtrHash(Isaac.GetPlayer(i)) == GetPtrHash(player) then
                -- Save by player slot; entity pointers and GetData do not survive continue.
                hit[tostring(i)] = true
                break
            end
        end
    end, EntityType.ENTITY_PLAYER)

    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        -- The engine also emits NEW_LEVEL before GAME_STARTED on startup.
        if not started then return end
        local hit = mistakes()
        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            local bill = math.floor(player:GetNumCoins() * BILL_SHARE)
            if player:HasCollectible(Constants.Item.VIBE_CODING) and bill > 0 then
                if hit[tostring(i)] then
                    player:AddCoins(-bill)
                    Game():GetHUD():ShowItemText("API bill", string.format("-%d coins", bill))
                else
                    Game():GetHUD():ShowItemText("Made no mistakes", "API bill waived this floor")
                end
            end
        end
        Risk.state.vibeMistakes = {}
    end)
end

return VibeCoding
