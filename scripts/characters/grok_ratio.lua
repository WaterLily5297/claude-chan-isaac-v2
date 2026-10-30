-- Tainted Grok: Quote Without Reading. Hits on everyone else build Ratio that
-- lands on the quoted target when the timer runs out. Original parody; Grok and
-- the parody account Gork stay distinct. Saved per player: the selection cooldown.
-- The live selection and Ratio are transient.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Tools = include("scripts.characters.target_tools")
local Choices = include("scripts.characters.attack_choices")
local Ratio = {}

local BASE_DAMAGE = 0.9
local RADIUS = 220
local QUOTE_FRAMES = 180 -- Six seconds.
local COOLDOWN_FRAMES = 300 -- Ten seconds from selection.
local RATIO_CAP = 3

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, cooldown=0}
end
local function valid(s)
    return type(s) == "table" and s.version == 1 and integer(s.cooldown, 0, COOLDOWN_FRAMES)
end
local function alive(ref)
    local e = ref and ref.Ref
    return e and e:Exists() and not e:IsDead()
end

function Ratio:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Grok-chan", true)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isTainted(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.grokRatio) ~= "table" then Risk.state.grokRatio = {} end
        return Risk.state.grokRatio
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous, kind = GetPtrHash(p), slots[key], p:GetPlayerType()
            local changed = not previous or previous.pointer ~= pointer
                or previous.seed ~= p.InitSeed or previous.kind ~= kind
            if id >= 0 and kind == id then
                local b = bindings[pointer]
                local sameOwner = b and b.seed == p.InitSeed
                -- Read the old slot before rebuilding the map: cyclic moves
                -- retain this owner's saved progress and transient ability.
                local s = all[sameOwner and b.slot or key]
                if not sameOwner and previous and changed then s = nil end
                if not valid(s) then s = fresh() end
                if not sameOwner then
                    b = {seed=p.InitSeed, slot=key, frame=Game():GetFrameCount()}
                end
                b.slot = key; b.state = s; nextBindings[pointer] = b
            end
            -- Keep the immutable identity snapshot while this slot is unchanged.
            nextSlots[key] = changed and {pointer=pointer, seed=p.InitSeed, kind=kind} or previous
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
    -- One pulse of 1x player damage per Ratio stack, credited to the player.
    local function land(p, b)
        local quote = b.quote
        b.quote = nil
        local target = quote.ref.Ref
        for _ = 1, quote.ratio do target:TakeDamage(p.Damage, 0, EntityRef(p), 0) end
        if quote.ratio > 0 then Game():GetHUD():ShowItemText("Grok-chan", "Ratio'd") end
    end
    -- Birthright: if the quoted target died first, half the Ratio moves once to
    -- the nearest surviving hostile.
    local function transfer(p, b)
        local quote = b.quote
        local from = quote.position
        if quote.moved or not p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then return false end
        local target = from and Tools.Nearest(from, RADIUS)
        if not target then return false end
        quote.ref = EntityPtr(target); quote.hash = GetPtrHash(target)
        Choices.Half(quote.choices)
        quote.ratio = Choices.Resolve(quote.choices, RATIO_CAP); quote.moved = true
        return true
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.grokRatio = {} end
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
        each(function(_, b) b.quote = nil end)
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
            local advanced = now > b.frame
            b.frame = now
            if advanced then s.cooldown = math.max(0, s.cooldown - 1) end
            local quote = b.quote
            if quote then
                local previous = quote.ratio
                quote.ratio = Choices.Resolve(quote.choices, RATIO_CAP)
                if quote.ratio < previous then Game():GetHUD():ShowItemText("Grok-chan", "Own reply: Ratio lost") end
                local target = quote.ref.Ref
                if target and target:Exists() then quote.position = target.Position end
                -- An early defeat wastes the pulse unless Birthright moves it.
                if not alive(quote.ref) and not transfer(p, b) then b.quote = nil
                elseif alive(quote.ref) and (not quote.ref.Ref:IsVulnerableEnemy()
                    or quote.ref.Ref:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)) then b.quote = nil
                elseif advanced then
                    quote.remaining = quote.remaining - 1
                    if quote.remaining <= 0 then land(p, b) end
                end
            end
            -- The cooldown outlasts the quote, so it also blocks retargeting.
            if drop:Poll(p, s.cooldown == 0,
                "Quote cooling down") then
                local target = Tools.Nearest(p.Position, RADIUS)
                if target then
                    s.cooldown = COOLDOWN_FRAMES
                    b.quote = {ref=EntityPtr(target), hash=GetPtrHash(target), position=target.Position,
                        remaining=QUOTE_FRAMES, ratio=0, choices=Choices.New()}
                    Game():GetHUD():ShowItemText("Grok-chan", "Quoted")
                else
                    drop:Refuse(p, "No target in range")
                end
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        if not ready or not next(bindings) or not tear:Exists() then return end
        if binding(Tools.Owner(tear)) then Tools.MarkVolley(tear, Game():GetFrameCount()) end
    end)
    -- Paid hits on anyone but the quoted target build Ratio, once per attack.
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, _, _, source)
        if not ready or not next(bindings) or Game():IsPaused() or not entity:IsEnemy()
            or not entity:IsVulnerableEnemy() or entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then return end
        local src = source and source.Entity
        local data = src and src.GetData and src:GetData()
        if data and (data.ccLlamaHelper or data.ccThoughtDerived) then return end
        local b = binding(Tools.Owner(src))
        local quote = b and b.quote
        if not quote then return end
        local key = Tools.AttackKey(src, Game():GetFrameCount())
        if not key then return end
        Choices.Record(quote.choices, key, GetPtrHash(entity) ~= quote.hash)
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
            local text
            if b.quote then
                text = string.format("Grok-chan: Ratio %d/%d  %ds", b.quote.ratio, RATIO_CAP, math.ceil(b.quote.remaining / 30))
            elseif b.state.cooldown > 0 then
                text = string.format("Grok-chan: Cooldown %ds", math.ceil(b.state.cooldown / 30))
            else text = "Grok-chan: DROP: quote someone" end
            HudLayout.DrawPlayer(HudText, i, text, 1, 0.35, 0.3, 0.9)
        end)
    end)
end

return Ratio
