-- Observe DROP without consuming or overriding the engine's native input.
-- A gesture is transient: interrupted presses must never become saved actions.
local DropTap = {}
local MAX_TAP_FRAMES = 12

local function hasPocketChoice(player)
    local count = 0
    -- Card/pill slots 0-3 are distinct from active slots. GetPocketItem is
    -- unusable in base Repentance, so inspect the documented getters instead.
    for slot = 0, 3 do
        if player:GetCard(slot) ~= 0 or player:GetPill(slot) ~= 0 then
            count = count + 1
            if count > 1 then return true end
        end
    end
    -- ActiveSlot.SLOT_POCKET and SLOT_POCKET2; exclude main and Schoolbag.
    for slot = 2, 3 do
        if player:GetActiveItem(slot) ~= 0 then
            count = count + 1
            if count > 1 then return true end
        end
    end
    return false
end

function DropTap.New()
    local records, gestures, cues = {}, {}, {}
    local tracker = {}

    function tracker:Reset()
        if next(records) then records = {} end
        if next(gestures) then gestures = {} end
        if next(cues) then cues = {} end
    end

    function tracker:Forget(player)
        local pointer = GetPtrHash(player)
        records[pointer], gestures[pointer], cues[pointer] = nil, nil, nil
    end

    local function poll(states, player, enabled)
        local pointer = GetPtrHash(player)
        -- A co-op ghost keeps its character type but must not use abilities.
        if not enabled or player:IsDead() or not player:AreControlsEnabled()
            or (player.IsCoopGhost and player:IsCoopGhost()) or Game():IsPaused() then
            states[pointer] = nil
            return false
        end
        local frame, controller = Game():GetFrameCount(), player.ControllerIndex
        local pressed = Input.IsActionPressed(ButtonAction.ACTION_DROP, controller)
        local kind, seed = player:GetPlayerType(), player.InitSeed
        local s = states[pointer]
        if not s or s.seed ~= seed or s.kind ~= kind or s.controller ~= controller
            or frame < s.frame then
            -- Observe a release before accepting a new press. This prevents a
            -- button held through entry, continue or control reassignment firing.
            states[pointer] = {seed=seed, kind=kind, controller=controller,
                frame=frame, down=pressed}
            return false
        end
        -- Native cycling owns any gesture that encounters multiple pocket
        -- items. Never rearm it just because one was used/dropped while held.
        -- Check before duplicate-frame rejection: inventory can change between
        -- two callbacks in that same frame.
        if (pressed or s.started) and hasPocketChoice(player) then
            s.frame, s.down, s.started = frame, pressed, nil
            return false
        end
        if frame == s.frame then return false end
        s.frame = frame
        if pressed then
            if not s.down then s.started = frame end
            if s.started and frame - s.started > MAX_TAP_FRAMES then s.started = nil end
            s.down = true
            return false
        end
        local tapped = s.down and s.started ~= nil
            and frame - s.started >= 1 and frame - s.started <= MAX_TAP_FRAMES
        s.down, s.started = false, nil
        return tapped
    end

    -- Observe refused gestures separately: an unavailable ability still forgets
    -- its action press, exactly as before. Feedback must never rearm that action.
    function tracker:Poll(player, enabled, reason)
        local tapped = poll(records, player, enabled)
        local observed = poll(gestures, player, true)
        local pointer = GetPtrHash(player)
        local s = gestures[pointer]
        if not s then cues[pointer] = nil; return false end
        if (s.started or observed) and not enabled then s.reason = reason end
        if tapped then
            -- A target check can still refuse this accepted tap before render.
            if cues[pointer] then cues[pointer].accepted = true end
        elseif observed and s.reason then
            self:Refuse(player, enabled and "State changed; tap again" or s.reason)
        end
        if not s.started then s.reason = nil end
        return tapped
    end

    function tracker:Refuse(player, reason)
        local pointer, now = GetPtrHash(player), Game():GetFrameCount()
        local old = cues[pointer]
        -- Repeated refusal taps update the reason without extending the flash.
        if old and old.seed == player.InitSeed and old.kind == player:GetPlayerType()
            and old.controller == player.ControllerIndex and now >= old.frame and now < old.untilFrame then
            old.accepted = nil
            old.text = "DROP: "..reason
            return
        end
        cues[pointer] = {text="DROP: "..reason, frame=now, untilFrame=now+45,
            seed=player.InitSeed, kind=player:GetPlayerType(), controller=player.ControllerIndex}
    end

    -- Replaces this player's existing form line; no extra co-op rows, sounds or
    -- shared item captions. Nothing here is persistent player state.
    function tracker:DrawRefusal(player, hud, layout, index)
        local pointer, now = GetPtrHash(player), Game():GetFrameCount()
        local cue = cues[pointer]
        if not cue then return false end
        if cue.accepted or cue.seed ~= player.InitSeed or cue.kind ~= player:GetPlayerType()
            or cue.controller ~= player.ControllerIndex or now < cue.frame or now >= cue.untilFrame
            or player:IsDead() or not player:AreControlsEnabled() or Game():IsPaused()
            or (player.IsCoopGhost and player:IsCoopGhost()) then
            cues[pointer] = nil
            return false
        end
        layout.DrawPlayer(hud, index, cue.text, 1, 0.8, 0.5, 1)
        return true
    end

    return tracker
end

return DropTap
