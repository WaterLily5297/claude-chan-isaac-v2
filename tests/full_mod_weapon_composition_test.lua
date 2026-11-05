-- Actual main.lua weapon composition with explicit source fields and event order.
-- These stand-ins do not establish native ancestry, physics or callback timing.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local function near(a,b,label)
    assert(type(a)=="number" and a==a and math.abs(a)<math.huge,label..": non-finite value")
    assert(math.abs(a-b)<1e-8,label..": "..a.." ~= "..b)
end
local function give(env,p,names)
    for _,name in ipairs(names) do p.items[assert(env.Item[name],name)]=1 end
    p:EvaluateItems()
end
local function toggle(env,p)
    env.buttons[p.ControllerIndex]=true; env.step()
    env.buttons[p.ControllerIndex]=false; env.step()
end
local function resource(env,kind,index)
    local key=tostring(index-1)
    if kind==100 then return env.Risk.state.claudeUsage[key].value end
    if kind==101 then return env.Risk.state.claudeAppeal[key].quota end
    if kind==103 then return env.Risk.state.deepseekPeak[key].compute end
    if kind==105 then return env.Risk.state.gptReset[key].credits end
end
local function paid(env,p,index,n)
    assert(p.coins==40-math.floor(n/10),"Opus wallet: "..p.coins.." for "..n)
    assert((env.Risk.state.opusTears[tostring(index-1)] or 0)==n%10,"Opus partial bill")
end
local kinds={single="laser",ring="laser",beam="laser",knife="knife",swing="knife",fetus="bomb",rocket="rocket"}
local function make(env,p,name)
    local e
    if name=="ludo" then
        e=env.tear(p); e.TearFlags=e.TearFlags|TearFlags.TEAR_LUDOVICO; e.Scale=1.7
    else e=env.weapon(assert(kinds[name]),p) end
    if name=="single" then e.OneHit=true
    elseif name=="ring" then e.circle=true
    elseif name=="knife" then e.flying=true
    elseif name=="swing" then
        e.SubType=4; e.SpawnerEntity=nil; e.Parent=env.weapon("knife",p)
    elseif name=="fetus" then e.IsFetus=true
    elseif name=="rocket" then e.SpawnerEntity=env.weapon("target",p) end
    return e
end
local function init(env,e)
    if e.Type==EntityType.ENTITY_LASER then env.fire("MC_POST_LASER_INIT",nil,e)
    elseif e.Type==EntityType.ENTITY_BOMB then env.fire("MC_POST_BOMB_INIT",nil,e)
    elseif e.Type==EntityType.ENTITY_TEAR then env.fire("MC_POST_FIRE_TEAR",nil,e) end
end
local function update(env,e,age)
    if age then e.FrameCount=age end
    local callbacks={[EntityType.ENTITY_LASER]="MC_POST_LASER_UPDATE",[EntityType.ENTITY_KNIFE]="MC_POST_KNIFE_UPDATE",
        [EntityType.ENTITY_BOMB]="MC_POST_BOMB_UPDATE",[EntityType.ENTITY_TEAR]="MC_POST_TEAR_UPDATE",
        [EntityType.ENTITY_EFFECT]="MC_POST_EFFECT_UPDATE"}
    env.fire(assert(callbacks[e.Type]),e.Variant,e)
end
local function hit(env,e,expected,label)
    local target=env.npc(300,{hp=100000})
    function target:IsEnemy() return true end
    local amount=e.Type==EntityType.ENTITY_BOMB and e.ExplosionDamage or e.CollisionDamage or 20
    local flags=(e.Type==EntityType.ENTITY_BOMB or e.Variant==EffectVariant.ROCKET) and DamageFlag.DAMAGE_EXPLOSION or 0
    target:TakeDamage(amount,flags,EntityRef(e),0)
    assert(#target.damage==1,label..": one collision must resolve exactly once")
    near(target.damage[1],expected or amount,label)
    target:Remove()
end

-- Duplicate-form partners exercise independent observer subscribers in main.
-- Two same-frame primaries share a form payment; Opus charges discrete sources
-- separately, then only one further held window per owner.
for kind=100,121 do for _,name in ipairs({"single","ring","beam","knife","swing","fetus","rocket","ludo"}) do
    local env=Full.New(root,{kind,kind})
    local p,q=table.unpack(env.players)
    p.aim,q.aim=Vector(1,0),Vector(1,0); env.step(10)
    give(env,p,{"OPUS_MODE","MILLION_CONTEXT"}); give(env,q,{"OPUS_MODE"})
    if kind==105 then toggle(env,p); toggle(env,q) end
    local baseline={resource(env,kind,1),resource(env,kind,2)}
    local held=name=="beam" or name=="ludo"
    local weapons={}
    for volley=1,10 do
        env.step(held and 6 or 16)
        for index,owner in ipairs(env.players) do
            if not held or volley==1 then
                weapons[index]={make(env,owner,name),make(env,owner,name)}
                for _,e in ipairs(weapons[index]) do init(env,e) end
            end
            for _,e in ipairs(weapons[index]) do
                local original=e.ExplosionDamage or e.CollisionDamage or 20
                update(env,e,held and (volley==1 and 1 or (volley-1)*6) or 1)
                update(env,e) -- Duplicate observation must not rebill/compound.
                local amount=e.ExplosionDamage or e.CollisionDamage or 20
                near(amount,original,"uncharged native damage "..kind.."/"..name)
                near(e.Scale,1.7,"native weapon scale")
                assert(e:Exists() and e.Velocity.X==10,"preserve weapon and velocity")
                local boost=kind==103 and name~="ludo" and volley*2<=baseline[index]
                hit(env,e,amount*(boost and 1.3 or 1),"full-main hit "..kind.."/"..name.."/"..volley)
                if not held then update(env,e,40) end
            end
            local expected=held and volley+1 or volley*2
            paid(env,owner,index,expected)
            local current=resource(env,kind,index)
            local delta=kind==100 and 4 or kind==103 and -2 or -1
            -- Peak currently forks a Ludovico tear only at fire; its paid
            -- observer deliberately ignores tears. Do not invent a new rule.
            local charges=kind==103 and name=="ludo" and 1 or volley
            if current then near(current,math.max(0,baseline[index]+charges*delta),
                "owner-specific form payment "..kind.."/"..name) end
        end
    end
    -- Removal prevents future item charges, while source form mechanics stay.
    for _,owner in ipairs(env.players) do owner.items={} end
    env.newRoom(); env.step()
    for index,owner in ipairs(env.players) do
        owner:EvaluateItems()
        local coins=owner.coins
        local e=make(env,owner,name); init(env,e); update(env,e,1)
        assert(owner.coins==coins,"removed Opus cannot bill")
        assert(env.fire("MC_INPUT_ACTION",nil,owner,InputHook.IS_ACTION_PRESSED,ButtonAction.ACTION_SHOOTRIGHT)==nil,
            "supplied weapon cases cannot leave a directional lock")
    end
end end

-- Earn both multipliers through the actual normal-DeepSeek meal and Cooker.
-- Discrete native damage and on-hit item leases compose without double hits.
for _,name in ipairs({"single","ring","knife","fetus","rocket","swing","beam","ludo"}) do
    local env=Full.New(root,{102,102})
    local p,q=table.unpack(env.players)
    give(env,p,{"OPUS_MODE","MILLION_CONTEXT","RICE_COOKER"})
    give(env,q,{"OPUS_MODE"})
    env.step(10); toggle(env,p); toggle(env,q); env.step(65)
    assert(env.Risk.state.deepseekRice["0"].thought==150 and env.Risk.state.deepseekRice["1"].thought==150)
    local hasCooker=name~="rocket" and name~="swing"
    if hasCooker then
        assert(env.use(env.Item.RICE_COOKER,p).Discharge); env.step(90)
        assert(env.Backlog.Primed(p,"rice"))
    end
    p.aim,q.aim=Vector(1,0),Vector(1,0)
    local e=make(env,p,name); local base=e.ExplosionDamage or e.CollisionDamage or 20
    init(env,e); update(env,e,1); update(env,e)
    assert(env.Risk.state.deepseekRice["0"].thought==0 and env.Risk.state.deepseekRice["1"].thought==150,
        "earned Thought must spend only the firing owner's charge")
    local rocket=name=="rocket"
    near(e.ExplosionDamage or e.CollisionDamage or 20,base*(rocket and 1 or 2),"native damage snapshot")
    local cooker=hasCooker and 2 or 1
    if hasCooker then assert(not env.Backlog.Primed(p,"rice"),"native attack must consume the completed Cooker prime") end
    hit(env,e,base*2*cooker,"earned Thought/Cooker "..name)
    local held=name=="beam" or name=="ludo"
    for age=2,8 do env.step(); update(env,e,age) end
    near(e.ExplosionDamage or e.CollisionDamage or 20,base*((held or rocket) and 1 or 2),"bounded Thought snapshot")
    hit(env,e,base*(held and 1 or 2)*cooker,"later Thought/Cooker hit "..name)
    paid(env,q,2,0)
    local other=make(env,q,name); init(env,other); update(env,other,1)
    assert(env.Risk.state.deepseekRice["1"].thought==0,"partner spends only on its own supplied attack")
    if name=="knife" then
        e.flying=false; update(env,e); near(e.CollisionDamage,base,"knife return restores native damage")
    end
end
print("PASS full main weapons: 176 two-owner weapon/resource cases and eight earned Thought compositions (offline)")
