-- Real Gemini Paint, painted-damage re-deal, banana peel and DROP callbacks with save/continue snapshots.
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
    GetPlayerTypeByName=function(name) return name=="Gemini-chan" and 52 or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=52,dead=false,
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
    include("scripts.characters.gemini_paint"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.geminiPaint[tostring(i or 0)] end
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
assert(state().paint==2,"a new run starts with two Paint")
enter(2,true)

-- DROP paints the nearest hostile within 180 units; no target spends nothing.
enemy(300); tap(p); assert(state().paint==2,"an enemy beyond 180 units cannot be painted")
local friend=enemy(40); friend.friendly=true; tap(p); assert(state().paint==2,"friendly enemies are ignored")
local far,close=enemy(170),enemy(90)
down[0]=true; tick(20); down[0]=false; tick(); assert(state().paint==2,"a long hold keeps native DROP")
paused=true; down[0]=true; tick(); paused=false; down[0]=false; tick(); assert(state().paint==2,"pause cancels a tap")
tap(p); assert(state().paint==1); near(hit(close,tear(p)),10)
assert(texts[#texts]=="Wet paint: wait one second")
draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="Gemini-chan: Paint 1/3  Drying 1s",draws[1])

-- Wet paint does not amplify attacks; pause and duplicate updates cannot dry it.
near(hit(close,tear(p)),10); tick(29); near(hit(close,tear(p)),10)
fire("MC_POST_UPDATE"); near(hit(close,tear(p)),10)
paused=true; tick(60); paused=false; near(hit(close,tear(p)),10)
tick();
-- Only the owner's damage to the dried mark gains the original +20%.
near(hit(close,tear(p)),12)
near(hit(far,tear(p)),10)
near(hit(close,tear(q)),10)
near(hit(close,{Type=EntityType.ENTITY_LASER,SpawnerEntity=p,ToPlayer=function() end}),12)
near(hit(close,p),12)

-- A new mark replaces the old one.
tap(p); assert(state().paint==0)
near(hit(close,tear(p)),10); tick(30); near(hit(close,tear(p)),12)
tap(p); assert(state().paint==0,"no Paint means no mark")

-- The mark lasts eight seconds of updates and pause freezes it.
close.Position=vec(500); far.Position=vec(20)
state().paint=1; tap(p); near(hit(far,tear(p)),10); tick(30); near(hit(far,tear(p)),12); near(hit(close,tear(p)),10)
paused=true; tick(300); paused=false; near(hit(far,tear(p)),12)
tick(209); fire("MC_POST_UPDATE"); near(hit(far,tear(p)),12,"a duplicate update cannot age the mark")
tick(1); near(hit(far,tear(p)),10)

-- The owner's defeat leaves one timed slowing peel; another killer leaves none.
far.Position=vec(900); state().paint=2; local victim=enemy(30); tap(p)
hit(victim,tear(p)); victim.dead=true; fire("MC_POST_ENTITY_KILL",victim)
assert(#peels==1 and peels[1].Variant==45 and peels[1].timeout==120 and peels[1].SpawnerEntity==p)
local second=enemy(30); tap(p)
hit(second,tear(p)); second.dead=true; fire("MC_POST_ENTITY_KILL",second)
assert(#peels==2 and peels[1].removed and not peels[2].removed,"one peel per owner")
local stolen=enemy(30); state().paint=1; tap(p); hit(stolen,tear(p)); tick(5)
stolen.dead=true; fire("MC_POST_ENTITY_KILL",stolen)
assert(#peels==2,"a defeat without the owner's credit leaves no peel")

-- Birthright raises the painted bonus to 30%.
local boss=enemy(30); state().paint=1; tap(p); p.birthright=true
near(hit(boss,tear(p)),10); tick(30); near(hit(boss,tear(p)),13); p.birthright=false

-- Leaving the room ends the mark without refund.
local before=state().paint
enter(3,true); near(hit(boss,tear(p)),10); assert(state().paint==before)

-- Unique combat clears earn Paint up to three; re-entry and peaceful rooms do not.
state().paint=0
finish(); assert(state().paint==1)
fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().paint==1,"duplicate awards are ignored")
enter(4,false); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().paint==1,"a room without combat is not a clear")
enter(3,true); finish(); assert(state().paint==1,"re-entering an awarded room cannot farm Paint")
for r=5,8 do enter(r,true); finish() end
assert(state().paint==3,"Paint caps at three")
assert(state(1).paint==3 and q,"each player earns their own Paint")

-- Continue preserves Paint; a new floor keeps it and resets awards.
state().paint=1
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().paint==1,"continue preserves Paint")
floor=20; enter(1,false); assert(state().paint==1 and next(state().awards)==nil)
enter(5,true); finish(); assert(state().paint==2,"awards are per floor")

-- Identity and character changes do not transfer Paint.
players[1]=player(101,999,0); p=players[1]; tick()
assert(state().paint==2,"a replacement player starts fresh")
state().paint=0
p.kind=0; tick(); assert(state()==nil)
p.kind=52; tick(); assert(state().paint==2)

-- Corrupt saves are discarded rather than trusted.
Risk.state.geminiPaint["0"]={version=1,paint=9,awards={}}
tick(); assert(state().paint==2)

fire("MC_POST_GAME_STARTED",false)
assert(state().paint==2,"a new run resets Paint")
print("OK: Gemini Paint marks, owner-only bonus, banana peels, Birthright and save/floor/identity lifecycle")
