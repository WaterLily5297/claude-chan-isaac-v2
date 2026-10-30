-- Tainted Kimi: You Are the Manager. Delegate tasks to nearby enemies; each task
-- delivers three small damage pulses. A per-room pulse budget bounds the output.
-- Saved per player: spent room budgets. Live tasks are transient.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Feedback = include("scripts.characters.feedback")
local Tools = include("scripts.characters.target_tools")
local Manager = {}

local BASE_DAMAGE = 0.85
local SLOTS = 3
local RADIUS = 220
local PULSES = 3
local PULSE_FRAMES = 60 -- Two seconds between pulses.
local INTERFERENCE_FRAMES = 30
local TASK_TINT = Color and Color(1, 1, 1, 1, 0.1, 0.25, 0.35) or nil
local ROOM_BUDGET = 9
local PULSE_DAMAGE, BIRTHRIGHT_PULSE = 0.6, 0.7

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=1, budget={}}
end
local function valid(s)
    if type(s) ~= "table" or s.version ~= 1 or type(s.budget) ~= "table" then return false end
    for k, v in pairs(s.budget) do
        if type(k) ~= "string" or not integer(v, PULSES, ROOM_BUDGET) then return false end
    end
    return true
end
local function alive(ref)
    local e = ref and ref.Ref
    return e and e:Exists() and not e:IsDead() and e:IsVulnerableEnemy()
        and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
end

function Manager:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Kimi-chan", true)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isTainted(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.kimiManager) ~= "table" then Risk.state.kimiManager = {} end
        return Risk.state.kimiManager
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
                    b = {seed=p.InitSeed, slot=key, tasks={}, frame=Game():GetFrameCount()}
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
    local function observeFloor(s)
        local floor = floorKey()
        if s.floor ~= floor then
            if s.floor ~= nil then s.budget = {} end
            s.floor = floor
        end
    end
    -- The nearest valid enemy that none of this owner's tasks already covers.
    local function unassigned(p, b)
        local taken, best, distance = {}, nil, nil
        for _, task in ipairs(b.tasks) do taken[task.hash] = true end
        for _, e in ipairs(Isaac.FindInRadius(p.Position, RADIUS, EntityPartition.ENEMY)) do
            if e:IsVulnerableEnemy() and not e:IsDead() and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
                and not taken[GetPtrHash(e)] then
                local d = p.Position:Distance(e.Position)
                if d <= RADIUS and (not distance or d < distance) then best, distance = e, d end
            end
        end
        return best
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.kimiManager = {} end
        bind()
        each(function(p, b) observeFloor(b.state); p:AddCacheFlags(CacheFlag.CACHE_DAMAGE); p:EvaluateItems() end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        -- Leaving cancels tasks; the room's spent budget stays spent.
        each(function(_, b) b.tasks = {}; observeFloor(b.state) end)
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
            observeFloor(s)
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            local advanced = now > b.frame
            b.frame = now
            -- Early death frees the slot; the scheduled pulses stay spent.
            local kept = {}
            for _, task in ipairs(b.tasks) do
                if alive(task.ref) then
                    if advanced and (task.pause or 0) > 0 then
                        task.pause = task.pause - 1
                    elseif advanced then
                        task.wait = task.wait - 1
                        if task.wait <= 0 then
                            local mult = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and BIRTHRIGHT_PULSE or PULSE_DAMAGE
                            task.ref.Ref:TakeDamage(p.Damage * mult, 0, EntityRef(p), 0)
                            Feedback.Mark(task.ref.Ref, TASK_TINT, PULSE_FRAMES)
                            task.left = task.left - 1
                            task.wait = PULSE_FRAMES
                        end
                    end
                    if task.left > 0 and alive(task.ref) then kept[#kept + 1] = task end
                end
            end
            b.tasks = kept
            local spent = s.budget[room] or 0
            if drop:Poll(p, combat and #b.tasks < SLOTS and spent + PULSES <= ROOM_BUDGET,
                not combat and "Needs combat" or #b.tasks >= SLOTS and "All task slots busy" or "Room pulse budget spent") then
                local target = unassigned(p, b)
                -- No target means nothing is scheduled or spent.
                if target then
                    s.budget[room] = spent + PULSES
                    b.tasks[#b.tasks + 1] = {ref=EntityPtr(target), hash=GetPtrHash(target), left=PULSES, wait=PULSE_FRAMES}
                    -- A light outline marks the assignee; it never hides the enemy.
                    Feedback.Mark(target, TASK_TINT, PULSE_FRAMES)
                    Game():GetHUD():ShowItemText("Kimi-chan", "You are the manager")
                else
                    drop:Refuse(p, "No unassigned target nearby")
                end
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        if ready and next(bindings) and tear:Exists() and binding(Tools.Owner(tear)) then
            Tools.MarkVolley(tear, Game():GetFrameCount())
        end
    end)
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, _, _, source)
        if not ready or not next(bindings) or Game():IsPaused() then return end
        local src = source and source.Entity
        local data = src and src.GetData and src:GetData()
        if data and (data.ccLlamaHelper or data.ccThoughtDerived) then return end
        local b = binding(Tools.Owner(src))
        if not b or not Tools.AttackKey(src, Game():GetFrameCount()) then return end
        for _, task in ipairs(b.tasks) do
            if task.hash == GetPtrHash(entity) and alive(task.ref) then task.pause = INTERFERENCE_FRAMES end
        end
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
            local text = string.format("Kimi-chan: Tasks %d/%d  Budget %d/%d", #b.tasks, SLOTS,
                ROOM_BUDGET - (b.state.budget[room] or 0), ROOM_BUDGET)
            local paused = 0
            for _, task in ipairs(b.tasks) do if (task.pause or 0) > 0 then paused = paused + 1 end end
            if paused > 0 then text = text..string.format("  Micromanaged %d", paused) end
            HudLayout.DrawPlayer(HudText, i, text, 0.45, 0.6, 1, 0.9)
        end)
    end)
end

return Manager
