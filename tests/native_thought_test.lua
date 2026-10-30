-- Native weapon callbacks exercised with the real Rice economy and food service.
local root=arg[1]
local frame, paused, clear, room, floor = 0, false, true, 1, 10
local callbacks, players, saved, draws = {}, {}, nil, {}
local C={RISK_MAX=100,Player={DEEPSEEK_CHAN=42},Item={LUNCH_BREAK=749,MILLION_CONTEXT=739}}
function include(name)
    if name=="scripts.characters.deepseek_rice" and arg[2] then return dofile(arg[2]) end
    if name=="scripts.constants" then return C end
    if name=="scripts.characters.model_roster" then return {Find=function() end} end
    if name=="scripts.hud_text" then return {Draw=function(_,text) draws[#draws+1]=text end} end
    return dofile(root.."/"..name:gsub("%.","/")..".lua")
end
local function copy(v)
    if type(v)~="table" then return v end
    local result={}; for k,x in pairs(v) do result[k]=copy(x) end; return result
end
package.preload.json=function() return {
    encode=function(v) saved=copy(v); return "snapshot" end,
    decode=function() return copy(saved) end,
} end
ModCallbacks=setmetatable({}, {__index=function(_,k) return k end})
TearFlags={TEAR_LUDOVICO={highBit=127}}
EffectVariant={TARGET=30,ROCKET=31}
EntityType={ENTITY_LASER=7,ENTITY_BOMB=4}
function EntityPtr(e) return setmetatable({}, {__index=function(_,k) if k=="Ref" and e:Exists() then return e end end}) end
CacheFlag={CACHE_SPEED=1}; CollectibleType={COLLECTIBLE_BIRTHRIGHT=619}
ButtonAction={ACTION_DROP=11,ACTION_SHOOTLEFT=4,ACTION_SHOOTRIGHT=5,ACTION_SHOOTUP=6,ACTION_SHOOTDOWN=7}
InputHook={IS_ACTION_PRESSED=0,IS_ACTION_TRIGGERED=1,GET_ACTION_VALUE=2}
local down={}
Input={IsActionPressed=function(_,controller) return down[controller] or false end}
function GetPtrHash(p) return p.pointer end
function Game() return {
    GetFrameCount=function() return frame end, GetNumPlayers=function() return #players end,
    IsPaused=function() return paused end,
    GetRoom=function() return {IsClear=function() return clear end} end,
    GetLevel=function() return {
        GetDungeonPlacementSeed=function() return floor end,
        GetStage=function() return 1 end,GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=room*13,SafeGridIndex=room} end,
    } end,
    GetHUD=function() return {IsVisible=function() return true end} end,
} end
Isaac={GetPlayer=function(i) return players[i+1] end,GetScreenHeight=function() return 270 end}
local mod={AddCallback=function(_,id,fn) callbacks[#callbacks+1]={id=id,fn=fn} end}
function mod:SaveData(s) self.saved=s end
function mod:LoadData() return self.saved end
function mod:HasData() return saved~=nil end
local function fire(id,...)
    local result
    for _,cb in ipairs(callbacks) do if cb.id==id then
        local value=cb.fn(mod,...); if value~=nil then result=value end
    end end
    return result
end
local function player(pointer,seed,controller)
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=42,
        FireDelay=0,MoveSpeed=1,hearts=2,charge=2,dead=false,controls=true,shooting=false}
    function p:GetPlayerType() return self.kind end
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return self.controls end
    function p:HasCollectible(id) return (id==619 and self.birthright) or (id==739 and self.context) end
    function p:GetShootingInput() return {LengthSquared=function() return self.shooting and 1 or 0 end} end
    function p:AddCacheFlags() end
    function p:EvaluateItems() self.MoveSpeed=1; fire("MC_EVALUATE_CACHE",self,1) end
    return p
end
local Risk=include("scripts.risk")
local Meal
local function load()
    callbacks={}
    mod:AddCallback("MC_POST_GAME_STARTED",function(_,continued)
        if continued then Risk:Load(mod) else Risk.state={} end
    end)
    mod:AddCallback("MC_PRE_GAME_EXIT",function(_,save) if save then Risk:Save(mod) end end)
    Meal=include("scripts.meal_break"); Meal:Init(mod,Risk)
    include("scripts.items.million_context"):Init(mod)
    include("scripts.characters.deepseek_rice"):Init(mod,Risk,Meal)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.deepseekRice[tostring(i or 0)] end
local function tap(p)
    down[p.ControllerIndex]=false; tick()
    down[p.ControllerIndex]=true; tick()
    down[p.ControllerIndex]=false; tick()
end
local function enter(index,hostile)
    room=index; clear=not hostile; fire("MC_POST_NEW_ROOM")
end
local function complete()
    clear=true; fire("MC_PRE_SPAWN_CLEAN_AWARD")
end
local function shot(p)
    local data={}
    local t={SpawnerEntity=p,CollisionDamage=4,Scale=1.7,TearFlags=1<<52,
        GetData=function() return data end, Exists=function() return true end,
        HasTearFlags=function() return false end}
    fire("MC_POST_FIRE_TEAR",t)
    return t
end

local nextEntity=1000
local function entity(p,kind)
    nextEntity=nextEntity+1
    local data={}
    local e={pointer=nextEntity,InitSeed=nextEntity,SpawnerEntity=p,Type=kind or 2,
        CollisionDamage=4,ExplosionDamage=20,Scale=1.7,Color="native",TearFlags=1<<52,
        Height=-23,FallingSpeed=-1,FallingAcceleration=0.17,HomingFriction=0.08,
        KnockbackMultiplier=1.4,FrameCount=0,OneHit=false,DisableFollowParent=false,
        Position={},Velocity={},Variant=0}
    function e:GetData() return data end
    function e:Exists() return not self.removed end
    function e:HasTearFlags(flag) assert(flag==TearFlags.TEAR_LUDOVICO); return self.ludo or false end
    function e:IsCircleLaser() return self.circle or false end
    function e:IsFlying() return self.flying or false end
    function e:ResetSpriteScale() self.spriteScale=self.Scale end
    function e:ToPlayer() return nil end
    return e
end
local p,q
local function freshRun()
    players={player(1,11,0),player(2,22,1)}; p,q=players[1],players[2]
    paused=false; down={}; frame=0; load(); fire("MC_POST_GAME_STARTED",false); tick(150)
end
local function update(entries,n)
    for _=1,n or 1 do
        frame=frame+1
        for _,entry in ipairs(entries) do
            entry[2].FrameCount=entry[2].FrameCount+1
            fire(entry[1],entry[2])
        end
        fire("MC_POST_UPDATE")
    end
end
local function near(a,b,msg) assert(math.abs(a-b)<1e-8,(msg and msg..": " or "")..tostring(a).." ~= "..tostring(b)) end
freshRun()
local beam=entity(p,7)
update({{"MC_POST_LASER_UPDATE",beam}})
assert(beam.CollisionDamage==8 and state().thought==0,"a released native beam must receive and spend Thought")
assert(state(1).thought==150,"another co-op player's Thought is independent")
fire("MC_POST_LASER_UPDATE",beam); assert(beam.CollisionDamage==8,"duplicate updates cannot compound damage")
update({{"MC_POST_LASER_UPDATE",beam}},5); assert(beam.CollisionDamage==8)
update({{"MC_POST_LASER_UPDATE",beam}}); assert(beam.CollisionDamage==4,"repeated-hit beam bonus ends after six gameplay updates")
update({{"MC_POST_LASER_UPDATE",beam}},150); assert(state().thought==0,"an ongoing beam cannot recharge its own Thought")
assert(beam.Scale==1.7 and beam.TearFlags==1<<52 and beam.Color=="native")

freshRun()
local ring,second=entity(p,7),entity(p,7); ring.circle=true; second.OneHit=true
update({{"MC_POST_LASER_UPDATE",ring},{"MC_POST_LASER_UPDATE",second}})
assert(ring.CollisionDamage==8 and second.CollisionDamage==8,"same-frame mixed release attacks share one payment")
update({{"MC_POST_LASER_UPDATE",ring},{"MC_POST_LASER_UPDATE",second}},20)
assert(ring.CollisionDamage==8 and second.CollisionDamage==8,"released rings and single-hit beams keep their flight snapshot")

freshRun()
local bomb=entity(p,4)
update({{"MC_POST_BOMB_UPDATE",bomb}})
assert(bomb.ExplosionDamage==20 and state().thought==150,"ordinary bombs must neither pay nor gain Thought")
bomb.IsFetus=true; bomb.ExplosionDamage=0
update({{"MC_POST_BOMB_UPDATE",bomb}}); assert(state().thought==150,"wait for initialized bomb damage")
bomb.ExplosionDamage=20
local twin=entity(p,4); twin.IsFetus=true
update({{"MC_POST_BOMB_UPDATE",bomb},{"MC_POST_BOMB_UPDATE",twin}})
assert(bomb.ExplosionDamage==40 and twin.ExplosionDamage==40 and bomb.CollisionDamage==4)
update({{"MC_POST_BOMB_UPDATE",bomb}},20); assert(bomb.ExplosionDamage==40)

freshRun()
local knife=entity(p,8)
update({{"MC_POST_KNIFE_UPDATE",knife}},10)
assert(knife.CollisionDamage==4 and state().thought==150,"holding a knife does not spend a charged shot")
p.shooting=true; knife.flying=true
update({{"MC_POST_KNIFE_UPDATE",knife}}); assert(knife.CollisionDamage==8 and state().thought==0)
update({{"MC_POST_KNIFE_UPDATE",knife}},10); assert(knife.CollisionDamage==8,"a thrown knife snapshots once per flight")
knife.flying=false; p.shooting=false
update({{"MC_POST_KNIFE_UPDATE",knife}}); assert(knife.CollisionDamage==4,"returning to contact damage removes only our factor")
tick(150); knife.flying=true
update({{"MC_POST_KNIFE_UPDATE",knife}}); assert(knife.CollisionDamage==8,"the next actual throw can spend new Thought")
p.kind=0; update({{"MC_POST_KNIFE_UPDATE",knife}}); assert(knife.CollisionDamage==4)

freshRun()
local orb=entity(p); orb.ludo=true
frame=frame+1; fire("MC_POST_FIRE_TEAR",orb); fire("MC_POST_UPDATE")
assert(orb.CollisionDamage==8)
local fork=entity(p); fork.ludo=true
include("scripts.tear_fork").Copy(orb,fork,0.5)
assert(fork.CollisionDamage==4 and fork.Scale==orb.Scale and fork.TearFlags==orb.TearFlags)
-- A copied controlled tear never claims or recursively doubles the resource.
update({{"MC_POST_TEAR_UPDATE",fork},{"MC_POST_TEAR_UPDATE",orb}},5)
assert(fork.CollisionDamage==4 and orb.CollisionDamage==8 and state().thought==0)
update({{"MC_POST_TEAR_UPDATE",fork},{"MC_POST_TEAR_UPDATE",orb}})
assert(fork.CollisionDamage==2 and orb.CollisionDamage==4,"child-first update order cannot retain an expired factor")

freshRun()
orb=entity(p); orb.ludo=true
update({{"MC_POST_TEAR_UPDATE",orb}})
paused=true; update({{"MC_POST_TEAR_UPDATE",orb}},50)
assert(orb.CollisionDamage==8 and state().thought==0,"pause cannot advance the continuous budget")
paused=false; update({{"MC_POST_TEAR_UPDATE",orb}},5); assert(orb.CollisionDamage==8)
update({{"MC_POST_TEAR_UPDATE",orb}}); assert(orb.CollisionDamage==4 and state().thought==0)

freshRun()
beam=entity(p,7); update({{"MC_POST_LASER_UPDATE",beam}})
beam.CollisionDamage=5 -- A modeled engine refresh supplies a new unboosted value.
update({{"MC_POST_LASER_UPDATE",beam}}); assert(beam.CollisionDamage==10)
update({{"MC_POST_LASER_UPDATE",beam}},5); assert(beam.CollisionDamage==5,"restore the refreshed base, never the initial damage")

freshRun()
p.context=true; orb=entity(p); orb.ludo=true
frame=frame+1; fire("MC_POST_FIRE_TEAR",orb); fire("MC_POST_TEAR_UPDATE",orb); fire("MC_POST_UPDATE")
assert(orb.CollisionDamage==8)
update({{"MC_POST_TEAR_UPDATE",orb}},6)
near(orb.CollisionDamage,4)
update({{"MC_POST_TEAR_UPDATE",orb}},100); near(orb.CollisionDamage,4,"a Ludovico tear never rots")
assert(state().thought==0,"1M Context must not snapshot or compound a temporary Thought factor")
-- An ordinary tear still rots to 30% over three seconds.
local plain=entity(p); update({{"MC_POST_TEAR_UPDATE",plain}})
plain.FrameCount=44; update({{"MC_POST_TEAR_UPDATE",plain}}); near(plain.CollisionDamage,2)
plain.FrameCount=200; update({{"MC_POST_TEAR_UPDATE",plain}}); near(plain.CollisionDamage,1.2)

freshRun()
orb=entity(p); orb.ludo=true; update({{"MC_POST_TEAR_UPDATE",orb}})
fork=entity(p); fork.ludo=true; include("scripts.tear_fork").Copy(orb,fork,0.5)
-- Save immediately after raw child creation, before its first update.
fire("MC_PRE_GAME_EXIT",true)
assert(orb.CollisionDamage==4 and fork.CollisionDamage==2,"exit removes transient factors even from an unupdated raw fork")
assert(saved.deepseekRice["0"].thought==0)
assert(saved.deepseekRice["0"].windowRemaining==5 and saved.deepseekRice["0"].windowFactor==2)
load(); fire("MC_POST_GAME_STARTED",true)
update({{"MC_POST_TEAR_UPDATE",orb}},5)
assert(orb.CollisionDamage==8,"continue preserves only the five remaining updates of the paid window")
update({{"MC_POST_TEAR_UPDATE",orb}})
assert(orb.CollisionDamage==4,"continue cannot bank a permanent doubled orb or refill the full window")

freshRun()
beam=entity(p,7); update({{"MC_POST_LASER_UPDATE",beam}})
enter(2,false); assert(beam.CollisionDamage==4,"room transitions release transient damage leases")
local hostile=entity({ToPlayer=function() return nil end},7)
local reflected=entity(p,7); reflected.Parent=entity(p,7)
local detached=entity(p,7); detached.DisableFollowParent=true
local childBomb=entity(p,4); childBomb.Parent=entity(p,4); childBomb.IsFetus=true
state().thought=150
update({{"MC_POST_LASER_UPDATE",hostile},{"MC_POST_LASER_UPDATE",reflected},
    {"MC_POST_LASER_UPDATE",detached},{"MC_POST_BOMB_UPDATE",childBomb}})
assert(state().thought==150 and hostile.CollisionDamage==4 and childBomb.ExplosionDamage==20)

freshRun()
orb=entity(p); orb.ludo=true; update({{"MC_POST_TEAR_UPDATE",orb}})
fork=entity(p); fork.ludo=true; include("scripts.tear_fork").Copy(orb,fork,0.5)
orb.removed=true; fire("MC_POST_ENTITY_REMOVE",orb)
assert(fork.CollisionDamage==2,"parent removal releases inherited continuous bonuses")
update({{"MC_POST_TEAR_UPDATE",fork}},8); assert(state().thought>0,"derived effects cannot keep billing or mark the player as firing")
print("OK: native laser, knife, fetus-bomb and controlled-tear Thought adapters; shared windows, fork lifetime and Context composition")
