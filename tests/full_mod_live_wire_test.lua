-- Supplied main.lua callbacks: Live Wire behavior and bounded room queries.
-- The optional old Grok module must pass behavior but fail the scan budget.
local root=assert(arg[1])
local Full=dofile(root.."/tests/lib/full_mod_env.lua")
local module=arg[2]~="-" and arg[2] or nil
local mode=arg[3] or "all"
local function near(a,b,message) assert(math.abs(a-b)<1e-8,message) end
local function setup(kinds)
    local env=Full.New(root,kinds,{grokModule=module})
    env.step(10)
    for i,p in ipairs(env.players) do
        p.Position=Vector((i-1)*300,0)
        p.items[env.Item.LIVE_WIRE]=1
        p:EvaluateItems()
    end
    return env
end
local function speed(env,p,active,base)
    assert((env.Backlog.Data(p).wire==true)==active,"wire state must belong to this owner")
    near(p.MoveSpeed,(base or 1)+(active and 0.15 or 0),"speed bonus must apply once")
end

if mode~="budget" then
    -- All forms retain their own cache inputs while gaining/losing the same bonus.
    for kind=100,121 do
        local env=setup({kind,0}); local p,q=env.players[1],env.players[2]
        local base=p.MoveSpeed
        local owner=env.npc(1000)
        local bullet=env.bullet(100,0,owner)
        env.step(4); near(p.MoveSpeed,base,"no early refresh")
        env.step(); speed(env,p,true,base); speed(env,q,false)
        env.resetMetrics(); env.step(10)
        speed(env,p,true,base); assert((env.metrics.cacheRebuilds or 0)==0,"stable state must not rebuild caches")
        bullet.Position=Vector(100.01,0); env.step(5); speed(env,p,false,base)
        bullet.Position=q.Position; env.step(5); speed(env,q,true); speed(env,p,false,base)
        p.Position=q.Position; env.step(5); speed(env,p,true,base)
        bullet:Remove(); env.step(5); speed(env,p,false,base); speed(env,q,false)
        assert(bullet.Velocity.X==1 and bullet.ProjectileFlags==0,"observation must not modify bullets")
    end

    -- Preserve the existing ordinary-bullet predicate, including its current
    -- treatment of dead/invulnerable NPC spawners; do not silently change rules.
    local exclusions={
        function(b) b.Variant=1 end, function(b) b.SubType=1 end,
        function(b) b.ProjectileFlags=1 end, function(b) b.ChangeFlags=1 end,
        function(b) b.flags=EntityFlag.FLAG_FRIENDLY end,
        function(b) b.SpawnerEntity.flags=EntityFlag.FLAG_FRIENDLY end,
        function(b) b.SpawnerEntity=nil end,
        function(b,env) b.SpawnerEntity=env.players[1] end,
        function(b) b.alive=false end,
        function(b) function b:IsDead() return true end end,
    }
    for _,change in ipairs(exclusions) do
        local env=setup({0}); local p=env.players[1]
        local bullet=env.bullet(0,0,env.npc(1000)); change(bullet,env)
        env.step(5); speed(env,p,false)
    end
    for _,opts in ipairs({{}, {invulnerable=true}}) do
        local env=setup({0}); local owner=env.npc(1000,opts); owner.alive=false
        env.bullet(0,0,owner); env.step(5); speed(env,env.players[1],true)
    end

    do
        local env=setup({0,0}); local p,q=env.players[1],env.players[2]
        env.bullet(0,0,env.npc(1000)); env.step(5); speed(env,p,true)
        p.items[env.Item.LIVE_WIRE]=nil; p:EvaluateItems()
        near(p.MoveSpeed,1,"item removal suppresses the bonus immediately on cache evaluation")
        env.newRoom(); env.step(5); speed(env,q,false)
        p.items[env.Item.LIVE_WIRE]=3; p:EvaluateItems(); env.step(5); speed(env,p,false)
        env.bullet(0,0,env.npc(1000)); env.step(5); speed(env,p,true)
        local snapshot=env.saveSnapshot()
        local resumed=Full.New(root,{0,0},{snapshot=snapshot,
            inventory={{[env.Item.LIVE_WIRE]=3},{[env.Item.LIVE_WIRE]=1}},grokModule=module})
        resumed.step(5); speed(resumed,resumed.players[1],false)
        resumed.bullet(resumed.players[2].Position.X,0,resumed.npc(1000))
        resumed.step(5); speed(resumed,resumed.players[2],true)
        resumed.fire("MC_POST_GAME_STARTED",nil,false)
        speed(resumed,resumed.players[2],false)
    end

    -- A cache callback can create/remove projectiles synchronously. A snapshot
    -- taken before that callback must not hide changes from the next owner.
    for _,action in ipairs({"spawn","remove","move","friendly"}) do
        local env=setup({0,0}); local p,q=env.players[1],env.players[2]
        local owner=env.npc(1000); env.bullet(0,0,owner)
        local later=action~="spawn" and env.bullet(q.Position.X,0,owner) or nil
        local changed=false
        env.mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE,function(_,player,flag)
            if player~=p or flag~=CacheFlag.CACHE_SPEED or changed then return end
            changed=true
            if action=="spawn" then env.bullet(q.Position.X,0,owner)
            elseif action=="remove" then later:Remove()
            elseif action=="move" then later.Position=Vector(1000,1000)
            else later.flags=EntityFlag.FLAG_FRIENDLY end
        end)
        env.step(5); assert(changed,"cache-side mutation must actually execute")
        speed(env,p,true); speed(env,q,action=="spawn")
    end
    print("PASS Live Wire: 22-form timing/co-op, predicate, removal/Continue and cache-callback controls (offline)")
end

if mode~="behavior" then
    for _,players in ipairs({1,4}) do for _,bullets in ipairs({0,12,96}) do
        local kinds={}; for i=1,players do kinds[i]=0 end
        local env=setup(kinds); local owner=env.npc(1000)
        for i=1,bullets do env.bullet((i%players)*300,0,owner) end
        env.step(5); env.resetMetrics(); env.step(30)
        assert(env.metrics.roomScans==6,"stable Live Wire holders share one room query per five-frame refresh")
        assert((env.metrics.cacheRebuilds or 0)==0,"steady bullets must not force cache rebuilds")
        for _,p in ipairs(env.players) do
            speed(env,p,bullets>0)
            p.items[env.Item.LIVE_WIRE]=nil; p:EvaluateItems()
        end
        env.resetMetrics(); env.step(30)
        assert((env.metrics.scans or 0)==0,"no holders must make no room queries")
    end end
    print("PASS Live Wire: six stable population budgets and holder-removal controls (offline)")
end
