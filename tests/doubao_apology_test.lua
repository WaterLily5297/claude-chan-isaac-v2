-- Real Doubao Apology: qualifying hits, token timer, slowing, bullet removal and save/continue snapshots.
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
local function vec(x,y) return {x=x,X=x,Y=y or 0,Distance=function(self,o) return math.sqrt((self.X-o.X)^2+(self.Y-o.Y)^2) end} end
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
    GetPlayerTypeByName=function(name) return name=="Doubao-chan" and 57 or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=57,dead=false,
        Position=vec(0),Damage=10}
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:ToPlayer() return self end
    function p:GetShootingInput() return self.aim or vec(0,0) end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return true end
    function p:HasCollectible(id) return id==619 and self.birthright end
    function p:AddCacheFlags() end
    function p:EvaluateItems() self.MoveSpeed=1; fire("MC_EVALUATE_CACHE",self,CacheFlag.CACHE_SPEED) end
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
    include("scripts.characters.doubao_apology"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.doubaoApology[tostring(i or 0)] end
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
assert(hud()=="Doubao-chan: No apology needed")

-- Only the first real enemy-caused hit in a hostile room qualifies.
local foe=enemy(300)
hurt(p,foe); assert(state().token==nil,"cleared rooms do not qualify")
enter(2,true); foe=enemy(300)
hurt(p,foe,DamageFlag.DAMAGE_FAKE); hurt(p,foe,DamageFlag.DAMAGE_NO_PENALTIES)
local machine={Type=EntityType.ENTITY_SLOT}; function machine:IsEnemy() return false end; function machine:HasEntityFlags() return false end
hurt(p,machine); hurt(p,nil); assert(state().token==nil,"fake, self and machine damage do not qualify")
local friend=enemy(300); friend.friendly=true; hurt(p,friend); assert(state().token==nil,"friendly entities do not qualify")
hurt(p,bullet(500)); assert(state().token==180 and texts[#texts]=="Apology ready","an enemy bullet qualifies")
bullets={}
assert(state(1).token==nil,"the partner was not hit")
tick(30); hurt(p,foe); assert(state().token==150,"only the first hit in a room counts")
assert(hud()=="Doubao-chan: Apology Ready 5s  Aim Down",hud())

-- The token lasts six seconds of updates; pause freezes it.
paused=true; tick(300); paused=false; fire("MC_POST_UPDATE"); assert(state().token==150)
tick(149); assert(state().token==1); tick(); assert(state().token==nil)
tap(p); assert(texts[#texts]~="Sorry, you're right.","no token, no apology")

-- DROP slows nearby enemies and removes the four nearest bullets.
p.aim=vec(1,0); enter(3,true); foe=enemy(50); local distant=enemy(400); local ally=enemy(60); ally.friendly=true
local behind=enemy(-40)
local b1,b2,b3,b4,b5,b6=bullet(-10),bullet(-20),bullet(30),bullet(40),bullet(50),bullet(300)
hurt(p,foe); down[0]=true; tick(20); down[0]=false; tick(); assert(state().token,"a long hold keeps native DROP")
tap(p); assert(state().token==nil and texts[#texts]=="Sorry, you're right.")
assert(not behind.slowed,"the slow is directed, not radial")
assert(foe.slowed and foe.slowed[1]==60 and not distant.slowed and not ally.slowed,"slow hostile enemies within 100 for two seconds")
assert(b1.removed and b2.removed and b3.removed and b4.removed and not b5.removed and not b6.removed)
hurt(p,foe); assert(state().token==nil,"one Apology per room")

-- Leaving the room ends the token; Birthright keeps it until exit.
enter(4,true); foe=enemy(50); hurt(p,foe); enter(5,true); assert(state().token==nil,"exit ends the token")
p.birthright=true; foe=enemy(50); hurt(p,foe); assert(state().token==0)
tick(500); assert(state().token==0 and hud()=="Doubao-chan: Apology Ready  Aim Right","Birthright lasts until exit")

-- Continue keeps the token and the room's spent hit.
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().token==0 and state().hitRoom)
p.birthright=false; enter(6,false); assert(state().token==nil)

-- Identity and character changes do not transfer it.
enter(7,true); foe=enemy(50); hurt(p,foe); assert(state().token)
players[1]=player(101,999,0); p=players[1]; tick(); assert(state().token==nil)
p.kind=0; tick(); assert(state()==nil); p.kind=57; tick(); assert(state())
Risk.state.doubaoApology["0"]={version=1,token=5}; tick(); assert(state().token==nil,"a token without its room is corrupt")

fire("MC_POST_GAME_STARTED",false); assert(state().token==nil and state().hitRoom==nil)
-- Aim memory is per-player, survives continue and includes the 60-degree cone edge.
p.aim=vec(1,0); tick(); p.aim=vec(0,0); enter(80,true)
local edge,outer,outside=enemy(0),enemy(0),enemy(101)
edge.Position=vec(50,50*math.sqrt(3)); outer.Position=vec(50,88)
hurt(p,edge); tap(p)
assert(edge.slowed and not outer.slowed and not outside.slowed,"120-degree cone and 100-unit radius include only the boundary")
reload({player(301,11,0),player(302,22,1)}); p,q=players[1],players[2]
assert(state().aimX==1 and state().aimY==0 and state(1).aimX==0 and state(1).aimY==1)
Risk.state.doubaoApology["0"]={version=1}; tick()
assert(state().version==2 and state().aimX==0 and state().aimY==1,"old saves receive downward aim")
print("OK: Doubao Apology qualifying hits, token timer, slowing, bullet removal, Birthright and save/identity lifecycle")
