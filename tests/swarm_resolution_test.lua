-- Exercise real character and Swarm callbacks in the entry point's registration order.
local root = arg[1]
function include(name) return dofile(root .. "/" .. name:gsub("%.", "/") .. ".lua") end
EffectVariant={TARGET=30,ROCKET=31}
ModCallbacks = setmetatable({}, { __index = function(_, key) return key end })
CallbackPriority = {EARLY=-100, DEFAULT = 0, LATE = 1000 }
CacheFlag = {CACHE_SPEED=1}
CollectibleType = {COLLECTIBLE_BIRTHRIGHT=619}
TearFlags={TEAR_LUDOVICO="ludo"}
ActiveSlot = { SLOT_POCKET = 2 }
EntityType = { ENTITY_TEAR = 2 }
function Color(r,g,b,a,ro,go,bo) return {R=r,G=g,B=b,A=a,RO=ro,GO=go,BO=bo} end
Input={IsActionPressed=function() return false end}
ButtonAction={ACTION_DROP=11}
function GetPtrHash(player) return player end

local callbacks = {}
local mod = {}
function mod:AddPriorityCallback(id, priority, fn, param)
    callbacks[#callbacks + 1] = {id = id, priority = priority, fn = fn, param = param, order = #callbacks + 1}
end
function mod:AddCallback(id, fn, param) self:AddPriorityCallback(id, 0, fn, param) end
local function fire(id, ...)
    local selected = {}
    for _, cb in ipairs(callbacks) do if cb.id == id then selected[#selected + 1] = cb end end
    table.sort(selected, function(a, b)
        if a.priority == b.priority then return a.order < b.order end
        return a.priority < b.priority
    end)
    for _, cb in ipairs(selected) do cb.fn(mod, ...) end
end

local frame, roll, enemies = 0, 0.99, 0
local spawned = {}
local function player(kind, swarm)
    local p = {kind = kind, swarm = swarm, data = {}}
    function p:ToPlayer() return self end
    function p:GetPlayerType() return self.kind end
    function p:GetData() return self.data end
    function p:HasCollectible(id) return id == 745 and self.swarm end
    function p:SetPocketActiveItem() end
    function p:IsDead() return false end
    function p:AreControlsEnabled() return true end
    function p:GetShootingInput() return {LengthSquared=function() return 0 end} end
    function p:AddCacheFlags() end
    function p:EvaluateItems() end
    return p
end
local deepseek, claude = player(42, true), player(41, true)
Isaac = {
    GetItemIdByName = function(name)
        return ({["Subagent Swarm"] = 745, ["Lunch Break"] = 749, ["Ban Hammer"] = 733})[name] or -1
    end,
    GetPlayerTypeByName = function(name, tainted)
        return (name == "DeepSeek-chan" and 42 or 41) + (tainted and 100 or 0)
    end,
    GetTrinketIdByName = function() return -1 end,
    GetPillEffectByName = function() return -1 end,
    GetPlayer = function(i) return i == 0 and deepseek or claude end,
    CountEnemies = function() return enemies end,
    Spawn = function(_, _, _, _, velocity, owner)
        local t = {Velocity = velocity, SpawnerEntity = owner, TearFlags=0,
            Scale=1, Height=-10, FallingSpeed=0, FallingAcceleration=0.5,
            HomingFriction=0, KnockbackMultiplier=1}
        function t:ToTear() return self end
        function t:ResetSpriteScale() self.spriteScale=self.Scale end
        local data={}; function t:GetData() return data end
        spawned[#spawned + 1] = t
        return t
    end,
}
function RNG() return {SetSeed = function() end, RandomFloat = function() return roll end} end
function Game() return {
    GetFrameCount = function() return frame end,
    GetNumPlayers = function() return 2 end,
    IsPaused=function() return false end,
    GetRoom=function() return {IsClear=function() return true end} end,
    GetLevel=function() return {GetDungeonPlacementSeed=function() return 1 end,
        GetStage=function() return 1 end,GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=1,SafeGridIndex=1} end} end,
    GetSeeds = function() return {GetStartSeed = function() return 123 end} end,
    GetHUD = function() return {ShowItemText = function() end} end,
} end
local risk = {state = {}}
function risk:IsSuspended() return false end
include("scripts.items.subagent_swarm"):Init(mod)
include("scripts.characters.claude_chan"):Init(mod, risk)
include("scripts.characters.claude_chan_b"):Init(mod, risk)
include("scripts.characters.deepseek_chan"):Init(mod, risk)
include("scripts.characters.deepseek_rice"):Init(mod,risk,{Remaining=function() return 0 end})
include("scripts.characters.deepseek_peak"):Init(mod,risk)
fire("MC_POST_GAME_STARTED", false)
local function think()
    for _=1,150 do frame=frame+1; fire("MC_POST_UPDATE") end
end
-- Character modules bind an observed form on the next update.
local function become(kind)
    deepseek.kind=kind; frame=frame+1; fire("MC_POST_UPDATE")
end

local function shot(owner)
    spawned = {}
    local t = {SpawnerEntity = owner, CollisionDamage = 4, Color = Color(1,1,1,1,0,0,0), Scale = 1,
        TearFlags=0, Height=-10, FallingSpeed=0, FallingAcceleration=0.5,
        HomingFriction=0, KnockbackMultiplier=1,
        Variant = 0, Position = {}, Velocity = {Rotated = function(_, angle) return angle end}}
    function t:Remove() self.removed = true end
    function t:Exists() return not self.removed end
    local data={}; function t:GetData() return data end
    function t:HasTearFlags() return false end
    fire("MC_POST_FIRE_TEAR", t)
    return t
end

-- Neither DeepSeek form randomly cancels shots any longer.
enemies, roll = 10, 0.1
local cancelled = shot(deepseek)
assert(not cancelled.removed, "normal shots must no longer be cancelled")
assert(#spawned == 2, "normal shots still resolve before Swarm")
become(142)
local crowded = shot(deepseek)
assert(not crowded.removed and #spawned == 4, "a crowded tainted room keeps its shot, forks and Swarm")
become(42)

enemies, roll = 0, 0.99
think()
local thought = shot(deepseek)
assert(thought.CollisionDamage == 8, "Deep Think must resolve before inspecting child damage")
assert(#spawned == 2 and spawned[1].CollisionDamage == 4 and spawned[2].CollisionDamage == 4,
    "Swarm tears must deal half the resolved Deep Think damage")
assert(spawned[1].Velocity == -15 and spawned[2].Velocity == 15, "keep the two-shot fan")
assert(spawned[1].SpawnerEntity == deepseek, "keep the owner")
become(142)
shot(deepseek)
assert(#spawned == 4, "tainted forks and Swarm add two each without recursive growth")
become(42)

frame = frame + 1
claude.data.ccUsage.value, claude.data.ccUsage.limited = 100, 90
-- Limited lives in Claude's damage stat (the stub fires at 4); the tear only
-- gets the grey tint, and Swarm children inherit the resolved parent damage.
local limited = shot(claude)
assert(limited.CollisionDamage == 4)
assert(#spawned == 2 and spawned[1].CollisionDamage == 2,
    "Swarm tears must not bypass Claude's limited damage")
assert(spawned[1].Color == limited.Color, "children use the resolved parent color")
assert(claude.data.ccUsage.limited == 90, "Swarm must not restart an active limit")
claude.kind = 141; frame = frame + 1; fire("MC_POST_UPDATE")
local appeal = risk.state.claudeAppeal["1"]
appeal.quota = 0
local suspended = shot(claude)
assert(#spawned == 2 and spawned[1].CollisionDamage == suspended.CollisionDamage * 0.5,
    "Swarm tears copy the suspended attack")
assert(appeal.quota == 0, "suspended attacks and generated tears are free")
appeal.quota = 10; frame = frame + 1
shot(claude); assert(appeal.quota == 8, "Swarm adds one extra quota per paid volley")
shot(claude); assert(appeal.quota == 8, "a same-frame pellet shares the payment")

claude.kind = 41
frame = frame + 1
claude.data.ccUsage.value, claude.data.ccUsage.limited = 0, 0
local ordinary = shot(claude)
assert(ordinary.CollisionDamage == 4 and spawned[1].CollisionDamage == 2)
assert(claude.data.ccUsage.value == 8, "Swarm doubles the volley payment")
shot(claude); assert(claude.data.ccUsage.value == 8, "a same-frame pellet shares the payment")
deepseek.swarm = false
shot(deepseek)
assert(#spawned == 0, "another player's Swarm must not leak to a non-holder")
shot({ToPlayer = function() return nil end})
assert(#spawned == 0, "ignore a non-player spawner")

-- Engine item effects are already present on the natural tear. Use unusual
-- flight values and a high-bit flag so defaults or a truncated mask cannot pass.
local function effectShot(owner, multiplier)
    spawned={}
    local original={SpawnerEntity=owner, Variant=7, Position={},
        Velocity={Rotated=function(_,a) return a end}, CollisionDamage=10*(multiplier or 1), Color=Color(0.3,0.8,0.5,0.6,0.1,0.2,0.3),
        TearFlags=(1 << 1) | (1 << 3) | (1 << 4) | (1 << 52),
        Scale=1.7, Height=-27, FallingSpeed=-4.5, FallingAcceleration=0.17,
        HomingFriction=0.08, KnockbackMultiplier=1.4}
    function original:Exists() return not self.removed end
    function original:Remove() self.removed=true end
    local data={}; function original:GetData() return data end
    function original:HasTearFlags() return false end
    fire('MC_POST_FIRE_TEAR',original)
    return original
end
local function inherited(original, count)
    assert(#spawned==count, 'inheritance must not change the fan size')
    for _,child in ipairs(spawned) do
        assert(child.TearFlags==original.TearFlags, 'fork loses native tear effects')
        assert(child.Scale==original.Scale and child.spriteScale==original.Scale,
            'fork must display the resolved parent size')
        assert(child.Height==original.Height and child.FallingSpeed==original.FallingSpeed
            and child.FallingAcceleration==original.FallingAcceleration, 'fork loses the flight arc')
        assert(child.HomingFriction==original.HomingFriction
            and child.KnockbackMultiplier==original.KnockbackMultiplier, 'fork loses effect parameters')
        assert(child.CollisionDamage==original.CollisionDamage*0.5 and child.Color==original.Color)
        assert(child.SpawnerEntity==original.SpawnerEntity, 'fork owner must remain unchanged')
    end
end
claude.kind=0; claude.swarm=true
local vanilla=effectShot(claude); inherited(vanilla,2)
assert(vanilla.Scale==1.7 and vanilla.CollisionDamage==10, 'fork must not mutate its parent')
deepseek.swarm=false; become(142)
inherited(effectShot(deepseek),2)
deepseek.swarm=true; inherited(effectShot(deepseek),4)
become(42); think()
local boosted=effectShot(deepseek); assert(boosted.Scale==1.7 and boosted.CollisionDamage==20); inherited(boosted,2)
enemies,roll=10,0.1
local blocked=effectShot(deepseek); assert(not blocked.removed and #spawned==2)
print("OK: Swarm shot resolution, player isolation and resolved fork effects/flight")

-- Summary Stapler supplies its multiplier before the real character callbacks.
-- This models the native FireTear handoff; engine timing still needs acceptance.
UseFlag = { USE_CARBATTERY = 32 }
EntityFlag = { FLAG_FRIENDLY = 1 }
local summaryShot, absorbed
local delta = { LengthSquared = function() return 1 end }
local position = setmetatable({}, { __sub = function() return delta end })
local aim = { LengthSquared = function() return 1 end, Resized = function() return {} end }
local function prepare(owner)
    owner.Position = position
    owner.GetShootingInput = function() return aim end
    owner.FireTear = function(p, pos, velocity, eye, tractor, streak, source, multiplier)
        assert(p == owner and source == owner and multiplier == 2)
        summaryShot = effectShot(owner, multiplier)
        return summaryShot
    end
    absorbed = 0
    Isaac.GetRoomEntities = function()
        local result = {}
        for i = 1, 4 do
            local bullet = { Position = position, InitSeed = i, Index = i,
                Variant = 0, SubType = 0, ProjectileFlags = 0, ChangeFlags = 0,
                SpawnerEntity = { ToNPC = function() return { HasEntityFlags = function() return false end } end } }
            function bullet:ToProjectile() return self end
            function bullet:Exists() return true end
            function bullet:IsDead() return false end
            function bullet:HasEntityFlags() return false end
            function bullet:Remove() absorbed = absorbed + 1 end
            result[#result + 1] = bullet
        end
        return result
    end
end
include("scripts.items.summary_stapler"):Init(mod)
local stapler = callbacks[#callbacks].fn
claude.kind, claude.swarm = 41, true
claude.data.ccUsage.value, claude.data.ccUsage.limited = 100, 90
prepare(claude)
assert(stapler(mod, -1, nil, claude, 0).Discharge and absorbed == 4)
-- Limited is in the damage stat FireTear reads; the shot is not cut again.
assert(summaryShot.CollisionDamage == 20, 'summary must not double-apply Claude limited damage')
inherited(summaryShot, 2)
claude.data.ccUsage.value, claude.data.ccUsage.limited = 0, 0
frame = frame + 1
stapler(mod, -1, nil, claude, 0)
assert(claude.data.ccUsage.value == 8, 'summary and Swarm keep ordinary usage accounting')
deepseek.swarm, enemies, roll = true, 0, 0.99
become(142)
prepare(deepseek)
stapler(mod, -1, nil, deepseek, 0)
inherited(summaryShot, 4)
enemies, roll = 10, 0.1
frame = frame + 1
stapler(mod, -1, nil, deepseek, 0)
assert(not summaryShot.removed and #spawned == 4, 'a crowded room must not cancel the summary shot')
assert(absorbed == 8, 'each summary absorbs its own bounded projectile set')
print('OK: Summary Stapler with real Claude limits, Swarm inheritance and Peak / Valley forks')
