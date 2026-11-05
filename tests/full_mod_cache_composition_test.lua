-- Full main.lua cache mixtures with supplied native inputs. No engine emulation.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local fields={"Damage","MoveSpeed","TearRange","ShotSpeed","MaxFireDelay","TearFlags","CanFly"}
local channels={"R","G","B","A","RO","GO","BO"}
local function near(a,b,label)
    assert(type(a)=="number" and a==a and math.abs(a)<math.huge,label..": non-finite result")
    assert(math.abs(a-b)<1e-9,label..": "..a.." ~= "..b)
end
local function snapshot(p)
    local out={}
    for _,field in ipairs(fields) do out[field]=p[field] end
    out.TearColor={}; for _,field in ipairs(channels) do out.TearColor[field]=p.TearColor[field] end
    return out
end
local function same(p,expected,label)
    for _,field in ipairs(fields) do
        if field=="CanFly" then assert(p[field]==expected[field],label..": native flight changed")
        else near(p[field],expected[field],label.."."..field) end
    end
    for _,field in ipairs(channels) do near(p.TearColor[field],expected.TearColor[field],label..".color."..field) end
end
local function repeatable(p,label)
    p:EvaluateItems(); local before=snapshot(p)
    p:EvaluateItems(); same(p,before,label)
end
local function hold(env,p,list)
    p.items={}
    for name,count in pairs(list) do p.items[assert(env.Item[name],name)]=count end
end
local function native(p,damage,speed,delay,flight)
    p.cacheBase={Damage=damage,MoveSpeed=speed,TearRange=340,ShotSpeed=1.4,MaxFireDelay=delay,
        CanFly=flight,TearFlags=TearFlags.TEAR_HOMING,
        TearColor=Color(0.2,0.7,0.9,0.6,0.11,0.22,0.33)}
end

-- Known mixed arithmetic: Constitution precedes Opus, Cube adds afterward,
-- and Tiny Variant multiplies that result. Character modifiers follow items.
local formDamage={[0]=1,[100]=1,[101]=1.25,[102]=0.9,[103]=0.8,[104]=1.15,[105]=1,
    [106]=1,[107]=0.9,[108]=1,[109]=0.9,[110]=1,[111]=1,[112]=0.95,[113]=0.9,
    [114]=1,[115]=0.9,[116]=1,[117]=1,[118]=1,[119]=0.85,[120]=1,[121]=0.9}
local count=0
for kind,mult in pairs(formDamage) do
    for _,coins in ipairs({0,40}) do
        local env=Full.New(root,{kind,0})
        local p,q=table.unpack(env.players)
        native(p,8,0.35,4,true); native(q,2.25,1.5,15,false)
        p.coins=coins
        p:EvaluateItems(); q:EvaluateItems(); local partner=snapshot(q)
        hold(env,p,{CONSTITUTION=1,OPUS_MODE=1,TUNGSTEN_CUBE=2,TINY_VARIANT=2})
        repeatable(p,"arithmetic "..kind)
        near(p.Damage,(8*0.9*(coins==0 and 0.6 or 1.8)+1.6)*0.9^2*mult,"ordered damage "..kind)
        local formSpeed=(kind==100 or kind==115) and -0.1 or kind==114 and 0.1 or 0
        near(p.MoveSpeed,0.1+0.3+formSpeed,"Cube floor then Tiny speed "..kind)
        assert(p.CanFly and p.TearFlags & TearFlags.TEAR_HOMING~=0 and p.TearFlags & TearFlags.TEAR_KNOCKBACK~=0)
        p.coins=coins==0 and 40 or 0
        p:EvaluateItems()
        near(p.Damage,(8*0.9*(p.coins==0 and 0.6 or 1.8)+1.6)*0.9^2*mult,
            "wallet change before notification update "..kind)
        q:EvaluateItems(); same(q,partner,"partner unaffected")
        count=count+1
    end
end

-- A lower native speed must not be raised to Cube's 0.1 floor. Native flags,
-- colour, shot interval and flight must survive item application/removal.
do
    local env=Full.New(root,{0,0})
    local p,q=table.unpack(env.players)
    native(p,2,0.05,-0.5,true); native(q,9,1.3,20,false)
    p:EvaluateItems(); q:EvaluateItems()
    local before,partner=snapshot(p),snapshot(q)
    hold(env,p,{TUNGSTEN_CUBE=3,GOLDEN_GATE=2,EM_DASH=1,PIZZA_GLUE=2,MILLION_CONTEXT=1})
    repeatable(p,"native inputs")
    near(p.Damage,4.4,"Cube stacks onto native damage")
    near(p.MoveSpeed,0.05,"Cube does not raise an already lower speed")
    near(p.TearRange,340+120+200,"mixed range additions")
    near(p.ShotSpeed,1.4-0.2+0.16,"Glue and Em Dash copies")
    near(p.MaxFireDelay,-0.5,"native sub-frame interval")
    assert(p.TearFlags==(TearFlags.TEAR_HOMING|TearFlags.TEAR_KNOCKBACK|TearFlags.TEAR_SPECTRAL|TearFlags.TEAR_PIERCING))
    near(p.TearColor.R,0.2,"native red"); near(p.TearColor.A,0.6,"native alpha")
    near(p.TearColor.RO,0.36,"additive red"); near(p.TearColor.GO,0.40,"additive green")
    near(p.TearColor.BO,0.33,"native additive blue")
    q:EvaluateItems(); same(q,partner,"native partner")
    p.items={}; p:EvaluateItems(); same(p,before,"removed mixed modifiers")
end

local function generator(seed)
    return function(limit) seed=seed*48271%2147483647; return seed%limit+1 end
end
-- Every registered ID is sampled across all forms. This tests held-inventory
-- cache/update effects, not activation of all 80 collectible mechanisms.
local seen={}
for kind=100,121 do for seed=1,8 do
    local env=Full.New(root,{kind,0})
    local p,q=table.unpack(env.players)
    native(p,2+seed,0.7+seed/10,seed%2==0 and -0.5 or 10,seed%2==0)
    native(q,1+seed/2,1.6,16,false)
    env.step(3)
    local bases={}
    for i,player in ipairs(env.players) do player:EvaluateItems(); bases[i]=snapshot(player) end
    local names={}; for name in pairs(env.Item) do names[#names+1]=name end; table.sort(names)
    assert(#names==80,"matrix must include the current collectible registry")
    local choose=generator(seed*7919+kind)
    for _,player in ipairs(env.players) do
        for _,name in ipairs(names) do if seed==1 or choose(4)==1 then
            player.items[env.Item[name]]=choose(3); seen[name]=true
        end end
        repeatable(player,"held mixture "..kind.."/"..seed)
    end
    env.step(3)
    for _,player in ipairs(env.players) do repeatable(player,"updated mixture") end
    -- Replace with another independently sampled inventory, then remove all.
    for _,player in ipairs(env.players) do
        player.items={}
        for _,name in ipairs(names) do if choose(5)==1 then player.items[env.Item[name]]=1 end end
    end
    env.step(3)
    for _,player in ipairs(env.players) do repeatable(player,"replacement mixture"); player.items={} end
    env.step(3)
    for i,player in ipairs(env.players) do player:EvaluateItems(); same(player,bases[i],"removed mixture "..kind.."/"..seed) end
end end
local ids=0; for _ in pairs(seen) do ids=ids+1 end
assert(ids==80,"every registered ID must occur in the sampled inventory matrix")
print("PASS full main cache: "..count.." arithmetic cases, native-input control, 22 complete and 154 sampled two-owner inventories (offline)")
