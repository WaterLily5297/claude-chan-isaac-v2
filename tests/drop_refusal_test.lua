-- Feedback observes input independently; it must not authorize an action.
local Drop=dofile(assert(arg[1]).."/scripts/characters/drop_tap.lua")
local now,paused,pressed=0,false,{}
function Game() return {GetFrameCount=function() return now end,IsPaused=function() return paused end} end
function GetPtrHash(p) return p.hash end
ButtonAction={ACTION_DROP=11}
Input={IsActionPressed=function(_,c) return pressed[c] or false end}
local function player(hash)
    return {hash=hash,InitSeed=hash,ControllerIndex=hash,kind=100,
        GetPlayerType=function(p) return p.kind end,
        IsDead=function(p) return p.dead end,IsCoopGhost=function(p) return p.ghost end,
        AreControlsEnabled=function(p) return not p.disabled end,
        GetCard=function(p,slot) return slot==0 and p.card or 0 end,
        GetPill=function() return 0 end,GetActiveItem=function(p,slot) return slot==2 and p.pocket or 0 end,
        card=0,pocket=0}
end
local p,q=player(1),player(2)
local tracker=Drop.New()
local function poll(p,down,enabled,reason)
    pressed[p.ControllerIndex]=down
    return tracker:Poll(p,enabled,reason)
end
local function step(p,down,enabled,reason)
    now=now+1; return poll(p,down,enabled,reason)
end
local draws={}
local hud={Draw=function(_,text,x,y) draws[#draws+1]={text=text,x=x,y=y} end}
local layout={DrawPlayer=function(hud,index,text,...) hud:Draw(text,50,230-index*24,...) end}
local function cue(p,expected)
    draws={}; local shown=tracker:DrawRefusal(p,hud,layout,0)
    assert(shown==(expected~=nil),"cue presence: "..tostring(expected))
    if expected then
        assert(#draws==1 and draws[1].text=="DROP: "..expected,draws[1] and draws[1].text)
        assert(#draws[1].text<=40 and draws[1].x==50 and draws[1].y==230)
    end
end
step(p,false,false,"No Paint left")
assert(not step(p,true,false,"No Paint left")); cue(p)
assert(not step(p,false,false,"No Paint left")); cue(p,"No Paint left")
local start=now
assert(not poll(p,false,false,"No Paint left")); cue(p,"No Paint left")
-- Repeated refused taps do not extend the 45-frame flash.
step(p,true,false,"No Paint left"); step(p,false,false,"No Paint left")
tracker:Refuse(p,"No target in range")
now=start+44; cue(p,"No target in range"); now=start+45; cue(p)

-- A refusal after a successful input observation (for example no target) has
-- the same non-extending deadline. A successful action clears it at render.
tracker:Reset(); step(p,false,true); step(p,true,true)
assert(step(p,false,true)); tracker:Refuse(p,"No target in range"); cue(p,"No target in range")
start=now
step(p,true,true); assert(step(p,false,true)); tracker:Refuse(p,"No target in range")
now=start+45; cue(p)
step(p,true,true); assert(step(p,false,true)); tracker:Refuse(p,"No target in range")
step(p,true,true); assert(step(p,false,true)); cue(p)

-- Losing eligibility at any sampled point still cancels the action. Gaining
-- it while held cannot turn the feedback observer into a queued ability.
for _,stage in ipairs({"press","held","release","same-frame"}) do
    tracker:Reset(); step(p,false,true)
    assert(not step(p,true,stage~="press","No Paint left"))
    if stage=="same-frame" then assert(not poll(p,true,false,"No Paint left")) end
    assert(not step(p,true,stage~="held","No Paint left"))
    assert(not step(p,false,stage~="release","No Paint left"))
    cue(p,stage=="release" and "No Paint left" or "State changed; tap again")
    step(p,false,true); step(p,true,true); assert(step(p,false,true)); cue(p)
end

-- Every native-input suppression cancels feedback as well as abilities.
for _,why in ipairs({"pockets","hold","pause","death","ghost","controls","controller","seed","kind","reset","forget","rollback"}) do
    tracker:Reset(); p.card,p.pocket=0,0; p.dead,p.ghost,p.disabled=false,false,false; paused=false
    step(p,false,false,"No Paint left"); step(p,true,false,"No Paint left")
    if why=="pockets" then p.card,p.pocket=1,2
    elseif why=="hold" then now=now+13
    elseif why=="pause" then paused=true
    elseif why=="death" then p.dead=true
    elseif why=="ghost" then p.ghost=true
    elseif why=="controls" then p.disabled=true
    elseif why=="controller" then p.ControllerIndex=p.ControllerIndex+1
    elseif why=="seed" then p.InitSeed=p.InitSeed+1
    elseif why=="kind" then p.kind=p.kind+1
    elseif why=="reset" then tracker:Reset()
    elseif why=="forget" then tracker:Forget(p)
    elseif why=="rollback" then now=0 end
    assert(not step(p,true,false,"No Paint left")); cue(p)
    p.card,p.pocket=0,0; p.dead,p.ghost,p.disabled=false,false,false; paused=false
    assert(not step(p,false,false,"No Paint left")); cue(p)
end

-- Active flashes are transient, identity-bound and independent in co-op.
for _,why in ipairs({"pause","death","ghost","controls","controller","seed","kind","reset","forget","rollback"}) do
    tracker:Reset(); now=100; p.dead,p.ghost,p.disabled=false,false,false; paused=false
    tracker:Refuse(p,"No Paint left"); tracker:Refuse(q,"No Hype yet")
    if why=="pause" then paused=true
    elseif why=="death" then p.dead=true
    elseif why=="ghost" then p.ghost=true
    elseif why=="controls" then p.disabled=true
    elseif why=="controller" then p.ControllerIndex=p.ControllerIndex+1
    elseif why=="seed" then p.InitSeed=p.InitSeed+1
    elseif why=="kind" then p.kind=p.kind+1
    elseif why=="reset" then tracker:Reset()
    elseif why=="forget" then tracker:Forget(p)
    elseif why=="rollback" then now=0 end
    cue(p)
    if why~="pause" and why~="reset" and why~="rollback" then cue(q,"No Hype yet") end
end
print("OK: refusal gestures preserve cancellation, transient cue deadlines and owner isolation")
