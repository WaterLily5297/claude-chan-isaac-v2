-- Real main/module loading with legacy and damaged meal metadata.
-- Supplied callbacks and a detached table codec are not native Continue.
local root, selected=assert(arg[1]),arg[2]
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local function input(e,p)
    return e.fire("MC_INPUT_ACTION",nil,p,InputHook.IS_ACTION_PRESSED,ButtonAction.ACTION_SHOOTRIGHT)
end
local function remaining(e,a,b)
    assert(e.Meal:Remaining(e.players[1])==a,"first owner's debt changed")
    assert(e.Meal:Remaining(e.players[2])==b,"second owner's debt changed")
end

if not selected or selected=="migration" then
    local cases={{"text","damaged"},{"table",{}},{"true",true},{"false",false},
        {"number",17},{"negative",-3},{"large",1e100},{"missing"}}
    for _,version in ipairs({1,2}) do
        for _,case in ipairs(cases) do
            local saved={mealBreaks={
                ["0"]={version=version,remaining=45,serial=9,priorDelay=case[2]},
                ["1"]={version=2,remaining=20,serial=4}},
                extensionState={version=3,marker="keep"}}
            if version==1 then
                -- Version 1 had no reliable ownership/serial contract. Extra
                -- fields must not turn that legacy timer into a Rice lease.
                saved.mealBreaks["0"].owner="rice"
                saved.mealBreaks["0"].serial="old extra"
            end
            local e=Full.New(root,{100,0},{snapshot=saved})
            local p,q=table.unpack(e.players)
            remaining(e,45,20)
            assert(input(e,p)==false and input(e,q)==false,"both restored timers lock shooting")
            assert(not e.Meal:CancelOwned(p,"rice",version==1 and 0 or 9),
                "unowned or legacy timer cannot be cancelled as Rice")
            e.paused=true;e.step(2);remaining(e,45,20)
            e.paused=false;e.step();remaining(e,44,19)
            assert(e.Risk.state.mealBreaks["0"].priorDelay==nil,
                "unowned delay metadata must be removed: "..case[1])
            local savedAgain=e.saveSnapshot()
            assert(savedAgain.mealBreaks["0"].remaining==44,"repair must preserve countdown")
            assert(savedAgain.mealBreaks["0"].serial==(version==1 and 0 or 9),"serial migration")
            assert(savedAgain.mealBreaks["1"].serial==4,"unrelated owner's serial")
            assert(savedAgain.extensionState.marker=="keep","unrelated module preserved")
            local resumed=Full.New(root,{100,0},{snapshot=savedAgain,identityBase=20000})
            resumed.step(19);remaining(resumed,25,0)
            assert(input(resumed,resumed.players[1])==false and input(resumed,resumed.players[2])==nil,
                "owners must unlock independently")
            resumed.step(25);remaining(resumed,0,0)
            assert(input(resumed,resumed.players[1])==nil,"valid debt must eventually unlock")
        end
    end
    print("PASS meal migration: 16 legacy/unowned metadata cases retain countdowns, pause, serials and owner isolation")
end

if not selected or selected=="rice_cooker" then
    for kind=100,121 do
        local seed=Full.New(root,{kind,0});seed.step(2)
        local p,q=table.unpack(seed.players)
        p.items[seed.Item.RICE_COOKER]=1;q.items[seed.Item.RICE_COOKER]=1
        assert(seed.use(seed.Item.RICE_COOKER,p).Discharge)
        seed.step(9)
        assert(seed.use(seed.Item.RICE_COOKER,q).Discharge)
        seed.step(3);remaining(seed,78,87)
        local saved=seed.saveSnapshot()
        saved.mealBreaks["0"].priorDelay={damaged=true}
        saved.mealBreaks["1"].priorDelay="old extra"
        local e=Full.New(root,{kind,0},{snapshot=saved,inventory={p.items,q.items},identityBase=30000+kind})
        local a,b=table.unpack(e.players)
        remaining(e,78,87)
        assert(input(e,a)==false and input(e,b)==false,"Rice Cooker locks survive Continue")
        e.step(77);remaining(e,1,10)
        assert(not e.Backlog.Primed(a,"rice") and not e.Backlog.Primed(b,"rice"),"no early reward")
        e.step();remaining(e,0,9)
        assert(e.Backlog.Primed(a,"rice") and not e.Backlog.Primed(b,"rice"),"first completion only")
        local prime=e.Backlog.Data(a).primes.rice
        e.step(9);remaining(e,0,0)
        assert(e.Backlog.Primed(b,"rice") and e.Backlog.Data(a).primes.rice==prime,
            "second completion cannot duplicate the first reward")
        assert(input(e,a)==nil and input(e,b)==nil,"both owners unlock")
        local final=e.saveSnapshot()
        for _,key in ipairs({"0","1"}) do
            assert(final.mealBreaks[key].priorDelay==nil and final.backlog.players[key].riceCooker==nil,
                "re-save retains neither stale delay nor completed reward marker")
        end
    end
    print("PASS meal migration: 22 forms retain two independent Rice Cooker debts and one-time completion rewards")
end

if not selected or selected=="owned" then
    local seed=Full.New(root,{0,0});seed.step()
    local a,b=table.unpack(seed.players)
    a.FireDelay,b.FireDelay=12,20
    local ok,serialA=seed.Meal:Start(a,45,"rice");assert(ok)
    local okB,serialB=seed.Meal:Start(b,35,"rice");assert(okB)
    local saved=seed.saveSnapshot()
    local e=Full.New(root,{0,0},{snapshot=saved,identityBase=40000})
    local p,q=table.unpack(e.players)
    assert(e.Risk.state.mealBreaks["0"].priorDelay==12
        and e.Risk.state.mealBreaks["1"].priorDelay==20,"valid owned delays must survive")
    q.FireDelay=100 -- A later foreign cooldown must not be shortened by cancellation.
    e.step(3);remaining(e,42,32)
    assert(e.Meal:CancelOwned(p,"rice",serialA) and p.FireDelay==9,"restore only the owned delay")
    assert(e.Meal:CancelOwned(q,"rice",serialB) and q.FireDelay==97,"preserve the foreign delay")
    remaining(e,0,0)
    for _,value in ipairs({"damaged",{},true,-1}) do
        local invalid=Full.New(root,{0,0},{snapshot={mealBreaks={
            ["0"]={version=2,remaining=45,serial=9,owner="rice",priorDelay=value}}}})
        invalid.step();assert(invalid.Meal:Remaining(invalid.players[1])==0,
            "existing rejection of invalid owned leases must remain")
    end
    print("PASS meal migration: valid owned delays, external cooldowns and existing invalid-owned policy")
end
