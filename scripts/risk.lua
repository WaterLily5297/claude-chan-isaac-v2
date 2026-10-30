-- Risk score ("fengkong" value): the heart of the mod.
--
-- Each floor rolls a random proxy IP with a number of users sharing it.
-- The more crowded the IP, the more the risk system distrusts you.
-- Taking damage looks like "abnormal behaviour" (+1); clearing a room
-- without getting hit looks like a normal user (-1).
--
-- At 90+ the account is Suspended: damage x0.75 until risk drops again.
-- The Appeal Form trinket is used up the moment risk reaches 90 and brings it
-- back to 50 instead.

local json = require("json")
local Constants = include("scripts.constants")
local HudText = include("scripts.hud_text")
local ModelRoster = include("scripts.characters.model_roster")
local SaveSync = include("scripts.save_sync")

local Risk = {}

local function defaultState()
    return {
        risk = 0,
        ip = "0.0.0.0",
        sharedUsers = 0,
        residentialApplied = false,
        relayApplied = false,
        constitutionApplied = false,
        constitutionBlockUsed = false,
        silentMult = 1,
    }
end

Risk.state = defaultState()

local SUSPEND_AT = 90
local SUSPENDED_DAMAGE_MULT = 0.75
local APPEAL_RESET_TO = 50

local started = false
local hitThisRoom = false
-- Set on a new floor; the save runs on the next update, after every module
-- has finished its own floor callbacks.
local checkpoint = false

local function clamp(v)
    return math.max(0, math.min(Constants.RISK_MAX, v))
end

local function anyPlayerHas(item)
    if item <= 0 then return false end
    for i = 0, Game():GetNumPlayers() - 1 do
        if Isaac.GetPlayer(i):HasCollectible(item) then
            return true
        end
    end
    return false
end

local function anyPlayerHasTrinket(trinket)
    if trinket <= 0 then return false end
    for i = 0, Game():GetNumPlayers() - 1 do
        if Isaac.GetPlayer(i):HasTrinket(trinket) then
            return true
        end
    end
    return false
end

-- The proxy account belongs to the Claude forms. DeepSeek-chan connects
-- directly, the model roster families have their own loops, and vanilla (or
-- other mods') characters play vanilla: no IP, risk, scaling or Hydra.
local function covered(player)
    if player == nil or Constants.IsDeepSeek(player) or ModelRoster:IsFamily(player) then return false end
    local t = player:GetPlayerType()
    return (Constants.Player.CLAUDE_CHAN >= 0 and t == Constants.Player.CLAUDE_CHAN)
        or (Constants.Player.CLAUDE_CHAN_B >= 0 and t == Constants.Player.CLAUDE_CHAN_B)
end

-- When no player is covered the whole IP / risk system sleeps: risk reads as
-- 0, never rises, and no IP is rolled. In co-op with a covered player it runs,
-- but only covered players are hurt by suspension or raise risk when hit.
function Risk:IsActive()
    local n = Game():GetNumPlayers()
    for i = 0, n - 1 do
        if covered(Isaac.GetPlayer(i)) then
            return true
        end
    end
    return n == 0
end

function Risk:Get()
    if not self:IsActive() then return 0 end
    return self.state.risk
end

local function refreshDamage()
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        player:EvaluateItems()
    end
end

-- Uses up one Appeal Form, if anyone holds one. Returns true on success.
local function fileAppeal()
    local trinket = Constants.Trinket.APPEAL_FORM
    if trinket <= 0 then return false end
    for i = 0, Game():GetNumPlayers() - 1 do
        local player = Isaac.GetPlayer(i)
        if player:HasTrinket(trinket) and player:TryRemoveTrinket(trinket) then
            return true
        end
    end
    return false
end

function Risk:IsSuspended()
    return self:Get() >= SUSPEND_AT
end

function Risk:Add(amount)
    if not self:IsActive() then return end
    local wasSuspended = self:IsSuspended()
    -- Residential IP halves every risk increase.
    if amount > 0 and anyPlayerHas(Constants.Item.RESIDENTIAL_IP) then
        amount = math.ceil(amount / 2)
    end
    -- Status Page shaves 1 off every increase (but hides the real number).
    if amount > 0 and anyPlayerHasTrinket(Constants.Trinket.STATUS_PAGE) then
        amount = amount - 1
    end
    self.state.risk = clamp(self.state.risk + amount)

    if not wasSuspended and self:IsSuspended() then
        if fileAppeal() then
            self.state.risk = APPEAL_RESET_TO
            Game():GetHUD():ShowItemText("Appeal approved", "Your account has been restored")
        else
            Game():GetHUD():ShowItemText("Account suspended", "Damage down until your risk drops")
        end
    end
    if wasSuspended ~= self:IsSuspended() then
        refreshDamage()
    end
end

function Risk:GetTier()
    local tier = Constants.Tier[1]
    for _, t in ipairs(Constants.Tier) do
        if self.state.risk >= t.min then
            tier = t
        end
    end
    return tier
end

-- Roll a new IP for the current floor and add the risk it brings.
function Risk:RollIp()
    if not self:IsActive() then return end
    local stage = Game():GetLevel():GetStage()
    local seed = Game():GetSeeds():GetStartSeed() + stage * 7919
    local rng = RNG()
    rng:SetSeed(math.max(1, seed), 35)

    self.state.ip = string.format("%d.%d.%d.%d",
        rng:RandomInt(223) + 1, rng:RandomInt(256), rng:RandomInt(256), rng:RandomInt(254) + 1)

    -- Most proxies are lightly shared; a few are packed relay servers.
    local shared = rng:RandomInt(20) + 1
    if rng:RandomFloat() < 0.3 then
        shared = shared + rng:RandomInt(200)
    end
    self.state.sharedUsers = shared

    self:Add(math.floor(shared / 10) + stage)
end

function Risk:Save(mod)
    if started then SaveSync.Run(self) end
    mod:SaveData(json.encode(self.state))
end

function Risk:Load(mod)
    self.state = defaultState()
    if mod:HasData() then
        local ok, data = pcall(json.decode, mod:LoadData())
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                self.state[k] = v
            end
        end
    end
end

function Risk:Init(mod)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if flag == CacheFlag.CACHE_DAMAGE and covered(player) and Risk:IsSuspended() then
            player.Damage = player.Damage * SUSPENDED_DAMAGE_MULT
        end
    end)

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
        hitThisRoom = false -- Do not inherit a previous run's transient latch.
        checkpoint = false
        if isContinued then
            Risk:Load(mod)
        else
            Risk.state = defaultState()
            Risk:RollIp()
        end
        started = true
    end)

    -- Save while live ownership bindings still exist, before normal cleanup.
    mod:AddPriorityCallback(ModCallbacks.MC_PRE_GAME_EXIT, CallbackPriority.EARLY, function(_, shouldSave)
        if started and shouldSave then
            Risk:Save(mod)
        end
        started, checkpoint = false, false
    end)

    -- POST_NEW_LEVEL also fires before POST_GAME_STARTED when a run begins;
    -- the first floor is handled there, so ignore it until the run has started.
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        if started then
            Risk:RollIp()
            checkpoint = true
        end
    end)

    -- Checkpoint every floor as well as on exit. If the game closes without a
    -- normal exit (crash, forced close), continuing must not load mod state
    -- from an older session or a different run.
    -- Include normal update handlers' floor, cap and ownership changes.
    mod:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.LATE, function()
        if started and checkpoint then
            Risk:Save(mod)
            checkpoint = false
        end
    end)

    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        hitThisRoom = false
    end)

    -- Let ordinary damage blockers run first; refused hits are not mistakes.
    mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.LATE, function(_, entity, _, flags)
        if not started or not covered(entity:ToPlayer()) then return end
        if ((flags or 0) & (DamageFlag.DAMAGE_FAKE | DamageFlag.DAMAGE_NO_PENALTIES)) ~= 0 then return end
        hitThisRoom = true
        Risk:Add(1)
    end, EntityType.ENTITY_PLAYER)

    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not hitThisRoom then
            Risk:Add(-1)
        end
    end)

    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not started or not Game():GetHUD():IsVisible() then return end

        local y = Isaac.GetScreenHeight() - 28
        if not Risk:IsActive() then
            HudText:Draw(HudText:T("direct"), 50, y + 12, 0.45, 0.75, 1, 1)
            return
        end
        local tier = Risk:GetTier()
        local c = tier.color
        HudText:Draw(HudText:T("ip", Risk.state.ip, Risk.state.sharedUsers), 50, y, 1, 1, 1, 0.8)
        if anyPlayerHasTrinket(Constants.Trinket.STATUS_PAGE) then
            HudText:Draw(HudText:T("operational"), 50, y + 12, 0.4, 1, 0.4, 1)
        else
            HudText:Draw(HudText:T("risk", Risk.state.risk, Constants.RISK_MAX, HudText:T(tier.label)),
                50, y + 12, c[1], c[2], c[3], 1)
        end
    end)
end

return Risk
