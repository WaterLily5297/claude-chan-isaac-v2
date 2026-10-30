# Full-entry primary weapon composition

2026-10-30, based on v2 main `bf08cb5`. This unit fixes a reproduced primary held-beam effect-sharing defect and adds supplied-event integration coverage. It does not accept native weapon behavior or change child-laser classification or payment policy. Installed `8fd6a8c` remains untouched.

## Reproduced defect and correction

Tainted DeepSeek pays once per owner for each further six-frame held-beam window. The shared observer previously notified its subscriber only for the first beam observed in that window. Peak refreshed that beam's 1.3x damage lease, but another primary beam belonging to the same player retained its old lease. With two sustained primaries, the later beam could lose an already-paid bonus; at an inclusive expiry boundary it could also retain the preceding paid bonus during a new unaffordable window.

The observer now retains the subscriber's decision with its existing owner/window record and offers an optional primary-laser sharing hook. Peak copies the paid or unpaid expiry into each eligible primary beam's own lease. Sharing does not call the payment function again, move the original deadline, or reuse a decision from another live binding or room epoch. Other subscribers keep their payment behavior. Single-hit beams, released rings, known child beams and other excluded sources do not enter this sharing hook. Existing child classification/inheritance remains unchanged and requires native E2 evidence for further policy changes.

Reproduce against the old implementation by running the new full-weapon suite with the two production modules from `bf08cb5`: `103/beam/3` resolves a supplied hit at `5.04` instead of the paid `6.552`. The corrected modules pass. Four additional syntax-valid isolated faults are rejected: retaining a paid expiry after an unpaid decision, renewing a late sibling's deadline, sharing windows across owners, and applying an old decision to a replacement binding. These private fault copies are validation inputs, not additional production defects.

## Supplied-event matrices

`tests/lib/full_mod_env.lua` loads actual `main.lua` and production modules. Its new `weapon` constructor supplies typed laser, knife, bomb, rocket and target-marker sources. Construction does not dispatch callbacks. Tests explicitly choose init/update order, entity age, knife flight, circle/one-hit flags, Fetus status and collision amounts. Rocket sources have no collision-damage field; the explosion amount comes from the supplied hit. These contracts are not an Isaac emulator.

| Suite | Cases and assertions |
|---|---|
| [Full weapon matrix](../tests/full_mod_weapon_composition_test.lua) | 22 duplicate-form pairs times eight source categories: single-hit laser, released ring, held beam, knife throw, swing hitbox, Dr. Fetus bomb, target-marker Epic Fetus rocket and Ludovico tear. Each case supplies ten volleys/windows with two primaries per owner, duplicate updates and collisions. Exact Opus source/window bills, per-form Usage/Quota/Compute/Credits, finite native damage, scale/velocity preservation, 1.3x affordable non-tear Peak hits, removal and input-lock cleanup are asserted. Full Send is activated through actual DROP polling. |
| Earned Thought composition, in the same suite | Eight two-owner cases earn full Thought through actual Rice meals. Six supported common-attack categories also complete Rice Cooker and compose its on-hit 2x lease with Thought. Checks include one resolved hit, owner isolation, discrete flight snapshots, six-update continuous expiry, Context's Ludovico exclusion and knife-return restoration. Rocket and swing cases cover Thought and resource observers, not common-prime support. |
| [Primary beam windows](../tests/full_mod_peak_windows_test.lua) | Four simultaneous tainted DeepSeek owners, two primaries each, alternating update order, duplicate observations, exact window bills and exhaustion. Additional controls cover a late sibling's fixed deadline, idle partners, pause, changed InitSeed/live binding, room reset and detached save composition. |

The matrix preserves a current source distinction: Peak forks a Ludovico tear at fire and skips tears in its additional-window boost observer. Opus and the allowance forms continue their existing held-window billing. This test records that distinction; it does not approve a new ongoing-fork rule. Initial form phases are tested except for the explicitly activated Full Send and earned Rice abilities. The matrix does not activate every character loop or every item.

## Validation and boundaries

Run:

```sh
texlua tests/full_mod_weapon_composition_test.lua .
texlua tests/full_mod_peak_windows_test.lua .
bash tools/check.sh
```

The full gate discovers both new suites automatically. Existing paid-observer, Peak, child-laser, cache, save and ordinary-primary regressions remain required. `tools/audit_interactions.py --write` refreshes the changed production-source inventory.

Remaining requirements include native multi-beam callbacks and collision timing, actual ancestry, engine RNG/physics/rendering, all active phases and Birthright timings, special subplayers, all item combinations, real Continue and full gameplay runs. The fixture's damage cancellation and nested hit dispatch are supplied contracts. None of these offline results closes native E2, character completion or release acceptance.

This focused record plus TESTING, CHARACTER_COMPLETION and INTERACTIONS is the unit handoff. Consolidating HANDOFF/CHANGELOG remains deferred while their files overlap open v2 PR #2. PR #2's owner test/path-convention gate, draft #7 and RC1 remain separate pending work.
