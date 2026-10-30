-- Tainted Mistral: Le Gros Chaton. Sit still to bake Baguettes, then send a slow
-- bread shockwave forward. The exaggeration lives in the bread effect; the
-- player's size and collision are unchanged. Saved per player: stored Baguettes.
-- Charge, cooldown and the travelling wave are transient.
local SaveSync = include("scripts.save_sync")
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Feedback = include("scripts.characters.feedback")
local Baguette = {}

local SPEED = -0.1
local BASE_DAMAGE = 0.9
local BAGUETTE_CAP = 2
local CHARGE_FRAMES, BIRTHRIGHT_CHARGE = 60, 45 -- Two seconds standing without firing; 1.5 with Birthright.
local COOLDOWN_FRAMES = 60
local WAVE_STEP = 4 -- Units per frame; full travel takes one second.
local WAVE_TRAVEL = 120
local HALF_WIDTH = 24
local DAMAGE = 2.5

local function fresh()
    return {version=1, baguettes=0}
end
local function valid(s)
    return type(s) == "table" and s.version == 1 and type(s.baguettes) == "number"
        and s.baguettes >= 0 and s.baguettes <= BAGUETTE_CAP and s.baguettes == math.floor(s.baguettes)
end
local function moving(p) return p.Velocity:Length() > 0.5 end
local function firing(p) return p:GetShootingInput():LengthSquared() > 0 end

function Baguette:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Mistral-chan", true)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isTainted(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.mistralBaguette) ~= "table" then Risk.state.mistralBaguette = {} end
        return Risk.state.mistralBaguette
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
                    b = {seed=p.InitSeed, slot=key, charge=0, cooldown=0, frame=Game():GetFrameCount()}
                end
                b.slot = key; b.state = s; nextBindings[pointer] = b
            end
            nextSlots[key] = {pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do all[key] = nil end
        for _, b in pairs(nextBindings) do all[b.slot] = b.state end
        bindings, slots = nextBindings, nextSlots
    end
    SaveSync.Register(Risk, "character.mistral_baguette", function()
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
    -- Aim first, then movement; otherwise the wave rolls downward.
    local function forward(p)
        local aim = p:GetShootingInput()
        if aim:LengthSquared() > 0 then return aim:Normalized() end
        if moving(p) then return p.Velocity:Normalized() end
        return Vector(0, 1)
    end
    -- Advance the wave one step; it hits each target once and stops at walls.
    local function roll(p, wave)
        wave.travel = math.min(WAVE_TRAVEL, wave.travel + WAVE_STEP)
        local pos = wave.origin + wave.dir * wave.travel
        if not Game():GetRoom():CheckLine(wave.origin, pos, 3) then return false end
        -- Crumbs mark the rolling bread every 24 units.
        if wave.travel % 24 == 0 then Feedback.Burst(pos, Color(1, 0.85, 0.45, 1, 0.25, 0.15, 0)) end
        for _, e in ipairs(Isaac.FindInRadius(pos, HALF_WIDTH + WAVE_STEP, EntityPartition.ENEMY)) do
            local hash = GetPtrHash(e)
            if not wave.hit[hash] and e:IsVulnerableEnemy() and not e:IsDead()
                and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
                and pos:Distance(e.Position) <= HALF_WIDTH + e.Size then
                wave.hit[hash] = true
                e:TakeDamage(p.Damage * DAMAGE, 0, EntityRef(p), 0)
            end
        end
        return wave.travel < WAVE_TRAVEL
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.mistralBaguette = {} end
        bind()
        each(function(p)
            p:AddCacheFlags(CacheFlag.CACHE_SPEED | CacheFlag.CACHE_DAMAGE); p:EvaluateItems()
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        each(function(_, b) b.wave = nil; b.charge = 0 end)
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
        each(function(p, b)
            local s = b.state
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            if now > b.frame then
                b.cooldown = math.max(0, b.cooldown - 1)
                if b.wave and not roll(p, b.wave) then b.wave = nil end
                local need = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_CHARGE or CHARGE_FRAMES
                if Game():GetRoom():IsClear() then
                    -- Safety pauses partial baking; room exit still discards it.
                elseif s.baguettes < BAGUETTE_CAP and not moving(p) and not firing(p) then
                    b.charge = b.charge + 1
                    if b.charge >= need then
                        b.charge = 0; s.baguettes = s.baguettes + 1
                        Game():GetHUD():ShowItemText("Mistral-chan", "Baguette baked")
                    end
                else
                    b.charge = 0
                end
            end
            b.frame = now
            if drop:Poll(p, s.baguettes > 0 and b.cooldown == 0,
                b.cooldown > 0 and "Wave cooling down" or "No Baguettes left") then
                s.baguettes = s.baguettes - 1; b.cooldown = COOLDOWN_FRAMES
                b.wave = {origin=p.Position, dir=forward(p), travel=0, hit={}}
                Game():GetHUD():ShowItemText("Mistral-chan", "Baguette!")
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if not binding(p) then return end
        if flag == CacheFlag.CACHE_SPEED then p.MoveSpeed = p.MoveSpeed + SPEED
        elseif flag == CacheFlag.CACHE_DAMAGE then p.Damage = p.Damage * BASE_DAMAGE end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() or not next(bindings) then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local text = string.format("Mistral-chan: Baguettes %d/%d", b.state.baguettes, BAGUETTE_CAP)
            if b.cooldown > 0 then text = text..string.format("  Cooldown %ds", math.ceil(b.cooldown / 30)) end
            if Game():GetRoom():IsClear() and b.state.baguettes < BAGUETTE_CAP then text = text.."  Combat to bake" end
            HudLayout.DrawPlayer(HudText, i, text, 1, 0.7, 0.3, 0.9)
        end)
    end)
end

return Baguette
