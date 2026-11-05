-- Real DeepSeek forms, meal/input lock and backlog modules in main.lua order.
-- Engine timing, weapons and save reconstruction remain supplied inputs.
local root = arg[1]
local Env = dofile(root .. "/tests/lib/backlog_env.lua")
local function near(actual, expected, label)
    assert(math.abs(actual - expected) < 1e-8, label .. ": " .. actual .. " ~= " .. expected)
end
local function finite(player)
    for _, key in ipairs({ "Damage", "MoveSpeed", "TearRange", "ShotSpeed" }) do
        local value = player[key]
        assert(type(value) == "number" and value == value and math.abs(value) < math.huge,
            "non-finite " .. key)
    end
end

for seed = 1, 12 do
    local env = Env.New(root)
    local originalInclude = include
    function include(name)
        if name == "scripts.items.backlog.deepseek" and arg[2] then return dofile(arg[2]) end
        return originalInclude(name)
    end
    local formIds, nextForm = {}, 100
    function Isaac.GetPlayerTypeByName(name, tainted)
        local key = name .. tostring(tainted == true)
        if not formIds[key] then formIds[key], nextForm = nextForm, nextForm + 1 end
        return formIds[key]
    end
    EntityType.ENTITY_KNIFE, EntityType.ENTITY_LASER, EntityType.ENTITY_BOMB = 8, 7, 4
    DamageFlag.DAMAGE_EXPLOSION = 4
    ButtonAction = { ACTION_SHOOTLEFT = 4, ACTION_SHOOTRIGHT = 5,
        ACTION_SHOOTUP = 6, ACTION_SHOOTDOWN = 7, ACTION_DROP = 11, ACTION_LEFT = 0 }
    InputHook = { IS_ACTION_PRESSED = 0, IS_ACTION_TRIGGERED = 1, GET_ACTION_VALUE = 2 }
    TearFlags = { TEAR_LUDOVICO = 1 << 30 }
    ActiveSlot.SLOT_POCKET = 2
    CollectibleType.COLLECTIBLE_BIRTHRIGHT = 619
    local buttons = {}
    Input = { IsActionPressed = function(_, controller) return buttons[controller] == true end }
    local C = include("scripts.constants")
    local function player(kind, slot)
        local p = env.player(200 + slot * 30)
        p.formType, p.InitSeed, p.ControllerIndex = kind, seed * 10 + slot, slot - 1
        p.FireDelay, p.MaxFireDelay, p.aim, p.move = 0, 10, Vector.Zero, Vector.Zero
        function p:GetPlayerType() return self.formType end
        function p:AreControlsEnabled() return true end
        function p:GetMovementInput() return self.move end
        function p:GetCard() return 0 end
        function p:GetPill() return 0 end
        function p:SetPocketActiveItem(id, slotId) self.active[slotId] = id end
        return p
    end
    local normal = player(C.Player.DEEPSEEK_CHAN, 1)
    local tainted = player(C.Player.DEEPSEEK_CHAN_B, 2)
    local partner = player(C.Player.DEEPSEEK_CHAN, 3)
    local vanilla = player(0, 4)
    local meal = include("scripts.meal_break")
    meal:Init(env.mod, env.Risk)
    local backlog = include("scripts.items.backlog.common")
    backlog:Init(env.mod, env.Risk)
    for _, family in ipairs({ "claude", "deepseek", "gpt", "gemini", "grok", "qwen",
            "llama", "mistral", "doubao", "kimi", "glm", "shared" }) do
        include("scripts.items.backlog." .. family):Init(env.mod, env.Risk, backlog, meal)
    end
    env.C, env.Item = backlog, C.Item
    include("scripts.characters.deepseek_chan"):Init(env.mod)
    include("scripts.characters.deepseek_rice"):Init(env.mod, env.Risk, meal)
    include("scripts.characters.deepseek_peak"):Init(env.mod, env.Risk)
    env.fire("MC_POST_GAME_STARTED", nil, false)
    env.newRoom()
    local function tick(n)
        for _ = 1, n or 1 do
            for _, p in ipairs(env.players) do p.FireDelay = math.max(0, p.FireDelay - 1) end
            env.update()
            for _, p in ipairs(env.players) do finite(p) end
        end
    end
    local function tap(p)
        buttons[p.ControllerIndex] = false; tick()
        buttons[p.ControllerIndex] = true; tick()
        buttons[p.ControllerIndex] = false; tick()
    end
    local function input(p, hook, action)
        return env.fire("MC_INPUT_ACTION", nil, p, hook, action or ButtonAction.ACTION_SHOOTLEFT)
    end
    local function rice(slot) return env.Risk.state.deepseekRice[tostring(slot or 0)] end
    local function peak() return env.Risk.state.deepseekPeak["1"] end
    local function knife(p)
        local k = env.tear(p)
        k.kind, k.Type, k.SubType, k.flying = "knife", EntityType.ENTITY_KNIFE, 0, true
        k.CollisionDamage = p.Damage
        function k:IsFlying() return self.flying end
        return k
    end
    local function tear(p)
        local t = env.tear(p)
        t.CollisionDamage, t.TearFlags = p.Damage, 0
        function t:HasTearFlags(flag) return (self.TearFlags & flag) ~= 0 end
        return t
    end
    -- Mix registry IDs deterministically. Only backlog callbacks and the two
    -- DeepSeek form implementations are loaded; other item modules are absent.
    local keys, random = {}, seed * 7919
    for key in pairs(C.Item) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, p in ipairs(env.players) do
        for _, key in ipairs(keys) do
            random = random * 48271 % 2147483647
            if random % 5 == 0 then p.items[C.Item[key]] = 1 end
        end
        p:EvaluateItems(); finite(p)
    end
    if seed % 2 == 0 then
        tick(360)
        assert(peak().phase == "peak", "enter Peak through real schedule updates")
    end
    -- Consume any idle-earned Rate-Limit Valve prime before the meal scenario.
    -- Its unspent-prime removal policy is a separate review candidate; do not
    -- mistake that independent 1.3x multiplier for duplicate Compute billing.
    for _, p in ipairs(env.players) do
        if p == tainted then
            local warmup = knife(p)
            env.fire("MC_POST_KNIFE_UPDATE", nil, warmup)
            warmup.flying = false
            env.fire("MC_POST_KNIFE_UPDATE", nil, warmup)
            warmup:Remove()
        else
            env.fire("MC_POST_FIRE_TEAR", nil, tear(p))
        end
    end
    tick()

    -- Character lunch and the active item coexist on different owners.
    tap(normal)
    assert(rice().bowls == 0 and rice().lunch and meal:Remaining(normal) == 60)
    assert(env.use(C.Item.RICE_COOKER, tainted).Discharge)
    assert(not env.use(C.Item.RICE_COOKER, normal).Discharge, "busy character meal keeps item charge")
    assert(not env.use(C.Item.RICE_COOKER, tainted, UseFlag.USE_CARBATTERY).Discharge)
    for _, p in ipairs({ normal, tainted }) do
        assert(input(p, InputHook.IS_ACTION_PRESSED) == false)
        assert(input(p, InputHook.IS_ACTION_TRIGGERED) == false)
        assert(input(p, InputHook.GET_ACTION_VALUE) == 0)
        assert(input(p, InputHook.IS_ACTION_PRESSED, ButtonAction.ACTION_LEFT) == nil,
            "meals preserve movement")
    end
    assert(input(partner, 0) == nil and input(vanilla, 0) == nil, "other owners keep shooting")
    tick(15)
    local remaining = meal:Remaining(normal)
    env.fire("MC_POST_UPDATE")
    assert(meal:Remaining(normal) == remaining, "duplicate frame does not advance shared lunch")

    -- Move to cancel the character-owned meal. The other owner's active meal
    -- must retain its timer; the bowl is refunded exactly once.
    normal.move = Vector(1, 0)
    tick()
    assert(not rice().lunch and rice().bowls == 1 and meal:Remaining(normal) == 0)
    assert(normal.FireDelay == 0 and input(normal, 0) == nil, "cancel releases only this shooting lock")
    local itemRemaining = meal:Remaining(tainted)
    tick()
    assert(rice().bowls == 1 and meal:Remaining(tainted) == itemRemaining - 1)
    normal.move = Vector.Zero
    tap(normal)
    assert(rice().bowls == 0 and rice().lunch)

    -- Removing inventory cannot undo a previously used active, and it must
    -- not leave passive cache bonuses after a room boundary.
    for _, p in ipairs(env.players) do p.items = {}; p:EvaluateItems(); finite(p) end
    tick(meal:Remaining(normal))
    assert(not rice().lunch and rice().thought == 150 and rice().speed == 180)
    tick(meal:Remaining(tainted))
    assert(backlog.Primed(tainted, "rice"), "completed item meal retains its promised next-attack reward")
    assert(not backlog.Primed(normal, "rice"), "character meal must not manufacture an item reward")
    for _, p in ipairs(env.players) do
        assert(meal:Remaining(p) == 0 and input(p, 0) == nil, "all completed locks release")
    end

    -- A normal tear spends the stored Thought once; repeated callbacks and a
    -- second same-frame tear keep the same paid multiplier.
    local a, b = tear(normal), tear(normal)
    env.fire("MC_POST_FIRE_TEAR", nil, a)
    env.fire("MC_POST_FIRE_TEAR", nil, a)
    env.fire("MC_POST_FIRE_TEAR", nil, b)
    near(a.CollisionDamage, normal.Damage * 2, "Thought resolves once")
    near(b.CollisionDamage, a.CollisionDamage, "same-frame volley shares Thought")
    assert(rice().thought == 0 and rice(2).thought > 0, "normal partner retains its own Thought")

    -- The active's 2x lease and the real tainted 1.3x knife boost compose.
    -- Two distinct knives and repeated hit/update callbacks share one payment.
    local compute = peak().compute
    local cost = peak().phase == "peak" and 4 or 2
    local k, other = knife(tainted), knife(tainted)
    env.fire("MC_POST_KNIFE_UPDATE", nil, k)
    env.fire("MC_POST_KNIFE_UPDATE", nil, k)
    env.fire("MC_POST_KNIFE_UPDATE", nil, other)
    assert(peak().compute == compute - cost, "one phase-priced payment across same-frame weapon callbacks")
    assert(not backlog.Primed(tainted, "rice"), "one attack consumes the item prime")
    local target = env.npc(350, { hp = 10000 })
    for _, weapon in ipairs({ k, k, other }) do
        local before = #target.damage
        target:TakeDamage(tainted.Damage, 0, EntityRef(weapon))
        assert(#target.damage == before + 1, "nested damage writers resolve to one supplied health hit")
        near(target.damage[#target.damage], tainted.Damage * 2 * 1.3, "item and character damage compose")
    end
    assert(peak().compute == compute - cost, "hits do not pay again")
    tick()
    k.flying = false
    env.fire("MC_POST_KNIFE_UPDATE", nil, k)
    k.flying = true
    env.fire("MC_POST_KNIFE_UPDATE", nil, k)
    assert(peak().compute == compute - cost * 2, "a later throw pays again")
    target:TakeDamage(tainted.Damage, 0, EntityRef(k))
    near(target.damage[#target.damage], tainted.Damage * 1.3, "later throw does not retain the consumed rice lease")

    tick(200)
    env.newRoom()
    for _, p in ipairs(env.players) do p:EvaluateItems(); finite(p) end
    near(normal.MoveSpeed, 1, "expired character speed does not survive item removal and room change")
    near(normal.Damage, 3.5 * 0.9, "normal base damage survives cache rebuilding")
    near(tainted.Damage, 3.5 * 0.8, "tainted base damage survives cache rebuilding")
    near(vanilla.Damage, 3.5, "vanilla partner remains native")
    for _, p in ipairs(env.players) do
        assert(next(backlog.Data(p).room) == nil, "room-scoped backlog state clears")
        assert(input(p, 0) == nil and p.FireDelay == 0, "no leftover meal lock")
    end

    -- A cancelled shared timer is not a completed meal. Supply death during
    -- the item lockout, then revive the same wrapper; no native revival claimed.
    assert(env.use(C.Item.RICE_COOKER, vanilla).Discharge)
    tick(5)
    vanilla.alive = false
    tick()
    assert(meal:Remaining(vanilla) == 0, "death cancels the shared meal")
    assert(not backlog.Primed(vanilla, "rice"), "death must not grant the unfinished item meal reward")
    assert(backlog.Peek(vanilla).riceCooker == nil, "cancelled reward must not survive in saved state")
    vanilla.alive = true
    tick()
    assert(not backlog.Primed(vanilla, "rice") and input(vanilla, 0) == nil,
        "the supplied revival has neither an unearned reward nor an input lock")

    -- Cancelling a later meal must neither erase nor extend an already earned
    -- prime. Only that pending meal is cancelled; spent charges are not refunded.
    assert(env.use(C.Item.RICE_COOKER, vanilla).Discharge)
    tick(90)
    local earned = backlog.Data(vanilla).primes.rice
    assert(earned and backlog.Primed(vanilla, "rice"))
    assert(env.use(C.Item.RICE_COOKER, vanilla).Discharge)
    tick(5)
    vanilla.alive = false
    tick()
    assert(backlog.Data(vanilla).primes.rice == earned,
        "cancelling another meal cannot replace the earned prime or extend its expiry")
end
print("PASS DeepSeek/meal/backlog composition: 12 seeded four-player cases (offline only)")
