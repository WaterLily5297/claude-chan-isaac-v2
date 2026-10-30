-- Tainted GLM: Please Retry. Schedule a request on one enemy; if it is still
-- there when the request lands, it hits hard. Failed requests earn bounded,
-- deterministic Retry stacks. Saved per player: Retry stacks only.
local SaveSync = include("scripts.save_sync")
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Feedback = include("scripts.characters.feedback")
local Tools = include("scripts.characters.target_tools")
local Retry = {}

local BASE_DAMAGE = 0.9
local RADIUS = 200
local REQUEST_FRAMES = 60 -- Two seconds.
local COOLDOWN_FRAMES = 90 -- Three seconds from selection.
local REQUEST_DAMAGE, RETRY_DAMAGE = 2, 1
local RETRY_CAP = 3
local BULLET_RADIUS = 120

local function fresh()
    return {version=1, retries=0}
end
local function valid(s)
    return type(s) == "table" and s.version == 1 and type(s.retries) == "number"
        and s.retries >= 0 and s.retries <= RETRY_CAP and s.retries == math.floor(s.retries)
end

function Retry:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("GLM-chan", true)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isTainted(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.glmRetry) ~= "table" then Risk.state.glmRetry = {} end
        return Risk.state.glmRetry
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if isTainted(p) then
                local b = bindings[pointer]
                local sameOwner = b and b.seed == p.InitSeed
                -- Read the old slot before rebuilding the map: cyclic moves
                -- retain this owner's saved progress and transient ability.
                local s = all[sameOwner and b.slot or key]
                if not sameOwner and previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then s = nil end
                if not valid(s) then s = fresh() end
                if not sameOwner then
                    b = {seed=p.InitSeed, slot=key, cooldown=0, frame=Game():GetFrameCount()}
                end
                b.slot = key; b.state = s; nextBindings[pointer] = b
            end
            nextSlots[key] = {pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do all[key] = nil end
        for _, b in pairs(nextBindings) do all[b.slot] = b.state end
        bindings, slots = nextBindings, nextSlots
    end
    SaveSync.Register(Risk, "character.glm_retry", function()
        if ready then bind() end
    end)

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
    local function clearBullet(p)
        local best, distance
        for _, e in ipairs(Isaac.FindInRadius(p.Position, BULLET_RADIUS, EntityPartition.BULLET)) do
            if e:ToProjectile() and e:Exists() then
                local d = p.Position:Distance(e.Position)
                if d <= BULLET_RADIUS and (not distance or d < distance) then best, distance = e, d end
            end
        end
        if best then best:Remove() end
    end
    local function fail(p, b)
        local s = b.state
        b.request = nil
        s.retries = math.min(RETRY_CAP, s.retries + 1)
        Game():GetHUD():ShowItemText("GLM-chan", "Please retry")
        if p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then clearBullet(p) end
    end
    local function connected(p, target)
        return p.Position:Distance(target.Position) <= RADIUS
            and Game():GetRoom():CheckLine(p.Position, target.Position, 3)
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.glmRetry = {} end
        bind()
        each(function(p) p:AddCacheFlags(CacheFlag.CACHE_DAMAGE); p:EvaluateItems() end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        -- Leaving cancels a pending request without earning a Retry.
        each(function(_, b) b.request = nil end)
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
        each(function(p, b)
            local s = b.state
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            local advanced = now > b.frame
            b.frame = now
            if advanced then b.cooldown = math.max(0, b.cooldown - 1) end
            local request = b.request
            if request then
                local target = request.ref.Ref
                if not target or not target:Exists() or target:IsDead() then
                    fail(p, b)
                elseif not target:IsVulnerableEnemy() or target:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                    b.request = nil
                    Game():GetHUD():ShowItemText("GLM-chan", "Target unavailable: request cancelled")
                elseif advanced then
                    request.remaining = request.remaining - 1
                    if request.remaining <= 0 then
                        b.request = nil
                        if connected(p, target) then
                            target:TakeDamage(p.Damage * (REQUEST_DAMAGE + RETRY_DAMAGE * s.retries), 0, EntityRef(p), 0)
                            Feedback.Burst(target.Position, Color(0.8, 0.5, 1, 1, 0.2, 0, 0.3))
                            s.retries = 0
                            Game():GetHUD():ShowItemText("GLM-chan", "Request complete")
                        else
                            Game():GetHUD():ShowItemText("GLM-chan", "Connection lost: request timed out")
                        end
                    end
                end
            end
            -- The cooldown outlasts the request, so only one is ever pending.
            if drop:Poll(p, combat and b.cooldown == 0,
                not combat and "Needs combat" or "Request cooling down") then
                local target = Tools.Nearest(p.Position, RADIUS)
                -- No target means no request and no cooldown.
                if target then
                    b.request = {ref=EntityPtr(target), remaining=REQUEST_FRAMES}
                    Feedback.Mark(target, Color(1, 1, 1, 1, 0.3, 0.1, 0.35), REQUEST_FRAMES)
                    b.cooldown = COOLDOWN_FRAMES
                    Game():GetHUD():ShowItemText("GLM-chan", "Request queued")
                else
                    drop:Refuse(p, "No target in range")
                end
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag == CacheFlag.CACHE_DAMAGE and binding(p) then p.Damage = p.Damage * BASE_DAMAGE end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() or not next(bindings) then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local text = string.format("GLM-chan: Retries %d/%d", b.state.retries, RETRY_CAP)
            if b.request then text = text..string.format("  Request Pending %ds", math.ceil(b.request.remaining / 30))
            elseif b.cooldown > 0 then text = text..string.format("  Cooldown %ds", math.ceil(b.cooldown / 30)) end
            local target = b.request and b.request.ref.Ref
            if target and target:Exists() and not connected(p, target) then text = text.."  Restore connection" end
            HudLayout.DrawPlayer(HudText, i, text, 0.4, 0.8, 1, 0.9)
        end)
    end)
end

return Retry
