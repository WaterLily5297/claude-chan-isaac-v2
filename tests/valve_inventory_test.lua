-- Real backlog attack/prime callbacks under supplied inventory changes.
-- In-flight weapons and callback timing are stubs, not native engine evidence.
local root, selected = arg[1], arg[2] or "all"
local Env = dofile(root .. "/tests/lib/backlog_env.lua")
local function near(a, b, label)
    assert(math.abs(a - b) < 1e-8, label .. ": " .. a .. " ~= " .. b)
end
local function fresh()
    local env = Env.New(root)
    local p, q = env.player(200), env.player(300)
    env.load()
    env.give(p, "RATE_LIMIT_VALVE")
    env.give(q, "RATE_LIMIT_VALVE")
    env.update(60)
    assert(env.C.Primed(p, "valve") and env.C.Primed(q, "valve"), "both idle holders earn their own prime")
    return env, p, q
end
local function hit(env, p, tear, expected, label)
    local target = env.npc(400)
    target:TakeDamage(p.Damage, 0, EntityRef(tear))
    assert(#target.damage == 1, "one supplied final hit")
    near(target.damage[1], expected, label)
end
local function run(name, callback)
    if selected == "all" or selected == name then callback(); print("PASS Valve inventory: " .. name) end
end

run("update", function()
    local env, p, q = fresh()
    p.items[env.Item.RATE_LIMIT_VALVE] = nil
    env.update()
    assert(not env.C.Primed(p, "valve"), "losing the passive must retire its unspent prime")
    assert(env.C.Data(p).primes.valve == nil, "update removes stale passive state")
    hit(env, p, env.shoot(p), 3.5, "removed passive no longer boosts the next attack")
    hit(env, q, env.shoot(q), 4.55, "another holder keeps its reward")
end)

run("immediate", function()
    local env, p = fresh()
    p.items[env.Item.RATE_LIMIT_VALVE] = nil
    -- Do not call Primed or update before firing: the consumption boundary
    -- itself must reject a stale reward after an inventory-changing callback.
    hit(env, p, env.shoot(p), 3.5, "removal before the next update still cancels the unspent prime")
    assert(env.C.Data(p).primes.valve == nil)
end)

run("copies", function()
    local env, p = fresh()
    p.items[env.Item.RATE_LIMIT_VALVE] = 2
    env.update()
    p.items[env.Item.RATE_LIMIT_VALVE] = 1
    env.update()
    hit(env, p, env.shoot(p), 4.55, "removing one duplicate retains the single passive benefit")
    env.update(60)
    assert(env.C.Primed(p, "valve"))
    p.items[env.Item.RATE_LIMIT_VALVE] = nil
    hit(env, p, env.shoot(p), 3.5, "removing the last copy cancels a newly earned prime")
end)

run("resolved", function()
    local env, p = fresh()
    local first = env.shoot(p)
    p.items[env.Item.RATE_LIMIT_VALVE] = nil
    local sibling = env.shoot(p)
    env.update()
    -- A same-frame volley already resolved its one multiplier. Do not edit
    -- those leases when the item disappears, or cancel in-flight shot damage.
    hit(env, p, first, 4.55, "resolved attack retains its bonus after inventory loss")
    hit(env, p, sibling, 4.55, "same resolved volley keeps a consistent multiplier")
    hit(env, p, env.shoot(p), 3.5, "a later volley no longer gains the lost passive")
end)

run("active-reward", function()
    local env, p, q = fresh()
    assert(env.use(env.Item.RICE_COOKER, p).Discharge)
    env.update(90)
    assert(env.C.Primed(p, "rice"), "the real active callback earns its separate reward")
    p.items[env.Item.RATE_LIMIT_VALVE] = nil
    hit(env, p, env.shoot(p), 7, "inventory loss cancels only the passive, not the completed active reward")
    hit(env, q, env.shoot(q), 4.55, "the partner's passive remains independent")
end)

run("reacquire", function()
    local env, p = fresh()
    hit(env, p, env.shoot(p), 4.55, "consume the original benefit")
    p.items[env.Item.RATE_LIMIT_VALVE] = nil
    env.update(30)
    env.give(p, "RATE_LIMIT_VALVE")
    env.update(29)
    assert(not env.C.Primed(p, "valve"), "reacquisition does not bypass the existing attack-based idle timer")
    env.update()
    hit(env, p, env.shoot(p), 4.55, "reacquired passive works at the original idle threshold")
end)
