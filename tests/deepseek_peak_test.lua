-- Real Peak / Valley, fork and DROP callbacks with detached save/continue snapshots.
local root=arg[1]
local frame, paused, clear, room, floor = 0, false, true, 1, 10
local callbacks, players, saved, draws, spawned = {}, {}, nil, {}, {}
local C={RISK_MAX=100,Player={DEEPSEEK_CHAN=42,DEEPSEEK_CHAN_B=142}}
function include(name)
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
CollectibleType={COLLECTIBLE_BIRTHRIGHT=619}
EntityType={ENTITY_TEAR=2,ENTITY_BOMB=4,ENTITY_LASER=7,ENTITY_KNIFE=8,ENTITY_EFFECT=1000}
ButtonAction={ACTION_DROP=11}
local down={}
Input={IsActionPressed=function(_,controller) return down[controller] or false end}
function GetPtrHash(p) return p.pointer end
function EntityPtr(e) return {Ref=e} end
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
Isaac={GetPlayer=function(i) return players[i+1] end,GetScreenHeight=function() return 270 end,GetScreenWidth=function() return 480 end,
    Spawn=function(_,variant,_,_,velocity,owner)
        local data={}
        local t={Variant=variant,Velocity=velocity,SpawnerEntity=owner,TearFlags=0,Scale=1}
        function t:ToTear() return self end
        function t:ResetSpriteScale() self.spriteScale=self.Scale end
        function t:GetData() return data end
        function t:Exists() return true end
        spawned[#spawned+1]=t
        return t
    end}
local mod={AddCallback=function(_,id,fn) callbacks[#callbacks+1]={id=id,fn=fn} end}
function mod:SaveData(s) self.saved=s end
function mod:LoadData() return self.saved end
function mod:HasData() return saved~=nil end
local function fire(id,...)
    for _,cb in ipairs(callbacks) do if cb.id==id then cb.fn(mod,...) end end
end
local function player(pointer,seed,controller)
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=142,
        dead=false,shooting=false}
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return true end
    function p:HasCollectible(id) return id==619 and self.birthright end
    function p:GetShootingInput() return {LengthSquared=function() return self.shooting and 1 or 0 end} end
    return p
end
local Risk=include("scripts.risk")
local function load()
    callbacks={}
    mod:AddCallback("MC_POST_GAME_STARTED",function(_,continued)
        if continued then Risk:Load(mod) else Risk.state={} end
    end)
    mod:AddCallback("MC_PRE_GAME_EXIT",function(_,save) if save then Risk:Save(mod) end end)
    include("scripts.characters.deepseek_peak"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.deepseekPeak[tostring(i or 0)] end
local function tap(p)
    down[p.ControllerIndex]=false; tick()
    down[p.ControllerIndex]=true; tick()
    down[p.ControllerIndex]=false; tick()
end
local function enter(index,hostile)
    room=index; clear=not hostile; fire("MC_POST_NEW_ROOM")
end
local function shot(p,alive)
    spawned={}
    local data={}
    local t={SpawnerEntity=p,CollisionDamage=4,Scale=1.7,TearFlags=1<<52,Variant=0,Position={},
        Velocity={Rotated=function(_,a) return a end},Color="native",Height=-20,FallingSpeed=0,
        FallingAcceleration=0.3,HomingFriction=0,KnockbackMultiplier=1}
    function t:GetData() return data end
    function t:Exists() return alive~=false end
    fire("MC_POST_FIRE_TEAR",t)
    return t
end
local function reload(newPlayers)
    fire("MC_PRE_GAME_EXIT",true)
    players=newPlayers; frame=0
    load(); fire("MC_POST_GAME_STARTED",true)
end

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
local s=state()
assert(s.compute==12 and s.phase=="valley" and s.remaining==360 and not s.saving,"new run starts in Valley with 12")

-- A paid volley pays once and forks every tear in it at half damage.
local t=shot(p)
assert(#spawned==2 and spawned[1].CollisionDamage==2 and spawned[1].Velocity==-12 and spawned[2].Velocity==12)
assert(spawned[1].TearFlags==t.TearFlags and spawned[1].Scale==1.7 and spawned[1].SpawnerEntity==p,
    "forks keep native effects and owner")
assert(t.CollisionDamage==4 and state().compute==10,"Valley costs 2; the primary tear is untouched")
local pellet=shot(p); assert(#spawned==2 and state().compute==10,"same-frame pellets share one payment")
local child=spawned[1]; spawned={}
fire("MC_POST_FIRE_TEAR",pellet)
assert(#spawned==0 and state().compute==10,"duplicate callbacks cannot fork again")
fire("MC_POST_FIRE_TEAR",child); assert(#spawned==0,"forks cannot fork recursively")
assert(state(1).compute==12,"spending is personal")
tick(); shot(p,false); assert(#spawned==0 and state().compute==10,"a cancelled tear neither forks nor pays")

-- Empty rooms freeze the schedule and recovery.
tick(100); assert(state().remaining==360 and state().compute==10,"cleared rooms freeze the timer")
enter(2,true)
tick(10); assert(state().remaining==350 and state().compute==11,"Valley recovers 3 per second in combat")
p.shooting=true; tick(30); assert(state().compute==11,"firing blocks recovery")
p.shooting=false
tick(5); paused=true; tick(30); paused=false
assert(state().remaining==315,"pause does not advance the schedule")
fire("MC_POST_UPDATE"); assert(state().remaining==315,"a duplicate frame cannot advance the schedule")
tick(315); assert(state().phase=="peak" and state().remaining==360,"twelve combat seconds switch to Peak")
assert(state().reserved==4 and state().compute==20,"Peak reserves four from the recovered 24")
local before=state().compute
tick(30); assert(state().compute==before,"Peak does not recover Compute")
tick(); shot(p); assert(#spawned==2 and state().compute==before-4,"Peak costs 4")

-- Insufficient Compute suppresses only the forks.
state().compute=3
tick(); local poor=shot(p); assert(#spawned==0 and state().compute==3 and poor.CollisionDamage==4)

-- DROP toggles Saving with a one-second cooldown; holds stay native.
state().compute=20
tap(p); assert(state().saving,"tap toggles Saving")
tick(); shot(p); assert(#spawned==0 and state().compute==20,"Saving spends nothing and keeps the shot")
tap(p); assert(state().saving,"a second tap inside the cooldown is ignored")
tick(30); tap(p); assert(not state().saving,"after the cooldown a tap restores Forks On")
down[0]=true; tick(20); down[0]=false; tick(); assert(not state().saving,"a long hold does not toggle")
assert(not state(1).saving,"another player's mode is untouched")

-- Caps follow Birthright and clamp when it is lost.
state().phase="valley"; state().reserved=0; state().compute=23; state().regen=0
tick(40); assert(state().compute==24,"Valley recovery stops at 24")
p.birthright=true; tick(80); assert(state().compute==32,"Birthright raises the cap to 32")
p.birthright=false; tick(); assert(state().compute==24,"losing Birthright clamps to the base cap")

-- Continue keeps Compute, phase, timer and mode, with recreated entities.
state().compute=17; state().phase="peak"; state().remaining=123; state().saving=true
local partner=state(1).compute
assert(partner>12,"the partner recovered independently in combat")
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]
s=state(); assert(s.compute==17 and s.phase=="peak" and s.remaining==123 and s.saving,"continue preserves state")
assert(state(1).compute==partner)

-- A new floor resets the phase but keeps Compute.
floor=20; enter(1,false)
assert(state().phase=="valley" and state().remaining==360 and state().compute==17,"new floor starts in Valley")
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]
assert(state().phase=="valley" and state().compute==17,"continue on the same floor does not reset")

-- Identity and character changes do not transfer Compute.
state().compute=5
players[1]=player(101,999,0); p=players[1]; tick()
assert(state().compute==12,"a replacement player gets fresh Compute")
state().compute=5
p.kind=42; tick(); assert(state()==nil)
spawned={}; shot(p); assert(#spawned==0,"normal DeepSeek never receives tainted forks")
p.kind=142; tick(); assert(state().compute==12)

-- Corrupt saves are discarded rather than trusted.
Risk.state.deepseekPeak["0"]={version=1,compute=math.huge,regen=0,phase="peak",remaining=0/0,saving=true}
tick(); assert(state().compute==12 and state().phase=="valley" and not state().saving)
Risk.state.deepseekPeak["0"]={version=1,compute=40,regen=0,phase="valley",remaining=10,saving=false}
tick(); assert(state().compute==12,"Compute above every cap is invalid")

-- Dead players neither advance nor spend.
enter(3,true); q.dead=true; local r=state(1).remaining; tick(10)
assert(state(1).remaining==r,"a dead player's schedule is frozen")
q.dead=false

-- Non-tear attacks buy a same-priced 1.3x off-peak boost instead of forks.
do
    enter(4,false); state().phase="valley"; state().saving=false; state().compute=10; tick()
    local function weapon(kind,fields)
        local e=fields or {}; e.Type=kind; local d={}
        function e:GetData() return d end
        function e:ToPlayer() end
        return e
    end
    local dealt
    local enemy={ToPlayer=function() end, TakeDamage=function(_,amount) dealt=amount end}
    local function hit(w,target)
        dealt=nil
        for _,cb in ipairs(callbacks) do
            if cb.id=="MC_ENTITY_TAKE_DMG" and cb.fn(mod,target or enemy,10,0,{Entity=w},0)==false then return dealt end
        end
        return 10
    end
    local function near(a,b) assert(math.abs(a-b)<1e-9,a.." ~= "..b) end
    frame=frame+1
    local ring=weapon(7,{SpawnerEntity=p,OneHit=true})
    fire("MC_POST_LASER_INIT",ring); assert(state().compute==8,"a laser start pays the Valley price")
    near(hit(ring),13); frame=frame+30; near(hit(ring),13)
    frame=frame+1
    local same=weapon(7,{SpawnerEntity=p,OneHit=true}); fire("MC_POST_LASER_INIT",same)
    shot(p); assert(#spawned==2,"the shared payment still forks the tear")
    assert(state().compute==6,"a laser and a tear on one frame share one payment")
    -- A held beam is boosted for its paid window only, then per paid window.
    frame=frame+1
    local beam=weapon(7,{SpawnerEntity=p,FrameCount=0}); fire("MC_POST_LASER_INIT",beam)
    assert(state().compute==4); near(hit(beam),13)
    frame=frame+7; near(hit(beam),10)
    beam.FrameCount=7; fire("MC_POST_LASER_UPDATE",beam); assert(state().compute==2,"the next window pays")
    near(hit(beam),13)
    -- Not enough Compute or Saving: native damage, nothing spent.
    frame=frame+7; beam.FrameCount=14; fire("MC_POST_LASER_UPDATE",beam); assert(state().compute==0)
    frame=frame+7; beam.FrameCount=21; fire("MC_POST_LASER_UPDATE",beam); near(hit(beam),10)
    state().compute=10; state().saving=true
    frame=frame+1; local saved=weapon(4,{SpawnerEntity=p,IsFetus=true}); fire("MC_POST_BOMB_INIT",saved)
    assert(state().compute==10); near(hit(saved),10)
    state().saving=false
    -- Dr. Fetus bombs pay for their explosion; placed bombs stay native.
    frame=frame+1; local fetus=weapon(4,{SpawnerEntity=p,IsFetus=true}); fire("MC_POST_BOMB_INIT",fetus)
    assert(state().compute==8); frame=frame+40; near(hit(fetus),13)
    frame=frame+1; local placed=weapon(4,{SpawnerEntity=p,IsFetus=false}); fire("MC_POST_BOMB_INIT",placed)
    assert(state().compute==8); near(hit(placed),10)
    -- A knife throw is boosted in flight only.
    frame=frame+1
    local knife=weapon(8,{SpawnerEntity=p,SubType=0,flying=true}); function knife:IsFlying() return self.flying end
    fire("MC_POST_KNIFE_UPDATE",knife); assert(state().compute==6); near(hit(knife),13)
    knife.flying=false; fire("MC_POST_KNIFE_UPDATE",knife); near(hit(knife),10)
    -- Peak prices apply; familiar weapons and player targets are untouched.
    state().phase="peak"
    frame=frame+1; local peak=weapon(7,{SpawnerEntity=p,OneHit=true}); fire("MC_POST_LASER_INIT",peak)
    assert(state().compute==2,"Peak costs 4"); near(hit(peak),13)
    assert(hit(peak,p)==10,"players are never re-dealt")
    frame=frame+1; fire("MC_POST_LASER_INIT",weapon(7,{SpawnerEntity={ToPlayer=function() end},OneHit=true}))
    assert(state().compute==2,"familiar lasers are free")
    state().phase="valley"
end

fire("MC_POST_RENDER")
local hud=draws[#draws]
assert(hud:match("Compute %d+/24") and hud:match("Valley") and hud:match("Forks On"),hud)

-- Reservations are conserved across phases, floor changes and continuation.
clear=false; p.shooting=true; state().saving=true; state().phase="valley"; state().compute=3; state().reserved=0; state().remaining=1
tick(); assert(state().phase=="peak" and state().compute==0 and state().reserved==3)
fire("MC_POST_UPDATE"); assert(state().reserved==3 and state().compute==0)
reload({player(401,11,0),player(402,22,1)}); p,q=players[1],players[2]; p.shooting=true
assert(state().reserved==3 and state().compute==0,"continue preserves exactly the reservation")
state().remaining=1; tick(); assert(state().phase=="valley" and state().compute==3 and state().reserved==0)
state().remaining=1; state().compute=10; tick(); assert(state().reserved==4 and state().compute==6)
floor=77; enter(1,false); assert(state().phase=="valley" and state().compute==10 and state().reserved==0)
fire("MC_POST_NEW_ROOM"); tick(); assert(state().compute==10,"floor refund occurs once")
p.birthright=true; state().compute=28; state().reserved=4; state().phase="peak"
p.birthright=false; tick(); assert(state().compute==20 and state().reserved==4,"cap loss clamps total Compute")
floor=78; enter(1,false); assert(state().compute==24 and state().reserved==0)
Risk.state.deepseekPeak["0"]={version=1,compute=7,regen=0,phase="peak",remaining=100,saving=true}
tick(); assert(state().version==2 and state().compute==7 and state().reserved==0,"legacy Peak does not reserve retroactively")
fire("MC_POST_GAME_STARTED",false)
assert(state().compute==12 and state().phase=="valley","a new run resets Compute")
print("OK: Peak / Valley schedule, Compute caps, volley forks, Saving mode and save/floor/identity lifecycle")
