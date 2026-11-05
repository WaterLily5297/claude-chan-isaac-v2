-- Real Risk, Constitution and backlog blockers in main.lua registration order.
-- Models documented pre-damage priority/short-circuit dispatch, not health loss.
local root = arg[1]
local env = dofile(root.."/tests/lib/backlog_env.lua").New(root)
local mode = arg[2] or "all"
CallbackPriority = {EARLY=-100,DEFAULT=0,LATE=1000}
DamageFlag.DAMAGE_IV_BAG, DamageFlag.DAMAGE_RED_HEARTS = 4096,32
package.preload.json = function() return {encode=function() return "{}" end,decode=function() return {} end} end
local names = {"Claude-chan","DeepSeek-chan","GPT-chan","Gemini-chan","Grok-chan",
    "Qwen-chan","Llama-chan","Mistral-chan","Doubao-chan","Kimi-chan","GLM-chan"}
function Isaac.GetPlayerTypeByName(name,tainted)
    for i,n in ipairs(names) do if name==n then return 40+i+(tainted and 100 or 0) end end
    return -1
end
local realInclude = include
function include(name)
    if name=="scripts.hud_text" then return {T=function(_,key) return key end,Draw=function() end} end
    return realInclude(name)
end
function RNG() return {SetSeed=function() end,RandomInt=function() return 0 end,RandomFloat=function() return 1 end} end
local baseGame = Game
function Game()
    local game=baseGame()
    game.GetSeeds=function() return {GetStartSeed=function() return 123 end} end
    return game
end
function env.mod:AddPriorityCallback(id,priority,fn,filter)
    env.callbacks[#env.callbacks+1]={id=id,priority=priority,fn=fn,filter=filter,order=#env.callbacks+1}
end
function env.mod:AddCallback(id,fn,filter) self:AddPriorityCallback(id,0,fn,filter) end
function env.fire(id,filter,...)
    local selected={}
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
    player.kindId=41
    function player:GetPlayerType() return self.kindId end
    function player:HasTrinket() return false end
end
env.Risk=include("scripts.risk")
include("scripts.items.constitution"):Init(env.mod,env.Risk)
env.Risk:Init(env.mod)
env.load() -- Register the real backlog after Risk, then start the run.
local Risk=env.Risk
local function freshRoom()
    env.newRoom()
    Risk.state.risk=50
    return env.npc(310,{y=0})
end
local function risk(expected,label)
    assert(Risk.state.risk==expected,label..": risk "..Risk.state.risk..", expected "..expected)
end
if mode=="all" or mode=="flags" then
    local enemy=freshRoom()
    for _,flags in ipairs({DamageFlag.DAMAGE_FAKE,DamageFlag.DAMAGE_NO_PENALTIES,
            DamageFlag.DAMAGE_FAKE|DamageFlag.DAMAGE_NO_PENALTIES}) do
        env.hitPlayer(p,enemy,flags)
        risk(50,"fake/no-penalty damage must not raise risk")
    end
    env.clearRoom(); risk(49,"ignored damage must not spoil the clean-room reduction")
end
if mode=="all" or mode=="shields" then
    local enemy=freshRoom()
    assert(env.use(env.Item.SOLD_OUT,p).Discharge)
    local bullet=env.bullet(305,0,enemy)
    assert(env.hitPlayer(p,bullet)==false and not bullet:Exists(),"Sold Out must cancel its guarded bullet")
    risk(50,"cancelled bullet must not raise risk")
    assert(env.use(env.Item.RED_STAMP,q).Discharge)
    assert(env.hitPlayer(q,enemy)==false,"Red Stamp must cancel contact")
    risk(50,"cancelled contact must not raise risk")
    env.clearRoom(); risk(49,"shielded room remains clean")
    enemy=freshRoom()
    env.give(p,"CONSTITUTION")
    assert(env.hitPlayer(p,enemy)==false,"Constitution still refuses the first hit")
    risk(50,"Constitution block must not raise risk")
    assert(env.hitPlayer(p,enemy)==nil)
    risk(51,"ordinary damage after the block still raises risk")
    env.clearRoom(); risk(51,"real damage spoils the clean-room reduction")
    p.items[env.Item.CONSTITUTION]=nil
end
if mode=="all" or mode=="coverage" then
    local enemy=freshRoom()
    for _,kind in ipairs({42,142,43,143,51,151}) do
        q.kindId=kind
        env.hitPlayer(q,enemy)
        risk(50,"DeepSeek and normal/tainted roster damage must stay outside Risk")
    end
    env.clearRoom(); risk(49,"excluded co-op hits must not spoil Claude's clean room")
    for _,kind in ipairs({41,141}) do
        enemy=freshRoom(); p.kindId=kind
        env.hitPlayer(p,enemy); risk(51,"Claude damage retains risk")
        env.clearRoom(); risk(51,"eligible damage keeps the room hit latch")
    end
    enemy=freshRoom(); p.kindId=0
    env.hitPlayer(p,enemy); risk(50,"vanilla damage stays outside Risk")
    p.kindId=41
end
if mode=="all" or mode=="lifecycle" then
    local enemy=freshRoom()
    env.hitPlayer(p,enemy); risk(51,"establish the old run's hit latch")
    Risk.state.risk=50
    env.fire("MC_PRE_GAME_EXIT",nil,false)
    env.hitPlayer(p,enemy); risk(50,"damage outside an active run must be ignored")
    env.fire("MC_POST_GAME_STARTED",nil,false)
    Risk.state.risk=50
    env.clearRoom(); risk(49,"a new run must not inherit an old hit latch")
    enemy=freshRoom(); env.hitPlayer(p,enemy); risk(51,"observer resumes on a new run")
end
print("OK: Risk damage eligibility, shield ordering, coverage and lifecycle ("..mode..")")
