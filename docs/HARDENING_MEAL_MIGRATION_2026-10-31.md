# Scheduled review: preserve meals while discarding stale delay metadata

Reviewed v2 main `2a79ebb04a927e7e01ed03bf13a3fafa04e8cb07` after three substantive units since [save-scalar hardening](HARDENING_SAVE_SCALARS_2026-10-31.md).

| Recent unit | Reviewed evidence and remaining boundary |
|---|---|
| [#28](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/28), GPT/Gemini profiles | Published-source packing still reproduces the current cells. Their side-only carry repair does not accept front/back carry or native motion. |
| [#29](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/29), GLM carry fit | The source/geometry guards still pass; the fallen pose and all Hit cells are unchanged. Native interpolation and held items remain unobserved. |
| [#30](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/30), Grok/Qwen profiles and carry | Packing, all-22 geometry and unchanged-Hit checks pass. Current source art is unchanged by this unit. The nine approved tainted illustration sources and comparison retain their registry hashes; those approvals are not complete runtime integration. |

## Reproduced finding F23

MealBreak's version-1 migration discarded unknown ownership but retained `priorDelay`. Version-2 unowned timers also accepted that irrelevant field. The update callback later subtracted one from any truthy `priorDelay`, even when the timer did not own a native fire-delay lease. A successfully decoded string, table or boolean in that field therefore interrupted the update with an arithmetic error.

An actual-main probe reproduces all three bad types for both versions on the baseline. The new migration and Rice Cooker selectors also fail against baseline source at their first affected update. This is a synthetic damaged/extra-field scenario, not an owner corruption report or a native JSON/disk test. Valid numerical stale metadata did not throw, but had no ownership contract.

## Narrow correction

After the existing validation and version-1 migration, an unowned timer drops `priorDelay`. Its valid remaining countdown and version-2 serial are preserved; version 1 still migrates to version 2 with serial zero and no Rice owner. The timer remains locked until its existing debt expires. Other owners, pending Rice Cooker rewards and unrelated saved modules are not reset.

Valid owned Rice timers keep their saved previous delay and the existing cancellation/foreign-cooldown rules. Invalid owned records still follow the existing rejection policy. No duration, reward, damage, input rule, save version or DeepSeek Risk/IP behavior changes. This does not catch arbitrary callback errors or suppress a failed save synchronizer.

## Offline regression evidence

[full_mod_meal_migration_test.lua](../tests/full_mod_meal_migration_test.lua) loads actual main.lua and production modules with explicit engine stand-ins and the detached table codec:

- Sixteen legacy/unowned cases cover text, table, booleans, finite/negative/large numbers and missing delay metadata. They retain debt while paused, advance normally afterward, survive another detached save/Continue, preserve serials and unrelated state, and unlock two owners independently. Legacy extra ownership cannot create a cancellable Rice lease.
- Twenty-two forms each resume two actual Rice Cooker uses with different remaining times and corrupted unowned delay metadata. Neither reward arrives early; each owner unlocks independently and receives its completion prime once. A later re-save contains neither stale delay metadata nor a completed reward marker.
- Valid owned timers preserve and decrement their prior delays. Cancellation restores only the owned cooldown and preserves a later foreign cooldown. Four malformed owned-delay controls retain the existing rejection behavior. This selector passes both before and after the correction.

An isolated unchanged-source control passes. Five local source faults fail the intended behavior checks: omitting cleanup, discarding meal debt, erasing valid owned delay, cleaning only migrated legacy timers, and resetting valid serials. The serial fault is caught first on the unaffected co-op owner's serial. These mutation copies and their logs remain private; the regression suite itself is automatically discovered by the standard gate.

Existing O6 Rice/Meal's eight supplied save/identity cases, the 45-field/core-save and 22-form Continue suite, and full-entry save composition still pass. The interaction inventory is refreshed. Run:

```sh
texlua tests/full_mod_meal_migration_test.lua .
texlua tests/deepseek_o6_save_test.lua .
texlua tests/full_mod_save_scalars_test.lua .
texlua tests/full_mod_save_composition_test.lua .
bash tools/check.sh
```

## Handoff

This document, TESTING, ITEM_COMPLETION F23 and CHARACTER_COMPLETION provide the update while open PR #2 protects consolidated HANDOFF/CHANGELOG edits. PR #2 and draft #7 remain untouched. U0 integration, RC1 and approved-tainted production retain their dependencies.

Installed `8fd6a8c` is preserved. No game, installation, owner save/settings or Workshop action occurred. Native input, fire-delay ownership, JSON/disk recovery, special-body identity and real Continue remain open. Broader nested-save validation, callback/error isolation, combat/performance, remaining art and U0-U7 acceptance are unfinished. Repeat the scheduled review after another three to five substantive units or a concrete failure.
