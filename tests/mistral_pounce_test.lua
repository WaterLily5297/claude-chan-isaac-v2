-- Real Mistral Pounce: charge, idle loss, forward swipe, walls, cooldown and save/continue snapshots.
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
local function vec(x,y) return setmetatable({X=x,Y=y or 0,x=x},V) end
V.__sub=function(a,b) return vec(a.X-b.X,a.Y-b.Y) end
function V:LengthSquared() return self.X*self.X+self.Y*self.Y end
function V:Length() return math.sqrt(self:LengthSquared()) end
function V:Normalized() local l=self:Length(); return vec(self.X/l,self.Y/l) end
function V:Distance(o) return (self-o):Length() end
function Vector(x,y) return vec(x,y) end
function EntityRef(e) return {Entity=e} end
local walls={}
function Game() return {
    GetFrameCount=function() return frame end, GetNumPlayers=function() return #players end,
    IsPaused=function() return paused end,
    GetRoom=function() return {IsClear=function() return clear end,
        CheckLine=function(_,a,b) for _,w in ipairs(walls) do if (a.X<w and b.X>w) or (a.X>w and b.X<w) then return false end end; return true end} end,
    GetLevel=function() return {
        GetDungeonPlacementSeed=function() return floor end,
        GetStage=function() return 1 end,GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=room*13} end,
    } end,
    GetHUD=function() return {IsVisible=function() return true end,
        ShowItemText=function(_,_,text) texts[#texts+1]=text end} end,
} end
Isaac={GetPlayer=function(i) return players[i+1] end,GetScreenHeight=function() return 270 end,GetScreenWidth=function() return 480 end,
    GetPlayerTypeByName=function(name) return name=="Mistral-chan" and 56 or -1 end,
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
        for _,e in ipairs(partition==EntityPartition.BULLET and bullets or enemies) do if e.Position:Distance(pos)<=radius+10 then found[#found+1]=e end end
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=56,dead=false,
        Position=vec(0),Damage=10,Velocity=vec(0),aim=vec(0)}
    function p:GetShootingInput() return self.aim end
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return true end
    function p:HasCollectible(id) return id==619 and self.birthright end
    function p:AddCacheFlags() end
    function p:EvaluateItems() self.MoveSpeed=1; fire("MC_EVALUATE_CACHE",self,CacheFlag.CACHE_SPEED) end
    return p
end
local nextEnemy=1000
local function enemy(x,y)
    nextEnemy=nextEnemy+1
    local e={pointer=nextEnemy,Position=vec(x,y),Size=10,dead=false,friendly=false,removed=false}
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
    include("scripts.characters.mistral_pounce"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.mistralPounce[tostring(i or 0)] end
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
local function run(p,n,firingDir) p.Velocity=vec(3,0); p.aim=firingDir or vec(1,0); tick(n) end
local function stand(p,n) p.Velocity=vec(0,0); p.aim=vec(0,0); tick(n) end

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
near(p.MoveSpeed,1.1); assert(not state().ready)

-- Two seconds of moving while firing charges one Pounce; stopping resets the charge.
run(p,59); assert(not state().ready and hud()=="Mistral-chan: Charge 98%",hud())
p.aim=vec(0,0); tick(); assert(hud()=="Mistral-chan: Charge 0%","moving without firing resets")
run(p,60); assert(state().ready and state().dirX==1 and state().dirY==0)
assert(hud()=="Mistral-chan: Pounce Ready Right")
assert(not state(1).ready,"charge is personal")

-- Standing for one second loses an unused Pounce; pause does not count.
stand(p,29); assert(state().ready)
paused=true; tick(60); paused=false; assert(state().ready,"pause does not count as standing")
fire("MC_POST_UPDATE"); assert(state().ready,"a duplicate update does not count")
tick(); assert(not state().ready and texts[#texts]=="Pounce lost")

-- DROP swipes forward: 2x damage once per target in the line, walls stop it.
run(p,60); assert(state().ready)
local ahead,behind,side,far,walled=enemy(50),enemy(-50),enemy(40,60),enemy(130),enemy(70,5)
walls={60}
p.aim=vec(-1,0); down[0]=false; tick(); down[0]=true; tick(); down[0]=false; tick()
assert(#ahead.taken==1 and ahead.taken[1]==20,"2x owner damage to a target ahead")
assert(#behind.taken==0 and #side.taken==0 and #far.taken==0 and #walled.taken==0,"only the forward line, within reach, without walls")
assert(not state().ready and texts[#texts]=="Pounce!")
assert(hud()=="Mistral-chan: Cooldown 3s",hud())

-- Cooldown blocks charging for three seconds.
walls={}
run(p,89); assert(hud()=="Mistral-chan: Cooldown 1s" and not state().ready,hud())
run(p,59); assert(not state().ready)
tick(); assert(state().ready,"charging resumes after the cooldown")

-- Birthright reaches 110 units; holding DROP keeps native DROP.
p.birthright=true; local reach=enemy(105)
down[0]=true; tick(20); down[0]=false; tick(); assert(state().ready and #reach.taken==0,"a long hold does not pounce")
p.aim=vec(1,0); down[0]=true; tick(); down[0]=false; tick()
assert(#reach.taken==1,"Birthright extends the reach"); p.birthright=false

-- The ready Pounce survives continue; charge and cooldown are transient.
run(p,200); assert(state().ready)
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().ready and state().dirX==1 and state().dirY==0 and hud()=="Mistral-chan: Pounce Ready Right")

-- Identity and character changes do not transfer it.
players[1]=player(101,999,0); p=players[1]; tick(); assert(not state().ready)
state().ready=true; p.kind=0; tick(); assert(state()==nil); p:EvaluateItems(); near(p.MoveSpeed,1)
p.kind=56; tick(); assert(not state().ready)
Risk.state.mistralPounce["0"]={version=1,ready="yes"}; tick(); assert(state().ready==false,"corrupt saves are discarded")

fire("MC_POST_GAME_STARTED",false); assert(not state().ready)
-- A full charge in a different movement direction replaces the stored direction.
p.Velocity=vec(0,-3); p.aim=vec(1,0); tick(59); assert(not state().ready)
tick(); assert(state().ready and state().dirY==-1 and state().dirX==0)
p.Velocity=vec(-3,0); tick(59); assert(state().dirY==-1,"turning is not immediate")
paused=true; tick(100); paused=false; fire("MC_POST_UPDATE"); assert(state().dirY==-1)
tick(); assert(state().dirX==-1 and state().dirY==0 and hud():find("Left"))
reload({player(201,11,0),player(202,22,1)}); p,q=players[1],players[2]
assert(state().dirX==-1 and state().ready,"direction persists without serializing a vector")
Risk.state.mistralPounce["0"]={version=1,ready=true}; tick()
assert(state().version==2 and state().ready and state().dirX==0 and state().dirY==1,"legacy ready charge migrates with visible Down direction")

-- Initial charging retains the old freedom to turn. A replacement must keep
-- its course; gradual turns cannot accumulate a charge across every direction.
fire("MC_POST_GAME_STARTED",false)
p.aim=vec(1,0); p.Velocity=vec(3,0); tick(30)
p.Velocity=vec(0,-3); tick(30)
assert(state().ready and state().dirY==-1,"turning does not penalize the initial charge")
for i=1,90 do
    local angle=math.rad(i*3)
    p.Velocity=vec(3*math.cos(angle),3*math.sin(angle)); tick()
end
assert(state().dirX==0 and state().dirY==-1,"a drifting course cannot replace the stored direction")
p.Velocity=vec(3,0); tick(59); assert(state().dirY==-1)
tick(); assert(state().dirX==1 and state().dirY==0,"a full steady replacement charge still succeeds")
print("OK: Mistral Pounce charge, idle loss, forward swipe, walls, cooldown, Birthright reach and save/identity lifecycle")
