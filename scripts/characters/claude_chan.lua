-- Claude-chan (playable character)
-- Character design by ZipZipPipe (Bilibili / Pixiv), used non-commercially with credit.
--
-- Stats: long context window (Range +1.5), Shot Speed +0.2, Speed -0.1, orange tears.
-- Pocket item: Ban Hammer.
-- One More Day: each paid attack adds 4 usage (8 with Subagent Swarm): a
-- same-frame volley of tears, laser starts and Dr. Fetus bombs, each further
-- 0.2-second window of a held beam or Ludovico tear, a knife throw, a melee
-- swing or an Epic Fetus rocket (scripts/characters/paid_attacks.lua). Not
-- firing drains 10 per second. At 100 she is Limited: 40% damage on every
-- weapon for 5 seconds, then the meter resets. Appeals (start 1, cap 2, one per two unique combat
-- clears) are spent with a DROP tap to remove 40 usage; they cannot cancel an
-- active Limited penalty.
-- Account age (per player): each later floor offers a kill-order review for
-- +0.2 damage, up to +1.6. A suspension resets it ("Banned again"); Birthright
-- keeps it through the first suspension on each floor without cancelling the
-- penalty. Older saves with one shared age give it to each Claude present.

local Constants = include("scripts.constants")
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Tint = include("scripts.characters.tear_tint")
local PaidAttacks = include("scripts.characters.paid_attacks")
local Review = include("scripts.characters.claude_review")

local ClaudeChan = {}

local USAGE_MAX = 100
local USAGE_PER_TEAR = 4
local SWARM_USAGE = 4               -- Subagent Swarm's extra payment per volley
local USAGE_DRAIN_INTERVAL = 3      -- frames per point drained while not firing (10/second)
local LIMIT_FRAMES = 150            -- 5 seconds
local LIMITED_DAMAGE_MULT = 0.4

local APPEAL_START, APPEAL_MAX = 1, 2
local CLEARS_PER_APPEAL = 2
local APPEAL_RELIEF = 40

local AGE_DAMAGE = 0.2
local AGE_MAX = 8

local function isClaude(player)
    return player and Constants.Player.CLAUDE_CHAN >= 0
        and player:GetPlayerType() == Constants.Player.CLAUDE_CHAN
end

local function integer(v, maximum)
    return type(v) == "number" and v == v and v >= 0 and v <= maximum and v == math.floor(v)
end

-- Older saves have no appeal or age fields; start them with the normal
-- allowance. A save with the old shared age hands it to this player.
local function normalize(usage, legacyAge)
    -- Repair each counter independently; valid debt/countdowns survive Continue.
    if not integer(usage.value, USAGE_MAX) then usage.value = 0 end
    if not integer(usage.limited, LIMIT_FRAMES) then usage.limited = 0 end
    if not integer(usage.appeals, APPEAL_MAX) then usage.appeals = APPEAL_START end
    if not integer(usage.age, AGE_MAX) then
        usage.age = integer(legacyAge, AGE_MAX) and legacyAge or 0
    end
    if usage.ageShield ~= nil and type(usage.ageShield) ~= "string" then usage.ageShield = nil end
    if usage.banned ~= nil and usage.banned ~= true then usage.banned = nil end
    if not integer(usage.clears, CLEARS_PER_APPEAL - 1) then usage.clears = 0 end
    if type(usage.awards) ~= "table" then usage.awards = {} end
    return usage
end

local function floorKey()
    local level = Game():GetLevel()
    return tostring(level:GetDungeonPlacementSeed())..":"..level:GetStage()..":"..level:GetStageType()
end

local function observeRoom(usage)
    local floor = floorKey()
    if usage.floor ~= floor then usage.floor = floor; usage.awards = {}; usage.room = nil end
    local desc = Game():GetLevel():GetCurrentRoomDesc()
    local room = tostring(desc.SpawnSeed)..":"..tostring(desc.SafeGridIndex)
    if usage.room ~= room then usage.room = room; usage.armed = false end
    if not Game():GetRoom():IsClear() then usage.armed = true end
end

local function refreshDamage(player)
    player:AddCacheFlags(CacheFlag.CACHE_DAMAGE)
    player:EvaluateItems()
end

function ClaudeChan:Init(mod, Risk)
    local ready = false
    local drop = DropTap.New()
    local volleys = {} -- Transient: slot -> {frame, limited}.
    local updates = {} -- Transient: player pointer -> {seed, frame}.
    local applied = {} -- Transient: player pointer -> Limited state in the damage stat.
    local owners, refreshNeeded = {}, {} -- Live slot identity; never serialized.

    local function forgetRuntime(pointer)
        updates[pointer] = nil; applied[pointer] = nil; refreshNeeded[pointer] = nil
    end

    local function observeOwners()
        if not ready then return end
        local count, all = Game():GetNumPlayers(), Risk.state.claudeUsage
        local changed = false
        for i = 0, count - 1 do
            local p, previous = Isaac.GetPlayer(i), owners[tostring(i)]
            if not previous or previous.pointer ~= GetPtrHash(p) or previous.seed ~= p.InitSeed then
                changed = true; break
            end
        end
        for key in pairs(owners) do if tonumber(key) >= count then changed = true; break end end
        if not changed then
            if type(all) == "table" then
                for key in pairs(all) do if not owners[key] then all[key] = nil end end
            end
            return
        end

        -- Stage every read before rewriting slots. A continuously observed
        -- pointer/seed keeps its account and paid volley through cyclic moves.
        -- Loaded slots bind once at startup/Continue, before live owners exist.
        local bootstrap = next(owners) == nil
        local oldByPointer, nextOwners, nextAccounts, nextVolleys = {}, {}, {}, {}
        local retained, replacements = {}, {}
        for key, owner in pairs(owners) do oldByPointer[owner.pointer] = {slot=key, owner=owner} end
        for i = 0, count - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer = GetPtrHash(p)
            local old = oldByPointer[pointer]
            local sameOwner = old and old.owner.seed == p.InitSeed
            if sameOwner or bootstrap then
                local source = sameOwner and old.slot or key
                nextAccounts[key] = type(all) == "table" and all[source] or nil
                nextVolleys[key] = volleys[source]
            else
                p:GetData().ccUsage = nil
                forgetRuntime(pointer); drop:Forget(p)
                replacements[pointer] = true
            end
            if sameOwner then retained[pointer] = true end
            nextOwners[key] = sameOwner and old.owner or {pointer=pointer, seed=p.InitSeed}
        end
        for _, previous in pairs(owners) do
            if not retained[previous.pointer] then forgetRuntime(previous.pointer) end
        end
        if type(all) == "table" then
            for key in pairs(all) do all[key] = nil end
            for key, account in pairs(nextAccounts) do all[key] = account end
        end
        owners, volleys = nextOwners, nextVolleys
        -- Retire all old identities before scheduling replacement refreshes.
        for pointer in pairs(replacements) do refreshNeeded[pointer] = true end
        -- Type changes on the same pointer/seed deliberately retain Claude debt.
        -- An observed departure or a new pointer/seed still ends that account.
    end

    local function getUsage(player)
        observeOwners()
        local data = player:GetData()
        for i = 0, Game():GetNumPlayers() - 1 do
            if GetPtrHash(Isaac.GetPlayer(i)) == GetPtrHash(player) then
                -- Slots survive continue; pointers and entity data do not.
                local all = Risk.state.claudeUsage
                if type(all) ~= "table" then all = {}; Risk.state.claudeUsage = all end
                local key = tostring(i)
                if type(all[key]) ~= "table" then
                    all[key] = { value = 0, limited = 0 }
                end
                -- Compact and Banked Reset mutate this same saved table.
                data.ccUsage = normalize(all[key], Risk.state.accountAge)
                return all[key], key
            end
        end
        -- An entity outside the player list must not borrow another player's slot.
        data.ccUsage = normalize(data.ccUsage or { value = 0, limited = 0 }, nil)
        return data.ccUsage
    end

    -- Act once per suspension and player. The saved latch keeps a continue
    -- from re-judging a suspension that was already handled.
    local function observeSuspension(player, usage)
        if not Risk:IsSuspended() then usage.banned = nil; return end
        if usage.banned then return end
        usage.banned = true
        if usage.age == 0 then return end
        local floor = floorKey()
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and usage.ageShield ~= floor then
            usage.ageShield = floor
            Game():GetHUD():ShowItemText("Banned again", "Birthright kept your account age")
            return
        end
        usage.age = 0
        refreshDamage(player)
        Game():GetHUD():ShowItemText("Banned again", "Account age reset to 0")
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        -- Risk has already loaded or reset its state, before any item use or shot.
        if not continued then Risk.state.claudeUsage = {} end
        ready = true; volleys = {}; updates = {}; applied = {}; owners = {}; refreshNeeded = {}; drop:Reset()
        -- Reset transient identities at the load boundary: recreated players
        -- must still receive their saved slot's account on Continue.
        observeOwners()
        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if isClaude(player) then observeRoom(getUsage(player)); refreshDamage(player) end
        end
        -- The old shared age has now been handed to every Claude present.
        Risk.state.accountAge = nil
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; volleys = {}; updates = {}; owners = {}; refreshNeeded = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if isClaude(player) then observeRoom(getUsage(player)) end
        end
    end)

    -- A unique clear is a newly completed hostile room on this floor.
    mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, function()
        if not ready then return end
        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if isClaude(player) and not player:IsDead() then
                local usage = getUsage(player)
                observeRoom(usage)
                if usage.armed and not usage.awards[usage.room] then
                    usage.awards[usage.room] = true; usage.armed = false
                    usage.clears = usage.clears + 1
                    if usage.clears >= CLEARS_PER_APPEAL then
                        usage.clears = 0
                        usage.appeals = math.min(APPEAL_MAX, usage.appeals + 1)
                    end
                end
            end
        end
    end)

    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function() drop:Reset() end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not ready then return end
        observeOwners()
        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if isClaude(player) and refreshNeeded[GetPtrHash(player)] then refreshDamage(player) end
        end
    end)

    -- Give the Ban Hammer as a pocket active on a fresh run only, so continuing
    -- a run doesn't reset its charge.
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isContinued)
        if isContinued or Constants.Item.BAN_HAMMER <= 0 then return end

        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if isClaude(player) then
                player:SetPocketActiveItem(Constants.Item.BAN_HAMMER, ActiveSlot.SLOT_POCKET, false)
            end
        end
    end)

    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if not isClaude(player) then return end

        if flag == CacheFlag.CACHE_DAMAGE then
            local usage = getUsage(player)
            player.Damage = player.Damage + AGE_DAMAGE * usage.age
            -- Limited weakens every weapon through the damage stat.
            applied[GetPtrHash(player)] = usage.limited > 0
            if usage.limited > 0 then player.Damage = player.Damage * LIMITED_DAMAGE_MULT end
            refreshNeeded[GetPtrHash(player)] = nil
        elseif flag == CacheFlag.CACHE_RANGE then
            player.TearRange = player.TearRange + 1.5 * 40
        elseif flag == CacheFlag.CACHE_SHOTSPEED then
            player.ShotSpeed = player.ShotSpeed + 0.2
        elseif flag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed - 0.1
        elseif flag == CacheFlag.CACHE_TEARCOLOR then
            player.TearColor = Tint.Apply(player.TearColor, 1, 0.55, 0.25, 1)
        end
    end)

    -- Bills one paid volley per player and frame; returns it for its limit state.
    local function bill(player)
        local usage, key = getUsage(player)
        local now = Game():GetFrameCount()
        -- Same-frame pellets are one paid volley and share its limit state.
        local volley = key and volleys[key]
        if not volley or volley.frame ~= now then
            volley = { frame = now, limited = usage.limited > 0 }
            if key then volleys[key] = volley end
            if not volley.limited then
                local swarm = Constants.Item.SUBAGENT_SWARM
                local cost = USAGE_PER_TEAR
                    + ((swarm and swarm > 0 and player:HasCollectible(swarm)) and SWARM_USAGE or 0)
                usage.value = usage.value + cost
                if usage.value >= USAGE_MAX then
                    usage.value = USAGE_MAX
                    usage.limited = LIMIT_FRAMES
                    refreshDamage(player)
                    Game():GetHUD():ShowItemText("Usage limit reached", "Your limit will reset soon")
                end
            end
        end
        return volley
    end

    mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, function(_, tear)
        if not ready then return end
        local player = tear.SpawnerEntity and tear.SpawnerEntity:ToPlayer()
        if not isClaude(player) then return end
        -- Item helpers are not new paid volleys. Limited damage comes from the
        -- damage stat; the grey tint only marks the weakened volley.
        local limited
        if tear:GetData().ccThoughtDerived then limited = getUsage(player).limited > 0
        else limited = bill(player).limited end
        if limited then
            tear.Color = Tint.Apply(tear.Color, 0.5, 0.5, 0.5, 0.7)
        end
    end)
    -- Lasers and Dr. Fetus bombs bill usage on the frame they start; held
    -- beams, knives, swings and rockets bill through the shared observer.
    mod:AddCallback(ModCallbacks.MC_POST_LASER_INIT, function(_, laser)
        if not ready then return end
        if laser.Parent and laser.Parent.Type == EntityType.ENTITY_LASER then return end
        local player = laser.SpawnerEntity and laser.SpawnerEntity:ToPlayer()
        if isClaude(player) then bill(player) end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT, function(_, bomb)
        if not ready or not bomb.IsFetus then return end
        local player = bomb.SpawnerEntity and bomb.SpawnerEntity:ToPlayer()
        if isClaude(player) then bill(player) end
    end)
    PaidAttacks.Observe(mod, function(player)
        if ready and isClaude(player) and not player:IsDead() then bill(player) end
    end)

    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
        if not ready then return end
        observeOwners()
        local pointer = GetPtrHash(player)
        if not isClaude(player) then
            updates[pointer] = nil
            drop:Forget(player)
            return
        end
        if Game():IsPaused() or player:IsDead() then
            drop:Forget(player)
            return
        end
        local now = Game():GetFrameCount()
        local usage, key = getUsage(player)
        observeSuspension(player, usage)
        observeRoom(usage)
        -- Suspension and room bookkeeping are already idempotent and may
        -- observe same-frame changes. Only timed progress needs this guard.
        local previous = updates[pointer]
        if previous and previous.seed == player.InitSeed and previous.frame == now then return end
        updates[pointer] = {seed=player.InitSeed, frame=now}
        if usage.limited > 0 then
            usage.limited = usage.limited - 1
            if usage.limited == 0 then
                usage.value = 0
            end
        elseif usage.value > 0 and now % USAGE_DRAIN_INTERVAL == 0 then
            local volley = key and volleys[key]
            local firing = player:GetShootingInput():LengthSquared() > 0
                or (volley and volley.frame == now)
            if not firing then usage.value = usage.value - 1 end
        end

        -- Items such as Banked Reset can end Limited outside this module.
        if refreshNeeded[pointer] or (usage.limited > 0) ~= (applied[pointer] or false) then refreshDamage(player) end

        -- No usage means nothing to appeal: the Appeal is kept.
        if drop:Poll(player, true) then
            if usage.appeals > 0 and usage.limited == 0 and usage.value > 0 then
                usage.appeals = usage.appeals - 1
                usage.value = math.max(0, usage.value - APPEAL_RELIEF)
                Game():GetHUD():ShowItemText("Appeal filed", "Another love letter.")
            else
                drop:Refuse(player, usage.limited > 0 and "Usage limit active"
                    or usage.appeals == 0 and "No Appeals left" or "No Usage to appeal")
            end
        end
    end)

    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if Game():IsPaused() then drop:Reset() end
        if not ready or not Game():GetHUD():IsVisible() then return end

        for i = 0, Game():GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if isClaude(player) then
                local usage = getUsage(player)
                local y = HudLayout.PlayerRow(i)
                local ageText = HudText:T("age", usage.age)
                local labels = {waiting="  Review pending", active="  Review: marked target last",
                    won="  Review passed", missed="  Review missed"}
                ageText = ageText..(usage.review and labels[usage.review.phase] or "")
                HudText:Draw(ageText, 50, HudLayout.PlayerRow(i, 1), 1, 0.85, 0.5, 0.9)
                local appeals = string.format("  Appeals %d/%d", usage.appeals, APPEAL_MAX)
                -- Keep the separate account-age row visible during a refusal.
                if not drop:DrawRefusal(player, HudText, HudLayout, i) then
                    if usage.limited > 0 then
                        HudText:Draw(HudText:T("limited", math.ceil(usage.limited / 30)) .. appeals, 50, y, 1, 0.3, 0.3, 1)
                    else
                        HudText:Draw(HudText:T("usage", usage.value) .. appeals, 50, y, 1, 0.65, 0.3, 1)
                    end
                end
            end
        end
    end)
    Review:Init(mod, Risk, getUsage, refreshDamage)
end

return ClaudeChan
