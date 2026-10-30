-- Real Risk, MealBreak and Rice/Thought across supplied co-op and save boundaries.
-- Snapshot JSON rejects runtime objects; it does not execute the native serializer.
local root, selected = assert(arg[1]), arg[2]
local callbacks, players, saved, frame, paused, down = {}, {}, nil, 0, false, {}
local Risk, Meal
local C = {Player={DEEPSEEK_CHAN=42, CLAUDE_CHAN=41, CLAUDE_CHAN_B=43}, Item={}}
function C.IsDeepSeek(p) return p:GetPlayerType()==42 end
function include(name)
    if name=="scripts.constants" then return C end
    if name=="scripts.characters.model_roster" then return {IsFamily=function() return false end} end
    if name=="scripts.hud_text" then return {Draw=function() end} end
    return dofile(root.."/"..name:gsub("%.","/")..".lua")
end
local function copy(value, seen)
    local kind=type(value)
    if kind=="table" then
        seen=seen or {}; assert(not seen[value], "cyclic save state")
        assert(getmetatable(value)==nil, "runtime object in save state")
        seen[value]=true
        local result={}
        for k,v in pairs(value) do
            assert(type(k)=="string" or type(k)=="number", "non-scalar save key")
            assert(k~="pointer" and k~="InitSeed" and k~="ref", "transient owner/entity in save")
            result[k]=copy(v,seen)
        end
        seen[value]=nil; return result
    end
    assert(kind=="nil" or kind=="string" or kind=="boolean"
        or (kind=="number" and value==value and math.abs(value)<math.huge), "non-JSON save value")
    return value
end
package.preload.json=function() return {
    encode=function(value) saved=copy(value); return "snapshot" end,
    decode=function() return copy(saved) end,
} end
ModCallbacks=setmetatable({}, {__index=function(_,k) return k end})
CallbackPriority={EARLY=-100,LATE=1000}
EntityType={ENTITY_PLAYER=1,ENTITY_LASER=7,ENTITY_KNIFE=8}
EffectVariant={TARGET=30,ROCKET=31}
CacheFlag={CACHE_SPEED=1,CACHE_DAMAGE=2}
CollectibleType={COLLECTIBLE_BIRTHRIGHT=619}
TearFlags={TEAR_LUDOVICO="ludo"}
ButtonAction={ACTION_DROP=11,ACTION_SHOOTLEFT=4,ACTION_SHOOTRIGHT=5,ACTION_SHOOTUP=6,ACTION_SHOOTDOWN=7}
InputHook={IS_ACTION_PRESSED=0,IS_ACTION_TRIGGERED=1,GET_ACTION_VALUE=2}
Input={IsActionPressed=function(_,controller) return down[controller] or false end}
function GetPtrHash(entity) return entity.pointer end
function EntityPtr(entity) return setmetatable({}, {__index=function(_,k)
    if k=="Ref" and entity:Exists() then return entity end
end}) end
function Game() return {
    GetFrameCount=function() return frame end, GetNumPlayers=function() return #players end,
    IsPaused=function() return paused end,
    GetRoom=function() return {IsClear=function() return true end} end,
    GetLevel=function() return {
        GetDungeonPlacementSeed=function() return 10 end,
        GetStage=function() return 1 end, GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=13,SafeGridIndex=1} end,
    } end,
} end
Isaac={GetPlayer=function(i) return players[i+1] end}
local mod={}
function mod:AddCallback(id,fn) callbacks[#callbacks+1]={id=id,fn=fn} end
function mod:AddPriorityCallback(id,_,fn) self:AddCallback(id,fn) end
function mod:SaveData(value) self.saved=value end
function mod:HasData() return saved~=nil end
function mod:LoadData() return self.saved end
local function fire(id,...)
    local result
    for _,cb in ipairs(callbacks) do if cb.id==id then
        local value=cb.fn(mod,...); if value~=nil then result=value end
    end end
    return result
end
local function player(pointer,seed,controller,kind)
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=kind or 42,
        FireDelay=0,MoveSpeed=1,MaxFireDelay=0,shooting=false,moving=false,dead=false}
    function p:GetPlayerType() return self.kind end
    function p:ToPlayer() return self end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return true end
    function p:HasCollectible(id) return id==619 and self.birthright end
    function p:GetMovementInput() return {LengthSquared=function() return self.moving and 1 or 0 end} end
    function p:GetShootingInput() return {LengthSquared=function() return self.shooting and 1 or 0 end} end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:AddCacheFlags() end
    function p:EvaluateItems() self.MoveSpeed=1; fire("MC_EVALUATE_CACHE",self,1) end
    return p
end
local function load()
    callbacks={}
    Risk=include("scripts.risk"); Risk:Init(mod)
    Meal=include("scripts.meal_break"); Meal:Init(mod,Risk)
    include("scripts.characters.deepseek_rice"):Init(mod,Risk,Meal)
end
local function fresh()
    frame=0; paused=false; down={}
    players={player(1,11,0),player(2,22,1),player(3,33,2,0)}
    load(); fire("MC_POST_GAME_STARTED",false)
    return players[1],players[2],players[3]
end
local function tick(count)
    for _=1,count or 1 do
        if not paused then for _,p in ipairs(players) do p.FireDelay=math.max(0,p.FireDelay-1) end end
        frame=frame+1; fire("MC_POST_UPDATE")
    end
end
local function rice(p)
    for i,owner in ipairs(players) do
        if owner.pointer==p.pointer then return Risk.state.deepseekRice[tostring(i-1)] end
    end
end
local function tap(p)
    down[p.ControllerIndex]=false; tick()
    down[p.ControllerIndex]=true; tick()
    down[p.ControllerIndex]=false; tick()
end
local function blocked(p) return fire("MC_INPUT_ACTION",p,InputHook.GET_ACTION_VALUE,4)==0 end
local function weapon(p,id,kind)
    local data={}
    local e={SpawnerEntity=p,pointer=id,InitSeed=id,Type=kind or 8,CollisionDamage=4,flying=true}
    function e:GetData() return data end
    function e:Exists() return true end
    function e:IsFlying() return self.flying end
    function e:IsCircleLaser() return false end
    return e
end
local count=0
local function case(name,fn)
    if not selected or selected==name then fn(); count=count+1 end
end

case("meal_move",function()
    local p,q,r=fresh()
    Meal:Start(p,60); Meal:Start(q,90); tick(9)
    players={q,r,p}; fire("MC_POST_UPDATE")
    assert(Meal:Remaining(p)==51 and Meal:Remaining(q)==81,
        "same live owners must keep their meal debt when slots move")
    assert(blocked(p) and blocked(q) and not blocked(r), "input lock follows only its owner")
    tick(); assert(Meal:Remaining(p)==50 and Meal:Remaining(q)==80, "move must not restart the clock")
end)

case("rice_move",function()
    local p,q,r=fresh(); tick(41)
    rice(p).bowls=2; rice(p).clears=1; rice(p).awards.kept=true
    rice(q).bowls=0; rice(q).thought=17
    local a,b=rice(p),rice(q)
    players={q,r,p}; fire("MC_POST_UPDATE")
    assert(rice(p)==a and rice(q)==b and rice(p).thought==41 and rice(q).thought==17,
        "slot moves must preserve each live owner's Rice progress")
    assert(rice(p).awards.kept and rice(p).bowls==2 and rice(q).bowls==0)
    tick(); assert(rice(p).thought==42 and rice(q).thought==18, "move must preserve update deduplication")
end)

case("cycle_save",function()
    local p,q,r=fresh(); tap(p); tick(7); Meal:Start(q,90)
    local a,b=rice(p),rice(q)
    for _,order in ipairs({{q,r,p},{r,p,q},{p,q,r}}) do
        players=order; fire("MC_POST_UPDATE")
        assert(rice(p)==a and rice(q)==b and a.lunch and a.bowls==0)
        assert(Meal:Remaining(p)==53 and Meal:Remaining(q)==90, "cyclic move is atomic")
    end
    players={q,p,r}; fire("MC_POST_UPDATE")
    fire("MC_PRE_GAME_EXIT",true)
    assert(saved.deepseekRice["1"].lunch and saved.deepseekRice["1"].bowls==0)
    assert(saved.mealBreaks["1"].remaining==53 and saved.mealBreaks["0"].remaining==90)
    -- Recreated identities bind saved slot order after a process-style reload.
    q,p,r=player(102,222,0),player(101,111,1),player(103,333,2,0)
    players={q,p,r}; frame=0; load(); fire("MC_POST_GAME_STARTED",true)
    assert(Meal:Remaining(p)==53 and Meal:Remaining(q)==90 and rice(p).lunch)
    tick(53)
    assert(rice(p).speed==180 and rice(p).thought==150 and not rice(p).lunch)
    assert(rice(q).speed==0 and Meal:Remaining(q)==37, "unowned timer must not grant Rice rewards")
    fire("MC_POST_UPDATE"); assert(rice(p).speed==180, "reward only once")
end)

case("owned_cancel",function()
    local p,q,r=fresh(); tap(p); tick(7); Meal:Start(q,90)
    players={r,q,p}; fire("MC_POST_UPDATE")
    p.moving=true; tick()
    assert(rice(p).bowls==1 and not rice(p).lunch and Meal:Remaining(p)==0)
    assert(p.FireDelay==0 and Meal:Remaining(q)==89, "move retains the owned delay cancellation lease")
    tick(); assert(rice(p).bowls==1, "movement refunds at most once")
    p.moving=false; tap(p); p.FireDelay=200
    players={q,p,r}; fire("MC_POST_UPDATE"); p.moving=true; tick()
    assert(p.FireDelay==199 and Meal:Remaining(p)==0, "foreign cooldown survives cancellation after move")
end)

case("identity",function()
    local p,q,r=fresh(); tick(37); tap(p)
    local old=rice(p)
    players[1]=setmetatable({}, {__index=p,__newindex=p}); fire("MC_POST_UPDATE")
    assert(rice(p)==old and Meal:Remaining(p)==60, "another Lua wrapper is the same live owner")
    players[1]=p
    p.ControllerIndex=7; down[7]=true; tick()
    down[7]=false; tick()
    assert(rice(p)==old and old.bowls==0, "controller reassignment must not spend another bowl")
    p.kind=0; tick(); assert(rice(p)==nil and Meal:Remaining(p)>0,
        "type departure retires Rice rewards but retains the shared food debt")
    p.kind=42; tick(); assert(rice(p).bowls==1 and not rice(p).lunch and rice(p).thought==0)
    local formerQ=rice(q)
    players={q,r}; fire("MC_POST_UPDATE")
    assert(rice(q)==formerQ and Risk.state.deepseekRice["2"]==nil and Risk.state.mealBreaks["2"]==nil)
    local replacement=player(q.pointer,q.InitSeed+100,1)
    players[1]=replacement; fire("MC_POST_UPDATE")
    assert(rice(replacement).thought==0 and Meal:Remaining(replacement)==0, "reused pointer with new seed starts fresh")
    tick(23); Meal:Start(replacement,60)
    replacement=player(400,replacement.InitSeed,1)
    players[1]=replacement; fire("MC_POST_UPDATE")
    assert(rice(replacement).thought==0 and Meal:Remaining(replacement)==0, "new pointer with reused seed also starts fresh")
    players[3]=p; fire("MC_POST_UPDATE")
    assert(rice(p).bowls==1 and Meal:Remaining(p)==0, "observed departure cannot park an old meal for a later join")
    fire("MC_PRE_GAME_EXIT",true)
    players={player(201,211,0),player(202,222,1,0),player(203,233,2)}
    fire("MC_POST_GAME_STARTED",true)
    assert(rice(players[1]).thought==0 and Meal:Remaining(players[3])==0, "same-session Continue clears live identities")
end)

case("paused_window",function()
    local p,q,r=fresh()
    local fourth=player(4,44,3); players[4]=fourth; fire("MC_POST_UPDATE")
    tick(150); p.shooting=true; Meal:Start(q,60)
    local beam=weapon(p,1010,7); fire("MC_POST_LASER_UPDATE",beam)
    assert(beam.CollisionDamage==8 and rice(p).windowRemaining==6)
    paused=true; players={fourth,p,r,q}; tick(5)
    assert(rice(p).windowRemaining==6 and Meal:Remaining(q)==60, "paused moves preserve both clocks")
    paused=false
    for _=1,6 do
        fire("MC_POST_LASER_UPDATE",beam); assert(beam.CollisionDamage==8)
        tick()
    end
    fire("MC_POST_LASER_UPDATE",beam)
    assert(beam.CollisionDamage==4 and Meal:Remaining(q)==54,
        "a moved window expires on its original clock instead of restarting")
    assert(rice(fourth).thought==150 and rice(q).thought==150, "partners keep their own Thought")
end)

case("knife_exit",function()
    local p,q,r=fresh(); tick(150); p.shooting=true
    local knife=weapon(p,1001)
    fire("MC_POST_KNIFE_UPDATE",knife)
    assert(knife.CollisionDamage==8 and rice(p).thought==0)
    players={q,r,p}; fire("MC_POST_UPDATE")
    local sibling=weapon(p,1002); fire("MC_POST_KNIFE_UPDATE",sibling)
    assert(sibling.CollisionDamage==8 and rice(p).thought==0, "move must preserve the resolved same-frame volley")
    fire("MC_PRE_GAME_EXIT",true)
    assert(knife.CollisionDamage==4 and sibling.CollisionDamage==4, "exit restores tracked knife factors")
    assert(saved.deepseekRice["2"].thought==0, "save must not refund spent Thought")
    q,r,p=player(102,222,0),player(103,333,1,0),player(101,111,2)
    players={q,r,p}; frame=0; load(); fire("MC_POST_GAME_STARTED",true)
    p.shooting=true
    local recreated=weapon(p,2001); fire("MC_POST_KNIFE_UPDATE",recreated)
    assert(recreated.CollisionDamage==4 and rice(p).thought==0,
        "a recreated flight cannot manufacture the previous transient attack factor")
    tick(); p.kind=0; tick(); fire("MC_POST_KNIFE_UPDATE",recreated)
    assert(recreated.CollisionDamage==4 and rice(p)==nil)
end)

case("legacy",function()
    local p,q=fresh()
    saved={deepseekRice={['0']={version=1,bowls=2,clears=1,thought=37,speed=19,lunch=true,mealToken=99}},
        mealBreaks={['0']={version=1,remaining=12}}}
    load(); fire("MC_POST_GAME_STARTED",true)
    assert(rice(p).version==2 and rice(p).bowls==2 and rice(p).thought==37 and rice(p).speed==19)
    assert(rice(p).mealToken==nil and Meal:Remaining(p)==12, "legacy source identity must not be invented")
    assert(not Meal:CancelOwned(p,"rice",99), "legacy timer cannot be cancelled as a token-owned meal")
    assert(rice(q).bowls==1 and Meal:Remaining(q)==0, "missing partner state defaults independently")
    fire("MC_PRE_GAME_EXIT",true)
    assert(saved.mealBreaks["0"].version==2 and saved.deepseekRice["0"].version==2)
    saved.deepseekRice["0"].version=999; saved.mealBreaks["0"].version=999
    load(); fire("MC_POST_GAME_STARTED",true)
    assert(rice(p).bowls==1 and rice(p).thought==0 and Meal:Remaining(p)==0)
    fire("MC_POST_GAME_STARTED",false)
    assert(rice(p).thought==0 and Meal:Remaining(p)==0, "fresh run cannot inherit the loaded counters")
end)
assert(count>0,"unknown scenario")
print("PASS O6 Rice/Meal: "..count.." supplied save/identity scenarios; native acceptance pending")
