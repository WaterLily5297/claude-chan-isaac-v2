-- Real Constitution callbacks with independent holders and detached save data.
local root, mode = arg[1], arg[2] or "all"
ModCallbacks = setmetatable({}, {__index=function(_, k) return k end})
DamageFlag = {DAMAGE_IV_BAG=1, DAMAGE_RED_HEARTS=2, DAMAGE_FAKE=4, DAMAGE_NO_PENALTIES=8}
EntityType = {ENTITY_PLAYER=1}
CacheFlag = {CACHE_DAMAGE=1, CACHE_SPEED=2}
PlayerType = {PLAYER_JACOB=19, PLAYER_ESAU=20, PLAYER_LAZARUS_B=29, PLAYER_THEFORGOTTEN_B=35,
    PLAYER_LAZARUS2_B=38, PLAYER_THESOUL_B=40}
function include(name)
    if name == "scripts.constants" then return {Item={CONSTITUTION=746}} end
    assert(name == "scripts.save_sync")
    return dofile(root.."/scripts/save_sync.lua")
end
local callbacks, players = {}, {}
local Risk = {state={}}
local mod = {}
function mod:AddCallback(id, fn) callbacks[id]=fn end
function Game() return {
    GetNumPlayers=function() return #players end,
    GetHUD=function() return {ShowItemText=function() end} end,
} end
Isaac = {GetPlayer=function(i) return players[i+1] end}
function GetPtrHash(p) return p.pointer end
local function player(id)
    local p={pointer=id, InitSeed=id, held=true, soul=0, Damage=4, MoveSpeed=1}
    function p:ToPlayer() return self end
    function p:HasCollectible() return self.held end
    function p:AddSoulHearts(n) self.soul=self.soul+n end
    function p:SetMinDamageCooldown(n) self.cooldown=n end
    function p:IsDead() return self.dead == true end
    function p:IsCoopGhost() return self.ghost == true end
    function p:GetPlayerType() return self.kind or 0 end
    return p
end
local function fire(id, ...) if callbacks[id] then return callbacks[id](mod, ...) end end
local function hit(p, flags) return fire("MC_ENTITY_TAKE_DMG", p, 1, flags or 0) end
local function tick(p) fire("MC_POST_PEFFECT_UPDATE", p) end
local function copy(t)
    if type(t)~="table" then assert(type(t)~="userdata" and type(t)~="function"); return t end
    local out={}
    for k,v in pairs(t) do assert(type(k)=="string" or type(k)=="number"); out[k]=copy(v) end
    return out
end
local function start(saved)
    fire("MC_PRE_GAME_EXIT", false)
    fire("MC_POST_NEW_LEVEL") -- startup level precedes load; must not reset saved blocks
    fire("MC_POST_GAME_STARTED", saved~=nil)
    -- Risk is registered after Constitution in main.lua and loads/resets here.
    Risk.state=saved and copy(saved) or {constitutionApplied=false,constitutionBlockUsed=false}
end
dofile(root.."/scripts/items/constitution.lua"):Init(mod,Risk)

local p,q=player(10),player(20)
players={p,q}
start()
if mode=="all" or mode=="hearts" then
    tick(p);tick(q);tick(p);tick(q)
    assert(p.soul==2 and q.soul==2,"each holder receives its own pickup soul heart once")
    p.held=false;tick(p);p.held=true;tick(p)
    assert(p.soul==2,"dropping and regaining must not farm pickup hearts")
end
if mode=="all" or mode=="blocks" then
    assert(hit(p)==false and hit(q)==false,"each holder has its own first-hit block")
    assert(hit(p)==nil and hit(q)==nil,"each holder spends only one block per floor")
    assert(p.cooldown==60 and q.cooldown==60,"each refused hit grants invincibility")
end
if mode~="all" then print("PASS Constitution "..mode); return end

-- Save/continue retains independent consumption after Risk loads its snapshot.
fire("MC_POST_NEW_LEVEL")
assert(hit(p)==false)
local saved=copy(Risk.state)
players={player(110),player(120)};p,q=players[1],players[2]
start(saved);tick(p);tick(q)
assert(p.soul==0 and q.soul==0,"continued pickup rewards cannot duplicate")
assert(hit(p)==nil and hit(q)==false,"continue preserves each holder's spent block")
fire("MC_POST_NEW_LEVEL")
assert(hit(p)==false and hit(q)==false,"a new floor rearms both holders")
assert(p.soul==0 and q.soul==0,"floor transitions never regrant pickup hearts")

-- Replacements in a live slot do not inherit the departed holder's state.
players[2]=player(220);q=players[2];tick(q)
assert(q.soul==2 and hit(q)==false,"replacement player owns fresh item state")
assert(hit(p)==nil,"replacement must not reset the remaining player's block")

-- Preserve old shared consumption conservatively for players present on load.
players={player(310),player(320)};p,q=players[1],players[2]
start({constitutionApplied=true,constitutionBlockUsed=true})
tick(p);tick(q)
assert(p.soul==0 and q.soul==0 and hit(p)==nil and hit(q)==nil,"legacy saves cannot duplicate rewards or blocks")
fire("MC_POST_NEW_LEVEL")
assert(hit(p)==false and hit(q)==false,"migrated holders separate on the next floor")
players[3]=player(330);tick(players[3])
assert(players[3].soul==2 and hit(players[3])==false,"a later join does not inherit legacy consumption")

-- The Forgotten's subplayer shares inventory and the root holder's state.
players={player(350)};local skeleton=players[1];local soul=player(360)
function skeleton:GetSubPlayer() return soul end
start();tick(soul);tick(skeleton)
assert(soul.soul==2 and skeleton.soul==0,"subplayer must not lose or duplicate the pickup reward")
assert(hit(soul)==false and hit(skeleton)==nil,"shared-inventory forms consume the same shield")
fire("MC_POST_NEW_LEVEL")
assert(hit(skeleton)==false and hit(soul)==nil,"either shared form can consume the next shield")
-- Tainted Forgotten exposes its shared-inventory partner through OtherTwin.
skeleton.GetSubPlayer=nil;skeleton.kind=35;soul.kind=40
function skeleton:GetOtherTwin() return soul end
start();tick(soul);tick(skeleton)
assert(soul.soul==4 and skeleton.soul==0,"tainted shared inventory receives one pickup reward")
assert(hit(soul)==false and hit(skeleton)==nil,"tainted shared inventory spends one shield")

-- Jacob and Esau are distinct player IDs with their own per-slot item state.
local jacob, esau = player(365), player(366)
jacob.kind, esau.kind = PlayerType.PLAYER_JACOB, PlayerType.PLAYER_ESAU
function jacob:GetOtherTwin() return esau end
function esau:GetOtherTwin() return jacob end
players={jacob,esau};start();tick(jacob);tick(esau)
assert(jacob.soul==2 and esau.soul==2,"both twin player IDs receive independent pickup rewards")
assert(hit(jacob)==false and hit(esau)==false,"each twin has an independent first-hit block")
assert(hit(jacob)==nil and hit(esau)==nil,"one twin cannot spend the other's shield")
fire("MC_POST_NEW_LEVEL")
assert(hit(esau)==false and hit(jacob)==false,"both twin slots rearm on a new floor")
fire("MC_POST_NEW_LEVEL");assert(hit(jacob)==false)
players={esau,jacob};tick(esau);tick(jacob)
assert(jacob.soul==2 and esau.soul==2,"separate twin moves cannot regrant pickup rewards")
assert(hit(jacob)==nil and hit(esau)==false,"separate twin moves preserve asymmetric shield debt")

-- Flip swaps active entities in a slot; returning is not a new co-op join.
local living,dead=player(370),player(380)
living.kind,dead.kind=29,38
players={living};start();tick(living);assert(hit(living)==false)
players[1]=dead;tick(dead);assert(hit(dead)==false)
players[1]=living;tick(living)
assert(living.soul==2 and hit(living)==nil,"Flip back must not reset an existing body's effects")
players[1]=dead;tick(dead)
assert(dead.soul==2 and hit(dead)==nil,"repeated Flip must not farm hearts or shields")
saved=copy(Risk.state);start(saved);tick(dead)
assert(dead.soul==2 and hit(dead)==nil,"continued active body keeps consumed effects")
-- Birthright may expose the other body without listing it as a root slot.
function dead:GetOtherTwin() return living end
fire("MC_POST_NEW_LEVEL")
assert(hit(living)==false and hit(dead)==false,"Birthright bodies remain independent")
start({constitutionApplied=true,constitutionBlockUsed=true});tick(dead)
players[1]=living;tick(living)
assert(living.soul==2 and hit(living)==nil,"legacy migration must include the initially hidden body")

-- Two independently observed Lazarus body groups move as whole groups even
-- when the inactive bodies are hidden. Recreated groups adopt saved slot keys.
local a,b,c,d=player(510),player(520),player(530),player(540)
a.kind,b.kind,c.kind,d.kind=29,38,29,38
players={a,c};start();tick(a);tick(c);assert(hit(a)==false)
players={b,d};tick(b);tick(d);assert(hit(d)==false)
players={a,c};tick(a);tick(c)
players={c,a};tick(c);tick(a)
assert(a.soul==2 and c.soul==2,"Lazarus group rotation cannot regrant active rewards")
players={d,b};tick(d);tick(b)
assert(b.soul==2 and d.soul==2,"hidden body records move with their known group")
assert(hit(d)==nil and hit(b)==false,"moved hidden bodies keep independent shield bits")
local moved=Risk.state.constitution.players
assert(moved["0:29"].applied and not moved["0:29"].used and moved["1:29"].used,
    "inactive group state is retained under its new slot")
include("scripts.save_sync").Run(Risk)
saved=copy(Risk.state)
a,b,c,d=player(610),player(620),player(630),player(640)
a.kind,b.kind,c.kind,d.kind=29,38,29,38
players={d,b};start(saved);tick(d);tick(b)
players={c,a};tick(c);tick(a)
assert(a.soul==0 and b.soul==0 and c.soul==0 and d.soul==0,"Continue keeps both hidden pickup bits")
assert(hit(c)==false and hit(a)==nil,"first hidden Flip after Continue keeps the appropriate debt")

-- A visible, known counterpart can identify a newly exposed body during a
-- simultaneous move. An unrelated unknown body must not steal a moved group.
a,b,c=player(710),player(720),player(730);a.kind,b.kind,c.kind=29,38,0
players={a,c};start({constitutionApplied=true,constitutionBlockUsed=true});tick(a);tick(c)
function b:GetOtherTwin() return a end
players={c,b};tick(b);tick(a)
assert(a.soul==0 and b.soul==0 and hit(a)==nil and hit(b)==nil,
    "known counterpart locates both legacy records during a first exposure and move")
local replacement=player(735);replacement.kind=29
function replacement:GetOtherTwin() return b end
players={c,replacement};tick(replacement);tick(b)
assert(replacement.soul==2 and hit(replacement)==false,"replaced body starts fresh within a known group")
assert(b.soul==0 and hit(b)==nil,"body replacement preserves the surviving counterpart")
local newcomer=player(740);newcomer.kind=38
players={a,c};start({constitutionApplied=true,constitutionBlockUsed=true});tick(a);tick(c)
players={newcomer,a};tick(newcomer);tick(a)
assert(newcomer.soul==2 and hit(newcomer)==false,"unknown join cannot inherit a moved group's hidden bits")
assert(a.soul==0 and hit(a)==nil,"unknown join cannot overwrite the known moved owner")

-- Shared Forgotten state follows the root while callbacks may name its Soul.
local rootBody,sharedSoul,partner=player(810),player(820),player(830)
function rootBody:GetSubPlayer() return sharedSoul end
players={rootBody,partner};start();tick(sharedSoul);tick(partner);assert(hit(sharedSoul)==false)
players={partner,rootBody};tick(rootBody);tick(sharedSoul);tick(partner)
assert(sharedSoul.soul==2 and rootBody.soul==0 and partner.soul==2,"shared body move keeps one pickup reward")
assert(hit(rootBody)==nil and hit(sharedSoul)==nil and hit(partner)==false,"shared body move keeps separate co-op debt")
rootBody.GetSubPlayer=nil;rootBody.kind=35;sharedSoul.kind=40
function rootBody:GetOtherTwin() return sharedSoul end
start();tick(sharedSoul);tick(partner);assert(hit(sharedSoul)==false)
players={rootBody,partner};tick(rootBody);tick(sharedSoul);tick(partner)
assert(sharedSoul.soul==4 and rootBody.soul==0 and partner.soul==4,"tainted shared-body move keeps one pickup reward")
assert(hit(rootBody)==nil and hit(sharedSoul)==nil and hit(partner)==false,"tainted shared-body move retains shared debt")

-- Dead and ghost players cannot consume rewards while inactive.
players={player(410)};p=players[1];start();p.ghost=true;tick(p)
assert(p.soul==0 and hit(p)==nil,"ghost cannot consume Constitution")
p.ghost=false;p.dead=true;tick(p)
assert(p.soul==0 and hit(p)==nil,"dead player cannot consume Constitution")
p.dead=false
for _,flags in pairs(DamageFlag) do assert(hit(p,flags)==nil,"excluded damage keeps the block") end
tick(p);assert(p.soul==2 and hit(p)==false,"revival retains unused effects")
fire("MC_EVALUATE_CACHE",p,CacheFlag.CACHE_DAMAGE)
fire("MC_EVALUATE_CACHE",p,CacheFlag.CACHE_SPEED)
assert(p.Damage==3.6 and p.MoveSpeed==0.9,"stat costs stay unchanged")
fire("MC_POST_NEW_LEVEL") -- unused block makes an out-of-run callback observable
fire("MC_PRE_GAME_EXIT",false);assert(hit(p)==nil,"callbacks after exit cannot consume state")
copy(Risk.state) -- no engine objects or table keys in the saved state
print("PASS Constitution: per-player rewards, blocks, continue, migration and lifecycle")
