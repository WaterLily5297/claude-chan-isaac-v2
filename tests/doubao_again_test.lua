-- Real tainted Doubao I'll Do It Again: Confident/Apology cycle, hit rules and save/continue snapshots.
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
CacheFlag={CACHE_DAMAGE=1,CACHE_SPEED=2}
EntityType={ENTITY_PROJECTILE=9,ENTITY_SLOT=6,ENTITY_PLAYER=1,ENTITY_TEAR=2,ENTITY_BOMB=4,ENTITY_LASER=7,ENTITY_KNIFE=8,ENTITY_EFFECT=1000}
EffectVariant={PLAYER_CREEP_BLACK=45}
function Vector(x,y) return {X=x,Y=y} end
function Color(r,g,b,a) return {R=r,G=g,B=b,A=a} end
local peels={}
EntityPartition={ENEMY=8,BULLET=2}
local bullets={}
EntityFlag={FLAG_FRIENDLY=1}
ButtonAction={ACTION_DROP=11}
DamageFlag={DAMAGE_FAKE=8,DAMAGE_NO_PENALTIES=268435456}
function EntityRef(e) return {Entity=e} end
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
    GetPlayerTypeByName=function(name,tainted) return name=="Doubao-chan" and (tainted and 157 or 57) or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=157,dead=false,
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
    function e:IsEnemy() return true end
    e.Type=10
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
    include("scripts.characters.doubao_again"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.doubaoAgain[tostring(i or 0)] end
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


local function bullet(x)
    local b={Position=vec(x),removed=false,Type=EntityType.ENTITY_PROJECTILE}
    function b:ToProjectile() return self end
    function b:Exists() return not self.removed end
    function b:Remove() self.removed=true end
    function b:IsEnemy() return false end
    bullets[#bullets+1]=b
    return b
end
local function hud() draws={}; fire("MC_POST_RENDER"); return draws[1] end
local function hurt(p,source,flags) fire("MC_ENTITY_TAKE_DMG",p,1,flags or 0,{Entity=source}) end

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
near(p.Damage,10); assert(hud()=="Doubao-chan: Ready to promise",hud())

-- DROP starts Confident at 1.35x; timers wait outside hostile combat.
tap(p); assert(state().phase=="confident" and texts[#texts]=="Leave it to me!"); near(p.Damage,13.5)
tick(90); assert(state().remaining==180,"no countdown in a cleared room")
tap(p); assert(state().remaining==180,"one promise at a time")
enter(2,true); assert(state().remaining==179)
paused=true; tick(30); paused=false; fire("MC_POST_UPDATE"); fire("MC_POST_UPDATE")
assert(state().remaining==179 and hud()=="Doubao-chan: Confident 6s  Clear -> Apology",hud())
tick(178); assert(state().phase=="confident" and state().remaining==1)
-- Then four seconds of Apology at 0.85x, then ready.
tick(); assert(state().phase=="apology" and state().remaining==120 and texts[#texts]=="Sorry, you're right"); near(p.Damage,8.5)
tap(p); assert(state().phase=="apology","no new promise during the Apology")
clear=true; tick(60); assert(state().remaining==117); clear=false
tick(116); assert(state().phase=="apology"); tick(); assert(state().phase==nil and texts[#texts]=="I'll do it again"); near(p.Damage,10)
assert(state(1).phase==nil,"each player promises separately")

-- An enemy hit during Confident starts the Apology early; other damage does not.
tap(p); local e=enemy(50); local shot=bullet(30)
hurt(p,e,DamageFlag.DAMAGE_FAKE); hurt(p,e,DamageFlag.DAMAGE_NO_PENALTIES); assert(state().phase=="confident","fake or penalty-free damage")
local machine={Type=EntityType.ENTITY_SLOT}; function machine:IsEnemy() return false end; function machine:HasEntityFlags() return false end
hurt(p,machine); hurt(p,nil); e.friendly=true; hurt(p,e); e.friendly=false
assert(state().phase=="confident","machines, unknown sources and friendly enemies do not count")
hurt(q,e); assert(state().phase=="confident" and state(1).phase==nil,"another player's hit does not count")
hurt(p,shot); assert(state().phase=="apology" and state().remaining==120); near(p.Damage,8.5)
hurt(p,e); assert(state().remaining==120,"hits during the Apology change nothing")
tick(120); assert(state().phase==nil)
tap(p); hurt(p,e); assert(state().phase=="apology","enemy contact counts")

-- Birthright shortens the Apology to three seconds.
tick(120); p.birthright=true; tap(p); tick(180); assert(state().remaining==90)
tick(89); assert(state().phase=="apology"); tick(); assert(state().phase==nil); p.birthright=false

-- A dead Doubao's timers stop.
tap(p); p.dead=true; tick(60); p.dead=false; tick(); assert(state().remaining==179)

-- Continue keeps the phase and its timer; damage is recomputed.
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().phase=="confident" and state().remaining==178); near(p.Damage,13.5)

-- Identity and character changes do not transfer progress; corrupt data resets.
players[1]=player(101,999,0); p=players[1]; tick(); assert(state().phase==nil)
p.kind=0; tick(); assert(state()==nil); p:EvaluateItems(); near(p.Damage,10)
p.kind=157; tick(); clear=true
for _,bad in ipairs({{version=1,phase="confident",remaining=181},{version=1,phase="apology",remaining=121},
    {version=1,phase="apology",remaining=0},{version=1,phase="smug",remaining=10},{version=1,phase="apology",remaining=1.5},
    {version=1,remaining=5},{version=2}}) do
    Risk.state.doubaoAgain["0"]=bad; tick(); assert(state().phase==nil and state().remaining==nil and state().version==1)
end
clear=false; Risk.state.doubaoAgain["0"]={version=1,phase="apology",remaining=120}; tick(); assert(state().remaining==119,"valid data is kept")
state().phase="confident"; fire("MC_POST_GAME_STARTED",false); assert(state().phase==nil,"a new run starts ready")
-- Promise fulfilled: only an armed hostile clear ends Confident, once.
clear=true; tap(p); fire("MC_PRE_SPAWN_CLEAN_AWARD")
assert(state().phase=="confident","peaceful callbacks do not end a promise")
enter(100,true); finish()
assert(state().phase=="apology" and state().remaining==120,"clear begins the normal recovery")
near(p.Damage,8.5); assert(state(1).phase==nil,"clearing does not start a partner's phase")
state().remaining=100; fire("MC_PRE_SPAWN_CLEAN_AWARD"); tick(90)
assert(state().remaining==100,"duplicates and safe-room time do not restart or pay recovery")
enter(101,true); assert(state().remaining==99); finish(); assert(state().remaining==99,"Apology clear does not restart it")
reload({player(201,999,0),player(202,22,1)}); p,q=players[1],players[2]
assert(state().phase=="apology" and state().remaining==99,"continue retains the carried recovery")
clear=false; tick(99); p.birthright=true; tap(p); finish()
assert(state().phase=="apology" and state().remaining==90,"Birthright keeps its original recovery time")
print("OK: tainted Doubao Confident/Apology cycle, combat-only timers, early apology, Birthright and save/identity lifecycle")
