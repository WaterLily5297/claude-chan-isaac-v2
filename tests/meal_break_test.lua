-- Real item/pill/input callbacks, detached saves and fresh player wrappers.
local root, oldItem = arg[1], arg[2]
local callbacks, players, frame, paused, saved = {}, {}, 0, false, nil
local C = {RISK_MAX=100,Item={LUNCH_BREAK=749}, Pill={GETTING_FOOD=51, CAT_GIRL=50}}
function include(name)
    if name == "scripts.constants" then return C end
    if name == "scripts.characters.model_roster" then return { Find = function() end } end
    if name == "scripts.hud_text" then return {} end
    return dofile(root.."/"..name:gsub("%.","/")..".lua")
end
local function copy(v)
    if type(v) ~= "table" then return v end
    local result = {}; for k,x in pairs(v) do result[k]=copy(x) end; return result
end
package.preload.json = function() return {
    encode=function(v) saved=copy(v); return "snapshot" end,
    decode=function() return copy(saved) end,
} end
ModCallbacks=setmetatable({}, {__index=function(_,k) return k end})
ButtonAction={ACTION_SHOOTLEFT=4,ACTION_SHOOTRIGHT=5,ACTION_SHOOTUP=6,ACTION_SHOOTDOWN=7,
    ACTION_LEFT=0,ACTION_BOMB=8,ACTION_ITEM=9,ACTION_PILLCARD=10,ACTION_DROP=11,ACTION_MAP=12,ACTION_MENUCONFIRM=13}
InputHook={IS_ACTION_PRESSED=0,IS_ACTION_TRIGGERED=1,GET_ACTION_VALUE=2}
UseFlag={USE_CARBATTERY=32}; EntityFlag={FLAG_FRIENDLY=1}
CacheFlag={CACHE_DAMAGE=1,CACHE_FIREDELAY=2}
function Color(...) return {...} end
function EntityRef(p) return p end
function GetPtrHash(p) return p.pointer end
local function player(pointer,seed)
    local p={pointer=pointer,InitSeed=seed,FireDelay=0,hearts=0,dead=false,data={}}
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:AddHearts(n) self.hearts=self.hearts+n end
    function p:GetData() return self.data end
    function p:AddCacheFlags() end
    function p:EvaluateItems() end
    return p
end
local slows, messages, scans = 0, 0, 0
local foe={ToNPC=function(s) return s end,IsVulnerableEnemy=function() return true end,
    HasEntityFlags=function() return false end,
    AddSlowing=function(_,owner,frames) assert(owner==players[1] and frames==90); slows=slows+1 end}
Isaac={GetPlayer=function(i) scans=scans+1; return players[i+1] end,
    GetRoomEntities=function() return {foe} end}
function Game() return {GetNumPlayers=function() return #players end,
    GetFrameCount=function() return frame end,IsPaused=function() return paused end,
    GetHUD=function() return {ShowItemText=function() messages=messages+1 end} end} end
local mod={AddCallback=function(_,id,fn,param) callbacks[#callbacks+1]={id=id,fn=fn,param=param} end}
function mod:SaveData(s) self.saved=s end
function mod:HasData() return saved~=nil end
function mod:LoadData() return self.saved end
local function fire(id,...)
    local result
    for _,cb in ipairs(callbacks) do
        local filter=id=="MC_USE_ITEM" or id=="MC_USE_PILL"
        if cb.id==id and (not filter or cb.param==nil or cb.param==select(1,...)) then
            local value=cb.fn(mod,...); if value~=nil then result=value end
        end
    end
    return result
end
local Risk=include("scripts.risk")
local Meal
local function load()
    callbacks={}
    mod:AddCallback("MC_POST_GAME_STARTED",function(_,continued)
        if continued then Risk:Load(mod) else Risk.state={} end
    end)
    mod:AddCallback("MC_PRE_GAME_EXIT",function(_,save) if save then Risk:Save(mod) end end)
    Meal=include("scripts.meal_break"); Meal:Init(mod,Risk)
    local item = oldItem and dofile(oldItem) or include("scripts.items.lunch_break")
    item:Init(mod,Meal)
    include("scripts.pills"):Init(mod,Meal)
end
local function use(p,flags) return fire("MC_USE_ITEM",749,nil,p,flags or 0) end
local function input(p,hook,action) return fire("MC_INPUT_ACTION",p,hook,action or 4) end
local function tick(count)
    for _=1,count do
        frame=frame+1
        for _,p in ipairs(players) do p.FireDelay=math.max(0,p.FireDelay-1) end
        fire("MC_POST_UPDATE")
    end
end
local function wrap(p) return setmetatable({}, {__index=p,__newindex=p}) end
players={player(1,11),player(2,22)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
use(p,32)
assert(p.hearts==0 and slows==0,"Car Battery must not duplicate the food heal or slowdown")
assert(use(p).Discharge and p.hearts==2 and slows==1 and messages==1)
assert(Meal:Remaining(p)==90 and p.FireDelay==90)
assert(not use(wrap(p)).Discharge and p.hearts==2,"an ongoing meal cannot be bought again")
assert(Meal:Remaining(q)==0)
local scansBefore=scans
for action=4,7 do
    assert(input(wrap(p),0,action)==false and input(p,1,action)==false and input(p,2,action)==0)
end
assert(scans==scansBefore,"hot input polling must not scan players or mutate bindings")
for _,action in ipairs({0,8,9,10,11,12,13}) do assert(input(p,0,action)==nil) end
assert(input(q,0)==nil and input(nil,0)==nil and input({ToPlayer=function() end},0)==nil)
assert(input(p,99)==nil)
fire("MC_POST_UPDATE"); assert(Meal:Remaining(p)==90,"use frame must not consume a countdown tick")
tick(17); assert(Meal:Remaining(p)==73)
fire("MC_POST_UPDATE"); assert(Meal:Remaining(p)==73,"duplicate update must not consume time")
paused=true; tick(50); assert(Meal:Remaining(p)==73 and input(p,0)==nil)
paused=false; fire("MC_POST_NEW_ROOM"); fire("MC_POST_NEW_LEVEL")
assert(Meal:Remaining(p)==73,"room/floor transitions must not erase food debt")
fire("MC_USE_PILL",51,q)
assert(q.hearts==2 and Meal:Remaining(q)==90,"food pill shares the per-player lockout")
fire("MC_PRE_GAME_EXIT",true)
assert(input(p,0)==nil and not use(p).Discharge,"no effects may run after exit")
-- Simulate process restart: new module, entity identities and detached save state.
players={player(101,111),player(102,222)}; p,q=players[1],players[2]; frame=0
load(); fire("MC_POST_NEW_ROOM"); fire("MC_POST_GAME_STARTED",true)
assert(Meal:Remaining(p)==73 and Meal:Remaining(q)==90)
assert(input(p,2)==0 and p.FireDelay==73,"restore input and delay before the first update")
tick(72); assert(Meal:Remaining(p)==1 and input(p,0)==false)
tick(1); assert(Meal:Remaining(p)==0 and input(p,0)==nil and p.FireDelay==0)
assert(Meal:Remaining(q)==17,"co-op meal clocks must remain independent")
q.FireDelay=200; fire("MC_USE_PILL",51,q)
assert(Meal:Remaining(q)==90 and q.FireDelay==200,"a new meal must not shorten another cooldown")
PillColor={PILL_GIANT_FLAG=2048}
local before=q.hearts; fire("MC_USE_PILL",51,q,0,3|2048)
assert(q.hearts==before+4,"a horse Getting Food heals two hearts")
before=q.hearts; fire("MC_USE_PILL",51,q,0,3)
assert(q.hearts==before+2,"a normal pill heals one heart"); PillColor=nil
tick(90); assert(input(q,0)==nil and q.FireDelay==110)
assert(use(p).Discharge); tick(3)
frame=frame-10; fire("MC_POST_UPDATE")
assert(Meal:Remaining(p)==87,"frame rollback must not erase or advance saved time")
-- Same pointer with another seed is a replacement, not another Lua wrapper.
local impostor=player(p.pointer,p.InitSeed+1)
assert(input(impostor,0)==nil)
players[1]=impostor; fire("MC_POST_UPDATE")
assert(Meal:Remaining(impostor)==0)
assert(use(impostor).Discharge); impostor.dead=true; fire("MC_POST_UPDATE")
assert(Meal:Remaining(impostor)==0 and input(impostor,0)==nil)
impostor.dead=false
players={}; fire("MC_POST_UPDATE")
players={player(3,33)}; fire("MC_POST_UPDATE")
assert(Meal:Remaining(players[1])==0,"a new co-op player must not inherit a departed meal")
-- Save migration and corrupt bounds fail closed to no meal, never a permanent lockout.
saved.mealBreaks={['0']={version=1,remaining=-1}}
load(); fire("MC_POST_GAME_STARTED",true); assert(Meal:Remaining(players[1])==0)
saved.mealBreaks={['0']={version=1,remaining=math.huge}}
load(); fire("MC_POST_GAME_STARTED",true); assert(Meal:Remaining(players[1])==0)
saved.mealBreaks=nil
load(); fire("MC_POST_GAME_STARTED",true); assert(Meal:Remaining(players[1])==0)
fire("MC_USE_PILL",51,players[1]); assert(Meal:Remaining(players[1])==90)
fire("MC_POST_GAME_STARTED",false); assert(Meal:Remaining(players[1])==0)
print("OK: food input isolation, Car Battery, saved countdowns, pause, expiry and co-op identity")
