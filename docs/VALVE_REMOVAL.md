# Rate-Limit Valve inventory loss

U3/F17, 2026-10-30, based on v2 main `359665e`. This resolves the separate passive-removal candidate found during the [scheduled integration review](HARDENING_2026-10-30.md). Source and offline evidence only; installed `8fd6a8c` is preserved.

## Problem and rule

After earning Rate-Limit Valve's 1.3x prime, removing the passive left that unused bonus in the common transient table. A later attack still dealt 4.55 from a supplied base of 3.5. This occurred both after an update and when removal was followed immediately by firing.

Under the owner's U3 inventory-cleanup requirement and delegated minor-rule decisions, this passive now requires at least one copy until the attack resolves. Losing the last copy removes its unused benefit. An attack whose factor already resolved retains it, including the other tears in its existing same-frame volley. Completed active-item rewards remain separate and do not acquire this ownership requirement. The multiplier and two-second attack-based idle threshold are unchanged.

## Implementation

The shared prime API accepts an optional collectible requirement. Availability and attack consumption check it against the current owner inventory. Rate-Limit Valve supplies its own item ID; all other prime producers retain their existing behavior. Its update also removes an unspent record after observing the item is absent, so a passive lost without an immediate attack does not leave stale prime state.

The resolved volley and weapon leases still contain their original multiplier. They do not depend on current inventory after resolution. No native weapon/entity field, callback registration order, saved-state version, item pool or quality changes. The extra collectible ID is transient prime metadata, not serialized state.

## Evidence

`texlua tests/valve_inventory_test.lua .` runs six real-backlog scenarios:

1. An update after item loss removes the pending record and bonus; another holder keeps its own benefit.
2. Removal followed by firing with no update or availability query still rejects the stale bonus at consumption.
3. Removing one of two copies keeps the single benefit; removing the last copy cancels the next unused prime.
4. Already resolved attacks and a same-frame sibling keep their factor after removal; a later volley receives no new bonus.
5. A completed Rice Cooker reward still gives 2x when the passive is lost, instead of losing the active reward or incorrectly retaining the extra 1.3x factor. The meal countdown is a supplied stand-in in this fixture.
6. Reacquisition neither bypasses nor resets the existing time since the last common attack; the item works again at that threshold.

The `update` and `immediate` selectors each fail on baseline `359665e`. With the fix, all six scenarios and the existing real DeepSeek/meal composition and backlog suites pass. Run the full `bash tools/check.sh`, generated item-reference/source-inventory checks and `git diff --check` before committing.

The full offline gate, new six-scenario fixture, existing composition suites, generated references and whitespace checks passed on 2026-10-30 with Git Bash, Python and `texlua`.

These tests supply inventory changes, event order and final damage application. They do not execute D4/D100, Clicker, Genesis, native weapon timing, physical input or real Continue. A drop and reacquisition with no intervening observable callback cannot be reconstructed from an inventory snapshot. Existing attack attribution and E2 restrictions are unchanged.

## Handoff

EID, the generated reference, expansion rule, F17 ledger, TESTING and INTERACTIONS now state the source behavior and remaining native work. The dated hardening review keeps its original discovery context. This unit does not touch PR #2's files; consolidated HANDOFF/CHANGELOG updates remain deferred under that restriction. PR #2's owner testing/path-rule question and draft U0 PR #7 remain open.

Continue actual family/item composition and U4's O6 save, performance and isolation work. This resolves one inventory-loss defect, not all remaining item-removal cases or the full 22-form matrix. No game, installation, setting, save, art or Workshop publication was changed.
