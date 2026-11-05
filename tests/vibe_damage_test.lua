-- Vibe Coding must observe eligible damage after the backlog's hit blockers.
-- Uses real item/service callbacks; the engine dispatch and damage flags are stubs.
local root = arg[1]
local Env = dofile(root.."/tests/lib/backlog_env.lua")
local env = Env.New(root)
CallbackPriority = {EARLY=-100,DEFAULT=0,LATE=1000}
TearFlags = {TEAR_HOMING=1,TEAR_PIERCING=2,TEAR_SPECTRAL=4,TEAR_POISON=8,TEAR_SLOW=16}
function RNG() return {SetSeed=function() end} end
local originalGame = Game
function Game()
    local game = originalGame()
    game.GetSeeds = function() return {GetStartSeed=function() return 123 end} end
    return game
end
-- Model priority, stable registration order and the documented first-return
-- damage dispatch rule, rather than manually calling a chosen observer first.
function env.mod:AddPriorityCallback(id, priority, fn, filter)
    env.callbacks[#env.callbacks+1] = {id=id,priority=priority,fn=fn,filter=filter,order=#env.callbacks+1}
end
function env.mod:AddCallback(id, fn, filter) self:AddPriorityCallback(id,0,fn,filter) end
function env.fire(id, filter, ...)
    local selected = {}
    for _,cb in ipairs(env.callbacks) do
        if cb.id==id and (cb.filter==nil or filter==nil or cb.filter==filter) then selected[#selected+1]=cb end
    end
    table.sort(selected,function(a,b)
        if a.priority==b.priority then return a.order<b.order end
        return a.priority<b.priority
    end)
    local result
    for _,cb in ipairs(selected) do
        local value=cb.fn(env.mod,...)
        if value~=nil then result=value; if id=="MC_ENTITY_TAKE_DMG" then return value end end
    end
    return result
end
local p,q=env.player(300),env.player(350)
for _,player in ipairs({p,q}) do
    player.coins=40
    function player:GetNumCoins() return self.coins end
    function player:AddCoins(n) self.coins=self.coins+n end
end
-- Match main.lua: Vibe is registered before the backlog and its blockers.
include("scripts.items.vibe_coding"):Init(env.mod,env.Risk)
env.load()
env.give(p,"VIBE_CODING"); env.give(q,"VIBE_CODING")
env.newRoom()
local function nextFloor(expectedP,expectedQ,label)
    env.newFloor()
    assert(p.coins==expectedP and q.coins==expectedQ,
        label..": coins "..p.coins.."/"..q.coins..", expected "..expectedP.."/"..expectedQ)
    assert(next(env.Risk.state.vibeMistakes)==nil,"settling clears the floor's records")
end
local enemy=env.npc(310,{y=0})
env.hitPlayer(p,enemy,DamageFlag.DAMAGE_FAKE)
env.hitPlayer(q,enemy,DamageFlag.DAMAGE_NO_PENALTIES)
env.hitPlayer(p,enemy,DamageFlag.DAMAGE_FAKE|DamageFlag.DAMAGE_NO_PENALTIES)
nextFloor(40,40,"fake and no-penalty damage must not produce bills")

enemy=env.npc(310,{y=0})
assert(env.use(env.Item.SOLD_OUT,p).Discharge)
local bullet=env.bullet(305,0,enemy)
assert(env.hitPlayer(p,bullet)==false and not bullet:Exists(),"real Sold Out guard cancels the bullet")
assert(env.use(env.Item.RED_STAMP,q).Discharge)
assert(env.hitPlayer(q,enemy)==false,"real Red Stamp blocks contact")
nextFloor(40,40,"cancelled damage must not produce bills")

enemy=env.npc(310,{y=0})
assert(env.hitPlayer(p,enemy)==nil)
env.hitPlayer(p,enemy) -- Multiple hits must still charge only once on the next floor.
nextFloor(30,40,"ordinary damage bills only its owner")
nextFloor(30,40,"a following clean floor waives the bill")
-- A hit before acquiring the item still counts: do not add a holder-only filter.
q.items[env.Item.VIBE_CODING]=nil
env.hitPlayer(q,env.npc(310,{y=0}))
env.give(q,"VIBE_CODING")
nextFloor(30,30,"late acquisition keeps actual prior damage")
env.fire("MC_PRE_GAME_EXIT",nil,false)
env.hitPlayer(p,env.npc(310,{y=0}))
assert(next(env.Risk.state.vibeMistakes)==nil,"exit disables the observer")
print("OK: Vibe ignores fake/no-penalty and shielded hits; real damage, co-op and floor billing remain")
