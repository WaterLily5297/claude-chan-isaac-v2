-- Actual entry-point Constitution ownership under supplied events/identities.
-- Soul-heart calls are counted; native health, bodies and Continue are not emulated.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local function track(e)
    for _,p in ipairs(e.players) do
        p.soulGiven=0
        function p:AddSoulHearts(n) self.soulGiven=self.soulGiven+n end
    end
end
local function tick(e,p) e.fire("MC_POST_PEFFECT_UPDATE",nil,p) end
local function hit(e,p)
    return e.fire("MC_ENTITY_TAKE_DMG",EntityType.ENTITY_PLAYER,p,1,0,EntityRef(e.npc(1000)),0)
end
local function snapshot(e,exit)
    if exit then return e.saveSnapshot() end
    e.Risk:Save(e.mod); return require("json").decode(e.mod.saved)
end
local function check(e,map,expected,label)
    for i,p in ipairs(e.players) do
        local s=assert(map[tostring(i-1)],label.." missing owner")
        local want=expected[p.hash]
        assert(s.applied==want.applied and s.used==want.used,label.." state follows owner "..i)
        assert(p.soulGiven==want.soul,label.." duplicated pickup reward "..i)
    end
end

for _,mode in ipairs({"update","direct","exit"}) do
    if not arg[2] or arg[2]==mode then
        for _,kinds in ipairs({{0,0,0,0},{100,102,105,121}}) do
            local e=Full.New(root,kinds); track(e)
            local p,q,r,s=table.unpack(e.players)
            p.items[e.Item.CONSTITUTION]=1; q.items[e.Item.CONSTITUTION]=1
            r.items[e.Item.CONSTITUTION]=1
            tick(e,p); tick(e,q)
            assert(hit(e,p)==false and hit(e,r)==false)
            -- A shield can be consumed before the first effect update. Removing
            -- the item leaves that debt and an unclaimed pickup reward distinct.
            r.items[e.Item.CONSTITUTION]=nil
            local expected={}
            for i,actor in ipairs(e.players) do
                local state=e.Risk.state.constitution.players[tostring(i-1)]
                expected[actor.hash]={applied=state.applied,used=state.used,soul=actor.soulGiven}
            end
            local actors=e.players
            e.players={s,p,q,r}
            if mode=="update" then
                for _=1,4 do
                    e.step()
                    check(e,e.Risk.state.constitution.players,expected,"observed rotation")
                    local list=e.players; e.players={list[4],list[1],list[2],list[3]}
                end
            end
            local saved=snapshot(e,mode=="exit")
            check(e,saved.constitution.players,expected,"final "..mode)
            if mode~="exit" then
                actors=e.players; e.players={actors[3],actors[4],actors[1],actors[2]}
                saved=snapshot(e)
                check(e,saved.constitution.players,expected,"second final move")
                local again=snapshot(e)
                check(e,again.constitution.players,expected,"repeated save")
            end
            local inventories,types={},{}
            for i,actor in ipairs(e.players) do inventories[i]=actor.items; types[i]=actor.kindId end
            local resumed=Full.New(root,types,{snapshot=saved,inventory=inventories,identityBase=20000})
            track(resumed); resumed.step(2)
            for i,actor in ipairs(resumed.players) do
                local before=saved.constitution.players[tostring(i-1)]
                local after=resumed.Risk.state.constitution.players[tostring(i-1)]
                assert(actor.soulGiven==0,"Continue cannot regrant an already claimed pickup")
                assert(before.applied==after.applied and before.used==after.used,"Continue keeps separate bits")
                actor.items[resumed.Item.CONSTITUTION]=1
                tick(resumed,actor)
                assert(actor.soulGiven==(before.applied and 0 or 2),"pending pickup belongs to its continued owner")
                assert((hit(resumed,actor)==false)==not before.used,"Continue keeps the correct shield debt")
                assert(hit(resumed,actor)~=false,"only one shield per owner")
            end
            print("PASS Constitution "..mode..": four-owner bits, rewards and actual-main Continue")
        end
    end
end

if not arg[2] or arg[2]=="lifecycle" then
    local e=Full.New(root,{0,0}); track(e)
    local p,q=table.unpack(e.players)
    for _,actor in ipairs(e.players) do actor.items[e.Item.CONSTITUTION]=1; tick(e,actor); assert(hit(e,actor)==false) end
    e.players={q,p}
    -- Damage is also an observation; no update/save may grant a free shield.
    assert(hit(e,p)~=false and hit(e,q)~=false,"damage after a move cannot rearm a shield")
    p.ControllerIndex=7
    e.players[2]=setmetatable({}, {__index=p,__newindex=p})
    tick(e,e.players[2]); assert(p.soulGiven==2,"wrapper/controller changes retain the owner")
    p.items[e.Item.CONSTITUTION]=nil; tick(e,p)
    p.items[e.Item.CONSTITUTION]=1; tick(e,p)
    assert(p.soulGiven==2 and hit(e,p)~=false,"removal/reacquisition keeps consumed effects")
    e.newFloor()
    assert(hit(e,p)==false and hit(e,q)==false,"new floor rearms each holder exactly once")
    assert(p.soulGiven==2 and q.soulGiven==2)
    p.InitSeed=p.InitSeed+900
    tick(e,p)
    assert(p.soulGiven==4 and hit(e,p)==false,"a true replacement starts fresh")
    assert(q.soulGiven==2 and hit(e,q)~=false,"replacement preserves the remaining owner")
    e.players={q}; e.step()
    local saved=snapshot(e)
    assert(saved.constitution.players["1"]==nil,"departed state is absent from the saved map")
    e.players={q,p}; tick(e,p)
    assert(p.soulGiven==6 and hit(e,p)==false,"a later join cannot recover a departed record")
    assert(q.soulGiven==2 and hit(e,q)~=false,"later join cannot reset the survivor")
    local fresh=Full.New(root,{0}); track(fresh)
    fresh.players[1].items[fresh.Item.CONSTITUTION]=1
    local unclaimed=snapshot(fresh)
    assert(fresh.players[1].soulGiven==0 and not unclaimed.constitution.players["0"].applied,
        "save observation cannot grant or consume a pending pickup reward")
    local continued=Full.New(root,{0},{snapshot=unclaimed,
        inventory={fresh.players[1].items},identityBase=30000})
    track(continued); continued.step(2)
    assert(continued.players[1].soulGiven==2,"unclaimed saved pickup is granted once after Continue")
    print("PASS Constitution lifecycle: damage observation, wrapper, inventory, floor, replacement and departure")
end
