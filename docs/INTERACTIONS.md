# Source interaction audit

W4.1, 2026-10-26. Baseline gameplay is `ef7d2dd`; the audit was added from documentation main `a9dca36`. The generated section follows current source, including the later normal-Claude live-owner correction. This is an offline source inventory and triage queue, not a native compatibility verdict. The original audit changed no gameplay, balance, callback priority or save format.

## Reproduce and interpret

Run `python tools/audit_interactions.py --write` after changing `main.lua` or `scripts/**/*.lua`, then review the generated diff. `--check` verifies the marked section without writing; `--json` prints structured source findings. `tools/check.sh` runs the scanner regressions and the freshness check. It does not require the candidate tables to be empty or treat them as proven defects.

The scanner reads all source modules, including helpers with no registrations, without executing Lua. It records callback names and explicit priorities (or `default`), cache-flag references, selected native field assignments/mutator calls, and direct `Risk.state` roots. `self.state` is recognized as Risk state only in `scripts/risk.lua`. Comment and string contents are not executable findings. Source fingerprints and line links make the report reproducible.

Field classifications are deliberately conservative:

- **self-dependent:** the RHS directly reads the same lexical field. This can compose a value, but does not prove correct arithmetic, clamping or order.
- **literal:** the RHS is a literal constant. Some are intentional, such as granting `CanFly`; inspect the condition before calling it an override bug.
- **indirect:** the RHS uses a local, another field or a function. It may already include the original value. Follow its source rather than converting it blindly to an additive write.
- **multiple-target:** target fields are listed, but RHS-to-target mapping needs review.

This is a lexical scanner, not a Lua parser, data-flow analyser or engine model. Receiver aliases, function calls, helper-registered callbacks, implicit metatable mutations, whole-table replacements, dynamic keys, multi-line multiple assignments and dynamically computed callback IDs/priorities remain manual work. Cache flags are module references, not a proof that every write is guarded by that flag. Mutator names are a bounded list, not every native API. The report does not resolve the active character, item possession, source entity or helper descendants. Its overlap table groups field names; it cannot prove that two writers reach the same entity.

`main.lua` supplies explicit Init order, including a fixed backlog-family loop. The report lists declared callback priorities but does not infer a total runtime order from filenames or include order. Same-priority registration, callback phase, conditions and external mods must be considered together. The opt-in `tests/runtime_probe.lua` and future engine callbacks installed by a test session are outside this production-source inventory.

## First review and follow-up queue

| Candidate | Source finding | Disposition and next verification |
|---|---|---|
| Tungsten Cube `MoveSpeed = speed` | [tungsten_cube.lua](../scripts/items/tungsten_cube.lua) first subtracts 0.15 per copy from the current speed, then clamps with `math.min(current, 0.1)` to avoid raising an already lower value. The final assignment is indirect. | **No confirmed absolute-overwrite bug.** Keep the existing rule. Extend a focused speed-writer combination matrix if coverage is missing; do not replace this with an invented base speed. |
| Damage cache additions and multipliers | Constitution is initialized before Risk; ordinary items precede the shared backlog service and character modules in [main.lua](../main.lua). [backlog/common.lua](../scripts/items/backlog/common.lua) multiplies collected damage factors, while other callbacks also add or multiply. | [Full-entry cache coverage](FULL_MOD_CACHE_COMPOSITION.md): 46 initial-form Constitution/Opus/Cube/Tiny cases assert exact ordered arithmetic and immediate wallet changes; 176 two-owner inventories test finite/repeatable caches and replacement/removal. Production already passes. Native invalidation, active phases, real rerolls and other mixed operations remain open; no priority change is justified solely by overlap. |
| Hardcoded Output and 1M Context | [hardcoded_output.lua](../scripts/items/hardcoded_output.lua) intentionally sets a tear to 3.5 on fire. [million_context.lua](../scripts/items/million_context.lua) later assigns saved base damage times its age factor, excluding Ludovico. Backlog/character helpers can also affect projectile damage. | **Existing ordinary-source composition covered:** the [six-module matrix](PRIMARY_TEAR_COMPOSITION.md) captures 3.5, Strawberry third-tear doubling to 7, then Context snapshot/age decay without compounding. Production already passes; this is not a final-writer rule approval or native-order acceptance. Other writers remain open; child/Parent/derived-shot billing still requires native E2 evidence. |
| Colour writes across items and forms | Golden Gate and several item tints read colour through a local alias; roster and tainted Claude do the same. [tear_tint.lua](../scripts/characters/tear_tint.lua) preserves additive channels. New NPC/effect colours also appear under the same `Color` field name. | Indirect assignments are not automatically destructive. The [six-module fixture](PRIMARY_TEAR_COMPOSITION.md) now checks Golden Gate/Pizza Glue/Strawberry/Blueberry over supplied native colour, including alpha/additive offsets and unchanged shared objects. Character tints retain separate coverage; native renderer and other writers remain open. NPC/effect decoration has a different receiver. |
| Charm before ordinary shields | Absolutely Right previously registered a default-priority observer before backlog guards. The real-module fixture reproduced charm on a Sold Out-blocked bullet. | [Corrected to LATE](CHARM_DAMAGE_ORDER.md), with existing source/duration/flag behavior retained. Native final health/status timing, vetoes after LATE and other hit reactions remain open. |
| Tear copying and helper damage | [tear_fork.lua](../scripts/tear_fork.lua) copies parent damage/colour/flags into a new child. Other helpers use native creation, scaling and later field writes. | [Full-entry ordinary-shot coverage](FULL_MOD_PRIMARY_COMPOSITION.md) checks Swarm/Peak resolved copies, Context aging and actual One More Finger synchronous helpers alongside form/item resource accounting. Raw-spawn and helper event contracts remain supplied inputs; production already passes. Preserve established ownership rules; no child-billing fix from static findings. Native E2 remains required for unresolved ancestry. |
| Flight cache | [transformation.lua](../scripts/transformation.lua) assigns `CanFly = true` only after its transformation predicate, within the flight cache. | Intentional grant, not an unconditional loss of native flight. [264 seeded composition cases](AGENTIC_COSTUME_COMPOSITION.md) now exercise the real backlog, transformation and costume-lock callbacks: threshold/removal, supplied native flight, cache rebuilding, type departure/return and vanilla controls. Character ability loops and native cache/render timing remain open. |
| Shared Risk roots | Risk owns serialization/default restoration; legacy `accountAge` is read/migrated by Claude; backlog families share the versioned service through local aliases. The scanner finds direct shared access to `claudeUsage` and `reviewApproved`. | Shared roots are expected in services, but do not prove per-player isolation. The [core loading review](HARDENING_SAVE_SCALARS_2026-10-31.md) validates the eight existing base fields independently while retaining valid module maps; its dynamic boolean-key loop is limited to the four named legacy/pickup flags. [Character slot continuity](CHARACTER_SLOT_OWNERS.md) fixes 21 forms resetting the same observed owners on slot moves; all 22 form records and 17 active timelines now have bounded offline reassignment coverage. W6.1 still needs native identity/save ordering, unobserved moves, broader migration and special-body cases. Dynamic or nested writes remain visible as unresolved work, not accepted coverage. |
| Checkpoint Pin multi-assignment | [backlog/shared.lua](../scripts/items/backlog/shared.lua) restores `Position` and clears `Velocity` in one assignment. | Both targets are listed without pretending the RHS was resolved. Existing mechanism tests and a later native collision/room case determine acceptance. |
| Ignore Instructions dynamic targets | [ignore_instructions.lua](../scripts/items/ignore_instructions.lua) indexes transient primary records by owner pointer and active slot. The four unresolved indexed assignments update/remove these local records; they do not write native entity fields or Risk state. | Manually reviewed for consume/refusal/replacement behavior, EntityPtr/seed identity and room/start clearing. Eight fault checks strengthen offline coverage. Native pairing and recursive external uses remain open in F2; the lexical warnings stay visible. |
| Callback cancellation and explicit late callbacks | Constitution registers before Risk; Risk and Vibe damage bookkeeping use explicit LATE priority. Swarm's fire-tear callback also declares LATE. Other registrations generally use default priority. | Preserve cancellation/derived-shot regressions. Review callbacks with early returns and external integrations by actual event, not the whole-file callback list. Static default priority alone is not an ordering defect. |
| Optional EID registration | Missing or throwing EID registration methods previously escaped `Eid:Init()` and interrupted later entry-point registrations. The indexed `warned[method]` assignment is a local diagnostic map, not engine or Risk state. | [Isolated at the adapter boundary](EID_ISOLATION.md), with failing-before fixtures, unchanged healthy description records and real-entry-point smoke coverage. Native EID versions, rendering and other optional integrations remain open. |
| Meal completion versus cancellation | MealBreak clears its timer on death before the backlog update. Rice Cooker formerly interpreted that zero as completed lunch. | F16 is corrected by requiring a living owner for a new reward. [Real-service composition](HARDENING_2026-10-30.md) preserves normal completion, owner isolation, character-meal cancellation and primary weapon damage/payment. Native death/revival remains open. |
| Unspent Rate-Limit Valve prime after removal | A prime earned while holding the passive previously survived item removal and boosted a later attack. | [F17 corrected offline](VALVE_REMOVAL.md): consumption checks required ownership even before an update; an inventory-loss update removes the pending record. Resolved attack leases and completed active rewards remain unchanged. Native inventory/weapon timing remains open. |
| Shared meal and Rice slot ownership | Both binders previously discarded progress when the same live players changed slots, including an unfinished food lockout. | [F18 corrected offline](O6_RICE_MEAL_IDENTITY.md): atomic remapping retains the same owner's counters, meal delay lease and Thought clock. Replacements, type transitions, migration, supplied saves and knife-exit cleanup have bounded coverage; native reassignment and save/cleanup order remain open. |
| Primary held-beam effect sharing | A paid observer window notified Peak only for the first primary beam; another beam could lose its paid bonus or retain an older paid expiry during an unaffordable window. | [Corrected in full-entry weapon coverage](FULL_MOD_WEAPON_COMPOSITION.md): each eligible primary shares its owner's existing paid/unpaid decision without extra charges or deadline renewal. Four-owner, replacement, pause and exhaustion controls pass. Child classification/payment policy is unchanged; native E2 remains required. |
| Preview repeated enemy enumeration | Every marker previously rebuilt and sorted a nearby-enemy list every fifth update. | [Full entry-point profiling](PERFORMANCE.md) measured 288 queries for four holders over 180 supplied updates. Sharing a callback-local enemy list reduces this to 36 with target/radius/tie/exclusion/lifecycle controls. Native AI, other target writers and engine performance remain unverified. |

No gameplay fix was bundled with the original audit because those findings needed semantic checks before code changes. The later W2 audit reproduced normal-Claude account transfer on live slot replacement and added transient owner isolation with failing-before regressions; [TESTING.md](TESTING.md) retains the precise scope, same-entity debt exception and native limits. W4.2 takes other confirmed defects individually. W4.3 expands native categories and W4.4 adds seeded mod-item combinations. W2/W3 completion tables should link findings to exact registered content and current EID/HUD rules. W6 owns serialization/performance review. Do not treat an empty or manually classified overlap list as engine acceptance.

## Active target integration review (2026-10-30)

[F19 and active-loop composition](HARDENING_TARGET_COMPOSITION_2026-10-30.md) reproduce an independent Export pulse losing its item modifier inside backlog's globally guarded replacement. Guarding the current source/target pair preserves ordinary echo suppression while allowing independent target damage to compose; nested scopes unwind even on exceptions. The actual-main suite drives 25 duplicate-form weapon/ability cases and a Retry pair, with explicit nested-callback and pulse-exemption controls. Native event identity, cancellation order, all combinations and E2 remain open. The full-entry fixture's distinct room SpawnSeeds are supplied identities, not observed engine values.

## Scheduled integration review (2026-10-27)

The [review after #121-#124](HARDENING_2026-10-27.md) adds an item-filtered fixture loading both active modules. Twenty-eight supplied sequences preserve effects across other item callbacks and a target death; four wrong/missing-filter faults missed by the isolated suites are rejected. Existing source registrations are correct, so production code and this generated inventory stay unchanged. Actual native dispatch/order, charge processing and the F12 completion observer remain unverified.

## Evidence and limits

Scanner fixtures cover comments, quoted/long strings, line preservation, callback priorities, multiline expressions, direct versus indirect/literal writes, similar field names, cache flags, selected mutators, direct/shared/dynamic state roots, multiple assignments, malformed lexical regions, deterministic output and stale-report detection. The Tungsten source case explicitly remains indirect. These tests validate the audit tool, not Isaac's semantics.

The owner has not tested installed `8fd6a8c`. This unit does not read or replace installed files, access saves/settings, launch the game or publish Workshop. Native input, weapons, size/flight, save reconstruction and visual cases remain in [TESTING.md](TESTING.md).

<!-- BEGIN GENERATED INTERACTION INVENTORY -->

## Generated source inventory

112 files; 406 callback registrations; 109 candidate direct field writes. Source fingerprint: `cf3b468f98aa8342bb29b8957c66c1672260d105bfa9d2d3828c6f094de12cab`.

Counts are lexical findings, not runtime coverage. Helper modules with no matched operations remain listed. See the manual review and scanner limits above.

### Candidate overlaps

Shared field names require an order/activation review; different receivers may be different entities. Even self-dependent addition and multiplication can be order-sensitive. No row is automatically a confirmed bug.

| Field | Modules with direct writes | Review scope |
|---|---|---|

| CollisionDamage | [items/hardcoded_output.lua](../scripts/items/hardcoded_output.lua), [items/million_context.lua](../scripts/items/million_context.lua), [items/overloaded.lua](../scripts/items/overloaded.lua), [items/strawberry.lua](../scripts/items/strawberry.lua), [tear_fork.lua](../scripts/tear_fork.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| Color | [characters/claude_chan.lua](../scripts/characters/claude_chan.lua), [characters/feedback.lua](../scripts/characters/feedback.lua), [characters/gemini_paint.lua](../scripts/characters/gemini_paint.lua), [enemies/relay_slime.lua](../scripts/enemies/relay_slime.lua), [hydra.lua](../scripts/hydra.lua), [items/backlog/gemini.lua](../scripts/items/backlog/gemini.lua), [items/backlog/mistral.lua](../scripts/items/backlog/mistral.lua), [items/blueberry.lua](../scripts/items/blueberry.lua), [items/pizza_glue.lua](../scripts/items/pizza_glue.lua), [items/strawberry.lua](../scripts/items/strawberry.lua), [tear_fork.lua](../scripts/tear_fork.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| Damage | [characters/claude_chan.lua](../scripts/characters/claude_chan.lua), [characters/claude_chan_b.lua](../scripts/characters/claude_chan_b.lua), [characters/deepseek_chan.lua](../scripts/characters/deepseek_chan.lua), [characters/doubao_again.lua](../scripts/characters/doubao_again.lua), [characters/gemini_edit.lua](../scripts/characters/gemini_edit.lua), [characters/glm_queue.lua](../scripts/characters/glm_queue.lua), [characters/glm_retry.lua](../scripts/characters/glm_retry.lua), [characters/gpt_downgrade.lua](../scripts/characters/gpt_downgrade.lua), [characters/gpt_reset.lua](../scripts/characters/gpt_reset.lua), [characters/grok_ratio.lua](../scripts/characters/grok_ratio.lua), [characters/kimi_manager.lua](../scripts/characters/kimi_manager.lua), [characters/llama_hype.lua](../scripts/characters/llama_hype.lua), [characters/llama_release.lua](../scripts/characters/llama_release.lua), [characters/mistral_baguette.lua](../scripts/characters/mistral_baguette.lua), [characters/qwen_adapter.lua](../scripts/characters/qwen_adapter.lua), [characters/qwen_finetune.lua](../scripts/characters/qwen_finetune.lua), [items/backlog/claude.lua](../scripts/items/backlog/claude.lua), [items/backlog/common.lua](../scripts/items/backlog/common.lua), [items/benchmaxxed.lua](../scripts/items/benchmaxxed.lua), [items/cheap_relay.lua](../scripts/items/cheap_relay.lua), [items/constitution.lua](../scripts/items/constitution.lua), [items/decimal_pill.lua](../scripts/items/decimal_pill.lua), [items/opus_mode.lua](../scripts/items/opus_mode.lua), [items/rolled_back.lua](../scripts/items/rolled_back.lua), [items/silent_update.lua](../scripts/items/silent_update.lua), [items/temperature_dial.lua](../scripts/items/temperature_dial.lua), [items/thinking_cleared.lua](../scripts/items/thinking_cleared.lua), [items/tungsten_cube.lua](../scripts/items/tungsten_cube.lua), [items/ultrathink.lua](../scripts/items/ultrathink.lua), [pills.lua](../scripts/pills.lua), [risk.lua](../scripts/risk.lua), [transformation.lua](../scripts/transformation.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| MaxFireDelay | [characters/qwen_adapter.lua](../scripts/characters/qwen_adapter.lua), [characters/qwen_finetune.lua](../scripts/characters/qwen_finetune.lua), [items/rolled_back.lua](../scripts/items/rolled_back.lua), [pills.lua](../scripts/pills.lua), [transformation.lua](../scripts/transformation.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| MoveSpeed | [characters/claude_chan.lua](../scripts/characters/claude_chan.lua), [characters/deepseek_rice.lua](../scripts/characters/deepseek_rice.lua), [characters/grok_check.lua](../scripts/characters/grok_check.lua), [characters/mistral_baguette.lua](../scripts/characters/mistral_baguette.lua), [characters/mistral_pounce.lua](../scripts/characters/mistral_pounce.lua), [items/backlog/common.lua](../scripts/items/backlog/common.lua), [items/constitution.lua](../scripts/items/constitution.lua), [items/rolled_back.lua](../scripts/items/rolled_back.lua), [items/tungsten_cube.lua](../scripts/items/tungsten_cube.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| Scale | [characters/dossiers.lua](../scripts/characters/dossiers.lua), [enemies/relay_slime.lua](../scripts/enemies/relay_slime.lua), [items/backlog/gemini.lua](../scripts/items/backlog/gemini.lua), [items/strawberry.lua](../scripts/items/strawberry.lua), [tear_fork.lua](../scripts/tear_fork.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| ShotSpeed | [characters/claude_chan.lua](../scripts/characters/claude_chan.lua), [characters/claude_chan_b.lua](../scripts/characters/claude_chan_b.lua), [items/backlog/common.lua](../scripts/items/backlog/common.lua), [items/em_dash.lua](../scripts/items/em_dash.lua), [items/pizza_glue.lua](../scripts/items/pizza_glue.lua), [items/rolled_back.lua](../scripts/items/rolled_back.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| TearColor | [characters/claude_chan.lua](../scripts/characters/claude_chan.lua), [characters/claude_chan_b.lua](../scripts/characters/claude_chan_b.lua), [characters/deepseek_chan.lua](../scripts/characters/deepseek_chan.lua), [characters/model_roster.lua](../scripts/characters/model_roster.lua), [items/golden_gate.lua](../scripts/items/golden_gate.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| TearFlags | [items/em_dash.lua](../scripts/items/em_dash.lua), [items/golden_gate.lua](../scripts/items/golden_gate.lua), [items/tungsten_cube.lua](../scripts/items/tungsten_cube.lua), [tear_fork.lua](../scripts/tear_fork.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| TearRange | [characters/claude_chan.lua](../scripts/characters/claude_chan.lua), [characters/claude_chan_b.lua](../scripts/characters/claude_chan_b.lua), [characters/qwen_adapter.lua](../scripts/characters/qwen_adapter.lua), [items/backlog/common.lua](../scripts/items/backlog/common.lua), [items/golden_gate.lua](../scripts/items/golden_gate.lua), [items/million_context.lua](../scripts/items/million_context.lua), [items/rolled_back.lua](../scripts/items/rolled_back.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |

| Velocity | [items/backlog/mistral.lua](../scripts/items/backlog/mistral.lua), [items/backlog/shared.lua](../scripts/items/backlog/shared.lua), [items/vibe_coding.lua](../scripts/items/vibe_coding.lua) | Receiver identity, active form, callback phase/priority and source registration order need review. |


### Shared state-root access

Read/alias access can mutate nested state later; this table does not infer ownership or prove isolation. Whole-table restoration and dynamic keys require manual review.

| Root | Referencing modules |
|---|---|

| `[dynamic]` | [risk.lua](../scripts/risk.lua) |

| `[whole table]` | [risk.lua](../scripts/risk.lua) |

| `claudeUsage` | [characters/claude_chan.lua](../scripts/characters/claude_chan.lua), [characters/claude_review.lua](../scripts/characters/claude_review.lua) |

| `reviewApproved` | [items/support_ticket.lua](../scripts/items/support_ticket.lua), [story.lua](../scripts/story.lua) |


### Per-module inventory


#### main.lua


Callbacks: `"ClaudeChan:RunRuntimeProbe"` (`default`, [main.lua:102](../main.lua#L102)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/characters/attack_choices.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L12: dynamic field target requires manual review.


#### scripts/characters/claude_chan.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/claude_chan.lua:201](../scripts/characters/claude_chan.lua#L201)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/claude_chan.lua:215](../scripts/characters/claude_chan.lua#L215)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/claude_chan.lua:218](../scripts/characters/claude_chan.lua#L218)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/claude_chan.lua:228](../scripts/characters/claude_chan.lua#L228)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/claude_chan.lua:247](../scripts/characters/claude_chan.lua#L247)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/claude_chan.lua:248](../scripts/characters/claude_chan.lua#L248)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/claude_chan.lua:259](../scripts/characters/claude_chan.lua#L259)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/claude_chan.lua:270](../scripts/characters/claude_chan.lua#L270)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/claude_chan.lua:316](../scripts/characters/claude_chan.lua#L316)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/claude_chan.lua:331](../scripts/characters/claude_chan.lua#L331)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [characters/claude_chan.lua:337](../scripts/characters/claude_chan.lua#L337)), `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [characters/claude_chan.lua:346](../scripts/characters/claude_chan.lua#L346)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/claude_chan.lua:396](../scripts/characters/claude_chan.lua#L396)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_RANGE`, `CACHE_SHOTSPEED`, `CACHE_SPEED`, `CACHE_TEARCOLOR`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/claude_chan.lua:275](../scripts/characters/claude_chan.lua#L275) | `player.Damage` | `player.Damage+AGE_DAMAGE*usage.age` | self-dependent |

| [characters/claude_chan.lua:278](../scripts/characters/claude_chan.lua#L278) | `player.Damage` | `player.Damage*LIMITED_DAMAGE_MULT` | self-dependent |

| [characters/claude_chan.lua:281](../scripts/characters/claude_chan.lua#L281) | `player.TearRange` | `player.TearRange+1.5*40` | self-dependent |

| [characters/claude_chan.lua:283](../scripts/characters/claude_chan.lua#L283) | `player.ShotSpeed` | `player.ShotSpeed+0.2` | self-dependent |

| [characters/claude_chan.lua:285](../scripts/characters/claude_chan.lua#L285) | `player.MoveSpeed` | `player.MoveSpeed-0.1` | self-dependent |

| [characters/claude_chan.lua:287](../scripts/characters/claude_chan.lua#L287) | `player.TearColor` | `Tint.Apply(player.TearColor,1,0.55,0.25,1)` | self-dependent |

| [characters/claude_chan.lua:326](../scripts/characters/claude_chan.lua#L326) | `tear.Color` | `Tint.Apply(tear.Color,0.5,0.5,0.5,0.7)` | self-dependent |



Risk state roots: `accountAge` direct write at L213; `accountAge` read/alias at L174; `claudeUsage` direct write at L168, L203; `claudeUsage` read/alias at L103, L167.


Unresolved syntax: L114: dynamic field target requires manual review; L133: dynamic field target requires manual review; L134: dynamic field target requires manual review; L138: dynamic field target requires manual review; L140: dynamic field target requires manual review; L141: dynamic field target requires manual review; L147: dynamic field target requires manual review; L148: dynamic field target requires manual review; L152: dynamic field target requires manual review; L171: dynamic field target requires manual review; L299: dynamic field target requires manual review; L351: dynamic field target requires manual review; L367: dynamic field target requires manual review; L98: dynamic field target requires manual review.


#### scripts/characters/claude_chan_b.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/claude_chan_b.lua:152](../scripts/characters/claude_chan_b.lua#L152)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/claude_chan_b.lua:162](../scripts/characters/claude_chan_b.lua#L162)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/claude_chan_b.lua:165](../scripts/characters/claude_chan_b.lua#L165)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/claude_chan_b.lua:172](../scripts/characters/claude_chan_b.lua#L172)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/claude_chan_b.lua:173](../scripts/characters/claude_chan_b.lua#L173)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/claude_chan_b.lua:217](../scripts/characters/claude_chan_b.lua#L217)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/claude_chan_b.lua:231](../scripts/characters/claude_chan_b.lua#L231)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/claude_chan_b.lua:264](../scripts/characters/claude_chan_b.lua#L264)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/claude_chan_b.lua:274](../scripts/characters/claude_chan_b.lua#L274)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [characters/claude_chan_b.lua:279](../scripts/characters/claude_chan_b.lua#L279)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/claude_chan_b.lua:284](../scripts/characters/claude_chan_b.lua#L284)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_RANGE`, `CACHE_SHOTSPEED`, `CACHE_TEARCOLOR`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/claude_chan_b.lua:236](../scripts/characters/claude_chan_b.lua#L236) | `player.Damage` | `player.Damage*(suspended and SUSPENDED_DAMAGE or DAMAGE_MULT)` | self-dependent |

| [characters/claude_chan_b.lua:238](../scripts/characters/claude_chan_b.lua#L238) | `player.TearRange` | `player.TearRange+1.5*40` | self-dependent |

| [characters/claude_chan_b.lua:240](../scripts/characters/claude_chan_b.lua#L240) | `player.ShotSpeed` | `player.ShotSpeed+0.2` | self-dependent |

| [characters/claude_chan_b.lua:244](../scripts/characters/claude_chan_b.lua#L244) | `player.TearColor` | `Color(c.R*k[1],c.G*k[2],c.B*k[3],c.A*k[4],c.RO,c.GO,c.BO)` | indirect |

| [characters/claude_chan_b.lua:245](../scripts/characters/claude_chan_b.lua#L245) | `player.TearColor` | `Color(k[1],k[2],k[3],k[4],0,0,0)` | indirect |



Risk state roots: `claudeAppeal` direct write at L89, L154; `claudeAppeal` read/alias at L70, L89, L90.


Unresolved syntax: L109: dynamic field target requires manual review; L111: dynamic field target requires manual review; L113: dynamic field target requires manual review; L193: dynamic field target requires manual review; L223: dynamic field target requires manual review.


#### scripts/characters/claude_review.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/claude_review.lua:63](../scripts/characters/claude_review.lua#L63)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/claude_review.lua:67](../scripts/characters/claude_review.lua#L67)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/claude_review.lua:71](../scripts/characters/claude_review.lua#L71)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/claude_review.lua:72](../scripts/characters/claude_review.lua#L72)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [characters/claude_review.lua:73](../scripts/characters/claude_review.lua#L73)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/claude_review.lua:80](../scripts/characters/claude_review.lua#L80)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `claudeUsage` read/alias at L49.


Unresolved syntax: L40: dynamic field target requires manual review.


#### scripts/characters/costume_lock.lua


Callbacks: `ModCallbacks.MC_POST_PLAYER_UPDATE` (`default`, [characters/costume_lock.lua:95](../scripts/characters/costume_lock.lua#L95)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/costume_lock.lua:100](../scripts/characters/costume_lock.lua#L100)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/costume_lock.lua:101](../scripts/characters/costume_lock.lua#L101)), `ModCallbacks.MC_USE_ITEM` (`default`, [characters/costume_lock.lua:102](../scripts/characters/costume_lock.lua#L102)), `ModCallbacks.MC_USE_CARD` (`default`, [characters/costume_lock.lua:105](../scripts/characters/costume_lock.lua#L105)), `ModCallbacks.MC_USE_PILL` (`default`, [characters/costume_lock.lua:106](../scripts/characters/costume_lock.lua#L106)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L23: dynamic field target requires manual review.


#### scripts/characters/deepseek_chan.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/deepseek_chan.lua:20](../scripts/characters/deepseek_chan.lua#L20)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/deepseek_chan.lua:30](../scripts/characters/deepseek_chan.lua#L30)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_TEARCOLOR`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/deepseek_chan.lua:34](../scripts/characters/deepseek_chan.lua#L34) | `player.Damage` | `player.Damage*(k=="normal"and NORMAL_DAMAGE or TAINTED_DAMAGE)` | self-dependent |

| [characters/deepseek_chan.lua:37](../scripts/characters/deepseek_chan.lua#L37) | `player.TearColor` | `Tint.Apply(player.TearColor,0.35,0.65,1,1)` | self-dependent |

| [characters/deepseek_chan.lua:39](../scripts/characters/deepseek_chan.lua#L39) | `player.TearColor` | `Tint.Apply(player.TearColor,0.45,1,0.95,1)` | self-dependent |



Risk state roots: none detected.


#### scripts/characters/deepseek_peak.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/deepseek_peak.lua:126](../scripts/characters/deepseek_peak.lua#L126)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/deepseek_peak.lua:132](../scripts/characters/deepseek_peak.lua#L132)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/deepseek_peak.lua:135](../scripts/characters/deepseek_peak.lua#L135)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/deepseek_peak.lua:142](../scripts/characters/deepseek_peak.lua#L142)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/deepseek_peak.lua:143](../scripts/characters/deepseek_peak.lua#L143)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/deepseek_peak.lua:204](../scripts/characters/deepseek_peak.lua#L204)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/deepseek_peak.lua:289](../scripts/characters/deepseek_peak.lua#L289)), `ModCallbacks.MC_POST_LASER_UPDATE` (`default`, [characters/deepseek_peak.lua:295](../scripts/characters/deepseek_peak.lua#L295)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [characters/deepseek_peak.lua:298](../scripts/characters/deepseek_peak.lua#L298)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/deepseek_peak.lua:319](../scripts/characters/deepseek_peak.lua#L319)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/deepseek_peak.lua:338](../scripts/characters/deepseek_peak.lua#L338)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `deepseekPeak` direct write at L59, L128; `deepseekPeak` read/alias at L59, L60.


Unresolved syntax: L238: dynamic field target requires manual review; L250: dynamic field target requires manual review; L273: dynamic field target requires manual review; L50: dynamic field target requires manual review; L86: dynamic field target requires manual review; L88: dynamic field target requires manual review; L90: dynamic field target requires manual review.


#### scripts/characters/deepseek_rice.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/deepseek_rice.lua:106](../scripts/characters/deepseek_rice.lua#L106)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/deepseek_rice.lua:117](../scripts/characters/deepseek_rice.lua#L117)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/deepseek_rice.lua:120](../scripts/characters/deepseek_rice.lua#L120)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/deepseek_rice.lua:130](../scripts/characters/deepseek_rice.lua#L130)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/deepseek_rice.lua:131](../scripts/characters/deepseek_rice.lua#L131)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/deepseek_rice.lua:137](../scripts/characters/deepseek_rice.lua#L137)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/deepseek_rice.lua:149](../scripts/characters/deepseek_rice.lua#L149)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/deepseek_rice.lua:272](../scripts/characters/deepseek_rice.lua#L272)).


Cache flag references: `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/deepseek_rice.lua:134](../scripts/characters/deepseek_rice.lua#L134) | `p.MoveSpeed` | `p.MoveSpeed+0.15` | self-dependent |



Risk state roots: `deepseekRice` direct write at L26, L108; `deepseekRice` read/alias at L26, L27.


Unresolved syntax: L66: dynamic field target requires manual review; L71: dynamic field target requires manual review; L73: dynamic field target requires manual review.


#### scripts/characters/dossiers.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/dossiers.lua:50](../scripts/characters/dossiers.lua#L50)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/dossiers.lua:51](../scripts/characters/dossiers.lua#L51)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/dossiers.lua:52](../scripts/characters/dossiers.lua#L52)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/dossiers.lua:74](../scripts/characters/dossiers.lua#L74) | `sprite.Scale` | `Vector(scale,scale)` | indirect |



Risk state roots: none detected.


#### scripts/characters/doubao_again.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/doubao_again.lua:96](../scripts/characters/doubao_again.lua#L96)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/doubao_again.lua:102](../scripts/characters/doubao_again.lua#L102)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/doubao_again.lua:105](../scripts/characters/doubao_again.lua#L105)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/doubao_again.lua:109](../scripts/characters/doubao_again.lua#L109)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/doubao_again.lua:110](../scripts/characters/doubao_again.lua#L110)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/doubao_again.lua:146](../scripts/characters/doubao_again.lua#L146)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/doubao_again.lua:155](../scripts/characters/doubao_again.lua#L155)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/doubao_again.lua:164](../scripts/characters/doubao_again.lua#L164)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/doubao_again.lua:171](../scripts/characters/doubao_again.lua#L171)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/doubao_again.lua:168](../scripts/characters/doubao_again.lua#L168) | `p.Damage` | `p.Damage*CONFIDENT_DAMAGE` | self-dependent |

| [characters/doubao_again.lua:169](../scripts/characters/doubao_again.lua#L169) | `p.Damage` | `p.Damage*APOLOGY_DAMAGE` | self-dependent |



Risk state roots: `doubaoAgain` direct write at L34, L98; `doubaoAgain` read/alias at L34, L35.


Unresolved syntax: L58: dynamic field target requires manual review; L60: dynamic field target requires manual review; L62: dynamic field target requires manual review.


#### scripts/characters/doubao_apology.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/doubao_apology.lua:124](../scripts/characters/doubao_apology.lua#L124)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/doubao_apology.lua:129](../scripts/characters/doubao_apology.lua#L129)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/doubao_apology.lua:132](../scripts/characters/doubao_apology.lua#L132)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/doubao_apology.lua:140](../scripts/characters/doubao_apology.lua#L140)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/doubao_apology.lua:167](../scripts/characters/doubao_apology.lua#L167)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/doubao_apology.lua:181](../scripts/characters/doubao_apology.lua#L181)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `doubaoApology` direct write at L40, L126; `doubaoApology` read/alias at L40, L41.


Unresolved syntax: L65: dynamic field target requires manual review; L67: dynamic field target requires manual review; L69: dynamic field target requires manual review.


#### scripts/characters/drop_tap.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L112: dynamic field target requires manual review; L126: dynamic field target requires manual review; L38: dynamic field target requires manual review; L46: dynamic field target requires manual review; L57: dynamic field target requires manual review; L90: dynamic field target requires manual review.


#### scripts/characters/feedback.lua


Callbacks: none detected.


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/feedback.lua:11](../scripts/characters/feedback.lua#L11) | `effect.Color` | `color` | indirect |



Mutator calls: `SetColor` ([characters/feedback.lua:16](../scripts/characters/feedback.lua#L16)).


Risk state roots: none detected.


#### scripts/characters/gemini_edit.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/gemini_edit.lua:93](../scripts/characters/gemini_edit.lua#L93)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/gemini_edit.lua:99](../scripts/characters/gemini_edit.lua#L99)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/gemini_edit.lua:102](../scripts/characters/gemini_edit.lua#L102)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/gemini_edit.lua:108](../scripts/characters/gemini_edit.lua#L108)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/gemini_edit.lua:146](../scripts/characters/gemini_edit.lua#L146)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/gemini_edit.lua:152](../scripts/characters/gemini_edit.lua#L152)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/gemini_edit.lua:171](../scripts/characters/gemini_edit.lua#L171)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/gemini_edit.lua:174](../scripts/characters/gemini_edit.lua#L174)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/gemini_edit.lua:172](../scripts/characters/gemini_edit.lua#L172) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `geminiEdit` direct write at L38, L95; `geminiEdit` read/alias at L38, L39.


Unresolved syntax: L161: dynamic field target requires manual review; L62: dynamic field target requires manual review; L64: dynamic field target requires manual review; L66: dynamic field target requires manual review.


#### scripts/characters/gemini_paint.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/gemini_paint.lua:109](../scripts/characters/gemini_paint.lua#L109)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/gemini_paint.lua:115](../scripts/characters/gemini_paint.lua#L115)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/gemini_paint.lua:118](../scripts/characters/gemini_paint.lua#L118)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/gemini_paint.lua:125](../scripts/characters/gemini_paint.lua#L125)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/gemini_paint.lua:126](../scripts/characters/gemini_paint.lua#L126)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/gemini_paint.lua:166](../scripts/characters/gemini_paint.lua#L166)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/gemini_paint.lua:177](../scripts/characters/gemini_paint.lua#L177)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [characters/gemini_paint.lua:191](../scripts/characters/gemini_paint.lua#L191)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/gemini_paint.lua:211](../scripts/characters/gemini_paint.lua#L211)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/gemini_paint.lua:206](../scripts/characters/gemini_paint.lua#L206) | `effect.Color` | `Color(1,0.9,0.2,1,0.4,0.35,0)` | indirect |



Risk state roots: `geminiPaint` direct write at L45, L111; `geminiPaint` read/alias at L45, L46.


Unresolved syntax: L144: dynamic field target requires manual review; L172: dynamic field target requires manual review; L73: dynamic field target requires manual review; L75: dynamic field target requires manual review; L77: dynamic field target requires manual review.


#### scripts/characters/glm_queue.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/glm_queue.lua:113](../scripts/characters/glm_queue.lua#L113)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/glm_queue.lua:119](../scripts/characters/glm_queue.lua#L119)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/glm_queue.lua:122](../scripts/characters/glm_queue.lua#L122)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/glm_queue.lua:134](../scripts/characters/glm_queue.lua#L134)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/glm_queue.lua:135](../scripts/characters/glm_queue.lua#L135)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/glm_queue.lua:170](../scripts/characters/glm_queue.lua#L170)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/glm_queue.lua:180](../scripts/characters/glm_queue.lua#L180)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/glm_queue.lua:185](../scripts/characters/glm_queue.lua#L185)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/glm_queue.lua:183](../scripts/characters/glm_queue.lua#L183) | `p.Damage` | `p.Damage*BONUS` | self-dependent |



Risk state roots: `glmQueue` direct write at L42, L115; `glmQueue` read/alias at L42, L43.


Unresolved syntax: L153: dynamic field target requires manual review; L156: dynamic field target requires manual review; L176: dynamic field target requires manual review; L74: dynamic field target requires manual review; L76: dynamic field target requires manual review; L78: dynamic field target requires manual review.


#### scripts/characters/glm_retry.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/glm_retry.lua:102](../scripts/characters/glm_retry.lua#L102)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/glm_retry.lua:108](../scripts/characters/glm_retry.lua#L108)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/glm_retry.lua:111](../scripts/characters/glm_retry.lua#L111)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/glm_retry.lua:118](../scripts/characters/glm_retry.lua#L118)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/glm_retry.lua:119](../scripts/characters/glm_retry.lua#L119)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/glm_retry.lua:175](../scripts/characters/glm_retry.lua#L175)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/glm_retry.lua:178](../scripts/characters/glm_retry.lua#L178)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/glm_retry.lua:176](../scripts/characters/glm_retry.lua#L176) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `glmRetry` direct write at L36, L104; `glmRetry` read/alias at L36, L37.


Unresolved syntax: L56: dynamic field target requires manual review; L58: dynamic field target requires manual review; L60: dynamic field target requires manual review.


#### scripts/characters/gpt_downgrade.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/gpt_downgrade.lua:116](../scripts/characters/gpt_downgrade.lua#L116)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/gpt_downgrade.lua:122](../scripts/characters/gpt_downgrade.lua#L122)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/gpt_downgrade.lua:125](../scripts/characters/gpt_downgrade.lua#L125)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/gpt_downgrade.lua:132](../scripts/characters/gpt_downgrade.lua#L132)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/gpt_downgrade.lua:133](../scripts/characters/gpt_downgrade.lua#L133)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/gpt_downgrade.lua:181](../scripts/characters/gpt_downgrade.lua#L181)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/gpt_downgrade.lua:191](../scripts/characters/gpt_downgrade.lua#L191)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/gpt_downgrade.lua:196](../scripts/characters/gpt_downgrade.lua#L196)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [characters/gpt_downgrade.lua:212](../scripts/characters/gpt_downgrade.lua#L212)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/gpt_downgrade.lua:222](../scripts/characters/gpt_downgrade.lua#L222)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/gpt_downgrade.lua:227](../scripts/characters/gpt_downgrade.lua#L227)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/gpt_downgrade.lua:225](../scripts/characters/gpt_downgrade.lua#L225) | `p.Damage` | `p.Damage*(b.state.verified and VERIFIED_DAMAGE or FALLBACK_DAMAGE)` | self-dependent |



Risk state roots: `gptRouting` direct write at L34, L118; `gptRouting` read/alias at L34, L35.


Unresolved syntax: L145: dynamic field target requires manual review; L187: dynamic field target requires manual review; L72: dynamic field target requires manual review; L75: dynamic field target requires manual review; L77: dynamic field target requires manual review.


#### scripts/characters/gpt_reset.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/gpt_reset.lua:126](../scripts/characters/gpt_reset.lua#L126)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/gpt_reset.lua:132](../scripts/characters/gpt_reset.lua#L132)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/gpt_reset.lua:135](../scripts/characters/gpt_reset.lua#L135)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/gpt_reset.lua:141](../scripts/characters/gpt_reset.lua#L141)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/gpt_reset.lua:142](../scripts/characters/gpt_reset.lua#L142)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/gpt_reset.lua:170](../scripts/characters/gpt_reset.lua#L170)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/gpt_reset.lua:186](../scripts/characters/gpt_reset.lua#L186)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/gpt_reset.lua:193](../scripts/characters/gpt_reset.lua#L193)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [characters/gpt_reset.lua:198](../scripts/characters/gpt_reset.lua#L198)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/gpt_reset.lua:205](../scripts/characters/gpt_reset.lua#L205)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/gpt_reset.lua:210](../scripts/characters/gpt_reset.lua#L210)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/gpt_reset.lua:208](../scripts/characters/gpt_reset.lua#L208) | `p.Damage` | `p.Damage*FULL_SEND_DAMAGE` | self-dependent |



Risk state roots: `gptReset` direct write at L42, L128; `gptReset` read/alias at L42, L43.


Unresolved syntax: L154: dynamic field target requires manual review; L176: dynamic field target requires manual review; L74: dynamic field target requires manual review; L76: dynamic field target requires manual review; L78: dynamic field target requires manual review.


#### scripts/characters/grok_check.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/grok_check.lua:105](../scripts/characters/grok_check.lua#L105)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/grok_check.lua:111](../scripts/characters/grok_check.lua#L111)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/grok_check.lua:114](../scripts/characters/grok_check.lua#L114)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/grok_check.lua:128](../scripts/characters/grok_check.lua#L128)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/grok_check.lua:129](../scripts/characters/grok_check.lua#L129)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/grok_check.lua:177](../scripts/characters/grok_check.lua#L177)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/grok_check.lua:182](../scripts/characters/grok_check.lua#L182)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [characters/grok_check.lua:204](../scripts/characters/grok_check.lua#L204)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/grok_check.lua:214](../scripts/characters/grok_check.lua#L214)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/grok_check.lua:221](../scripts/characters/grok_check.lua#L221)).


Cache flag references: `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/grok_check.lua:218](../scripts/characters/grok_check.lua#L218) | `p.MoveSpeed` | `p.MoveSpeed+VERIFIED_SPEED` | self-dependent |



Risk state roots: `grokCheck` direct write at L37, L107; `grokCheck` read/alias at L37, L38.


Unresolved syntax: L194: dynamic field target requires manual review; L65: dynamic field target requires manual review; L67: dynamic field target requires manual review; L69: dynamic field target requires manual review.


#### scripts/characters/grok_ratio.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/grok_ratio.lua:109](../scripts/characters/grok_ratio.lua#L109)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/grok_ratio.lua:115](../scripts/characters/grok_ratio.lua#L115)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/grok_ratio.lua:118](../scripts/characters/grok_ratio.lua#L118)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/grok_ratio.lua:124](../scripts/characters/grok_ratio.lua#L124)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/grok_ratio.lua:171](../scripts/characters/grok_ratio.lua#L171)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/grok_ratio.lua:176](../scripts/characters/grok_ratio.lua#L176)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/grok_ratio.lua:189](../scripts/characters/grok_ratio.lua#L189)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/grok_ratio.lua:192](../scripts/characters/grok_ratio.lua#L192)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/grok_ratio.lua:190](../scripts/characters/grok_ratio.lua#L190) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `grokRatio` direct write at L41, L111; `grokRatio` read/alias at L41, L42.


Unresolved syntax: L62: dynamic field target requires manual review; L65: dynamic field target requires manual review; L67: dynamic field target requires manual review.


#### scripts/characters/kimi_manager.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/kimi_manager.lua:122](../scripts/characters/kimi_manager.lua#L122)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/kimi_manager.lua:128](../scripts/characters/kimi_manager.lua#L128)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/kimi_manager.lua:131](../scripts/characters/kimi_manager.lua#L131)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/kimi_manager.lua:138](../scripts/characters/kimi_manager.lua#L138)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/kimi_manager.lua:139](../scripts/characters/kimi_manager.lua#L139)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/kimi_manager.lua:194](../scripts/characters/kimi_manager.lua#L194)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/kimi_manager.lua:199](../scripts/characters/kimi_manager.lua#L199)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/kimi_manager.lua:210](../scripts/characters/kimi_manager.lua#L210)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/kimi_manager.lua:213](../scripts/characters/kimi_manager.lua#L213)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/kimi_manager.lua:211](../scripts/characters/kimi_manager.lua#L211) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `kimiManager` direct write at L49, L124; `kimiManager` read/alias at L49, L50.


Unresolved syntax: L183: dynamic field target requires manual review; L77: dynamic field target requires manual review; L79: dynamic field target requires manual review; L81: dynamic field target requires manual review.


#### scripts/characters/kimi_slides.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/kimi_slides.lua:140](../scripts/characters/kimi_slides.lua#L140)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/kimi_slides.lua:146](../scripts/characters/kimi_slides.lua#L146)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/kimi_slides.lua:149](../scripts/characters/kimi_slides.lua#L149)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/kimi_slides.lua:156](../scripts/characters/kimi_slides.lua#L156)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/kimi_slides.lua:157](../scripts/characters/kimi_slides.lua#L157)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/kimi_slides.lua:201](../scripts/characters/kimi_slides.lua#L201)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/kimi_slides.lua:212](../scripts/characters/kimi_slides.lua#L212)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/kimi_slides.lua:222](../scripts/characters/kimi_slides.lua#L222)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `kimiSlides` direct write at L51, L142; `kimiSlides` read/alias at L51, L52.


Unresolved syntax: L118: dynamic field target requires manual review; L135: dynamic field target requires manual review; L175: dynamic field target requires manual review; L178: dynamic field target requires manual review; L207: dynamic field target requires manual review; L79: dynamic field target requires manual review; L81: dynamic field target requires manual review; L83: dynamic field target requires manual review.


#### scripts/characters/llama_hype.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/llama_hype.lua:112](../scripts/characters/llama_hype.lua#L112)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/llama_hype.lua:118](../scripts/characters/llama_hype.lua#L118)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/llama_hype.lua:121](../scripts/characters/llama_hype.lua#L121)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/llama_hype.lua:127](../scripts/characters/llama_hype.lua#L127)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/llama_hype.lua:128](../scripts/characters/llama_hype.lua#L128)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/llama_hype.lua:167](../scripts/characters/llama_hype.lua#L167)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/llama_hype.lua:177](../scripts/characters/llama_hype.lua#L177)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/llama_hype.lua:180](../scripts/characters/llama_hype.lua#L180)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/llama_hype.lua:178](../scripts/characters/llama_hype.lua#L178) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `llamaHype` direct write at L42, L114; `llamaHype` read/alias at L42, L43.


Unresolved syntax: L146: dynamic field target requires manual review; L173: dynamic field target requires manual review; L70: dynamic field target requires manual review; L72: dynamic field target requires manual review; L74: dynamic field target requires manual review.


#### scripts/characters/llama_release.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/llama_release.lua:112](../scripts/characters/llama_release.lua#L112)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/llama_release.lua:118](../scripts/characters/llama_release.lua#L118)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/llama_release.lua:121](../scripts/characters/llama_release.lua#L121)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/llama_release.lua:127](../scripts/characters/llama_release.lua#L127)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/llama_release.lua:128](../scripts/characters/llama_release.lua#L128)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/llama_release.lua:153](../scripts/characters/llama_release.lua#L153)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/llama_release.lua:167](../scripts/characters/llama_release.lua#L167)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/llama_release.lua:170](../scripts/characters/llama_release.lua#L170)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/llama_release.lua:168](../scripts/characters/llama_release.lua#L168) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `llamaRelease` direct write at L40, L114; `llamaRelease` read/alias at L40, L41.


Unresolved syntax: L139: dynamic field target requires manual review; L159: dynamic field target requires manual review; L68: dynamic field target requires manual review; L70: dynamic field target requires manual review; L72: dynamic field target requires manual review.


#### scripts/characters/mistral_baguette.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/mistral_baguette.lua:110](../scripts/characters/mistral_baguette.lua#L110)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/mistral_baguette.lua:118](../scripts/characters/mistral_baguette.lua#L118)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/mistral_baguette.lua:121](../scripts/characters/mistral_baguette.lua#L121)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/mistral_baguette.lua:127](../scripts/characters/mistral_baguette.lua#L127)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/mistral_baguette.lua:128](../scripts/characters/mistral_baguette.lua#L128)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/mistral_baguette.lua:166](../scripts/characters/mistral_baguette.lua#L166)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/mistral_baguette.lua:171](../scripts/characters/mistral_baguette.lua#L171)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/mistral_baguette.lua:168](../scripts/characters/mistral_baguette.lua#L168) | `p.MoveSpeed` | `p.MoveSpeed+SPEED` | self-dependent |

| [characters/mistral_baguette.lua:169](../scripts/characters/mistral_baguette.lua#L169) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `mistralBaguette` direct write at L40, L112; `mistralBaguette` read/alias at L40, L41.


Unresolved syntax: L103: dynamic field target requires manual review; L60: dynamic field target requires manual review; L62: dynamic field target requires manual review; L64: dynamic field target requires manual review.


#### scripts/characters/mistral_pounce.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/mistral_pounce.lua:113](../scripts/characters/mistral_pounce.lua#L113)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/mistral_pounce.lua:119](../scripts/characters/mistral_pounce.lua#L119)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/mistral_pounce.lua:122](../scripts/characters/mistral_pounce.lua#L122)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/mistral_pounce.lua:126](../scripts/characters/mistral_pounce.lua#L126)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/mistral_pounce.lua:172](../scripts/characters/mistral_pounce.lua#L172)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/mistral_pounce.lua:175](../scripts/characters/mistral_pounce.lua#L175)).


Cache flag references: `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/mistral_pounce.lua:173](../scripts/characters/mistral_pounce.lua#L173) | `p.MoveSpeed` | `p.MoveSpeed+SPEED` | self-dependent |



Risk state roots: `mistralPounce` direct write at L38, L115; `mistralPounce` read/alias at L38, L39.


Unresolved syntax: L59: dynamic field target requires manual review; L61: dynamic field target requires manual review; L63: dynamic field target requires manual review.


#### scripts/characters/model_roster.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/model_roster.lua:73](../scripts/characters/model_roster.lua#L73)).


Cache flag references: `CACHE_TEARCOLOR`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/model_roster.lua:79](../scripts/characters/model_roster.lua#L79) | `p.TearColor` | `Color(c.R*k[1],c.G*k[2],c.B*k[3],c.A,c.RO,c.GO,c.BO)` | indirect |

| [characters/model_roster.lua:80](../scripts/characters/model_roster.lua#L80) | `p.TearColor` | `Color(k[1],k[2],k[3],1,0,0,0)` | indirect |



Risk state roots: none detected.


#### scripts/characters/paid_attacks.lua


Callbacks: `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/paid_attacks.lua:74](../scripts/characters/paid_attacks.lua#L74)), `ModCallbacks.MC_POST_LASER_UPDATE` (`default`, [characters/paid_attacks.lua:77](../scripts/characters/paid_attacks.lua#L77)), `ModCallbacks.MC_POST_TEAR_UPDATE` (`default`, [characters/paid_attacks.lua:94](../scripts/characters/paid_attacks.lua#L94)), `ModCallbacks.MC_POST_KNIFE_UPDATE` (`default`, [characters/paid_attacks.lua:100](../scripts/characters/paid_attacks.lua#L100)), `ModCallbacks.MC_POST_EFFECT_UPDATE` (`default`, [characters/paid_attacks.lua:110](../scripts/characters/paid_attacks.lua#L110)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/paid_attacks.lua:115](../scripts/characters/paid_attacks.lua#L115)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/paid_attacks.lua:116](../scripts/characters/paid_attacks.lua#L116)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/paid_attacks.lua:117](../scripts/characters/paid_attacks.lua#L117)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L106: dynamic field target requires manual review; L46: dynamic field target requires manual review; L57: dynamic field target requires manual review; L69: dynamic field target requires manual review.


#### scripts/characters/qwen_adapter.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/qwen_adapter.lua:124](../scripts/characters/qwen_adapter.lua#L124)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/qwen_adapter.lua:130](../scripts/characters/qwen_adapter.lua#L130)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/qwen_adapter.lua:133](../scripts/characters/qwen_adapter.lua#L133)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/qwen_adapter.lua:147](../scripts/characters/qwen_adapter.lua#L147)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/qwen_adapter.lua:148](../scripts/characters/qwen_adapter.lua#L148)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/qwen_adapter.lua:194](../scripts/characters/qwen_adapter.lua#L194)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/qwen_adapter.lua:208](../scripts/characters/qwen_adapter.lua#L208)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/qwen_adapter.lua:220](../scripts/characters/qwen_adapter.lua#L220)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_FIREDELAY`, `CACHE_RANGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/qwen_adapter.lua:213](../scripts/characters/qwen_adapter.lua#L213) | `p.TearRange` | `p.TearRange+RANGE_BONUS` | self-dependent |

| [characters/qwen_adapter.lua:215](../scripts/characters/qwen_adapter.lua#L215) | `p.MaxFireDelay` | `FireRate.ScaleInterval(p.MaxFireDelay,TEMPO_INTERVAL)` | self-dependent |

| [characters/qwen_adapter.lua:217](../scripts/characters/qwen_adapter.lua#L217) | `p.Damage` | `p.Damage*POWER_DAMAGE` | self-dependent |



Risk state roots: `qwenAdapter` direct write at L51, L126; `qwenAdapter` read/alias at L51, L52.


Unresolved syntax: L180: dynamic field target requires manual review; L183: dynamic field target requires manual review; L200: dynamic field target requires manual review; L87: dynamic field target requires manual review; L89: dynamic field target requires manual review; L91: dynamic field target requires manual review.


#### scripts/characters/qwen_finetune.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/qwen_finetune.lua:122](../scripts/characters/qwen_finetune.lua#L122)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/qwen_finetune.lua:128](../scripts/characters/qwen_finetune.lua#L128)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/qwen_finetune.lua:131](../scripts/characters/qwen_finetune.lua#L131)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/qwen_finetune.lua:137](../scripts/characters/qwen_finetune.lua#L137)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/qwen_finetune.lua:138](../scripts/characters/qwen_finetune.lua#L138)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/qwen_finetune.lua:163](../scripts/characters/qwen_finetune.lua#L163)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/qwen_finetune.lua:181](../scripts/characters/qwen_finetune.lua#L181)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/qwen_finetune.lua:192](../scripts/characters/qwen_finetune.lua#L192)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_FIREDELAY`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/qwen_finetune.lua:187](../scripts/characters/qwen_finetune.lua#L187) | `p.Damage` | `(p.Damage+s.awards*per)*build.damage` | self-dependent |

| [characters/qwen_finetune.lua:189](../scripts/characters/qwen_finetune.lua#L189) | `p.MaxFireDelay` | `FireRate.ScaleInterval(p.MaxFireDelay,build.interval)` | self-dependent |



Risk state roots: `qwenFineTune` direct write at L46, L124; `qwenFineTune` read/alias at L46, L47.


Unresolved syntax: L149: dynamic field target requires manual review; L169: dynamic field target requires manual review; L79: dynamic field target requires manual review; L81: dynamic field target requires manual review; L83: dynamic field target requires manual review.


#### scripts/characters/target_tools.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/characters/tear_tint.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/characters/thought_attacks.lua


Callbacks: `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/thought_attacks.lua:133](../scripts/characters/thought_attacks.lua#L133)), `ModCallbacks.MC_POST_TEAR_UPDATE` (`default`, [characters/thought_attacks.lua:138](../scripts/characters/thought_attacks.lua#L138)), `ModCallbacks.MC_POST_LASER_UPDATE` (`default`, [characters/thought_attacks.lua:161](../scripts/characters/thought_attacks.lua#L161)), `ModCallbacks.MC_POST_KNIFE_UPDATE` (`default`, [characters/thought_attacks.lua:173](../scripts/characters/thought_attacks.lua#L173)), `ModCallbacks.MC_POST_BOMB_UPDATE` (`default`, [characters/thought_attacks.lua:200](../scripts/characters/thought_attacks.lua#L200)), `ModCallbacks.MC_POST_EFFECT_UPDATE` (`default`, [characters/thought_attacks.lua:207](../scripts/characters/thought_attacks.lua#L207)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/thought_attacks.lua:215](../scripts/characters/thought_attacks.lua#L215)), `ModCallbacks.MC_POST_ENTITY_REMOVE` (`default`, [characters/thought_attacks.lua:226](../scripts/characters/thought_attacks.lua#L226)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/thought_attacks.lua:231](../scripts/characters/thought_attacks.lua#L231)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/thought_attacks.lua:232](../scripts/characters/thought_attacks.lua#L232)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/thought_attacks.lua:233](../scripts/characters/thought_attacks.lua#L233)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L103: dynamic field target requires manual review; L124: dynamic field target requires manual review; L150: dynamic field target requires manual review; L183: dynamic field target requires manual review; L188: dynamic field target requires manual review; L195: dynamic field target requires manual review; L213: dynamic field target requires manual review; L229: dynamic field target requires manual review; L24: dynamic field target requires manual review; L75: dynamic field target requires manual review; L81: dynamic field target requires manual review; L93: dynamic field target requires manual review.


#### scripts/compatibility/reaction_pack.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [compatibility/reaction_pack.lua:29](../scripts/compatibility/reaction_pack.lua#L29)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L18: dynamic field target requires manual review.


#### scripts/constants.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/door_safety.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/eid.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L487: dynamic field target requires manual review.


#### scripts/enemies/relay_slime.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [enemies/relay_slime.lua:32](../scripts/enemies/relay_slime.lua#L32)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [enemies/relay_slime.lua:36](../scripts/enemies/relay_slime.lua#L36)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [enemies/relay_slime.lua:44](../scripts/enemies/relay_slime.lua#L44)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [enemies/relay_slime.lua:23](../scripts/enemies/relay_slime.lua#L23) | `npc.Color` | `SLIME_COLOR` | indirect |

| [enemies/relay_slime.lua:24](../scripts/enemies/relay_slime.lua#L24) | `npc.Scale` | `SCALES[generation]` | indirect |



Risk state roots: none detected.


Unresolved syntax: L14: dynamic field target requires manual review.


#### scripts/enemy_scaling.lua


Callbacks: `ModCallbacks.MC_POST_NPC_INIT` (`default`, [enemy_scaling.lua:7](../scripts/enemy_scaling.lua#L7)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/fire_rate.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/hud_layout.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/hud_text.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/hydra.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [hydra.lua:14](../scripts/hydra.lua#L14)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [hydra.lua:18](../scripts/hydra.lua#L18)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [hydra.lua:40](../scripts/hydra.lua#L40) | `clone.Color` | `HYDRA_COLOR` | indirect |



Risk state roots: none detected.


#### scripts/items/absolutely_right.lua


Callbacks: `ModCallbacks.MC_ENTITY_TAKE_DMG` (`CallbackPriority.LATE`, [items/absolutely_right.lua:14](../scripts/items/absolutely_right.lua#L14)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/ai_language_model.lua


Callbacks: `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/ai_language_model.lua:24](../scripts/items/ai_language_model.lua#L24)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/backlog/claude.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/claude.lua:38](../scripts/items/backlog/claude.lua#L38)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/backlog/claude.lua:87](../scripts/items/backlog/claude.lua#L87)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/backlog/claude.lua:91](../scripts/items/backlog/claude.lua#L91) | `player.Damage` | `player.Damage+bonus` | self-dependent |



Risk state roots: none detected.


#### scripts/items/backlog/common.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/backlog/common.lua:253](../scripts/items/backlog/common.lua#L253)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/backlog/common.lua:392](../scripts/items/backlog/common.lua#L392)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [items/backlog/common.lua:403](../scripts/items/backlog/common.lua#L403)), `ModCallbacks.MC_POST_LASER_UPDATE` (`default`, [items/backlog/common.lua:408](../scripts/items/backlog/common.lua#L408)), `ModCallbacks.MC_POST_KNIFE_UPDATE` (`default`, [items/backlog/common.lua:414](../scripts/items/backlog/common.lua#L414)), `ModCallbacks.MC_POST_BOMB_UPDATE` (`default`, [items/backlog/common.lua:423](../scripts/items/backlog/common.lua#L423)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [items/backlog/common.lua:476](../scripts/items/backlog/common.lua#L476)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [items/backlog/common.lua:540](../scripts/items/backlog/common.lua#L540)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/backlog/common.lua:573](../scripts/items/backlog/common.lua#L573)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/backlog/common.lua:584](../scripts/items/backlog/common.lua#L584)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/backlog/common.lua:591](../scripts/items/backlog/common.lua#L591)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [items/backlog/common.lua:606](../scripts/items/backlog/common.lua#L606)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [items/backlog/common.lua:625](../scripts/items/backlog/common.lua#L625)), `ModCallbacks.MC_PRE_USE_ITEM` (`default`, [items/backlog/common.lua:641](../scripts/items/backlog/common.lua#L641)), `ModCallbacks.MC_POST_UPDATE` (`default`, [items/backlog/common.lua:653](../scripts/items/backlog/common.lua#L653)), `ModCallbacks.MC_POST_RENDER` (`default`, [items/backlog/common.lua:682](../scripts/items/backlog/common.lua#L682)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_RANGE`, `CACHE_SHOTSPEED`, `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/backlog/common.lua:257](../scripts/items/backlog/common.lua#L257) | `player.Damage` | `player.Damage*m` | self-dependent |

| [items/backlog/common.lua:261](../scripts/items/backlog/common.lua#L261) | `player.MoveSpeed` | `player.MoveSpeed+add` | self-dependent |

| [items/backlog/common.lua:265](../scripts/items/backlog/common.lua#L265) | `player.TearRange` | `player.TearRange+add` | self-dependent |

| [items/backlog/common.lua:269](../scripts/items/backlog/common.lua#L269) | `player.ShotSpeed` | `player.ShotSpeed+add` | self-dependent |



Risk state roots: `backlog` direct write at L210; `backlog` read/alias at L186, L627, L630.


Unresolved syntax: L132: dynamic field target requires manual review; L197: dynamic field target requires manual review; L214: dynamic field target requires manual review; L282: dynamic field target requires manual review; L292: dynamic field target requires manual review; L308: dynamic field target requires manual review; L311: dynamic field target requires manual review; L312: dynamic field target requires manual review; L328: dynamic field target requires manual review; L335: dynamic field target requires manual review; L343: dynamic field target requires manual review; L456: dynamic field target requires manual review; L553: dynamic field target requires manual review; L568: dynamic field target requires manual review; L637: dynamic field target requires manual review; L97: dynamic field target requires manual review.


#### scripts/items/backlog/deepseek.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/deepseek.lua:27](../scripts/items/backlog/deepseek.lua#L27)), `ModCallbacks.MC_PRE_PICKUP_COLLISION` (`default`, [items/backlog/deepseek.lua:62](../scripts/items/backlog/deepseek.lua#L62)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/deepseek.lua:92](../scripts/items/backlog/deepseek.lua#L92)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L76: dynamic field target requires manual review; L86: dynamic field target requires manual review.


#### scripts/items/backlog/doubao.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/doubao.lua:26](../scripts/items/backlog/doubao.lua#L26)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/doubao.lua:65](../scripts/items/backlog/doubao.lua#L65)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/backlog/gemini.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/gemini.lua:31](../scripts/items/backlog/gemini.lua#L31)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/gemini.lua:52](../scripts/items/backlog/gemini.lua#L52)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/gemini.lua:77](../scripts/items/backlog/gemini.lua#L77)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/backlog/gemini.lua:46](../scripts/items/backlog/gemini.lua#L46) | `poof.Color` | `Color(1,1,0.2,1,0.4,0.4,0)` | indirect |

| [items/backlog/gemini.lua:87](../scripts/items/backlog/gemini.lua#L87) | `e.Color` | `Color(1,1,1,0.6,0.2,0.2,0.4)` | indirect |

| [items/backlog/gemini.lua:106](../scripts/items/backlog/gemini.lua#L106) | `tear.Scale` | `tear.Scale*0.6` | self-dependent |



Mutator calls: `SetColor` ([items/backlog/gemini.lua:36](../scripts/items/backlog/gemini.lua#L36)).


Risk state roots: none detected.


Unresolved syntax: L114: dynamic field target requires manual review; L121: dynamic field target requires manual review; L129: dynamic field target requires manual review; L43: dynamic field target requires manual review; L44: dynamic field target requires manual review; L75: dynamic field target requires manual review; L82: dynamic field target requires manual review.


#### scripts/items/backlog/glm.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/glm.lua:44](../scripts/items/backlog/glm.lua#L44)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/glm.lua:61](../scripts/items/backlog/glm.lua#L61)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/backlog/gpt.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/gpt.lua:26](../scripts/items/backlog/gpt.lua#L26)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/gpt.lua:63](../scripts/items/backlog/gpt.lua#L63)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Mutator calls: `SetColor` ([items/backlog/gpt.lua:32](../scripts/items/backlog/gpt.lua#L32)).


Risk state roots: none detected.


Unresolved syntax: L40: dynamic field target requires manual review.


#### scripts/items/backlog/grok.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/grok.lua:26](../scripts/items/backlog/grok.lua#L26)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Mutator calls: `SetColor` ([items/backlog/grok.lua:31](../scripts/items/backlog/grok.lua#L31)), `SetColor` ([items/backlog/grok.lua:90](../scripts/items/backlog/grok.lua#L90)).


Risk state roots: none detected.


Unresolved syntax: L79: dynamic field target requires manual review; L82: dynamic field target requires manual review; L85: dynamic field target requires manual review; L88: dynamic field target requires manual review.


#### scripts/items/backlog/kimi.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/kimi.lua:29](../scripts/items/backlog/kimi.lua#L29)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/kimi.lua:109](../scripts/items/backlog/kimi.lua#L109)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Mutator calls: `SetColor` ([items/backlog/kimi.lua:38](../scripts/items/backlog/kimi.lua#L38)).


Risk state roots: none detected.


#### scripts/items/backlog/llama.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/llama.lua:38](../scripts/items/backlog/llama.lua#L38)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/llama.lua:76](../scripts/items/backlog/llama.lua#L76)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/backlog/mistral.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/mistral.lua:28](../scripts/items/backlog/mistral.lua#L28)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/mistral.lua:58](../scripts/items/backlog/mistral.lua#L58)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/backlog/mistral.lua:50](../scripts/items/backlog/mistral.lua#L50) | `e.Color` | `Color(0.9,0.7,0.4,1,0.2,0.1,0)` | indirect |

| [items/backlog/mistral.lua:81](../scripts/items/backlog/mistral.lua#L81) | `b.Velocity` | `away:Resized(math.max(6,b.Velocity:Length()))` | indirect |



Risk state roots: none detected.


Unresolved syntax: L76: dynamic field target requires manual review.


#### scripts/items/backlog/qwen.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/qwen.lua:35](../scripts/items/backlog/qwen.lua#L35)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/backlog/shared.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/shared.lua:48](../scripts/items/backlog/shared.lua#L48)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/shared.lua:70](../scripts/items/backlog/shared.lua#L70)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/backlog/shared.lua:74](../scripts/items/backlog/shared.lua#L74) | `player.Position` | `r.pin.position,Vector.Zero` | multiple-target; manual mapping |

| [items/backlog/shared.lua:74](../scripts/items/backlog/shared.lua#L74) | `player.Velocity` | `r.pin.position,Vector.Zero` | multiple-target; manual mapping |



Risk state roots: none detected.


Unresolved syntax: L108: dynamic field target requires manual review; L117: dynamic field target requires manual review; L74: multiple assignment requires manual mapping.


#### scripts/items/ban_hammer.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/ban_hammer.lua:22](../scripts/items/ban_hammer.lua#L22)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/ban_hammer.lua:26](../scripts/items/ban_hammer.lua#L26)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/banked_reset.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/banked_reset.lua:15](../scripts/items/banked_reset.lua#L15)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/benchmaxxed.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/benchmaxxed.lua:20](../scripts/items/benchmaxxed.lua#L20)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/benchmaxxed.lua:30](../scripts/items/benchmaxxed.lua#L30)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/benchmaxxed.lua:24](../scripts/items/benchmaxxed.lua#L24) | `player.Damage` | `player.Damage+Bench.BONUS*count` | self-dependent |

| [items/benchmaxxed.lua:26](../scripts/items/benchmaxxed.lua#L26) | `player.Damage` | `player.Damage*Bench.PENALTY^count` | self-dependent |



Risk state roots: none detected.


#### scripts/items/blueberry.lua


Callbacks: `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/blueberry.lua:15](../scripts/items/blueberry.lua#L15)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/blueberry.lua:23](../scripts/items/blueberry.lua#L23) | `tear.Color` | `Color(c.R*0.45,c.G*0.55,c.B,c.A,c.RO,c.GO,c.BO+0.25)` | indirect |



Mutator calls: `AddTearFlags` ([items/blueberry.lua:21](../scripts/items/blueberry.lua#L21)).


Risk state roots: none detected.


#### scripts/items/cheap_relay.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/cheap_relay.lua:18](../scripts/items/cheap_relay.lua#L18)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/cheap_relay.lua:22](../scripts/items/cheap_relay.lua#L22)), `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [items/cheap_relay.lua:38](../scripts/items/cheap_relay.lua#L38)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/cheap_relay.lua:45](../scripts/items/cheap_relay.lua#L45)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/cheap_relay.lua:48](../scripts/items/cheap_relay.lua#L48) | `player.Damage` | `player.Damage*mult` | self-dependent |



Risk state roots: `relayApplied` direct write at L40; `relayApplied` read/alias at L39.


#### scripts/items/claudius_discount.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/claudius_discount.lua:18](../scripts/items/claudius_discount.lua#L18)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/claudius_discount.lua:21](../scripts/items/claudius_discount.lua#L21)), `ModCallbacks.MC_PRE_PICKUP_COLLISION` (`default`, [items/claudius_discount.lua:25](../scripts/items/claudius_discount.lua#L25)), `ModCallbacks.MC_POST_UPDATE` (`default`, [items/claudius_discount.lua:35](../scripts/items/claudius_discount.lua#L35)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [items/claudius_discount.lua:50](../scripts/items/claudius_discount.lua#L50)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L41: dynamic field target requires manual review; L43: dynamic field target requires manual review.


#### scripts/items/compact.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/compact.lua:18](../scripts/items/compact.lua#L18)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/constitution.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/constitution.lua:186](../scripts/items/constitution.lua#L186)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/constitution.lua:191](../scripts/items/constitution.lua#L191)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [items/constitution.lua:197](../scripts/items/constitution.lua#L197)), `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [items/constitution.lua:206](../scripts/items/constitution.lua#L206)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [items/constitution.lua:215](../scripts/items/constitution.lua#L215)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/constitution.lua:230](../scripts/items/constitution.lua#L230)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/constitution.lua:234](../scripts/items/constitution.lua#L234) | `player.Damage` | `player.Damage*DAMAGE_MULT` | self-dependent |

| [items/constitution.lua:236](../scripts/items/constitution.lua#L236) | `player.MoveSpeed` | `player.MoveSpeed-SPEED_DOWN` | self-dependent |



Risk state roots: `constitution` direct write at L67; `constitution` read/alias at L46; `constitutionApplied` read/alias at L62, L68; `constitutionBlockUsed` direct write at L68; `constitutionBlockUsed` read/alias at L63.


Unresolved syntax: L103: dynamic field target requires manual review; L110: dynamic field target requires manual review; L111: dynamic field target requires manual review; L119: dynamic field target requires manual review; L139: dynamic field target requires manual review; L150: dynamic field target requires manual review; L158: dynamic field target requires manual review; L159: dynamic field target requires manual review; L181: dynamic field target requires manual review; L61: dynamic field target requires manual review.


#### scripts/items/decimal_pill.lua


Callbacks: `ModCallbacks.MC_USE_PILL` (`default`, [items/decimal_pill.lua:19](../scripts/items/decimal_pill.lua#L19)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/decimal_pill.lua:31](../scripts/items/decimal_pill.lua#L31)), `ModCallbacks.MC_POST_UPDATE` (`default`, [items/decimal_pill.lua:40](../scripts/items/decimal_pill.lua#L40)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/decimal_pill.lua:47](../scripts/items/decimal_pill.lua#L47)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/decimal_pill.lua:50](../scripts/items/decimal_pill.lua#L50) | `player.Damage` | `player.Damage+bonus` | self-dependent |



Risk state roots: none detected.


#### scripts/items/deep_research.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/deep_research.lua:11](../scripts/items/deep_research.lua#L11)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/disgrace_loop.lua


Callbacks: `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/disgrace_loop.lua:18](../scripts/items/disgrace_loop.lua#L18)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/disgrace_loop.lua:19](../scripts/items/disgrace_loop.lua#L19)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/disgrace_loop.lua:20](../scripts/items/disgrace_loop.lua#L20)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`CallbackPriority.LATE`, [items/disgrace_loop.lua:25](../scripts/items/disgrace_loop.lua#L25)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L31: dynamic field target requires manual review.


#### scripts/items/em_dash.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/em_dash.lua:14](../scripts/items/em_dash.lua#L14)).


Cache flag references: `CACHE_SHOTSPEED`, `CACHE_TEARFLAG`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/em_dash.lua:17](../scripts/items/em_dash.lua#L17) | `player.ShotSpeed` | `player.ShotSpeed+EmDash.SHOT_SPEED*player:GetCollectibleNum(Constants.Item.EM_DASH)` | self-dependent |

| [items/em_dash.lua:19](../scripts/items/em_dash.lua#L19) | `player.TearFlags` | `player.TearFlags\|TearFlags.TEAR_PIERCING` | self-dependent |



Risk state roots: none detected.


#### scripts/items/golden_gate.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/golden_gate.lua:14](../scripts/items/golden_gate.lua#L14)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/golden_gate.lua:28](../scripts/items/golden_gate.lua#L28)).


Cache flag references: `CACHE_RANGE`, `CACHE_TEARCOLOR`, `CACHE_TEARFLAG`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/golden_gate.lua:17](../scripts/items/golden_gate.lua#L17) | `player.TearRange` | `player.TearRange+RANGE*player:GetCollectibleNum(Constants.Item.GOLDEN_GATE)` | self-dependent |

| [items/golden_gate.lua:19](../scripts/items/golden_gate.lua#L19) | `player.TearFlags` | `player.TearFlags\|TearFlags.TEAR_SPECTRAL` | self-dependent |

| [items/golden_gate.lua:23](../scripts/items/golden_gate.lua#L23) | `player.TearColor` | `Color(c.R,c.G*0.9,c.B*0.5,c.A,c.RO+0.25,c.GO+0.18,c.BO)` | indirect |

| [items/golden_gate.lua:24](../scripts/items/golden_gate.lua#L24) | `player.TearColor` | `Color(1,0.9,0.5,1,0.25,0.18,0)` | indirect |



Risk state roots: none detected.


#### scripts/items/hardcoded_output.lua


Callbacks: `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/hardcoded_output.lua:12](../scripts/items/hardcoded_output.lua#L12)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/hardcoded_output.lua:15](../scripts/items/hardcoded_output.lua#L15) | `tear.CollisionDamage` | `EXPECTED_DAMAGE` | indirect |



Risk state roots: none detected.


#### scripts/items/i_panicked.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/i_panicked.lua:26](../scripts/items/i_panicked.lua#L26)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/ignore_instructions.lua


Callbacks: `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/ignore_instructions.lua:51](../scripts/items/ignore_instructions.lua#L51)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/ignore_instructions.lua:52](../scripts/items/ignore_instructions.lua#L52)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/ignore_instructions.lua:53](../scripts/items/ignore_instructions.lua#L53)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L61: dynamic field target requires manual review; L65: dynamic field target requires manual review; L66: dynamic field target requires manual review; L68: dynamic field target requires manual review.


#### scripts/items/lets_delve.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/lets_delve.lua:7](../scripts/items/lets_delve.lua#L7)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/lunch_break.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/lunch_break.lua:16](../scripts/items/lunch_break.lua#L16)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/meme_state.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `memeExtras` direct write at L58; `memeExtras` read/alias at L20, L42.


Unresolved syntax: L62: dynamic field target requires manual review.


#### scripts/items/million_context.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/million_context.lua:16](../scripts/items/million_context.lua#L16)), `ModCallbacks.MC_POST_TEAR_UPDATE` (`default`, [items/million_context.lua:22](../scripts/items/million_context.lua#L22)).


Cache flag references: `CACHE_RANGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/million_context.lua:18](../scripts/items/million_context.lua#L18) | `player.TearRange` | `player.TearRange+RANGE_BONUS` | self-dependent |

| [items/million_context.lua:32](../scripts/items/million_context.lua#L32) | `tear.CollisionDamage` | `data.ccBaseDamage*rot` | indirect |



Risk state roots: none detected.


#### scripts/items/mt_moon.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/mt_moon.lua:24](../scripts/items/mt_moon.lua#L24)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/mt_moon.lua:25](../scripts/items/mt_moon.lua#L25)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/mt_moon.lua:27](../scripts/items/mt_moon.lua#L27)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/opus_mode.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/opus_mode.lua:31](../scripts/items/opus_mode.lua#L31)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/opus_mode.lua:32](../scripts/items/opus_mode.lua#L32)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/opus_mode.lua:73](../scripts/items/opus_mode.lua#L73)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [items/opus_mode.lua:81](../scripts/items/opus_mode.lua#L81)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [items/opus_mode.lua:86](../scripts/items/opus_mode.lua#L86)), `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [items/opus_mode.lua:92](../scripts/items/opus_mode.lua#L92)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/opus_mode.lua:106](../scripts/items/opus_mode.lua#L106)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/opus_mode.lua:110](../scripts/items/opus_mode.lua#L110) | `player.Damage` | `player.Damage*mult` | self-dependent |



Risk state roots: `opusTears` direct write at L40; `opusTears` read/alias at L34, L34, L40, L41.


Unresolved syntax: L67: dynamic field target requires manual review.


#### scripts/items/overloaded.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/overloaded.lua:22](../scripts/items/overloaded.lua#L22)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/overloaded.lua:23](../scripts/items/overloaded.lua#L23)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/overloaded.lua:25](../scripts/items/overloaded.lua#L25)), `ModCallbacks.MC_POST_UPDATE` (`default`, [items/overloaded.lua:33](../scripts/items/overloaded.lua#L33)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/overloaded.lua:29](../scripts/items/overloaded.lua#L29) | `tear.CollisionDamage` | `tear.CollisionDamage*MANUAL_DAMAGE` | self-dependent |



Risk state roots: none detected.


#### scripts/items/pizza_glue.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/pizza_glue.lua:20](../scripts/items/pizza_glue.lua#L20)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/pizza_glue.lua:25](../scripts/items/pizza_glue.lua#L25)).


Cache flag references: `CACHE_SHOTSPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/pizza_glue.lua:22](../scripts/items/pizza_glue.lua#L22) | `player.ShotSpeed` | `player.ShotSpeed-SHOT_SPEED*player:GetCollectibleNum(Constants.Item.PIZZA_GLUE)` | self-dependent |

| [items/pizza_glue.lua:34](../scripts/items/pizza_glue.lua#L34) | `tear.Color` | `Color(c.R,c.G,c.B*0.85,c.A,c.RO+0.25,c.GO+0.22,c.BO+0.12)` | indirect |

| [items/pizza_glue.lua:35](../scripts/items/pizza_glue.lua#L35) | `tear.Color` | `Color(1,1,0.85,1,0.25,0.22,0.12)` | indirect |



Mutator calls: `AddTearFlags` ([items/pizza_glue.lua:31](../scripts/items/pizza_glue.lua#L31)).


Risk state roots: none detected.


#### scripts/items/prompt_leak.lua


Callbacks: `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/prompt_leak.lua:11](../scripts/items/prompt_leak.lua#L11)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/residential_ip.lua


Callbacks: `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [items/residential_ip.lua:12](../scripts/items/residential_ip.lua#L12)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `residentialApplied` direct write at L17; `residentialApplied` read/alias at L13.


#### scripts/items/rolled_back.lua


Callbacks: `ModCallbacks.MC_USE_PILL` (`default`, [items/rolled_back.lua:19](../scripts/items/rolled_back.lua#L19)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/rolled_back.lua:28](../scripts/items/rolled_back.lua#L28)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/rolled_back.lua:39](../scripts/items/rolled_back.lua#L39)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_FIREDELAY`, `CACHE_LUCK`, `CACHE_RANGE`, `CACHE_SHOTSPEED`, `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/rolled_back.lua:42](../scripts/items/rolled_back.lua#L42) | `player.Damage` | `player.Damage+n` | self-dependent |

| [items/rolled_back.lua:43](../scripts/items/rolled_back.lua#L43) | `player.MaxFireDelay` | `FireRate.ScaleInterval(player.MaxFireDelay,0.8^n)` | self-dependent |

| [items/rolled_back.lua:44](../scripts/items/rolled_back.lua#L44) | `player.MoveSpeed` | `player.MoveSpeed+0.2*n` | self-dependent |

| [items/rolled_back.lua:45](../scripts/items/rolled_back.lua#L45) | `player.TearRange` | `player.TearRange+40*n` | self-dependent |

| [items/rolled_back.lua:46](../scripts/items/rolled_back.lua#L46) | `player.ShotSpeed` | `player.ShotSpeed+0.1*n` | self-dependent |

| [items/rolled_back.lua:47](../scripts/items/rolled_back.lua#L47) | `player.Luck` | `player.Luck+n` | self-dependent |



Risk state roots: none detected.


#### scripts/items/seahorse_emoji.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/seahorse_emoji.lua:24](../scripts/items/seahorse_emoji.lua#L24)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/seahorse_emoji.lua:40](../scripts/items/seahorse_emoji.lua#L40)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/seahorse_emoji.lua:43](../scripts/items/seahorse_emoji.lua#L43)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L21: dynamic field target requires manual review; L35: dynamic field target requires manual review.


#### scripts/items/silent_update.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/silent_update.lua:38](../scripts/items/silent_update.lua#L38)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [items/silent_update.lua:46](../scripts/items/silent_update.lua#L46)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/silent_update.lua:48](../scripts/items/silent_update.lua#L48)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/silent_update.lua:50](../scripts/items/silent_update.lua#L50) | `player.Damage` | `player.Damage*(Risk.state.silentMult or 1)` | self-dependent |



Risk state roots: `silentMult` direct write at L28; `silentMult` read/alias at L50.


#### scripts/items/six_seven.lua


Callbacks: `ModCallbacks.MC_USE_PILL` (`default`, [items/six_seven.lua:7](../scripts/items/six_seven.lua#L7)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/skip_permissions.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/skip_permissions.lua:20](../scripts/items/skip_permissions.lua#L20)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/skip_permissions.lua:24](../scripts/items/skip_permissions.lua#L24)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/slot_owners.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L38: dynamic field target requires manual review; L39: dynamic field target requires manual review; L47: dynamic field target requires manual review; L48: dynamic field target requires manual review; L50: dynamic field target requires manual review.


#### scripts/items/small_rock.lua


Callbacks: `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/small_rock.lua:26](../scripts/items/small_rock.lua#L26)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/small_rock.lua:27](../scripts/items/small_rock.lua#L27)), `ModCallbacks.MC_POST_UPDATE` (`default`, [items/small_rock.lua:29](../scripts/items/small_rock.lua#L29)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/strawberry.lua


Callbacks: `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/strawberry.lua:15](../scripts/items/strawberry.lua#L15)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/strawberry.lua:21](../scripts/items/strawberry.lua#L21) | `tear.CollisionDamage` | `tear.CollisionDamage*Strawberry.DAMAGE` | self-dependent |

| [items/strawberry.lua:22](../scripts/items/strawberry.lua#L22) | `tear.Scale` | `tear.Scale*1.2` | self-dependent |

| [items/strawberry.lua:24](../scripts/items/strawberry.lua#L24) | `tear.Color` | `Color(c.R,c.G*0.35,c.B*0.35,c.A,c.RO+0.3,c.GO,c.BO)` | indirect |



Risk state roots: none detected.


#### scripts/items/subagent_swarm.lua


Callbacks: `ModCallbacks.MC_POST_FIRE_TEAR` (`CallbackPriority.LATE`, [items/subagent_swarm.lua:15](../scripts/items/subagent_swarm.lua#L15)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/summary_stapler.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/summary_stapler.lua:25](../scripts/items/summary_stapler.lua#L25)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/support_ticket.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/support_ticket.lua:6](../scripts/items/support_ticket.lua#L6)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `reviewApproved` direct write at L16.


#### scripts/items/temperature_dial.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/temperature_dial.lua:23](../scripts/items/temperature_dial.lua#L23)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/temperature_dial.lua:37](../scripts/items/temperature_dial.lua#L37)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/temperature_dial.lua:42](../scripts/items/temperature_dial.lua#L42)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/temperature_dial.lua:39](../scripts/items/temperature_dial.lua#L39) | `player.Damage` | `player.Damage*COLD_DAMAGE` | self-dependent |



Mutator calls: `AddTearFlags` ([items/temperature_dial.lua:48](../scripts/items/temperature_dial.lua#L48)).


Risk state roots: none detected.


#### scripts/items/tests_passing.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/tests_passing.lua:20](../scripts/items/tests_passing.lua#L20)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/items/thinking_cleared.lua


Callbacks: `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/thinking_cleared.lua:25](../scripts/items/thinking_cleared.lua#L25)), `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [items/thinking_cleared.lua:42](../scripts/items/thinking_cleared.lua#L42)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/thinking_cleared.lua:46](../scripts/items/thinking_cleared.lua#L46)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/thinking_cleared.lua:49](../scripts/items/thinking_cleared.lua#L49) | `player.Damage` | `player.Damage+ROOM_DAMAGE` | self-dependent |



Risk state roots: none detected.


#### scripts/items/tungsten_cube.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/tungsten_cube.lua:14](../scripts/items/tungsten_cube.lua#L14)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_SPEED`, `CACHE_TEARFLAG`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/tungsten_cube.lua:18](../scripts/items/tungsten_cube.lua#L18) | `player.Damage` | `player.Damage+DAMAGE*count` | self-dependent |

| [items/tungsten_cube.lua:24](../scripts/items/tungsten_cube.lua#L24) | `player.MoveSpeed` | `speed` | indirect |

| [items/tungsten_cube.lua:26](../scripts/items/tungsten_cube.lua#L26) | `player.TearFlags` | `player.TearFlags\|TearFlags.TEAR_KNOCKBACK` | self-dependent |



Risk state roots: none detected.


#### scripts/items/ultrathink.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/ultrathink.lua:21](../scripts/items/ultrathink.lua#L21)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/ultrathink.lua:25](../scripts/items/ultrathink.lua#L25)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/ultrathink.lua:40](../scripts/items/ultrathink.lua#L40)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/ultrathink.lua:51](../scripts/items/ultrathink.lua#L51)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/ultrathink.lua:54](../scripts/items/ultrathink.lua#L54) | `player.Damage` | `player.Damage+LEVELS[level].bonus` | self-dependent |



Risk state roots: none detected.


#### scripts/items/vibe_coding.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/vibe_coding.lua:40](../scripts/items/vibe_coding.lua#L40)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/vibe_coding.lua:46](../scripts/items/vibe_coding.lua#L46)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/vibe_coding.lua:51](../scripts/items/vibe_coding.lua#L51)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`CallbackPriority.LATE`, [items/vibe_coding.lua:66](../scripts/items/vibe_coding.lua#L66)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [items/vibe_coding.lua:80](../scripts/items/vibe_coding.lua#L80)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/vibe_coding.lua:58](../scripts/items/vibe_coding.lua#L58) | `tear.Velocity` | `tear.Velocity*-1` | self-dependent |



Mutator calls: `AddTearFlags` ([items/vibe_coding.lua:60](../scripts/items/vibe_coding.lua#L60)).


Risk state roots: `vibeMistakes` direct write at L31, L96; `vibeMistakes` read/alias at L31, L32, L33, L37, L37.


#### scripts/meal_break.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [meal_break.lua:103](../scripts/meal_break.lua#L103)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [meal_break.lua:115](../scripts/meal_break.lua#L115)), `ModCallbacks.MC_POST_UPDATE` (`default`, [meal_break.lua:119](../scripts/meal_break.lua#L119)), `ModCallbacks.MC_INPUT_ACTION` (`default`, [meal_break.lua:141](../scripts/meal_break.lua#L141)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [meal_break.lua:66](../scripts/meal_break.lua#L66) | `player.FireDelay` | `math.max(player.FireDelay,remaining)` | self-dependent |

| [meal_break.lua:97](../scripts/meal_break.lua#L97) | `player.FireDelay` | `math.min(player.FireDelay,b.state.priorDelay or 0)` | self-dependent |



Risk state roots: `mealBreaks` direct write at L16, L105; `mealBreaks` read/alias at L16, L17.


Unresolved syntax: L51: dynamic field target requires manual review; L52: dynamic field target requires manual review; L54: dynamic field target requires manual review.


#### scripts/pickup_safety.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


#### scripts/pills.lua


Callbacks: `ModCallbacks.MC_USE_PILL` (`default`, [pills.lua:24](../scripts/pills.lua#L24)), `ModCallbacks.MC_USE_PILL` (`default`, [pills.lua:30](../scripts/pills.lua#L30)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [pills.lua:39](../scripts/pills.lua#L39)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [pills.lua:49](../scripts/pills.lua#L49)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_FIREDELAY`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [pills.lua:53](../scripts/pills.lua#L53) | `player.MaxFireDelay` | `FireRate.ScaleInterval(player.MaxFireDelay,CAT_FIRE_DELAY_MULT)` | self-dependent |

| [pills.lua:55](../scripts/pills.lua#L55) | `player.Damage` | `player.Damage*CAT_DAMAGE_MULT` | self-dependent |



Risk state roots: none detected.


#### scripts/risk.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [risk.lua:230](../scripts/risk.lua#L230)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [risk.lua:236](../scripts/risk.lua#L236)), `ModCallbacks.MC_PRE_GAME_EXIT` (`CallbackPriority.EARLY`, [risk.lua:249](../scripts/risk.lua#L249)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [risk.lua:258](../scripts/risk.lua#L258)), `ModCallbacks.MC_POST_UPDATE` (`CallbackPriority.LATE`, [risk.lua:269](../scripts/risk.lua#L269)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [risk.lua:276](../scripts/risk.lua#L276)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`CallbackPriority.LATE`, [risk.lua:281](../scripts/risk.lua#L281)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [risk.lua:288](../scripts/risk.lua#L288)), `ModCallbacks.MC_POST_RENDER` (`default`, [risk.lua:294](../scripts/risk.lua#L294)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [risk.lua:232](../scripts/risk.lua#L232) | `player.Damage` | `player.Damage*SUSPENDED_DAMAGE_MULT` | self-dependent |



Risk state roots: `[dynamic]` direct write at L222; `[whole table]` direct write at L65, L217, L242; `[whole table]` read/alias at L213, L226; `ip` direct write at L198; `ip` read/alias at L304; `risk` direct write at L165, L169; `risk` read/alias at L126, L165, L183, L308; `sharedUsers` direct write at L206; `sharedUsers` read/alias at L304.


Unresolved syntax: L222: dynamic field target requires manual review; L61: dynamic field target requires manual review.


#### scripts/save_sync.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L10: dynamic field target requires manual review.


#### scripts/story.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [story.lua:57](../scripts/story.lua#L57)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [story.lua:58](../scripts/story.lua#L58)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [story.lua:61](../scripts/story.lua#L61)), `ModCallbacks.MC_POST_UPDATE` (`default`, [story.lua:64](../scripts/story.lua#L64)), `ModCallbacks.MC_POST_RENDER` (`default`, [story.lua:70](../scripts/story.lua#L70)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [story.lua:76](../scripts/story.lua#L76)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `reviewApproved` read/alias at L36, L38; `storyPending` direct write at L14; `storyPending` read/alias at L14, L15; `storySeen` direct write at L25; `storySeen` read/alias at L11, L11.


#### scripts/story_roster.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [story_roster.lua:129](../scripts/story_roster.lua#L129)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [story_roster.lua:134](../scripts/story_roster.lua#L134)), `ModCallbacks.MC_POST_UPDATE` (`default`, [story_roster.lua:137](../scripts/story_roster.lua#L137)), `ModCallbacks.MC_POST_RENDER` (`default`, [story_roster.lua:143](../scripts/story_roster.lua#L143)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [story_roster.lua:152](../scripts/story_roster.lua#L152)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `rosterStory` direct write at L79, L130; `rosterStory` read/alias at L79, L80.


#### scripts/tear_fork.lua


Callbacks: none detected.


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [tear_fork.lua:7](../scripts/tear_fork.lua#L7) | `child.CollisionDamage` | `parent.CollisionDamage*damageMultiplier` | indirect |

| [tear_fork.lua:8](../scripts/tear_fork.lua#L8) | `child.Color` | `parent.Color` | indirect |

| [tear_fork.lua:9](../scripts/tear_fork.lua#L9) | `child.TearFlags` | `parent.TearFlags` | indirect |

| [tear_fork.lua:10](../scripts/tear_fork.lua#L10) | `child.Height` | `parent.Height` | indirect |

| [tear_fork.lua:11](../scripts/tear_fork.lua#L11) | `child.FallingSpeed` | `parent.FallingSpeed` | indirect |

| [tear_fork.lua:12](../scripts/tear_fork.lua#L12) | `child.FallingAcceleration` | `parent.FallingAcceleration` | indirect |

| [tear_fork.lua:15](../scripts/tear_fork.lua#L15) | `child.Scale` | `parent.Scale` | indirect |



Mutator calls: `ResetSpriteScale` ([tear_fork.lua:16](../scripts/tear_fork.lua#L16)).


Risk state roots: none detected.


#### scripts/transformation.lua


Callbacks: `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [transformation.lua:35](../scripts/transformation.lua#L35)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [transformation.lua:49](../scripts/transformation.lua#L49)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_FIREDELAY`, `CACHE_FLYING`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [transformation.lua:53](../scripts/transformation.lua#L53) | `player.CanFly` | `true` | literal |

| [transformation.lua:55](../scripts/transformation.lua#L55) | `player.MaxFireDelay` | `FireRate.ScaleInterval(player.MaxFireDelay,FIRE_DELAY_MULT)` | self-dependent |

| [transformation.lua:57](../scripts/transformation.lua#L57) | `player.Damage` | `player.Damage+DAMAGE_BONUS` | self-dependent |



Risk state roots: none detected.

<!-- END GENERATED INTERACTION INVENTORY -->
