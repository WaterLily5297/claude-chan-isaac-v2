-- Final ownership observation at serialization, without an intervening update.
-- Supplied identities/callbacks and detached tables are not native save evidence.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local roots={"claudeUsage","claudeAppeal","deepseekRice","deepseekPeak",
    "gptRouting","gptReset","geminiPaint","geminiEdit","grokCheck","grokRatio",
    "qwenAdapter","qwenFineTune","llamaRelease","llamaHype","mistralPounce",
    "mistralBaguette","doubaoApology","doubaoAgain","kimiSlides","kimiManager","glmQueue","glmRetry"}
local function copy(v)
    if type(v)~="table" then return v end
    local out={}; for k,x in pairs(v) do out[k]=copy(x) end; return out
end
local function same(a,b,label)
    assert(type(a)==type(b),label..": type differs")
    if type(a)~="table" then assert(a==b,label..": "..tostring(a).." ~= "..tostring(b)); return end
    for k,v in pairs(a) do same(v,b[k],label.."."..k) end
    for k in pairs(b) do assert(a[k]~=nil,label..": extra field "..k) end
end
local setters={
    function(s,i) s.value=i*13; s.age=i end,
    function(s,i) s.quota=i*7; s.pages=i%3 end,
    function(s,i) s.bowls=i%3; s.thought=i*20; s.speed=i*10 end,
    function(s,i) s.compute=i*2 end,
    function(s,i) s.verified=i%2==0; s.routing=i%3 end,
    function(s,i) s.credits=i*7 end,
    function(s,i) s.paint=i%3 end,
    function(s,i) s.doneRoom="former_"..i end,
    function(s,i) s.checkRoom="former_"..i end,
    function(s,i) s.cooldown=i*10 end,
    function(s,i) s.selected=i%3+1; s.adapters=i%3 end,
    function(s,i) s.build=i%3+1; s.awards=i%3; s.pinned=i%3 end,
    function(s,i) s.releases=i%3 end,
    function(s,i) s.hype=i%3 end,
    function(s,i) s.ready=i%2==0 end,
    function(s,i) s.baguettes=i%3 end,
    function(s,i) s.aimX=i%2; s.aimY=1-s.aimX; s.hitRoom="former_"..i end,
    function(s,i) s.phase="confident"; s.remaining=i*20 end,
    function(s,i) s.slides=i%3 end,
    function(s,i) s.budget["former_"..i]=3 end,
    function(s,i) s.queue=i%3 end,
    function(s,i) s.retries=i%3 end,
}
local function direct(e)
    e.Risk:Save(e.mod)
    return require("json").decode(e.mod.saved)
end
local function check(e,kind,saved,expected,label)
    for i,p in ipairs(e.players) do
        same(saved[roots[kind-99]][tostring(i-1)],expected[p.hash],kind.."/"..label.."/"..i)
    end
end
for kind=100,121 do
    if not arg[2] or tonumber(arg[2])==kind then
        for _,mixed in ipairs({false,true}) do
            for _,mode in ipairs({"direct","exit"}) do
                local e=Full.New(root,mixed and {kind,0,kind,0} or {kind,kind,kind,kind})
                e.step(10)
                local expected={}
                for i,p in ipairs(e.players) do
                    local s=e.Risk.state[roots[kind-99]][tostring(i-1)]
                    if p.kindId==kind then setters[kind-99](s,i) end
                    expected[p.hash]=copy(s)
                end
                local p=e.players; e.players={p[4],p[1],p[2],p[3]}; e.paused=mixed
                local saved=mode=="direct" and direct(e) or e.saveSnapshot()
                check(e,kind,saved,expected,mode)
                if mode=="direct" then
                    -- Save must update the live bindings as well as the serialized
                    -- map; a second direct save must not replay the first rotation.
                    p=e.players; e.players={p[3],p[4],p[1],p[2]}
                    saved=direct(e); check(e,kind,saved,expected,"second direct")
                    local repeated=direct(e); same(saved,repeated,"idempotent direct save")
                end
                assert(saved._saveSync==nil and saved._memeOwners==nil,"runtime observers cannot enter saves")
                local kinds={}; for i,actor in ipairs(e.players) do kinds[i]=actor.kindId end
                local resumed=Full.New(root,kinds,{snapshot=saved,identityBase=10000})
                same(saved[roots[kind-99]],resumed.Risk.state[roots[kind-99]],kind.."/Continue")
            end
        end
        -- A final replacement/departure is an observation too, not permission
        -- to copy the departing owner's progress into a new identity.
        local e=Full.New(root,{kind,kind}); e.step(10)
        local map=e.Risk.state[roots[kind-99]]
        setters[kind-99](map["0"],4); setters[kind-99](map["1"],2)
        local old,partner=copy(map["0"]),copy(map["1"])
        e.players[1].InitSeed=e.players[1].InitSeed+900
        local saved=direct(e)
        assert(not pcall(same,saved[roots[kind-99]]["0"],old,"replaced owner"),"final replacement retained old progress")
        same(saved[roots[kind-99]]["1"],partner,"replacement preserves partner")
        -- Observe departure on the second owner, after a valid live binding.
        e.players[2].kindId=0
        saved=direct(e)
        if kind==100 then same(saved.claudeUsage["1"],partner,"same-owner Claude debt exception")
        else assert(saved[roots[kind-99]]["1"]==nil,"final type departure must remove former form state") end
        print("PASS final-save ownership: "..kind.." direct/exit, four-player moves, Continue and replacement/type boundaries")
    end
end

if tonumber(arg[2]) then return end

local function use(e,name,p)
    p.items[e.Item[name]]=1
    assert(e.use(e.Item[name],p).Discharge,"item activation: "..name)
end
local function tap(e,p)
    e.step(); e.buttons[p.ControllerIndex]=true; e.step()
    e.buttons[p.ControllerIndex]=false; e.step()
end

-- Item maps and two distinct meal ownership contracts move together at exit.
if not arg[2] or arg[2]=="items" then
    local e=Full.New(root,{102,0,102,0}); e.step(10)
    local actors={table.unpack(e.players)}
    for i,p in ipairs(actors) do
        for _=1,i do use(e,"ANOTHER_ADAPTER",p) end
        if i==1 or i==4 then use(e,"TEMPERATURE_DIAL",p) end
        p.items[e.Item.OPUS_MODE]=1; p.items[e.Item.VIBE_CODING]=1
        for _=1,i do e.primary(p); e.step() end
        if i%2==1 then e.fire("MC_ENTITY_TAKE_DMG",EntityType.ENTITY_PLAYER,p,1,0,EntityRef(e.npc(1000)),0) end
    end
    tap(e,actors[1]); e.step(4); tap(e,actors[3])
    use(e,"RICE_COOKER",actors[2]); e.step(3); use(e,"RICE_COOKER",actors[4]); e.step(2)
    local maps={meal=e.Risk.state.mealBreaks,rice=e.Risk.state.deepseekRice,
        backlog=e.Risk.state.backlog.players,meme=e.Risk.state.memeExtras.players,
        opus=e.Risk.state.opusTears,vibe=e.Risk.state.vibeMistakes}
    local expected={}
    for i,p in ipairs(actors) do
        expected[p.hash]={}
        for name,map in pairs(maps) do expected[p.hash][name]=copy(map[tostring(i-1)]) end
    end
    e.players={actors[4],actors[2],actors[1],actors[3]}
    local saved=e.saveSnapshot()
    local savedMaps={meal=saved.mealBreaks,rice=saved.deepseekRice,
        backlog=saved.backlog.players,meme=saved.memeExtras.players,opus=saved.opusTears,vibe=saved.vibeMistakes}
    for i,p in ipairs(e.players) do
        for name,map in pairs(savedMaps) do same(map[tostring(i-1)],expected[p.hash][name],"mixed item "..name.."/"..i) end
    end
    local inventory={}; for i,p in ipairs(e.players) do inventory[i]=p.items end
    local resumed=Full.New(root,{0,0,102,102},{snapshot=saved,inventory=inventory,identityBase=20000})
    resumed.step(90)
    for i,p in ipairs(resumed.players) do
        assert(resumed.Meal:Remaining(p)==0,"all saved meal debts finish")
        assert(resumed.Backlog.Primed(p,"rice")== (i<=2),"only Cooker owners earn Cooker rewards")
        if i>2 then assert(resumed.Risk.state.deepseekRice[tostring(i-1)].thought==150,"Rice completion belongs to its original owner") end
    end
    print("PASS final-save composition: meals, Rice, backlog, meme choices, Opus and Vibe")
end

-- Multiple includes of the shared meme service must not apply a move twice.
if not arg[2] or arg[2]=="meme" then
    local e=Full.New(root,{0,0}); e.step(2)
    local first=include("scripts.items.meme_state")
    local second=include("scripts.items.meme_state")
    local p,q=table.unpack(e.players)
    first.For(e.Risk,p).decimal=0.11
    second.For(e.Risk,q).decimal=0.22
    first.For(e.Risk,q); second.For(e.Risk,p)
    e.players={q,p}
    assert(first.For(e.Risk,p).decimal==0.11,"first import must follow its owner")
    assert(second.For(e.Risk,q).decimal==0.22,"second import must not apply the move again")
    local saved=direct(e)
    assert(saved.memeExtras.players["0"].decimal==0.22 and saved.memeExtras.players["1"].decimal==0.11,"meme save follows owners")
    assert(first.For(e.Risk,p).decimal==0.11 and second.For(e.Risk,q).decimal==0.22,"separate import cannot replay the saved rotation")
    same(saved.memeExtras,direct(e).memeExtras,"meme repeated save")
    print("PASS shared meme observer: distinct includes and repeated reads/save")
end

-- A floor checkpoint waits until the normal update's cap and ownership work.
if not arg[2] or arg[2]=="checkpoint" then
    local e=Full.New(root,{105,105}); e.step(10)
    local p,q=table.unpack(e.players)
    p.items[CollectibleType.COLLECTIBLE_BIRTHRIGHT]=1
    e.Risk.state.gptReset["0"].credits=100; e.Risk.state.gptReset["1"].credits=7
    e.newFloor(); p.items[CollectibleType.COLLECTIBLE_BIRTHRIGHT]=nil; e.players={q,p}
    e.step()
    local saved=require("json").decode(e.mod.saved)
    assert(saved.gptReset["0"].credits==7 and saved.gptReset["1"].credits==80,"checkpoint follows owner and live cap settlement")
    same(saved.gptReset,e.Risk.state.gptReset,"checkpoint equals settled form state")
    local prior=e.mod.saved; e.step(); assert(e.mod.saved==prior,"one checkpoint per floor")
    print("PASS checkpoint phase: cap settlement and owner change before serialization")
end

-- An explicit non-saving exit and a duplicate exit cannot overwrite a checkpoint.
if not arg[2] or arg[2]=="exit" then
    for _,shouldSave in ipairs({false,true}) do
        local e=Full.New(root,{105,105}); e.step(2)
        e.Risk.state.gptReset["0"].credits=28; e.Risk.state.gptReset["1"].credits=7
        direct(e); local prior=e.mod.saved
        e.players={e.players[2],e.players[1]}
        e.fire("MC_PRE_GAME_EXIT",nil,shouldSave)
        if shouldSave then assert(e.mod.saved~=prior,"saving exit must write the final move")
        else assert(e.mod.saved==prior,"non-saving exit cannot replace the checkpoint") end
        local firstExit=e.mod.saved
        e.Risk.state.gptReset={}
        e.fire("MC_PRE_GAME_EXIT",nil,true)
        assert(e.mod.saved==firstExit,"ended run cannot write a later snapshot after cleanup")
    end
    print("PASS save lifecycle: non-saving and duplicate exit preserve prior snapshot")
end

-- Named registration replaces a hook once. A failure precedes encoding/write,
-- propagates, and leaves the floor checkpoint pending for the next update.
if not arg[2] or arg[2]=="failure" then
    local e=Full.New(root,{105}); e.step(2)
    local Sync=include("scripts.save_sync")
    direct(e); local prior=e.mod.saved
    local json=require("json"); local encode=json.encode; local encodes=0
    function json.encode(value) encodes=encodes+1; return encode(value) end
    Sync.Register(e.Risk,"test.failure",function() error("intentional save synchronization failure") end)
    local ok,err=pcall(function() direct(e) end)
    assert(not ok and tostring(err):find("intentional save synchronization failure",1,true),"synchronizer error must propagate")
    assert(e.mod.saved==prior and encodes==0,"failed synchronization must precede encoding and writing")
    e.newFloor()
    ok=pcall(function() e.fire("MC_POST_UPDATE") end)
    assert(not ok and e.mod.saved==prior,"failed checkpoint stays unwritten")
    local calls=0
    Sync.Register(e.Risk,"test.failure",function() calls=calls+1 end)
    e.fire("MC_POST_UPDATE")
    assert(calls==1 and e.mod.saved~=prior,"pending checkpoint retries after hook recovery")
    local current=e.mod.saved; e.fire("MC_POST_UPDATE")
    assert(calls==1 and e.mod.saved==current,"successful retry clears the pending checkpoint")
    print("PASS save synchronization failure: no write, one recovered hook and checkpoint retry")
end
