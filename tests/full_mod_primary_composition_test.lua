-- Actual main.lua ordinary-primary composition under supplied firing callbacks.
-- Raw Spawn and synchronous FireTear are distinct fixture contracts, not native evidence.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local channels={"R","G","B","A","RO","GO","BO"}
local function near(a,b,label)
    assert(type(a)=="number" and a==a and math.abs(a)<math.huge,label..": non-finite damage")
    assert(math.abs(a-b)<1e-8,label..": "..a.." ~= "..b)
end
local function give(env,p,names)
    for _,name in ipairs(names) do p.items[assert(env.Item[name],name)]=1 end
    p:EvaluateItems()
end
local function npc(env,index)
    local n=0
    for _,e in ipairs(env.entities) do if e:ToNPC() then n=n+1; if n==index then return e end end end
    error("missing supplied enemy")
end
local function resource(env,kind,index)
    local key=tostring(index-1)
    if kind==100 then return env.Risk.state.claudeUsage[key].value end
    if kind==101 then return env.Risk.state.claudeAppeal[key].quota end
    if kind==103 then return env.Risk.state.deepseekPeak[key].compute end
    if kind==105 then return env.Risk.state.gptReset[key].credits end
end
local function toggle(env,p)
    env.buttons[p.ControllerIndex]=true; env.step()
    env.buttons[p.ControllerIndex]=false; env.step()
end

for kind=100,121 do
    local env=Full.New(root,{kind,kind},{enemies=2})
    local p,q=table.unpack(env.players)
    p.aim,q.aim=Vector(1,0),Vector(1,0)
    env.step(10)
    give(env,p,{"OPUS_MODE","STRAWBERRY","MILLION_CONTEXT","SUBAGENT_SWARM"})
    give(env,q,{"OPUS_MODE"})
    if kind==105 then toggle(env,p); toggle(env,q) end
    local number=0
    for volley=1,5 do
        env.step()
        local oldP,oldQ=resource(env,kind,1),resource(env,kind,2)
        for pellet=1,2 do
            number=number+1
            for index,owner in ipairs(env.players) do
                local expected=owner.Damage*(index==1 and number%3==0 and 2 or 1)
                local before=#env.spawned
                local tear=env.primary(owner,1.7)
                near(tear.CollisionDamage,expected,"resolved primary "..kind)
                near(tear.Scale,1.7*(index==1 and number%3==0 and 1.2 or 1),"native primary scale")
                local forks=(index==1 and 2 or 0)+(kind==103 and 2 or 0)
                assert(#env.spawned-before==forks,"expected bounded raw forks")
                local shots={tear}
                for i=before+1,#env.spawned do
                    local child=env.spawned[i]
                    assert(child:ToTear()==child and child:GetData().ccThoughtDerived,"raw child must execute TearFork.Copy")
                    near(child.CollisionDamage,expected*0.5,"resolved half-damage fork")
                    near(child.Scale,tear.Scale,"fork scale"); near(child.SpriteScale.X,tear.Scale,"fork sprite scale reset")
                    assert(child.TearFlags==tear.TearFlags and child.SpawnerEntity==owner)
                    for _,channel in ipairs(channels) do near(child.Color[channel],tear.Color[channel],"fork colour "..channel) end
                    for _,field in ipairs({"Height","FallingSpeed","FallingAcceleration","HomingFriction","KnockbackMultiplier"}) do
                        near(child[field],tear[field],"fork native field "..field)
                    end
                    shots[#shots+1]=child
                end
                for i,shot in ipairs(shots) do
                    local base=expected*(i==1 and 1 or 0.5)
                    for _,age in ipairs({0,1,1,30,62,90,180}) do
                        shot.FrameCount=age; env.fire("MC_POST_TEAR_UPDATE",nil,shot)
                        near(shot.CollisionDamage,base*(index==1 and math.max(0.3,1-age/90) or 1),
                            "Context decay without compounding or rebilling")
                    end
                    local target=npc(env,index); local hits=#target.damage
                    target:TakeDamage(shot.CollisionDamage,0,EntityRef(shot),0)
                    assert(#target.damage==hits+1,"one supplied collision must produce one unmodified hit")
                    near(target.damage[#target.damage],shot.CollisionDamage,"resolved hit")
                end
            end
        end
        local newP,newQ=resource(env,kind,1),resource(env,kind,2)
        if kind==100 then assert(newP==oldP+8 and newQ==oldQ+4,"Usage is per volley with one Swarm surcharge")
        elseif kind==101 then assert(newP==oldP-2 and newQ==oldQ-1,"Quota is per volley with one Swarm surcharge")
        elseif kind==103 then assert(newP==oldP-2 and newQ==oldQ-2,"Valley Compute pays once per owner/volley")
        elseif kind==105 then assert(newP==oldP-1 and newQ==oldQ-1,"Full Send Credits pay once per owner/volley") end
        for index,owner in ipairs(env.players) do
            assert(env.Risk.state.opusTears[tostring(index-1)]==number%10,"only primary tears enter the Opus bill")
            assert(owner.coins==40-math.floor(number/10),"forks/updates/hits cannot add wallet charges")
        end
    end
end

-- Earn Thought and an independent item prime through actual meal callbacks.
-- A same-frame volley consumes Thought once; Context snapshots its resolved
-- damage, while the other owner's Cooker multiplier is applied on collision.
do
    local env=Full.New(root,{102,0},{enemies=2})
    local p,q=table.unpack(env.players)
    env.step(10)
    give(env,p,{"OPUS_MODE","STRAWBERRY","MILLION_CONTEXT","SUBAGENT_SWARM"})
    give(env,q,{"RICE_COOKER"})
    assert(env.use(env.Item.RICE_COOKER,q).Discharge)
    toggle(env,p)
    assert(env.Risk.state.deepseekRice["0"].lunch)
    env.step(90)
    assert(env.Risk.state.deepseekRice["0"].thought==150 and env.Backlog.Primed(q,"rice"))
    p.aim=Vector(1,0)
    for i=1,3 do
        local before=#env.spawned
        local tear=env.primary(p,1.7)
        local expected=p.Damage*(i==3 and 4 or 2)
        near(tear.CollisionDamage,expected,"earned Thought and Strawberry")
        assert(env.Risk.state.deepseekRice["0"].thought==0,"Thought must be spent once for the volley")
        assert(#env.spawned-before==2)
        for j=before+1,#env.spawned do near(env.spawned[j].CollisionDamage,expected*0.5,"Swarm inherits resolved Thought") end
        tear.FrameCount=30; env.fire("MC_POST_TEAR_UPDATE",nil,tear)
        near(tear.CollisionDamage,expected*(1-30/90),"Context retains resolved ordinary Thought")
    end
    assert(env.Backlog.Primed(q,"rice"),"another owner's volley cannot consume the Cooker prime")
    local target=npc(env,2)
    local tear=env.primary(q)
    target:TakeDamage(tear.CollisionDamage,0,EntityRef(tear),0)
    near(target.damage[#target.damage],q.Damage*2,"Cooker resolves once on collision")
    assert(not env.Backlog.Primed(q,"rice"))
    env.step(); tear=env.primary(q)
    target:TakeDamage(tear.CollisionDamage,0,EntityRef(tear),0)
    near(target.damage[#target.damage],q.Damage,"later volley has no leftover Cooker bonus")
end

-- Actual One More Finger dispatches FireTear synchronously. Its callback must
-- run, but Opus must see the owner-scoped exemption before backlog marks it.
for _,kind in ipairs({100,101,102,103,105}) do
    local env=Full.New(root,{kind,0})
    local p,q=table.unpack(env.players)
    p.aim,q.aim=Vector(1,0),Vector(1,0); env.step(10)
    give(env,p,{"OPUS_MODE","ONE_MORE_FINGER"}); give(env,q,{"OPUS_MODE"})
    if kind==105 then toggle(env,p) end
    for i=1,10 do env.step(16); env.primary(p); env.primary(q) end
    env.step() -- One More Finger schedules its FireTear on the next update.
    assert(#p.fired==2 and #q.fired==0,"fifth/tenth helper count "..kind..": "..#p.fired.."/"..#q.fired)
    for _,helper in ipairs(p.fired) do
        assert(helper:GetData().ccThoughtDerived,"synchronous callback must mark the helper")
        near(helper.CollisionDamage,p.Damage*0.3,"native helper multiplier")
    end
    assert(p:GetData().ccDerivedTearDepth==nil,"helper spawn scope must unwind")
    assert(p.coins==39 and q.coins==39 and env.Risk.state.opusTears["0"]==0 and env.Risk.state.opusTears["1"]==0,
        "synchronous helpers cannot bill Opus or another owner")
end

-- Mixed passive hit listeners now execute through the same entry point. This
-- samples held inventories, not every active item or every character ability.
local function generator(seed)
    return function(limit) seed=seed*48271%2147483647; return seed%limit+1 end
end
for kind=100,121 do for seed=1,4 do
    local env=Full.New(root,{kind,0},{enemies=2})
    local p,q=table.unpack(env.players)
    p.aim,q.aim=Vector(1,0),Vector(1,0); env.step(10)
    local names={}; for name in pairs(env.Item) do names[#names+1]=name end; table.sort(names)
    assert(#names==80)
    local choose=generator(kind*7919+seed)
    for _,owner in ipairs(env.players) do
        for _,name in ipairs(names) do if seed==1 or choose(3)==1 then owner.items[env.Item[name]]=1 end end
        give(env,owner,{"OPUS_MODE"})
    end
    for shot=1,10 do
        env.step(2)
        for index,owner in ipairs(env.players) do
            local before=#env.spawned
            local tear=env.primary(owner)
            assert(tear:Exists(),"these initial forms must not randomly remove ordinary primary tears")
            near(tear.CollisionDamage,tear.CollisionDamage,"finite mixed primary")
            assert(#env.spawned-before<=4,"primary spawning must remain bounded")
            local shots={tear}
            for i=before+1,#env.spawned do if env.spawned[i]:ToTear() then shots[#shots+1]=env.spawned[i] end end
            for _,projectile in ipairs(shots) do
                projectile.FrameCount=1; env.fire("MC_POST_TEAR_UPDATE",nil,projectile)
                near(projectile.CollisionDamage,projectile.CollisionDamage,"finite mixed projectile")
                npc(env,index):TakeDamage(projectile.CollisionDamage,0,EntityRef(projectile),0)
            end
        end
    end
    env.step(2)
    for index,owner in ipairs(env.players) do
        assert(owner.coins==39 and env.Risk.state.opusTears[tostring(index-1)]==0,
            "mixed hit listeners, forks and helpers cannot add Opus payments")
        for _,amount in ipairs(npc(env,index).damage) do near(amount,amount,"finite nested damage") end
        owner.items={}
    end
    env.newRoom()
    env.step(2)
    for _,owner in ipairs(env.players) do
        owner:EvaluateItems()
        local primary=env.primary(owner)
        near(primary.CollisionDamage,owner.Damage,"removed item primary damage")
        near(primary.Scale,1,"removed item primary scale")
        assert(owner.coins==39,"removed Opus cannot keep charging")
        assert(env.fire("MC_INPUT_ACTION",nil,owner,InputHook.IS_ACTION_PRESSED,ButtonAction.ACTION_SHOOTRIGHT)==nil,
            "the supplied passive mixes cannot leave a directional input lock")
    end
end end
print("PASS full main primary: 22 shot/fork/billing cases, earned Thought/Cooker, five helper cases and 88 mixed inventories (offline)")
