-- Real tainted GLM Please Retry: requests, Retry stacks, cooldown and save/continue snapshots.
local root=arg[1]
local frame, paused, clear, room, floor = 0, false, true, 1, 10
local lineOfSight=true
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
function EntityRef(e) return {Entity=e} end
local function vec(x) return {x=x, Distance=function(self,o) return math.abs(self.x-o.x) end} end
function Game() return {
    GetFrameCount=function() return frame end, GetNumPlayers=function() return #players end,
    IsPaused=function() return paused end,
    GetRoom=function() return {IsClear=function() return clear end, CheckLine=function() return lineOfSight end} end,
    GetLevel=function() return {
        GetDungeonPlacementSeed=function() return floor end,
        GetStage=function() return 1 end,GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=room*13} end,
    } end,
    GetHUD=function() return {IsVisible=function() return true end,
        ShowItemText=function(_,_,text) texts[#texts+1]=text end} end,
} end
Isaac={GetPlayer=function(i) return players[i+1] end,GetScreenHeight=function() return 270 end,GetScreenWidth=function() return 480 end,
    GetPlayerTypeByName=function(name,tainted) return name=="GLM-chan" and (tainted and 159 or 59) or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=159,dead=false,
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
    include("scripts.characters.glm_retry"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.glmRetry[tostring(i or 0)] end
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
local function bullet(x)
    local b={Position=vec(x),removed=false}
    function b:ToProjectile() return self end
    function b:Exists() return not self.removed end
    function b:Remove() self.removed=true end
    bullets[#bullets+1]=b
    return b
end
local function last() return texts[#texts] end
players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
p:EvaluateItems(); near(p.Damage,9); assert(hud()=="GLM-chan: Retries 0/3",hud())

-- No requests outside combat; no target means no cooldown.
local idle=enemy(40); tap(p); assert(not texts[1])
enter(2,true); local far=enemy(250); tap(p); assert(not texts[1] and hud()=="DROP: No target in range")

-- DROP queues a two-second request; a surviving target takes 2x.
local e=enemy(50); tap(p); assert(last()=="Request queued" and hud()=="GLM-chan: Retries 0/3  Request Pending 2s",hud())
paused=true; tick(30); paused=false; fire("MC_POST_UPDATE"); fire("MC_POST_UPDATE")
tick(59); assert(#e.taken==0); tick(); assert(#e.taken==1 and last()=="Request complete"); near(e.taken[1],18)
assert(#far.taken==0)
-- The three-second cooldown starts at selection and blocks DROP.
assert(hud()=="GLM-chan: Retries 0/3  Cooldown 1s",hud())
local shown=#texts; tap(p); assert(#texts==shown,"cooldown")
tick(26); assert(hud()=="DROP: Request cooling down"); tick()
tick(18); assert(hud()=="GLM-chan: Retries 0/3","request HUD returns after refusal")

-- Early death earns a Retry, up to three; another player's state is separate.
for i=1,4 do
    tap(p); e.dead=true; tick(); e.dead=false
    assert(state().retries==math.min(i,3) and last()=="Please retry" and not hud():find("Pending"))
    tick(90)
end
assert(state(1).retries==0)
-- A successful request consumes all Retries: 2x + 3x = 5x.
tap(p); tick(60); near(e.taken[#e.taken],45); assert(state().retries==0)
tick(30)

-- Leaving cancels a request without a Retry.
tap(p); enter(3,true); tick(90); assert(state().retries==0 and #e.taken==2,"exit cancels")
assert(hud()=="GLM-chan: Retries 0/3","no request after exit")

-- Birthright: a failed request removes the nearest enemy bullet once.
local t=enemy(60); local b1,b2,b3=bullet(30),bullet(60),bullet(500)
tap(p); t.dead=true; tick(); t.dead=false; assert(not b1.removed,"only Birthright clears bullets")
tick(90); p.birthright=true; tap(p); t.dead=true; tick(); t.dead=false
assert(b1.removed and not b2.removed and not b3.removed); p.birthright=false
tick(90); bullets={}; local b4=bullet(130); p.birthright=true; tap(p); t.removed=true; tick(); t.removed=false
assert(state().retries==3 and not b4.removed,"bullets beyond reach stay"); p.birthright=false
tick(90)

-- A dead GLM's request waits.
tap(p); p.dead=true; tick(90); p.dead=false; tick(59); assert(#t.taken==0); tick(); assert(#t.taken==1)
assert(state().retries==0); near(t.taken[1],45)

-- Continue keeps Retries, not the request.
state().retries=2; tick(30); tap(p)
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().retries==2 and hud()=="GLM-chan: Retries 2/3"); p:EvaluateItems(); near(p.Damage,9)
tick(90); assert(#t.taken==1,"requests do not survive a continue")

-- Identity and character changes do not transfer progress; corrupt data resets.
players[1]=player(101,999,0); p=players[1]; tick(); assert(state().retries==0)
p.kind=0; tick(); assert(state()==nil); p:EvaluateItems(); near(p.Damage,10)
p.kind=159; tick()
for _,bad in ipairs({{version=1,retries=4},{version=1,retries=-1},{version=1,retries=1.5},{version=1},{version=2,retries=1}}) do
    Risk.state.glmRetry["0"]=bad; tick(); assert(state().retries==0 and state().version==1)
end
Risk.state.glmRetry["0"]={version=1,retries=3}; tick(); assert(state().retries==3,"valid data is kept")
-- Stay connected: failed distance/visibility does not consume or award stored Retries.
fire("MC_POST_GAME_STARTED",false); enter(100,true); local remote=enemy(100)
state().retries=2; p.birthright=true; local safeBullet=bullet(10); tap(p)
p.Position=vec(-101); tick(60)
assert(#remote.taken==0 and state().retries==2 and last()=="Connection lost: request timed out")
assert(not safeBullet.removed and state(1).retries==0,"timeouts are not early-target-death rewards")
assert(hud():find("Cooldown"),hud()); fire("MC_POST_UPDATE")
p.Position=vec(0); tick(30); lineOfSight=false; tap(p)
assert(hud():find("Restore connection"),hud()); tick(60)
assert(#remote.taken==0 and state().retries==2,"blocked completion cannot hit through the wall")
lineOfSight=true; tick(30); tap(p); p.Position=vec(-100); tick(60)
assert(#remote.taken==1 and state().retries==0,"200 units is inclusive")
near(remote.taken[1],36)
tick(30); tap(p); remote.friendly=true; tick()
assert(state().retries==0 and #remote.taken==1 and not hud():find("Pending"),"friendly targets cancel without reward")
print("OK: tainted GLM requests, cooldown, Retry stacks, exit cancel, Birthright bullet, dead owner and save/identity lifecycle")
