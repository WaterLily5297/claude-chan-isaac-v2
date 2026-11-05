# Agentic and fixed-look composition

Offline U3/G7 fixture, 2026-10-30, based on v2 main `9888186`. Production behavior is unchanged. This extends the flight-cache interaction review with actual shared-module composition rather than treating overlapping field names as a defect.

## Modules and inputs

`tests/agentic_costume_composition_test.lua` loads the real backlog service and its twelve family/shared modules, then the real Agentic transformation and fixed-look service. Cache callbacks follow their registration order in `main.lua`; update phases are explicitly supplied by the fixture and are not observed native scheduling.

There are 264 cases: all 22 normal/tainted type IDs, twelve deterministic seeds each, with four player slots. Two slots use different registered mod forms and two are vanilla type controls. Every player receives a seeded selection from the 74 collectible IDs outside the six-item Agentic set; the six set IDs are varied separately to exercise the threshold. Registration alone does not load an item's implementation: non-backlog individual item callbacks and family-specific character ability callbacks are not loaded here.

The engine stub supplies native flight, positive/negative firing delay, player scale, cache rebuilding and costume-call counters. It does not derive those values from actual vanilla collectibles. Edge Compass's five-frame position observer is allowed to settle before inventory comparisons; its normal delayed shot-speed bonus must not be misreported as a transformation defect.

## Assertions

- Three copies of one set item plus one other distinct item do not activate Agentic. A third distinct item activates it for both a mod form and a vanilla control, with flight, +0.5 damage after backlog modifiers and the existing interval multiplier.
- Repeated cache rebuilds do not compound stats. Supplied negative firing delays remain finite. Other players below the threshold retain their own stats and native flight.
- Both registered forms clear costumes; vanilla controls never do. Supplied size remains unchanged throughout the callbacks.
- Leaving a mod form restores held collectible and acquired native-form costume calls once, without replaying mechanical bonuses. Returning resumes the fixed look while keeping the active transformation.
- Removing the third distinct item restores the prior cached values and independent native flight. Removing the remaining inventory and changing rooms restores baseline stats and empties room-scoped backlog data.
- Only newly activated transformations receive their gain cue; removal and type changes do not replay it.

Three private source mutations were rejected at the intended assertions: losing the flight grant, counting copies as distinct set items, and clearing vanilla costumes. These faults were injected outside the repository; production files were not edited.

## Reproduction and limits

Run `texlua tests/agentic_costume_composition_test.lua .`, `bash tools/check.sh` and `git diff --check`. The existing gate discovers the new `*_test.lua` automatically; no gate modification is needed. The focused 264-case fixture, full gate and whitespace check passed on 2026-10-30 using the existing Git Bash, Python and `texlua`.

This is not a 22-form gameplay acceptance matrix. Character resource billing, shooting locks, actual weapons, native stat initialization, costume rendering, collision over pits, save/Continue and other mods remain unverified. Generic type changes are not executions of Clicker, revival or native transformations. No new rule, art, installation, save or game session was changed; installed `8fd6a8c` remains the manual-test checkpoint.

## Resume

The shared-flight candidate now has bounded composition evidence. Continue U3 with real family-ability/item combinations and billing/lock assertions, then the remaining save/performance work. Preserve the older roster-seeded and Greed draft branches; this focused main-based branch does not depend on either.

HANDOFF and CHANGELOG updates remain deferred because those files belong to open v2 PR #2 and the owner's plan prohibits modifying its files before resolution. The current evidence is linked from TESTING, the interaction review and G7; reconcile the consolidated handoff after that restriction clears. PR #2 visual acceptance and the resource-path rule review remain open.
