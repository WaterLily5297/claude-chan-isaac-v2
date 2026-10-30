-- Optional EID failures must not abort registration of other descriptions or
-- the rest of main.lua. Supplied APIs only; no external mod is executed here.
local root = arg[1]
function include(name) return dofile(root .. "/" .. name:gsub("%.", "/") .. ".lua") end
local function ids(start)
    local known, nextId = {}, start
    return function(name, tainted)
        local key = name .. tostring(tainted)
        if not known[key] then known[key], nextId = nextId, nextId + 1 end
        return known[key]
    end
end
Isaac = { GetItemIdByName = ids(800), GetTrinketIdByName = ids(190),
    GetPillEffectByName = ids(50), GetPlayerTypeByName = ids(41) }
local module = arg[2] and dofile(arg[2]) or include("scripts.eid")
local methods = { "addPill", "addCharacterInfo", "addTrinket", "addCollectible" }
local function api(failingMethod, failingId)
    local instance, records = {}, {}
    for _, method in ipairs(methods) do
        instance[method] = function(self, id, description, name, language)
            assert(self == instance, "preserve the EID method receiver")
            if method == failingMethod and (not failingId or id == failingId) then
                error("supplied external registration error")
            end
            local key = method .. ":" .. id .. ":" .. language
            assert(not records[key], "do not retry or duplicate an entry")
            records[key] = name .. "\n" .. description
        end
    end
    return instance, records
end
local function run(instance)
    EID = instance
    local originalPrint, warnings = print, {}
    print = function(message) warnings[#warnings + 1] = message end
    local ok, message = pcall(function() module:Init() end)
    print = originalPrint
    assert(ok, "optional EID error escaped Init: " .. tostring(message))
    return warnings
end
local function matches(actual, expected, omitted)
    local kept, skipped = 0, 0
    for key, value in pairs(expected) do
        if omitted and omitted(key) then
            assert(actual[key] == nil, "failed or unsupported entry was unexpectedly registered")
            skipped = skipped + 1
        else
            assert(actual[key] == value, "unaffected description lost or changed: " .. key)
            kept = kept + 1
        end
    end
    for key in pairs(actual) do assert(expected[key], "unexpected description: " .. key) end
    assert(kept > 0, "retain meaningful unaffected registration controls")
    return skipped
end

assert(#run(nil) == 0 and #run(false) == 0, "absent EID stays quiet")
for _, malformed in ipairs({ true, 42, "enabled", function() end }) do
    assert(#run(malformed) == 1, "malformed optional globals receive one diagnostic")
end
assert(#run({}) == 4, "missing methods are reported once per category, not per entry")
assert(#run(setmetatable({}, { __index = function() error("supplied API lookup failure") end })) == 4,
    "external method lookup failures must also stay inside the integration boundary")

local healthy, expected = api()
assert(#run(healthy) == 0, "healthy EID registration stays quiet")
local partial, partialRecords = api()
partial.addPill, partial.addTrinket, partial.addCharacterInfo = nil, false, "unsupported"
assert(#run(partial) == 3, "unsupported methods do not block supported collectibles")
assert(matches(partialRecords, expected, function(key)
    return key:sub(1, 15) ~= "addCollectible:"
end) > 0)

local brokenCategory, otherCategories = api("addPill")
assert(#run(brokenCategory) == 1, "repeated category errors emit only one diagnostic")
assert(matches(otherCategories, expected, function(key) return key:match("^addPill:") end) > 0)

local rejectedId = Isaac.GetItemIdByName("Ban Hammer")
local brokenEntry, otherEntries = api("addCollectible", rejectedId)
assert(#run(brokenEntry) == 1, "one failing collectible does not spam across languages")
assert(matches(otherEntries, expected, function(key)
    return key:match("^addCollectible:" .. rejectedId .. ":")
end) == 3, "only the rejected collectible's three languages are omitted")

-- Run the real entry point and existing callback smoke scenarios with an EID
-- method that always throws. main.lua must still reach its later registrations.
EID = { addPill = function() error("supplied startup integration failure") end }
dofile(root .. "/tests/smoke_test.lua")
EID = nil
print("PASS optional EID isolation: unavailable APIs, entry failures and full entry point")
