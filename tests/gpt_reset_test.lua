-- Real tainted GPT Reset Watcher: Credits, Full Send, banked Tibo reset and save/continue snapshots.
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
EntityType={ENTITY_PLAYER=1,ENTITY_TEAR=2,ENTITY_BOMB=4,ENTITY_LASER=7,ENTITY_KNIFE=8}
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
    GetPlayerTypeByName=function(name,tainted) return name=="GPT-chan" and (tainted and 151 or 51) or -1 end,
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
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=151,dead=false,
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
    include("scripts.characters.gpt_reset"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.gptReset[tostring(i or 0)] end
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
    if volley~=false then fire("MC_POST_FIRE_TEAR",t) end
    return t
end
local function hit(target,source) fire("MC_ENTITY_TAKE_DMG",target,1,0,{Entity=source}) end
local function reload(newPlayers)
    fire("MC_PRE_GAME_EXIT",true)
    players=newPlayers; frame=0
    load(); fire("MC_POST_GAME_STARTED",true)
end

local function shot(p,derived)
    local t=tear(p,false); t:GetData().ccThoughtDerived=derived
    fire("MC_POST_FIRE_TEAR",t); return t
end
local function laser(p) fire("MC_POST_LASER_INIT",{SpawnerEntity=p}) end
local function bomb(p,fetus) fire("MC_POST_BOMB_INIT",{SpawnerEntity=p,IsFetus=fetus}) end
local function hud() draws={}; fire("MC_POST_RENDER"); return draws[1] end

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
assert(state().credits==80 and not state().fullSend and not state().ready,"a new run starts with 80 Credits in Standard")
near(p.Damage,10)
assert(hud()=="Credits 80/80  Standard  Next Reset 0/3",hud())

-- Standard is free; Full Send costs one Credit per same-frame attack.
tick(); shot(p); laser(p); assert(state().credits==80,"Standard is free")
tap(p); assert(state().fullSend and texts[#texts]=="Full Send"); near(p.Damage,15)
tick(); shot(p); shot(p); laser(p); shot(p,true); assert(state().credits==79,"one payment per frame")
tick(); shot(p,true); assert(state().credits==79,"derived tears never pay")
tick(); laser(p); assert(state().credits==78,"lasers pay")
tick(); bomb(p,true); assert(state().credits==77,"Dr. Fetus bombs pay")
tick(); bomb(p,false); assert(state().credits==77,"ordinary bombs are free")
tick(); shot(q); assert(state(1).credits==80,"spending is personal")
local t=tear(p,false); tick(); fire("MC_POST_FIRE_TEAR",t); tick(); fire("MC_POST_FIRE_TEAR",t)
assert(state().credits==76,"a duplicate callback cannot pay twice")
-- Knife throws and held beams pay through the shared observer.
local knifeData={}
local knife={SpawnerEntity=p,SubType=0,GetData=function() return knifeData end,IsFlying=function() return true end}
tick(); fire("MC_POST_KNIFE_UPDATE",knife); tick(); fire("MC_POST_KNIFE_UPDATE",knife)
assert(state().credits==75,"a knife throw pays once in Full Send")
local beam={SpawnerEntity=p,FrameCount=6,GetData=function() return {} end,IsCircleLaser=function() return false end}
tick(); fire("MC_POST_LASER_UPDATE",beam); assert(state().credits==74,"a held beam pays per window")
state().credits=76

-- At zero Full Send returns to Standard and cannot be re-entered.
state().credits=1; tick(); shot(p)
assert(state().credits==0 and not state().fullSend); near(p.Damage,10)
tap(p); assert(not state().fullSend,"no credits, no Full Send")

-- Three unique combat clears bank one reset; progress pauses while banked.
enter(2,true); finish(); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().clears==1,"duplicate awards are ignored")
enter(3,false); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().clears==1,"a peaceful room is not a clear")
enter(2,true); finish(); assert(state().clears==1,"re-entry cannot farm")
enter(4,true); finish(); enter(5,true); finish()
assert(state().ready and state().clears==0 and texts[#texts]=="Reset Ready")
assert(hud()=="Credits 0/80  Standard  Tibo: Reset Ready",hud())
enter(6,true); finish(); enter(7,true); finish()
assert(state().clears==0 and state().ready,"progress pauses while a reset is banked")

-- DROP claims the reset before any toggle.
down[0]=true; tick(20); down[0]=false; tick(); assert(state().ready,"a long hold keeps native DROP")
tap(p); assert(not state().ready and state().credits==80 and not state().fullSend,"the reset refills without toggling")
tap(p); assert(state().fullSend,"the next tap toggles")
enter(9,true); finish(); assert(state().clears==1,"progress resumes after the claim")

-- Birthright raises the cap and refill to 100 and clamps when lost.
state().ready=true; p.birthright=true; tap(p); assert(state().credits==100)
assert(hud()=="Credits 100/100  Full Send  Next Reset 1/3",hud())
p.birthright=false; tick(); assert(state().credits==80,"losing Birthright clamps to 80")

-- Floors and continue preserve credits, mode, progress and a banked reset.
state().credits=33; state().ready=true; state().clears=0
floor=20; enter(1,false)
assert(state().credits==33 and state().fullSend and state().ready and next(state().awards)==nil)
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]; tick()
assert(state().credits==33 and state().fullSend and state().ready,"continue preserves the allowance")
near(p.Damage,15)

-- Real time does nothing: pause and idle frames change no state.
paused=true; tick(600); paused=false; tick(600); assert(state().credits==33)

-- Identity and character changes do not transfer the allowance.
players[1]=player(101,999,0); p=players[1]; tick(); assert(state().credits==80 and not state().ready)
p.kind=51; tick(); assert(state()==nil)
tick(); shot(p); p:EvaluateItems(); near(p.Damage,10)
p.kind=151; tick(); assert(state().credits==80)

-- Corrupt saves are discarded.
Risk.state.gptReset["0"]={version=1,credits=500,fullSend=true,clears=0,ready=false,awards={}}
tick(); assert(state().credits==80 and not state().fullSend)

fire("MC_POST_GAME_STARTED",false); assert(state().credits==80 and not state().ready)
-- Waiting for Tibo: combat taps toggle modes but retain the banked refill.
fire("MC_POST_GAME_STARTED",false); enter(100,true)
state().credits=20; state().ready=true
local partnerCredits=state(1).credits
tap(p); assert(state().ready and state().credits==20 and state().fullSend,"combat cannot claim the reset")
near(p.Damage,15); assert(hud():find("after combat"),hud())
tap(p); assert(state().ready and state().credits==20 and not state().fullSend)
assert(state(1).credits==partnerCredits,"the banked restriction is personal")
reload({player(201,999,0),player(202,22,1)}); p,q=players[1],players[2]
assert(state().ready and state().credits==20,"continue retains the banked reset")
finish(); tap(p); assert(not state().ready and state().credits==80 and not state().fullSend)
print("OK: Reset Watcher Credits, Full Send payments, banked Tibo reset, Birthright and save/floor/identity lifecycle")
