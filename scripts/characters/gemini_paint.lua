-- Normal Gemini: Nano Banana / One More Edit. Paint marks and banana peels.
-- Saved per-player Paint and unique clears. The live mark and peel are transient.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Tools = include("scripts.characters.target_tools")
local Gemini = {}

local PAINT_START, PAINT_CAP = 2, 3
local MARK_RADIUS = 180
local MARK_FRAMES = 240 -- Eight seconds.
local DRY_FRAMES = 30 -- Included in the mark's original lifetime.
local MARK_BONUS, BIRTHRIGHT_BONUS = 1.2, 1.3
local PEEL_FRAMES = 120 -- Four seconds of slowing creep.

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, paint=PAINT_START, awards={}}
end
local function valid(s)
    if type(s) ~= "table" or s.version ~= 1 or not integer(s.paint, 0, PAINT_CAP)
        or type(s.awards) ~= "table" then return false end
    for k, v in pairs(s.awards) do
        if type(k) ~= "string" or v ~= true then return false end
    end
    return true
end
local function alive(ref)
    local e = ref and ref.Ref
    return e and e:Exists() and not e:IsDead()
end

function Gemini:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Gemini-chan", false)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local redealing = false
    local function isGemini(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.geminiPaint) ~= "table" then Risk.state.geminiPaint = {} end
        return Risk.state.geminiPaint
    end
    local function roomKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..tostring(level:GetCurrentRoomDesc().SpawnSeed)
    end
    local function floorKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..level:GetStage()..":"..level:GetStageType()
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if isGemini(p) then
                local b = bindings[pointer]
                local sameOwner = b and b.seed == p.InitSeed
                -- Read the old slot before rebuilding the map: cyclic moves
                -- retain this owner's saved progress and transient ability.
                local s = all[sameOwner and b.slot or key]
                if not sameOwner and previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then s = nil end
                if not valid(s) then s = fresh() end
                if not sameOwner then
                    b = {seed=p.InitSeed, slot=key, armed={}, frame=Game():GetFrameCount()}
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
        if not ready or not isGemini(p) then return end
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
    local function observeFloor(b)
        local s, floor = b.state, floorKey()
        if s.floor ~= floor then
            if s.floor ~= nil then s.awards = {}; b.armed = {} end
            s.floor = floor
        end
    end
    local function clearPeel(b)
        local peel = b.peel and b.peel.Ref
        if peel and peel:Exists() then peel:Remove() end
        b.peel = nil
    end
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.geminiPaint = {} end
        bind()
        each(function(_, b) observeFloor(b) end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        -- Room effects end on exit without refund.
        each(function(_, b) b.mark = nil; b.peel = nil; observeFloor(b) end)
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
            observeFloor(b)
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            local advanced = now > b.frame
            b.frame = now
            if combat then b.armed[room] = true end
            if b.mark then
                if not alive(b.mark.ref) then b.mark = nil
                elseif advanced then
                    b.mark.remaining = b.mark.remaining - 1
                    if b.mark.remaining <= 0 then b.mark = nil end
                end
            end
            if drop:Poll(p, s.paint > 0,
                "No Paint left") then
                local target = Tools.Nearest(p.Position, MARK_RADIUS)
                -- No target means no Paint is spent. A new mark replaces the old one.
                if target then
                    s.paint = s.paint - 1
                    b.mark = {ref=EntityPtr(target), hash=GetPtrHash(target), remaining=MARK_FRAMES}
                    Game():GetHUD():ShowItemText("Gemini-chan", "Wet paint: wait one second")
                else
                    drop:Refuse(p, "No target in range")
                end
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not ready or not next(bindings) then return end
        local room = roomKey()
        each(function(p, b)
            local s = b.state
            if p:IsDead() or not b.armed[room] or s.awards[room] then return end
            s.awards[room] = true
            s.paint = math.min(PAINT_CAP, s.paint + 1)
        end)
    end)
    -- Owner damage to the painted enemy is re-dealt once with the bonus applied.
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, countdown)
        if redealing or not ready or not next(bindings) then return end
        local p = Tools.Owner(source and source.Entity)
        local b = binding(p)
        if not b or not b.mark or GetPtrHash(entity) ~= b.mark.hash then return end
        b.mark.credit = Game():GetFrameCount()
        -- Early hits still give owner kill credit, but no amplification.
        if b.mark.remaining > MARK_FRAMES - DRY_FRAMES then return end
        local bonus = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_BONUS or MARK_BONUS
        redealing = true
        entity:TakeDamage(amount * bonus, flags, source, countdown)
        redealing = false
        return false
    end)
    mod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, function(_, entity)
        if not ready or not next(bindings) then return end
        local now = Game():GetFrameCount()
        each(function(p, b)
            local mark = b.mark
            if not mark or GetPtrHash(entity) ~= mark.hash then return end
            b.mark = nil
            -- Only the owner's defeat leaves a peel; one peel per owner.
            if not mark.credit or now - mark.credit > 1 then return end
            clearPeel(b)
            local peel = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.PLAYER_CREEP_BLACK, 0,
                entity.Position, Vector(0, 0), p)
            local effect = peel and peel:ToEffect()
            if effect then
                effect:SetTimeout(PEEL_FRAMES)
                effect.Color = Color(1, 0.9, 0.2, 1, 0.4, 0.35, 0)
                b.peel = EntityPtr(effect)
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local text = string.format("Gemini-chan: Paint %d/%d", b.state.paint, PAINT_CAP)
            if b.mark then
                local drying = b.mark.remaining - (MARK_FRAMES - DRY_FRAMES)
                text = text..(drying > 0 and string.format("  Drying %ds", math.ceil(drying / 30))
                    or string.format("  Edit %ds", math.ceil(b.mark.remaining / 30)))
            end
            HudLayout.DrawPlayer(HudText, i, text, 0.7, 0.6, 1, 0.9)
        end)
    end)
end

return Gemini
