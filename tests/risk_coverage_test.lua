-- Real Risk and roster modules: only Claude/vanilla players use the proxy account.
local root = arg[1]
local callbacks, players = {}, {}
local Hud = {T=function(_,key) return key end, Draw=function() end}
function include(name)
    if name=="scripts.hud_text" then return Hud end
    return dofile(root.."/"..name:gsub("%.","/")..".lua")
end
package.preload.json=function() return {encode=function() return "" end, decode=function() return {} end} end
local names = {"GPT-chan","Gemini-chan","Grok-chan","Qwen-chan","Llama-chan","Mistral-chan","Doubao-chan","Kimi-chan","GLM-chan"}
Isaac = {GetItemIdByName=function() return -1 end, GetTrinketIdByName=function() return -1 end,
    GetPillEffectByName=function() return -1 end}
function Isaac.GetPlayerTypeByName(n, tainted)
    if n=="Claude-chan" then return tainted and 141 or 41 end
    if n=="DeepSeek-chan" then return tainted and 142 or 42 end
    for i, name in ipairs(names) do if n==name then return tainted and 150+i or 50+i end end
    return -1
end
function Isaac.GetPlayer(i) return players[i+1] end
function Isaac.GetScreenHeight() return 270 end
ModCallbacks = setmetatable({}, {__index=function(_,k) return k end})
CacheFlag = {CACHE_DAMAGE=1}
CallbackPriority = {EARLY=-100,DEFAULT=0,LATE=1000}
DamageFlag = {DAMAGE_FAKE=1 << 21,DAMAGE_NO_PENALTIES=1 << 28}
EntityType = {ENTITY_PLAYER=1}
function RNG() return {SetSeed=function() end, RandomInt=function() return 0 end, RandomFloat=function() return 1 end} end
function Game() return {
    GetNumPlayers=function() return #players end,
    GetLevel=function() return {GetStage=function() return 1 end} end,
    GetSeeds=function() return {GetStartSeed=function() return 1 end} end,
    GetHUD=function() return {ShowItemText=function() end, IsVisible=function() return false end} end,
} end
local mod = {AddCallback=function(_, id, fn)
    callbacks[id] = callbacks[id] or {}; table.insert(callbacks[id], fn) end,
    HasData=function() return false end}
function mod:AddPriorityCallback(id, _, fn) self:AddCallback(id,fn) end
local function fire(id, ...) for _, fn in ipairs(callbacks[id] or {}) do fn(mod, ...) end end
local function player(kind)
    local p = {kind=kind, Damage=10}
    function p:GetPlayerType() return self.kind end
    function p:ToPlayer() return self end
    function p:HasCollectible() return false end
    function p:HasTrinket() return false end
    function p:AddCacheFlags() end
    function p:EvaluateItems() self.Damage=10; fire('MC_EVALUATE_CACHE', self, CacheFlag.CACHE_DAMAGE) end
    return p
end

local Risk = include("scripts.risk")
Risk:Init(mod)
fire('MC_POST_GAME_STARTED', false)

-- A roster-only or DeepSeek/roster run has no proxy account.
local gpt, glm, deepseek = player(51), player(59), player(42)
players = {gpt, glm}
assert(not Risk:IsActive(), "roster-only run must not use the proxy account")
players = {deepseek, gpt}
assert(not Risk:IsActive(), "DeepSeek and roster co-op must not use the proxy account")
Risk.state.risk = 50; Risk:Add(10); assert(Risk.state.risk == 50 and Risk:Get() == 0)

-- With Claude in co-op, only Claude raises risk and only Claude is suspended.
local claude = player(41)
players = {claude, gpt, deepseek}
assert(Risk:IsActive())
Risk.state.risk = 10
fire('MC_ENTITY_TAKE_DMG', gpt); fire('MC_ENTITY_TAKE_DMG', deepseek)
assert(Risk.state.risk == 10, "roster and DeepSeek hits must not add risk")
fire('MC_PRE_SPAWN_CLEAN_AWARD'); assert(Risk.state.risk == 9, "their hits must not spoil a clean room")
fire('MC_ENTITY_TAKE_DMG', claude); assert(Risk.state.risk == 10)
fire('MC_PRE_SPAWN_CLEAN_AWARD'); assert(Risk.state.risk == 10)
Risk.state.risk = 95
for _, p in ipairs(players) do p:EvaluateItems() end
assert(math.abs(claude.Damage - 7.5) < 1e-9, "Claude is suspended")
assert(gpt.Damage == 10 and deepseek.Damage == 10, "suspension must not touch roster or DeepSeek players")

-- Registered tainted roster forms are outside the proxy account too.
for _, id in ipairs(include("scripts.characters.model_roster").tainted) do
    players = {player(id)}
    assert(not Risk:IsActive(), "registered tainted roster forms must not use the proxy account")
end
players = {player(141)}
assert(Risk:IsActive(), "tainted Claude keeps the proxy account")

-- Vanilla characters play vanilla (README: "Risk score, Claude forms only").
local isaac = player(0)
players = {isaac}
assert(not Risk:IsActive() and Risk:Get() == 0, "a vanilla run must not use the proxy account")
Risk.state.risk = 10; fire('MC_ENTITY_TAKE_DMG', isaac); assert(Risk.state.risk == 10)
-- With Claude in co-op, a vanilla partner is never billed or suspended.
players = {claude, isaac}
fire('MC_ENTITY_TAKE_DMG', isaac); assert(Risk.state.risk == 10, "a vanilla partner's hit adds no risk")
Risk.state.risk = 95; isaac:EvaluateItems(); assert(isaac.Damage == 10, "a vanilla partner is never suspended")
print("OK: proxy risk covers the Claude forms only")
