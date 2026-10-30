-- Real Verified / Fallback, Sanity Check and DROP callbacks with detached save/continue snapshots.
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
EntityType={ENTITY_PLAYER=1,ENTITY_TEAR=2,ENTITY_FAMILIAR=3,ENTITY_BOMB=4,ENTITY_LASER=7,ENTITY_KNIFE=8}
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
    GetPlayerTypeByName=function(name) return name=="GPT-chan" and 51 or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=51,dead=false,
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
    include("scripts.characters.gpt_downgrade"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.gptRouting[tostring(i or 0)] end
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
local function hit(target,source) fire("MC_ENTITY_TAKE_DMG",target,1,0,{Entity=source}); fire("MC_POST_UPDATE") end
local function reload(newPlayers)
    fire("MC_PRE_GAME_EXIT",true)
    players=newPlayers; frame=0
    load(); fire("MC_POST_GAME_STARTED",true)
end

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
assert(state().verified and state().routing==0,"a new run starts Verified")
near(p.Damage,11.5)

-- Unique combat clears add Routing; re-entry and peaceful rooms do not.
enter(2,true); finish(); assert(state().routing==1)
fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().routing==1,"duplicate awards are ignored")
enter(3,false); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().routing==1,"a room without combat is not a clear")
enter(2,true); finish(); assert(state().routing==1,"re-entering an awarded room cannot farm Routing")
enter(4,true); finish(); enter(5,true); finish()
assert(state().routing==3 and state().verified,"three clears cap Routing but stay Verified until the next combat")
assert(state(1).routing==3,"each player tracks their own clears")

-- At three Routing, the next combat begins in announced Fallback.
enter(7,false); assert(state().verified)
enter(8,true); assert(not state().verified,"the next combat starts in Fallback")
near(p.Damage,8); assert(texts[#texts]:match("Fallback"))

-- DROP tags the nearest vulnerable enemy within 200 units; no target spends nothing.
enemy(300); tap(p); assert(state().checkRoom==nil,"an enemy beyond 200 units cannot be tagged")
local friend=enemy(50); friend.friendly=true; tap(p); assert(state().checkRoom==nil,"friendly enemies are ignored")
local far,close=enemy(180),enemy(120)
down[0]=true; tick(20); down[0]=false; tick(); assert(state().checkRoom==nil,"a long hold keeps native DROP")
paused=true; down[0]=true; tick(); paused=false; down[0]=false; tick(); assert(state().checkRoom==nil,"pause cancels a tap")
tap(p); assert(state().checkRoom~=nil,"a tap spends the room's check")
draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="GPT-chan: Fallback  Check 0/3",draws[1])

-- Only distinct paid attacks against the tagged enemy count.
local v1=tear(p); local pellet=tear(p)
hit(far,v1); hit(close,tear(q)); hit(close,tear(p,false))
draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="GPT-chan: Fallback  Check 0/3","others, untagged and unpaid hits do not count")
hit(close,v1); hit(close,pellet); hit(close,v1)
draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="GPT-chan: Fallback  Check 1/3","one volley is one attack")
tick(); local derived=tear(p,false); derived:GetData().ccThoughtDerived=true; derived.FrameCount=1
hit(close,derived); hit(close,derived)
local laser={Type=EntityType.ENTITY_LASER,SpawnerEntity=p,ToPlayer=function() end}
frame=(frame//6+1)*6; hit(close,laser)
draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="GPT-chan: Fallback  Check 2/3",draws[1])
frame=frame+5; hit(close,laser)
assert(not state().verified,"one continuous window counts once")
tap(p); assert(not state().verified,"a second tag in the same room is ignored")
frame=frame+1; hit(close,laser)
assert(state().verified and state().routing==0,"three paid hits restore Verified and clear Routing")
near(p.Damage,11.5); assert(texts[#texts]=="Verified")
assert(not state(1).verified,"the partner remains in Fallback")
near(q.Damage,8)

-- The partner verifies by an owner-attributed defeat after a single hit.
local target=enemy(40); q.Position=vec(0); tap(q)
hit(target,tear(q)); fire("MC_POST_ENTITY_KILL",target)
assert(state(1).verified,"defeating the tagged enemy verifies")

-- A defeat without the owner's credit fails; leaving the room keeps Fallback.
state().routing=3; enter(9,true); assert(not state().verified)
local victim=enemy(30); tap(p); hit(victim,tear(p))
tick(5); fire("MC_POST_ENTITY_KILL",victim); victim.removed=true; tick()
assert(not state().verified,"a later kill by another source cannot verify")
draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="GPT-chan: Fallback  Check failed",draws[1])
tap(p); assert(not state().verified)
enter(10,true); local boss=enemy(60); tap(p)
hit(boss,tear(p)); tick(); hit(boss,tear(p))
enter(11,true); tick()
draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="GPT-chan: Fallback  DROP: Sanity Check","exit fails the check")
assert(not state().verified,"partial progress is lost on exit")

-- Birthright needs only two paid hits; bosses can verify without dying.
p.birthright=true; boss=enemy(60); tap(p)
hit(boss,tear(p)); tick(); hit(boss,{Type=EntityType.ENTITY_BOMB,SpawnerEntity=p,FrameCount=0,ToPlayer=function() end})
assert(state().verified,"Birthright verifies after two paid hits")
p.birthright=false

-- Familiar contact kills must not count as the owner's own defeat.
state().routing=3; enter(90,true); assert(not state().verified)
local familiarVictim=enemy(20); tap(p)
local familiar={Type=EntityType.ENTITY_FAMILIAR,SpawnerEntity=p,ToPlayer=function() end}
hit(familiarVictim,familiar); fire("MC_POST_ENTITY_KILL",familiarVictim)
assert(not state().verified,"a familiar contact kill cannot restore the owner's Verified status")

-- Continue preserves Fallback and the spent room check; entities are recreated.
state().routing=3; enter(12,true); assert(not state().verified)
local foe=enemy(20); tap(p); local spent=state().checkRoom
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]
enemies={foe}; tick()
assert(not state().verified and state().routing==3 and state().checkRoom==spent,"continue preserves Fallback")
near(p.Damage,8)
tap(p); hit(foe,tear(p)); tick(); hit(foe,tear(p)); tick(); hit(foe,tear(p))
assert(not state().verified,"continue cannot grant a second check in the same room")

-- A new floor restores Verified and clears Routing; continue on it does not reset again.
floor=20; enter(1,false)
assert(state().verified and state().routing==0 and next(state().awards)==nil,"a new floor restores Verified")
near(p.Damage,11.5)
enter(2,true); finish(); assert(state().routing==1,"awards are per floor")
state().routing=3; enter(3,true); assert(not state().verified)
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(not state().verified,"continue on the same floor stays in Fallback")

-- Identity and character changes do not transfer routing.
players[1]=player(101,999,0); p=players[1]; tick()
assert(state().verified and state().routing==0,"a replacement player starts fresh")
state().routing=2
p.kind=0; tick(); assert(state()==nil)
p:EvaluateItems(); near(p.Damage,10)
p.kind=51; tick(); assert(state().routing==0)

-- Corrupt saves are discarded rather than trusted.
Risk.state.gptRouting["0"]={version=1,verified="yes",routing=0,awards={}}
tick(); assert(state().verified==true)
Risk.state.gptRouting["0"]={version=1,verified=false,routing=9,awards={}}
tick(); assert(state().verified and state().routing==0,"Routing above the cap is invalid")

fire("MC_POST_GAME_STARTED",false)
assert(state().verified and state().routing==0,"a new run resets routing")
-- Distinct off-target paid attacks contradict once; the chosen target wins for the same attack.
state().routing=3; enter(200,true); local focus,off=enemy(20),enemy(80); tap(p)
frame=frame+1; hit(focus,tear(p)); frame=frame+1; local contrary=tear(p); hit(off,contrary); hit(off,contrary)
draws={}; fire("MC_POST_RENDER"); assert(draws[1]:find("Check 0/3"),"one contradictory attack removes one hit, never below zero")
-- A delayed piercing hit revises that attack's outcome instead of receiving both gain and loss.
frame=frame+1; hit(focus,contrary)
draws={}; fire("MC_POST_RENDER"); assert(draws[1]:find("Check 2/3"),"target priority also holds across updates")
local helper=tear(p,false); helper:GetData().ccThoughtDerived=true; helper:GetData().ccLlamaHelper=true
frame=frame+1; hit(off,helper); hit(off,tear(q)); hit(off,tear(p,false))
draws={}; fire("MC_POST_RENDER"); assert(draws[1]:find("Check 2/3"),"unpaid/helper/partner hits do not contradict")
frame=frame+1; local area=tear(p); hit(off,area); hit(focus,area); assert(state().verified,"mixed target order still verifies")
-- Reverse order and multiple enemies never contradict the same paid attack.
state().routing=3; enter(201,true); focus,off=enemy(20),enemy(80); tap(p)
frame=frame+1; area=tear(p); hit(focus,area); hit(off,area)
draws={}; fire("MC_POST_RENDER"); assert(draws[1]:find("Check 1/3"))
-- Picking up Birthright must not re-interpret an old, already contradicted prefix as success.
frame=frame+1; hit(focus,tear(p)); frame=frame+1; hit(off,tear(p)); frame=frame+1; hit(off,tear(p))
p.birthright=true; tick(); assert(not state().verified,"old two-hit progress was already lost")
frame=frame+1; hit(focus,tear(p)); assert(not state().verified)
frame=frame+1; hit(focus,tear(p)); assert(state().verified,"current two-hit progress still earns Birthright completion")
p.birthright=false
-- Stable observation keeps accounts; slot reuse must still retire the old owner.
fire("MC_POST_GAME_STARTED",false); enter(300,false)
state().routing=2; state(1).routing=1
local stableFirst,stableSecond=state(),state(1)
tick(20)
assert(state()==stableFirst and state(1)==stableSecond and state().routing==2 and state(1).routing==1,
    "unchanged owners retain their accounts and routing")
players={q,p}; tick()
assert(state().routing==1 and state(1).routing==2 and state()==stableSecond and state(1)==stableFirst,
    "routing follows each continuously observed owner through a slot swap")
state().routing=2; players={q}; tick()
assert(state().routing==2 and state(1)==nil,"departure prunes only the absent slot")
players[2]=p; tick()
assert(state().routing==2 and state(1).routing==0,"a returning slot starts fresh")
state(1).routing=1
players[1]=player(701,q.InitSeed,0); tick()
assert(state().routing==0 and state(1).routing==1,"pointer-only replacement cannot inherit the previous account")
print("OK: Verified / Fallback routing, Sanity Check attack accounting, Birthright and save/floor/identity lifecycle")
