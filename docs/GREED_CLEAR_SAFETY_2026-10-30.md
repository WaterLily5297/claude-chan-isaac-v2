# All Tests Passing: Greed clear-state guard

## Scope and status

U3 compatibility work, based on v2 main `9888186`. This unit carries forward the gameplay guard from the preserved local `codex/greed-mode-clear-safety` draft and strengthens its regression coverage. It is independent of the resource-path audit and does not change PR #2's files.

Source correction only; native acceptance is pending. The installed `8fd6a8c` checkpoint is preserved. No game, runtime files, settings or saves were accessed.

## Problem and behavior

All Tests Passing already refuses uncleared boss, Boss Rush and challenge rooms. On the baseline, an uncleared ordinary room still receives `SetClear(true)` when the supplied game mode is Greed. Native wave progression must own this clear state; the item should not bypass that responsibility.

The guard now also refuses any uncleared room while `Game:IsGreedMode()` is true. It returns `Discharge = false`, `Remove = false` and `ShowAnim = false`, with the existing required-review caption, before changing the room or its doors. Cleared rooms retain the existing use behavior and special exits remain protected. No item cost, quality, pool or save format changes.

The [community API reference](https://wofsauge.github.io/IsaacDocs/rep/Game.html#isgreedmode) documents that `IsGreedMode()` covers both Greed and Greedier. The fixture supplies that boolean for both labels; this is not evidence from two native modes. This rule conservatively covers all uncleared rooms in those modes, not only a guessed arena room type.

## Verification

- The expanded `tests/door_safety_test.lua` fails on baseline main `9888186` at the Greed charge-retention assertion, then passes with the guard.
- It checks ordinary and boss room types, repeated refusals, all three returned use flags, no clear-state setter call, unchanged doors, the refusal caption, cleared-room use with special exits protected, and return to an ordinary run without a stale refusal.
- Existing ordinary-room, required-room and pickup/exit safety assertions remain active.
- On 2026-10-30, `texlua tests/door_safety_test.lua .`, the full `bash tools/check.sh` gate and `git diff --check` passed. The gate used the existing Git Bash and `texlua`; it includes the door-safety fixture, item-reference freshness and generated interaction inventory. These results are offline only.

## Remaining native checks

Use All Tests Passing during waves, between waves and after clearing the arena in Greed and Greedier, in both Repentance and Repentance+. Observe actual charge retention, normal wave/reward progression and door behavior. The offline fixture does not establish when the engine reports `IsClear()` between waves, so it cannot prove that every native wave interval is protected. Also confirm ordinary-run behavior and native handling of the returned use flags.

## Handoff and publication

`docs/TESTING.md`, the item ledger, EID and generated item reference describe the source change and its limits. `docs/HANDOFF.md` and `CHANGELOG.md` are deferred because they belong to open v2 PR #2 and the owner's plan prohibits changing its files before resolution. Integrate this unit into those records after that restriction clears. The existing gate already runs `door_safety_test.lua`, so no gate edit is required.

Preserve the earlier draft branch as history; do not publish both versions of the same fix. Publish this focused main-based branch only after its checks pass, and verify remote contents and CI before any authorized merge. No Workshop publication is authorized.
