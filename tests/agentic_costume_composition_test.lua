-- Real backlog, Agentic and fixed-look callbacks under supplied cache/input
-- states. Family-specific abilities and native physics/rendering are not loaded.
local root = arg[1]
local Env = dofile(root .. "/tests/lib/backlog_env.lua")
local families = { "Claude-chan", "DeepSeek-chan", "GPT-chan", "Gemini-chan", "Grok-chan",
    "Qwen-chan", "Llama-chan", "Mistral-chan", "Doubao-chan", "Kimi-chan", "GLM-chan" }
local forms = {}
for _, name in ipairs(families) do
    for _, tainted in ipairs({ false, true }) do
        forms[#forms + 1] = { name = name, tainted = tainted, id = 100 + #forms }
    end
end

local function near(a, b, label)
    assert(math.abs(a - b) < 1e-8, label .. ": " .. tostring(a) .. " ~= " .. tostring(b))
end
local function snapshot(p)
    local out = {}
    for _, key in ipairs({ "Damage", "MoveSpeed", "TearRange", "ShotSpeed", "MaxFireDelay" }) do
        local n = p[key]
        assert(type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge,
            "non-finite " .. key)
        out[key] = n
    end
    out.CanFly = p.CanFly
    return out
end
local function same(expected, p, label)
    for key, value in pairs(expected) do
        if type(value) == "number" then near(p[key], value, label .. " " .. key)
        else assert(p[key] == value, label .. " " .. key) end
    end
end

local cases = 0
for formIndex, form in ipairs(forms) do
    for seed = 1, 12 do
        local env = Env.New(root)
        local originalInclude = include
        function include(name)
            if name == "scripts.transformation" and arg[2] then return dofile(arg[2]) end
            if name == "scripts.characters.costume_lock" and arg[3] then return dofile(arg[3]) end
            return originalInclude(name)
        end
        function Isaac.GetPlayerTypeByName(name, tainted)
            for _, entry in ipairs(forms) do
                if entry.name == name and entry.tainted == (tainted == true) then return entry.id end
            end
            return -1
        end
        CacheFlag.CACHE_FLYING = 32
        PlayerForm = { NUM_PLAYER_FORMS = 15 }
        SoundEffect = { SOUND_POWERUP_SPEWER = 132 }
        local sounds = 0
        function SFXManager() return { Play = function() sounds = sounds + 1 end } end

        local function player(kind, slot)
            local p = env.player(100 + slot * 80)
            p.kind, p.clears, p.restored, p.restoredForms = kind, 0, {}, {}
            p.nativeFlight = (seed + slot) % 2 == 0
            p.nativeDelay = seed % 2 == 0 and -0.5 or 10
            p.SpriteScale = { X = slot % 2 == 0 and 0.7 or 1.4, Y = 1.3 }
            p.scaleX, p.scaleY = p.SpriteScale.X, p.SpriteScale.Y
            function p:GetPlayerType() return self.kind end
            function p:GetCollectibleCount()
                local count = 0
                for _, n in pairs(self.items) do count = count + n end
                return count
            end
            function p:GetTrinket() return 0 end
            function p:GetEffects() return { GetEffectsList = function() return { Size = 0 } end } end
            function p:ClearCostumes() self.clears = self.clears + 1 end
            function p:AddCostume(item)
                assert(self:HasCollectible(item.id), "only held costumes may be restored")
                self.restored[#self.restored + 1] = item.id
            end
            function p:HasPlayerForm(id) return id == 3 end
            function p:AddPlayerFormCostume(id)
                assert(id == 3, "restore only the supplied acquired native form")
                self.restoredForms[#self.restoredForms + 1] = id
            end
            local evaluate = p.EvaluateItems
            function p:EvaluateItems()
                -- Supply a native cache rebuild, retaining independently
                -- supplied flight and delay before real mod callbacks run.
                self.CanFly, self.MaxFireDelay = self.nativeFlight, self.nativeDelay
                evaluate(self)
            end
            return p
        end

        local p = player(form.id, 1)
        local q = player(forms[formIndex % #forms + 1].id, 2)
        local vanilla = player(0, 3)
        local vanillaPartner = player(1, 4)
        env.load()
        include("scripts.transformation"):Init(env.mod)
        local lock = include("scripts.characters.costume_lock")
        lock:Init(env.mod)
        local maxItem = 0
        for _, id in pairs(env.Item) do
            env.config[id] = { id = id }
            maxItem = math.max(maxItem, id)
        end
        function Isaac.GetItemConfig() return {
            GetCollectibles = function() return { Size = maxItem + 1 } end,
            GetCollectible = function(_, id) return env.config[id] end,
        } end

        local function tick()
            env.update()
            for _, owner in ipairs(env.players) do
                env.fire("MC_POST_PEFFECT_UPDATE", nil, owner)
                env.fire("MC_POST_PLAYER_UPDATE", nil, owner)
                assert(owner.SpriteScale.X == owner.scaleX and owner.SpriteScale.Y == owner.scaleY,
                    "fixed-look composition must preserve supplied size")
            end
        end
        local function evaluateStable(owner)
            owner:EvaluateItems()
            local first = snapshot(owner)
            owner:EvaluateItems()
            same(first, owner, "cache rebuild must not compound")
            return first
        end

        local setKeys = { "ULTRATHINK", "COMPACT", "VIBE_CODING", "SUBAGENT_SWARM",
            "SKIP_PERMISSIONS", "TESTS_PASSING" }
        local excluded, allKeys = {}, {}
        for _, key in ipairs(setKeys) do excluded[key] = true end
        for key in pairs(env.Item) do allKeys[#allKeys + 1] = key end
        table.sort(allKeys)
        assert(#allKeys == 80, "sample the current 80-ID collectible registry")
        local random = seed * 7919 + formIndex * 104729
        local function choose(n)
            random = random * 48271 % 2147483647
            return random % n
        end
        for _, owner in ipairs(env.players) do
            for _, key in ipairs(allKeys) do
                if not excluded[key] and choose(4) == 0 then owner.items[env.Item[key]] = 1 end
            end
        end
        local first = env.Item[setKeys[seed % 6 + 1]]
        local second = env.Item[setKeys[(seed + 1) % 6 + 1]]
        local third = env.Item[setKeys[(seed + 2) % 6 + 1]]
        for _, owner in ipairs(env.players) do
            owner.items[first], owner.items[second] = 3, 1
        end
        env.newRoom()
        -- Let Edge Compass's five-frame position observer settle before
        -- comparing inventories; its delayed grant is independent of Agentic.
        for _ = 1, 5 do tick() end
        local baseline = {}
        for i, owner in ipairs(env.players) do
            baseline[i] = evaluateStable(owner)
            assert(not owner.data.ccAgentic, "copies of two items must not count as three distinct items")
            assert(owner.CanFly == owner.nativeFlight, "inactive Agentic preserves native flight")
        end
        assert(p.clears > 0 and q.clears > 0, "both registered forms use the fixed look")
        assert(vanilla.clears == 0 and vanillaPartner.clears == 0, "vanilla partners retain costumes")

        p.items[third], vanilla.items[third] = 1, 1
        tick()
        for _, entry in ipairs({ { p, 1 }, { vanilla, 3 } }) do
            local owner, old = entry[1], baseline[entry[2]]
            evaluateStable(owner)
            assert(owner.data.ccAgentic and owner.CanFly, "third distinct item grants Agentic flight")
            near(owner.Damage, old.Damage + 0.5, "Agentic adds damage after backlog cache modifiers")
            near(owner.MaxFireDelay, math.max(-0.75, (old.MaxFireDelay + 1) * 0.8 - 1),
                "Agentic scales the firing interval")
        end
        same(baseline[2], q, "partner remains below the threshold")
        same(baseline[4], vanillaPartner, "vanilla partner remains below the threshold")
        assert(sounds == 2, "only the two newly transformed players receive the cue")

        local transformed = evaluateStable(p)
        local beforeDeparture = p.clears
        p.kind = 0
        tick()
        same(transformed, p, "costume restoration must not replay mechanical bonuses")
        assert(p.clears == beforeDeparture and #p.restored > 0 and #p.restoredForms == 1,
            "leaving a mod form restores acquired layers without clearing the vanilla form")
        local restored = #p.restored
        tick()
        assert(#p.restored == restored and #p.restoredForms == 1, "departure restoration occurs once")
        p.kind = form.id
        tick()
        assert(p.clears > beforeDeparture, "returning to the mod form resumes the fixed look")
        same(transformed, p, "return to mod form preserves transformed stats")

        p.items[third], vanilla.items[third] = nil, nil
        tick()
        for i, owner in ipairs(env.players) do
            evaluateStable(owner)
            same(baseline[i], owner, "removing the third distinct item restores the previous cache")
        end
        assert(sounds == 2, "removing a transformation does not replay its gain cue")

        for _, owner in ipairs(env.players) do owner.items = {} end
        env.newRoom()
        tick()
        for _, owner in ipairs(env.players) do
            evaluateStable(owner)
            near(owner.Damage, 3.5, "inventory removal restores damage")
            near(owner.MoveSpeed, 1, "inventory removal restores speed")
            near(owner.TearRange, 260, "inventory removal restores range")
            near(owner.ShotSpeed, 1, "inventory removal restores shot speed")
            near(owner.MaxFireDelay, owner.nativeDelay, "inventory removal restores native delay")
            assert(owner.CanFly == owner.nativeFlight and not owner.data.ccAgentic,
                "inventory removal retains only native flight")
            assert(next(owner.data.ccBacklog.room) == nil, "room effects end at the room boundary")
        end
        assert(vanilla.clears == 0 and vanillaPartner.clears == 0, "native costume controls remain untouched")
        cases = cases + 1
    end
end
assert(cases == 264, "retain all 22 forms across 12 fixed seeds")
print("Agentic/fixed-look composition: 264 seeded four-player cases passed (offline callbacks only)")
