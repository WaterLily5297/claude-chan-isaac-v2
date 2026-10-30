-- Real Kimi Slides: unique clears, DROP presentations, slowing, owner bonus and save/continue snapshots.
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
CacheFlag={CACHE_DAMAGE=1}
EntityType={ENTITY_PLAYER=1,ENTITY_TEAR=2,ENTITY_BOMB=4,ENTITY_LASER=7,ENTITY_KNIFE=8,ENTITY_EFFECT=1000}
EffectVariant={PLAYER_CREEP_BLACK=45}
function Vector(x,y) return {X=x,Y=y} end
function Color(r,g,b,a) return {R=r,G=g,B=b,A=a} end
local peels={}
EntityPartition={ENEMY=8}
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
    GetPlayerTypeByName=function(name) return name=="Kimi-chan" and 58 or -1 end,
    Spawn=function(kind,variant,_,pos,_,owner)
        local e={Type=kind,Variant=variant,Position=pos,SpawnerEntity=owner,removed=false}
        function e:ToEffect() return self end
        function e:SetTimeout(t) self.timeout=t end
        function e:Exists() return not self.removed end
        function e:Remove() self.removed=true end
        peels[#peels+1]=e
        return e
    end,
    FindInRadius=function(pos,radius)
        local found={}
        for _,e in ipairs(enemies) do if math.abs(e.Position.x-pos.x)<=radius+10 then found[#found+1]=e end end
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=58,dead=false,
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
    include("scripts.characters.kimi_slides"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.kimiSlides[tostring(i or 0)] end
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


players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
assert(state().slides==0,"a new run starts with no Slides")
local function hud() draws={}; fire("MC_POST_RENDER"); return draws[1] end
assert(hud()=="Kimi-chan: Slides 0/6  Cost 3",hud())

-- Unique combat clears earn Slides up to six; re-entry and peaceful rooms do not.
enter(2,true); finish(); assert(state().slides==1)
fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().slides==1,"duplicate awards are ignored")
enter(3,false); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().slides==1,"a room without combat is not a clear")
enter(2,true); finish(); assert(state().slides==1,"re-entering an awarded room cannot farm Slides")
for r=4,10 do enter(r,true); finish() end
assert(state().slides==6,"Slides cap at six")
assert(state(1).slides==6,"each player earns their own Slides")

-- DROP needs three Slides and an audience within 220 units; no audience spends nothing.
enter(11,true)
enemy(225); tap(p); assert(state().slides==6,"an enemy beyond 220 units cannot be presented to")
local friend=enemy(40); friend.friendly=true; tap(p); assert(state().slides==6 and not friend.slowed,"friendly enemies are ignored")
local a,b,c,d=enemy(200),enemy(30),enemy(90),enemy(150)
down[0]=true; tick(20); down[0]=false; tick(); assert(state().slides==6,"a long hold keeps native DROP")
paused=true; down[0]=true; tick(); paused=false; down[0]=false; tick(); assert(state().slides==6,"pause cancels a tap")
tap(p); assert(state().slides==3 and texts[#texts]=="Another slide deck")
assert(b.slowed and b.slowed[1]==120 and c.slowed and d.slowed and not a.slowed,"the three nearest are slowed for four seconds")
assert(hud()=="Kimi-chan: Slides 3/6  Cost 3  Presenting 4s",hud())

-- Only the owner's damage to the audience gains +15%.
near(hit(b,tear(p)),11.5)
near(hit(a,tear(p)),10)
near(hit(b,tear(q)),10)
near(hit(c,{Type=EntityType.ENTITY_LASER,SpawnerEntity=p,ToPlayer=function() end}),10)
b.dead=true; near(hit(c,tear(p)),11.5); near(hit(d,tear(p)),10)
b.dead=false; tick(); near(hit(b,tear(p)),10); near(hit(c,tear(p)),11.5) -- No backward focus after revival.
c.friendly=true; tick(); near(hit(d,tear(p)),11.5); near(hit(c,tear(p)),10)
c.friendly=false

-- A new presentation replaces the old one.
b.slowed=nil; c.slowed=nil; d.slowed=nil
b.Position=vec(600); c.Position=vec(600); d.Position=vec(600)
tap(p); assert(state().slides==0 and a.slowed)
near(hit(a,tear(p)),11.5); near(hit(b,tear(p)),10)
state().slides=2; tap(p); assert(state().slides==2,"too few Slides means no presentation"); state().slides=0

-- The presentation lasts four seconds of updates and pause freezes it.
paused=true; tick(300); paused=false; near(hit(a,tear(p)),11.5)
tick(116); fire("MC_POST_UPDATE"); near(hit(a,tear(p)),11.5,"a duplicate update cannot age the deck")
tick(1); near(hit(a,tear(p)),10)

-- The deck ends once its audience is gone.
state().slides=3; a.Position=vec(10); tap(p); near(hit(a,tear(p)),11.5)
a.dead=true; tick(); a.dead=false; near(hit(a,tear(p)),10)

-- Birthright lowers the cost to two.
p.birthright=true; state().slides=2; assert(hud()=="Kimi-chan: Slides 2/6  Cost 2",hud())
tap(p); assert(state().slides==0); near(hit(a,tear(p)),11.5); p.birthright=false

-- Leaving the room ends the presentation without refund.
enter(12,true); near(hit(a,tear(p)),10); assert(state().slides==0)

-- Continue preserves Slides; a new floor keeps them and resets awards.
state().slides=4
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().slides==4,"continue preserves Slides")
floor=20; enter(1,false); assert(state().slides==4 and next(state().awards)==nil)
enter(4,true); finish(); assert(state().slides==5,"awards are per floor")

-- Identity and character changes do not transfer Slides.
players[1]=player(101,999,0); p=players[1]; tick()
assert(state().slides==0,"a replacement player starts fresh")
state().slides=2
p.kind=0; tick(); assert(state()==nil)
p.kind=58; tick(); assert(state().slides==0)

-- Corrupt saves are discarded rather than trusted.
Risk.state.kimiSlides["0"]={version=1,slides=9,awards={}}
tick(); assert(state().slides==0)

fire("MC_POST_GAME_STARTED",false)
assert(state().slides==0,"a new run resets Slides")
print("OK: Kimi single-speaker focus, Slides clears, presentations, slowing, owner-only bonus, Birthright and save/floor/identity lifecycle")
