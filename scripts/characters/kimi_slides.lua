-- Normal Kimi: Another Slide Deck. Unique clears earn Slides; DROP presents them.
-- Saved per-player Slides and unique clears. The live presentation is transient.
local SaveSync = include("scripts.save_sync")
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Tools = include("scripts.characters.target_tools")
local Feedback = include("scripts.characters.feedback")
local Kimi = {}

local SLIDE_CAP = 6
local COST, BIRTHRIGHT_COST = 3, 2
local RADIUS = 220
local AUDIENCE = 3
local PRESENT_FRAMES = 120 -- Four seconds.
local SLOW_VALUE = 0.6
local BONUS = 1.15

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, slides=0, awards={}}
end
local function valid(s)
    if type(s) ~= "table" or s.version ~= 1 or not integer(s.slides, 0, SLIDE_CAP)
        or type(s.awards) ~= "table" then return false end
    for k, v in pairs(s.awards) do
        if type(k) ~= "string" or v ~= true then return false end
    end
    return true
end
local function cost(p)
    return p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_COST or COST
end
local function alive(ref)
    local e = ref and ref.Ref
    return e and e:Exists() and not e:IsDead() and e:IsVulnerableEnemy()
        and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
end

function Kimi:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Kimi-chan", false)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local redealing = false
    local function isKimi(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.kimiSlides) ~= "table" then Risk.state.kimiSlides = {} end
        return Risk.state.kimiSlides
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
            if isKimi(p) then
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
    SaveSync.Register(Risk, "character.kimi_slides", function()
        if ready then bind() end
    end)

    local function binding(p)
        if not ready or not isKimi(p) then return end
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
    -- Up to three nearest vulnerable enemies, closest first.
    local function audience(p)
        local found = {}
        for _, e in ipairs(Isaac.FindInRadius(p.Position, RADIUS, EntityPartition.ENEMY)) do
            if e:IsVulnerableEnemy() and not e:IsDead() and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
                and p.Position:Distance(e.Position) <= RADIUS then found[#found + 1] = e end
        end
        table.sort(found, function(a, b) return p.Position:Distance(a.Position) < p.Position:Distance(b.Position) end)
        for i = #found, AUDIENCE + 1, -1 do found[i] = nil end
        return found
    end
    local function present(p, b, targets)
        local marks, order = {}, {}
        for _, e in ipairs(targets) do
            -- A light blue tint is the outline; no screen-covering slide.
            e:AddSlowing(EntityRef(p), PRESENT_FRAMES, SLOW_VALUE, Color(0.85, 0.9, 1.2, 1, 0, 0, 0.1))
            marks[GetPtrHash(e)] = EntityPtr(e)
            order[#order + 1] = GetPtrHash(e)
        end
        b.show = {marks=marks, order=order, speaker=1, remaining=PRESENT_FRAMES}
    end
    local function speaker(show)
        while show.speaker <= #show.order do
            local hash = show.order[show.speaker]
            if alive(show.marks[hash]) then return hash end
            show.marks[hash] = nil
            show.speaker = show.speaker + 1
        end
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.kimiSlides = {} end
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
        -- A presentation ends on room exit without refund.
        each(function(_, b) b.show = nil; observeFloor(b) end)
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
            if b.show then
                for hash, ref in pairs(b.show.marks) do
                    if not alive(ref) then b.show.marks[hash] = nil end
                end
                if advanced then b.show.remaining = b.show.remaining - 1 end
                local focus = speaker(b.show)
                if b.show.remaining <= 0 or not focus then b.show = nil
                elseif advanced then
                    Feedback.Mark(b.show.marks[focus].Ref, Color(0.7, 0.85, 1, 1, 0, 0.1, 0.3), 2)
                end
            end
            if drop:Poll(p, s.slides >= cost(p),
                "Not enough Slides") then
                local targets = audience(p)
                -- No audience means no Slides are spent. A new deck replaces the old one.
                if #targets > 0 then
                    s.slides = s.slides - cost(p)
                    present(p, b, targets)
                    Game():GetHUD():ShowItemText("Kimi-chan", "Another slide deck")
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
            s.slides = math.min(SLIDE_CAP, s.slides + 1)
        end)
    end)
    -- Owner damage to a presented enemy is re-dealt once with the bonus applied.
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, amount, flags, source, countdown)
        if redealing or not ready or not next(bindings) then return end
        local p = Tools.Owner(source and source.Entity)
        local b = binding(p)
        if not b or not b.show or speaker(b.show) ~= GetPtrHash(entity) then return end
        redealing = true
        entity:TakeDamage(amount * BONUS, flags, source, countdown)
        redealing = false
        return false
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local text = string.format("Kimi-chan: Slides %d/%d  Cost %d", b.state.slides, SLIDE_CAP, cost(p))
            if b.show then text = text..string.format("  Presenting %ds", math.ceil(b.show.remaining / 30)) end
            HudLayout.DrawPlayer(HudText, i, text, 0.55, 0.65, 1, 0.9)
        end)
    end)
end

return Kimi
