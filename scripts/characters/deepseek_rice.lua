-- Rice First: a saved, personal meal economy. No proxy or risk mechanics.
local C = include("scripts.constants")
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local ThoughtAttacks = include("scripts.characters.thought_attacks")
local Rice = {}

local function normal(p)
    return p and C.Player.DEEPSEEK_CHAN >= 0 and p:GetPlayerType() == C.Player.DEEPSEEK_CHAN
end
local function integer(v, maximum, fallback)
    if type(v) ~= "number" or v ~= v or v < 0 or v > maximum or v ~= math.floor(v) then return fallback end
    return math.floor(v)
end
local function fresh()
    return {version=2, bowls=1, clears=0, thought=0, speed=0, lunch=false, awards={},
        windowRemaining=0, windowFactor=1}
end

function Rice:Init(mod, Risk, Meal)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function allStates()
        if type(Risk.state.deepseekRice) ~= "table" then Risk.state.deepseekRice = {} end
        return Risk.state.deepseekRice
    end
    local function refresh(p)
        p:AddCacheFlags(CacheFlag.CACHE_SPEED)
        p:EvaluateItems()
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i=0,Game():GetNumPlayers()-1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if normal(p) then
                local b = bindings[pointer]
                local sameOwner = b and b.seed == p.InitSeed
                -- Slot changes alone do not change the owner. Keep the live
                -- attack clock/window as well as its scalar saved progress.
                local s = all[sameOwner and b.slot or key]
                if not sameOwner and previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then s = nil end
                if type(s) ~= "table" or (s.version ~= 1 and s.version ~= 2)
                    or not integer(s.bowls,2) or not integer(s.clears,1)
                    or not integer(s.thought,150) or not integer(s.speed,180) then
                    s=fresh()
                end
                if s.version == 1 then s.version=2; s.mealToken=nil end
                s.mealToken=integer(s.mealToken,2147483647)
                s.lunch = s.lunch == true
                s.windowRemaining=integer(s.windowRemaining,6,0)
                if type(s.windowFactor)~="number" or s.windowFactor~=s.windowFactor
                    or s.windowFactor<1 or s.windowFactor>2 then
                    s.windowRemaining=0; s.windowFactor=1
                end
                if type(s.awards) ~= "table" then s.awards={} end
                if not sameOwner then
                    b = {seed=p.InitSeed, slot=key, frame=Game():GetFrameCount(), clock=0}
                    if s.windowRemaining>0 then
                        b.window={clock=s.windowRemaining-6,multiplier=s.windowFactor}
                    end
                end
                b.slot=key; b.state=s; nextBindings[pointer]=b
            else
                -- Observed character changes discard the former form's rewards.
                if bindings[pointer] then refresh(p) end
            end
            nextSlots[key]={pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do all[key]=nil end
        for _, b in pairs(nextBindings) do all[b.slot]=b.state end
        bindings, slots = nextBindings, nextSlots
    end
    local function binding(p)
        if not ready or not normal(p) then return end
        local b=bindings[GetPtrHash(p)]
        if b and b.seed == p.InitSeed then return b end
    end
    local function roomIdentity()
        local level=Game():GetLevel()
        local floor=tostring(level:GetDungeonPlacementSeed())..":"..level:GetStage()..":"..level:GetStageType()
        local desc=level:GetCurrentRoomDesc()
        return floor, tostring(desc.SpawnSeed)..":"..tostring(desc.SafeGridIndex)
    end
    local function observeRoom(s)
        local floor, room=roomIdentity()
        if s.floor ~= floor then s.floor=floor; s.awards={}; s.room=nil end
        if s.room ~= room then s.room=room; s.armed=false end
        if not Game():GetRoom():IsClear() then s.armed=true end
    end
    local function each(fn)
        for i=0,Game():GetNumPlayers()-1 do
            local p=Isaac.GetPlayer(i)
            local b=binding(p)
            if b then fn(p,b,i) end
        end
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready=true; bindings={}; slots={}; drop:Reset()
        if not continued then Risk.state.deepseekRice={} end
        bind()
        each(function(p,b)
            observeRoom(b.state)
            -- A missing/corrupt shared timer cannot manufacture a completed meal.
            if Meal:Remaining(p) <= 0 then b.state.lunch=false end
            refresh(p)
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready=false; bindings={}; slots={}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        each(function(_,b)
            b.volley=nil; b.window=nil; b.attackFrame=nil; b.continuousFrame=nil
            b.state.windowRemaining=0; b.state.windowFactor=1
            observeRoom(b.state)
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() drop:Reset() end)
    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_,p,flag)
        local b=binding(p)
        if b and flag == CacheFlag.CACHE_SPEED and b.state.speed > 0 then
            p.MoveSpeed=p.MoveSpeed+0.15
        end
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not ready then return end
        bind()
        each(function(p,b)
            local s=b.state
            observeRoom(s)
            if p:IsDead() or not s.armed or s.awards[s.room] then return end
            s.awards[s.room]=true; s.armed=false
            s.clears=s.clears+1
            if s.clears == 2 then s.clears=0; s.bowls=math.min(2,s.bowls+1) end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not ready then return end
        bind()
        local now=Game():GetFrameCount()
        if Game():IsPaused() then
            drop:Reset()
            each(function(_,b)
                b.frame=now
                if b.continuousFrame then b.continuousFrame=now end
            end)
            return
        end
        each(function(p,b)
            local s=b.state
            observeRoom(s)
            if p:IsDead() then
                drop:Forget(p)
                local hadSpeed=s.speed>0
                s.lunch=false; s.speed=0; s.thought=0; b.frame=now; b.volley=nil; b.window=nil
                s.windowRemaining=0; s.windowFactor=1
                if hadSpeed then refresh(p) end
                return
            end
            local advanced=now>b.frame
            local cancelled = false
            if s.lunch and p:AreControlsEnabled() and p:GetMovementInput():LengthSquared()>0 then
                -- Another food effect may have replaced the timer. Never cancel that effect.
                if s.mealToken then Meal:CancelOwned(p,"rice",s.mealToken) end
                s.lunch=false; s.mealToken=nil; s.bowls=math.min(2,s.bowls+1); cancelled=true
            end
            if now<b.frame then
                b.volley=nil; b.window=nil; b.attackFrame=nil; b.continuousFrame=nil
                s.windowRemaining=0; s.windowFactor=1
                drop:Forget(p)
            end
            b.frame=now
            if advanced then
                b.clock=b.clock+1
                if b.window then
                    s.windowRemaining=math.max(0,6-(b.clock-b.window.clock))
                    if s.windowRemaining==0 then s.windowFactor=1 end
                end
                if s.speed>0 then
                    s.speed=s.speed-1
                    if s.speed==0 then refresh(p) end
                end
                if s.lunch and Meal:Remaining(p)==0 then
                    s.lunch=false; s.mealToken=nil; s.thought=150; s.speed=180
                    refresh(p)
                elseif not cancelled and Meal:Remaining(p)==0 and p:AreControlsEnabled()
                    and p:GetShootingInput():LengthSquared()==0
                    and b.attackFrame~=now
                    and (not b.continuousFrame or b.continuousFrame<now-1) then
                    s.thought=math.min(150,s.thought+1)
                end
            end
            if drop:Poll(p,true) and s.bowls>0 and not s.lunch and Meal:Remaining(p)==0
                and p:GetMovementInput():LengthSquared()==0 then
                local duration=p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 30 or 60
                local started, token=Meal:Start(p,duration,"rice")
                if started then
                    s.bowls=s.bowls-1; s.lunch=true; s.mealToken=token
                end
            end
        end)
    end)
    -- A delayed burst (Cursed Eye, multi-frame volleys) is any discrete attack
    -- that arrives before the native firing cycle could fire again, capped.
    local function burst(p,b)
        local v=b.volley
        if not v or not v.discrete then return false end
        local cycle=math.min(15,math.max(0,math.floor(tonumber(p.MaxFireDelay) or 0)))
        return b.clock-v.clock<cycle
    end
    local function current(p,b,now)
        return b.volley and (b.volley.frame==now or burst(p,b))
    end
    local function resolve(p,continuous)
        local b=binding(p)
        if not b or p:IsDead() or Game():IsPaused() then return end
        local now=Game():GetFrameCount()
        if not b.volley or b.volley.frame~=now and (continuous or not burst(p,b)) then
            if continuous and b.window and b.clock-b.window.clock<6 then
                b.volley={frame=now,clock=b.clock,multiplier=b.window.multiplier}
            else
                b.volley={frame=now,clock=b.clock,multiplier=1+b.state.thought/150,discrete=not continuous}
                b.state.thought=0
            end
        end
        if continuous and (not b.window or b.clock-b.window.clock>=6) then
            b.window={clock=b.clock,multiplier=b.volley.multiplier}
            b.state.windowRemaining=6; b.state.windowFactor=b.volley.multiplier
        end
        b.attackFrame=now
        return b.volley.multiplier
    end
    ThoughtAttacks:Init(mod,{
        Eligible=function(p) return binding(p)~=nil end,
        Resolve=resolve,
        WindowFactor=function(p)
            local b=binding(p)
            if b and b.window and b.clock-b.window.clock<6 then return b.window.multiplier end
            return 1
        end,
        Active=function(p)
            local b=binding(p)
            if b then b.continuousFrame=Game():GetFrameCount() end
        end,
        -- The current discrete volley's multiplier, without paying. Mimic
        -- familiars ride along on an attack the player already paid for.
        Peek=function(p)
            local b=binding(p)
            if not b or p:IsDead() or Game():IsPaused() then return end
            if current(p,b,Game():GetFrameCount()) and b.volley.discrete then return b.volley.multiplier end
        end,
    })
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() then return end
        each(function(p,b,i)
            local s=b.state
            local text=string.format("Thought %.1fs  Rice %d/2",s.thought/30,s.bowls)
            if s.lunch then text=text..string.format("  Lunch %.1fs: stay still",Meal:Remaining(p)/30) end
            HudLayout.DrawPlayer(HudText, i, text, 0.45,0.75,1,1)
        end)
    end)
end

return Rice
