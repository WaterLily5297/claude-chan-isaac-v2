-- Tainted Doubao: I'll Do It Again. An overpromise/recovery cycle: Confident,
-- then Apology, then ready to promise again. Timers run only in hostile combat.
-- Saved per player: the current phase and its remaining frames.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Again = {}

local CONFIDENT_FRAMES = 180 -- Six seconds.
local APOLOGY_FRAMES, BIRTHRIGHT_APOLOGY = 120, 90 -- Four seconds; three with Birthright.
local CONFIDENT_DAMAGE, APOLOGY_DAMAGE = 1.35, 0.85
local PHASES = {confident=CONFIDENT_FRAMES, apology=APOLOGY_FRAMES}

local function fresh()
    return {version=1}
end
local function valid(s)
    if type(s) ~= "table" or s.version ~= 1 then return false end
    if s.phase == nil then return s.remaining == nil end
    local max = PHASES[s.phase]
    return max ~= nil and type(s.remaining) == "number" and s.remaining >= 1 and s.remaining <= max
        and s.remaining == math.floor(s.remaining)
end

function Again:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Doubao-chan", true)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isTainted(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.doubaoAgain) ~= "table" then Risk.state.doubaoAgain = {} end
        return Risk.state.doubaoAgain
    end
    local function refresh(p)
        p:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
        p:EvaluateItems()
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
                    b = {seed=p.InitSeed, slot=key, frame=Game():GetFrameCount()}
                end
                b.slot = key; b.state = s; nextBindings[pointer] = b
            end
            nextSlots[key] = {pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do all[key] = nil end
        for _, b in pairs(nextBindings) do all[b.slot] = b.state end
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
    local function apologize(p, s)
        s.phase = "apology"
        s.remaining = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_APOLOGY or APOLOGY_FRAMES
        Game():GetHUD():ShowItemText("Doubao-chan", "Sorry, you're right")
        refresh(p)
    end
    -- Only enemies and their bullets qualify; machines, curses and self-damage do not.
    local function enemyCaused(source)
        local e = source and source.Entity
        if not e then return false end
        if e.Type == EntityType.ENTITY_PROJECTILE then return true end
        return e:IsEnemy() and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.doubaoAgain = {} end
        bind()
        each(function(p) refresh(p) end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if ready then bind(); each(function(_, b) b.armed = false end) end
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
            if combat then b.armed = true end
            if s.phase and combat and advanced then
                s.remaining = s.remaining - 1
                if s.remaining <= 0 then
                    if s.phase == "confident" then apologize(p, s)
                    else
                        s.phase = nil; s.remaining = nil
                        Game():GetHUD():ShowItemText("Doubao-chan", "I'll do it again")
                        refresh(p)
                    end
                end
            end
            if drop:Poll(p, s.phase == nil,
                s.phase == "confident" and "Already Confident" or "Still recovering") then
                s.phase = "confident"; s.remaining = CONFIDENT_FRAMES
                Game():GetHUD():ShowItemText("Doubao-chan", "Leave it to me!")
                refresh(p)
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not ready then return end
        each(function(p, b)
            if not b.armed then return end
            b.armed = false
            if not p:IsDead() and b.state.phase == "confident" then apologize(p, b.state) end
        end)
    end)
    -- A real enemy hit during Confident starts the Apology early; the hit still lands.
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, _, flags, source)
        if not ready or not next(bindings) then return end
        local p = entity:ToPlayer()
        local b = binding(p)
        if not b or b.state.phase ~= "confident" then return end
        if (flags & (DamageFlag.DAMAGE_FAKE | DamageFlag.DAMAGE_NO_PENALTIES)) ~= 0 then return end
        if not enemyCaused(source) then return end
        apologize(p, b.state)
    end, EntityType.ENTITY_PLAYER)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag ~= CacheFlag.CACHE_DAMAGE then return end
        local b = binding(p)
        if not b then return end
        if b.state.phase == "confident" then p.Damage = p.Damage * CONFIDENT_DAMAGE
        elseif b.state.phase == "apology" then p.Damage = p.Damage * APOLOGY_DAMAGE end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() or not next(bindings) then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s, text = b.state, "Doubao-chan: Ready to promise"
            if s.phase == "confident" then text = string.format("Doubao-chan: Confident %ds  Clear -> Apology", math.ceil(s.remaining / 30))
            elseif s.phase == "apology" then text = string.format("Doubao-chan: Apology %ds", math.ceil(s.remaining / 30)) end
            HudLayout.DrawPlayer(HudText, i, text, 1, 0.7, 0.6, 0.9)
        end)
    end)
end

return Again
