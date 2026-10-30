-- Real tainted Claude Appeal Pending and Banked Reset callbacks with detached save/continue snapshots.
local root=arg[1]
local frame, paused, clear, room, floor = 0, false, true, 1, 10
local callbacks, players, saved, draws, texts = {}, {}, nil, {}, {}
local C={Player={CLAUDE_CHAN=41,CLAUDE_CHAN_B=141,DEEPSEEK_CHAN=42},Item={BANKED_RESET=744,SUBAGENT_SWARM=745}}
function include(name)
    if name=="scripts.constants" then return C end
    if name=="scripts.characters.model_roster" then return {Find=function() end, IsFamily=function() return false end} end
    if name=="scripts.hud_text" then return {Draw=function(_,text) draws[#draws+1]=text end} end
    return dofile(root.."/"..name:gsub("%.","/")..".lua")
end
local function copy(v)
    if type(v)~="table" then return v end
    local result={}; for k,x in pairs(v) do result[k]=copy(x) end; return result
end
package.preload.json=function() return {
    encode=function(v) saved=copy(v); return "snapshot" end,
    decode=function() return copy(saved) end,
} end
ModCallbacks=setmetatable({}, {__index=function(_,k) return k end})
CollectibleType={COLLECTIBLE_BIRTHRIGHT=619}
CacheFlag={CACHE_DAMAGE=1,CACHE_RANGE=2,CACHE_SHOTSPEED=4,CACHE_TEARCOLOR=8}
ActiveSlot={SLOT_POCKET=2}
ButtonAction={ACTION_DROP=11}
function Color(r,g,b,a,ro,go,bo) return {R=r,G=g,B=b,A=a,RO=ro,GO=go,BO=bo} end
local down={}
Input={IsActionPressed=function(_,controller) return down[controller] or false end}
function GetPtrHash(e) return e.pointer end
function Game() return {
    GetFrameCount=function() return frame end, GetNumPlayers=function() return #players end,
    IsPaused=function() return paused end,
    GetRoom=function() return {IsClear=function() return clear end} end,
    GetLevel=function() return {
        GetDungeonPlacementSeed=function() return floor end,
        GetStage=function() return 1 end,GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=room*13,SafeGridIndex=room} end,
    } end,
    GetHUD=function() return {IsVisible=function() return true end,
        ShowItemText=function(_,title) texts[#texts+1]=title end} end,
} end
Isaac={GetPlayer=function(i) return players[i+1] end,GetScreenHeight=function() return 270 end, GetScreenWidth=function() return 480 end}
local mod={AddCallback=function(_,id,fn,param) callbacks[#callbacks+1]={id=id,fn=fn,param=param} end}
function mod:SaveData(s) self.saved=s end
function mod:LoadData() return self.saved end
function mod:HasData() return saved~=nil end
local function fire(id,...)
    for _,cb in ipairs(callbacks) do if cb.id==id then cb.fn(mod,...) end end
end
local function player(pointer,seed,controller)
    local p={pointer=pointer,InitSeed=seed,ControllerIndex=controller,kind=141,dead=false,data={}}
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:ToPlayer() return self end
    function p:GetShootingInput() return {LengthSquared=function() return self.shooting and 1 or 0 end} end
    function p:IsDead() return self.dead end
    function p:AreControlsEnabled() return true end
    function p:GetData() return self.data end
    function p:HasCollectible(id) return (id==619 and self.birthright) or (id==745 and self.swarm) end
    function p:SetPocketActiveItem(id) self.pocket=id end
    function p:AddCacheFlags() end
    function p:EvaluateItems()
        self.Damage=10; self.TearRange=100; self.ShotSpeed=1; self.TearColor=self.itemColor
        for _,f in pairs(CacheFlag) do fire("MC_EVALUATE_CACHE",self,f) end
    end
    return p
end
local Risk=include("scripts.risk")
function Risk:Add() end
local function load()
    callbacks={}
    mod:AddCallback("MC_POST_GAME_STARTED",function(_,continued)
        if continued then Risk:Load(mod) else Risk.state={} end
    end)
    mod:AddCallback("MC_PRE_GAME_EXIT",function(_,save) if save then Risk:Save(mod) end end)
    include("scripts.characters.claude_chan_b"):Init(mod,Risk)
    include("scripts.items.banked_reset"):Init(mod,Risk)
end
local function tick(n)
    for _=1,n or 1 do frame=frame+1; fire("MC_POST_UPDATE") end
end
local function state(i) return Risk.state.claudeAppeal[tostring(i or 0)] end
local function near(a,b) assert(math.abs(a-b)<1e-8,tostring(a).." ~= "..tostring(b)) end
local function tap(p)
    down[p.ControllerIndex]=false; tick()
    down[p.ControllerIndex]=true; tick()
    down[p.ControllerIndex]=false; tick()
end
local function enter(index,hostile)
    room=index; clear=not hostile; fire("MC_POST_NEW_ROOM"); tick()
end
local function finish() clear=true; fire("MC_PRE_SPAWN_CLEAN_AWARD"); tick() end
local function shot(owner,derived)
    local data={ccThoughtDerived=derived}
    local t={SpawnerEntity=owner,CollisionDamage=4}
    function t:GetData() return data end
    function t:Exists() return true end
    fire("MC_POST_FIRE_TEAR",t)
    return t
end
local function reset(p) fire("MC_USE_ITEM",744,nil,p) end
local function reload(newPlayers)
    fire("MC_PRE_GAME_EXIT",true)
    players=newPlayers; frame=0
    load(); fire("MC_POST_GAME_STARTED",true)
end

players={player(1,11,0),player(2,22,1)}; load(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
assert(state().quota==220 and state().pages==2 and state().review==nil,"a new run starts with 220 Quota and two Pages")
assert(p.pocket==744,"Banked Reset is the pocket item")
near(p.Damage,12.5); near(p.TearRange,160); near(p.ShotSpeed,1.2)

-- One paid volley costs one Quota; pellets, derived tears and duplicates share it.
local t=shot(p); assert(state().quota==219 and t.CollisionDamage==4,"the tear itself is untouched")
shot(p); fire("MC_POST_FIRE_TEAR",t); shot(p,true); assert(state().quota==219)
tick(); p.swarm=true; shot(p); assert(state().quota==217,"Subagent Swarm costs one extra Quota")
p.swarm=false
-- Laser starts and Dr. Fetus bombs share the frame's payment; familiars and placed bombs are free.
local familiar={ToPlayer=function() end}
tick(); fire("MC_POST_LASER_INIT",{SpawnerEntity=p}); shot(p); assert(state().quota==216,"a laser shares its frame's payment")
tick(); fire("MC_POST_BOMB_INIT",{SpawnerEntity=p,IsFetus=true}); assert(state().quota==215,"a Fetus bomb pays")
tick(); fire("MC_POST_BOMB_INIT",{SpawnerEntity=p,IsFetus=false}); fire("MC_POST_LASER_INIT",{SpawnerEntity=familiar})
assert(state().quota==215,"placed bombs and familiars are free")
assert(state(1).quota==220,"spending is personal")
-- Knife throws pay one Quota through the shared observer.
local knifeData={}
local knife={SpawnerEntity=p,SubType=0,GetData=function() return knifeData end,IsFlying=function() return true end}
tick(); fire("MC_POST_KNIFE_UPDATE",knife); tick(); fire("MC_POST_KNIFE_UPDATE",knife)
assert(state().quota==214,"a knife throw pays once"); state().quota=215

-- A DROP tap with Quota left keeps native DROP and spends nothing.
tap(p); assert(state().pages==2 and state().review==nil)

-- At zero, Suspended keeps a usable 0.5x attack that costs nothing.
state().quota=1; tick(); shot(p)
assert(state().quota==0 and texts[#texts]=="Suspended"); near(p.Damage,5)
near(p.TearColor.R,0.4); near(p.TearColor.A,0.7)
tick(); shot(p); assert(state().quota==0,"suspended attacks are free")

-- A review needs a Page and runs only during active combat.
down[0]=true; tick(20); down[0]=false; tick(); assert(state().pages==2,"a long hold does not appeal")
tap(p); assert(state().pages==1 and state().review.remaining==180,"a tap starts a six-second review")
tap(p); assert(state().pages==1,"one review at a time")
tick(60); assert(state().review.remaining==180,"cleared rooms freeze the review")
enter(2,true); local before=state().review
assert(before==nil,"leaving the room cancels the review without a refund")
assert(state().pages==1)
tap(p); assert(state().pages==0 and state().review.remaining==180)
paused=true; tick(30); paused=false
assert(state().review.remaining==180,"pause freezes the review")
draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="Under Review: 6s  Pages 0/2",draws[1])
p.shooting=true; tick(45); assert(state().review.remaining==180 and state().pages==0,"shooting pauses without spending another Page")
draws={}; fire("MC_POST_RENDER"); assert(draws[1]:find("Waiting for silence"))
near(p.Damage,5); p.shooting=false
tick(179); assert(state().quota==0 and state().review.remaining==1)
tick(); assert(state().review==nil and state().quota==60,"a finished review restores 60 Quota")
near(p.Damage,12.5); near(p.TearColor.R,0.85)
assert(texts[#texts]=="Appeal accepted")

-- No Pages means no review.
state().quota=0; tick(); tap(p); assert(state().review==nil and state().pages==0)
draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="DROP: No Pages left",draws[1])
tick(45); draws={}; fire("MC_POST_RENDER"); assert(draws[1]=="Suspended  Pages 0/2",draws[1])

-- Three unique combat clears earn a Page, capped at two; re-entry cannot farm.
finish(); assert(state().clears==1,"the hostile room counts once cleared")
enter(3,false); fire("MC_PRE_SPAWN_CLEAN_AWARD"); assert(state().clears==1,"a peaceful room is not a clear")
enter(2,true); finish(); assert(state().clears==1,"re-entering an awarded room cannot farm")
enter(4,true); finish(); enter(5,true); finish()
assert(state().pages==1 and state().clears==0)
for r=6,11 do enter(r,true); finish() end
assert(state().pages==2,"Pages cap at two")

-- Birthright restores 90.
enter(12,true); state().quota=0; tick(); p.birthright=true
tap(p); tick(180); assert(state().quota==90,"Birthright restores 90 Quota")
p.birthright=false

-- Banked Reset refills Quota and cancels a review without returning the Page.
state().quota=0; tick(); tap(p); local pages=state().pages
assert(state().review)
reset(p); assert(state().quota==220 and state().review==nil and state().pages==pages,"no double payout")
near(p.Damage,12.5)
reset(q); assert(state(1).quota==220)

-- Continue keeps Quota, Pages and the review timer; entities are recreated.
state().quota=0; state().pages=2; tick(); tap(p); tick(30)
local remaining=state().review.remaining; state(1).quota=77
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]
assert(state().quota==0 and state().review.remaining==remaining and state(1).quota==77,"continue preserves the allowance")
assert(p.pocket==nil,"continue does not reissue Banked Reset")
near(p.Damage,5)
tick(); assert(state().review.remaining==remaining-1,"the review resumes after continue")

-- A new floor refills Quota and Pages and drops the review; continue on it does not.
floor=20; enter(1,false)
assert(state().quota==220 and state().pages==2 and state().review==nil and next(state().awards)==nil)
near(p.Damage,12.5)
state().quota=5
reload({player(101,11,0),player(102,22,1)}); p,q=players[1],players[2]
assert(state().quota==5,"continue does not refill")

-- Identity and character changes do not transfer the allowance.
players[1]=player(101,999,0); p=players[1]; tick()
assert(state().quota==220,"a replacement player starts fresh")
state().quota=5
p.kind=41; tick(); assert(state()==nil)
shot(p); p:EvaluateItems(); near(p.Damage,10)
p.kind=141; tick(); assert(state().quota==220)

-- Corrupt saves are discarded rather than trusted.
Risk.state.claudeAppeal["0"]={version=1,quota=999,pages=2,clears=0,awards={}}
tick(); assert(state().quota==220)
Risk.state.claudeAppeal["0"]={version=1,quota=10,pages=2,clears=0,awards={},review={remaining=0/0,room="x"}}
tick(); assert(state().quota==220 and state().review==nil)

-- Item colors survive the tint.
p.itemColor=Color(0.5,1,1,1,0.2,0,0); p:EvaluateItems()
near(p.TearColor.R,0.425); near(p.TearColor.RO,0.2)

fire("MC_POST_GAME_STARTED",false)
assert(state().quota==220 and state().pages==2,"a new run resets the allowance")
print("OK: Appeal Pending quota, suspension, active-combat review, Pages, Banked Reset and save/floor/identity lifecycle")
