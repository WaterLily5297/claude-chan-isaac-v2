-- Whole-entry-point update budgets plus visible Preview targeting invariants.
-- No wall-clock or interpreter-specific allocation threshold belongs in CI.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
for kind=100,121 do
    local env=Full.New(root,{kind},{enemies=12})
    local probe,items=false,0
    for _,cb in ipairs(env.callbacks) do if cb.id=="ClaudeChan:RunRuntimeProbe" then probe=true end end
    for _ in pairs(env.Item) do items=items+1 end
    assert(probe and items==80,"the complete entry point and collectible registry must load")
    env.step(10); env.resetMetrics(); env.step(60)
    assert((env.metrics.scans or 0)==0,"idle unarmed form must not repeatedly enumerate enemies: "..kind)
    assert((env.metrics.callbacks or 0)>60,"real update/render callbacks must execute")
    local p=env.players[1]
    assert(p.Damage==p.Damage and math.abs(p.Damage)<math.huge,"finite supplied damage")
end

if arg[3]~="behavior" then for _,players in ipairs({1,4}) do
    for _,enemies in ipairs({0,12,96}) do
        local kinds={}; for i=1,players do kinds[i]=100+(i-1)*2 end
        local env=Full.New(root,kinds,{enemies=enemies,geminiModule=arg[2]})
        env.step(10); env.preview(); env.resetMetrics(); env.step(30)
        assert(env.metrics.roomScans==6,
            "Preview must share one enemy enumeration per five-frame refresh across all owners/markers")
        assert((env.metrics.radiusScans or 0)==0 and (env.metrics.typeScans or 0)==0)
        for _,npc in ipairs(env.entities) do if npc:ToNPC() then
            assert(npc.Target and npc.Target:Exists(),"nearby eligible enemy must still receive a live decoy target")
        end end
        env.step(151); env.resetMetrics(); env.step(30)
        assert((env.metrics.scans or 0)==0,"expired previews must stop scanning")
    end
end end

do
    local env=Full.New(root,{102},{geminiModule=arg[2]})
    env.step(10)
    local p=env.players[1]; p.Position=Vector(300,200)
    local sentinel={native=true}
    local function npc(x,y,opts)
        opts=opts or {}; opts.y=y
        local n=env.npc(x,opts); n.Target=sentinel; return n
    end
    local left=npc(210,200)
    local right=npc(390,200)
    local tied=npc(300,200)
    local boundary=npc(580,200)
    local outside=npc(581,200)
    local boss=npc(220,200,{boss=true})
    local friendly=npc(220,200,{friendly=true})
    local invulnerable=npc(220,200,{invulnerable=true})
    local dead=npc(220,200); dead.alive=false
    env.preview()
    local a,b=env.spawned[#env.spawned-1],env.spawned[#env.spawned]
    env.step(4); assert(left.Target==sentinel,"targeting keeps its five-frame cadence")
    env.step()
    assert(left.Target==a and right.Target==b and tied.Target==a,"nearest marker and first-marker ties stay unchanged")
    assert(boundary.Target==b and outside.Target==sentinel,"200-unit inclusive boundary stays unchanged")
    assert(boss.Target==sentinel and friendly.Target==sentinel and invulnerable.Target==sentinel and dead.Target==sentinel)
    local later=npc(210,200)
    b.Position=Vector(215,200); env.step(5)
    assert(later.Target==b and left.Target==b,"new enemies and moved markers are observed at the next refresh")
    b:Remove(); env.step(5)
    assert(left.Target==a,"a removed marker is not a candidate")
    env.preview(); env.step(5)
    assert(not a:Exists() and left.Target~=a and left.Target:Exists(),"reuse replaces prior markers")
    env.newRoom(); env.resetMetrics(); env.step(10)
    assert((env.metrics.scans or 0)==0,"room cleanup retires the targeting workload")
end
do
    local env=Full.New(root,{103,107,119,121},{enemies=48,geminiModule=arg[2]})
    env.step(10); env.allItems(); env.preview()
    for _,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=true end
    env.step()
    for _,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=false end
    env.step()
    local scheduled=0
    for _,spent in pairs(env.Risk.state.kimiManager["2"].budget) do scheduled=scheduled+spent end
    assert(scheduled==3,"the mixed workload must arm the actual Kimi task loop")
    env.resetMetrics(); env.step(180)
    local hits=0
    for _,e in ipairs(env.entities) do if e:ToNPC() then hits=hits+#e.damage end end
    assert(hits>=4,"the mixed workload must run Kimi and GLM scheduled damage callbacks")
    for _,p in ipairs(env.players) do
        for _,field in ipairs({"Damage","MaxFireDelay","MoveSpeed","TearRange","ShotSpeed"}) do
            assert(p[field]==p[field] and math.abs(p[field])<math.huge,"finite mixed-item cache: "..field)
        end
    end
end
print(arg[3]=="behavior" and "PASS 22 idle forms and Preview target/lifecycle controls; scan budget skipped"
    or "PASS main update budget: 22 idle forms, six Preview workloads, target/lifecycle and mixed-item controls (offline)")
