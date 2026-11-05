-- Actual main.lua save/Continue composition under supplied offline callbacks.
-- The detached plain-table codec is not native JSON or engine acceptance.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local function same(a,b,path)
    path=path or "state"
    assert(type(a)==type(b),path..": type changed")
    if type(a)~="table" then assert(a==b,path..": value changed"); return end
    for k,v in pairs(a) do same(v,b[k],path.."."..tostring(k)) end
    for k in pairs(b) do assert(a[k]~=nil,path..": unexpected key "..tostring(k)) end
end
local function inventory(env)
    local out={}; for i,p in ipairs(env.players) do out[i]=p.items end; return out
end
local function input(env,p)
    return env.fire("MC_INPUT_ACTION",nil,p,InputHook.IS_ACTION_PRESSED,ButtonAction.ACTION_SHOOTRIGHT)
end
local function use(env,name,p)
    p.items[env.Item[name]]=1
    assert(env.use(env.Item[name],p).Discharge,"active should succeed: "..name)
end
local function tap(env,p)
    env.buttons[p.ControllerIndex]=true; env.step()
    env.buttons[p.ControllerIndex]=false; env.step()
end
local formRoots={"claudeUsage","claudeAppeal","deepseekRice","deepseekPeak",
    "gptRouting","gptReset","geminiPaint","geminiEdit","grokCheck","grokRatio",
    "qwenAdapter","qwenFineTune","llamaRelease","llamaHype","mistralPounce",
    "mistralBaguette","doubaoApology","doubaoAgain","kimiSlides","kimiManager","glmQueue","glmRetry"}

for kind=100,121 do
    local env=Full.New(root,{kind,0},{enemies=3})
    env.step(10)
    local p,q=env.players[1],env.players[2]
    use(env,"TEMPERATURE_DIAL",p)
    q.items[env.Item.TEMPERATURE_DIAL]=1; q:EvaluateItems()
    use(env,"ANOTHER_ADAPTER",p); use(env,"ANOTHER_ADAPTER",p)
    use(env,"ANOTHER_ADAPTER",q)
    env.preview()
    use(env,"RICE_COOKER",p); env.step(7)
    use(env,"RICE_COOKER",q); env.step(11)
    assert(env.Meal:Remaining(p)==72 and env.Meal:Remaining(q)==79)
    assert(input(env,p)==false and input(env,q)==false)
    local markers=env.spawned
    local saved=env.saveSnapshot()
    for _,marker in ipairs(markers) do assert(not marker:Exists(),"exit must remove live Preview markers") end
    local formRoot=formRoots[kind-99]
    assert(type(saved[formRoot])=="table" and type(saved[formRoot]["0"])=="table",
        "actual form state must be present: "..formRoot)
    assert(saved.backlog.players["0"].adapter==3 and saved.backlog.players["1"].adapter==2)
    assert(saved.memeExtras.players["0"].temperature==1 and saved.memeExtras.players["1"].temperature==0)
    assert(saved.backlog.players["0"].riceCooker and saved.backlog.players["1"].riceCooker)
    local resumed=Full.New(root,{kind,0},{snapshot=saved,inventory=inventory(env),identityBase=10000,enemies=3})
    local a,b=resumed.players[1],resumed.players[2]
    assert(a.hash~=p.hash and a.InitSeed~=p.InitSeed,"Continue must use recreated identities")
    same(saved[formRoot],resumed.Risk.state[formRoot],formRoot)
    same(saved.backlog,resumed.Risk.state.backlog,"backlog")
    same(saved.memeExtras,resumed.Risk.state.memeExtras,"memeExtras")
    assert(#resumed.spawned==0,"Continue must not recreate transient Preview markers")
    assert(resumed.Backlog.Data(a).room.adapter==nil and resumed.Backlog.Data(b).room.adapter==nil,
        "Adapter choice persists, but its existing room-local bonus does not")
    assert(resumed.Meal:Remaining(a)==72 and resumed.Meal:Remaining(b)==79)
    assert(input(resumed,a)==false and input(resumed,b)==false,"lock restores before the first update")
    assert(not resumed.Backlog.Primed(a,"rice") and not resumed.Backlog.Primed(b,"rice"))
    resumed.step(71)
    assert(resumed.Meal:Remaining(a)==1 and not resumed.Backlog.Primed(a,"rice"),"no early reward")
    resumed.step()
    assert(resumed.Meal:Remaining(a)==0 and resumed.Backlog.Primed(a,"rice"))
    assert(resumed.Meal:Remaining(b)==7 and not resumed.Backlog.Primed(b,"rice"),"owners finish independently")
    assert(input(resumed,a)==nil and input(resumed,b)==false,"only the completed meal unlocks")
    local prime=resumed.Backlog.Data(a).primes.rice
    resumed.step(7)
    assert(resumed.Backlog.Primed(b,"rice") and input(resumed,b)==nil)
    assert(resumed.Backlog.Data(a).primes.rice==prime,"completion cannot regrant or extend an earned prime")
    assert(resumed.Backlog.Peek(a).riceCooker==nil and resumed.Backlog.Peek(b).riceCooker==nil)
    local completed=resumed.saveSnapshot()
    assert(completed.backlog.players["0"].riceCooker==nil and completed.backlog.players["1"].riceCooker==nil)
    assert(saved.backlog.players["0"].riceCooker==true,"loaded state cannot mutate the detached source snapshot")
end

-- All four persistent maps must agree after an observed live slot rotation.
-- This does not model a slot change immediately before save without an update.
do
    local env=Full.New(root,{102,0,102,0})
    env.step(10)
    local a,b,c,d=table.unpack(env.players)
    use(env,"TEMPERATURE_DIAL",a)
    use(env,"TEMPERATURE_DIAL",d)
    for index,p in ipairs(env.players) do
        for _=1,index do use(env,"ANOTHER_ADAPTER",p) end
    end
    tap(env,a); env.step(5); tap(env,c)
    use(env,"RICE_COOKER",b); env.step(9); use(env,"RICE_COOKER",d)
    local left={}
    for _,p in ipairs(env.players) do left[p]=env.Meal:Remaining(p) end
    assert(env.Risk.state.deepseekRice["0"].lunch and env.Risk.state.deepseekRice["2"].lunch)
    env.players={d,a,b,c}; env.step()
    for _,p in ipairs(env.players) do assert(env.Meal:Remaining(p)==left[p]-1,"meal debt follows its live owner") end
    local saved=env.saveSnapshot()
    assert(saved.deepseekRice["1"].lunch and saved.deepseekRice["3"].lunch)
    assert(saved.deepseekRice["0"]==nil and saved.deepseekRice["2"]==nil)
    assert(saved.backlog.players["0"].riceCooker and saved.backlog.players["2"].riceCooker)
    assert(saved.backlog.players["1"].riceCooker==nil and saved.backlog.players["3"].riceCooker==nil)
    local resumed=Full.New(root,{0,102,0,102},{snapshot=saved,inventory=inventory(env),identityBase=20000})
    same(saved.deepseekRice,resumed.Risk.state.deepseekRice,"rotated Rice")
    same(saved.mealBreaks,resumed.Risk.state.mealBreaks,"rotated meals")
    same(saved.backlog,resumed.Risk.state.backlog,"rotated backlog")
    same(saved.memeExtras,resumed.Risk.state.memeExtras,"rotated meme state")
    local expectedAdapters={2,2,3,1}
    for i,p in ipairs(resumed.players) do
        assert(resumed.Backlog.Peek(p).adapter==expectedAdapters[i],"Adapter cycle follows its owner")
        assert(resumed.Meal:Remaining(p)==left[env.players[i]]-1)
        assert(input(resumed,p)==false)
    end
    resumed.players[2].move=Vector(1,0); resumed.step()
    local rice=resumed.Risk.state.deepseekRice
    assert(not rice["1"].lunch and rice["1"].bowls==1 and resumed.Meal:Remaining(resumed.players[2])==0,
        "moving cancels and refunds only this owner's character meal after Continue")
    assert(rice["3"].lunch and rice["3"].bowls==0 and resumed.Meal:Remaining(resumed.players[4])>0)
    resumed.players[2].move=Vector.Zero; resumed.step(90)
    assert(resumed.Backlog.Primed(resumed.players[1],"rice") and resumed.Backlog.Primed(resumed.players[3],"rice"))
    assert(not resumed.Backlog.Primed(resumed.players[2],"rice") and not resumed.Backlog.Primed(resumed.players[4],"rice"),
        "character meals cannot become Rice Cooker rewards")
    assert(not rice["3"].lunch and rice["3"].thought==150 and rice["3"].speed>0)
end

-- Persistent spent task budget survives; explicitly transient tasks do not.
do
    local env=Full.New(root,{119,0},{enemies=4})
    env.step(10); tap(env,env.players[1])
    local saved=env.saveSnapshot()
    local spent=0; for _,n in pairs(saved.kimiManager["0"].budget) do spent=spent+n end
    assert(spent==3,"the actual Kimi loop must spend a task before exit")
    local resumed=Full.New(root,{119,0},{snapshot=saved,identityBase=30000,enemies=4})
    same(saved.kimiManager,resumed.Risk.state.kimiManager,"Kimi spent budget")
    resumed.step(100)
    for _,npc in ipairs(resumed.entities) do if npc:ToNPC() then
        assert(#npc.damage==0,"Continue must not resurrect transient target tasks")
    end end
    tap(resumed,resumed.players[1])
    local spentAgain=0; for _,n in pairs(resumed.Risk.state.kimiManager["0"].budget) do spentAgain=spentAgain+n end
    assert(spentAgain==6,"the earlier cancelled task cannot refund its spent budget")
    resumed.step(180)
    local hits=0; for _,npc in ipairs(resumed.entities) do if npc:ToNPC() then hits=hits+#npc.damage end end
    assert(hits==3,"new post-Continue task must deliver exactly its three pulses")
end

-- Same-session Continue and a fresh start use the actual Risk load/reset hooks.
do
    local env=Full.New(root,{102,0})
    env.step(10)
    local p,q=table.unpack(env.players)
    use(env,"TEMPERATURE_DIAL",q); use(env,"ANOTHER_ADAPTER",p)
    use(env,"RICE_COOKER",q); tap(env,p); env.step(9)
    local saved=env.saveSnapshot()
    env.fire("MC_POST_NEW_ROOM"); env.fire("MC_POST_GAME_STARTED",nil,true)
    same(saved.mealBreaks,env.Risk.state.mealBreaks,"same-session meals")
    same(saved.deepseekRice,env.Risk.state.deepseekRice,"same-session Rice")
    same(saved.backlog,env.Risk.state.backlog,"same-session backlog")
    assert(env.Backlog.Data(q).riceMeal and input(env,q)==false)
    env.step(90)
    assert(env.Backlog.Primed(q,"rice") and env.Risk.state.deepseekRice["0"].thought==150)
    env.saveSnapshot()
    env.fire("MC_POST_NEW_ROOM"); env.fire("MC_POST_GAME_STARTED",nil,false)
    assert(env.Meal:Remaining(p)==0 and env.Meal:Remaining(q)==0)
    assert(not env.Backlog.Primed(q,"rice") and not env.Backlog.Data(q).riceMeal)
    assert(env.Risk.state.deepseekRice["0"].thought==0 and env.Risk.state.deepseekRice["0"].bowls==1)
    assert((not env.Backlog.Peek(p) or env.Backlog.Peek(p).adapter==nil)
        and env.Risk.state.memeExtras.players["1"].temperature==0,
        "a fresh run cannot inherit the previous run's item choices")
end

-- A live stand-in must not silently survive through the snapshot codec.
do
    local env=Full.New(root,{102})
    env.Risk.state.invalidEntity=env.players[1]
    local ok,err=pcall(env.saveSnapshot)
    assert(not ok and (tostring(err):find("non%-JSON save value") or tostring(err):find("runtime object in save state")),
        "the fixture must reject an accidentally persisted runtime entity")
end
print("PASS full main save composition: 22 form/item pairs, rotation, Kimi, restart and runtime-object controls (offline only)")
