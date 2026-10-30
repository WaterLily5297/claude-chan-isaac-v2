# Full entry-point target ability composition review

## Scope and reproduced finding

Scheduled integration review after v2 PRs [#16](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/16), [#17](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/17) and [#18](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/18), based on main `6044725`. The previous review is [full-entry save composition](HARDENING_SAVE_COMPOSITION_2026-10-30.md). This review exercises selected active character loops through actual `main.lua`, rather than accepting them merely because their modules loaded.

**F19:** backlog's global damage-replacement guard skipped independent damage generated while a modified hit was being dispatched. In the reproduced case, tainted Gemini's third angled attack triggered Export inside an Is This True? challenge-modified hit. Export's independent player source should receive the challenge's 1.35x modifier, but the shared guard bypassed it. The old production module produces `11.34` rather than `15.309` in the new suite. The triggering weapon's own hit still had its modifier, making this a composition defect rather than a missing item registration.

The guard now identifies the replacement's source and target. Only that pair bypasses another application of common modifiers. Independent damage with another source or target is evaluated normally. Nested calls restore the previous guard, including when a downstream damage call throws; the exception is rethrown, not hidden. Explicit common-service pulses retain their existing modifier exemption. No balance values, character rules, weapon attribution, billing policy or save schema change.

## Actual-main coverage

The new [target composition suite](../tests/full_mod_target_composition_test.lua) supplies tear, single-hit laser, flying knife, Dr. Fetus bomb and Ludovico sources to each of five duplicate-form pairs: **25 two-owner cases**. It drives real DROP polling, item use, fire/update/hit callbacks, cache evaluation and selected room transitions.

| Pair | Active-loop and item assertions |
|---|---|
| Tainted Gemini | Actual three-angle Export chain with Is This True?, Opus and a completed Rice Cooker reward. Exact source and pulse damage; duplicate collisions do not advance; Export neither inherits the triggering shot's Cooker lease nor bills Opus. Partner chain has its own completion and modifiers; a new room permits a new chain. |
| Normal Gemini | Paint is spent only by its owner. Wet hits have no character multiplier; dry hits compose 1.2x with the item challenge and Cooker lease. Birthright acquisition/loss changes the pending mark's live hit multiplier to 1.3x/back. Partner hits borrow none of these modifiers; room exit removes targets without refunding Paint. |
| Normal Grok | Character check and item challenge preserve their separate on/off-target multipliers. Three distinct attacks verify exactly once despite duplicate/nested callbacks. Community Note exposes after its own three attacks; subsequent hits retain the item bonus after the character check ends. Speed and room budgets remain owner-specific and expire on a new room. |
| Tainted Grok | Same-attack favorable target choices win; a distinct own reply subtracts one Ratio. Duplicate hits do not add stacks. Two and three independently earned stacks land at their respective owners' deadlines; player-sourced pulses receive only that owner's active item challenge and do not bill weapon starts. |
| Tainted Kimi | Task assignment spends three pulses. Owner weapon hits pause the assigned task for 30 frames; a partner hit on that target does not pause the owner's task or the partner's different assignment. Exact first-pulse boundary, live Birthright gain/loss on later pulses, item challenge, three-pulse cap and separate Opus/task budgets are checked. |

Additional actual GLM Retry composition kills the first pending target to earn one stack, waits through cooldown, then schedules both owners' requests. The later 3x/2x player pulses compose with the appropriate challenge and consume only the successful owner's stack; they never bill Opus.

Two explicit controls extend the damage-dispatch boundary:

- A supplied later callback sends an independent same-source hit to another target, then an echo of the already-modified original pair. The other target receives its own 0.85x modifier, the outer guard is restored, and the original pair is not amplified twice. This models an external callback; it is not evidence from another installed mod. An explicit common pulse still bypasses common modifiers.
- A supplied downstream exception must propagate. A later hit from the same source to the same target still receives its item modifier, proving the exception did not leave a stale suppression guard.

## Fixture correction and fault controls

The full-entry fixture formerly changed `SafeGridIndex` but always supplied `SpawnSeed=13`. Many character room keys use SpawnSeed, so that input could not represent a genuinely new room for them. It now supplies `SpawnSeed=roomIndex+3`, preserving the original initial-room value and giving stable revisit identities. This is a fixture correction, not a production engine-path fix or a claim about the engine's seed formula.

The old production common module fails the new Export assertion. Five additional syntax-valid production faults fail: ignoring target identity, ignoring source identity, discarding the outer guard, throwing before restoring it, and removing the common-pulse exemption. A sixth control reinstates the constant fixture room seed and fails the new-room chain assertion. Fault copies stay private; they are not additional shipped defects.

Run:

```sh
texlua tests/full_mod_target_composition_test.lua .
bash tools/check.sh
```

The full gate discovers the suite automatically. Existing item/backlog, child-laser, save, cache and weapon regressions remain required; the interaction inventory is refreshed after the production edit.

## Remaining boundaries and handoff

These are supplied-event offline results. They do not establish native collision/cancellation order, source identity reuse, physics, rendering, charge discharge, actual Continue, all external callbacks or every form/weapon/Birthright combination. An independent event reusing the exact same source/target pair inside a replacement remains indistinguishable from its echo; the correction does not claim a general event-identity protocol. Downstream exceptions remain failures and can interrupt their caller; restoring this local guard is not global error isolation.

Pending native E2, F10/F12, special-player, active-loop, art and full-run requirements stay open. No child-laser/Parent/derived-shot payment rule is expanded. No game, runtime installation, saves, settings or Workshop action occurred; installed `8fd6a8c` remains owner-untried and unchanged.

This record, TESTING, ITEM_COMPLETION F19, CHARACTER_COMPLETION and INTERACTIONS are the unit handoff. HANDOFF/CHANGELOG consolidation stays deferred because of open PR #2's overlapping files. PR #2's native icon/dossier/path-convention gate, draft #7 and RC1 remain unresolved. Continue the remaining U3/U4/U5 cases; schedule another short hardening review after three to five substantive units or a concrete failure.
