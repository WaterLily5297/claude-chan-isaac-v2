-- Real GLM Queue: unique clears, Access Pass redemption, new-room spending and save/continue snapshots.
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
CacheFlag={CACHE_DAMAGE=1,CACHE_SPEED=2,CACHE_FIREDELAY=4,CACHE_RANGE=8}
EntityType={ENTITY_PLAYER=1,ENTITY_TEAR=2,ENTITY_BOMB=4,ENTITY_LASER=7,ENTITY_KNIFE=8,ENTITY_EFFECT=1000}
EffectVariant={PLAYER_CREEP_BLACK=45}
function Vector(x,y) return {X=x,Y=y} end
function Color(r,g,b,a) return {R=r,G=g,B=b,A=a} end
local peels={}
EntityPartition={ENEMY=8,BULLET=2}
local bullets={}
EntityFlag={FLAG_FRIENDLY=1}
ButtonAction={ACTION_DROP=11}
local down={}
Input={IsActionPressed=function(_,controller) return down[controller] or false end}
function GetPtrHash(e) return e.pointer end
function EntityPtr(e) return {Ref=e} end
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
    GetPlayerTypeByName=function(name) return name=="GLM-chan" and 59 or -1 end,
    Spawn=function(kind,variant,_,pos,_,owner)
        local e={Type=kind,Variant=variant,Position=pos,SpawnerEntity=owner,removed=false}
        function e:ToEffect() return self end
        function e:SetTimeout(t) self.timeout=t end
        function e:Exists() return not self.removed end
        function e:Remove() self.removed=true end
        peels[#peels+1]=e
        return e
    end,
    FindInRadius=function(pos,radius,partition)
        local found={}
        for _,e in ipairs(partition==EntityPartition.BULLET and bullets or enemies) do if math.abs(e.Position.x-pos.x)<=radius+10 then found[#found+1]=e end end
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=59,dead=false,
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
    function p:EvaluateItems() self.Damage=10; self.MaxFireDelay=9; self.TearRange=100
        for _,f in pairs(CacheFlag) do fire("MC_EVALUATE_CACHE",self,f) end end
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
    function e:IsEnemy() return true end
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
    include("scripts.characters.glm_queue"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.glmQueue[tostring(i or 0)] end
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
local function stats(p,d,f,r) p:EvaluateItems(); near(p.Damage,d); near(p.MaxFireDelay,f); near(p.TearRange,r) end

local function hud() draws={}; fire("MC_POST_RENDER"); return draws[1] end
local function dmg(p,d) p:EvaluateItems(); near(p.Damage,d) end

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
assert(state().queue==0 and state().pass==0)
assert(hud()=="GLM-chan: Number in queue 0/3",hud())

-- Unique combat clears advance the Queue to three; re-entry and peaceful rooms do not.
enter(2,true); finish(); assert(state().queue==1)
fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().queue==1,"duplicate awards are ignored")
enter(3,false); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().queue==1,"a peaceful room is not a clear")
enter(2,true); finish(); assert(state().queue==1,"re-clearing a room does not advance")
tap(p); assert(state().pass==0 and state().queue==1,"DROP below three does nothing")
for r=4,6 do enter(r,true); finish() end
assert(state().queue==3,"the Queue stops at three")
assert(state(1).queue==3,"each player queues separately")
assert(hud()=="GLM-chan: Ticket ready! Tap DROP before next fight",hud())

-- A ready ticket survives safe rooms and revisits, but not another new fight.
enter(3,false); assert(state().queue==3); enter(2,true); assert(state().queue==3)
enter(70,true); assert(state().queue==2 and state().pass==0,"missing the call loses exactly one Queue step")
fire("MC_POST_UPDATE"); enter(70,true); assert(state().queue==2,"duplicate/revisit cannot lose another step")
finish(); assert(state().queue==3,"clear progress still earns the next call")
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().queue==3,"continue in the seen room keeps the ticket")

-- A long hold or pause keeps native DROP; a tap redeems the Access Pass.
down[0]=true; tick(20); down[0]=false; tick(); assert(state().queue==3,"a long hold keeps native DROP")
paused=true; down[0]=true; tick(); paused=false; down[0]=false; tick(); assert(state().queue==3,"pause cancels a tap")
tap(p); assert(state().queue==0 and state().pass==2 and texts[#texts]=="Access granted")
assert(hud()=="GLM-chan: Access 2 room(s)",hud())
dmg(p,10)

-- The pass spends on new hostile rooms only; the bonus belongs to that room.
enter(4,true); assert(state().pass==2,"revisiting a seen hostile room does not spend"); dmg(p,10)
enter(7,false); assert(state().pass==2,"a peaceful room does not spend")
enter(8,true); assert(state().pass==1 and state().activeRoom); dmg(p,12); dmg(q,10)
assert(hud()=="GLM-chan: Access active  1 room(s) left",hud())
finish(); assert(state().queue==0,"the Queue pauses while the pass boosts this room"); dmg(p,12)
enter(9,false); dmg(p,10)
enter(8,true); dmg(p,10); assert(state().pass==1,"returning to a boosted room neither boosts nor spends")
enter(10,true); assert(state().pass==0); dmg(p,12)
finish(); assert(state().queue==0,"the last pass room still pauses the Queue")
enter(11,true); dmg(p,10); finish(); assert(state().queue==1,"the Queue resumes after the pass")

-- Clears while unused pass rooms remain do not advance the Queue, and passes never stack.
state().queue=3; tap(q); assert(state(1).pass==2)
state(1).queue=3; enter(12,true); finish()
assert(state(1).queue==3 and state(1).pass==1); tap(q); assert(state(1).pass==1 and state(1).queue==3,"no stacking")

-- Redeeming mid-fight in a seen room boosts nothing, and that clear does not queue.
enter(14,true); state().queue=3; state().pass=0; state().activeRoom=nil; tap(p); assert(state().pass==2)
dmg(p,10); finish(); assert(state().queue==0,"unused pass rooms pause the Queue")
-- A paused update neither spends a pass room nor ages anything; dead players earn nothing.
paused=true; room=15; clear=false; enemies={}; fire("MC_POST_NEW_ROOM"); tick(); assert(state().pass==2)
paused=false; tick(); assert(state().pass==1); clear=true
state().pass=0; enter(16,true); p.dead=true; finish(); assert(state().queue==0,"a dead GLM earns no Queue"); p.dead=false
state().activeRoom=nil
-- Birthright gives three rooms.
p.birthright=true; state().queue=3; tap(p); assert(state().pass==3); p.birthright=false

-- Continue keeps the Queue, the pass and the boosted room.
enter(13,true); assert(state().pass==2); dmg(p,12)
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
dmg(p,12); assert(state().pass==2,"continue does not spend again")
room=99; dmg(p,10); room=13; dmg(p,12) -- the bonus is tied to its room even before room callbacks run

-- A new floor resets seen rooms and awards but keeps the pass.
floor=20; enter(2,true); assert(state().pass==1,"the same room seed on a new floor is new")
assert(next(state().awards)==nil)

-- Identity and character changes do not transfer the pass.
clear=true; players[1]=player(101,999,0); p=players[1]; tick(); assert(state().pass==0 and state().queue==0)
state().queue=2
p.kind=0; tick(); assert(state()==nil)
p.kind=59; tick(); assert(state().queue==0)
Risk.state.glmQueue["0"]={version=1,queue=4,pass=0,awards={},seen={}}
tick(); assert(state().queue==0,"an impossible Queue is corrupt")

fire("MC_POST_GAME_STARTED",false); assert(state().queue==0 and state().pass==0)
print("OK: GLM Queue clears, Access Pass redemption, new-room boosts, pause, Birthright and save/floor/identity lifecycle")
