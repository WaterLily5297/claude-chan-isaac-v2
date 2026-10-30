-- Real tainted Llama Still Waiting: Hype clears, helper tears, expiry and save/continue snapshots.
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
local V={}
V.__index=V
local function vec(x) return setmetatable({x=x},V) end
function V:Distance(o) return math.abs(self.x-o.x) end
function V.__sub(a,b) return vec(a.x-b.x) end
function V.__mul(a,k) return vec(a.x*k) end
function V:Normalized() return vec(self.x==0 and 0 or self.x/math.abs(self.x)) end
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
    GetPlayerTypeByName=function(name,tainted) return name=="Llama-chan" and (tainted and 155 or 55) or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=155,dead=false,
        Position=vec(0),Damage=10,ShotSpeed=1,fired={}}
    function p:FireTear(pos,velocity,_,_,_,source,mult)
        local data={}
        local t={pos=pos,velocity=velocity,source=source,mult=mult}
        function t:GetData() return data end
        self.fired[#self.fired+1]=t
        return t
    end
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return true end
    function p:HasCollectible(id) return id==619 and self.birthright end
    function p:AddCacheFlags() end
    function p:EvaluateItems() self.Damage=10
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
    -- This lifecycle suite stubs the injected service; the real callback and
    -- billing contract is exercised by llama_helper_billing_test.lua.
    local backlog={FireDerived=function(p,velocity,mult,position)
        return p:FireTear(position,velocity,false,true,false,p,mult)
    end}
    include("scripts.characters.llama_hype"):Init(mod,Risk,backlog)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.llamaHype[tostring(i or 0)] end
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
assert(hud()=="Llama-chan: Hype 0/3",hud())
p:EvaluateItems(); near(p.Damage,9)

-- No Hype, no helper; native DROP stays untouched.
tap(p); assert(not texts[1])

-- Unique combat clears earn Hype up to three.
enter(2,true); finish(); assert(state().hype==1 and state(1).hype==1)
fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().hype==1,"one award per clear")
enter(2,true); finish(); assert(state().hype==1,"re-clearing a room does not count")
enter(3,false); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().hype==1,"a peaceful room is not a clear")
enter(4,true); p.dead=true; finish(); p.dead=false; assert(state().hype==1 and state(1).hype==2,"a dead Llama earns nothing")
enter(5,true); finish(); enter(6,true); finish(); enter(7,true); finish()
assert(state().hype==3 and hud()=="Llama-chan: Hype 3/3","Hype caps at three")

-- DROP spends all Hype on a helper lasting four seconds per Hype.
enter(8,true); local e=enemy(100); local far=enemy(300)
tap(p); assert(state().hype==0 and texts[#texts]=="Still waiting...")
assert(hud()=="Llama-chan: Hype 0/3  Helper 12s",hud())
tap(p); assert(#texts==1,"no Hype, no new helper")
-- One weak tear per second at the nearest enemy, fired from where the helper stands.
p.Position=vec(-120)
tick(26); assert(#p.fired==0)
tick(); local t=p.fired[1]
assert(#p.fired==1 and t.mult==0.5 and t.pos.x==0 and t.velocity.x==10 and t.source==p and t:GetData().ccLlamaHelper)
p.ShotSpeed=1.5; e.Position=vec(-50)
tick(30); assert(#p.fired==2 and p.fired[2].velocity.x==-15,"aims at the nearest enemy")
e.dead=true; tick(30); assert(#p.fired==3 and p.fired[3].velocity.x==15,"the next nearest within 400")
far.Position=vec(500); tick(30); assert(#p.fired==3,"no target, no tear")
far.Position=vec(300)
-- A paused frame and a duplicate update do not age the helper.
paused=true; tick(10); paused=false
fire("MC_POST_UPDATE"); fire("MC_POST_UPDATE")
tick(239); assert(hud():find("Helper 1s"),hud()); assert(#p.fired==10)
tick(); assert(#p.fired==11 and not hud():find("Helper"),"the helper expires after twelve seconds")
tick(60); assert(#p.fired==11,"no tears after expiry")
local helperBefore=#p.fired

-- Birthright makes each Hype five seconds; room exit removes the helper.
state().hype=2; p.birthright=true; tap(p); p.birthright=false
assert(hud()=="Llama-chan: Hype 0/3  Helper 10s",hud())
state().hype=1; tap(p); assert(hud()=="Llama-chan: Hype 0/3  Helper 4s","spending again replaces the helper")
enter(9,true); assert(not hud():find("Helper"),"leaving the room removes the helper")
tick(60); assert(#p.fired==helperBefore)

-- Continue keeps Hype and clears; a new floor clears the room list only.
state().hype=2
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().hype==2 and state().cleared["10:"..(2*13)]); near(p.Damage,9)
enter(2,true); finish(); assert(state().hype==2,"continue keeps unique clears")
floor=20; enter(2,true); assert(next(state().cleared)==nil,"a new floor forgets old rooms")
finish(); assert(state().hype==3,"the same room seed on a new floor is new")
p.dead=true; tap(p); assert(state().hype==3 and not hud():find("Helper"),"a dead Llama cannot spend"); p.dead=false
tap(p); p.dead=true; tick(90); p.dead=false; assert(hud():find("Helper 12s"),"the helper waits while its owner is dead")

-- Identity and character changes do not transfer progress; corrupt data resets.
clear=true; players[1]=player(101,999,0); p=players[1]; tick(); assert(state().hype==0)
p.kind=0; tick(); assert(state()==nil); p:EvaluateItems(); near(p.Damage,10)
p.kind=155; tick(); Risk.state.llamaHype["0"]={version=1,hype=4,cleared={}}; tick(); assert(state().hype==0)
Risk.state.llamaHype["0"]={version=1,hype=1.5,cleared={}}; tick(); assert(state().hype==0)
Risk.state.llamaHype["0"]={version=1,hype=1,cleared={x=1}}; tick(); assert(state().hype==0 and next(state().cleared)==nil)
state().hype=2; fire("MC_POST_GAME_STARTED",false); assert(state().hype==0,"a new run starts empty")
-- Stay near the demo: range is inclusive, lifetime/cadence never accumulate catch-up shots.
fire("MC_POST_GAME_STARTED",false); enter(100,true); enemy(100)
p.Position=vec(0); q.Position=vec(0); state().hype=1; tap(p)
local firedBefore=#p.fired
p.Position=vec(121); tick(30)
assert(#p.fired==firedBefore and hud():find("Return to demo"),"a nearby partner cannot enable the owner's demo")
paused=true; tick(100); paused=false; fire("MC_POST_UPDATE")
p.Position=vec(120); tick(29); assert(#p.fired==firedBefore,"no immediate catch-up on return")
tick(); assert(#p.fired==firedBefore+1,"the 120-unit boundary retains the original shot")
p.Position=vec(121); tick(60); p.Position=vec(0); tick(30)
assert(#p.fired==firedBefore+1 and not hud():find("Helper"),"out-of-range time still expires the helper")
-- A deployed helper keeps the duration bought with Hype when Birthright changes.
for _,initial in ipairs({false,true}) do
    players={player(501,511,0),player(502,522,1)}; p,q=players[1],players[2]
    down={}; paused=false; p.birthright=initial; q.birthright=not initial
    load(); fire("MC_POST_GAME_STARTED",false); enter(201,true); enemy(40)
    state().hype=1; state(1).hype=2; tap(p)
    local duration=initial and 150 or 120
    tick(30); p.birthright=not initial; tick(30)
    p.birthright=initial; tick(30); p.birthright=not initial
    tick(duration-91)
    assert(hud():find("Helper 1s"),
        "pending helper keeps its bought duration through Birthright gain/loss/reacquisition")
    fire("MC_POST_UPDATE"); assert(hud():find("Helper 1s"),"duplicate update keeps the last helper frame")
    tick(); assert(not hud():find("Helper"),"pending helper expires at its original deadline")
    assert(state().hype==0 and state(1).hype==2,"inventory changes neither refund Hype nor spend a partner's Hype")
    state().hype=1; tap(p)
    assert(hud():find(initial and "Helper 4s" or "Helper 5s"),
        "a later deployment samples the owner's current Birthright")
end
print("OK: tainted Llama Hype clears, helper duration, aiming, expiry, room exit, Birthright, floor and save/identity lifecycle")
