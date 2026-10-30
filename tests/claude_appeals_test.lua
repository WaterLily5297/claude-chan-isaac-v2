-- Real normal Claude callbacks: Appeals, volley billing, unique clears and the
-- Birthright age shield, across detached save/continue snapshots.
local root = arg[1]
local callbacks, players, frame, saved = {}, {}, 1, nil
local clear, room, floor, suspended, down = true, 1, 1, false, {}
local captions, draws, enemies = {}, {}, {}
local paused=false
EntityFlag={FLAG_FRIENDLY=1}
function EntityPtr(e) return {Ref=e} end
local function pos(x) return {X=x,Y=0,Distance=function(self,o) return math.abs(self.X-o.X) end} end
local C = {Player={CLAUDE_CHAN=41}, Item={BAN_HAMMER=733, SUBAGENT_SWARM=745}}
local Hud = {T=function(_,key,...) return key..":"..table.concat({...},",") end,
    Draw=function(_,text) draws[#draws+1]=text end}
function include(name)
    if name=="scripts.constants" then return C end
    if name=="scripts.characters.model_roster" then return {Find=function() end, IsFamily=function() return false end} end
    if name=="scripts.hud_text" then return Hud end
    return dofile(root.."/"..name:gsub("%.","/")..".lua")
end
local function copy(v)
    if type(v)~="table" then return v end
    local t={}; for k,x in pairs(v) do t[k]=copy(x) end; return t
end
package.preload.json=function() return {
    encode=function(v) saved=copy(v); return "snapshot" end,
    decode=function() return copy(saved) end,
} end
ModCallbacks=setmetatable({}, {__index=function(_,k) return k end})
CacheFlag={CACHE_DAMAGE=1}; ActiveSlot={SLOT_POCKET=2}
CollectibleType={COLLECTIBLE_BIRTHRIGHT=619}; ButtonAction={ACTION_DROP=11}
Input={IsActionPressed=function(_,controller) return down[controller] or false end}
function Color(...) return {...} end
function GetPtrHash(p) return p.pointer end
local nextPointer=0
local function player()
    nextPointer=nextPointer+1
    local p={kind=41,pointer=nextPointer,data={},InitSeed=nextPointer,ControllerIndex=#players,Damage=3.5,Position=pos(0)}
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:GetData() return self.data end
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return true end
    function p:HasCollectible(id) return (id==619 and self.birthright) or (id==745 and self.swarm) end
    function p:GetShootingInput() return {LengthSquared=function() return self.shooting and 1 or 0 end} end
    function p:SetPocketActiveItem() end
    function p:AddCacheFlags() end
    function p:EvaluateItems()
        self.Damage=3.5
        for _,c in ipairs(callbacks) do if c.id=="MC_EVALUATE_CACHE" then c.fn(mod,self,CacheFlag.CACHE_DAMAGE) end end
    end
    return p
end
Isaac={GetPlayer=function(i) return players[i+1] end, GetScreenHeight=function() return 270 end, GetScreenWidth=function() return 480 end, GetRoomEntities=function() return enemies end}
function Game() return {GetNumPlayers=function() return #players end,
    GetFrameCount=function() return frame end, IsPaused=function() return paused end,
    GetRoom=function() return {IsClear=function() return clear end} end,
    GetLevel=function() return {GetDungeonPlacementSeed=function() return floor end,
        GetStage=function() return 1 end, GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=room,SafeGridIndex=room} end} end,
    GetHUD=function() return {IsVisible=function() return true end,
        ShowItemText=function(_,a,b) captions[#captions+1]=a.." / "..b end} end} end
mod={}
function mod:AddCallback(id,fn) callbacks[#callbacks+1]={id=id,fn=fn} end
function mod:SaveData(s) self.saved=s end
function mod:HasData() return saved~=nil end
function mod:LoadData() return self.saved end
local Risk=include("scripts.risk")
function Risk:IsSuspended() return suspended end
local function fire(id,...) for _,c in ipairs(callbacks) do if c.id==id then c.fn(mod,...) end end end
local function load()
    callbacks={}
    mod:AddCallback("MC_POST_GAME_STARTED",function(_,continued)
        if continued then Risk:Load(mod) else Risk.state={} end
    end)
    mod:AddCallback("MC_PRE_GAME_EXIT",function(_,save) if save then Risk:Save(mod) end end)
    include("scripts.characters.claude_chan"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; for _,p in ipairs(players) do fire("MC_POST_PEFFECT_UPDATE",p) end; fire("MC_POST_UPDATE") end
end
local function usage(i) return Risk.state.claudeUsage[tostring(i or 0)] end
local function tap(p)
    down[p.ControllerIndex]=false; tick()
    down[p.ControllerIndex]=true; tick()
    down[p.ControllerIndex]=false; tick()
end
local function volley(p,n)
    frame=frame+1
    local tears={}
    for i=1,n or 1 do
        local data={}
        tears[i]={SpawnerEntity=p,CollisionDamage=10,GetData=function() return data end}
        fire("MC_POST_FIRE_TEAR",tears[i])
    end
    fire("MC_POST_PEFFECT_UPDATE",p)
    return tears
end
local function enter(index,hostile) room=index; clear=not hostile; fire("MC_POST_NEW_ROOM"); tick() end
local function complete() clear=true; fire("MC_PRE_SPAWN_CLEAN_AWARD") end
local function reload()
    fire("MC_PRE_GAME_EXIT",true)
    players={player(),player()}; frame=1; load(); fire("MC_POST_GAME_STARTED",true)
end

players={player(),player()}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
assert(usage().appeals==1 and usage().clears==0,"a new run starts with one Appeal")

-- One paid volley is one payment; Swarm doubles it.
volley(p,4); assert(usage().value==4,"same-frame pellets share one payment")
p.swarm=true; volley(p); assert(usage().value==12,"Swarm adds one extra 4-point payment"); p.swarm=false
-- Laser starts and Dr. Fetus bombs bill the same per-frame payment; familiars and plain bombs do not.
local familiar={ToPlayer=function() end}
local mixedData={}
frame=frame+1; fire("MC_POST_LASER_INIT",{SpawnerEntity=p}); fire("MC_POST_FIRE_TEAR",{SpawnerEntity=p,CollisionDamage=10,GetData=function() return mixedData end})
fire("MC_POST_LASER_INIT",{SpawnerEntity=p}); assert(usage().value==16,"a laser shares its frame's payment")
frame=frame+1; fire("MC_POST_BOMB_INIT",{SpawnerEntity=p,IsFetus=true}); assert(usage().value==20,"a Fetus bomb pays")
frame=frame+1; fire("MC_POST_BOMB_INIT",{SpawnerEntity=p,IsFetus=false}); fire("MC_POST_LASER_INIT",{SpawnerEntity=familiar})
fire("MC_POST_BOMB_INIT",{SpawnerEntity=familiar,IsFetus=true}); assert(usage().value==20,"placed bombs and familiars are free")
frame=frame+1; fire("MC_POST_LASER_INIT",{SpawnerEntity=q}); assert(usage().value==20 and usage(1).value==4,"lasers bill their own player"); usage(1).value=0
-- A held beam pays once per further 0.2-second window through the observer.
EntityType={ENTITY_LASER=7,ENTITY_KNIFE=8,ENTITY_EFFECT=1000}; EffectVariant={TARGET=30,ROCKET=31}
do
    local beam={SpawnerEntity=p,FrameCount=0,GetData=function() return {} end}
    usage().value=0
    for f=0,12 do beam.FrameCount=f; frame=frame+1; fire("MC_POST_LASER_UPDATE",beam) end
    assert(usage().value==8,"a held beam pays at 6 and 12 updates after its start")
    usage().value=0
end
-- The volley that reaches the limit keeps full damage for all of its pellets.
usage().value=98
local edge=volley(p,3)
assert(usage().limited>0 and edge[1].CollisionDamage==10 and edge[3].CollisionDamage==10,
    "the limit applies from the next volley")
assert(math.abs(p.Damage-3.5*0.4)<1e-9,"Limited weakens the damage stat, so every weapon")
assert(math.abs(q.Damage-3.5)<1e-9,"Limited is personal")
local weak=volley(p,2)
assert(weak[1].CollisionDamage==10 and weak[1].Color,"Limited tears keep their stat damage and get a grey tint")

-- Appeals cannot cancel an active Limited penalty.
local before=usage().limited
tap(p); assert(usage().appeals==1 and usage().limited==before-3,"no Appeal during Limited")
usage().limited=1; tick(); assert(usage().value==0 and math.abs(p.Damage-3.5)<1e-9,"the end of Limited restores damage")
usage().value=60
captions={}
tap(p); assert(usage().appeals==0 and usage().value<=20 and usage().value>=18,"an Appeal removes 40 usage")
assert(captions[#captions]=="Appeal filed / Another love letter.")
local now=usage().value
tap(p); assert(usage().value<=now,"no Appeals left means no relief")
assert(usage(1).appeals==1,"Appeals are personal")
usage().appeals=1; usage().value=0
tap(p); assert(usage().appeals==1,"nothing to appeal keeps the Appeal")
usage().value=50
down[0]=true; tick(20); down[0]=false; tick()
assert(usage().appeals==1,"a long DROP hold stays native")

-- Unique hostile clears earn Appeals; empty or repeated rooms do not.
usage().appeals=0
enter(2,false); complete(); assert(usage().clears==0,"an empty-room clear pays nothing")
enter(3,true); complete(); complete(); assert(usage().clears==1,"one award per room")
enter(2,false); enter(3,true); complete(); assert(usage().clears==1,"re-entry cannot pay twice")
enter(4,true); complete(); assert(usage().appeals==1 and usage().clears==0,"two clears earn an Appeal")
assert(usage(1).appeals==2,"the partner earned separately and is capped at two")
for i=5,10 do enter(i,true); complete() end
assert(usage().appeals==2,"Appeals cap at two")
q.dead=true; usage(1).appeals=0; usage(1).clears=0
enter(11,true); complete(); assert(usage(1).clears==0,"dead players earn nothing")
q.dead=false
usage().clears=0
floor=2; enter(3,true); complete(); assert(usage().clears==1,"same room index on a new floor is eligible")

-- Continue keeps Appeals, progress and a partly fought room.
usage().appeals=1
enter(12,true); reload(); p,q=players[1],players[2]
assert(usage().appeals==1 and usage().clears==1,"continue keeps Appeal progress")
complete(); assert(usage().appeals==2 and usage().clears==0,"a room armed before saving still pays")
-- Old or corrupt saves fall back to the normal allowance.
Risk.state.claudeUsage["0"]={value=10,limited=0}
tick(); assert(usage().appeals==1 and usage().clears==0 and usage().value<=10,"old saves start with one Appeal")
Risk.state.claudeUsage["0"].appeals=0/0
tick(); assert(usage().appeals==1)

-- Birthright keeps account age through the first suspension on each floor.
usage().age=3
p.birthright=true; suspended=true; tick()
assert(usage().age==3,"Birthright shields the first suspension")
reload(); p,q=players[1],players[2]; p.birthright=true; tick()
assert(usage().age==3,"continue does not re-judge a handled suspension")
suspended=false; tick(); suspended=true; tick()
assert(usage().age==0,"the second suspension on a floor resets age")
assert(usage(1).age==0,"the partner without Birthright lost its own age")
suspended=false; tick(); usage().age=2; usage(1).age=0; floor=3; enter(1,false)
suspended=true; tick(); assert(usage().age==2,"a new floor renews the shield")
suspended=false; tick(); p.birthright=false
suspended=true; tick(); assert(usage().age==0,"without Birthright suspension resets age")
suspended=false

-- Floors now offer a kill-order review instead of automatic account age.
local function foe(seed,x)
 local e={InitSeed=seed,Type=10,Variant=0,SubType=0,Position=pos(x),dead=false,friendly=false,vulnerable=true}
 function e:Exists() return not self.removed end
 function e:IsDead() return self.dead end
 function e:IsEnemy() return true end
 function e:IsVulnerableEnemy() return self.vulnerable end
 function e:HasEntityFlags() return self.friendly end
 enemies[#enemies+1]=e; return e
end
local function kill(e) e.dead=true; fire("MC_POST_ENTITY_KILL",e) end
local function nextFloor(n)
 floor=n; clear=true; enemies={}; room=1; fire("MC_POST_NEW_LEVEL"); fire("MC_POST_NEW_ROOM"); tick()
end
usage().age=1; usage(1).age=4; nextFloor(4)
assert(usage().age==1 and usage(1).age==4,"a new floor does not grant unearned age")
local reviewA,reviewB=foe(91,10),foe(92,40); enter(40,true)
assert(usage().review.phase=="active" and usage().review.target=="91:10:0:0")
kill(reviewB); tick(); kill(reviewA); clear=true; tick()
assert(usage().age==2 and usage(1).age==5,"last target earns the original personal age award")
fire("MC_POST_UPDATE"); complete(); assert(usage().age==2,"award is once per floor")
p:EvaluateItems(); assert(math.abs(p.Damage-3.9)<1e-9)
-- An early death misses only this floor; simultaneous deaths count as last.
nextFloor(5); local early,other=foe(100,10),foe(101,50); enter(41,true); kill(early); tick()
assert(usage().review.phase=="missed" and usage().age==2); kill(other); clear=true; tick(); assert(usage().age==2)
nextFloor(6); early,other=foe(102,10),foe(103,50); enter(42,true)
kill(early); kill(other); clear=true; tick(); assert(usage().age==3,"same-frame clear counts as last")
-- Single-enemy rooms and peaceful rooms do not choose a target; revisits do not retry.
nextFloor(7); early=foe(110,10); enter(43,true); assert(usage().review.phase=="waiting")
other=foe(111,20); enter(43,true); assert(usage().review.phase=="waiting")
enemies={}; local high,low=foe(120,20),foe(119,-20); enter(44,true)
assert(usage().review.target=="119:10:0:0","equal-distance tie uses stable seed")
-- Save contains only primitive target identity; continue can resolve recreated entities.
reload(); p,q=players[1],players[2]; enemies={}; high,low=foe(120,20),foe(119,-20); tick()
assert(usage().review.phase=="active"); kill(high); kill(low); clear=true; tick(); assert(usage().age==4)
-- Departure cancels; a missing/changed target never grants age. Pause cannot settle a kill.
nextFloor(8); early,other=foe(130,10),foe(131,40); enter(45,true); enter(46,false)
assert(usage().review.phase=="missed" and usage().age==4)
nextFloor(9); early,other=foe(140,10),foe(141,40); enter(47,true); early.friendly=true; tick()
assert(usage().review.phase=="missed")
nextFloor(10); early,other=foe(150,10),foe(151,40); enter(48,true); kill(early); kill(other); clear=true
paused=true; tick(); assert(usage().age==4); paused=false; tick(); assert(usage().age==5)
-- Prior suspension policy and eight-award cap remain; replacement cannot inherit an active review.
nextFloor(11); early,other=foe(160,10),foe(161,40); enter(49,true); usage().age=8
kill(early); kill(other); clear=true; tick(); assert(usage().age==8)
nextFloor(12); early,other=foe(170,10),foe(171,40); enter(50,true)
players[1]=player(); p=players[1]; tick(); assert(usage().review.phase=="none","replacement gets no borrowed challenge")
kill(early); kill(other); clear=true; tick()
assert(usage().age==0,"a replacement owner keeps neither the old age nor its unfinished review award")
nextFloor(13); early,other=foe(180,10),foe(181,40); enter(51,true); p.kind=0; tick(); p.kind=41; tick()
assert(usage().review.phase=="none","changing away and back cannot resume the challenge")
usage().age=nil; usage(1).age=nil; Risk.state.accountAge=3
reload(); p,q=players[1],players[2]
assert(usage().age==3 and usage(1).age==3 and Risk.state.accountAge==nil,"a shared legacy age migrates per player")

fire("MC_POST_RENDER")
local found=false
for _,text in ipairs(draws) do if text:match("Appeals %d/2") then found=true end end
assert(found,"HUD shows Appeals")
fire("MC_POST_GAME_STARTED",false); assert(usage().appeals==1,"a new run resets Appeals")
print("OK: Claude Appeals, volley billing, unique clears, Birthright age shield and save lifecycle")
