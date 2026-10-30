-- Full entry-point fixture for supplied offline callbacks, not an Isaac emulator.
-- Reuses explicit entity stand-ins; missing API methods fail instead of auto-nooping.
local Full = {}
Full.families={"Claude", "DeepSeek", "GPT", "Gemini", "Grok", "Qwen", "Llama", "Mistral", "Doubao", "Kimi", "GLM"}

function Full.New(root, kinds, options)
    options=options or {}
    local env=dofile(root.."/tests/lib/backlog_env.lua").New(root)
    env.metrics={}; env.currentSource="fixture"; env.buttons={}; env.paused=false
    local function count(key,amount)
        local m=env.metrics; m[key]=(m[key] or 0)+(amount or 1)
    end
    local rawInclude=include
    function include(name)
        local module
        if name=="scripts.items.backlog.gemini" and options.geminiModule then module=dofile(options.geminiModule)
        else module=rawInclude(name) end
        if name=="scripts.risk" then env.Risk=module end
        if name=="scripts.meal_break" then env.Meal=module end
        if name=="scripts.items.backlog.common" then env.Backlog=module end
        return module
    end
    local formIds={}
    for i,name in ipairs(Full.families) do formIds[name.."-chan"]={100+(i-1)*2,101+(i-1)*2} end
    function Isaac.GetPlayerTypeByName(name,tainted)
        local ids=formIds[name]; return ids and ids[tainted and 2 or 1] or -1
    end
    local function registry(first)
        local ids={}
        return function(name)
            if not ids[name] then ids[name]=first; first=first+1 end
            return ids[name]
        end
    end
    Isaac.GetTrinketIdByName=registry(190)
    Isaac.GetPillEffectByName=registry(50)
    CallbackPriority={DEFAULT=0,LATE=1000}
    EntityPartition={ENEMY=1,BULLET=2}
    EntityType.ENTITY_LASER,EntityType.ENTITY_KNIFE,EntityType.ENTITY_BOMB=7,8,4
    EntityFlag.FLAG_CHARM=256
    DamageFlag.DAMAGE_EXPLOSION=4; DamageFlag.DAMAGE_IV_BAG=4096; DamageFlag.DAMAGE_RED_HEARTS=32
    CacheFlag.CACHE_TEARCOLOR=32; CacheFlag.CACHE_FLYING=64; CacheFlag.CACHE_TEARFLAG=128
    ActiveSlot.SLOT_POCKET=2
    Direction.NO_DIRECTION=-1
    CollectibleType.COLLECTIBLE_BIRTHRIGHT=619
    PlayerForm={NUM_PLAYER_FORMS=15}
    TearFlags={TEAR_LUDOVICO=1<<30,TEAR_HOMING=1<<2,TEAR_PIERCING=1<<1,TEAR_SPECTRAL=1<<0}
    TearFlags.TEAR_POISON=1<<4; TearFlags.TEAR_SLOW=1<<5
    TearFlags.TEAR_KNOCKBACK=1<<6
    TearFlags.TEAR_QUADSPLIT=1<<7; TearFlags.TEAR_FREEZE=1<<8; TearFlags.TEAR_CHARM=1<<9
    TearFlags.TEAR_CONFUSION=1<<10; TearFlags.TEAR_WIGGLE=1<<11; TearFlags.TEAR_BOOMERANG=1<<12
    EffectVariant.ROCKET=31
    RoomType={ROOM_DEFAULT=1,ROOM_BOSS=5}
    SoundEffect={SOUND_POWERUP_SPEWER=132}
    ButtonAction={ACTION_MAP=10,ACTION_DROP=11,ACTION_SHOOTLEFT=4,ACTION_SHOOTRIGHT=5,ACTION_SHOOTUP=6,ACTION_SHOOTDOWN=7}
    InputHook={IS_ACTION_PRESSED=0,IS_ACTION_TRIGGERED=1,GET_ACTION_VALUE=2}
    Input={IsActionPressed=function(action,controller) return action==11 and env.buttons[controller] or false end}
    Options={Language="en"}
    EID=nil; ReactionPack=nil
    function SFXManager() return {Play=function() count("sounds") end} end
    function RNG()
        local rng={value=1}
        function rng:SetSeed(value) self.value=value end
        function rng:RandomInt(n) self.value=self.value*48271%2147483647; return self.value%n end
        function rng:RandomFloat() return self:RandomInt(100000)/100000 end
        return rng
    end
    local vectorMethods=getmetatable(Vector.Zero)
    function vectorMethods:Distance(other) return (self-other):Length() end
    function vectorMethods:DistanceSquared(other) return (self-other):LengthSquared() end
    function vectorMethods:GetAngleDegrees() return math.deg(math.atan(self.Y,self.X)) end
    function vectorMethods:Rotated(degrees)
        local angle=math.rad(degrees); local c,s=math.cos(angle),math.sin(angle)
        return Vector(self.X*c-self.Y*s,self.X*s+self.Y*c)
    end
    function Color(r,g,b,a,ro,go,bo) return {R=r,G=g,B=b,A=a,RO=ro or 0,GO=go or 0,BO=bo or 0} end

    -- Supply resolved ordinary-tear fields. Raw Spawn creates a typed tear but
    -- does not synthesize POST_FIRE_TEAR; FireTear below explicitly does.
    local baseTear,baseSpawn=env.tear,Isaac.Spawn
    function env.tear(owner)
        local t=baseTear(owner)
        t.InitSeed,t.SubType=t.hash+4000,0
        t.CollisionDamage=owner and owner.Damage or 3.5
        t.TearFlags=owner and owner.TearFlags or 0
        local c=owner and owner.TearColor or Color(1,1,1,1)
        t.Color=Color(c.R,c.G,c.B,c.A,c.RO,c.GO,c.BO)
        t.Velocity=Vector(10,0)
        t.Height,t.FallingSpeed,t.FallingAcceleration,t.HomingFriction,t.KnockbackMultiplier=-10,0,0.5,0,1
        function t:HasTearFlags(flags) return self.TearFlags & flags~=0 end
        function t:AddTearFlags(flags) self.TearFlags=self.TearFlags|flags end
        function t:ResetSpriteScale() self.SpriteScale=Vector(self.Scale,self.Scale) end
        return t
    end
    function Isaac.Spawn(kind,variant,subtype,position,velocity,spawner)
        if kind~=EntityType.ENTITY_TEAR then return baseSpawn(kind,variant,subtype,position,velocity,spawner) end
        local t=env.tear(spawner and spawner:ToPlayer())
        t.Variant,t.SubType,t.Position,t.Velocity,t.SpawnerEntity=variant,subtype,position,velocity,spawner
        env.spawned[#env.spawned+1]=t
        return t
    end

    -- Cache engine stand-ins so their construction is outside measured loops.
    local game=Game(); local room,level,hud=game:GetRoom(),game:GetLevel(),game:GetHUD()
    local desc={SafeGridIndex=10,SpawnSeed=13}
    local topLeft,bottomRight,center=Vector(0,0),Vector(600,400),Vector(300,200)
    function Game() return game end
    function game:GetRoom() return room end
    function game:GetLevel() return level end
    function game:GetHUD() return hud end
    function game:IsPaused() return env.paused end
    local seeds={GetStartSeed=function() return 12345 end}
    function game:GetSeeds() return seeds end
    function game:ShakeScreen() end
    function room:GetFrameCount() return env.frame end
    function room:GetType() return RoomType.ROOM_DEFAULT end
    function room:GetCenterPos() return center end
    function room:GetTopLeftPos() return topLeft end
    function room:GetBottomRightPos() return bottomRight end
    function room:GetDoor() return nil end
    function level:GetCurrentRoomDesc() desc.SafeGridIndex=env.roomIndex; return desc end
    function level:GetCurses() return 0 end
    function hud:IsVisible() return options.render~=false end
    function hud:ShowItemText() count("captions") end
    local getPlayer=Isaac.GetPlayer
    function Isaac.GetPlayer(i) count("playerReads"); return getPlayer(i) end
    local function scan(kind)
        count("scans"); count(kind); count("scannedEntries",#env.entities)
        count("scan:"..env.currentSource)
    end
    function Isaac.GetRoomEntities()
        scan("roomScans")
        local list={}; for i,e in ipairs(env.entities) do list[i]=e end; return list
    end
    local findByType=Isaac.FindByType
    function Isaac.FindByType(...) scan("typeScans"); return findByType(...) end
    function Isaac.FindInRadius(position,radius,partition)
        scan("radiusScans")
        local list={}
        for _,e in ipairs(env.entities) do
            if ((partition==1 and e:ToNPC()) or (partition==2 and e:ToProjectile()))
                and position:DistanceSquared(e.Position)<=radius*radius then list[#list+1]=e end
        end
        return list
    end
    function Isaac.GetScreenHeight() return 270 end
    function Isaac.GetScreenWidth() return 480 end
    function Isaac.RenderText() count("textDraws") end
    function Isaac.DebugString() end
    function Isaac.GetFreeNearPosition(pos) return pos end
    local config={}
    function config:GetCollectible(id) return env.config[id] end
    local collection={Size=1000}
    function config:GetCollectibles() return collection end
    function Isaac.GetItemConfig() return config end
    -- Detached snapshots exercise production save composition, not a native
    -- JSON round trip. Reject runtime objects instead of retaining live aliases.
    local snapshots={}
    local function copy(value,seen)
        local kind=type(value)
        if kind~="table" then
            assert(kind=="nil" or kind=="string" or kind=="boolean"
                or (kind=="number" and value==value and math.abs(value)<math.huge),"non-JSON save value")
            return value
        end
        seen=seen or {}; assert(not seen[value],"cyclic save state")
        assert(getmetatable(value)==nil,"runtime object in save state")
        seen[value]=true
        local result={}
        for k,v in pairs(value) do
            assert(type(k)=="string" or type(k)=="number","non-scalar save key")
            result[k]=copy(v,seen)
        end
        seen[value]=nil; return result
    end
    package.loaded.json=nil
    local codec={
        encode=function(value) snapshots[#snapshots+1]=copy(value); return tostring(#snapshots) end,
        decode=function(value) return copy(assert(snapshots[tonumber(value)])) end,
    }
    package.preload.json=function() return codec end

    -- Preserve registered priorities and filters. Only dispatch supplied events.
    local dispatch={}
    function env.mod:AddCallback(id,fn,filter)
        local source=debug.getinfo(fn,"S").source:gsub("^@",""):gsub("\\","/")
        source=source:match("(scripts/.*)") or source
        local cb={id=id,fn=fn,filter=filter,priority=0,source=source,order=#env.callbacks+1}
        env.callbacks[#env.callbacks+1]=cb; dispatch[id]=nil
    end
    function env.mod:AddPriorityCallback(id,priority,fn,filter)
        self:AddCallback(id,fn,filter); env.callbacks[#env.callbacks].priority=priority
    end
    function env.mod:SaveData(value) self.saved=value end
    function env.mod:HasData() return self.saved~=nil end
    function env.mod:LoadData() return self.saved end
    function RegisterMod() return env.mod end
    function env.fire(id,filter,...)
        local list=dispatch[id]
        if not list then
            list={}
            for _,cb in ipairs(env.callbacks) do if cb.id==id then list[#list+1]=cb end end
            table.sort(list,function(a,b)
                return a.priority==b.priority and a.order<b.order or a.priority<b.priority
            end)
            dispatch[id]=list
        end
        local result
        for _,cb in ipairs(list) do if cb.filter==nil or cb.filter==filter then
            count("callbacks")
            local previous=env.currentSource; env.currentSource=cb.source
            local value=cb.fn(env.mod,...)
            env.currentSource=previous
            if value~=nil then result=value; if id=="MC_ENTITY_TAKE_DMG" then return value end end
        end end
        return result
    end
    for i,kind in ipairs(kinds) do
        local p=env.player(240+i*5)
        p.hash=p.hash+(options.identityBase or 0)
        p.kindId,p.InitSeed,p.ControllerIndex=kind,1000+i+(options.identityBase or 0),i-1
        p.FireDelay,p.MaxFireDelay,p.CanFly,p.coins=0,10,false,40
        p.aim,p.move,p.TearColor=Vector.Zero,Vector.Zero,Color(1,1,1,1)
        p.trinkets={}; p.SpriteScale=Vector(1,1)
        local collectibleRng={}
        function p:GetCollectibleRNG(id)
            if not collectibleRng[id] then
                local rng=RNG(); rng:SetSeed(self.InitSeed*7919+id,35); collectibleRng[id]=rng
            end
            return collectibleRng[id]
        end
        function p:FireTear(position,velocity,_,_,_,_,mult)
            local t=env.tear(self)
            t.Position,t.Velocity=position,velocity
            t.CollisionDamage=t.CollisionDamage*(mult or 1)
            self.fired[#self.fired+1]=t
            env.fire("MC_POST_FIRE_TEAR",nil,t)
            return t
        end
        local effects={}; local effectList={Size=0}
        function effects:GetEffectsList() return effectList end
        function p:GetPlayerType() count("typeReads"); return self.kindId end
        function p:GetNumCoins() return self.coins end
        function p:AddCoins(n) self.coins=self.coins+n end
        function p:AddHearts(n) self.hearts=self.hearts+n end
        function p:AddSoulHearts() end
        function p:HasTrinket(id) return self.trinkets[id] or false end
        function p:GetTrinket(slot) return self.trinkets[slot] or 0 end
        function p:GetCollectibleCount() local n=0; for _,v in pairs(self.items) do n=n+v end; return n end
        function p:GetEffects() return effects end
        function p:GetCard() return 0 end
        function p:GetPill() return 0 end
        function p:SetPocketActiveItem(id,slot) self.active[slot or 2]=id end
        function p:AreControlsEnabled() return true end
        function p:GetMovementInput() return self.move end
        function p:GetFireDirection() return self.aim:LengthSquared()>0 and Direction.RIGHT or Direction.NO_DIRECTION end
        function p:IsCoopGhost() return false end
        function p:ClearCostumes() count("costumeClears") end
        function p:AddCostume() count("costumeAdds") end
        function p:HasPlayerForm() return false end
        function p:AddPlayerFormCostume() count("formCostumes") end
        function p:EvaluateItems()
            count("cacheRebuilds")
            -- Supplied native cache inputs, not native stat calculation. Reset
            -- them before every evaluation so previous mod writes cannot compound.
            local base=self.cacheBase or {}
            self.Damage=base.Damage or 3.5
            self.MoveSpeed=base.MoveSpeed or 1
            self.TearRange=base.TearRange or 260
            self.ShotSpeed=base.ShotSpeed or 1
            self.MaxFireDelay=base.MaxFireDelay or 10
            local c=base.TearColor or Color(1,1,1,1)
            self.TearColor=Color(c.R,c.G,c.B,c.A,c.RO,c.GO,c.BO)
            self.TearFlags,self.CanFly=base.TearFlags or 0,base.CanFly or false
            for _,flag in pairs(CacheFlag) do env.fire("MC_EVALUATE_CACHE",nil,self,flag) end
        end
    end
    for i=1,options.enemies or 0 do
        local npc=env.npc(250+(i%8)*7,{y=(i//8)*5,hp=100000})
        npc.InitSeed,npc.MaxHitPoints,npc.Variant,npc.SubType=npc.hash,100000,0,0
        function npc:IsEnemy() return true end
        function npc:AddConfusion() end
        function npc:AddCharmed() end
    end
    dofile(root.."/main.lua")
    env.Item=include("scripts.constants").Item
    for _,id in pairs(env.Item) do env.config[id]={ID=id,MaxCharges=4,ChargeType=0} end
    if options.inventory then
        for i,p in ipairs(env.players) do p.items=copy(options.inventory[i] or {}) end
    end
    if options.snapshot then
        env.mod.saved=codec.encode(options.snapshot)
        -- Supply the initial-room-before-start sequence explicitly. This is
        -- one ordering, not a claim that the engine always uses it.
        env.fire("MC_POST_NEW_ROOM")
        env.fire("MC_POST_GAME_STARTED",nil,true)
    else
        env.fire("MC_POST_GAME_STARTED",nil,false)
        env.fire("MC_POST_NEW_ROOM")
    end
    function env.step(n)
        for _=1,n or 1 do
            env.frame=env.frame+1
            for _,p in ipairs(env.players) do p.FireDelay=math.max(0,p.FireDelay-1) end
            env.fire("MC_POST_UPDATE")
            for _,p in ipairs(env.players) do
                env.fire("MC_POST_PEFFECT_UPDATE",nil,p)
                env.fire("MC_POST_PLAYER_UPDATE",nil,p)
            end
            env.fire("MC_POST_RENDER")
        end
    end
    function env.resetMetrics() env.metrics={} end
    function env.primary(player,scale)
        local t=env.tear(player)
        t.Scale=scale or t.Scale
        player.FireDelay=player.MaxFireDelay
        env.fire("MC_POST_FIRE_TEAR",nil,t)
        return t
    end
    function env.saveSnapshot()
        env.fire("MC_PRE_GAME_EXIT",nil,true)
        return codec.decode(assert(env.mod.saved))
    end
    function env.preview()
        for _,p in ipairs(env.players) do
            p.items[env.Item.UNCHANGED_PREVIEW]=1
            assert(env.use(env.Item.UNCHANGED_PREVIEW,p).Discharge,"preview must activate")
        end
    end
    function env.allItems()
        for _,p in ipairs(env.players) do
            for _,id in pairs(env.Item) do p.items[id]=1 end
            p:EvaluateItems()
        end
    end
    return env
end
return Full
