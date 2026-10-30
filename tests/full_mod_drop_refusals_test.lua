-- Actual main.lua, supplied state/input and captured text: offline only.
-- Does not prove physical DROP timing, native font widths or HUD placement.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local roots={"claudeUsage","claudeAppeal","deepseekRice","deepseekPeak",
    "gptRouting","gptReset","geminiPaint","geminiEdit","grokCheck","grokRatio",
    "qwenAdapter","qwenFineTune","llamaRelease","llamaHype","mistralPounce",
    "mistralBaguette","doubaoApology","doubaoAgain","kimiSlides","kimiManager","glmQueue","glmRetry"}
local function states(env,kind,fn)
    for i,p in ipairs(env.players) do fn(env.Risk.state[roots[kind-99]][tostring(i-1)],p,i) end
end
local function roomKey()
    local level=Game():GetLevel()
    return level:GetDungeonPlacementSeed()..":"..level:GetCurrentRoomDesc().SpawnSeed
end
local function tap(env,one)
    for i,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=not one or i==one end
    env.step()
    for _,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=false end
    env.step()
end
local function capture(env)
    local draws={}
    Isaac.RenderText=function(text,x,y) draws[#draws+1]={text=text,x=x,y=y} end
    env.fire("MC_POST_RENDER")
    local cues={}
    for _,d in ipairs(draws) do
        if d.text:sub(1,6)=="DROP: " then cues[#cues+1]=d end
    end
    return cues,draws
end
local function resources(env,kind)
    local values={}
    states(env,kind,function(s)
        for _,key in ipairs({"appeals","quota","pages","bowls","credits","paint","releases",
                "hype","baguettes","slides","queue","pass","selected","build","fullSend","saving"}) do
            values[#values+1]=key.."="..tostring(s[key])
        end
        local budget=0; for _,v in pairs(s.budget or {}) do budget=budget+v end
        values[#values+1]="budget="..budget
    end)
    return table.concat(values,";")
end
local cases={
    {100,"No Usage to appeal"},
    {100,"No Appeals left",function(s) s.appeals=0; s.value=10 end},
    {100,"Usage limit active",function(s) s.limited=90 end},
    {101,"Quota remains"},
    {101,"No Pages left",function(s) s.quota=0; s.pages=0 end},
    {101,"Review in progress",function(s) s.quota=0 end,first=true},
    {102,"No Rice bowls left",function(s) s.bowls=0 end},
    {102,"Stand still to eat",function(_,p) p.move=Vector(1,0) end},
    {102,"Meal in progress",first=true},
    {103,"Toggle cooling down",first=true},
    {104,"Already Verified"},
    {104,"Check spent this room",function(s) s.verified=false; s.checkRoom=roomKey() end},
    {104,"Check in progress",function(s) s.verified=false end,first=true,enemies=1},
    {104,"No target in range",function(s) s.verified=false end},
    {105,"No Credits left",function(s) s.credits=0 end},
    {105,"Claim reset between fights",function(s) s.credits=0; s.ready=true end},
    {106,"No Paint left",function(s) s.paint=0 end},
    {106,"No target in range"},
    {107,"Already exported this room",function(s) s.doneRoom=roomKey() end},
    {107,"No target in range"},
    {108,"Needs combat",clear=true},
    {108,"Check spent this room",function(s) s.checkRoom=roomKey() end},
    {108,"Check in progress",first=true,enemies=1},
    {108,"No target in range"},
    {109,"Quote cooling down",first=true,enemies=1},
    {109,"No target in range"},
    {111,"Change build between fights"},
    {111,"Pinned: clear 2 new rooms",function(s) s.pinned=2 end,clear=true},
    {112,"No Releases left",function(s) s.releases=0 end},
    {112,"Release between fights"},
    {113,"No Hype yet"},
    {114,"Charge: move while firing"},
    {115,"No Baguettes left"},
    {115,"Wave cooling down",function(s) s.baguettes=2 end,first=true},
    {116,"No Apology ready"},
    {117,"Already Confident",first=true},
    {117,"Still recovering",function(s) s.phase="apology"; s.remaining=120 end},
    {118,"Not enough Slides",function(s) s.slides=0 end},
    {118,"No target in range",function(s) s.slides=3 end},
    {119,"Needs combat",clear=true},
    {119,"Room pulse budget spent",function(s) s.budget[roomKey()]=9 end},
    {119,"All task slots busy",first=3,enemies=4},
    {119,"No unassigned target nearby"},
    {119,"No unassigned target nearby",first=true,enemies=1},
    {120,"Queue below 3/3"},
    {120,"Access Pass active",function(s) s.queue=3; s.pass=1 end},
    {121,"Needs combat",clear=true},
    {121,"Request cooling down",first=true,enemies=1},
    {121,"No target in range"},
}
for _,case in ipairs(cases) do
    local kind,reason=case[1],case[2]
    local env=Full.New(root,{kind,kind,kind,kind},{enemies=case.enemies or 0})
    env.clear=case.clear or false; env.step(10)
    if case[3] then states(env,kind,case[3]) end
    env.step() -- Observe a release after supplied eligibility changes.
    if case.first then
        for _=1,type(case.first)=="number" and case.first or 1 do tap(env) end
    end
    env.step()
    local before=resources(env,kind)
    local captions,sounds=env.metrics.captions or 0,env.metrics.sounds or 0
    tap(env)
    local cues,draws=capture(env)
    assert(#cues==4,kind.."/"..reason..": expected four refusal lines, got "..#cues)
    local rows={}
    for i,d in ipairs(cues) do
        assert(d.text=="DROP: "..reason,kind..": "..d.text.." ~= "..reason)
        assert(d.x==50 and d.y==230-(i-1)*24,"owner must retain their own HUD band")
        assert(#d.text<=40,"refusal exceeds conservative narrow-screen character budget")
        rows[d.y]=true
    end
    for _,d in ipairs(draws) do
        assert(not rows[d.y] or d.text:sub(1,6)=="DROP: ","old form HUD overlaps refusal")
    end
    assert(resources(env,kind)==before,kind.." refusal spent a resource or changed a choice")
    assert((env.metrics.captions or 0)==captions and (env.metrics.sounds or 0)==sounds,
        kind.." refusal emitted a shared caption or sound")
end

-- Native cycling and long holds are silent on all 22 forms, including Qwen.
for kind=100,121 do
    for _,mode in ipairs({"pockets","hold"}) do
        local env=Full.New(root,{kind,kind}); env.step(10)
        for _,p in ipairs(env.players) do
            if mode=="pockets" then
                function p:GetCard(slot) return slot==0 and 1 or 0 end
                p.active[2]=999
            end
        end
        local before=resources(env,kind)
        for _,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=true end
        env.step(mode=="hold" and 13 or 1)
        for _,p in ipairs(env.players) do env.buttons[p.ControllerIndex]=false end
        env.step()
        assert(#capture(env)==0,kind.."/"..mode.." must stay silent")
        assert(resources(env,kind)==before,kind.."/"..mode.." changed ability resources")
    end
end

-- Qwen's unconditional selection still succeeds; mixed-family messages only
-- occupy the tapped player's band. Successful actions restore normal HUD text.
do
    local env=Full.New(root,{110,113,106,100}); env.step(10)
    local q=env.Risk.state.qwenAdapter["0"]; local selected=q.selected
    tap(env,1); assert(q.selected~=selected and #capture(env)==0)
    tap(env,2); local cues=capture(env)
    assert(#cues==1 and cues[1].y==206 and cues[1].text=="DROP: No Hype yet")
    tap(env,3); cues=capture(env); assert(#cues==2)
    local n=env.npc(260,{hp=10000}); n.InitSeed=n.hash; function n:IsEnemy() return true end
    tap(env,3); cues=capture(env)
    assert(#cues==1 and cues[1].y==206,"successful Paint removes only its own old refusal")
end

-- Cues never enter actual saves and cannot survive room changes or Continue.
do
    local env=Full.New(root,{113}); env.step(10); tap(env); assert(#capture(env)==1)
    local saved=env.saveSnapshot()
    local function noCue(value)
        if type(value)~="table" then return end
        for k,v in pairs(value) do
            assert(k~="untilFrame" and k~="cues" and k~="gestures","transient cue serialized")
            if type(v)=="string" then assert(not v:find("DROP:",1,true),"cue text serialized") end
            noCue(v)
        end
    end
    noCue(saved)
    local resumed=Full.New(root,{113},{snapshot=saved,identityBase=10000})
    resumed.step(); assert(#capture(resumed)==0)
    tap(resumed); assert(#capture(resumed)==1)
    resumed.newRoom(); resumed.step(); assert(#capture(resumed)==0)
end
print("OK: "..#cases.." four-player refusal cases, 44 native-gesture cases, mixed HUD and transient saves")
