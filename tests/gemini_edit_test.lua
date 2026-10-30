-- Real tainted Gemini One More Edit: chain steps, export pulse, once per room and save/continue snapshots.
local root=arg[1]
local frame, paused, clear, room, floor = 0, false, true, 1, 10
local callbacks, players, saved, draws, texts, enemies = {}, {}, nil, {}, {}, {}
local C={Player={CLAUDE_CHAN=41,DEEPSEEK_CHAN=42}}
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
local function vec(x,y) return {x=x,X=x,Y=y or 0, Distance=function(self,o) return math.sqrt((self.X-o.X)^2+(self.Y-o.Y)^2) end} end
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
    GetPlayerTypeByName=function(name,tainted) return name=="Gemini-chan" and (tainted and 152 or 52) or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=152,dead=false,
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
    include("scripts.characters.gemini_edit"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.geminiEdit[tostring(i or 0)] end
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
local function hud() draws={}; fire("MC_POST_RENDER"); return draws[1] end
p:EvaluateItems(); near(p.Damage,9)
enter(2,true)
assert(hud()=="Gemini-chan: DROP: start an edit",hud())

-- DROP targets the nearest hostile within 180 units; no target starts nothing.
enemy(300); tap(p); assert(hud()=="DROP: No target in range","beyond 180 units")
local friend=enemy(40); friend.friendly=true; tap(p); assert(hud()=="DROP: No target in range","friendly ignored")
tick(45); assert(hud()=="Gemini-chan: DROP: start an edit","normal HUD returns after refusal")
local far,close=enemy(170),enemy(90)
down[0]=true; tick(20); down[0]=false; tick(); assert(hud()=="Gemini-chan: DROP: start an edit","a long hold keeps native DROP")
tap(p); assert(texts[#texts]=="One more edit")
assert(hud()=="Gemini-chan: Crop 0/3  6s",hud())

-- Distinct paid attacks on the target advance; damage itself is unchanged.
local t1=tear(p); near(hit(close,t1),10); near(hit(close,t1),10)
frame=frame+1; near(hit(close,tear(p)),10)
assert(hud():find("Recolor 1/3"),"the same angle cannot advance a distinct attack")
assert(hud()=="Gemini-chan: Recolor 1/3  6s  Move 30deg","one volley counts once")
frame=frame+1; hit(far,tear(p)); frame=frame+1; hit(close,tear(q)); frame=frame+1; hit(close,tear(p,false))
assert(hud()=="Gemini-chan: Recolor 1/3  6s  Move 30deg","other targets, partners and unregistered tears do not count")
p.Position=vec(90,-90); frame=frame+1; hit(close,tear(p)); assert(hud()=="Gemini-chan: Export 2/3  6s  Move 30deg",hud())
p.Position=vec(180,0); frame=frame+1; hit(close,tear(p))
assert(texts[#texts]=="Exported" and close.taken[#close.taken-1]==18 and close.taken[#close.taken]==10,"export pulses 2x player damage")
assert(hud()=="Gemini-chan: Exported")
tap(p); assert(hud()=="DROP: Already exported this room","one completed chain per room")
tick(45); assert(hud()=="Gemini-chan: Exported","exported HUD returns")

-- Retargeting erases progress; an early defeat never completes; the chain times out.
p.Position=vec(0); enter(3,true); local a,b=enemy(20),enemy(60)
tap(p); frame=frame+1; hit(a,tear(p)); p.Position=vec(20,-20); frame=frame+1; hit(a,tear(p)); assert(hud()=="Gemini-chan: Export 2/3  6s  Move 30deg")
tap(p); assert(hud()=="Gemini-chan: Crop 0/3  6s","a new tap erases progress")
frame=frame+1; hit(a,tear(p)); a.dead=true; tick(); assert(hud()=="Gemini-chan: DROP: start an edit","early defeat ends the chain")
tap(p); frame=frame+1; hit(b,tear(p))
paused=true; tick(300); paused=false; assert(hud()=="Gemini-chan: Recolor 1/3  6s  Move 30deg","pause freezes the timer")
tick(179); fire("MC_POST_UPDATE"); assert(hud()=="Gemini-chan: Recolor 1/3  1s  Move 30deg","duplicate update cannot age it")
tick(1); assert(hud()=="Gemini-chan: DROP: start an edit","six seconds pass")

-- Birthright gives ten seconds; leaving the room cancels.
p.birthright=true; tap(p); assert(hud()=="Gemini-chan: Crop 0/3  10s",hud()); p.birthright=false
enter(4,true); assert(hud()=="Gemini-chan: DROP: start an edit")

-- Continue keeps the exported room; a new room is open again.
enter(2,true); assert(hud()=="Gemini-chan: Exported")
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(hud()=="Gemini-chan: Exported","continue keeps the exported room")
players[1]=player(101,999,0); p=players[1]; tick(); assert(state().doneRoom==nil,"a replacement starts fresh")
p.kind=0; tick(); assert(state()==nil)
p.kind=152; tick(); Risk.state.geminiEdit["0"]={version=1,doneRoom=5}; tick(); assert(state().doneRoom==nil,"corrupt data is discarded")
fire("MC_POST_GAME_STARTED",false); assert(state().doneRoom==nil)
-- Exactly 30 degrees advances; zero separation and an unchanged bearing do not.
p.Position=vec(0); enter(50,true); local angled=enemy(0); tap(p)
frame=frame+1; hit(angled,tear(p)); assert(hud():find("Crop 0/3"),"zero separation is not a bearing")
p.Position=vec(100,0); frame=frame+1; hit(angled,tear(p)); assert(hud():find("Recolor 1/3"))
p.Position=vec(100*math.cos(math.rad(29)),100*math.sin(math.rad(29)))
frame=frame+1; hit(angled,tear(p)); assert(hud():find("Recolor 1/3"),"29 degrees remains native only")
p.Position=vec(100*math.cos(math.rad(30)),100*math.sin(math.rad(30)))
frame=frame+1; hit(angled,tear(p)); assert(hud():find("Export 2/3"),"30-degree boundary advances")
angled.friendly=true; tick(); assert(hud()=="Gemini-chan: DROP: start an edit","unavailable target ends the chain")
-- Birthright is sampled when a chain starts, not while that chain is pending.
for _,initial in ipairs({false,true}) do
    players={player(501,511,0),player(502,522,1)}; p,q=players[1],players[2]
    down={}; paused=false; p.birthright=initial; q.birthright=not initial
    load(); fire("MC_POST_GAME_STARTED",false); enter(201,true)
    local pending=enemy(40); tap(p); hit(pending,tear(p))
    local duration=initial and 300 or 180
    assert(hud():find("Recolor 1/3"),"a paid step is present before inventory changes")
    tick(60); p.birthright=not initial; tick(30)
    p.birthright=initial; tick(30); p.birthright=not initial
    tick(duration-121)
    assert(hud():find("Recolor 1/3  1s"),
        "pending edit keeps its original duration and step through Birthright gain/loss/reacquisition")
    fire("MC_POST_UPDATE")
    assert(hud():find("Recolor 1/3  1s"),"duplicate update does not spend the last edit frame")
    tick(); assert(hud()=="Gemini-chan: DROP: start an edit",
        "pending edit expires at its original deadline")
    assert(state().doneRoom==nil and state(1).doneRoom==nil,"expiry neither exports nor spends a partner's room")
    tap(p)
    assert(hud():find(initial and "Crop 0/3  6s" or "Crop 0/3  10s"),
        "a later edit samples the owner's current Birthright")
end
print("OK: tainted Gemini edit chain steps, export pulse, once per room, retarget, timers, Birthright and save/identity lifecycle")
