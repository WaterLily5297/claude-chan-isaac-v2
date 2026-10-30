-- Real tainted Kimi You Are the Manager: task slots, pulses, room budget and save/continue snapshots.
local root=arg[1]
local frame, paused, clear, room, floor = 0, false, true, 1, 10
local callbacks, players, saved, draws, texts, enemies = {}, {}, nil, {}, {}, {}
local C={RISK_MAX=100,Player={CLAUDE_CHAN=41,DEEPSEEK_CHAN=42}}
function include(name)
    if name=="scripts.constants" then return C end
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
CacheFlag={CACHE_DAMAGE=1}
EntityType={ENTITY_PLAYER=1,ENTITY_TEAR=2,ENTITY_BOMB=4,ENTITY_LASER=7,ENTITY_KNIFE=8,ENTITY_EFFECT=1000}
EffectVariant={PLAYER_CREEP_BLACK=45}
function Vector(x,y) return {X=x,Y=y} end
function Color(r,g,b,a) return {R=r,G=g,B=b,A=a} end
local peels={}
EntityPartition={ENEMY=8}
EntityFlag={FLAG_FRIENDLY=1}
ButtonAction={ACTION_DROP=11}
local down={}
Input={IsActionPressed=function(_,controller) return down[controller] or false end}
function GetPtrHash(e) return e.pointer end
function EntityPtr(e) return {Ref=e} end
function EntityRef(e) return {Entity=e} end
local function vec(x) return {x=x, Distance=function(self,o) return math.abs(self.x-o.x) end} end
function Game() return {
    GetFrameCount=function() return frame end, GetNumPlayers=function() return #players end,
    IsPaused=function() return paused end,
    GetRoom=function() return {IsClear=function() return clear end} end,
    GetLevel=function() return {
        GetDungeonPlacementSeed=function() return floor end,
        GetStage=function() return 1 end,GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=room*13} end,
    } end,
    GetHUD=function() return {IsVisible=function() return true end,
        ShowItemText=function(_,_,text) texts[#texts+1]=text end} end,
} end
Isaac={GetPlayer=function(i) return players[i+1] end,GetScreenHeight=function() return 270 end,GetScreenWidth=function() return 480 end,
    GetPlayerTypeByName=function(name,tainted) return name=="Kimi-chan" and (tainted and 158 or 58) or -1 end,
    Spawn=function(kind,variant,_,pos,_,owner)
        local e={Type=kind,Variant=variant,Position=pos,SpawnerEntity=owner,removed=false}
        function e:ToEffect() return self end
        function e:SetTimeout(t) self.timeout=t end
        function e:Exists() return not self.removed end
        function e:Remove() self.removed=true end
        peels[#peels+1]=e
        return e
    end,
    FindInRadius=function(pos,radius)
        local found={}
        for _,e in ipairs(enemies) do if math.abs(e.Position.x-pos.x)<=radius+10 then found[#found+1]=e end end
        return found
    end}
local mod={AddCallback=function(_,id,fn) callbacks[#callbacks+1]={id=id,fn=fn} end}
function mod:SaveData(s) self.saved=s end
function mod:LoadData() return self.saved end
function mod:HasData() return saved~=nil end
local function fire(id,...)
    for _,cb in ipairs(callbacks) do if cb.id==id then cb.fn(mod,...) end end
end
local function player(pointer,seed,controller)
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=158,dead=false,
        Position=vec(0),Damage=10}
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return true end
    function p:HasCollectible(id) return id==619 and self.birthright end
    function p:AddCacheFlags() end
    function p:EvaluateItems() self.Damage=10; fire("MC_EVALUATE_CACHE",self,CacheFlag.CACHE_DAMAGE) end
    return p
end
local nextEnemy=1000
local function enemy(x)
    nextEnemy=nextEnemy+1
    local e={pointer=nextEnemy,Position=vec(x),dead=false,friendly=false,removed=false}
    function e:IsVulnerableEnemy() return true end
    function e:IsDead() return self.dead end
    function e:Exists() return not self.removed end
    function e:HasEntityFlags(f) return f==EntityFlag.FLAG_FRIENDLY and self.friendly end
    function e:ToPlayer() return nil end
    function e:AddSlowing(_,frames,value) self.slowed={frames,value} end
    e.taken={}
    function e:TakeDamage(amount,flags,source,countdown)
        local cancelled=false
        for _,cb in ipairs(callbacks) do
            if cb.id=="MC_ENTITY_TAKE_DMG" and cb.fn(mod,self,amount,flags,source,countdown)==false then cancelled=true end
        end
        if not cancelled then self.taken[#self.taken+1]=amount end
    end
    enemies[#enemies+1]=e
    return e
end
local Risk=include("scripts.risk")
local function load()
    callbacks={}
    mod:AddCallback("MC_POST_GAME_STARTED",function(_,continued)
        if continued then Risk:Load(mod) else Risk.state={} end
    end)
    mod:AddCallback("MC_PRE_GAME_EXIT",function(_,save) if save then Risk:Save(mod) end end)
    include("scripts.characters.kimi_manager"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.kimiManager[tostring(i or 0)] end
local function near(a,b) assert(math.abs(a-b)<1e-8,tostring(a).." ~= "..tostring(b)) end
local function tap(p)
    down[p.ControllerIndex]=false; tick()
    down[p.ControllerIndex]=true; tick()
    down[p.ControllerIndex]=false; tick()
end
local function enter(index,hostile)
    room=index; clear=not hostile; enemies={}; fire("MC_POST_NEW_ROOM"); tick()
end
local function finish() clear=true; fire("MC_PRE_SPAWN_CLEAN_AWARD"); tick() end
local function tear(owner,volley)
    local data={}
    local t={Type=EntityType.ENTITY_TEAR,SpawnerEntity=owner,FrameCount=0}
    function t:GetData() return data end
    function t:Exists() return true end
    function t:ToPlayer() return nil end
    if volley~=false then fire("MC_POST_FIRE_TEAR",t) end
    return t
end
local function hit(target,source,amount) target:TakeDamage(amount or 10,0,{Entity=source},0); return target.taken[#target.taken] end
local function reload(newPlayers)
    fire("MC_PRE_GAME_EXIT",true)
    players=newPlayers; frame=0
    load(); fire("MC_POST_GAME_STARTED",true)
end



local function hud() draws={}; fire("MC_POST_RENDER"); return draws[1] end
players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
near(p.Damage,8.5); assert(hud()=="Kimi-chan: Tasks 0/3  Budget 9/9",hud())

-- No tasks outside combat.
local idle=enemy(40); tap(p); assert(not texts[1] and #idle.taken==0)

-- DROP assigns the nearest unassigned enemy; three slots; three 0.6x pulses two seconds apart.
enter(2,true)
local e1,e2,e3,e4,far=enemy(50),enemy(100),enemy(150),enemy(200),enemy(300)
tap(p); tap(p); tap(p); assert(texts[#texts]=="You are the manager" and #texts==3)
assert(hud()=="Kimi-chan: Tasks 3/3  Budget 0/9",hud())
tap(p); assert(#texts==3,"three slots")
tick(50); assert(#e1.taken==0)
tick(); assert(#e1.taken==1 and #e2.taken==0); near(e1.taken[1],5.1)
tick(3); assert(#e2.taken==1 and #e3.taken==0); tick(3); assert(#e3.taken==1)
paused=true; tick(30); paused=false; fire("MC_POST_UPDATE"); fire("MC_POST_UPDATE")
tick(53); assert(#e1.taken==1); tick(); assert(#e1.taken==2)
tick(66); assert(#e1.taken==3 and #e2.taken==3 and #e3.taken==3,"three pulses each")
assert(#e4.taken==0 and #far.taken==0,"only assigned enemies are hit")
tick(120); assert(#e1.taken==3 and hud()=="Kimi-chan: Tasks 0/3  Budget 0/9","tasks end after three pulses")
tap(p); assert(#texts==3,"the room budget is spent")
assert(hud()=="DROP: Room pulse budget spent" and state(1).budget["10:26"]==nil,"each player has a budget")
tick(45); assert(hud():find("Tasks 0/3"),"task HUD returns after refusal")

-- No target, no spend; early death frees the slot but not the budget.
enter(3,true); far=enemy(225); tap(p); assert(hud()=="DROP: No unassigned target nearby",hud())
local quick=enemy(60); tap(p); tick(59); quick.dead=true; tick(); assert(#quick.taken==0,"no pulse on a dead target")
assert(hud()=="Kimi-chan: Tasks 0/3  Budget 6/9",hud())
quick.dead=false; tick(70); assert(#quick.taken==0,"a cancelled task never resumes"); quick.dead=true
local friend=enemy(20); friend.friendly=true; local other=enemy(80); tap(p); tick(60); assert(#friend.taken==0 and #other.taken==1)

-- Leaving cancels tasks; coming back keeps the spent budget.
enter(4,true); assert(hud()=="Kimi-chan: Tasks 0/3  Budget 9/9")
tick(120); assert(#other.taken==1,"exit cancels tasks")
local fragile=enemy(40); function fragile:TakeDamage(a) self.taken[#self.taken+1]=a; self.dead=true end
tap(p); tick(60); assert(#fragile.taken==1 and hud()=="Kimi-chan: Tasks 0/3  Budget 6/9",hud())
enter(3,true); assert(hud()=="Kimi-chan: Tasks 0/3  Budget 3/9",hud())

-- Birthright pulses are 0.7x; a dead Kimi's tasks wait.
local boss=enemy(30); p.birthright=true; tap(p)
p.dead=true; tick(90); p.dead=false; assert(#boss.taken==0)
tick(60); assert(#boss.taken==1); near(boss.taken[1],5.95); p.birthright=false

-- Continue keeps budgets, not tasks; a new floor forgets old rooms.
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().budget["10:39"]==9); near(p.Damage,8.5); assert(hud():find("Tasks 0/3  Budget 0/9"))
tick(120); assert(#boss.taken==1,"tasks do not survive a continue")
floor=20; enter(3,true); assert(next(state().budget)==nil and hud()=="Kimi-chan: Tasks 0/3  Budget 9/9")

-- Identity and character changes do not transfer progress; corrupt data resets.
state().budget["x"]=6; players[1]=player(101,999,0); p=players[1]; tick(); assert(next(state().budget)==nil)
p.kind=0; tick(); assert(state()==nil); p:EvaluateItems(); near(p.Damage,10)
p.kind=158; tick()
for _,bad in ipairs({{version=1,budget={a=2}},{version=1,budget={a=10}},{version=1,budget={a=4.5}},{version=1,budget={[1]=3}},{version=1}}) do
    Risk.state.kimiManager["0"]=bad; tick(); assert(type(state().budget)=="table" and next(state().budget)==nil)
end
Risk.state.kimiManager["0"]={version=1,budget={a=9}}; tick(); assert(state().budget.a==9,"valid data is kept")
-- A paid owner hit pauses only that task, for one refreshable second.
enter(50,true); local taskTarget=enemy(40); tap(p); tick(20)
local paid=tear(p); hit(taskTarget,paid); local nativeHits=#taskTarget.taken
tick(29); assert(#taskTarget.taken==nativeHits,"micromanagement pauses the countdown")
assert(hud():find("Micromanaged"))
-- Helpers, direct pulses and partner attacks cannot refresh the pause.
local helper=tear(p,false); helper:GetData().ccThoughtDerived=true; helper:GetData().ccLlamaHelper=true
hit(taskTarget,helper); hit(taskTarget,tear(q)); hit(taskTarget,p)
nativeHits=#taskTarget.taken; tick(40); assert(#taskTarget.taken==nativeHits,"resume keeps the old remaining delay")
tick(); assert(#taskTarget.taken==nativeHits+1); near(taskTarget.taken[#taskTarget.taken],p.Damage*0.6)
-- Repeated hits refresh to one second, never add another second.
hit(taskTarget,tear(p)); tick(15); frame=frame+1; hit(taskTarget,tear(p)); nativeHits=#taskTarget.taken
paused=true; tick(200); paused=false; fire("MC_POST_UPDATE"); tick(89)
assert(#taskTarget.taken==nativeHits); tick(); assert(#taskTarget.taken==nativeHits+1)
assert(state().budget[tostring(floor)..":"..tostring(room*13)]==3,"no additional budget charge")
taskTarget.friendly=true; tick(); assert(hud():find("Tasks 0/3"),"friendly assignees are released")
-- Pending tasks sample the owner's Birthright at each pulse, without rebooking.
players={player(501,511,0),player(502,522,1)}; p,q=players[1],players[2]
down={}; paused=false; p.birthright=false; q.birthright=true; q.Position=vec(400)
load(); fire("MC_POST_GAME_STARTED",false); enter(201,true)
local pTask,qTask=enemy(40),enemy(440)
tap(p); tap(q); tick(27) -- Owner p's task is 30 frames old; q's is 27.
p.birthright=true; q.birthright=false; tick(29)
assert(#pTask.taken==0 and #qTask.taken==0,"inventory changes do not trigger an early pulse")
tick(); near(pTask.taken[1],p.Damage*0.7)
tick(3); near(qTask.taken[1],q.Damage*0.6)
p.birthright=false; q.birthright=true; tick(56)
assert(#pTask.taken==1 and #qTask.taken==1,"inventory changes preserve the second pulse deadline")
tick(); near(pTask.taken[2],p.Damage*0.6)
tick(3); near(qTask.taken[2],q.Damage*0.7)
p.birthright=true; q.birthright=false; tick(56)
assert(#pTask.taken==2 and #qTask.taken==2,"reacquisition preserves the third pulse deadline")
tick(); near(pTask.taken[3],p.Damage*0.7)
tick(3); near(qTask.taken[3],q.Damage*0.6)
tick(60); assert(#pTask.taken==3 and #qTask.taken==3,"Birthright never restarts completed tasks")
local budgetKey=tostring(floor)..":"..tostring(room*13)
assert(state().budget[budgetKey]==3 and state(1).budget[budgetKey]==3,
    "pending Birthright changes do not recharge or refund either owner's budget")
print("OK: tainted Kimi task assignment, slots, pulses, room budget, early death, exit, Birthright, floor and save/identity lifecycle")
