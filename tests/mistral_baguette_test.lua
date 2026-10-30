-- Real tainted Mistral Le Gros Chaton: baking, slow shockwave, walls, cooldown and save/continue snapshots.
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
V.__add=function(a,b) return vec(a.X+b.X,a.Y+b.Y) end
V.__mul=function(a,k) return vec(a.X*k,a.Y*k) end
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
    GetPlayerTypeByName=function(name,tainted) return name=="Mistral-chan" and (tainted and 156 or 56) or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=156,dead=false,
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
    function p:EvaluateItems() self.MoveSpeed=1; self.Damage=10
        fire("MC_EVALUATE_CACHE",self,CacheFlag.CACHE_SPEED); fire("MC_EVALUATE_CACHE",self,CacheFlag.CACHE_DAMAGE) end
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
    include("scripts.characters.mistral_baguette"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.mistralBaguette[tostring(i or 0)] end
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

local function hud() draws={}; fire("MC_POST_RENDER"); return draws[1] end
local function stand(p,n) p.Velocity=vec(0,0); p.aim=vec(0,0); tick(n) end
local function aim(p,x,y) p.Velocity=vec(0,0); p.aim=vec(x,y or 0) end

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
near(p.MoveSpeed,0.9); near(p.Damage,9)
assert(hud()=="Mistral-chan: Baguettes 0/2  Combat to bake",hud())

-- Two seconds standing without firing bakes one Baguette; firing or moving resets.
stand(p,90); assert(state().baguettes==0 and state(1).baguettes==0,"a safe room cannot bake")
assert(hud():find("Combat to bake"),hud()); clear=false
stand(p,59); assert(state().baguettes==0)
aim(p,1); tick(); stand(p,59); assert(state().baguettes==0,"firing resets the charge")
p.Velocity=vec(3,0); tick(); stand(p,59); assert(state().baguettes==0,"moving resets the charge")
tick(); assert(state().baguettes==1 and texts[#texts]=="Baguette baked")
-- Pause and duplicate updates do not count; the cap is two.
stand(p,58); paused=true; tick(30); paused=false; fire("MC_POST_UPDATE"); fire("MC_POST_UPDATE")
assert(state().baguettes==1); tick(); assert(state().baguettes==1); tick(); assert(state().baguettes==2)
tick(120); assert(state().baguettes==2 and hud()=="Mistral-chan: Baguettes 2/2","capped at two")
assert(state(1).baguettes==2,"q bakes separately")

-- DROP sends a slow wave along the aim: 2.5x once per enemy in reach.
enter(2,true)
local e1,e2,e3,e4=enemy(40,0),enemy(100,0),enemy(160,0),enemy(60,40)
aim(p,1); tap(p); assert(state().baguettes==1 and texts[#texts]=="Baguette!")
tick(); assert(#e1.taken==0,"the wave is slow")
tick(); assert(#e1.taken==1); near(e1.taken[1],22.5)
tick(14); assert(#e2.taken==0); tick(); assert(#e2.taken==1)
tick(13); assert(#e1.taken==1 and #e3.taken==0 and #e4.taken==0,"one hit each; reach and width are bounded")
local e5=enemy(120,0); tick(); assert(#e5.taken==0,"the wave is gone after 120 units"); e5.dead=true
assert(hud()=="Mistral-chan: Baguettes 1/2  Cooldown 1s",hud()) 
-- The two-second cooldown blocks DROP.
tap(p); assert(state().baguettes==1,"cooldown")
tick(25); assert(hud()=="DROP: Wave cooling down"); tick()
assert(hud()=="DROP: Wave cooling down","cue lifetime is independent of cooldown")
tick(19); assert(hud()=="Mistral-chan: Baguettes 1/2")
-- Walls stop the wave; a new wave can hit the same enemy again.
walls={70}; e2.Position=vec(110,0)
tap(p); tick(40); assert(#e1.taken==2 and #e2.taken==1 and #e3.taken==0,"the wall stops it"); walls={}
tick(30)
local shown=#texts; assert(state().baguettes==0); tap(p); assert(#texts==shown,"no Baguette, no wave")

-- Room exit cancels a rolling wave.
state().baguettes=1; tick(60); stand(p,0); tap(p); tick(2)
enter(3,true); local late=enemy(0,100); tick(40); assert(#late.taken==0,"room exit cancels the wave")
-- Standing still without aim sends it down; movement aims it too.
state().baguettes=2; tick(60); local below,right=enemy(0,60),enemy(60,0)
stand(p,0); tap(p); tick(30); assert(#below.taken==1 and #right.taken==0)
tick(60); p.Velocity=vec(3,0); tap(p); tick(30); assert(#right.taken==1,"moving aims the wave")

-- Birthright bakes in 1.5 seconds; a dead Mistral bakes nothing.
state().baguettes=0; p.birthright=true; stand(p,44); assert(state().baguettes==0); tick(); assert(state().baguettes==1)
p.birthright=false
p.dead=true; tick(90); p.dead=false; assert(state().baguettes==1,"a dead Mistral bakes nothing")

-- Continue keeps Baguettes, not the charge.
stand(p,30)
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().baguettes==1); near(p.MoveSpeed,0.9); near(p.Damage,9)
tick(58); assert(state().baguettes==1); tick(); assert(state().baguettes==2)

-- Identity and character changes do not transfer progress; corrupt data resets.
players[1]=player(101,999,0); p=players[1]; tick(); assert(state().baguettes==0)
p.kind=0; tick(); assert(state()==nil); p:EvaluateItems(); near(p.MoveSpeed,1); near(p.Damage,10)
p.kind=156; tick(); Risk.state.mistralBaguette["0"]={version=1,baguettes=3}; tick(); assert(state().baguettes==0)
Risk.state.mistralBaguette["0"]={version=1,baguettes=0.5}; tick(); assert(state().baguettes==0)
-- Clearing pauses partial baking; a later fight resumes it, while room exit resets it.
fire("MC_POST_GAME_STARTED",false); clear=false; stand(p,30)
clear=true; stand(p,90); assert(state().baguettes==0)
clear=false; stand(p,29); assert(state().baguettes==0); tick(); assert(state().baguettes==1)
stand(p,30); enter(200,false); clear=false; stand(p,59); assert(state().baguettes==1)
tick(); assert(state().baguettes==2,"the new room requires the full baking interval")
-- Baking reads the current threshold without throwing away accumulated progress.
local function freshBake(birthright)
    players={player(501,511,0),player(502,522,1)}; p,q=players[1],players[2]
    down={}; paused=false; room=201; clear=false; enemies={}
    p.birthright=birthright; q.birthright=not birthright
    load(); fire("MC_POST_GAME_STARTED",false)
end
freshBake(false); stand(p,40); p.birthright=true; stand(p,4)
assert(state().baguettes==0,"gaining Birthright does not bake before frame 45")
tick(); assert(state().baguettes==1 and state(1).baguettes==1,
    "mid-bake Birthright gain uses accumulated progress and the current threshold")
freshBake(true); stand(p,40); p.birthright=false; stand(p,19)
assert(state().baguettes==0 and state(1).baguettes==0,
    "mid-bake Birthright loss restores the 60-frame threshold for that owner")
tick(); assert(state().baguettes==1 and state(1).baguettes==1,
    "losing Birthright preserves elapsed baking progress")
freshBake(true); stand(p,30); p.birthright=false; stand(p,10)
p.birthright=true; stand(p,4); fire("MC_POST_UPDATE")
assert(state().baguettes==0 and state(1).baguettes==0,"reacquisition and duplicate updates do not grant early bread")
tick(); assert(state().baguettes==1 and state(1).baguettes==0,
    "reacquisition uses existing progress without changing the partner's threshold")
print("OK: tainted Mistral baking, cap, slow wave, walls, cooldown, room exit, direction, Birthright and save/identity lifecycle")
