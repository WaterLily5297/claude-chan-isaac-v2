-- Full entry-point target abilities and independent nested damage. Supplied
-- entity identity, source fields and callback order are not engine evidence.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local function near(a,b,label)
    assert(type(a)=="number" and a==a and math.abs(a-b)<1e-8,label..": "..tostring(a).." ~= "..tostring(b))
end
local function enemy(env,x,y)
    local n=env.npc(x,{y=y or 0,hp=100000})
    n.InitSeed,n.MaxHitPoints=n.hash,n.HitPoints
    function n:IsEnemy() return true end
    return n
end
local function give(env,p,names)
    for _,name in ipairs(names) do p.items[assert(env.Item[name],name)]=1 end
    p:EvaluateItems()
end
local function tap(env,p)
    env.buttons[p.ControllerIndex]=false; env.step()
    env.buttons[p.ControllerIndex]=true; env.step()
    env.buttons[p.ControllerIndex]=false; env.step()
end
local function setup(kind)
    local env=Full.New(root,{kind,kind})
    local p,q=table.unpack(env.players)
    p.Position,q.Position=Vector(220,0),Vector(720,0)
    p.aim,q.aim=Vector(1,0),Vector(1,0)
    local target,other,partner=enemy(env,300),enemy(env,350),enemy(env,800)
    env.step(10)
    give(env,p,{"OPUS_MODE","IS_THIS_TRUE"}); give(env,q,{"OPUS_MODE"})
    return env,p,q,target,other,partner
end
local function attack(env,p,kind)
    if kind=="tear" then return env.primary(p) end
    local e
    if kind=="ludo" then
        e=env.tear(p); e.TearFlags=e.TearFlags|TearFlags.TEAR_LUDOVICO
        env.fire("MC_POST_FIRE_TEAR",nil,e); e.FrameCount=1
        env.fire("MC_POST_TEAR_UPDATE",nil,e)
    else
        e=env.weapon(kind,p); e.FrameCount=1
        if kind=="laser" then
            e.OneHit=true; env.fire("MC_POST_LASER_INIT",nil,e); env.fire("MC_POST_LASER_UPDATE",nil,e)
        elseif kind=="knife" then
            e.flying=true; env.fire("MC_POST_KNIFE_UPDATE",nil,e)
        elseif kind=="bomb" then
            e.IsFetus=true; env.fire("MC_POST_BOMB_INIT",nil,e); env.fire("MC_POST_BOMB_UPDATE",nil,e)
        else error("unsupported supplied attack") end
    end
    return e
end
local function hit(target,source,amount)
    local before=#target.damage
    local flags=source.Type==EntityType.ENTITY_BOMB and DamageFlag.DAMAGE_EXPLOSION or 0
    target:TakeDamage(amount or source.ExplosionDamage or source.CollisionDamage,flags,EntityRef(source),0)
    local hits={}; for i=before+1,#target.damage do hits[#hits+1]=target.damage[i] end
    return hits
end

-- Export is independent player-sourced damage inside the triggering weapon's
-- modified hit. It must receive the challenge once, not inherit that shot's
-- consumed Cooker prime or disappear behind the shot's recursion guard.
for _,kind in ipairs({"tear","laser","knife","bomb","ludo"}) do
    local env,p,q,target,other,partner=setup(107)
    give(env,p,{"RICE_COOKER"})
    assert(env.use(env.Item.RICE_COOKER,p).Discharge); env.step(90)
    assert(env.Backlog.Primed(p,"rice"))
    assert(env.use(env.Item.IS_THIS_TRUE,p).Discharge)
    tap(env,p); tap(env,q)
    local angles={Vector(-80,0),Vector(0,-80),Vector(80,0)}
    for step,offset in ipairs(angles) do
        env.step(6); p.Position=target.Position+offset
        local shot=attack(env,p,kind)
        local hits=hit(target,shot)
        assert(#hits==(step==3 and 2 or 1),"Export occurs once on the third distinct angle/attack")
        local base=shot.ExplosionDamage or shot.CollisionDamage
        if step==3 then near(hits[1],p.Damage*2*1.35,"independent Export keeps the challenge modifier") end
        near(hits[#hits],base*1.35*(step==1 and 2 or 1),"triggering source keeps its own item lease")
        if step<3 then
            local repeatHits=hit(target,shot)
            assert(#repeatHits==1,"duplicate collision cannot advance the chain")
        end
    end
    assert(env.Risk.state.geminiEdit["0"].doneRoom and not env.Risk.state.geminiEdit["1"].doneRoom)
    assert(env.Risk.state.opusTears["0"]==3 and env.Risk.state.opusTears["1"]==nil,
        "Export pulses never become paid weapon starts")
    for step,offset in ipairs(angles) do
        env.step(6); q.Position=partner.Position+offset
        local hits=hit(partner,attack(env,q,kind))
        assert(#hits==(step==3 and 2 or 1),"partner Export occurs once")
        if #hits==2 then near(hits[1],q.Damage*2,"partner Export has no borrowed challenge") end
    end
    assert(env.Risk.state.geminiEdit["1"].doneRoom,"partner chain completes independently")
    local oldRoom=env.Risk.state.geminiEdit["0"].doneRoom
    env.newRoom(); p.Position=Vector(220,0); target=enemy(env,300); env.step(); tap(env,p)
    for _,offset in ipairs(angles) do
        env.step(6); p.Position=target.Position+offset; hit(target,attack(env,p,kind))
    end
    assert(env.Risk.state.geminiEdit["0"].doneRoom~=oldRoom,"a genuinely new supplied room allows a new chain")
end

-- Wet paint samples Birthright on the hit, and the independent challenge and
-- consumed Cooker lease must compose at each supplied phase.
for _,kind in ipairs({"tear","laser","knife","bomb","ludo"}) do
    local env,p,q,target=setup(106)
    give(env,p,{"RICE_COOKER"})
    assert(env.use(env.Item.RICE_COOKER,p).Discharge); env.step(90)
    assert(env.use(env.Item.IS_THIS_TRUE,p).Discharge); tap(env,p)
    assert(env.Risk.state.geminiPaint["0"].paint==1 and env.Risk.state.geminiPaint["1"].paint==2)
    local shot=attack(env,p,kind); local base=shot.ExplosionDamage or shot.CollisionDamage
    near(hit(target,shot)[1],base*2*1.35,"wet paint gives no early character bonus")
    env.step(30)
    near(hit(target,shot)[1],base*2*1.35*1.2,"dry paint and item lease compose")
    p.items[CollectibleType.COLLECTIBLE_BIRTHRIGHT]=1
    near(hit(target,shot)[1],base*2*1.35*1.3,"Birthright acquisition affects the current mark")
    p.items[CollectibleType.COLLECTIBLE_BIRTHRIGHT]=nil
    near(hit(target,shot)[1],base*2*1.35*1.2,"Birthright loss restores the mark multiplier")
    local partnerShot=attack(env,q,kind)
    near(hit(target,partnerShot)[1],partnerShot.ExplosionDamage or partnerShot.CollisionDamage,
        "partner cannot borrow the owner's paint/challenge/Cooker")
    env.newRoom(); target=enemy(env,300); env.step()
    local clean=attack(env,p,kind)
    near(hit(target,clean)[1],clean.ExplosionDamage or clean.CollisionDamage,"room exit clears both target modifiers")
    assert(env.Risk.state.geminiPaint["0"].paint==1,"leaving never refunds spent Paint")
end

-- Character verification and Community Note count the same three distinct
-- attacks despite duplicate collisions and nested modifier callbacks.
for _,kind in ipairs({"tear","laser","knife","bomb","ludo"}) do
    local env,p,q,target,other=setup(108)
    give(env,p,{"RICE_COOKER","COMMUNITY_NOTE"})
    assert(env.use(env.Item.RICE_COOKER,p).Discharge); env.step(90)
    assert(env.use(env.Item.IS_THIS_TRUE,p).Discharge); tap(env,p)
    for step=1,3 do
        env.step(6); local shot=attack(env,p,kind)
        local base=shot.ExplosionDamage or shot.CollisionDamage
        local hits=hit(target,shot)
        assert(#hits==1,"verification cannot manufacture additional hits")
        near(hits[1],base*1.35*1.3*(step==1 and 2 or 1),"check and item challenge composition")
        if step<3 then
            near(hit(target,shot)[1],hits[1],"duplicate hit cannot verify or expose early")
            near(hit(other,shot)[1],base*0.85*0.9*(step==1 and 2 or 1),"both off-target tradeoffs remain")
            assert(not env.Risk.state.grokCheck["0"].verifiedRoom)
        else
            near(hit(target,shot)[1],base*1.35*1.15,"verified check ends; exposed item target remains")
        end
    end
    near(p.MoveSpeed,1.15,"verified room speed"); near(q.MoveSpeed,1,"partner remains unverified")
    assert(env.Risk.state.grokCheck["0"].verifiedRoom and not env.Risk.state.grokCheck["1"].verifiedRoom)
    assert(env.Risk.state.opusTears["0"]==3,"nested amplification cannot bill extra attacks")
    env.newRoom(); target=enemy(env,300); env.step()
    near(p.MoveSpeed,1,"new supplied room clears verified speed")
    tap(env,p)
    assert(env.Risk.state.grokCheck["0"].checkRoom~=env.Risk.state.grokCheck["1"].checkRoom,
        "a new room has its own character check budget")
end

-- Ratio reconciles target choices once per attack, while its delayed player
-- pulses receive the still-active item challenge without creating more bills.
for _,kind in ipairs({"tear","laser","knife","bomb","ludo"}) do
    local env,p,q,target,other,partner=setup(109)
    local partnerOther=enemy(env,850)
    tap(env,p); local deadline=env.frame+180
    tap(env,q); local partnerDeadline=env.frame+180
    assert(env.use(env.Item.IS_THIS_TRUE,p).Discharge)
    for step=1,4 do
        env.step(6); local shot=attack(env,p,kind)
        if step==1 then hit(target,shot); hit(other,shot); hit(other,shot) -- favorable choice wins
        elseif step==2 then hit(target,shot) -- a distinct own reply loses one
        else hit(other,shot); hit(other,shot) end
        if step<=3 then hit(partnerOther,attack(env,q,kind)) end
    end
    local before,otherBefore=#target.damage,#partner.damage
    env.step(deadline-env.frame)
    assert(#target.damage==before+2,"two resolved Ratio stacks land once each")
    for i=before+1,#target.damage do near(target.damage[i],p.Damage*1.35,"Ratio and item challenge") end
    assert(#partner.damage==otherBefore,"partner's later deadline stays independent")
    env.step(partnerDeadline-env.frame)
    assert(#partner.damage==otherBefore+3,"partner keeps three independent Ratio stacks")
    for i=otherBefore+1,#partner.damage do near(partner.damage[i],q.Damage,"partner Ratio has no borrowed item bonus") end
    assert(env.Risk.state.opusTears["0"]==4 and env.Risk.state.opusTears["1"]==3)
end

-- Tasks use the same item target modifier, but partner hits cannot pause an
-- owner's task and a task pulse cannot count as the owner's weapon input.
for _,kind in ipairs({"tear","laser","knife","bomb","ludo"}) do
    local env,p,q,target,_,partner=setup(119)
    tap(env,p); local selected=env.frame
    tap(env,q)
    assert(env.use(env.Item.IS_THIS_TRUE,p).Discharge)
    local ownShot=attack(env,p,kind); hit(target,ownShot)
    local partnerShot=attack(env,q,kind); hit(target,partnerShot)
    local before=#target.damage
    -- p's task had advanced three frames before its 30-frame interference.
    env.step(59); assert(#target.damage==before,"own weapon delays the assigned task")
    env.step(27); assert(#target.damage==before,"the last interference/delay frame stays quiet")
    env.step(); assert(#target.damage==before+1,"task resumes at its original remaining interval")
    near(target.damage[#target.damage],p.Damage*0.6*1.35,"task pulse composes with challenge")
    p.items[CollectibleType.COLLECTIBLE_BIRTHRIGHT]=1
    assert(env.use(env.Item.IS_THIS_TRUE,p).Discharge)
    env.step(60); near(target.damage[#target.damage],p.Damage*0.7*1.35,"task samples Birthright on a pulse")
    p.items[CollectibleType.COLLECTIBLE_BIRTHRIGHT]=nil
    env.step(60); assert(#target.damage==before+3,"each task has exactly three pulses")
    near(target.damage[#target.damage],p.Damage*0.6*1.35,"task respects Birthright loss")
    assert(#partner.damage==3,"partner task is not delayed by hitting someone else's assignment")
    assert(env.Risk.state.opusTears["0"]==1 and env.Risk.state.opusTears["1"]==1)
    local budget=env.Risk.state.kimiManager["0"].budget
    local spent=0; for _,n in pairs(budget) do spent=spent+n end
    assert(spent==3 and env.frame>selected,"task pulses do not respend the room budget")
end

-- A failed request earns one Retry; a later successful player-sourced request
-- composes with the item challenge and consumes only its owner's saved stacks.
do
    local env,p,q,target,other,partner=setup(121)
    tap(env,p); target:Remove(); env.step()
    assert(env.Risk.state.glmRetry["0"].retries==1 and env.Risk.state.glmRetry["1"].retries==0)
    env.step(90); tap(env,p); tap(env,q)
    assert(env.use(env.Item.IS_THIS_TRUE,p).Discharge)
    env.step(60)
    assert(#other.damage==1 and #partner.damage==1)
    near(other.damage[1],p.Damage*3*1.35,"Retry stack and item target bonus")
    near(partner.damage[1],q.Damage*2,"partner request has no borrowed Retry")
    assert(env.Risk.state.glmRetry["0"].retries==0 and env.Risk.state.glmRetry["1"].retries==0)
    local bills=env.Risk.state.opusTears
    assert(not bills or (bills["0"]==nil and bills["1"]==nil),"requests never bill weapon attacks")
end

-- A supplied later damage callback models an independent same-source hit on
-- another target, then a same-pair echo. The outer guard must be restored after
-- the nested target's modifier finishes. This is an external-callback control.
do
    local env,p,_,target,other=setup(0)
    assert(env.use(env.Item.IS_THIS_TRUE,p).Discharge)
    local shot=attack(env,p,"tear")
    local entered=false
    env.mod:AddCallback("MC_ENTITY_TAKE_DMG",function(_,entity,amount,flags,source,countdown)
        if entered or entity~=target or source.Entity~=shot then return end
        entered=true
        other:TakeDamage(10,flags,source,countdown)
        target:TakeDamage(amount,flags,source,countdown)
    end)
    local hits=hit(target,shot,10)
    assert(#hits==2 and #other.damage==1,"bounded supplied nested callback")
    near(other.damage[1],8.5,"a different target still receives its own modifier")
    near(hits[1],13.5,"outer source/target guard is restored after nested damage")
    near(hits[2],13.5,"original replacement is not compounded")
    local count=#target.damage
    env.Backlog.Pulse(target,p,2)
    assert(#target.damage==count+1)
    near(target.damage[#target.damage],p.Damage*2,"explicit common pulses keep their modifier exemption")
end

do
    local env,p,_,target=setup(0)
    assert(env.use(env.Item.IS_THIS_TRUE,p).Discharge)
    local shot=attack(env,p,"tear")
    local native=target.TakeDamage
    local fail=true
    function target:TakeDamage(...)
        if fail then fail=false; error("injected downstream damage failure") end
        return native(self,...)
    end
    local ok,err=pcall(native,target,10,0,EntityRef(shot),0)
    assert(not ok and tostring(err):find("injected downstream damage failure",1,true),"failure remains visible to the caller")
    near(hit(target,shot,10)[1],13.5,"failed replacement cannot poison future damage")
end
print("PASS full-main targets: 25 two-owner weapon/ability cases, Retry, nested-target/pulse and error controls (offline)")
