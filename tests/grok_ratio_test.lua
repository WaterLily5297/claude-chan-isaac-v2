-- Real tainted Grok Quote Without Reading: Ratio from other targets, expiry pulses, cooldown and save/continue snapshots.
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
    GetPlayerTypeByName=function(name,tainted) return name=="Grok-chan" and (tainted and 153 or 53) or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=153,dead=false,
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
    include("scripts.characters.grok_ratio"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.grokRatio[tostring(i or 0)] end
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
local function hit(target,source,amount) target:TakeDamage(amount or 10,0,{Entity=source},0); fire("MC_POST_UPDATE"); return target.taken[#target.taken] end
local function reload(newPlayers)
    fire("MC_PRE_GAME_EXIT",true)
    players=newPlayers; frame=0
    load(); fire("MC_POST_GAME_STARTED",true)
end


players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
local function hud() draws={}; fire("MC_POST_RENDER"); return draws[1] end
local function step() frame=frame+1 end
p:EvaluateItems(); near(p.Damage,9)
enter(2,true)
assert(hud()=="Grok-chan: DROP: quote someone",hud())

-- DROP quotes the nearest hostile within 220 units; nothing nearby spends nothing.
enemy(400); tap(p); assert(hud()=="DROP: No target in range" and state().cooldown==0)
local friend=enemy(30); friend.friendly=true
local quoted,other,third=enemy(50),enemy(120),enemy(200)
tap(p); assert(texts[#texts]=="Quoted" and state().cooldown==300)
assert(hud()=="Grok-chan: Ratio 0/3  6s",hud())

-- Paid hits on others build Ratio once per attack; the quoted target, partners
-- and unregistered tears do not. Damage itself is unchanged.
step(); local t=tear(p); near(hit(other,t),10); hit(third,t)
assert(hud()=="Grok-chan: Ratio 1/3  6s","one volley counts once")
local prop=enemy(60); prop.IsEnemy=function() return false end
step(); hit(quoted,tear(p)); step(); hit(other,tear(q)); step(); hit(other,tear(p,false)); step(); hit(prop,tear(p))
assert(hud()=="Grok-chan: Ratio 0/3  6s","an own-only reply loses one Ratio")
for _=1,4 do step(); hit(third,tear(p)) end
assert(hud()=="Grok-chan: Ratio 3/3  6s","Ratio caps at three")
tap(p); assert(state().cooldown<300 and hud()=="DROP: Quote cooling down","no retarget during the quote")

-- At expiry the quoted target takes one 1x pulse per stack.
local before=#quoted.taken
paused=true; tick(200); paused=false
tick(state().cooldown-121); fire("MC_POST_UPDATE"); assert(#quoted.taken==before,"duplicate updates cannot age the quote")
tick(1); assert(#quoted.taken==before+3 and quoted.taken[#quoted.taken]==9 and texts[#texts]=="Ratio'd")
assert(state().cooldown==120 and hud()=="Grok-chan: Cooldown 4s",hud())
tap(p); assert(state().cooldown<120,"no new quote during the cooldown")
tick(117); assert(state().cooldown==0 and hud()=="Grok-chan: DROP: quote someone","ten-second cooldown from selection")

-- An early defeat wastes the pulse; leaving the room cancels.
tap(p); step(); hit(other,tear(p)); quoted.dead=true; tick()
assert(hud():find("Cooldown"),"early death wastes the quote")
state().cooldown=0; quoted.dead=false; tap(p); enter(3,true); assert(hud():find("Cooldown"),"room exit cancels")

-- Birthright moves half the Ratio once to the nearest surviving hostile.
state().cooldown=0; local a,b2,c=enemy(40),enemy(150),enemy(500)
p.birthright=true; tap(p)
for _=1,3 do step(); hit(b2,tear(p)) end
a.dead=true; tick(); assert(hud()=="Grok-chan: Ratio 1/3  6s",hud())
local n=#b2.taken; tick(180); assert(#b2.taken==n+1,"half the Ratio lands on the new target")
for _,x in ipairs(enemies) do x.dead=true end
state().cooldown=0; local e1,e2,e3=enemy(40),enemy(200),enemy(380); tap(p)
for _=1,3 do step(); hit(e3,tear(p)) end
e1.dead=true; tick(); assert(hud():find("Ratio 1/3"),hud())
e2.dead=true; tick(); assert(hud():find("Cooldown"),"Birthright moves the Ratio only once")
p.birthright=false

-- Continue keeps the cooldown; identity and corrupt data reset safely.
state().cooldown=0; local d=enemy(30); tap(p); assert(state().cooldown==300)
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().cooldown==299 and hud():find("Cooldown"),"continue keeps the cooldown, not the quote")
players[1]=player(101,999,0); p=players[1]; tick(); assert(state().cooldown==0,"a replacement starts fresh")
p.kind=0; tick(); assert(state()==nil)
p.kind=153; tick(); Risk.state.grokRatio["0"]={version=1,cooldown=999}; tick(); assert(state().cooldown==0)
fire("MC_POST_GAME_STARTED",false); assert(state().cooldown==0)
-- Same attack: eligible other targets win over the quoted target in either order.
enter(70,true); local focus,off=enemy(20),enemy(100); tap(p)
step(); local area=tear(p); hit(focus,area); hit(off,area)
assert(hud():find("Ratio 1/3"),"an area attack never both gains and loses")
step(); area=tear(p); hit(off,area); hit(focus,area); assert(hud():find("Ratio 2/3"))
step(); local contrary=tear(p); hit(focus,contrary); hit(focus,contrary); assert(hud():find("Ratio 1/3"))
step(); hit(off,contrary); assert(hud():find("Ratio 3/3"),"a delayed hit gives the same final outcome")
local helper=tear(p,false); helper:GetData().ccThoughtDerived=true; helper:GetData().ccLlamaHelper=true
step(); hit(focus,helper); hit(focus,tear(q)); hit(focus,tear(p,false)); assert(hud():find("Ratio 3/3"))
step(); local friend=enemy(80); friend.friendly=true; area=tear(p); hit(focus,area); hit(friend,area)
assert(hud():find("Ratio 2/3"),"a friendly is not an eligible other target")
-- Repeated binds retain cooldowns; slot reuse cannot give them to a new owner.
fire("MC_POST_GAME_STARTED",false)
state().cooldown=200; state(1).cooldown=150
local stableFirst,stableSecond=state(),state(1)
tick(20)
assert(state()==stableFirst and state(1)==stableSecond and state().cooldown==180 and state(1).cooldown==130,
    "unchanged owners retain their accounts and advance cooldowns once per frame")
players={q,p}; tick()
assert(state().cooldown==0 and state(1).cooldown==0 and state()~=stableFirst and state(1)~=stableSecond,
    "swapping occupied slots cannot transfer cooldowns")
state().cooldown=20; players={q}; tick()
assert(state().cooldown==19 and state(1)==nil,"departure prunes only the absent slot")
players[2]=p; tick()
assert(state().cooldown==18 and state(1).cooldown==0,"a returning slot starts fresh")
state(1).cooldown=100
players[1]=player(701,q.InitSeed,0); tick()
assert(state().cooldown==0 and state(1).cooldown==99,"pointer-only replacement cannot inherit the previous cooldown")
print("OK: tainted Grok Ratio from other targets, expiry pulses, cooldown, early defeat, Birthright transfer and save/identity lifecycle")
