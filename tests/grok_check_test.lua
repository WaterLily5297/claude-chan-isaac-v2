-- Real Grok fact check, damage re-deal, room speed, Birthright bullets and DROP callbacks with save/continue snapshots.
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
    GetPlayerTypeByName=function(name) return name=="Grok-chan" and 53 or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=53,dead=false,
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
    include("scripts.characters.grok_check"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.grokCheck[tostring(i or 0)] end
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
    local b={Position=vec(x),removed=false}
    function b:ToProjectile() return self end
    function b:Exists() return not self.removed end
    function b:Remove() self.removed=true end
    bullets[#bullets+1]=b
    return b
end
local function hud() draws={}; fire("MC_POST_RENDER"); return draws[1] end

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
near(p.MoveSpeed,1)

-- Checks need a hostile room and a target within 220 units.
local foe=enemy(100); tap(p); assert(hud()=="DROP: Needs combat","a cleared room cannot be checked")
enter(2,true)
enemy(400); tap(p); assert(state().checkRoom==nil,"no target spends nothing")
local friend=enemy(40); friend.friendly=true; tap(p); assert(state().checkRoom==nil,"friendly enemies are ignored")
local other,target=enemy(210),enemy(150)
down[0]=true; tick(20); down[0]=false; tick(); assert(state().checkRoom==nil,"a long hold keeps native DROP")
tap(p); assert(state().checkRoom and texts[#texts]=="Is this true?")
assert(hud()=="Grok-chan: Check 0/3  6s",hud())

-- During a check the owner deals 1.3x to the target and 0.9x to others.
near(hit(target,tear(p)),13); near(hit(other,tear(p)),9); near(hit(target,tear(q)),10)
assert(hud()=="Grok-chan: Check 1/3  6s",hud())
tick(); local v=tear(p); near(hit(target,v),13); near(hit(target,v),13)
assert(hud()=="Grok-chan: Check 2/3  6s","one volley is one attack")
tap(p); assert(hud()=="DROP: Check in progress","no second check in the same room")
tick(45); assert(hud():find("Check 2/3"),"the existing check was not restarted")

-- A third distinct attack verifies: modifiers end and speed rises for the room.
tick(); near(hit(target,tear(p)),13)
assert(hud()=="Grok-chan: Verified" and state().verifiedRoom); near(p.MoveSpeed,1.15)
near(hit(target,tear(p)),10); near(hit(other,tear(p)),10)
near(q.MoveSpeed,1,"the partner is not verified")

-- Leaving the room ends the speed bonus; a new room allows a new check.
enter(3,true); near(p.MoveSpeed,1); enter(2,true); p:EvaluateItems(); near(p.MoveSpeed,1,"re-entering the verified room does not restore speed")
enter(3,true); target=enemy(50); local stray=bullet(10)
tap(p); hit(target,tear(p)); target.dead=true; fire("MC_POST_ENTITY_KILL",target)
assert(hud()=="Grok-chan: Verified","an owner-credited defeat verifies"); near(p.MoveSpeed,1.15)
assert(not stray.removed,"only Birthright clears bullets"); bullets={}

-- Timeout or another killer gives nothing.
enter(4,true); target=enemy(50); tap(p)
tick(179); fire("MC_POST_UPDATE"); near(hit(target,tear(p)),13,"a duplicate update cannot age the check")
tick(); near(hit(target,tear(p)),10)
assert(hud()=="Grok-chan: Unverified"); near(p.MoveSpeed,1)
enter(5,true); target=enemy(50); tap(p); hit(target,tear(p)); tick(5)
target.dead=true; fire("MC_POST_ENTITY_KILL",target); assert(hud()=="Grok-chan: Unverified")

-- Pause and duplicate updates freeze the timer.
enter(6,true); target=enemy(50); tap(p)
paused=true; tick(300); paused=false; fire("MC_POST_UPDATE")
assert(hud()=="Grok-chan: Check 0/3  6s",hud())

-- Birthright verification removes up to three nearby bullets once.
enter(7,true); target=enemy(50); p.birthright=true; tap(p)
local b1,b2,b3,b4,b5=bullet(10),bullet(20),bullet(30),bullet(40),bullet(500)
for _=1,3 do tick(); hit(target,tear(p)) end
assert(b1.removed and b2.removed and b3.removed and not b4.removed and not b5.removed,"three nearest bullets")
p.birthright=false

-- Continue keeps the spent check and the verified room's speed.
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
near(p.MoveSpeed,1.15); target=enemy(30); tap(p); assert(hud()=="DROP: Check spent this room","no second check after continue")
tick(45); assert(hud()=="Grok-chan: Verified","saved verification remains after the cue")

-- Character and identity changes discard the flags.
players[1]=player(101,999,0); p=players[1]; tick(); assert(state().verifiedRoom==nil)
p.kind=0; tick(); assert(state()==nil)
p.kind=53; tick(); assert(state())
Risk.state.grokCheck["0"]={version=1,checkRoom=7}
tick(); assert(state().checkRoom==nil,"corrupt saves are discarded")

fire("MC_POST_GAME_STARTED",false); assert(state().checkRoom==nil and state().verifiedRoom==nil)
-- Show the receipts: one uninterrupted second without sight fails the spent check.
enter(100,true); target=enemy(50); tap(p); lineOfSight=false; tick(29)
local sightWarning=hud():find("Restore sight"); fire("MC_POST_UPDATE")
paused=true; tick(60); paused=false; fire("MC_POST_UPDATE")
assert(hud():find("Check"),"pause/duplicate callbacks do not consume the grace interval")
tick(); assert(hud()=="Grok-chan: Unverified" and not state().verifiedRoom)
assert(sightWarning,"obstruction has a visible counterplay cue")
near(hit(target,tear(p)),10); near(p.MoveSpeed,1)
lineOfSight=true; tap(p); assert(hud()=="DROP: Check spent this room","no second check after losing sight")
tick(45); assert(hud()=="Grok-chan: Unverified","lost check remains spent after the cue")
enter(101,true); target=enemy(50); tap(p)
lineOfSight=false; tick(20); lineOfSight=true; tick(); lineOfSight=false; tick(29)
assert(hud():find("Check"),"seeing the target resets the consecutive obstruction interval")
lineOfSight=true; tick(); target.friendly=true; tick()
assert(hud()=="Grok-chan: Unverified","a friendly target ends the check safely")
print("OK: Grok fact check, target/other damage, room speed, Birthright bullets and save/identity lifecycle")
