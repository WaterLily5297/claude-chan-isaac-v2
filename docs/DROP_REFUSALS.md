# DROP refusal feedback

Updated 2026-10-30, implementing U5 from baseline `39bda21`. **Owner delegated** the quiet feedback rule: a refused short tap replaces only that player's normal form HUD line with an English `DROP: ...` reason for 45 frames (1.5 seconds). There is no sound, shared item caption or extra co-op row. Normal Qwen always cycles and needs no refusal cue. Costs, cooldowns, targets and ability eligibility are unchanged.

Repeated refusal taps update the reason without extending the current flash. A successful ability restores its normal HUD at render. Room/floor/run reset, pause, death, loss of controls, ghost status or player identity changes clear the transient cue; Continue never restores it. Normal Claude keeps its separate account-age row. For other forms the cue replaces both parts of a wrapped form line, so it cannot overlap the original text.

This is offline implementation and fixture evidence, not native input or visual acceptance. The installed build remains `8fd6a8c`. HANDOFF/CHANGELOG consolidation is deferred while open v2 PR #2 owns those files; this document and TESTING are this unit's handoff.

## Shared rules for every form

[drop_tap.lua](../scripts/characters/drop_tap.lua) decides whether a tap happened at all. Native-input interruptions remain silent:

- Holding two or more pocket items (cards, pills, pocket actives). Native cycling owns DROP.
- A hold longer than 12 frames (0.4 s). Native dropping owns the long hold.
- Paused game, disabled controls, a dead player or a co-op ghost.
- A press already held when the room, form, controller or run changed. Release and tap again.

When a form's own condition is false during the press, its action press is still forgotten. A separate gesture observer may explain the refusal on release, but cannot authorize an ability. If eligibility changes while held, the cue says `State changed; tap again`; observe a release and tap again.

## Per-form conditions

A resource/state refusal names the missing resource, running phase, cooldown or combat requirement. A missing target says `No target in range` (or `No unassigned target nearby` for Tainted Kimi), without spending anything. If several conditions fail, the active lock/phase or combat requirement takes precedence where applicable; the table lists the possible conditions, not a new priority rule for abilities.

| Form | DROP does nothing when | Current cue |
|---|---|---|
| Claude-chan | No Appeals left, Usage is 0, or a usage limit is active. | No Appeals left / No Usage to appeal / Usage limit active |
| Tainted Claude-chan | Quota is above 0, no Pages left, or a Review is already running. | Quota remains / No Pages left / Review in progress |
| DeepSeek-chan | No bowls, a meal is already running, or you are moving. | No Rice bowls left / Meal in progress / Stand still to eat |
| Tainted DeepSeek-chan | Within one second of the last Saving/Forks toggle. | Toggle cooling down |
| GPT-chan | Already Verified, this room's Sanity Check is spent, or a check is running; no target within 200. | Already Verified / Check spent this room / Check in progress / no target |
| Tainted GPT-chan | Standard mode with no Credits and no reset claimable in this room. A banked reset is claimed only outside combat; in combat DROP only toggles Full Send. | No Credits left / Claim reset between fights |
| Gemini-chan | No Paint left; no target within 180. | No Paint left / no target |
| Tainted Gemini-chan | This room's edit chain already exported; no target within 180. | Already exported this room, or no target |
| Grok-chan | Not in combat, this room's check is spent, or a check is running; no target within 220. | Needs combat / Check spent this room / Check in progress / no target |
| Tainted Grok-chan | The ten-second cooldown is running; no target within 220. | Quote cooling down / no target |
| Qwen-chan | Never refused: DROP always cycles the next adapter. | Always shows the choice |
| Tainted Qwen-chan | In combat. Outside combat, a pinned build refuses with its clears left. | Change build between fights, or Pinned: clear N new rooms |
| Llama-chan | No Releases left. In combat the Release is kept. | No Releases left, or Release between fights |
| Tainted Llama-chan | No Hype. | No Hype yet |
| Mistral-chan | No charged Pounce: move while firing to charge one. | Charge: move while firing |
| Tainted Mistral-chan | No Baguettes, or the wave cooldown is running. | No Baguettes left / Wave cooling down |
| Doubao-chan | No Apology token. A qualifying enemy hit grants one. | No Apology ready |
| Tainted Doubao-chan | Confident or the following recovery is still running. | Already Confident / Still recovering |
| Kimi-chan | Fewer Slides than the deck cost; no enemy within 220. | Not enough Slides / no target |
| Tainted Kimi-chan | Not in combat, three tasks already assigned, or this room's nine-pulse budget would be exceeded; no unassigned target within 220. | Needs combat / All task slots busy / Room pulse budget spent / no unassigned target |
| GLM-chan | Queue below 3/3, or a pass is already active. | Queue below 3/3 / Access Pass active |
| Tainted GLM-chan | Not in combat, or the three-second cooldown is running; no target within 200. | Needs combat / Request cooling down / no target |

## Implementation and offline evidence

`drop_tap.lua` retains the original action observer and uses a separate transient observer solely for refusal gestures. Both use the same release, duration, identity and pocket-ownership rules. Each form supplies its current reason and reports target misses only after its existing target lookup. The two former global refusal captions (Tainted Qwen's pinned build and Llama's combat release) now use the same player-local cue. Accepted ability captions keep their existing behavior.

- `drop_tap_test.lua`: unchanged action timing, interruptions, wrapper identity and every pocket-slot combination.
- `drop_refusal_test.lua`: separate eligibility observation, same-frame changes, no rearming after interruption, 45-frame expiry, repeated taps, success clearing, lifecycle/identity invalidation and player isolation.
- `full_mod_drop_refusals_test.lua`: actual `main.lua`, 49 refusal situations with four players each; exact English reasons and independent HUD rows; no resource spending, mode change, shared caption or sound on refusal. Includes real ability activation before review/check/task/cooldown refusals, 44 all-form multi-pocket/hold cases, Qwen selection, mixed-family HUD, successful-target restoration, room reset and detached Continue. State setup, native input samples, text rendering and save codec are supplied fixtures.

Six isolated source faults are rejected by the intended assertions: letting feedback authorize actions, removing cue expiry, retaining cues across reset, ignoring multiple pockets, drawing every cue in player 1's row, and suppressing Gemini's target-miss cue. A minimal full-entry control copy passes before mutation. Existing form HUD assertions now check the new cue and restoration while retaining their resource, combat and timing assertions.

## Still needs engine evidence

Check short taps/holds and native pocket cycling on keyboard/controller, especially eligibility changing while held. Inspect the 45-frame flash in combat, a narrow window, large HUD offset, four-player co-op and Jacob/Esau. Verify disappearance after success, pause, room change, death/revival and real Continue. The cue uses at most 40 characters in fixtures (x=50 plus the conservative 6 px estimate fits a 360-wide window); actual glyph widths, corners, other mods and native event timing remain unverified. See [HUD_TEXT_AUDIT.md](HUD_TEXT_AUDIT.md) and manual checklist item 3. No new game test or installation was performed.
