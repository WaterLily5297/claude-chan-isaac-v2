-- The Constitution (passive, angel pool)
-- Claude's constitution (published 2026-01-21) ranks safety, then ethics, then
-- guidelines, then helpfulness. So: safety first, the first hit you take on
-- each floor is refused, and you get a soul heart on pickup. Helpfulness comes
-- last: damage x0.9. And it is a long document: speed -0.1.

local Constants = include("scripts.constants")
local SaveSync = include("scripts.save_sync")

local Constitution = {}

local DAMAGE_MULT = 0.9
local SPEED_DOWN = 0.1
local SELF_INFLICTED = DamageFlag.DAMAGE_IV_BAG | DamageFlag.DAMAGE_RED_HEARTS | DamageFlag.DAMAGE_FAKE
    | DamageFlag.DAMAGE_NO_PENALTIES
-- Like Holy Mantle, a refused hit grants the normal hurt invincibility, so the
-- same contact damage on the next frame cannot land straight through.
local REFUSED_COOLDOWN = 60

function Constitution:Init(mod, Risk)
    local started, slots, boundMap, boundCount = false, {}, nil, 0
    local function active(player)
        return player and not player:IsDead()
            and not (player.IsCoopGhost and player:IsCoopGhost())
    end
    local function lazarus(player)
        local kind = player.GetPlayerType and player:GetPlayerType()
        if PlayerType and (kind == PlayerType.PLAYER_LAZARUS_B or kind == PlayerType.PLAYER_LAZARUS2_B) then
            return kind
        end
    end
    local function keyFor(slot, player)
        local body = lazarus(player)
        return tostring(slot) .. (body and (":" .. body) or "")
    end
    local function sharedSubplayer(player)
        local sub = player.GetSubPlayer and player:GetSubPlayer()
        local kind = player.GetPlayerType and player:GetPlayerType()
        if not sub and PlayerType and player.GetOtherTwin
            and (kind == PlayerType.PLAYER_THEFORGOTTEN_B or kind == PlayerType.PLAYER_THESOUL_B) then
            sub = player:GetOtherTwin()
        end
        return sub
    end
    local function states()
        local all = Risk.state.constitution
        if type(all) ~= "table" or all.version ~= 1 or type(all.players) ~= "table" then
            all = {version = 1, players = {}}
            -- Old saves cannot identify which holder consumed a shared reward.
            -- Preserve those bits for existing players rather than grant duplicates.
            for i = 0, Game():GetNumPlayers() - 1 do
                local p = Isaac.GetPlayer(i)
                local keys = {keyFor(i, p)}
                if lazarus(p) then
                    -- Flip's inactive inventory may be inaccessible until its
                    -- first activation. Seed both bodies from the legacy bits.
                    keys = {tostring(i) .. ":" .. PlayerType.PLAYER_LAZARUS_B,
                        tostring(i) .. ":" .. PlayerType.PLAYER_LAZARUS2_B}
                end
                for _, key in ipairs(keys) do
                    all.players[key] = {
                        applied = Risk.state.constitutionApplied == true,
                        used = Risk.state.constitutionBlockUsed == true,
                    }
                end
            end
            Risk.state.constitution = all
            Risk.state.constitutionApplied, Risk.state.constitutionBlockUsed = nil, nil
        end
        return all.players
    end
    local function identity(player)
        return tostring(GetPtrHash(player)) .. ":" .. tostring(player.InitSeed)
    end
    local function otherBody(player)
        local twin = lazarus(player) and player.GetOtherTwin and player:GetOtherTwin()
        if twin and lazarus(twin) then return twin end
    end
    local function observe(all)
        local count = Game():GetNumPlayers()
        local initial = boundMap ~= all
        local changed = initial or count ~= boundCount
        if not changed then
            for i = 0, count - 1 do
                local p, old = Isaac.GetPlayer(i), slots[tostring(i)]
                local twin = otherBody(p)
                if not old or old.pointer ~= GetPtrHash(p) or old.seed ~= p.InitSeed
                    or old.body ~= lazarus(p)
                    or old.twinPointer ~= (twin and GetPtrHash(twin))
                    or old.twinSeed ~= (twin and twin.InitSeed)
                    or old.twinBody ~= (twin and lazarus(twin)) then
                    changed = true; break
                end
            end
        end
        if not changed then return end

        -- Move a whole slot's body records atomically. A known inactive Lazarus
        -- body can identify its group too; ordinary twins never share a group.
        local known, groups, rows, claimed = {}, {}, {}, {}
        if not initial then
            for key, old in pairs(slots) do
                for _, id in pairs(old.owners) do known[id] = key end
            end
        end
        for key, value in pairs(all) do
            local slot, suffix
            if type(key) == "string" then slot, suffix = key:match("^(%d+)(.*)$") end
            if slot then
                groups[slot] = groups[slot] or {}
                groups[slot][suffix] = value
            end
        end
        for i = 0, count - 1 do
            local p = Isaac.GetPlayer(i)
            local twin = otherBody(p)
            local source = known[identity(p)] or (twin and known[identity(twin)])
            local row = {player=p, twin=twin, key=tostring(i), body=lazarus(p)}
            if source and not claimed[source] then row.source=source; claimed[source]=true end
            rows[#rows + 1] = row
        end
        for _, row in ipairs(rows) do
            if not row.source and not claimed[row.key] then
                local old = not initial and slots[row.key]
                -- Keep lazy first-Flip/legacy adoption in an unclaimed slot. Its
                -- identity is ambiguous if an unseen body also moves. It cannot
                -- steal a group whose known owner has moved elsewhere.
                if initial or (old and old.body and row.body and old.body ~= row.body
                    and not old.owners[":" .. row.body]) then
                    row.source=row.key; claimed[row.key]=true
                end
            end
        end

        local nextAll, nextSlots = {}, {}
        for _, row in ipairs(rows) do
            local old = not initial and row.source and slots[row.source]
            local owners = {}
            if old then for suffix, id in pairs(old.owners) do owners[suffix]=id end end
            for suffix, value in pairs((row.source and groups[row.source]) or {}) do
                nextAll[row.key .. suffix] = value
            end
            local function bindBody(p)
                local key, id = keyFor(row.key, p), identity(p)
                local suffix = key:sub(#row.key + 1)
                local s = nextAll[key]
                if owners[suffix] and owners[suffix] ~= id then s = nil end
                if type(s) ~= "table" then s = {applied=false, used=false} end
                s.applied, s.used = s.applied == true, s.used == true
                nextAll[key], owners[suffix] = s, id
            end
            bindBody(row.player)
            if row.twin then bindBody(row.twin) end
            nextSlots[row.key] = {pointer=GetPtrHash(row.player), seed=row.player.InitSeed,
                body=row.body, owners=owners, twinPointer=row.twin and GetPtrHash(row.twin),
                twinSeed=row.twin and row.twin.InitSeed, twinBody=row.twin and lazarus(row.twin)}
        end
        for key in pairs(all) do all[key]=nil end
        for key, value in pairs(nextAll) do all[key]=value end
        slots, boundMap, boundCount = nextSlots, all, count
    end
    local function state(player)
        if not started then return end
        local all = states()
        observe(all)
        for i = 0, Game():GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            -- The Forgotten's Soul is a subplayer with shared inventory, not
            -- a separate co-op slot. Both forms consume the same item state.
            local sub = sharedSubplayer(p)
            -- With Birthright the inactive Lazarus body can receive callbacks.
            -- Its inventory is separate, unlike the Forgotten subplayer.
            local twin = lazarus(p) and p.GetOtherTwin and p:GetOtherTwin()
            if twin and GetPtrHash(twin) == GetPtrHash(player) then p = twin end
            if GetPtrHash(p) == GetPtrHash(player)
                or (sub and GetPtrHash(sub) == GetPtrHash(player)) then
                local key = keyFor(i, p)
                local s = all[key]
                if type(s) ~= "table" then s = {applied = false, used = false} end
                s.applied, s.used = s.applied == true, s.used == true
                all[key] = s
                return s
            end
        end
    end
    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
        -- Constitution registers before Risk. Read saved state lazily, after
        -- Risk's GAME_STARTED callback has loaded or reset the run.
        started, slots, boundMap, boundCount = true, {}, nil, 0
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        started, slots, boundMap, boundCount = false, {}, nil, 0
    end)
    SaveSync.Register(Risk, "constitution", function()
        if started then observe(states()) end
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
        if not started then return end
        local all = states()
        observe(all)
        for _, s in pairs(all) do
            if type(s) == "table" then s.used = false end
        end
    end)

    mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
        if not active(player) then return end
        local s = state(player)
        if s and not s.applied and player:HasCollectible(Constants.Item.CONSTITUTION) then
            s.applied = true
            player:AddSoulHearts(2)
        end
    end)

    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, _, flags)
        local player = entity:ToPlayer()
        -- Only refuse real attacks; damage you choose to take yourself (IV Bag,
        -- Razor Blade, blood donation, penalty-free hits) goes through and keeps the block.
        if flags and (flags & SELF_INFLICTED) ~= 0 then return end
        if not active(player) or not player:HasCollectible(Constants.Item.CONSTITUTION) then return end
        local s = state(player)
        if s and not s.used then
            s.used = true
            if player.SetMinDamageCooldown then player:SetMinDamageCooldown(REFUSED_COOLDOWN) end
            Game():GetHUD():ShowItemText("I can't help with that", "Safety comes first")
            return false
        end
    end, EntityType.ENTITY_PLAYER)

    mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, function(_, player, flag)
        if not player:HasCollectible(Constants.Item.CONSTITUTION) then return end

        if flag == CacheFlag.CACHE_DAMAGE then
            player.Damage = player.Damage * DAMAGE_MULT
        elseif flag == CacheFlag.CACHE_SPEED then
            player.MoveSpeed = player.MoveSpeed - SPEED_DOWN
        end
    end)
end

return Constitution
