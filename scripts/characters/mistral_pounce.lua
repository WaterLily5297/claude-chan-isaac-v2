-- Normal Mistral: Le Chat. Move while firing to charge a Pounce, then swipe forward.
-- No player teleport or contact immunity. The ready Pounce is saved per player;
-- charge and cooldown are transient.
local SaveSync = include("scripts.save_sync")
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Feedback = include("scripts.characters.feedback")
local Mistral = {}

local SPEED = 0.1
local CHARGE_FRAMES = 60 -- Two seconds of moving while firing.
local IDLE_FRAMES = 30 -- Standing still for one second loses an unused Pounce.
local COOLDOWN_FRAMES = 90
local REACH, BIRTHRIGHT_REACH = 80, 110
local HALF_WIDTH = 20
local DAMAGE = 2

local function fresh()
    return {version=2, ready=false, dirX=0, dirY=1}
end
local function valid(s)
    return type(s) == "table" and type(s.ready) == "boolean" and (s.version == 1
        or (s.version == 2 and type(s.dirX) == "number" and type(s.dirY) == "number"
            and math.abs(s.dirX * s.dirX + s.dirY * s.dirY - 1) < 0.0001))
end
local function moving(p) return p.Velocity:Length() > 0.5 end
local function firing(p) return p:GetShootingInput():LengthSquared() > 0 end

function Mistral:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Mistral-chan", false)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isMistral(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.mistralPounce) ~= "table" then Risk.state.mistralPounce = {} end
        return Risk.state.mistralPounce
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if isMistral(p) then
                local b = bindings[pointer]
                local sameOwner = b and b.seed == p.InitSeed
                -- Read the old slot before rebuilding the map: cyclic moves
                -- retain this owner's saved progress and transient ability.
                local s = all[sameOwner and b.slot or key]
                if not sameOwner and previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then s = nil end
                if not valid(s) then s = fresh() end
                if s.version == 1 then s.version = 2; s.dirX = 0; s.dirY = 1 end
                if not sameOwner then
                    b = {seed=p.InitSeed, slot=key, charge=0, idle=0, cooldown=0, frame=Game():GetFrameCount()}
                end
                b.slot = key; b.state = s; nextBindings[pointer] = b
            end
            nextSlots[key] = {pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do all[key] = nil end
        for _, b in pairs(nextBindings) do all[b.slot] = b.state end
        bindings, slots = nextBindings, nextSlots
    end
    SaveSync.Register(Risk, "character.mistral_pounce", function()
        if ready then bind() end
    end)

    local function binding(p)
        if not ready or not isMistral(p) then return end
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
    local function direction(s)
        local names = {"Right", "Down-right", "Down", "Down-left", "Left", "Up-left", "Up", "Up-right"}
        local angle = math.atan(s.dirY, s.dirX)
        return names[math.floor(angle / (math.pi / 4) + 0.5) % 8 + 1]
    end
    -- One hit per target along a forward line; walls between stop it.
    local function swipe(p, s)
        local dir = Vector(s.dirX, s.dirY)
        local reach = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_REACH or REACH
        local room = Game():GetRoom()
        local hit = 0
        for _, e in ipairs(Isaac.FindInRadius(p.Position, reach + HALF_WIDTH, EntityPartition.ENEMY)) do
            if e:IsVulnerableEnemy() and not e:IsDead() and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
                local offset = e.Position - p.Position
                local along = offset.X * dir.X + offset.Y * dir.Y
                local across = math.abs(offset.X * dir.Y - offset.Y * dir.X)
                if along >= 0 and along <= reach and across <= HALF_WIDTH + e.Size
                    and room:CheckLine(p.Position, e.Position, 3) then
                    e:TakeDamage(p.Damage * DAMAGE, 0, EntityRef(p), 0)
                    Feedback.Burst(e.Position, Color(1, 0.7, 0.3, 1, 0.2, 0.1, 0))
                    hit = hit + 1
                end
            end
        end
        -- The swipe itself: a poof halfway along the line, where walls allow.
        local mid = Vector(p.Position.X + dir.X * reach / 2, p.Position.Y + dir.Y * reach / 2)
        if room:CheckLine(p.Position, mid, 3) then Feedback.Burst(mid, Color(1, 0.7, 0.3, 1, 0.2, 0.1, 0)) end
        return hit
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.mistralPounce = {} end
        bind()
        each(function(p) p:AddCacheFlags(CacheFlag.CACHE_SPEED); p:EvaluateItems() end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if ready then bind() end
    end)
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
        each(function(p, b)
            local s = b.state
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            if now > b.frame then
                b.cooldown = math.max(0, b.cooldown - 1)
                if moving(p) then b.idle = 0 else b.idle = b.idle + 1 end
                if s.ready and b.idle >= IDLE_FRAMES then
                    s.ready = false
                    Game():GetHUD():ShowItemText("Mistral-chan", "Pounce lost")
                end
                if b.cooldown == 0 and moving(p) and firing(p) then
                    local dir = p.Velocity:Normalized()
                    -- Preserve free movement during the initial charge. Replacing
                    -- a ready direction requires holding a new course, not slowly
                    -- rotating through many small turns that evade the threshold.
                    if s.ready and b.chargeX and dir.X * b.chargeX + dir.Y * b.chargeY < 0.99 then
                        b.charge = 0
                    end
                    if b.charge == 0 then b.chargeX, b.chargeY = dir.X, dir.Y end
                    b.charge = b.charge + 1
                    if b.charge >= CHARGE_FRAMES then
                        b.charge = 0; s.ready = true; s.dirX, s.dirY = dir.X, dir.Y
                    end
                else
                    b.charge = 0; b.chargeX = nil; b.chargeY = nil
                end
            end
            b.frame = now
            if drop:Poll(p, s.ready,
                "Charge: move while firing") then
                s.ready = false; b.cooldown = COOLDOWN_FRAMES; b.charge = 0
                swipe(p, s)
                Game():GetHUD():ShowItemText("Mistral-chan", "Pounce!")
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag == CacheFlag.CACHE_SPEED and binding(p) then p.MoveSpeed = p.MoveSpeed + SPEED end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local text
            if b.state.ready then text = "Mistral-chan: Pounce Ready "..direction(b.state)
            elseif b.cooldown > 0 then text = string.format("Mistral-chan: Cooldown %ds", math.ceil(b.cooldown / 30))
            else text = string.format("Mistral-chan: Charge %d%%", math.floor(b.charge * 100 / CHARGE_FRAMES)) end
            HudLayout.DrawPlayer(HudText, i, text, 1, 0.7, 0.3, 0.9)
        end)
    end)
end

return Mistral
