-- Tainted Claude-chan (裏Claudeちゃん) - "Appeal Pending"
-- Character design by ZipZipPipe, used non-commercially with credit.
--
-- Each floor starts with 220 Quota and two Appeal Pages (cap two). A paid
-- attack costs one Quota (two with Subagent Swarm) and she deals 1.25x damage:
-- a same-frame volley of tears, laser starts and Dr. Fetus bombs, each further
-- 0.2-second window of a held beam or Ludovico tear, a knife throw, a melee
-- swing or an Epic Fetus rocket.
-- At zero she is Suspended: a usable 0.5x attack. A DROP tap while Suspended
-- spends a Page and starts six seconds of active-combat review, which restores
-- 60 Quota (90 with Birthright). Leaving the room cancels it without refund.
-- Three unique combat clears earn a Page. Range +1.5, Shot Speed +0.2.
-- Pocket item: Banked Reset, which refills Quota and cancels a pending review.

local Constants = include("scripts.constants")
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local PaidAttacks = include("scripts.characters.paid_attacks")

local TaintedClaude = {}

local QUOTA = 220
local PAGES = 2
local CLEARS_PER_PAGE = 3
local REVIEW_FRAMES = 180 -- Six active-combat seconds.
local REVIEW_QUOTA, BIRTHRIGHT_REVIEW_QUOTA = 60, 90
local SWARM_QUOTA = 1
local DAMAGE_MULT, SUSPENDED_DAMAGE = 1.25, 0.5

local TEAR_TINT = {0.85, 0.3, 0.2, 1}
local SUSPENDED_TINT = {0.4, 0.4, 0.4, 0.7}

local function isTainted(player)
    return player and Constants.Player.CLAUDE_CHAN_B >= 0
        and player:GetPlayerType() == Constants.Player.CLAUDE_CHAN_B
end
local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, quota=QUOTA, pages=PAGES, clears=0, awards={}}
end
local function valid(s)
    if type(s) ~= "table" or s.version ~= 1 or not integer(s.quota, 0, QUOTA)
        or not integer(s.pages, 0, PAGES) or not integer(s.clears, 0, CLEARS_PER_PAGE - 1)
        or type(s.awards) ~= "table" then return false end
    local r = s.review
    if r ~= nil and (type(r) ~= "table" or not integer(r.remaining, 1, REVIEW_FRAMES)
        or type(r.room) ~= "string") then return false end
    for k, v in pairs(s.awards) do
        if type(k) ~= "string" or v ~= true then return false end
    end
    return true
end
local function roomKey()
    local level = Game():GetLevel()
    local desc = level:GetCurrentRoomDesc()
    return tostring(level:GetDungeonPlacementSeed())..":"..tostring(desc.SpawnSeed)..":"..tostring(desc.SafeGridIndex)
end
local function refresh(player)
    player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_TEARCOLOR)
    player:EvaluateItems()
end

-- Stateless so Banked Reset can call it without sharing this module's closures.
-- Refills Quota and cancels a pending review; the spent Page is not returned.
function TaintedClaude.Refill(Risk, player)
    local all = Risk.state.claudeAppeal
    if type(all) ~= "table" or not isTainted(player) then return false end
    for i = 0, Game():GetNumPlayers() - 1 do
        if GetPtrHash(Isaac.GetPlayer(i)) == GetPtrHash(player) then
            local s = all[tostring(i)]
            if not valid(s) then return false end
            local wasSuspended = s.quota == 0
            s.quota = QUOTA; s.review = nil
            if wasSuspended then refresh(player) end
            return true
        end
    end
    return false
end

function TaintedClaude:Init(mod, Risk)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function allStates()
        if type(Risk.state.claudeAppeal) ~= "table" then Risk.state.claudeAppeal = {} end
        return Risk.state.claudeAppeal
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if isTainted(p) then
                if previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then all[key] = nil end
                if not valid(all[key]) then all[key] = fresh() end
                local b = bindings[pointer]
                if not b or b.seed ~= p.InitSeed or b.slot ~= key then
                    b = {seed=p.InitSeed, slot=key, frame=Game():GetFrameCount(), armed={}}
                end
                b.state = all[key]; nextBindings[pointer] = b
            else
                -- A character change discards the tainted allowance.
                all[key] = nil
            end
            nextSlots[key] = {pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do if not nextSlots[key] then all[key] = nil end end
        bindings, slots = nextBindings, nextSlots
    end
    local function binding(p)
        if not ready or not isTainted(p) then return end
        local b = bindings[GetPtrHash(p)]
        if b and b.seed == p.InitSeed then return b end
    end
    local function each(fn)
        for i = 0, Game():GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            local b = binding(p)
            if b then fn(p, b, i) end
        end
    end
    local function observeFloor(p, b)
        local s, level = b.state, Game():GetLevel()
        local floor = tostring(level:GetDungeonPlacementSeed())..":"..level:GetStage()..":"..level:GetStageType()
        if s.floor ~= floor then
            -- A new floor refills Quota and Pages; continue on the same floor does not.
            if s.floor ~= nil then
                local wasSuspended = s.quota == 0
                s.quota = QUOTA; s.pages = PAGES; s.review = nil; s.awards = {}
                b.armed = {}
                if wasSuspended then refresh(p) end
            end
            s.floor = floor
        end
    end
    local function observeRoom(b)
        local r = b.state.review
        if r and r.room ~= roomKey() then b.state.review = nil end
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.claudeAppeal = {} end
        bind()
        each(function(p, b) observeFloor(p, b); observeRoom(b); refresh(p) end)
        if continued or Constants.Item.BANKED_RESET <= 0 then return end
        each(function(p)
            p:SetPocketActiveItem(Constants.Item.BANKED_RESET, ActiveSlot.SLOT_POCKET, false)
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        -- Leaving the room cancels a review without returning its Page.
        each(function(p, b) b.volley = nil; observeFloor(p, b); observeRoom(b) end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() drop:Reset() end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not ready then return end
        bind()
        if not next(bindings) then return end
        local now = Game():GetFrameCount()
        if Game():IsPaused() then
            drop:Reset()
            each(function(_, b) b.frame = now end)
            return
        end
        local combat = not Game():GetRoom():IsClear()
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            observeFloor(p, b)
            observeRoom(b)
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            local advanced = now > b.frame
            if now < b.frame then b.volley = nil; drop:Forget(p) end
            b.frame = now
            if combat then b.armed[room] = true end
            -- Review advances during combat only while the owner stops attacking.
            local firing = p:GetShootingInput():LengthSquared() > 0 or b.attacked == now
            if advanced and combat and s.review and not firing then
                s.review.remaining = s.review.remaining - 1
                if s.review.remaining <= 0 then
                    s.review = nil
                    local restored = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
                        and BIRTHRIGHT_REVIEW_QUOTA or REVIEW_QUOTA
                    local wasSuspended = s.quota == 0
                    s.quota = math.min(QUOTA, s.quota + restored)
                    Game():GetHUD():ShowItemText("Appeal accepted", "Quota restored")
                    if wasSuspended then refresh(p) end
                end
            end
            if drop:Poll(p, s.quota == 0 and s.pages > 0 and s.review == nil,
                s.review and "Review in progress" or s.quota > 0 and "Quota remains" or "No Pages left") then
                s.pages = s.pages - 1
                s.review = {remaining=REVIEW_FRAMES, room=room}
                Game():GetHUD():ShowItemText("Appeal submitted", "Under review")
            end
        end)
    end)
    -- A unique clear is a newly completed hostile room on this floor.
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not ready or not next(bindings) then return end
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            if p:IsDead() or not b.armed[room] or s.awards[room] then return end
            s.awards[room] = true
            s.clears = s.clears + 1
            if s.clears >= CLEARS_PER_PAGE then
                s.clears = 0
                s.pages = math.min(PAGES, s.pages + 1)
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if not isTainted(player) then return end
        local b = binding(player)
        local suspended = b and b.state.quota == 0
        if flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * (suspended and SUSPENDED_DAMAGE or DAMAGE_MULT)
        elseif flag == CacheFlag.CACHE_RANGE then
            player.TearRange = player.TearRange + 1.5 * 40
        elseif flag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + 0.2
        elseif flag == CacheFlag.CACHE_TEARCOLOR then
            -- Tint rather than replace, so item colors stay readable.
            local k, c = suspended and SUSPENDED_TINT or TEAR_TINT, player.TearColor
            if c then player.TearColor = Color(c.R*k[1], c.G*k[2], c.B*k[3], c.A*k[4], c.RO, c.GO, c.BO)
            else player.TearColor = Color(k[1], k[2], k[3], k[4], 0, 0, 0) end
        end
    end)
    local function pay(p)
        local b = binding(p)
        if not b or p:IsDead() then return end
        local s, now = b.state, Game():GetFrameCount()
        b.attacked = now -- Observation only: suspended native attacks remain free.
        -- One volley is one payment; Suspended attacks are free.
        if b.volley == now or s.quota == 0 then return end
        b.volley = now
        local swarm = Constants.Item.SUBAGENT_SWARM
        local cost = 1 + ((swarm and swarm > 0 and p:HasCollectible(swarm)) and SWARM_QUOTA or 0)
        s.quota = math.max(0, s.quota - cost)
        if s.quota == 0 then
            Game():GetHUD():ShowItemText("Suspended", "Tap DROP to appeal")
            refresh(p)
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        if not ready or not next(bindings) then return end
        local data = tear:Exists() and tear:GetData()
        if not data or data.ccThoughtDerived or data.ccAppealSeen then return end
        data.ccAppealSeen = true
        pay(tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer())
    end)
    -- Lasers and Dr. Fetus bombs pay on the frame they start, sharing that
    -- frame's payment with tears; held beams, knives, swings and rockets pay
    -- through the shared observer.
    mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, function(_, laser)
        if not ready or not next(bindings) then return end
        if laser.Parent and laser.Parent.Type == EntityType.ENTITY_LASER then return end
        pay(laser.SpawnerEntity and laser.SpawnerEntity:ToPlayer())
    end)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(_, bomb)
        if not ready or not next(bindings) or not bomb.IsFetus then return end
        pay(bomb.SpawnerEntity and bomb.SpawnerEntity:ToPlayer())
    end)
    PaidAttacks.Observe(mod, pay)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if Game():IsPaused() then drop:Reset() end
        if not ready or not Game():GetHUD():IsVisible() then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s = b.state
            local y = HudLayout.PlayerRow(i)
            local pages = string.format("  Pages %d/%d", s.pages, PAGES)
            if s.review then
                local firing = p:GetShootingInput():LengthSquared() > 0 or b.attacked == Game():GetFrameCount()
                local label = firing and "Waiting for silence: " or "Under Review: "
                HudText:Draw(label..string.format("%ds", math.ceil(s.review.remaining / 30)) .. pages,
                    50, y, 1, 0.8, 0.4, 1)
            elseif s.quota == 0 then
                HudText:Draw("Suspended" .. pages, 50, y, 1, 0.3, 0.3, 1)
            else
                HudText:Draw(string.format("Quota %d/%d", s.quota, QUOTA) .. pages, 50, y, 1, 0.55, 0.4, 1)
            end
        end)
    end)
end

TaintedClaude.QUOTA = QUOTA

return TaintedClaude
