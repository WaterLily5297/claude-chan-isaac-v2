# Full entry-point save composition review

## Scope and result

Scheduled integration review after v2 [#12](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/12), [#13](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/13) and [#14](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/14), based on main `6e7db51`. The previous review is [the DeepSeek/meal composition record](HARDENING_2026-10-30.md). These records retain separate evidence scopes.

No new production defect was reproduced in this unit. The new `tests/full_mod_save_composition_test.lua` loads actual `main.lua`, all production modules and their registered callbacks. It extends the full-entry fixture with detached save snapshots, inventory restoration and recreated player identities. Production behavior, save schemas, balance, art and callback registration are unchanged.

## Supplied cases

| Cases | Setup and assertions |
|---|---|
| 22 form/item pairs | Each actual normal/tainted form plus a vanilla partner uses Temperature Dial, Another Adapter, Rice Cooker and Unchanged Preview. Distinct Adapter counters, temperature choices and staggered 72/79-frame meals survive exit and Continue into new pointer/seed identities. The populated form state also matches immediately after load. Shooting locks restore before the first update; each meal awards its own prime at the correct boundary, clears its pending flag and does not refresh an already earned prime. |
| Four-owner rotation | Two normal DeepSeek character meals and two vanilla Rice Cooker meals rotate through four slots. An update observes the move before exit. Rice, shared meals, backlog and meme state keep the correct owners across the rotation and recreated Continue identities. Movement cancels/refunds only the chosen character meal; the other completes. Character meals never produce Cooker primes, while both item meals do. |
| Actual Kimi task | Tainted Kimi schedules a task through a supplied DROP tap before exit. Its three spent pulses remain spent; the explicitly transient target task does not return. A new post-Continue task increases spent budget to six and delivers exactly three pulses. |
| Same-session restart | Existing modules receive exit, initial room and continued-start callbacks. Character/item meals restore and complete. A subsequent fresh-start callback clears old meal debt, earned primes and item choices, and resets Rice resources. |
| Runtime-object control | Deliberately placing a live player stand-in in saved state is rejected by the fixture codec instead of being silently copied as a persistent object. |

All cases use the real Risk save/load hooks and module registration order. Exit writes the snapshot before later module cleanup callbacks. The first 22 cases verify Preview markers are removed on exit and are not recreated on Continue; Adapter's saved next choice persists while its explicitly room-local active bonus is discarded. Loading and updating never mutate the detached source snapshot.

The 22 cases exercise real form initialization, cache/update/render/save callbacks alongside those four item mechanisms. They do not exercise every form's active loop. Rice and Kimi have the additional explicit ability cases above; holding or loading the other modules does not accept their mechanics.

## Verification

```sh
texlua tests/full_mod_save_composition_test.lua .
texlua tests/full_mod_update_budget_test.lua .
bash tools/check.sh
```

Both focused suites and the full gate passed, including 84 Lua suites, syntax checks on 204 Lua files and the existing Python/asset/inventory checks. The gate discovers the new `*_test.lua` automatically; its script does not need modification. Five syntax-valid, isolated source faults were also rejected by the new suite:

| Deliberate fault | Failing assertion |
|---|---|
| Risk load omits the backlog root | Restored backlog type/state differs. |
| MealBreak resets saved debt on Continue | Expected meal countdown is missing. |
| Rice Cooker fails to restore its pending reward | No prime at the first completion boundary. |
| Kimi resets spent budgets on Continue | The saved room budget is lost. |
| Preview omits run-exit cleanup | Live markers remain after exit. |

These fault copies are validation controls, not production changes or newly discovered bugs. Historical tests are not weakened or replaced.

## Remaining limits and next work

- This is offline evidence under supplied events. The codec copies finite scalar values and plain tables, rejects cycles/metatables/functions and separates snapshots from live state. It does not serialize native JSON, reproduce numeric-key conversion, validate corrupted disk files or emulate engine entities.
- Continue explicitly supplies the initial-room-before-game-start sequence. Fresh starts supply game-start then new-room. No player-init callback is supplied, so starting pockets/menu selection are outside the fixture. Those orders and the frame clock are inputs, not observations of Repentance or Repentance+.
- The rotation case observes a live slot change before saving. A slot change immediately followed by a save, native save timing, same-frame floor checkpoints, special subplayers, native inventory restoration and inter-mod callback order remain open.
- The generic form-state comparisons are not all-form resource consumption, weapon, migration or Continue acceptance. Form-specific transient policies remain intact; this unit does not resolve the broader Continue design question. The existing [O6 Rice/Meal fixture](O6_RICE_MEAL_IDENTITY.md) retains its separate migration/knife controls and native limits.
- No item consumption, charge bookkeeping, physics, animation, hardware input, native firing lock or long-run performance is accepted from these tests. E2 still gates child-laser/Parent billing changes.
- Open PR #2's files are untouched. HANDOFF/CHANGELOG consolidation remains deferred to avoid overlap; this record and TESTING.md are the unit handoff. Draft #7 and RC1 retain their existing gates.

Continue U3/U4/U5 with the remaining actual weapon/character combinations and save-boundary coverage. Do not mark those units complete from this review. The installed `8fd6a8c` manual-test checkpoint remains unchanged and owner-untried; no game, runtime, saves, settings or Workshop action occurred.
