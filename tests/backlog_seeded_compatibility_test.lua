-- Deterministic two-player collectible mixtures through the real backlog
-- modules. The stub does not load character modules or emulate native Isaac.
local root = arg[1]
local Env = dofile(root .. "/tests/lib/backlog_env.lua")

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function generator(seed)
    return function(limit)
        seed = (seed * 48271) % 2147483647
        return (seed % limit) + 1
    end
end

local function checkStats(player, label)
    for _, key in ipairs({ "Damage", "MoveSpeed", "TearRange", "ShotSpeed" }) do
        assert(finite(player[key]), label .. " produced non-finite " .. key)
    end
end

local function checkBaseline(player, label)
    assert(player.Damage == 3.5, label .. " retained damage after inventory removal")
    assert(player.MoveSpeed == 1, label .. " retained speed after inventory removal")
    assert(player.TearRange == 260, label .. " retained range after inventory removal")
    assert(player.ShotSpeed == 1, label .. " retained shot speed after inventory removal")
    local backlog = player:GetData().ccBacklog
    local roomKeys = {}
    for key in pairs((backlog and backlog.room) or {}) do roomKeys[#roomKeys + 1] = tostring(key) end
    assert(#roomKeys == 0, label .. " retained room state after a room transition: " .. table.concat(roomKeys, ","))
end

for seed = 1, 32 do
    local env = Env.New(root)
    local p, q = env.player(280), env.player(320)
    env.load()
    env.newRoom()

    local itemKeys = {}
    for key in pairs(env.Item) do itemKeys[#itemKeys + 1] = key end
    table.sort(itemKeys)
    assert(#itemKeys == 80, "the seeded matrix must cover the current 80-collectible registry")

    local choose = generator(seed * 7919)
    for _, key in ipairs(itemKeys) do
        local id = env.Item[key]
        if choose(4) == 1 then p.items[id] = 1 end
        if choose(5) == 1 then q.items[id] = 1 end
    end

    for _, player in ipairs({ p, q }) do
        player:EvaluateItems()
        checkStats(player, "seed " .. seed)
    end

    env.update(3)
    for _, player in ipairs({ p, q }) do
        player:EvaluateItems()
        checkStats(player, "updated seed " .. seed)
        local target = env.npc(player == p and 400 or 500, { y = 200 })
        env.shoot(player, target)
    end

    p.items, q.items = {}, {}
    env.newRoom()
    for _, player in ipairs({ p, q }) do
        player:EvaluateItems()
        checkBaseline(player, "seed " .. seed)
    end
end

print("seeded backlog compatibility: 32 seeds, two owners per seed passed")
