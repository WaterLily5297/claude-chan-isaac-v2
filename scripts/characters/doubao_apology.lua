-- Normal Doubao: Sorry, You're Right. The first enemy hit in a room earns an Apology.
-- It never refunds health or cancels the hit. Saved per player; fictional role.
local HudText = include("scripts.hud_text")
local HudLayout = include("scripts.hud_layout")
local DropTap = include("scripts.characters.drop_tap")
local Feedback = include("scripts.characters.feedback")
local Doubao = {}

local TOKEN_FRAMES = 180 -- Six seconds.
local RADIUS = 100
local SLOW_FRAMES, SLOW_VALUE = 60, 0.5
local BULLETS = 4

local function integer(v, minimum, maximum)
    return type(v) == "number" and v == v and v >= minimum and v <= maximum and v == math.floor(v)
end
local function fresh()
    return {version=2, aimX=0, aimY=1}
end
-- token: remaining frames, or 0 for a Birthright token that lasts until room exit.
local function valid(s)
    return type(s) == "table" and (s.version == 1 or (s.version == 2
        and type(s.aimX) == "number" and type(s.aimY) == "number"
        and math.abs(s.aimX * s.aimX + s.aimY * s.aimY - 1) < 0.0001))
        and (s.hitRoom == nil or type(s.hitRoom) == "string")
        and (s.tokenRoom == nil or type(s.tokenRoom) == "string")
        and (s.tokenRoom == nil) == (s.token == nil)
        and (s.token == nil or integer(s.token, 0, TOKEN_FRAMES))
end

function Doubao:Init(mod, Risk)
    local id = Isaac.GetPlayerTypeByName("Doubao-chan", false)
    local ready, bindings, slots = false, {}, {}
    local drop = DropTap.New()
    local function isDoubao(p)
        return p and id >= 0 and p:GetPlayerType() == id
    end
    local function allStates()
        if type(Risk.state.doubaoApology) ~= "table" then Risk.state.doubaoApology = {} end
        return Risk.state.doubaoApology
    end
    local function roomKey()
        local level = Game():GetLevel()
        return tostring(level:GetDungeonPlacementSeed())..":"..tostring(level:GetCurrentRoomDesc().SpawnSeed)
    end
    local function bind()
        local all, nextBindings, nextSlots = allStates(), {}, {}
        for i = 0, Game():GetNumPlayers() - 1 do
            local p, key = Isaac.GetPlayer(i), tostring(i)
            local pointer, previous = GetPtrHash(p), slots[key]
            if isDoubao(p) then
                if previous and (previous.pointer ~= pointer or previous.seed ~= p.InitSeed
                    or previous.kind ~= p:GetPlayerType()) then all[key] = nil end
                if not valid(all[key]) then all[key] = fresh() end
                if all[key].version == 1 then all[key].version = 2; all[key].aimX = 0; all[key].aimY = 1 end
                local b = bindings[pointer]
                if not b or b.seed ~= p.InitSeed or b.slot ~= key then
                    b = {seed=p.InitSeed, slot=key, frame=Game():GetFrameCount()}
                end
                b.state = all[key]; nextBindings[pointer] = b
            else
                all[key] = nil
            end
            nextSlots[key] = {pointer=pointer, seed=p.InitSeed, kind=p:GetPlayerType()}
        end
        for key in pairs(all) do if not nextSlots[key] then all[key] = nil end end
        bindings, slots = nextBindings, nextSlots
    end
    local function binding(p)
        if not ready or not isDoubao(p) then return end
        local b = bindings[GetPtrHash(p)]
        if b and b.seed == p.InitSeed then return b end
    end
    local function each(fn)
        for i = 0, Game():GetNumPlayers() - 1 do
            local p = Isaac.GetPlayer(i)
            local b = binding(p)
            if b then fn(p, b, i) end
        end
    end
    local function dropToken(s) s.token = nil; s.tokenRoom = nil end
    -- Only enemies and their bullets qualify; machines, curses and self-damage do not.
    local function enemyCaused(source)
        local e = source and source.Entity
        if not e then return false end
        if e.Type == EntityType.ENTITY_PROJECTILE then return true end
        return e:IsEnemy() and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
    end
    local function rememberAim(p, s)
        local aim = p:GetShootingInput()
        local length = math.sqrt(aim.X * aim.X + aim.Y * aim.Y)
        if length > 0 then s.aimX, s.aimY = aim.X / length, aim.Y / length end
    end
    local function direction(s)
        local names = {"Right", "Down-right", "Down", "Down-left", "Left", "Up-left", "Up", "Up-right"}
        return names[math.floor(math.atan(s.aimY, s.aimX) / (math.pi / 4) + 0.5) % 8 + 1]
    end
    local function apologize(p, s)
        Feedback.Burst(p.Position, Color(1, 0.6, 0.7, 1, 0.3, 0.1, 0.15))
        for _, e in ipairs(Isaac.FindInRadius(p.Position, RADIUS, EntityPartition.ENEMY)) do
            local dx, dy = e.Position.X - p.Position.X, e.Position.Y - p.Position.Y
            local distance = math.sqrt(dx * dx + dy * dy)
            if e:IsVulnerableEnemy() and not e:IsDead() and not e:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
                and distance <= RADIUS + 1e-9 and dx * s.aimX + dy * s.aimY >= 0.5 * distance - 1e-9 then
                e:AddSlowing(EntityRef(p), SLOW_FRAMES, SLOW_VALUE, Color(1, 0.8, 0.8, 1, 0, 0, 0))
            end
        end
        local bullets = {}
        for _, e in ipairs(Isaac.FindInRadius(p.Position, RADIUS, EntityPartition.BULLET)) do
            if e:ToProjectile() and e:Exists() and p.Position:Distance(e.Position) <= RADIUS then bullets[#bullets + 1] = e end
        end
        table.sort(bullets, function(a, b) return p.Position:Distance(a.Position) < p.Position:Distance(b.Position) end)
        for i = 1, math.min(BULLETS, #bullets) do bullets[i]:Remove() end
    end

    mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, continued)
        ready = true; bindings = {}; slots = {}; drop:Reset()
        if not continued then Risk.state.doubaoApology = {} end
        bind()
    end)
    mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
        ready = false; bindings = {}; slots = {}; drop:Reset()
    end)
    mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
        drop:Reset()
        if not ready then return end
        bind()
        if not next(bindings) then return end
        local room = roomKey()
        each(function(_, b) if b.state.tokenRoom ~= room then dropToken(b.state) end end)
    end)
    mod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if not ready then return end
        bind()
        if not next(bindings) then return end
        local now = Game():GetFrameCount()
        if Game():IsPaused() then
            drop:Reset()
            each(function(_, b) b.frame = now end)
            return
        end
        each(function(p, b)
            local s = b.state
            if p:IsDead() then drop:Forget(p); b.frame = now; return end
            rememberAim(p, s)
            if now > b.frame and s.token and s.token > 0 then
                s.token = s.token - 1
                if s.token == 0 then dropToken(s) end
            end
            b.frame = now
            if drop:Poll(p, s.token ~= nil,
                "No Apology ready") then
                dropToken(s)
                apologize(p, s)
                Game():GetHUD():ShowItemText("Doubao-chan", "Sorry, you're right.")
            end
        end)
    end)
    mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function(_, entity, _, flags, source)
        if not ready or not next(bindings) then return end
        local p = entity:ToPlayer()
        local b = binding(p)
        if not b then return end
        if (flags & (DamageFlag.DAMAGE_FAKE | DamageFlag.DAMAGE_NO_PENALTIES)) ~= 0 then return end
        if Game():GetRoom():IsClear() or not enemyCaused(source) then return end
        local s, room = b.state, roomKey()
        if s.hitRoom == room then return end
        s.hitRoom = room
        s.tokenRoom = room
        s.token = p:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 0 or TOKEN_FRAMES
        Game():GetHUD():ShowItemText("Doubao-chan", "Apology ready")
    end, EntityType.ENTITY_PLAYER)
    mod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if not ready then return end
        if Game():IsPaused() then drop:Reset() end
        if not Game():GetHUD():IsVisible() then return end
        each(function(p, b, i)
            if drop:DrawRefusal(p, HudText, HudLayout, i) then return end
            local s = b.state
            local text = "Doubao-chan: No apology needed"
            if s.token == 0 then text = "Doubao-chan: Apology Ready"
            elseif s.token then text = string.format("Doubao-chan: Apology Ready %ds", math.ceil(s.token / 30)) end
            if s.token then text = text.."  Aim "..direction(s) end
            HudLayout.DrawPlayer(HudText, i, text, 1, 0.7, 0.6, 0.9)
        end)
    end)
end

return Doubao
