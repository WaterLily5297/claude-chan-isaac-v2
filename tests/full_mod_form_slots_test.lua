-- Same observed live owners across slot moves. Supplied pointer/seed identity
-- and callback order do not establish native Flip, revival or subplayer rules.
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
    assert(type(a)==type(b),label..": type changed")
    if type(a)~="table" then assert(a==b,label..": "..tostring(a).." ~= "..tostring(b)); return end
    for k,v in pairs(a) do same(v,b[k],label.."."..k) end
    for k in pairs(b) do assert(a[k]~=nil,label..": extra field "..k) end
end
local function state(env,kind,slot) return env.Risk.state[roots[kind-99]][tostring(slot)] end
local setters={
    function(s,i) s.value=i*13; s.appeals=i%3; s.age=i end,
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
    function(s,i) s.build=i%3+1; s.pinned=i%3 end,
    function(s,i) s.releases=i%3 end,
    function(s,i) s.hype=i%3 end,
    function(s,i) s.ready=i%2==0 end,
    function(s,i) s.baguettes=i%3 end,
    function(s,i) s.aimX=i%2; s.aimY=1-s.aimX end,
    function(s,i) s.phase="confident"; s.remaining=i*20 end,
    function(s,i) s.slides=i%3 end,
    function(s,i) s.budget["former_"..i]=3 end,
    function(s,i) s.queue=i%3 end,
    function(s,i) s.retries=i%3 end,
}
local function observe(env)
    -- Duplicate same-frame callbacks must rebind without aging clocks twice.
    env.fire("MC_POST_UPDATE")
    for _,p in ipairs(env.players) do
        env.fire("MC_POST_PEFFECT_UPDATE",nil,p)
        env.fire("MC_POST_PLAYER_UPDATE",nil,p)
    end
end
local function setup(kind,mixed)
    local env=Full.New(root,mixed and {kind,0,kind,0} or {kind,kind,kind,kind})
    env.step(10)
    for i,p in ipairs(env.players) do
        if p.kindId==kind then setters[kind-99](state(env,kind,i-1),i) end
    end
    env.step()
    local expected={}
    for i,p in ipairs(env.players) do
        if p.kindId==kind then expected[p.hash]=copy(state(env,kind,i-1)) end
    end
    return env,expected
end
local function check(env,kind,expected,label)
    for i,p in ipairs(env.players) do
        local s=state(env,kind,i-1)
        if p.kindId==kind then same(s,assert(expected[p.hash]),kind.."/"..label.."/"..i)
        elseif kind~=100 then assert(s==nil,"a vanilla slot inherited form state") end
    end
end
for kind=100,121 do
    if not arg[2] or tonumber(arg[2])==kind then
        for _,mixed in ipairs({false,true}) do
            local env,expected=setup(kind,mixed)
            -- Four rotations include occupied, vacant and mixed-form slots.
            for turn=1,4 do
                local p=env.players
                env.players={p[4],p[1],p[2],p[3]}
                env.paused=turn==2
                observe(env); observe(env)
                check(env,kind,expected,"rotation "..turn)
                env.paused=false
            end
            -- Rewrapping and controller changes keep form state, but do not
            -- claim that an old physical DROP press is valid on a new controller.
            local p=env.players[1]
            env.players[1]=setmetatable({}, {__index=p,__newindex=p})
            p.ControllerIndex=8; observe(env)
            check(env,kind,expected,"wrapper/controller")
            env.players[1]=p

            -- Observe a final move before save. The detached snapshot restores
            -- slots to new identities; no old live binding is serialized.
            local a=env.players; env.players={a[3],a[4],a[1],a[2]}; observe(env)
            check(env,kind,expected,"before save")
            local saved=env.saveSnapshot()
            local kinds={}; for i,q in ipairs(env.players) do kinds[i]=q.kindId end
            local resumed=Full.New(root,kinds,{snapshot=saved,identityBase=10000})
            same(saved[roots[kind-99]],resumed.Risk.state[roots[kind-99]],kind.."/Continue")
        end
        -- Removing one owner must not clear the surviving moved owner's record.
        local env,expected=setup(kind,false)
        local original=env.players
        env.players={original[3],original[1]}; observe(env)
        check(env,kind,expected,"departure")
        assert(state(env,kind,2)==nil and state(env,kind,3)==nil,"vacated slots remain in save")
        -- An observed departure is not a parked identity. A later join starts
        -- fresh, including the former entity returning after absence.
        env.players[3]=original[4]; observe(env)
        assert(state(env,kind,2)~=nil and state(env,kind,2)~=state(env,kind,0),"join aliases another owner")
        setters[kind-99](state(env,kind,2),4); env.step()
        local old=state(env,kind,2)
        original[4].InitSeed=original[4].InitSeed+1000; observe(env)
        assert(state(env,kind,2)~=old,"new seed must replace the old record")
        setters[kind-99](state(env,kind,2),4); env.step()
        old=state(env,kind,2)
        original[4].hash=original[4].hash+100000; observe(env)
        assert(state(env,kind,2)~=old,"new pointer must replace the old record")
        setters[kind-99](state(env,kind,2),4); env.step()
        old=state(env,kind,2); local before=copy(old)
        local function debt()
            -- The separate Review module cancels its task on type departure;
            -- Claude's exception retains account debt, allowance and age.
            for _,key in ipairs({"value","limited","appeals","age","clears"}) do
                assert(state(env,kind,2)[key]==before[key],"same-owner Claude account "..key)
            end
        end
        original[4].kindId=0; observe(env)
        if kind==100 then debt()
        else assert(state(env,kind,2)==nil,"type departure must still discard former form state") end
        original[4].kindId=kind; observe(env)
        if kind==100 then debt()
        else assert(state(env,kind,2)~=old,"returning form starts fresh after observed departure") end
        print("PASS form slots: "..kind.." duplicate/mixed moves, wrapper/controller, departed owner and Continue")
    end
end
