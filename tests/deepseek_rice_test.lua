-- Real Rice, MealBreak and DROP callbacks with detached save/continue snapshots.
local root=arg[1]
local frame, paused, clear, room, floor = 0, false, true, 1, 10
local callbacks, players, saved, draws = {}, {}, nil, {}
local C={RISK_MAX=100,Player={DEEPSEEK_CHAN=42},Item={LUNCH_BREAK=749}}
function include(name)
    if name=="scripts.constants" then return C end
    if name=="scripts.characters.model_roster" then return {Find=function() end} end
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
EffectVariant={TARGET=30,ROCKET=31}
ModCallbacks=setmetatable({}, {__index=function(_,k) return k end})
TearFlags={TEAR_LUDOVICO="ludo"}
CacheFlag={CACHE_SPEED=1}; CollectibleType={COLLECTIBLE_BIRTHRIGHT=619}
ButtonAction={ACTION_DROP=11,ACTION_SHOOTLEFT=4,ACTION_SHOOTRIGHT=5,ACTION_SHOOTUP=6,ACTION_SHOOTDOWN=7}
InputHook={IS_ACTION_PRESSED=0,IS_ACTION_TRIGGERED=1,GET_ACTION_VALUE=2}
local down={}
Input={IsActionPressed=function(_,controller) return down[controller] or false end}
function GetPtrHash(p) return p.pointer end
function Game() return {
    GetFrameCount=function() return frame end, GetNumPlayers=function() return #players end,
    IsPaused=function() return paused end,
    GetRoom=function() return {IsClear=function() return clear end} end,
    GetLevel=function() return {
        GetDungeonPlacementSeed=function() return floor end,
        GetStage=function() return 1 end,GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=room*13,SafeGridIndex=room} end,
    } end,
    GetHUD=function() return {IsVisible=function() return true end} end,
} end
Isaac={GetPlayer=function(i) return players[i+1] end,GetScreenHeight=function() return 270 end,GetScreenWidth=function() return 480 end}
local mod={AddCallback=function(_,id,fn) callbacks[#callbacks+1]={id=id,fn=fn} end}
function mod:SaveData(s) self.saved=s end
function mod:LoadData() return self.saved end
function mod:HasData() return saved~=nil end
local function fire(id,...)
    local result
    for _,cb in ipairs(callbacks) do if cb.id==id then
        local value=cb.fn(mod,...); if value~=nil then result=value end
    end end
    return result
end
local function player(pointer,seed,controller)
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=42,
        FireDelay=0,MoveSpeed=1,hearts=2,charge=2,dead=false,controls=true,shooting=false}
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return self.controls end
    function p:HasCollectible(id) return id==619 and self.birthright end
    function p:GetMovementInput() return {LengthSquared=function() return self.moving and 1 or 0 end} end
    function p:GetShootingInput() return {LengthSquared=function() return self.shooting and 1 or 0 end} end
    function p:AddCacheFlags() end
    function p:EvaluateItems() self.MoveSpeed=1; fire("MC_EVALUATE_CACHE",self,1) end
    return p
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
    include("scripts.characters.deepseek_rice"):Init(mod,Risk,Meal)
end
local function tick(n)
    for _=1,n or 1 do
        if not paused then for _,p in ipairs(players) do p.FireDelay=math.max(0,p.FireDelay-1) end end
        frame=frame+1; fire("MC_POST_UPDATE")
    end
end
local function state(i) return Risk.state.deepseekRice[tostring(i or 0)] end
local function tap(p)
    down[p.ControllerIndex]=false; tick()
    down[p.ControllerIndex]=true; tick()
    down[p.ControllerIndex]=false; tick()
end
local function enter(index,hostile)
    room=index; clear=not hostile; fire("MC_POST_NEW_ROOM")
end
local function complete()
    clear=true; fire("MC_PRE_SPAWN_CLEAN_AWARD")
end
local function shot(p)
    local data={}
    local t={SpawnerEntity=p,CollisionDamage=4,Scale=1.7,TearFlags=1<<52,
        GetData=function() return data end, Exists=function() return true end,
        HasTearFlags=function() return false end}
    fire("MC_POST_FIRE_TEAR",t)
    return t
end
players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
assert(state().bowls==1 and state(1).bowls==1)
tick(150)
assert(state().thought==150 and p.charge==2,"idle builds Thought, never pocket charge")
local t=shot(p); local pellet=shot(p)
assert(t.CollisionDamage==8 and pellet.CollisionDamage==8,"every pellet in the volley receives Thought")
assert(t.Scale==1.7 and t.TearFlags==1<<52,"preserve native visual/effect fields")
fire("MC_POST_FIRE_TEAR",t); assert(t.CollisionDamage==8,"duplicate callbacks must not multiply twice")
assert(state().thought==0 and state(1).thought==150,"spending is personal")
local removed={SpawnerEntity=q,Exists=function() return false end}
fire("MC_POST_FIRE_TEAR",removed)
assert(state(1).thought==150,"a previously cancelled attack must not spend another player's Thought")
p.shooting=true; tick(30); assert(state().thought==0,"held shooting does not recharge Thought")
assert(shot(p).CollisionDamage==4)
p.shooting=false
tap(p)
assert(state().bowls==0 and state().lunch and Meal:Remaining(p)==60)
assert(p.hearts==2 and p.charge==2,"intrinsic meal neither heals nor spends active charge")
assert(fire("MC_INPUT_ACTION",p,0,4)==false and fire("MC_INPUT_ACTION",q,0,4)==nil)
tick(20); tap(p); assert(state().bowls==0 and Meal:Remaining(p)==37,"cannot restart an existing meal")
paused=true; tick(15); assert(Meal:Remaining(p)==37)
paused=false
fire("MC_PRE_GAME_EXIT",true)
players={player(101,111,0),player(102,222,1)}; p,q=players[1],players[2]; frame=0
load(); fire("MC_POST_GAME_STARTED",true)
assert(state().lunch and Meal:Remaining(p)==37 and state().bowls==0,"continue restores one pending meal")
tick(36); assert(p.MoveSpeed==1 and state().lunch)
tick(); assert(not state().lunch and state().thought==150 and state().speed==180 and p.MoveSpeed==1.15)
fire("MC_POST_UPDATE"); assert(state().speed==180,"duplicate frame cannot advance speed timer")
paused=true; tick(10); paused=false; assert(state().speed==180)
enter(2,false); complete(); assert(state().clears==0,"empty-room fake clear gives no rice")
enter(3,true); complete(); complete(); assert(state().clears==1 and state().bowls==0)
enter(2,false); enter(3,true); complete(); assert(state().clears==1,"re-entered or repopulated room cannot pay twice")
enter(4,true); complete(); assert(state().bowls==1 and state().clears==0)
fire("MC_PRE_GAME_EXIT",true)
load(); fire("MC_POST_GAME_STARTED",true); complete()
assert(state().bowls==1 and state().clears==0,"awards survive continue")
tick(180); assert(state().speed==0 and p.MoveSpeed==1,"speed expires through cache evaluation")
for i=5,10 do enter(i,true); complete() end
assert(state().bowls==2 and state().clears==0,"bowl cap and cadence remain bounded")
-- Native hold stays untouched, and an interrupted press cannot eat on release.
down[0]=true; tick(20); down[0]=false; tick(); assert(state().bowls==2)
down[0]=true; tick(); paused=true; fire("MC_POST_RENDER"); paused=false
down[0]=false; tick(); assert(state().bowls==2)
Meal:Start(p,90); tap(p)
assert(state().bowls==2 and not state().lunch,"the charged active's meal must block spending rice")
tick(87); assert(Meal:Remaining(p)==0 and state().speed==0,"an active-only meal does not grant the rice reward")
p.birthright=true; tap(p); assert(Meal:Remaining(p)==30)
tick(5); Meal:Start(p,90); tick(30)
assert(state().lunch and Meal:Remaining(p)==60,"a food refresh postpones the single meal payout")
p.dead=true; tick(); assert(not state().lunch and state().speed==0 and state().thought==0)
p.dead=false; tick(); assert(p.MoveSpeed==1,"death must not complete the meal")
-- Replacement identity does not inherit saved rewards, timers or gestures.
players[1]=player(101,999,0); p=players[1]; tick()
assert(state().bowls==1 and state().speed==0 and not state().lunch)
p.kind=0; tick(); assert(state()==nil)
p.kind=42; tick(); assert(state().bowls==1 and state().thought==0)
q.dead=true; enter(11,true); complete(); assert(state(1).clears==0,"dead co-op players do not earn clears")
floor=20; enter(3,true); complete(); assert(state().bowls==2,"same room index on a new floor is eligible")
-- A partial hostile room survives saving without converting a safe room into combat.
enter(12,true); fire("MC_PRE_GAME_EXIT",true); load(); fire("MC_POST_GAME_STARTED",true)
complete(); assert(state().clears==1)
fire("MC_POST_RENDER"); assert(draws[#draws]:match("Thought") and draws[#draws]:match("Rice"))
Risk.state.deepseekRice["0"]={version=1,bowls=math.huge,thought=0/0,speed=-10,clears="bad",lunch=true}
tick(); assert(state().bowls==1 and state().speed==0 and not state().lunch)
fire("MC_POST_GAME_STARTED",false); assert(state().bowls==1 and state().thought==0)
tick(37); fire("MC_PRE_GAME_EXIT",true); load(); fire("MC_POST_GAME_STARTED",true)
assert(state().thought==37,"continue retains partial Thought rather than real-time elapsed time")

-- O1 regression: multi-pocket DROP keeps native input without spending Rice.
-- The simulated rotation is a fixture input, not observed engine ordering.
for _, pockets in ipairs({'card-active','card-pill'}) do
    for _, nativeFirst in ipairs({true,false}) do
        players={player(201,2011,0),player(202,2022,1)}
        p,q=players[1],players[2]; frame=0; paused=false; down={}
        p.selectedPocket=0
        function p:GetCard(slot) return slot==0 and 1 or 0 end
        function p:GetPill(slot) return pockets=='card-pill' and slot==1 and 1 or 0 end
        function p:GetActiveItem(slot) return pockets=='card-active' and slot==2 and C.Item.LUNCH_BREAK or 0 end
        load(); fire('MC_POST_GAME_STARTED',false); tick()
        local function nativeDropPoll()
            for _,hook in ipairs({0,1,2}) do
                assert(fire('MC_INPUT_ACTION',p,hook,ButtonAction.ACTION_DROP)==nil,
                    'current modules must leave native DROP input unmodified')
            end
            -- Model one native selection change, separately from mod callbacks.
            p.selectedPocket=1-p.selectedPocket
        end
        down[0]=true
        if nativeFirst then nativeDropPoll() end
        tick()
        if not nativeFirst then nativeDropPoll() end
        assert(state().bowls==1, 'press itself must not spend Rice')
        down[0]=false; tick()
        assert(p.selectedPocket==1 and state().bowls==1 and Meal:Remaining(p)==0,
            'native pocket rotation must not also start a meal')
        assert(state(1).bowls==1 and Meal:Remaining(q)==0, 'other controller stays independent')
    end
end
-- A long hold remains a separate control: no meal on release and no native
-- DROP hook overridden. Actual item dropping still requires an engine run.
players={player(301,3011,0)}; p=players[1]; frame=0; down={}
load(); fire('MC_POST_GAME_STARTED',false); tick()
down[0]=true
for _=1,20 do
    assert(fire('MC_INPUT_ACTION',p,InputHook.IS_ACTION_PRESSED,ButtonAction.ACTION_DROP)==nil)
    tick()
end
down[0]=false; tick()
assert(state().bowls==1 and Meal:Remaining(p)==0, 'long hold must not start a meal')
print('O1: multi-pocket DROP preserves Rice offline; native input acceptance remains pending')
print("OK: Rice economy, native DROP observer, meal/save lifecycle, volley ownership and untouched tear effects")

-- Intrinsic Rice refunds exactly its own bowl on voluntary movement.
players={player(501,5011,0),player(502,5022,1)}; p,q=players[1],players[2]; frame=0; down={}; paused=false
load(); fire("MC_POST_GAME_STARTED",false); tap(p); tap(q)
local before=state().thought; p.moving=true; tick()
assert(state().bowls==1 and not state().lunch and Meal:Remaining(p)==0,"movement cancels intrinsic Rice")
assert(p.FireDelay==0 and state().speed==0 and state().thought==before,"no meal reward or stale firing delay")
assert(state(1).lunch and Meal:Remaining(q)>0 and state(1).bowls==0,"only the moving owner cancels")
fire("MC_POST_UPDATE"); assert(state().bowls==1,"duplicate callback cannot refund twice")
p.moving=false; p.FireDelay=200; tap(p); p.moving=true; local oldDelay=p.FireDelay; tick()
assert(p.FireDelay==oldDelay-1,"a longer external firing delay is not erased")
p.moving=false; p.FireDelay=0; tap(p); tick(5)
fire("MC_PRE_GAME_EXIT",true); players={player(601,5011,0),player(602,5022,1)};p,q=players[1],players[2];frame=0
load(); fire("MC_POST_GAME_STARTED",true); p.moving=true; tick()
assert(state().bowls==1 and Meal:Remaining(p)==0,"owned cancellation works after continue")
-- A later food effect supersedes Rice's timer ownership, so cancellation cannot erase it.
p.moving=false; tap(p); Meal:Start(p,90); p.moving=true; tick()
assert(state().bowls==1 and not state().lunch and Meal:Remaining(p)==89,"unrelated food restriction remains")
assert(fire("MC_INPUT_ACTION",p,0,4)==false and state().speed==0)
tick(90); assert(state().speed==0,"cancelled Rice never completes through another meal")
print("OK: Rice movement cancellation, ownership, one refund, continue and external food/delay isolation")

-- Reject a moving start, retain a genuine pre-meal cooldown, and clamp a refund at two.
p.moving=true; local bowls=state().bowls; tap(p); assert(state().bowls==bowls and not state().lunch)
p.moving=false; p.FireDelay=20; tap(p); tick(5); p.moving=true; tick()
assert(p.FireDelay==11,"cancellation restores only the remaining pre-meal delay")
p.moving=false; p.FireDelay=0; tap(p); state().bowls=2; p.moving=true; tick(); assert(state().bowls==2)
