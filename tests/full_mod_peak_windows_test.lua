-- Full entry-point regression: primary held beams share a paid Peak decision,
-- without sharing payments, extending deadlines or surviving owner boundaries.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local function near(a,b,label) assert(math.abs(a-b)<1e-8,label..": "..a.." ~= "..b) end
local function setup()
    local env=Full.New(root,{103,103,103,103})
    local beams={}
    for i,p in ipairs(env.players) do
        p.aim=Vector(1,0); p.items[env.Item.OPUS_MODE]=1; p:EvaluateItems()
        beams[i]={env.weapon("laser",p),env.weapon("laser",p)}
        for _,beam in ipairs(beams[i]) do env.fire("MC_POST_LASER_INIT",nil,beam) end
    end
    return env,beams
end
local function observe(env,beam,age)
    beam.FrameCount=age
    env.fire("MC_POST_LASER_UPDATE",nil,beam)
end
local function hit(env,beam,factor)
    local npc=env.npc(300,{hp=100000})
    npc:TakeDamage(10,0,EntityRef(beam),0)
    assert(#npc.damage==1,"a supplied primary hit is re-dealt at most once")
    near(npc.damage[1],10*factor,"paid primary window")
    npc:Remove()
end

do
    local env,beams=setup()
    -- Each owner initialized two beams, sharing one 2-Compute charge but
    -- contributing two source starts to that owner's Opus partial bill.
    for i=1,4 do
        assert(env.Risk.state.deepseekPeak[tostring(i-1)].compute==10)
        assert(env.Risk.state.opusTears[tostring(i-1)]==2)
    end
    for window=1,5 do
        env.step(6)
        for i=4,1,-1 do
            local first=window%2+1; local second=3-first
            observe(env,beams[i][first],window*6)
            observe(env,beams[i][second],window*6)
            observe(env,beams[i][second],window*6)
            for _,beam in ipairs(beams[i]) do hit(env,beam,1.3) end
            assert(env.Risk.state.deepseekPeak[tostring(i-1)].compute==10-window*2,"each owner pays its own window")
            assert(env.Risk.state.opusTears[tostring(i-1)]==window+2)
        end
    end
    env.step(6)
    for i=1,4 do
        for _,beam in ipairs(beams[i]) do observe(env,beam,36); hit(env,beam,1) end
        assert(env.Risk.state.deepseekPeak[tostring(i-1)].compute==0)
        assert(env.Risk.state.opusTears[tostring(i-1)]==8,"unaffordable Peak remains an Opus attack")
    end
end

do
    local env,beams=setup()
    env.step(6); observe(env,beams[1][1],6)
    env.step(5); observe(env,beams[1][2],11)
    hit(env,beams[1][2],1.3)
    assert(env.Risk.state.deepseekPeak["0"].compute==8 and env.Risk.state.opusTears["0"]==3,
        "a late sibling reuses the existing charge")
    env.step(2)
    hit(env,beams[1][2],1) -- No update: the old frame-12 deadline must stay fixed.
    assert(env.Risk.state.deepseekPeak["1"].compute==10 and env.Risk.state.opusTears["1"]==2,
        "an idle partner never borrows a paid window")
end

do
    local env,beams=setup()
    env.step(6); observe(env,beams[1][1],6)
    env.paused=true; observe(env,beams[1][2],6)
    env.paused=false
    -- The init lease expires now; an observation while paused must not share
    -- the later decision or pay for another one.
    env.step(); hit(env,beams[1][2],1)
    observe(env,beams[1][2],7); hit(env,beams[1][2],1.3)
    assert(env.Risk.state.deepseekPeak["0"].compute==8 and env.Risk.state.opusTears["0"]==3)
    env.players[1].InitSeed=99999; env.step()
    observe(env,beams[1][2],8); hit(env,beams[1][2],1)
    assert(env.Risk.state.deepseekPeak["0"].compute==12,"old decision cannot bind to a replacement owner")
    env.newRoom(); env.step()
    local fresh=env.weapon("laser",env.players[1]); env.fire("MC_POST_LASER_INIT",nil,fresh)
    env.step(6); observe(env,fresh,6); hit(env,fresh,1.3)
    assert(env.Risk.state.deepseekPeak["0"].compute==8,"room reset permits a fresh window")
    local snapshot=env.saveSnapshot()
    assert(snapshot.deepseekPeak["0"].compute==8,"transient decisions never enter the saved resource map")
end
print("PASS full main primary beam windows: four owners, alternating order, exhaustion, deadline, pause, replacement, room and save (offline)")
