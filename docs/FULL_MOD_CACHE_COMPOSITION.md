# Full entry-point cache composition

## Scope and result

U3/W4.4 follow-up from v2 main `0729770`. The earlier [seeded backlog fixture](../tests/backlog_seeded_compatibility_test.lua) loaded only backlog modules; the [Agentic/fixed-look matrix](AGENTIC_COSTUME_COMPOSITION.md) supplied form IDs without loading their actual abilities. The new `tests/full_mod_cache_composition_test.lua` loads actual `main.lua` and all production modules, including character callbacks, individual items, backlog and Agentic.

No production defect was reproduced by these cases. The change adds regression coverage and extends the fixture's explicit native-cache inputs. Gameplay values, callback priorities, art, save schemas and installed files are unchanged.

## Verified combinations

### Ordered arithmetic and two-owner isolation

Forty-six cases cover vanilla plus all 22 initial forms, each with zero or forty coins. One owner holds Constitution, Opus Mode, two Tungsten Cubes and two Tiny Variants; the partner has different supplied base stats and no items. The expected damage is calculated independently from the documented item effects in entry-point order:

```text
((native_damage * 0.9 * opus_multiplier) + 2 * 0.8) * 0.9^2 * initial_form_multiplier
```

`opus_multiplier` is 0.6 with zero coins and 1.8 otherwise. The fixture uses native damage 8, then flips the wallet and evaluates again before a wallet-notification update. Initial form multipliers are explicit expectations; later active phases are not silently treated as the initial phase. No random Relay or Silent Update multiplier participates in this exact arithmetic control.

The supplied speed 0.35 is reduced by Constitution and the Cubes, reaches Cube's 0.1 floor, then receives Tiny Variant's +0.3 and the initial form's speed modifier. Re-evaluation must be stable; the partner's stats remain unchanged. Native flight and homing survive, with knockback added.

### Native-input and removal control

A separate vanilla pair supplies distinct native damage, speed, range, shot speed, firing interval, flight, flags and all seven colour channels. Three Cubes, two Golden Gates, Em Dash, two Pizza Glues and 1M Context compose on one owner. Assertions cover damage/range/shot-speed arithmetic, preservation of a native speed below Cube's floor, a supplied negative firing delay, additive colour channels, combined homing/knockback/spectral/piercing, flight and partner isolation. Removing the inventory and reevaluating restores the supplied baseline.

### Full and sampled inventories

Each of 22 forms runs eight deterministic two-owner cases, paired with vanilla:

- One case per form holds all 80 registered collectible IDs, with one to three copies of each on both owners: 22 complete inventories.
- Seven further cases per form sample independent inventories from the sorted registry: 154 sampled inventories.
- Every case checks finite/repeatable caches immediately after adding items and after three supplied update steps, replaces both inventories with another sample, then removes all items. After updates and a cache evaluation, stats, flags, colour and native flight must match each owner's original form baseline.
- The suite asserts the registry has 80 IDs and that every ID occurred. These are held-inventory cache/update cases, not activation of all 80 mechanisms.

## Fixture correction and evidence limits

The full-entry fixture previously omitted `CACHE_TEARFLAG`, so its update/save tests did not execute those cache branches. It now explicitly supplies that flag and the knockback flag used by Cube. Optional `player.cacheBase` values represent incoming native stats and are reset before every cache evaluation; colours are copied so prior writes cannot compound through a shared input object.

This fixture correction does not fix a production flag bug. It also adds one cache callback dispatch per registered cache subscriber when evaluating all flags, so earlier [performance measurements](PERFORMANCE.md) retain their historical fixture scope; do not silently equate their callback totals with this expanded fixture.

The supplied cache inputs and full cache evaluations are not native stat calculation or cache invalidation. There are no weapon-fire, collision, item-use, damage-taken or floor-clear events in these cases. Copy counts, item replacements and clocks are supplied inputs. Generic inventory replacement does not accept native D4/D100/Clicker/Genesis/R Key behavior, special subplayers, active phases, all weapon billing, transient reward policies or other mods' callback order. E2 still gates child-laser/Parent billing changes.

## Validation and handoff

```sh
texlua tests/full_mod_cache_composition_test.lua .
bash tools/check.sh
```

The focused matrix and full gate passed: 85 Lua suites, syntax checks on 205 Lua files and the existing Python/asset/inventory checks. Four syntax-valid isolated fault copies fail the intended checks: Cube overwrites incoming damage, Opus reads stale wallet state, Golden Gate replaces existing flags, and Cube raises a native speed below 0.1. These are validation controls, not newly discovered source defects. The full gate discovers the new `*_test.lua` automatically.

The damage-cache candidate in INTERACTIONS.md is covered for these explicit combinations and initial form states; no priority or balance change is justified. Actual primary/native-weapon events and active character/item loops remain the next compatibility work. U3 and G1-G7 remain open.

Open PR #2's files are untouched, so HANDOFF/CHANGELOG consolidation stays deferred. This record, TESTING.md and INTERACTIONS.md provide the focused handoff. Installed `8fd6a8c` remains unchanged and owner-untried. No game, runtime files, saves, settings or Workshop action occurred.
