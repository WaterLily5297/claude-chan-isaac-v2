-- Real usage/item callbacks across a process-style save boundary.
-- JSON is a detached snapshot stub; engine save-file acceptance stays separate.
local root = arg[1]
local callbacks, players, frame, saved = {}, {}, 1, nil
local C = {Player={CLAUDE_CHAN=41}, Item={BAN_HAMMER=733, COMPACT=735, BANKED_RESET=744}}
local Hud = {T=function(_,key,...) return key..":"..table.concat({...},",") end, Draw=function() end}
function include(name)
    if name=="scripts.constants" then return C end
    if name=="scripts.characters.model_roster" then return {Find=function() end} end
    if name=="scripts.hud_text" then return Hud end
    return dofile(root.."/"..name:gsub("%.","/")..".lua")
end
local function copy(v)
    if type(v)~="table" then return v end
    local t={}; for k,x in pairs(v) do t[k]=copy(x) end; return t
end
package.preload.json=function() return {
    encode=function(v) saved=copy(v); return "snapshot" end,
    decode=function() return copy(saved) end,
} end
ModCallbacks=setmetatable({}, {__index=function(_,k) return k end})
CacheFlag={CACHE_DAMAGE=1}; ActiveSlot={SLOT_POCKET=2}
CollectibleType={COLLECTIBLE_BIRTHRIGHT=619}; ButtonAction={ACTION_DROP=11}
local down, clear, room, floor, paused = false, true, 1, 1, false
Input={IsActionPressed=function() return down end}
EntityType={ENTITY_PROJECTILE=9}; EntityFlag={FLAG_FRIENDLY=1}
function Color(...) return {...} end
function EntityRef(p) return p end
function GetPtrHash(p) return p.pointer end
local nextPointer=0
local function player(kind)
    nextPointer=nextPointer+1
    local p={kind=kind or 41,pointer=nextPointer,data={},InitSeed=nextPointer,ControllerIndex=0}
    function p:IsDead() return self.dead or false end
    function p:AreControlsEnabled() return true end
    function p:HasCollectible(id) return id==619 and self.birthright end
    function p:GetShootingInput() return {LengthSquared=function() return self.shooting and 1 or 0 end} end
    function p:GetPlayerType() return self.kind end
    function p:GetCard() return 0 end
    function p:GetPill() return 0 end
    function p:GetActiveItem() return 0 end
    function p:GetData() return self.data end
    function p:ToPlayer() return self end
    function p:SetPocketActiveItem(id) self.pocket=id end
    function p:AddCacheFlags() end
    function p:EvaluateItems()
        self.evaluations=(self.evaluations or 0)+1
        self.Damage=3.5
        for _,c in ipairs(callbacks) do if c.id=="MC_EVALUATE_CACHE" then c.fn(mod,self,CacheFlag.CACHE_DAMAGE) end end
    end
    return p
end
Isaac={GetPlayer=function(i) return players[i+1] end,
    GetRoomEntities=function() return {} end, GetScreenHeight=function() return 270 end}
function Game() return {GetNumPlayers=function() return #players end,
    GetFrameCount=function() return frame end, IsPaused=function() return paused end,
    GetRoom=function() return {IsClear=function() return clear end} end,
    GetLevel=function() return {GetDungeonPlacementSeed=function() return floor end,
        GetStage=function() return 1 end, GetStageType=function() return 0 end,
        GetCurrentRoomDesc=function() return {SpawnSeed=room,SafeGridIndex=room} end} end,
    GetHUD=function() return {ShowItemText=function() end,IsVisible=function() return true end} end} end
local mod={}
function mod:AddCallback(id,fn,param) callbacks[#callbacks+1]={id=id,fn=fn,param=param} end
function mod:SaveData(s) self.saved=s end
function mod:HasData() return saved~=nil end
function mod:LoadData() return self.saved end
local Risk=include("scripts.risk")
function Risk:IsSuspended() return false end
function Risk:Add(n) self.state.risk=(self.state.risk or 0)+n end
local function fire(id,...)
    for _,c in ipairs(callbacks) do
        if c.id==id and (id~="MC_USE_ITEM" or c.param==select(1,...)) then c.fn(mod,...) end
    end
end
local function module()
    callbacks={}
    -- Match main.lua: Risk loads/saves before the character lifecycle callback.
    mod:AddCallback("MC_POST_GAME_STARTED",function(_,continued)
        if continued then Risk:Load(mod) else Risk.state={} end
    end)
    mod:AddCallback("MC_PRE_GAME_EXIT",function(_,save) if save then Risk:Save(mod) end end)
    include("scripts.items.compact"):Init(mod)
    include("scripts.items.banked_reset"):Init(mod,Risk)
    include("scripts.characters.claude_chan"):Init(mod,Risk)
end
-- Each call is a separate volley on a new frame.
local function shot(p)
    frame=frame+1
    local data={}
    local t={SpawnerEntity=p,CollisionDamage=10,GetData=function() return data end}
    fire("MC_POST_FIRE_TEAR",t); return t
end
local function wrap(p) return setmetatable({}, {__index=p,__newindex=p}) end
players={player(),player()}; module(); fire("MC_POST_GAME_STARTED",false)
for _=1,25 do shot(players[1]) end
for _=1,5 do shot(players[2]);fire("MC_POST_PEFFECT_UPDATE",players[1]) end
assert(players[1].data.ccUsage.limited==145)
assert(players[2].data.ccUsage.value==20)
fire("MC_PRE_GAME_EXIT",true)
players={player(),player()}; module()
fire("MC_POST_NEW_LEVEL"); fire("MC_POST_GAME_STARTED",true)
assert(math.abs(players[1].Damage-3.5*0.4)<1e-9 and math.abs(players[2].Damage-3.5)<1e-9,
    "continue must not erase an active usage limit")
shot(wrap(players[1]))
assert(players[1].data.ccUsage.limited==145,"continue must preserve the remaining countdown")
assert(shot(players[2]).CollisionDamage==10 and players[2].data.ccUsage.value==24,
    "each continued player must retain their own meter")
assert(players[1].data.ccUsage~=players[2].data.ccUsage,"co-op meters must not alias")

-- Item changes must be saved even before a later character update/tear callback.
fire("MC_USE_ITEM",C.Item.COMPACT,nil,players[2])
assert(players[2].data.ccUsage.value==74)
fire("MC_USE_ITEM",C.Item.BANKED_RESET,nil,players[1])
assert(players[1].data.ccUsage.value==0 and players[1].data.ccUsage.limited==0)
fire("MC_POST_PEFFECT_UPDATE",players[1])
assert(math.abs(players[1].Damage-3.5)<1e-9,"an item that clears Limited restores damage on the next update")
assert(players[2].data.ccUsage.value==74)
fire("MC_PRE_GAME_EXIT",true)
players={player(),player()}; module(); fire("MC_POST_GAME_STARTED",true)
assert(shot(players[1]).CollisionDamage==10 and players[1].data.ccUsage.value==4)
assert(players[2].data.ccUsage.value==74,"Compact must persist without another update")

-- An observed character change and a rewrapped player retain the same slot debt.
players[2].kind=0; fire("MC_POST_PEFFECT_UPDATE",players[2])
players[2].kind=41; fire("MC_POST_PEFFECT_UPDATE",wrap(players[2]))
assert(players[2].data.ccUsage.value==74)

for _=1,7 do shot(players[2]) end
assert(players[2].data.ccUsage.limited==150)
for _=1,149 do frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",wrap(players[2])) end
assert(players[2].data.ccUsage.limited==1)
fire("MC_PRE_GAME_EXIT",true); players={player(),player()}; module(); fire("MC_POST_GAME_STARTED",true)
assert(math.abs(players[2].Damage-3.5*0.4)<1e-9,"the last Limited frame survives continue")
shot(players[2])
fire("MC_POST_PEFFECT_UPDATE",players[2])
assert(players[2].data.ccUsage.limited==0 and players[2].data.ccUsage.value==0)
assert(math.abs(players[2].Damage-3.5)<1e-9,"the end of Limited restores the damage stat")
for _=1,5 do shot(players[2]); fire("MC_POST_PEFFECT_UPDATE",players[2]) end
assert(players[2].data.ccUsage.value==20,"a paid volley's own frame never drains")
players[2].shooting=true
for _=1,30 do frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",players[2]) end
assert(players[2].data.ccUsage.value==20,"held fire blocks the drain")
players[2].shooting=false
for _=1,30 do frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",players[2]) end
assert(players[2].data.ccUsage.value==10,"not firing drains 10 per second")
players[2].data.ccUsage.value=0

-- A fresh run on reused player objects must not inherit their former aliases.
fire("MC_PRE_GAME_EXIT",false); fire("MC_POST_GAME_STARTED",false)
assert(shot(players[1]).CollisionDamage==10 and players[1].data.ccUsage.value==4)
assert(players[2].data.ccUsage.value==0)
fire("MC_PRE_GAME_EXIT",false)
local before=players[1].data.ccUsage.value
fire("MC_POST_PEFFECT_UPDATE",players[1]); shot(players[1])
assert(players[1].data.ccUsage.value==before,"inactive callbacks must not mutate run usage")
-- Old saves have no usage record; initialize safely without inventing a penalty.
saved={risk=0}; players={player()}; module();fire("MC_POST_GAME_STARTED",true)
assert(shot(players[1]).CollisionDamage==10 and players[1].data.ccUsage.value==4)

-- Timer progress belongs to gameplay frames, not callback invocation count.
players={player(),player()}; module(); fire("MC_POST_GAME_STARTED",false)
local p,q=players[1],players[2]
local a,b=p.data.ccUsage,q.data.ccUsage
a.value=100; a.limited=150; b.value=100; b.limited=90
frame=frame+1
fire("MC_POST_PEFFECT_UPDATE",p); fire("MC_POST_PEFFECT_UPDATE",wrap(p))
fire("MC_POST_PEFFECT_UPDATE",q); fire("MC_POST_PEFFECT_UPDATE",wrap(q))
assert(a.limited==149 and b.limited==89,"duplicate wrappers must not shorten either player's timer")
paused=true; frame=frame+1
fire("MC_POST_PEFFECT_UPDATE",p); fire("MC_POST_PEFFECT_UPDATE",q)
assert(a.limited==149 and b.limited==89,"paused callbacks must freeze timers")
paused=false; p.dead=true; frame=frame+1
fire("MC_POST_PEFFECT_UPDATE",p); fire("MC_POST_PEFFECT_UPDATE",q)
assert(a.limited==149 and b.limited==88,"a dead player's timer freezes without blocking the partner")
p.dead=false; frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",wrap(p))
assert(a.limited==148,"revival resumes one frame without catching up skipped time")
for _=1,147 do
    frame=frame+1
    fire("MC_POST_PEFFECT_UPDATE",p); fire("MC_POST_PEFFECT_UPDATE",wrap(p))
end
assert(a.limited==1 and a.value==100,"duplicate callbacks must not expire the five-second limit early")
frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",p)
assert(a.limited==0 and a.value==0,"the final active frame expires and clears usage once")

-- Drain has the same once-per-frame, pause and death contract.
a.value=10; b.value=20; b.limited=0
frame=frame+3-frame%3
fire("MC_POST_PEFFECT_UPDATE",p); fire("MC_POST_PEFFECT_UPDATE",wrap(p))
fire("MC_POST_PEFFECT_UPDATE",q); fire("MC_POST_PEFFECT_UPDATE",wrap(q))
assert(a.value==9 and b.value==19,"a drain frame subtracts one per player")
paused=true; frame=frame+3; fire("MC_POST_PEFFECT_UPDATE",p)
assert(a.value==9,"pause must not drain usage")
paused=false; p.dead=true; frame=frame+3; fire("MC_POST_PEFFECT_UPDATE",p)
assert(a.value==9,"death must not drain usage")
p.dead=false; p.shooting=true; frame=frame+3; fire("MC_POST_PEFFECT_UPDATE",p)
assert(a.value==9,"held fire still blocks drainage")

-- A new run may reuse the same pointer and frame; no stale timer guard survives.
fire("MC_PRE_GAME_EXIT",false); fire("MC_POST_GAME_STARTED",false)
a=p.data.ccUsage; a.value=100; a.limited=150
fire("MC_POST_PEFFECT_UPDATE",p)
assert(a.limited==149,"fresh-run lifecycle clears the transient frame guard")
fire("MC_PRE_GAME_EXIT",true); fire("MC_POST_GAME_STARTED",true)
a=p.data.ccUsage
fire("MC_POST_PEFFECT_UPDATE",wrap(p))
assert(a.limited==148,"continue at the same frame clears transient guards without erasing debt")
for _, interruption in ipairs({"pause", "death"}) do
    a.limited=0; a.value=60; a.appeals=1
    down=false; frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",p)
    down=true; frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",p)
    paused=interruption=="pause"; p.dead=interruption=="death"
    fire("MC_POST_PEFFECT_UPDATE",wrap(p)) -- Interrupt even after this frame was already processed.
    paused=false; p.dead=false
    down=false; frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",p)
    assert(a.appeals==1 and a.value==60,"interrupted DROP release must not consume an Appeal")
    down=true; frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",p)
    down=false; frame=frame+1; fire("MC_POST_PEFFECT_UPDATE",p)
    assert(a.appeals==0 and a.value==20,"a fresh DROP gesture after recovery still works")
end
-- Live slot replacement must not transfer another entity's account/debt.
-- Continue is a separate boundary: the existing detached-load cases above stay valid.
fire("MC_PRE_GAME_EXIT",false); players={player(),player()}; module()
fire("MC_POST_GAME_STARTED",false)
p,q=players[1],players[2]
local oldUsage, partnerUsage=p.data.ccUsage,q.data.ccUsage
oldUsage.age=5; oldUsage.value=48; oldUsage.appeals=2
partnerUsage.age=3; partnerUsage.value=28; partnerUsage.appeals=2
players[1]=player(); players[1].InitSeed=p.InitSeed; p=players[1]
fire("MC_POST_UPDATE"); p:EvaluateItems()
assert(p.data.ccUsage~=oldUsage and p.data.ccUsage.age==0,
    "a replacement player must not inherit another Claude's account age")
assert(p.data.ccUsage.value==0 and p.data.ccUsage.appeals==1,
    "replacement accounts start with the existing fresh allowance")
assert(Risk.state.claudeUsage["1"]==partnerUsage and partnerUsage.value==28 and partnerUsage.age==3,
    "retiring one slot must not reset the partner")
fire("MC_USE_ITEM",C.Item.COMPACT,nil,p)
assert(p.data.ccUsage.value==50 and oldUsage.value==48,
    "item aliases must bind the new saved table, not the retired owner's debt")

-- Keep the deliberate same-entity type-return debt rule and wrapper identity.
local current=p.data.ccUsage
p.kind=0; fire("MC_POST_PEFFECT_UPDATE",p); fire("MC_POST_UPDATE")
p.kind=41; fire("MC_POST_PEFFECT_UPDATE",wrap(p)); fire("MC_POST_UPDATE")
assert(p.data.ccUsage==current and current.value==50,
    "changing form on the same entity must not erase its existing debt")

-- Pointer reuse with a new initialization seed is a different owner, even in one frame.
current.age=4; current.value=80; current.limited=40
p:EvaluateItems(); assert(p.Damage<3.5)
p.InitSeed=p.InitSeed+1000
fire("MC_POST_PEFFECT_UPDATE",wrap(p))
assert(p.data.ccUsage~=current and p.data.ccUsage.age==0 and p.data.ccUsage.limited==0,
    "a reused pointer must not inherit an old initialization seed's account")
assert(math.abs(p.Damage-3.5)<1e-9,"identity replacement refreshes the old account's cache once")
local evaluations=p.evaluations
for _=1,10 do fire("MC_POST_UPDATE"); fire("MC_POST_PEFFECT_UPDATE",wrap(p)) end
assert(p.evaluations==evaluations,"unchanged owners must not rebuild damage on every observation")

-- A shot before the next general update still observes the new slot owner.
shot(p)
local previous=p.data.ccUsage
players[1]=player(); p=players[1]
local shotData={}
fire("MC_POST_FIRE_TEAR",{SpawnerEntity=p,CollisionDamage=10,GetData=function() return shotData end})
assert(p.data.ccUsage~=previous and p.data.ccUsage.value==4,
    "same-frame replacement must not share the retired owner's paid volley")

-- Remove an unused slot before saving; later co-op joins cannot inherit it.
players={p}; fire("MC_POST_UPDATE")
assert(Risk.state.claudeUsage["1"]==nil,"retired slots must be removed from the saved account map")
fire("MC_PRE_GAME_EXIT",true)
players={player(),player()}; module(); fire("MC_POST_GAME_STARTED",true)
assert(players[1].data.ccUsage.value==4,"continue retains the remaining player's account")
assert(players[2].data.ccUsage.value==0 and players[2].data.ccUsage.age==0,
    "a later joining player cannot inherit a removed co-op account")
assert(saved.claudeUsage["0"].pointer==nil and saved.claudeUsage["0"].seed==nil,
    "transient owner identity must not enter saved usage")
-- Slot reordering retains the same live owners; genuine replacements above
-- still start fresh. Account age and its cached bonus follow the original player.
p,q=players[1],players[2]
p.data.ccUsage.age=2; q.data.ccUsage.age=3
p:EvaluateItems(); q:EvaluateItems()
local damageP,damageQ=p.Damage,q.Damage
players={q,p}; fire("MC_POST_UPDATE")
assert(p.data.ccUsage.age==2 and q.data.ccUsage.age==3,
    "reordered slots must neither exchange nor erase the two players' accounts")
assert(p.Damage==damageP and q.Damage==damageQ,
    "both continuously observed owners keep their own account's cache")
-- Continue without reloading Lua must clear live identities before rebinding.
players[1].data.ccUsage.value=36; players[1].data.ccUsage.age=2
fire("MC_PRE_GAME_EXIT",true)
players={player(),player()}; fire("MC_POST_GAME_STARTED",true)
assert(players[1].data.ccUsage.value==36 and players[1].data.ccUsage.age==2,
    "same-session Continue must preserve saved debt despite recreated entities")
-- Load partially missing/malformed counters without erasing valid fields.
-- Non-finite cases represent in-memory corruption: the detached JSON stub
-- does not claim native JSON can serialize those numbers.
local malformed = {
    {name="missing both", record={}, value=0, limited=0},
    {name="missing value", record={limited=37}, value=0, limited=37},
    {name="missing limited", record={value=60}, value=60, limited=0},
    {name="string value", record={value="40", limited=12}, value=0, limited=12},
    {name="table value", record={value={}, limited=12}, value=0, limited=12},
    {name="boolean limited", record={value=40, limited=true}, value=40, limited=0},
    {name="string limited", record={value=40, limited="12"}, value=40, limited=0},
    {name="negative value", record={value=-1, limited=12}, value=0, limited=12},
    {name="excess value", record={value=101, limited=12}, value=0, limited=12},
    {name="fractional value", record={value=0.5, limited=12}, value=0, limited=12},
    {name="negative limited", record={value=40, limited=-1}, value=40, limited=0},
    {name="excess limited", record={value=40, limited=151}, value=40, limited=0},
    {name="fractional limited", record={value=40, limited=0.5}, value=40, limited=0},
    {name="NaN value", record={value=0/0, limited=12}, value=0, limited=12},
    {name="infinite limited", record={value=40, limited=math.huge}, value=40, limited=0},
    {name="valid zero", record={value=0, limited=0}, value=0, limited=0},
    {name="valid maxima", record={value=100, limited=150}, value=100, limited=150},
    {name="valid last frame", record={value=100, limited=1}, value=100, limited=1},
}
local failures = {}
for _, case in ipairs(malformed) do
    local ok, err = pcall(function()
        local record = copy(case.record)
        record.age, record.appeals, record.clears, record.awards = 4, 0, 1, {["kept"]=true}
        record.floor, record.room = tostring(floor)..":1:0", tostring(room)..":"..tostring(room)
        saved = {risk=0, claudeUsage={
            ["0"]=record, ["1"]={value=36, limited=12, age=2, appeals=2},
        }}
        players={player(),player()}; module(); fire("MC_POST_GAME_STARTED",true)
        local loaded, partner = players[1].data.ccUsage, players[2].data.ccUsage
        assert(loaded.value==case.value and loaded.limited==case.limited,
            "invalid counters use the existing zero default independently")
        assert(loaded.age==4 and loaded.appeals==0 and loaded.clears==1 and loaded.awards.kept,
            "counter repair must retain unrelated valid progression")
        assert(partner.value==36 and partner.limited==12 and partner.age==2 and partner.appeals==2,
            "one repaired account must not reset its valid partner")
        local expectedDamage = (3.5 + 0.8) * (case.limited > 0 and 0.4 or 1)
        assert(math.abs(players[1].Damage-expectedDamage)<1e-9,
            "continued damage uses the preserved valid Limited countdown")
        assert(loaded==Risk.state.claudeUsage["0"] and loaded~=partner,
            "normalization preserves the saved-table alias and player isolation")
        fire("MC_PRE_GAME_EXIT",true)
        players={player(),player()}; module(); fire("MC_POST_GAME_STARTED",true)
        loaded=players[1].data.ccUsage
        assert(loaded.value==case.value and loaded.limited==case.limited and loaded.age==4,
            "repaired fields survive a second detached save/load")
        fire("MC_POST_RENDER")
    end)
    if not ok then failures[#failures+1]=case.name..": "..tostring(err) end
end
assert(#failures==0, table.concat(failures,"\n"))
print("OK: Claude save/continue, counter normalization, live-owner isolation, wrapper/type-return debt and item aliases")
