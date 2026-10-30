-- Real Qwen adapters: DROP selection, per-room spending, clears and save/continue snapshots.
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
Direction={NO_DIRECTION=-1}
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
    GetPlayerTypeByName=function(name) return name=="Qwen-chan" and 54 or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=54,dead=false,
        Position=vec(0),Damage=10}
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:ToPlayer() return self end
    function p:GetFireDirection() return self.firing and 0 or Direction.NO_DIRECTION end
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
    include("scripts.characters.qwen_adapter"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.qwenAdapter[tostring(i or 0)] end
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

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
assert(state().adapters==1 and state().selected==1)
assert(hud()=="Qwen-chan: Adapters 1/2  Next Range  Active none",hud())

-- DROP cycles the next adapter without spending; holds keep native DROP.
tap(p); assert(state().selected==2 and state().adapters==1 and texts[#texts]=="Next adapter: Tempo")
down[0]=true; tick(20); down[0]=false; tick(); assert(state().selected==2,"a long hold does not cycle")
paused=true; down[0]=true; tick(); paused=false; down[0]=false; tick(); assert(state().selected==2,"pause cancels a tap")

-- Entering a new hostile room spends one adapter on the selection, for that room only.
enter(2,true); assert(state().adapters==0 and state().active==2)
stats(p,10,9,100); stats(q,10,9,100) -- Installation has no bonus yet.
assert(state().install==30 and state(1).install==30)
tick(20); p.firing=true; tick(); assert(state().install==30 and state(1).install==9,"firing restarts only the owner's install")
p.firing=false; paused=true; tick(50); paused=false; assert(state().install==30)
tick(29); fire("MC_POST_UPDATE"); stats(p,10,9,100); assert(state().install==1,"duplicates do not install")
tick(); stats(p,10,8,100); stats(q,10,9,160) -- Same original benefits after installation.
assert(hud()=="Qwen-chan: Adapters 0/2  Next Tempo  Active Tempo",hud())
tap(p); stats(p,10,8,100); assert(hud()=="Qwen-chan: Adapters 0/2  Next Power  Active Tempo","changing the next pick keeps the active one")
enter(3,true); stats(p,10,9,100); assert(state().active==nil,"no adapter means normal stats")

-- Two unique combat clears earn an adapter; re-entry and peaceful rooms do not.
finish(); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().clears==1)
enter(4,false); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().clears==1,"a peaceful room is not a clear")
enter(3,true); finish(); assert(state().clears==1 and state().adapters==0,"re-entering a seen room neither spends nor farms")
enter(5,true); finish(); assert(state().adapters==1 and state().clears==0)
enter(6,true); assert(state().active==3); tick(30); stats(p,11,9,100)
finish(); stats(p,11,9,100)
enter(5,true); stats(p,10,9,100)
assert(state().adapters==0,"re-entering an earlier room does not spend")
state().adapters=1; enter(6,true); clear=false; tick(); assert(state().adapters==1,"re-entering a seen hostile room does not spend")
clear=true; state().adapters=0

-- Range is +60; the cap is two, three with Birthright, and clamps when lost.
state().adapters=2; state().selected=1; state().clears=1
enter(7,true); tick(30); stats(p,10,9,160); finish(); assert(state().adapters==2)
state().adapters=2; state().clears=1; enter(8,true); state().adapters=2; finish(); assert(state().adapters==2,"two is the cap")
p.birthright=true; enter(9,true); state().adapters=2; state().clears=1; finish(); assert(state().adapters==3,"Birthright raises the cap to three")
p.birthright=false; tick(); assert(state().adapters==2,"losing Birthright clamps to two")

-- Continue keeps adapters, selection and the active room bonus.
state().selected=3; enter(10,true); tick(12); assert(state().install==18); stats(p,10,9,100)
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().install==17,"continue keeps primitive install progress"); tick(17)
stats(p,11,9,100); assert(state().active==3,"continue keeps the active adapter in its room")
assert(state().adapters==1,"continue does not spend again")

-- A new floor resets seen rooms and awards but keeps adapters.
floor=20; enter(2,true); assert(state().adapters==0 and state().active==3,"the same room seed on a new floor is new")
assert(next(state().awards)==nil)

-- Identity and character changes do not transfer adapters.
clear=true; players[1]=player(101,999,0); p=players[1]; tick(); assert(state().adapters==1 and state().active==nil)
p.kind=0; tick(); assert(state()==nil)
p.kind=54; tick(); assert(state().adapters==1)
Risk.state.qwenAdapter["0"]={version=1,adapters=1,clears=0,selected=1,awards={},seen={},active=2}
tick(); assert(state().active==nil,"an active adapter without its room is corrupt")

-- Version-one saves keep their already granted room bonus, with no new spend.
Risk.state.qwenAdapter["0"]={version=1,adapters=2,clears=1,selected=2,awards={},seen={},active=3,activeRoom=tostring(floor)..":"..tostring(room*13)}
clear=true; tick(); assert(state().version==2 and state().install==0 and state().adapters==2); stats(p,11,9,100)
state().adapters=1; enter(40,true); tick(8); enter(41,false)
assert(state().active==nil and state().install==0 and state().adapters==0,"exit discards spent installation")
fire("MC_POST_GAME_STARTED",false); assert(state().adapters==1 and state().selected==1)
print("OK: Qwen adapter selection, per-room spending, clear rewards, Birthright cap and save/floor/identity lifecycle")
