-- Opus Mode (passive, shop pool)
-- "More expensive than gold": damage x1.8, but every 10 attacks cost 1 coin.
-- An attack is a tear, a laser start, a Dr. Fetus bomb, or anything the shared
-- paid-attack observer bills (each held-beam or Ludovico window, knife throw,
-- swing and Epic Fetus rocket), so Brimstone or Mom's Knife never run free.
-- Out of coins, you fall back to the cheap model: damage x0.6 until you have
-- money again. The partial ten-attack count is saved per player slot, so
-- Continue does not wipe a nearly finished bill.

local Constants = include("scripts.constants")
local PaidAttacks = include("scripts.characters.paid_attacks")
local SlotOwners = include("scripts.items.slot_owners")
local SaveSync = include("scripts.save_sync")

local OpusMode = {}

local OPUS_MULT = 1.8
local FALLBACK_MULT = 0.6
local TEARS_PER_COIN = 10

local function refresh(player)
    player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
    player:EvaluateItems()
end

-- Risk is optional so standalone billing fixtures can omit saved state.
function OpusMode:Init(mod, Risk)
    local owners = SlotOwners.New()
    local started = false
    if Risk then
        mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function() started = true; owners:Reset() end)
        mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function() started = false; owners:Reset() end)
        SaveSync.Register(Risk, "opusTears", function()
            if started and type(Risk.state.opusTears) == "table" then owners:Observe(Risk.state.opusTears) end
        end)
    end
    -- Saved count map and this player's slot key; it follows the live owner (F6).
    local function saved(player)
        if not Risk then return nil end
        if type(Risk.state.opusTears) ~= "table" then Risk.state.opusTears = {} end
        local all = Risk.state.opusTears
        owners:Observe(all)
        for i = 0, Game():GetNumPlayers() - 1 do
            if GetPtrHash(Isaac.GetPlayer(i)) == GetPtrHash(player) then return all, tostring(i) end
        end
    end

    local function bill(player)
        if not player or not player:HasCollectible(Constants.Item.OPUS_MODE) then
            return
        end

        local data = player:GetData()
        local all, key = saved(player)
        if data.ccOpusTears == nil and key then
            -- Entity data is gone after Continue; resume from the saved count.
            local v = all[key]
            data.ccOpusTears = (type(v) == "number" and v >= 0 and v < TEARS_PER_COIN and v == math.floor(v)) and v or 0
        end
        data.ccOpusTears = (data.ccOpusTears or 0) + 1
        if data.ccOpusTears >= TEARS_PER_COIN then
            data.ccOpusTears = 0
            if player:GetNumCoins() > 0 then
                player:AddCoins(-1)
            end
        end
        if key then all[key] = data.ccOpusTears end
    end
    local function spawner(entity)
        return entity.SpawnerEntity and entity.SpawnerEntity:ToPlayer()
    end

    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        local player = spawner(tear)
        -- Backlog helpers are marked after this callback in main.lua. Their
        -- synchronous spawn scope must be checked before charging the owner.
        if tear:GetData().ccThoughtDerived
            or (player and (player:GetData().ccDerivedTearDepth or 0) > 0) then return end
        bill(player)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, function(_, laser)
        -- Child beams (Tech X rings splitting, laser reflections) ride their parent.
        if laser.Parent and laser.Parent.Type == EntityType.ENTITY_LASER then return end
        bill(spawner(laser))
    end)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(_, bomb)
        if bomb.IsFetus then bill(spawner(bomb)) end
    end)
    PaidAttacks.Observe(mod, function(player) bill(player) end)

    -- Switch between Opus and the fallback whenever the wallet hits or leaves 0.
    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
        if not player:HasCollectible(Constants.Item.OPUS_MODE) then return end

        local data = player:GetData()
        local broke = player:GetNumCoins() == 0
        if broke ~= (data.ccOpusBroke == true) then
            data.ccOpusBroke = broke
            refresh(player)
            if broke then
                Game():GetHUD():ShowItemText("Out of credits", "Falling back to a cheaper model")
            end
        end
    end)

    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if flag == CacheFlag.CACHE_DAMAGE and player:HasCollectible(Constants.Item.OPUS_MODE) then
            -- Cache evaluation may precede the next wallet notification update.
            local mult = player:GetNumCoins() == 0 and FALLBACK_MULT or OPUS_MULT
            player.Damage = player.Damage * mult
        end
    end)
end

return OpusMode
