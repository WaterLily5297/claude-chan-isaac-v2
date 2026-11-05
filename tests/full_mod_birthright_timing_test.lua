-- Actual main.lua callbacks with supplied inventory changes and cache resets.
-- These are not native pickup/reroll, special-body or engine timing tests.
local root = assert(arg[1])
local Full = dofile(root.."/tests/lib/full_mod_env.lua")
local roots = {"claudeUsage", "claudeAppeal", "deepseekRice", "deepseekPeak",
    "gptRouting", "gptReset", "geminiPaint", "geminiEdit", "grokCheck", "grokRatio",
    "qwenAdapter", "qwenFineTune", "llamaRelease", "llamaHype", "mistralPounce",
    "mistralBaguette", "doubaoApology", "doubaoAgain", "kimiSlides", "kimiManager", "glmQueue", "glmRetry"}
local function near(a,b,label)
    assert(math.abs(a-b)<1e-8, label..": "..tostring(a).." ~= "..tostring(b))
end
local function birth(p, value)
    p.items[CollectibleType.COLLECTIBLE_BIRTHRIGHT] = value and 1 or nil
    p:EvaluateItems() -- Explicit supplied native cache event, not automatic pickup evidence.
end
local function flip(e)
    for _,p in ipairs(e.players) do birth(p,not p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) end
end
local function duplicate(e)
    e.fire("MC_POST_UPDATE"); e.fire("MC_POST_UPDATE")
end
local function tap(e)
    e.step() -- Observe any changed eligibility while DROP is still released.
    for _,p in ipairs(e.players) do e.buttons[p.ControllerIndex]=true end
    e.step()
    for _,p in ipairs(e.players) do e.buttons[p.ControllerIndex]=false end
    e.step()
end
local function untilFrame(e, frame)
    assert(frame>=e.frame, "invalid fixture deadline")
    e.step(frame-e.frame)
end
local function state(e,i) return e.Risk.state[roots[e.kind-99]][tostring(i-1)] end
local function enemy(e,i,offset)
    local n=e.npc(e.players[i].Position.X+(offset or 30),{hp=100000})
    n.InitSeed,n.MaxHitPoints=n.hash,n.HitPoints
    function n:IsEnemy() return true end
    return n
end
local function hit(e,i,n)
    e.step()
    n:TakeDamage(10,0,EntityRef(e.primary(e.players[i])),0)
    return n.damage[#n.damage]
end
local function hurt(e,i,n)
    e.fire("MC_ENTITY_TAKE_DMG",EntityType.ENTITY_PLAYER,e.players[i],1,0,EntityRef(n),0)
end
local function case(kind, label, fn)
    if arg[2] and tonumber(arg[2])~=kind then return end
    local e=Full.New(root,{kind,kind})
    e.kind=kind
    for i,p in ipairs(e.players) do p.Position=Vector(200+(i-1)*500,0); birth(p,i==2) end
    e.clear=true; e.step(2); e.clear=false
    local lines={}
    function Isaac.RenderText(text,_,y) lines[y]=text end
    function e.hud(i)
        lines={}; e.fire("MC_POST_RENDER")
        local y=Isaac.GetScreenHeight()-40-(i-1)*24
        return (lines[y] or "").." "..(lines[y-12] or "")
    end
    fn(e,e.players[1],e.players[2])
    print("PASS Birthright timing "..kind..": "..label)
end

case(100,"suspension event, one shield per floor and no retroactive rescue",function(e,p,q)
    state(e,1).age=3; state(e,2).age=3
    e.Risk.state.risk=90; e.step()
    assert(state(e,1).age==0 and state(e,2).age==3,"first suspension reads each inventory")
    flip(e); e.step(); duplicate(e)
    assert(state(e,1).age==0 and state(e,2).age==3,"inventory changes do not replay a suspension")
    e.Risk.state.risk=0; e.step(); state(e,1).age=3
    e.Risk.state.risk=90; e.step()
    assert(state(e,1).age==3 and state(e,2).age==0,"new suspension sees gain/loss")
    birth(q,true); e.step()
    assert(state(e,2).age==0,"reacquisition does not rescue lost age")
    e.Risk.state.risk=0; e.step(); state(e,2).age=3
    e.Risk.state.risk=90; e.step()
    assert(state(e,1).age==0 and state(e,2).age==0,"reacquisition cannot renew spent floor shields")
end)

case(101,"Review samples current inventory at completion",function(e)
    for i=1,2 do state(e,i).quota=0 end
    tap(e); local start=e.frame
    for _,elapsed in ipairs({60,120,170}) do untilFrame(e,start+elapsed); flip(e) end
    untilFrame(e,start+179); duplicate(e)
    for i=1,2 do assert(state(e,i).quota==0 and state(e,i).pages==1,"pending Review paid one Page") end
    e.step()
    assert(state(e,1).quota==90 and state(e,2).quota==60,"completion must not use starting inventory")
    flip(e); e.step(); duplicate(e)
    assert(state(e,1).quota==90 and state(e,2).quota==60,"completed Review cannot pay again")
end)

case(102,"meal duration is bought once; next meal uses new inventory",function(e,p,q)
    for i=1,2 do state(e,i).bowls=2 end
    tap(e); local start=e.frame
    assert(e.Meal:Remaining(p)==60 and e.Meal:Remaining(q)==30,"both meal durations activate")
    for _,elapsed in ipairs({5,10,15}) do untilFrame(e,start+elapsed); flip(e) end
    untilFrame(e,start+29); duplicate(e)
    assert(e.Meal:Remaining(p)==31 and e.Meal:Remaining(q)==1,"pending meals retain purchased time")
    e.step(); assert(e.Meal:Remaining(p)==30 and e.Meal:Remaining(q)==0,"enhanced meal ends at 30")
    untilFrame(e,start+60)
    assert(e.Meal:Remaining(p)==0 and state(e,1).bowls==1 and state(e,2).bowls==1,"no refund or second spend")
    tap(e)
    assert(e.Meal:Remaining(p)==30 and e.Meal:Remaining(q)==60,"next meal samples current inventory")
end)

case(103,"live total cap includes the pending Peak reservation",function(e,p,q)
    flip(e)
    for i=1,2 do
        local s=state(e,i); s.compute=i==1 and 28 or 20; s.reserved=4; s.phase="peak"; s.remaining=300
    end
    e.step(); flip(e); e.step(); duplicate(e)
    assert(state(e,1).compute==20 and state(e,2).compute==20,"loss clamps total, gain grants nothing")
    flip(e); e.step()
    for i=1,2 do assert(state(e,i).compute==20 and state(e,i).reserved==4,"reacquisition cannot restore discarded Compute"); state(e,i).remaining=1 end
    e.step()
    for i=1,2 do assert(state(e,i).compute==24 and state(e,i).reserved==0,"phase transition releases only its reservation") end
    e.step(80)
    assert(state(e,1).compute==32 and state(e,2).compute==24,"future recovery uses each current cap")
end)

case(104,"Sanity Check keeps earned hits while its live threshold changes",function(e)
    local targets={enemy(e,1),enemy(e,2)}
    for i=1,2 do state(e,i).verified=false end
    tap(e)
    for i=1,2 do hit(e,i,targets[i]) end
    e.step(); flip(e); e.step(); flip(e); e.step()
    for i=1,2 do assert(not state(e,i).verified,"one hit stays pending through gain/loss") end
    for i=1,2 do hit(e,i,targets[i]) end
    e.step()
    assert(not state(e,1).verified and state(e,2).verified,"two hits only complete the enhanced check")
    flip(e); e.step(); duplicate(e)
    assert(state(e,1).verified and state(e,2).verified,"gain completes existing two-hit progress; loss keeps earned verification")
    flip(e); e.step()
    assert(state(e,1).verified and state(e,2).verified,"reacquisition does not restart the check")
end)

case(105,"live Credit cap and delayed reset claim",function(e)
    flip(e); state(e,1).credits=100; state(e,2).credits=80
    e.step(); flip(e); e.step()
    assert(state(e,1).credits==80 and state(e,2).credits==80,"cap loss clamps without a gain refill")
    flip(e); e.step(); duplicate(e)
    assert(state(e,1).credits==80,"reacquisition is not a reset claim")
    e.clear=true
    for i=1,2 do state(e,i).ready=true end
    tap(e)
    assert(state(e,1).credits==100 and state(e,2).credits==80,"banked reset samples inventory when claimed")
    for i=1,2 do assert(not state(e,i).ready,"each reset is consumed") end
end)

case(106,"dry Paint uses live owner inventory on every hit",function(e)
    local targets={enemy(e,1),enemy(e,2)}
    tap(e); e.step(30)
    for turn=1,4 do
        for i=1,2 do
            local enhanced=e.players[i]:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
            near(hit(e,i,targets[i]),enhanced and 13 or 12,"current dry Paint multiplier")
            assert(state(e,i).paint==1,"inventory changes do not buy another mark")
        end
        flip(e)
    end
end)

case(107,"Edit chain retains its initial deadline and paid step",function(e)
    local targets={enemy(e,1),enemy(e,2)}
    tap(e); local start=e.frame
    for i=1,2 do hit(e,i,targets[i]) end
    for _,elapsed in ipairs({20,40,60}) do untilFrame(e,start+elapsed); flip(e) end
    untilFrame(e,start+179); duplicate(e)
    assert(e.hud(1):find("Recolor 1/3",1,true) and e.hud(2):find("Recolor 1/3",1,true),"paid steps remain pending")
    e.step()
    assert(not e.hud(1):find("1/3",1,true) and e.hud(2):find("1/3",1,true),"normal chain expires at its original deadline")
    untilFrame(e,start+299); assert(e.hud(2):find("1/3",1,true),"enhanced chain lasts through frame 299")
    e.step(); assert(not e.hud(2):find("1/3",1,true),"loss does not shorten or renew the bought deadline")
    for i=1,2 do assert(state(e,i).doneRoom==nil,"expiry is not Export") end
    tap(e); start=e.frame; untilFrame(e,start+180)
    assert(e.hud(1):find("Crop 0/3",1,true) and not e.hud(2):find("Crop 0/3",1,true),"new chains use current inventory")
end)

case(108,"verification bullet reward samples completion inventory once",function(e)
    local targets={enemy(e,1),enemy(e,2)}; local bullets={{},{}}
    for i,p in ipairs(e.players) do for j=1,4 do bullets[i][j]=e.bullet(p.Position.X+j*3) end end
    tap(e)
    for round=1,3 do
        flip(e)
        for i=1,2 do hit(e,i,targets[i]) end
        e.step()
    end
    assert(state(e,1).verifiedRoom and state(e,2).verifiedRoom,"both checks completed")
    for j=1,4 do assert(bullets[1][j]:Exists()==(j==4) and bullets[2][j]:Exists(),"only enhanced owner clears its nearest three bullets") end
    flip(e); e.step(); duplicate(e)
    assert(bullets[1][4]:Exists() and bullets[2][1]:Exists(),"completed reward is not replayed on reacquisition")
end)

case(109,"early-death transfer samples current inventory and keeps the original deadline",function(e)
    local targets={enemy(e,1),enemy(e,2)}; local others={enemy(e,1,90),enemy(e,2,90)}
    tap(e); local start=e.frame
    for _=1,4 do for i=1,2 do hit(e,i,others[i]) end end
    e.step()
    for i=1,2 do assert(e.hud(i):find("Ratio 3/3",1,true),"four replies reach the existing three-stack cap") end
    flip(e); for _,n in ipairs(targets) do n:Remove() end; e.step()
    flip(e); e.step(); flip(e); e.step()
    untilFrame(e,start+179)
    assert(#others[1].damage==4 and #others[2].damage==4,"transfer never pays before the original quote deadline")
    e.step(); duplicate(e)
    assert(#others[1].damage==5 and #others[2].damage==4,"only eligible owner transfers floor(3/2) stacks")
    near(others[1].damage[5],e.players[1].Damage,"transferred pulse amount")
    flip(e); e.step()
    assert(#others[2].damage==4,"late acquisition cannot revive a cancelled quote")
end)

case(110,"adapter stock clamps live without disturbing installation",function(e)
    e.clear=true; flip(e); state(e,1).adapters=3; state(e,2).adapters=2
    e.step(); flip(e); e.step(); flip(e); e.step()
    for i=1,2 do assert(state(e,i).adapters==2,"cap loss is permanent; acquisition grants no stock"); state(e,i).selected=3 end
    e.clear=false; e.step(); local start=e.frame
    for i=1,2 do assert(state(e,i).adapters==1 and state(e,i).install==30,"one adapter funds each installation") end
    e.step(10); flip(e); e.step(10); flip(e); untilFrame(e,start+29); duplicate(e)
    for i=1,2 do assert(state(e,i).install==1,"inventory changes retain pending installation") end
    e.step()
    for i,p in ipairs(e.players) do assert(state(e,i).install==0 and state(e,i).adapters==1,"installation finishes once"); near(p.Damage,3.5*1.1,"Power installed") end
end)

case(111,"accumulated Fine-tune awards recalculate without compounding or erasure",function(e)
    for i=1,2 do state(e,i).awards=3; state(e,i).build=3 end
    for _=1,4 do
        for i,p in ipairs(e.players) do
            for _=1,3 do p:EvaluateItems() end
            near(p.Damage,3.5+3*(p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 0.3 or 0.2),"live award coefficient")
            assert(state(e,i).awards==3,"cache and inventory events cannot erase earned awards")
        end
        flip(e); e.step()
    end
end)

case(112,"Release samples owner inventory at release and never replays flies",function(e,p,q)
    e.clear=true; for i=1,2 do state(e,i).releases=2 end
    for _,actor in ipairs(e.players) do e.buttons[actor.ControllerIndex]=true end
    e.step(); flip(e)
    for _,actor in ipairs(e.players) do e.buttons[actor.ControllerIndex]=false end
    e.step()
    assert(p.flies==6 and q.flies==4,"two shared Releases plus only the current owner's extra flies")
    flip(e); e.step(); duplicate(e)
    assert(p.flies==6 and q.flies==4,"loss/gain cannot replay an already spent Release")
    tap(e)
    assert(p.flies==10 and q.flies==10,"next Release uses the new inventories")
    flip(e); e.step()
    for i=1,2 do assert(state(e,i).releases==0,"reacquisition grants no Release") end
end)

case(113,"helper lifetime is fixed at deployment, including the final shot",function(e,p,q)
    enemy(e,1); enemy(e,2)
    for i=1,2 do state(e,i).hype=1 end
    tap(e); local start=e.frame
    for _,elapsed in ipairs({20,40,60}) do untilFrame(e,start+elapsed); flip(e) end
    untilFrame(e,start+119); duplicate(e)
    assert(#p.fired==3 and #q.fired==3,"both helpers actually shoot")
    e.step(); assert(#p.fired==4 and #q.fired==4 and not e.hud(1):find("Helper",1,true),"normal lifetime includes its final shot")
    untilFrame(e,start+150)
    assert(#p.fired==4 and #q.fired==5 and not e.hud(2):find("Helper",1,true),"loss does not shorten enhanced helper")
    for i=1,2 do assert(state(e,i).hype==0,"spent Hype is not refunded"); state(e,i).hype=1 end
    tap(e); start=e.frame; untilFrame(e,start+150)
    assert(#p.fired==9 and #q.fired==9,"new deployment uses current inventory")
end)

case(114,"ready Pounce samples reach on activation, not during charge",function(e,p,q)
    local close={enemy(e,1),enemy(e,2)}; local far={enemy(e,1,100),enemy(e,2,100)}
    for _,actor in ipairs(e.players) do actor.Velocity=Vector(1,0); actor.aim=Vector(1,0) end
    e.step(20); flip(e); e.step(20); flip(e); e.step(20)
    for i=1,2 do assert(state(e,i).ready,"both charged without spending") end
    flip(e); tap(e); duplicate(e)
    assert(#close[1].damage==1 and #close[2].damage==1,"both swipes activate")
    assert(#far[1].damage==1 and #far[2].damage==0,"only currently enhanced swipe reaches 100 units")
    flip(e); e.step()
    assert(#far[2].damage==0,"late acquisition does not replay the swipe")
end)

case(115,"baking retains progress through live threshold changes",function(e,p,q)
    e.step(40); flip(e); e.step(4); duplicate(e)
    for i=1,2 do assert(state(e,i).baguettes==0,"no early bread") end
    e.step(); assert(state(e,1).baguettes==1 and state(e,2).baguettes==0,"gain at 40 finishes at 45")
    e.step(14); assert(state(e,2).baguettes==0,"loss keeps the 60-frame requirement")
    e.step(); assert(state(e,2).baguettes==1,"lost-Birthright bake completes at 60")
    e.newRoom(); birth(p,false); birth(q,false)
    for i=1,2 do state(e,i).baguettes=0 end
    e.step(40); birth(p,true); birth(q,true); e.step(4); birth(p,false); birth(q,false)
    e.step(10); for i=1,2 do assert(state(e,i).baguettes==0,"temporary gain did not grant bread") end
    birth(p,true); birth(q,true); e.step(); duplicate(e)
    for i=1,2 do assert(state(e,i).baguettes==1,"reacquisition uses retained progress once") end
end)

case(116,"Apology token snapshots the qualifying hit's inventory",function(e)
    local targets={enemy(e,1),enemy(e,2)}
    for i=1,2 do hurt(e,i,targets[i]) end
    local start=e.frame
    for _,elapsed in ipairs({20,40,60}) do untilFrame(e,start+elapsed); flip(e) end
    untilFrame(e,start+179); duplicate(e)
    assert(state(e,1).token==1 and state(e,2).token==0,"existing tokens retain their original lifetime")
    e.step(); assert(state(e,1).token==nil and state(e,2).token==0,"normal expiry versus room-bound token")
    e.newRoom()
    for i=1,2 do assert(state(e,i).token==nil,"room exit always cancels token"); hurt(e,i,enemy(e,i)) end
    assert(state(e,1).token==0 and state(e,2).token==180,"next qualifying hit reads current inventory")
end)

case(117,"Apology samples the phase transition and then retains that duration",function(e)
    tap(e); local start=e.frame
    for _,elapsed in ipairs({60,120,179}) do untilFrame(e,start+elapsed); flip(e) end
    e.step()
    assert(state(e,1).remaining==90 and state(e,2).remaining==120,"transition reads current inventory")
    local apology=e.frame
    for _,elapsed in ipairs({20,40,60}) do untilFrame(e,apology+elapsed); flip(e) end
    untilFrame(e,apology+89); duplicate(e)
    assert(state(e,1).remaining==1 and state(e,2).remaining==31,"pending phase retains its deadline")
    e.step(); assert(state(e,1).phase==nil and state(e,2).phase=="apology","enhanced recovery ends at 90")
    untilFrame(e,apology+120); tap(e)
    for i=1,2 do hurt(e,i,enemy(e,i)) end
    assert(state(e,1).remaining==120 and state(e,2).remaining==90,"next early-hit transition samples new inventories")
end)

case(118,"presentation cost is paid at activation with no retroactive refund",function(e)
    local targets={enemy(e,1),enemy(e,2)}
    for i=1,2 do state(e,i).slides=6 end
    tap(e); flip(e); e.step()
    assert(state(e,1).slides==3 and state(e,2).slides==4,"existing presentation keeps its paid cost")
    for i=1,2 do near(hit(e,i,targets[i]),11.5,"pending presentation still amplifies its speaker") end
    tap(e)
    assert(state(e,1).slides==1 and state(e,2).slides==1,"replacement presentation pays current cost")
    flip(e); for i=1,2 do state(e,i).slides=2 end
    tap(e)
    assert(state(e,1).slides==2 and state(e,2).slides==0,"loss can make the next activation unaffordable")
    flip(e); tap(e)
    assert(state(e,1).slides==0 and state(e,2).slides==0,"reacquisition restores discount without free Slides")
end)

case(119,"each task pulse reads current owner inventory without extending budget",function(e)
    local targets={enemy(e,1),enemy(e,2)}
    tap(e); local start=e.frame
    for pulse=1,3 do
        untilFrame(e,start+pulse*60-1); flip(e); duplicate(e)
        for i=1,2 do assert(#targets[i].damage==pulse-1,"pulse cannot fire early") end
        e.step()
        for i,p in ipairs(e.players) do
            assert(#targets[i].damage==pulse,"one scheduled pulse")
            near(targets[i].damage[pulse],p.Damage*(p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 0.7 or 0.6),"live pulse coefficient")
        end
    end
    flip(e); e.step(60)
    for i=1,2 do
        assert(#targets[i].damage==3,"reacquisition cannot add a fourth pulse")
        local spent=0; for _,n in pairs(state(e,i).budget) do spent=spent+n end
        assert(spent==3,"exactly three pulses remain spent")
    end
end)

case(120,"Access Pass snapshots redemption inventory across subsequent rooms",function(e)
    e.clear=true; for i=1,2 do state(e,i).queue=3 end
    tap(e)
    assert(state(e,1).pass==2 and state(e,2).pass==3,"both passes redeemed")
    for room=1,3 do
        flip(e); e.newRoom(); e.step(); duplicate(e)
        for i,p in ipairs(e.players) do
            local active=room<=(i==1 and 2 or 3)
            near(p.Damage,3.5*(active and 1.2 or 1),"redeemed pass room budget")
            assert(state(e,i).pass==math.max(0,(i==1 and 2 or 3)-room),"inventory changes do not resize a bought pass")
        end
    end
    e.newRoom({clear=true}); for i=1,2 do state(e,i).queue=3 end
    tap(e)
    assert(state(e,1).pass==3 and state(e,2).pass==2,"next redemption uses current inventory")
end)

case(121,"Retry reward samples failure inventory once, without a late bullet refund",function(e)
    local targets={enemy(e,1),enemy(e,2)}; local bullets={{},{}}
    for i,p in ipairs(e.players) do for j=1,2 do bullets[i][j]=e.bullet(p.Position.X+j*3) end end
    tap(e); e.step(10); flip(e); e.step(10); flip(e); e.step(10); flip(e)
    for _,n in ipairs(targets) do n:Remove() end
    e.step(); duplicate(e)
    assert(not bullets[1][1]:Exists() and bullets[1][2]:Exists() and bullets[2][1]:Exists(),"only current enhanced failure clears one bullet")
    for i=1,2 do assert(state(e,i).retries==1,"each failure awards one Retry") end
    flip(e); e.step(60)
    assert(bullets[1][2]:Exists() and bullets[2][1]:Exists(),"later inventory changes cannot replay failure")
end)
