-- Real Llama Releases: DROP fly sharing, recipients, clears and save/continue snapshots.
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
    GetPlayerTypeByName=function(name) return name=="Llama-chan" and 55 or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=55,flies=0,dead=false,
        Position=vec(0),Damage=10}
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:IsCoopGhost() return self.ghost == true end
    function p:AreControlsEnabled() return true end
    function p:HasCollectible(id) return id==619 and self.birthright end
    function p:AddBlueFlies(n) self.flies=self.flies+n end
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
    include("scripts.characters.llama_release"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.llamaRelease[tostring(i or 0)] end
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
local function flies() local r={}; for i,x in ipairs(players) do r[i]=x.flies end; return table.concat(r,",") end

-- Solo: one Release gives four flies.
players={player(1,11,0)}; load(); fire("MC_POST_GAME_STARTED",false)
local p=players[1]
assert(state().releases==1); p:EvaluateItems(); near(p.Damage,9.5)
assert(hud()=="Llama-chan: Releases 1/2  Next 0/2",hud())
clear=false; tap(p); assert(p.flies==0 and state().releases==1,"combat keeps the Release")
assert(texts[#texts]~="Prepare the release between fights","refusal stays out of shared captions")
assert(hud()=="DROP: Release between fights",hud()); tick(45)
assert(hud():find("Between fights"),hud()); clear=true
down[0]=true; tick(20); down[0]=false; tick(); assert(p.flies==0,"a long hold keeps native DROP")
tap(p); assert(p.flies==4 and state().releases==0 and texts[#texts]=="Released")
tap(p); assert(p.flies==4,"no Release, no flies")

-- Co-op: each living player gets two, at most four recipients; Birthright adds two to the owner.
local function vanilla(ptr,seed,ctrl) local x=player(ptr,seed,ctrl); x.kind=0; return x end
players={p,player(2,22,1),vanilla(3,33,2),vanilla(4,44,3),vanilla(5,55,4)}; tick()
local q=players[2]
state().releases=1; tap(p); assert(flies()=="6,2,2,2,0","at most four recipients: "..flies())
q.dead=true
assert(state(1).releases==1,"duplicate Llamas own separate budgets")
p.birthright=true; state().releases=1; tap(p); assert(flies()=="10,2,4,4,2","dead players are skipped: "..flies())
p.birthright=false; q.dead=false
-- A co-op ghost is not dead to IsDead() but cannot receive flies; the solo share applies.
players={p,q}; tick(); q.ghost=true
for _,x in ipairs(players) do x.flies=0 end
state().releases=1; tap(p); assert(flies()=="4,0","a co-op ghost receives no flies: "..flies())
q.ghost=false

-- Two unique combat clears earn a Release, capped at two.
state().releases=0
enter(2,true); finish(); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().clears==1)
enter(3,false); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().clears==1,"a peaceful room is not a clear")
enter(2,true); finish(); assert(state().clears==1,"re-entry cannot farm")
enter(4,true); finish(); assert(state().releases==1 and state().clears==0)
state().releases=2; state().clears=1
enter(5,true); finish(); assert(state().releases==2 and state().clears==0,"Releases cap at two")

-- Continue keeps Releases and progress; a new floor keeps them and resets awards.
state().releases=1; state().clears=1
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().releases==1 and state().clears==1)
floor=20; enter(2,true); finish(); assert(state().releases==2,"the same seed on a new floor is a new clear")

-- Identity and character changes do not transfer Releases.
clear=true; players[1]=player(101,999,0); p=players[1]; tick(); assert(state().releases==1)
p.kind=0; tick(); assert(state()==nil); p:EvaluateItems(); near(p.Damage,10)
p.kind=55; tick(); assert(state().releases==1)
Risk.state.llamaRelease["0"]={version=1,releases=7,clears=0,awards={}}
tick(); assert(state().releases==1,"corrupt saves are discarded")

fire("MC_POST_GAME_STARTED",false); assert(state().releases==1)
print("OK: Llama Releases, solo/co-op fly sharing, recipient cap, Birthright and save/floor/identity lifecycle")
