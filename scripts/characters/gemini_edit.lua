-- Tainted Gemini: One More Edit. A timed Crop / Recolor / Export chain on one target.
-- The endless-edit exaggeration is original parody. Saved per player: the room
-- whose chain is already exported. The live chain is transient.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Tools = include("scripts.characters.target_tools")
local Edit = {}

local BASE_DAMAGE = 0.9
local RADIUS = 180
local CHAIN_FRAMES, BIRTHRIGHT_FRAMES = 180, 300 -- Six seconds; ten with Birthright.
local STEPS = {"Crop", "Recolor", "Export"}
local PULSE = 2
local ANGLE_COS = math.cos(math.rad(30))

local function fresh()
    return {version=1}
end
local function valid(s)
    return type(s) == "table" and s.version == 1 and (s.doneRoom == nil or type(s.doneRoom) == "string")
end
local function alive(ref)
    local e = ref and ref.Ref
    return e and e:Exists() and not e:IsDead() and e:IsVulnerableEnemy()
        and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
end

function Edit:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Gemini-chan", true)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isTainted(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.geminiEdit) ~= "table" then Risk.state.geminiEdit = {} end
        return Risk.state.geminiEdit
    end
    local function roomKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..tostring(level:GetCurrentRoomDesc().SpawnSeed)
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
    local function export(p, b, target)
        b.chain = nil
        b.state.doneRoom = roomKey()
        target:TakeDamage(p.Damage * PULSE, 0, EntityRef(p), 0)
        Game():GetHUD():ShowItemText("Gemini-chan", "Exported")
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.geminiEdit = {} end
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
        each(function(_, b) b.chain = nil end)
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
        local room = roomKey()
        each(function(p, b)
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            local advanced = now > b.frame
            b.frame = now
            local chain = b.chain
            if chain then
                -- An early defeat never completes a partial chain.
                if not alive(chain.ref) then b.chain = nil
                elseif advanced then
                    chain.remaining = chain.remaining - 1
                    if chain.remaining <= 0 then b.chain = nil end
                end
            end
            if drop:Poll(p, b.state.doneRoom ~= room,
                "Already exported this room") then
                -- Starting again erases progress, even on the same target.
                local target = Tools.Nearest(p.Position, RADIUS)
                if target then
                    local frames = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_FRAMES or CHAIN_FRAMES
                    b.chain = {ref=EntityPtr(target), hash=GetPtrHash(target), remaining=frames, hits={}, step=0}
                    Game():GetHUD():ShowItemText("Gemini-chan", "One more edit")
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
    -- Each distinct paid attack on the target advances one step; damage is unchanged.
    -- The export pulse clears the chain first, so it cannot count as a step.
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, _, _, source)
        if not ready or not next(bindings) then return end
        local src = source and source.Entity
        local p = Tools.Owner(src)
        local b = binding(p)
        local chain = b and b.chain
        if not chain or not alive(chain.ref) or GetPtrHash(entity) ~= chain.hash then return end
        local key = Tools.AttackKey(src, Game():GetFrameCount())
        if not key or chain.hits[key] then return end
        chain.hits[key] = true
        local dx, dy = p.Position.X - entity.Position.X, p.Position.Y - entity.Position.Y
        local length = math.sqrt(dx * dx + dy * dy)
        if length < 0.001 then return end
        dx, dy = dx / length, dy / length
        if chain.angleX and dx * chain.angleX + dy * chain.angleY > ANGLE_COS + 1e-9 then return end
        chain.angleX, chain.angleY = dx, dy
        chain.step = chain.step + 1
        if chain.step >= #STEPS then export(p, b, entity) end
    end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, p, flag)
        if flag == CacheFlag.CACHE_DAMAGE and binding(p) then p.Damage = p.Damage * BASE_DAMAGE end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() or not next(bindings) then return end
        local room = roomKey()
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local text
            if b.chain then
                text = string.format("Gemini-chan: %s %d/%d  %ds", STEPS[b.chain.step + 1], b.chain.step, #STEPS,
                    math.ceil(b.chain.remaining / 30))
                if b.chain.step > 0 then text = text.."  Move 30deg" end
            elseif b.state.doneRoom == room then text = "Gemini-chan: Exported"
            else text = "Gemini-chan: DROP: start an edit" end
            HudLayout.DrawPlayer(HudText, i, text, 0.55, 0.45, 0.9, 0.9)
        end)
    end)
end

return Edit
