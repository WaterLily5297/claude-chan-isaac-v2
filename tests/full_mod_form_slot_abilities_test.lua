-- Compare the same supplied ability timeline with/without live slot moves.
-- These are actual mod callbacks, not native identity or weapon acceptance.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local roots={[100]="claudeUsage",[101]="claudeAppeal",[102]="deepseekRice",[103]="deepseekPeak",
    [104]="gptRouting",[106]="geminiPaint",[107]="geminiEdit",[108]="grokCheck",[109]="grokRatio",
    [110]="qwenAdapter",[113]="llamaHype",[114]="mistralPounce",[115]="mistralBaguette",
    [117]="doubaoAgain",[118]="kimiSlides",[119]="kimiManager",[121]="glmRetry"}
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
local function observe(env)
    env.fire("MC_POST_UPDATE")
    for _,p in ipairs(env.players) do env.fire("MC_POST_PEFFECT_UPDATE",nil,p); env.fire("MC_POST_PLAYER_UPDATE",nil,p) end
end
local function tap(env)
    for _,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=true end
    env.step()
    for _,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=false end
    env.step()
end
local function scenario(kind,moves)
    local env=Full.New(root,{kind,kind})
    local actors={env.players[1],env.players[2]}
    local focus,other={},{ }
    local function enemy(x)
        local n=env.npc(x,{hp=100000}); n.InitSeed,n.MaxHitPoints=n.hash,n.HitPoints
        function n:IsEnemy() return true end
        return n
    end
    for i,p in ipairs(actors) do
        p.Position=Vector(200+(i-1)*500,0)
        focus[i],other[i]=enemy(p.Position.X+30),enemy(p.Position.X+90)
    end
    env.step(10)
    local function state(p)
        for i,q in ipairs(env.players) do
            if GetPtrHash(q)==GetPtrHash(p) then return env.Risk.state[roots[kind]][tostring(i-1)] end
        end
        error("missing actor")
    end
    for _,p in ipairs(actors) do
        local s=state(p)
        if kind==100 then s.value=60
        elseif kind==101 then s.quota=0
        elseif kind==104 then s.verified=false
        elseif kind==113 then s.hype=2
        elseif kind==114 then p.Velocity=Vector(1,0); p.aim=Vector(1,0)
        elseif kind==115 then s.baguettes=2; p.aim=Vector(1,0)
        elseif kind==118 then s.slides=3 end
    end
    env.step()
    if kind~=103 and kind~=110 and kind~=114 then tap(env) end
    local beams,beamTargets={},{}
    if kind==103 then
        for i,p in ipairs(actors) do
            p.aim=Vector(1,0)
            beams[i]=env.weapon("laser",p); beamTargets[i]=enemy(p.Position.X+125)
            env.fire("MC_POST_LASER_INIT",nil,beams[i]); beams[i].FrameCount=1
            env.fire("MC_POST_LASER_UPDATE",nil,beams[i])
        end
    end
    -- Capture all scalar state and externally visible damage/shots at each
    -- point, so a late completion cannot hide a reset or a renewed deadline.
    local timeline={}
    for frame=1,300 do
        if frame==1 or frame%11==0 then
            if moves then env.players={env.players[2],env.players[1]} end
            observe(env); observe(env)
        end
        if frame==1 and (kind==100 or kind==101 or kind==103) then
            -- Only owner 1 has already paid. After the move their sibling is
            -- free, while owner 2's first shot must still pay for its own volley.
            env.primary(actors[1])
            if moves then env.players={env.players[2],env.players[1]} end
            observe(env)
            for _,p in ipairs(actors) do env.primary(p) end
        end
        env.step()
        if kind==103 then
            for i,beam in ipairs(beams) do
                beam.FrameCount=beam.FrameCount+1
                env.fire("MC_POST_LASER_UPDATE",nil,beam)
                beamTargets[i]:TakeDamage(10,0,EntityRef(beam),0)
            end
        end
        if kind==114 and frame==70 then tap(env) end
        if frame==5 or frame==35 or frame==55 then
            for i,p in ipairs(actors) do
                if kind==107 then
                    p.Position=focus[i].Position+(frame==5 and Vector(-60,0)
                        or frame==35 and Vector(0,-60) or Vector(60,0))
                end
                local target=kind==109 and other[i] or focus[i]
                target:TakeDamage(10,0,EntityRef(env.primary(p)),0)
            end
        end
        local step={}
        for i,p in ipairs(actors) do
            step[i]={state=copy(state(p)),damage=p.Damage,delay=p.FireDelay,
                shots=#p.fired,focus=copy(focus[i].damage),other=copy(other[i].damage),
                meal=env.Meal:Remaining(p),beam=beamTargets[i] and beamTargets[i].damage[#beamTargets[i].damage] or nil}
        end
        timeline[frame]=step
    end
    return timeline
end
for kind in pairs(roots) do
    if not arg[2] or tonumber(arg[2])==kind then
        local control=scenario(kind,false)
        local first,last=control[1][1],control[300][1]
        if kind==100 then assert(first.state.appeals==0,"Appeal positive control")
        elseif kind==101 then assert(first.state.review and last.state.quota>0,"Review positive control")
        elseif kind==102 then assert(first.meal>0 and last.meal==0,"Rice positive control")
        elseif kind==103 then assert(first.beam==13,"paid primary beam positive control")
        elseif kind==104 then assert(last.state.verified,"Sanity Check positive control")
        elseif kind==106 then assert(last.focus[2]>10,"dry Paint positive control")
        elseif kind==107 then assert(last.state.doneRoom and #last.focus==4,"Export positive control")
        elseif kind==108 then assert(last.state.verifiedRoom,"fact check positive control")
        elseif kind==109 then assert(#last.focus==3,"Ratio pulses positive control")
        elseif kind==110 then assert(first.state.install>0 and last.state.install==0,"adapter install positive control")
        elseif kind==113 then assert(last.shots>0,"Hype helper positive control")
        elseif kind==114 then assert(control[60][1].state.ready and #last.focus>3,"charged Pounce positive control")
        elseif kind==115 then assert(#last.focus>3,"Baguette wave positive control")
        elseif kind==117 then assert(first.state.phase=="confident" and control[190][1].state.phase=="apology","phase positive control")
        elseif kind==118 then assert(last.focus[1]>10,"presentation positive control")
        elseif kind==119 then assert(#last.focus==6,"three task pulses positive control")
        elseif kind==121 then assert(#last.focus==4,"request positive control") end
        local moved=scenario(kind,true)
        same(moved,control,kind.."/ability timeline")
        print("PASS slot ability timeline: "..kind.." (300 frames, two owners)")
    end
end
