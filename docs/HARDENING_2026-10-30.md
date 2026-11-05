# Scheduled integration review and meal cancellation

Reviewed v2 main `6af1bc7` after five substantive units. All evidence here is offline. The owner-untried installed `8fd6a8c` remains untouched.

## Recent units

| Unit | Review and remaining limit |
|---|---|
| v2 #5: seeded backlog mixtures | Real backlog callbacks, but no family abilities. Random registry IDs alone do not load individual item implementations or certify character billing. |
| v2 #6: Jacob and Esau | Focused Constitution ownership coverage; it does not establish all shared-body character economies. |
| v2 #8: Agentic/fixed look | Distinct-item/cache/costume service checks across 22 supplied form IDs; family abilities and native rendering remain outside that fixture. |
| v2 #9: Greed clear-state guard | Refuses uncleared Greed-mode rooms before state or door mutation. Actual between-wave clear timing still needs native evidence. |
| v2 #10: optional EID isolation | Protects external method lookup/calls and permits later main registrations. It does not isolate arbitrary gameplay-module failures or undo an external method's partial side effects. |

## F16: cancelled lunch produced a reward

MealBreak's update runs before the backlog update in `main.lua`. It clears a dead player's meal countdown. Rice Cooker then saw zero remaining time, cleared its pending flag and primed a 2x attack even though the meal was unfinished. Its isolated backlog fixture supplied a simple expiry timer, so it did not exercise the shared service's death cancellation.

`tests/deepseek_meal_composition_test.lua` reproduces this on baseline `6af1bc7`. The correction retains cleanup but requires the owner to be alive before granting a new prime. This implements the existing completed-meal condition; no charge is refunded, and no multiplier, duration, pool, quality or save version changes. An already earned prime remains intact and is not refreshed by cancelling a later meal. EID and the generated item reference explain cancellation.

## New composition fixture

The fixture loads the real MealBreak service, shared backlog and all twelve family/shared backlog modules, then DeepSeek base stats, normal Rice First/Thought and tainted Peak/Valley in their relative main registration order. Each of twelve fixed seeds has two normal DeepSeek owners, one tainted DeepSeek and one vanilla control. It samples inventories from the current 80-ID registry, but non-backlog individual item modules and the other ten families' abilities are not loaded. Risk is a supplied state container, not the real save service.

The supplied sequences check:

- Independent character and active-item meals; busy-use and Car Battery refusals; blocked directional shooting hooks while movement and other owners remain available.
- Duplicate-frame countdown stability; moving cancels only the character-owned meal and refunds its bowl once, leaving the other owner's item meal running.
- Active rewards survive item removal, while cache values remain finite and later return to form baselines. Completing a character meal does not manufacture a Rice Cooker item reward.
- Ordinary normal-form tears consume Thought once and share its resolved factor across a same-frame volley.
- Tainted knife updates share one phase-priced Compute payment across two same-frame knives and repeated callbacks. Both Valley and Peak are reached through the real schedule, not by assigning their saved phase directly.
- The item's 2x lease and the character's 1.3x boost produce one final supplied health hit per attempt through the real nested damage callbacks. Hits do not rebill; a later throw pays again without reusing the consumed item prime.
- Room cleanup and expired speed bonuses, death-cancelled pending rewards, supplied revival, and preservation of a reward earned before a later cancelled meal.

The extended warm-up exposed another removal candidate: Rate-Limit Valve can retain an unspent 1.3x prime after losing the passive. The fixture consumes warm-up primes through real attacks before isolating Rice Cooker; it does not accept that passive's removal policy. Track the separate candidate in INTERACTIONS and distinguish an unspent prime from a projectile whose bonus already resolved. Do not misclassify its additional factor as duplicate character billing.

Run `texlua tests/deepseek_meal_composition_test.lua .`; an optional second argument substitutes only the DeepSeek backlog module for a baseline comparison. The exact baseline copy fails at the unfinished-meal reward assertion, while the corrected module passes all twelve scenarios. Run the full `bash tools/check.sh`, item-reference/scanner freshness and `git diff --check` before committing.

The focused fixture, full offline gate, generated item reference, interaction inventory and whitespace checks passed on 2026-10-30 with Git Bash, Python and `texlua`. The source fix adds only the living-owner guard at reward time; all character and shared meal/attack implementations remain unchanged.

## Acceptance and next work

The test supplies Isaac event ordering, input polls, damage cancellation, flight flags and dead/alive states. It does not execute real weapons, physical inputs, native revival, JSON serialization, Continue, physics or rendering. Native resurrection may rebuild cooldowns and entities differently. No child-laser/Parent billing policy is changed; E2 still gates that work. The remaining twenty forms, other weapons/items, special-player identities, O6 saves and whole-mod performance remain open.

This unit avoids every file in open PR #2. HANDOFF/CHANGELOG consolidation remains deferred until that restriction clears; PR #2 still awaits owner testing/path-rule resolution and U0 remains draft #7. Continue with the passive removal candidate and actual family/item combinations. Repeat the scheduled review after another three to five substantive units or a concrete failure.
