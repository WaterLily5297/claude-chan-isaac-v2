-- Shared food lockout. Save scalar countdowns; never change type or costume.
local SaveSync = include("scripts.save_sync")
local MealBreak = {}
local MAX_FRAMES = 90

function MealBreak:Init(mod, Risk)
    local ready = false
    local bindings, slots = {}, {}
    local shooting = {
        [ButtonAction.ACTION_SHOOTLEFT] = true,
        [ButtonAction.ACTION_SHOOTRIGHT] = true,
        [ButtonAction.ACTION_SHOOTUP] = true,
        [ButtonAction.ACTION_SHOOTDOWN] = true,
    }
    local function allStates()
        if type(Risk.state.mealBreaks) ~= "table" then Risk.state.mealBreaks = {} end
        return Risk.state.mealBreaks
    end
    local function valid(s)
        return type(s) == "table" and (s.version == 1 or s.version == 2)
            and type(s.remaining) == "number" and s.remaining >= 0
            and s.remaining <= MAX_FRAMES and s.remaining == math.floor(s.remaining)
            and (s.version == 1 or (type(s.serial) == "number" and s.serial >= 0 and s.serial <= 2147483647
                and s.serial == math.floor(s.serial)
                and (s.owner == nil or s.owner == "rice")
                and (s.owner == nil or (type(s.priorDelay) == "number" and s.priorDelay >= 0 and s.priorDelay < math.huge))))
    end
    local function bindPlayers()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer = GetPtrHash(p)
            local old = slots[key]
            local b = bindings[pointer]
            local sameOwner = b and b.seed == p.InitSeed
            -- Read every old slot before rewriting the map: a cyclic move must
            -- retain each live owner's debt, frame guard and delay lease.
            local s = all[sameOwner and b.slot or key]
            if not sameOwner and old and (old.pointer ~= pointer or old.seed ~= p.InitSeed) then
                s = nil -- A replacement entity cannot inherit a departed player's meal.
            end
            if not valid(s) then s = {version = 2, remaining = 0, serial = 0} end
            if s.version == 1 then
                -- Legacy timers have no reliable source identity; never cancel them as Rice.
                s.version = 2; s.serial = 0; s.owner = nil
            end
            if not sameOwner then
                b = {seed = p.InitSeed, slot = key, frame = Game():GetFrameCount()}
            end
            b.slot, b.state = key, s
            nextBindings[pointer] = b
            nextSlots[key] = {pointer = pointer, seed = p.InitSeed}
        end
        for key in pairs(all) do all[key] = nil end
        for _, b in pairs(nextBindings) do all[b.slot] = b.state end
        bindings, slots = nextBindings, nextSlots
    end
    SaveSync.Register(Risk, "mealBreaks", function()
        if ready then bindPlayers() end
    end)
    local function binding(player)
        local b = bindings[GetPtrHash(player)]
        if b and b.seed == player.InitSeed then return b end
    end
    local function keepDelay(player, remaining)
        if remaining > 0 then player.FireDelay = math.max(player.FireDelay, remaining) end
    end

    function self:Remaining(player)
        if not ready then return 0 end
        local b = binding(player)
        return b and b.state.remaining or 0
    end
    function self:Start(player, frames, owner)
        if not ready or player:IsDead() then return false end
        bindPlayers()
        local b = binding(player)
        if not b then return false end
        if owner and (owner ~= "rice" or b.state.remaining > 0) then return false end
        b.state.serial = b.state.serial % 2147483647 + 1
        b.state.owner = owner
        b.state.priorDelay = owner and math.max(0, player.FireDelay) or nil
        b.state.remaining = math.max(b.state.remaining, math.min(MAX_FRAMES, frames))
        b.frame = Game():GetFrameCount()
        b.foreignDelay = false
        local imposed = owner and player.FireDelay < b.state.remaining
        keepDelay(player, b.state.remaining)
        b.delay = imposed and player.FireDelay or nil
        return true, b.state.serial
    end
    function self:CancelOwned(player, owner, serial)
        if not ready then return false end
        local b = binding(player)
        if not b or b.state.owner ~= owner or b.state.serial ~= serial then return false end
        -- Release only the delay last imposed here. A larger foreign cooldown survives.
        if b.delay and player.FireDelay <= b.delay and player.FireDelay >= b.delay - 1 then
            player.FireDelay = math.min(player.FireDelay, b.state.priorDelay or 0)
        end
        b.state.remaining = 0; b.state.owner = nil; b.state.priorDelay = nil; b.delay = nil
        return true
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        bindings, slots = {}, {}
        if not continued then Risk.state.mealBreaks = {} end
        ready = true
        bindPlayers() -- Risk loads first; restore before the first input poll.
        for i = 0, Game():GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            keepDelay(p, self:Remaining(p))
            local b = binding(p)
            b.delay = b.state.owner and p.FireDelay <= b.state.remaining and p.FireDelay or nil
        end
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false
        bindings, slots = {}, {}
    end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not ready then return end
        bindPlayers()
        local now, paused = Game():GetFrameCount(), Game():IsPaused()
        for i = 0, Game():GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            local b = binding(p)
            if p:IsDead() then
                b.state.remaining = 0; b.state.owner = nil; b.state.priorDelay = nil
            elseif not paused then
                if now > b.frame then
                    b.state.remaining = math.max(0, b.state.remaining - 1)
                    if b.state.priorDelay then b.state.priorDelay = math.max(0, b.state.priorDelay - 1) end
                end
                -- Remember whether another source replaced our imposed cooldown.
                if b.delay and (p.FireDelay > b.delay or p.FireDelay < b.delay - 1) then b.foreignDelay = true end
                keepDelay(p, b.state.remaining)
                b.delay = b.delay and not b.foreignDelay and p.FireDelay or nil
            end
            b.frame = now
        end
    end)
    mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, hook, action)
        -- This callback is polled frequently: no player/room scan or state mutation.
        if not ready or not shooting[action] or not entity then return end
        local p = entity:ToPlayer()
        if not p or p:IsDead() or self:Remaining(p) <= 0 or Game():IsPaused() then return end
        if hook == InputHook.GET_ACTION_VALUE then return 0 end
        if hook == InputHook.IS_ACTION_PRESSED or hook == InputHook.IS_ACTION_TRIGGERED then return false end
    end)
end

return MealBreak
