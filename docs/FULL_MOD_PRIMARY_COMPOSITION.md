# Full entry-point ordinary-primary composition

## Scope and result

U3/G2 follow-up from v2 main `3a6dbfb`. `tests/full_mod_primary_composition_test.lua` runs actual `main.lua` and all production callbacks with supplied ordinary tears, raw forks, synchronous helper firing, nested damage and item inventories. The earlier [six-item primary matrix](PRIMARY_TEAR_COMPOSITION.md), [cache matrix](FULL_MOD_CACHE_COMPOSITION.md) and [save review](HARDENING_SAVE_COMPOSITION_2026-10-30.md) retain their separate scopes.

No production defect was reproduced in this unit. Production source, values, callback priorities, save schemas, art and installation are unchanged. New assertions guard interactions that the full-entry cache/update fixtures did not execute.

## Supplied scenarios

| Cases | Mechanisms and assertions |
|---|---|
| 22 duplicate-form pairs | Both owners fire two primary tears per frame for five volleys. One holds Opus, Strawberry, Context and Swarm; the other holds Opus. Tainted GPT enters Full Send through DROP. Check resolved third-tear damage/scale, raw Swarm/Peak fork counts, half-damage inheritance, all colour channels, flags, falling/knockback fields and sprite-scale reset. |
| Ordinary aging and collision | Each primary/fork receives ages 0, 1, 1, 30, 62, 90 and 180. Context uses resolved damage without compounding, while the other owner's tears retain their damage. One supplied collision delivers one expected hit in these selected-item cases. Updates and collisions do not create additional bills. |
| Paid resource composition | Within the duplicate-form cases, Claude Usage changes once per volley (8 with Swarm, 4 without), tainted Claude Quota pays 2/1, Valley Compute pays 2 independently for both owners, and Full Send Credits pay 1. Opus bills ten primaries as one coin per owner; raw forks, aging and collisions do not count as additional primaries. |
| Earned Thought and Cooker | Normal DeepSeek completes an actual DROP meal and earns 150 Thought; a vanilla partner completes Rice Cooker. Three same-frame primaries combine Thought with Strawberry, and Swarm copies their resolved damage. Context retains that ordinary-shot boost. Thought is consumed once; the partner keeps its own Cooker prime until its collision, then a later volley loses the bonus. |
| Five synchronous-helper cases | Claude N/T, DeepSeek N/T and GPT T hold Opus plus One More Finger. The fifth/tenth actual attacks schedule helpers for the next update. Their synchronous FireTear callbacks run and mark them as derived; their 0.3 multiplier is applied, the spawn scope unwinds and neither owner receives extra Opus charges. |
| 88 mixed two-owner inventories | Four deterministic cases per form, paired with vanilla. One holds all 80 registered IDs; three sample the registry. Both owners also hold Opus. Ten supplied primaries per owner execute fire/update/hit listeners and scheduled helpers. Damage remains finite, raw spawning stays bounded and each owner pays exactly one coin. Inventory removal and a room transition restore primary damage/scale and leave no supplied directional lock or retained Opus charge. |

The duplicate-form cases exercise actual form callbacks but not every form's active ability. Full Send and the earned Rice meal are explicitly activated; the mixed inventory cases exercise passive listeners, not all 80 active/passive mechanisms. No enemy kill, boss floor or complete run is accepted from these scenarios.

## Fixture additions

`tests/lib/full_mod_env.lua` now supplies ordinary-tear damage, colour, flags, scale and falling fields, typed `ToTear()` results, `ResetSpriteScale`, and deterministic per-player/per-item RNG stand-ins. Previously the generic raw spawn returned an effect-kind object even for a tear, so the fork-copy branch could not be tested through this fixture.

Two event contracts remain explicit:

- Raw `Isaac.Spawn(ENTITY_TEAR, ...)` creates a typed tear without synthesizing a POST_FIRE_TEAR callback. This exercises the production raw-fork copy path without recursively inventing primary events.
- Player `FireTear` applies the supplied damage multiplier and synchronously dispatches POST_FIRE_TEAR. This exercises the existing owner-scoped helper exemption before later callbacks mark the tear as derived.

Those are supplied fixture contracts, not new native observations. The RNG stream, age inputs, native fields, cache inheritance, collision dispatch and sprite-scale field are stand-ins. No flight physics, animation, native RNG sequence, item renderer, input device or cross-mod callback behavior is modeled. Old update/performance fixtures retain their original measurement scope.

## Verification

```sh
texlua tests/full_mod_primary_composition_test.lua .
bash tools/check.sh
```

Four syntax-valid isolated fault copies fail the intended assertions:

| Deliberate fault | Rejected outcome |
|---|---|
| Move Swarm from LATE to default priority | Forks miss the later resolved Strawberry damage. |
| Copy player damage instead of parent projectile damage | Forks lose the resolved projectile bonus. |
| Context snapshots player damage | Parent/child resolved damage is lost during aging. |
| Opus ignores the synchronous owner spawn scope | One More Finger helpers add charges before the derived marker is applied. |

The focused suite and full gate passed: 86 Lua suites, syntax checks on 206 Lua files and the existing Python/asset/inventory checks. These faults are validation controls, not new production defects or policy changes. The gate automatically discovers the new `*_test.lua`; earlier suites remain active.

## Remaining work and handoff

- This covers supplied ordinary tears and selected raw/helper paths. Brimstone, Technology, knives, Dr./Epic Fetus, Ludovico, melee, native splits and familiar weapons still need the remaining composition/native matrix. No new child-laser/Parent/derived billing policy is introduced; E2 remains a prerequisite to those fixes.
- The initial-form and selected-ability cases do not close all-form resource exhaustion, Birthright timing, every target ability, pause/death, migration/Continue or special subplayer requirements. U3 and G1-G7 remain open.
- Raw-fork copied projectile fields and on-hit item leases are separate mechanisms. These tests do not invent new inheritance for every target modifier or accept native fork callback/ancestry timing.
- Open PR #2's files remain untouched; HANDOFF/CHANGELOG consolidation is deferred. This record, TESTING.md, CHARACTER_COMPLETION.md and INTERACTIONS.md provide the focused handoff. PR #7/RC1 retain their existing gates.

Installed `8fd6a8c` remains unchanged and owner-untried. No game, runtime files, saves, settings or Workshop action occurred.
