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
| Damage cache additions and multipliers | Constitution is initialized before Risk; ordinary items precede the shared backlog service and character modules in [main.lua](../main.lua). [backlog/common.lua](../scripts/items/backlog/common.lua) multiplies collected damage factors, while other callbacks also add or multiply. | Source order is explicit, but mixed operations are noncommutative and mutually exclusive forms are not simultaneous writers. W4.4 should assert documented outcomes for representative item pairs/triples, one cache evaluation and reroll/removal. No priority change is justified solely by overlap. |
| Hardcoded Output and 1M Context | [hardcoded_output.lua](../scripts/items/hardcoded_output.lua) intentionally sets a tear to 3.5 on fire. [million_context.lua](../scripts/items/million_context.lua) later assigns saved base damage times its age factor, excluding Ludovico. Backlog/character helpers can also affect projectile damage. | **Existing ordinary-source composition covered:** the [six-module matrix](PRIMARY_TEAR_COMPOSITION.md) captures 3.5, Strawberry third-tear doubling to 7, then Context snapshot/age decay without compounding. Production already passes; this is not a final-writer rule approval or native-order acceptance. Other writers remain open; child/Parent/derived-shot billing still requires native E2 evidence. |
| Colour writes across items and forms | Golden Gate and several item tints read colour through a local alias; roster and tainted Claude do the same. [tear_tint.lua](../scripts/characters/tear_tint.lua) preserves additive channels. New NPC/effect colours also appear under the same `Color` field name. | Indirect assignments are not automatically destructive. The [six-module fixture](PRIMARY_TEAR_COMPOSITION.md) now checks Golden Gate/Pizza Glue/Strawberry/Blueberry over supplied native colour, including alpha/additive offsets and unchanged shared objects. Character tints retain separate coverage; native renderer and other writers remain open. NPC/effect decoration has a different receiver. |
| Charm before ordinary shields | Absolutely Right previously registered a default-priority observer before backlog guards. The real-module fixture reproduced charm on a Sold Out-blocked bullet. | [Corrected to LATE](CHARM_DAMAGE_ORDER.md), with existing source/duration/flag behavior retained. Native final health/status timing, vetoes after LATE and other hit reactions remain open. |
| Tear copying and helper damage | [tear_fork.lua](../scripts/tear_fork.lua) copies parent damage/colour/flags into a new child. Other helpers use native creation, scaling and later field writes. | Copying to a new entity is not replacing the parent's field. Preserve established ownership/derived-shot rules; no child-billing fix from static findings. Native E2 remains required for unresolved ancestry. |
| Flight cache | [transformation.lua](../scripts/transformation.lua) assigns `CanFly = true` only after its transformation predicate, within the flight cache. | Intentional grant, not an unconditional loss of native flight. [264 seeded composition cases](AGENTIC_COSTUME_COMPOSITION.md) now exercise the real backlog, transformation and costume-lock callbacks: threshold/removal, supplied native flight, cache rebuilding, type departure/return and vanilla controls. Character ability loops and native cache/render timing remain open. |
| Shared Risk roots | Risk owns serialization/default restoration; legacy `accountAge` is read/migrated by Claude; backlog families share the versioned service through local aliases. The scanner finds direct shared access to `claudeUsage` and `reviewApproved`. | Shared roots are expected in services, but do not prove per-player isolation. W6.1 must map ownership/migration and check Continue, type swaps, legacy saves and co-op. Dynamic or nested writes remain visible as unresolved work, not accepted coverage. |
| Checkpoint Pin multi-assignment | [backlog/shared.lua](../scripts/items/backlog/shared.lua) restores `Position` and clears `Velocity` in one assignment. | Both targets are listed without pretending the RHS was resolved. Existing mechanism tests and a later native collision/room case determine acceptance. |
| Ignore Instructions dynamic targets | [ignore_instructions.lua](../scripts/items/ignore_instructions.lua) indexes transient primary records by owner pointer and active slot. The four unresolved indexed assignments update/remove these local records; they do not write native entity fields or Risk state. | Manually reviewed for consume/refusal/replacement behavior, EntityPtr/seed identity and room/start clearing. Eight fault checks strengthen offline coverage. Native pairing and recursive external uses remain open in F2; the lexical warnings stay visible. |
| Callback cancellation and explicit late callbacks | Constitution registers before Risk; Risk and Vibe damage bookkeeping use explicit LATE priority. Swarm's fire-tear callback also declares LATE. Other registrations generally use default priority. | Preserve cancellation/derived-shot regressions. Review callbacks with early returns and external integrations by actual event, not the whole-file callback list. Static default priority alone is not an ordering defect. |

No gameplay fix was bundled with the original audit because those findings needed semantic checks before code changes. The later W2 audit reproduced normal-Claude account transfer on live slot replacement and added transient owner isolation with failing-before regressions; [TESTING.md](TESTING.md) retains the precise scope, same-entity debt exception and native limits. W4.2 takes other confirmed defects individually. W4.3 expands native categories and W4.4 adds seeded mod-item combinations. W2/W3 completion tables should link findings to exact registered content and current EID/HUD rules. W6 owns serialization/performance review. Do not treat an empty or manually classified overlap list as engine acceptance.

## Scheduled integration review (2026-10-27)

The [review after #121-#124](HARDENING_2026-10-27.md) adds an item-filtered fixture loading both active modules. Twenty-eight supplied sequences preserve effects across other item callbacks and a target death; four wrong/missing-filter faults missed by the isolated suites are rejected. Existing source registrations are correct, so production code and this generated inventory stay unchanged. Actual native dispatch/order, charge processing and the F12 completion observer remain unverified.

## Evidence and limits

Scanner fixtures cover comments, quoted/long strings, line preservation, callback priorities, multiline expressions, direct versus indirect/literal writes, similar field names, cache flags, selected mutators, direct/shared/dynamic state roots, multiple assignments, malformed lexical regions, deterministic output and stale-report detection. The Tungsten source case explicitly remains indirect. These tests validate the audit tool, not Isaac's semantics.

The owner has not tested installed `8fd6a8c`. This unit does not read or replace installed files, access saves/settings, launch the game or publish Workshop. Native input, weapons, size/flight, save reconstruction and visual cases remain in [TESTING.md](TESTING.md).

<!-- BEGIN GENERATED INTERACTION INVENTORY -->

## Generated source inventory

111 files; 406 callback registrations; 109 candidate direct field writes. Source fingerprint: `d01eeebbf70a281b075d734edb8223e28aaf2239cc93f2934f2de000d4eb0855`.

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


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/claude_chan.lua:189](../scripts/characters/claude_chan.lua#L189)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/claude_chan.lua:203](../scripts/characters/claude_chan.lua#L203)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/claude_chan.lua:206](../scripts/characters/claude_chan.lua#L206)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/claude_chan.lua:216](../scripts/characters/claude_chan.lua#L216)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/claude_chan.lua:235](../scripts/characters/claude_chan.lua#L235)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/claude_chan.lua:236](../scripts/characters/claude_chan.lua#L236)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/claude_chan.lua:247](../scripts/characters/claude_chan.lua#L247)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/claude_chan.lua:258](../scripts/characters/claude_chan.lua#L258)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/claude_chan.lua:304](../scripts/characters/claude_chan.lua#L304)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/claude_chan.lua:319](../scripts/characters/claude_chan.lua#L319)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [characters/claude_chan.lua:325](../scripts/characters/claude_chan.lua#L325)), `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [characters/claude_chan.lua:334](../scripts/characters/claude_chan.lua#L334)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/claude_chan.lua:379](../scripts/characters/claude_chan.lua#L379)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_RANGE`, `CACHE_SHOTSPEED`, `CACHE_SPEED`, `CACHE_TEARCOLOR`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/claude_chan.lua:263](../scripts/characters/claude_chan.lua#L263) | `player.Damage` | `player.Damage+AGE_DAMAGE*usage.age` | self-dependent |

| [characters/claude_chan.lua:266](../scripts/characters/claude_chan.lua#L266) | `player.Damage` | `player.Damage*LIMITED_DAMAGE_MULT` | self-dependent |

| [characters/claude_chan.lua:269](../scripts/characters/claude_chan.lua#L269) | `player.TearRange` | `player.TearRange+1.5*40` | self-dependent |

| [characters/claude_chan.lua:271](../scripts/characters/claude_chan.lua#L271) | `player.ShotSpeed` | `player.ShotSpeed+0.2` | self-dependent |

| [characters/claude_chan.lua:273](../scripts/characters/claude_chan.lua#L273) | `player.MoveSpeed` | `player.MoveSpeed-0.1` | self-dependent |

| [characters/claude_chan.lua:275](../scripts/characters/claude_chan.lua#L275) | `player.TearColor` | `Tint.Apply(player.TearColor,1,0.55,0.25,1)` | self-dependent |

| [characters/claude_chan.lua:314](../scripts/characters/claude_chan.lua#L314) | `tear.Color` | `Tint.Apply(tear.Color,0.5,0.5,0.5,0.7)` | self-dependent |



Risk state roots: `accountAge` direct write at L201; `accountAge` read/alias at L162; `claudeUsage` direct write at L156, L191; `claudeUsage` read/alias at L97, L136, L155.


Unresolved syntax: L108: dynamic field target requires manual review; L109: dynamic field target requires manual review; L124: dynamic field target requires manual review; L127: dynamic field target requires manual review; L132: dynamic field target requires manual review; L138: dynamic field target requires manual review; L143: dynamic field target requires manual review; L159: dynamic field target requires manual review; L287: dynamic field target requires manual review; L339: dynamic field target requires manual review; L355: dynamic field target requires manual review; L98: dynamic field target requires manual review; L99: dynamic field target requires manual review.


#### scripts/characters/claude_chan_b.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/claude_chan_b.lua:145](../scripts/characters/claude_chan_b.lua#L145)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/claude_chan_b.lua:155](../scripts/characters/claude_chan_b.lua#L155)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/claude_chan_b.lua:158](../scripts/characters/claude_chan_b.lua#L158)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/claude_chan_b.lua:165](../scripts/characters/claude_chan_b.lua#L165)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/claude_chan_b.lua:166](../scripts/characters/claude_chan_b.lua#L166)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/claude_chan_b.lua:209](../scripts/characters/claude_chan_b.lua#L209)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/claude_chan_b.lua:223](../scripts/characters/claude_chan_b.lua#L223)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/claude_chan_b.lua:256](../scripts/characters/claude_chan_b.lua#L256)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/claude_chan_b.lua:266](../scripts/characters/claude_chan_b.lua#L266)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [characters/claude_chan_b.lua:271](../scripts/characters/claude_chan_b.lua#L271)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/claude_chan_b.lua:276](../scripts/characters/claude_chan_b.lua#L276)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_RANGE`, `CACHE_SHOTSPEED`, `CACHE_TEARCOLOR`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/claude_chan_b.lua:228](../scripts/characters/claude_chan_b.lua#L228) | `player.Damage` | `player.Damage*(suspended and SUSPENDED_DAMAGE or DAMAGE_MULT)` | self-dependent |

| [characters/claude_chan_b.lua:230](../scripts/characters/claude_chan_b.lua#L230) | `player.TearRange` | `player.TearRange+1.5*40` | self-dependent |

| [characters/claude_chan_b.lua:232](../scripts/characters/claude_chan_b.lua#L232) | `player.ShotSpeed` | `player.ShotSpeed+0.2` | self-dependent |

| [characters/claude_chan_b.lua:236](../scripts/characters/claude_chan_b.lua#L236) | `player.TearColor` | `Color(c.R*k[1],c.G*k[2],c.B*k[3],c.A*k[4],c.RO,c.GO,c.BO)` | indirect |

| [characters/claude_chan_b.lua:237](../scripts/characters/claude_chan_b.lua#L237) | `player.TearColor` | `Color(k[1],k[2],k[3],k[4],0,0,0)` | indirect |



Risk state roots: `claudeAppeal` direct write at L88, L147; `claudeAppeal` read/alias at L69, L88, L89.


Unresolved syntax: L104: dynamic field target requires manual review; L107: dynamic field target requires manual review; L109: dynamic field target requires manual review; L111: dynamic field target requires manual review; L186: dynamic field target requires manual review; L215: dynamic field target requires manual review; L98: dynamic field target requires manual review; L99: dynamic field target requires manual review.


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


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/deepseek_peak.lua:119](../scripts/characters/deepseek_peak.lua#L119)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/deepseek_peak.lua:125](../scripts/characters/deepseek_peak.lua#L125)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/deepseek_peak.lua:128](../scripts/characters/deepseek_peak.lua#L128)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/deepseek_peak.lua:135](../scripts/characters/deepseek_peak.lua#L135)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/deepseek_peak.lua:136](../scripts/characters/deepseek_peak.lua#L136)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/deepseek_peak.lua:193](../scripts/characters/deepseek_peak.lua#L193)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/deepseek_peak.lua:277](../scripts/characters/deepseek_peak.lua#L277)), `ModCallbacks.MC_POST_LASER_UPDATE` (`default`, [characters/deepseek_peak.lua:283](../scripts/characters/deepseek_peak.lua#L283)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [characters/deepseek_peak.lua:286](../scripts/characters/deepseek_peak.lua#L286)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/deepseek_peak.lua:296](../scripts/characters/deepseek_peak.lua#L296)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/deepseek_peak.lua:315](../scripts/characters/deepseek_peak.lua#L315)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `deepseekPeak` direct write at L58, L121; `deepseekPeak` read/alias at L58, L59.


Unresolved syntax: L226: dynamic field target requires manual review; L238: dynamic field target requires manual review; L261: dynamic field target requires manual review; L49: dynamic field target requires manual review; L74: dynamic field target requires manual review; L75: dynamic field target requires manual review; L81: dynamic field target requires manual review; L84: dynamic field target requires manual review; L86: dynamic field target requires manual review; L88: dynamic field target requires manual review.


#### scripts/characters/deepseek_rice.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/deepseek_rice.lua:98](../scripts/characters/deepseek_rice.lua#L98)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/deepseek_rice.lua:109](../scripts/characters/deepseek_rice.lua#L109)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/deepseek_rice.lua:112](../scripts/characters/deepseek_rice.lua#L112)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/deepseek_rice.lua:122](../scripts/characters/deepseek_rice.lua#L122)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/deepseek_rice.lua:123](../scripts/characters/deepseek_rice.lua#L123)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/deepseek_rice.lua:129](../scripts/characters/deepseek_rice.lua#L129)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/deepseek_rice.lua:141](../scripts/characters/deepseek_rice.lua#L141)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/deepseek_rice.lua:257](../scripts/characters/deepseek_rice.lua#L257)).


Cache flag references: `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/deepseek_rice.lua:126](../scripts/characters/deepseek_rice.lua#L126) | `p.MoveSpeed` | `p.MoveSpeed+0.15` | self-dependent |



Risk state roots: `deepseekRice` direct write at L25, L100; `deepseekRice` read/alias at L25, L26.


Unresolved syntax: L39: dynamic field target requires manual review; L44: dynamic field target requires manual review; L62: dynamic field target requires manual review; L65: dynamic field target requires manual review; L68: dynamic field target requires manual review; L70: dynamic field target requires manual review.


#### scripts/characters/dossiers.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/dossiers.lua:50](../scripts/characters/dossiers.lua#L50)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/dossiers.lua:51](../scripts/characters/dossiers.lua#L51)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/dossiers.lua:52](../scripts/characters/dossiers.lua#L52)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/dossiers.lua:74](../scripts/characters/dossiers.lua#L74) | `sprite.Scale` | `Vector(scale,scale)` | indirect |



Risk state roots: none detected.


#### scripts/characters/doubao_again.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/doubao_again.lua:88](../scripts/characters/doubao_again.lua#L88)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/doubao_again.lua:94](../scripts/characters/doubao_again.lua#L94)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/doubao_again.lua:97](../scripts/characters/doubao_again.lua#L97)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/doubao_again.lua:101](../scripts/characters/doubao_again.lua#L101)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/doubao_again.lua:102](../scripts/characters/doubao_again.lua#L102)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/doubao_again.lua:137](../scripts/characters/doubao_again.lua#L137)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/doubao_again.lua:146](../scripts/characters/doubao_again.lua#L146)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/doubao_again.lua:155](../scripts/characters/doubao_again.lua#L155)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/doubao_again.lua:162](../scripts/characters/doubao_again.lua#L162)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/doubao_again.lua:159](../scripts/characters/doubao_again.lua#L159) | `p.Damage` | `p.Damage*CONFIDENT_DAMAGE` | self-dependent |

| [characters/doubao_again.lua:160](../scripts/characters/doubao_again.lua#L160) | `p.Damage` | `p.Damage*APOLOGY_DAMAGE` | self-dependent |



Risk state roots: `doubaoAgain` direct write at L33, L90; `doubaoAgain` read/alias at L33, L34.


Unresolved syntax: L47: dynamic field target requires manual review; L48: dynamic field target requires manual review; L53: dynamic field target requires manual review; L55: dynamic field target requires manual review; L57: dynamic field target requires manual review; L59: dynamic field target requires manual review.


#### scripts/characters/doubao_apology.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/doubao_apology.lua:116](../scripts/characters/doubao_apology.lua#L116)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/doubao_apology.lua:121](../scripts/characters/doubao_apology.lua#L121)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/doubao_apology.lua:124](../scripts/characters/doubao_apology.lua#L124)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/doubao_apology.lua:132](../scripts/characters/doubao_apology.lua#L132)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/doubao_apology.lua:158](../scripts/characters/doubao_apology.lua#L158)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/doubao_apology.lua:172](../scripts/characters/doubao_apology.lua#L172)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `doubaoApology` direct write at L39, L118; `doubaoApology` read/alias at L39, L40.


Unresolved syntax: L53: dynamic field target requires manual review; L54: dynamic field target requires manual review; L60: dynamic field target requires manual review; L62: dynamic field target requires manual review; L64: dynamic field target requires manual review; L66: dynamic field target requires manual review.


#### scripts/characters/drop_tap.lua


Callbacks: none detected.


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L43: dynamic field target requires manual review; L54: dynamic field target requires manual review.


#### scripts/characters/feedback.lua


Callbacks: none detected.


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/feedback.lua:11](../scripts/characters/feedback.lua#L11) | `effect.Color` | `color` | indirect |



Mutator calls: `SetColor` ([characters/feedback.lua:16](../scripts/characters/feedback.lua#L16)).


Risk state roots: none detected.


#### scripts/characters/gemini_edit.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/gemini_edit.lua:85](../scripts/characters/gemini_edit.lua#L85)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/gemini_edit.lua:91](../scripts/characters/gemini_edit.lua#L91)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/gemini_edit.lua:94](../scripts/characters/gemini_edit.lua#L94)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/gemini_edit.lua:100](../scripts/characters/gemini_edit.lua#L100)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/gemini_edit.lua:135](../scripts/characters/gemini_edit.lua#L135)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/gemini_edit.lua:141](../scripts/characters/gemini_edit.lua#L141)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/gemini_edit.lua:160](../scripts/characters/gemini_edit.lua#L160)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/gemini_edit.lua:163](../scripts/characters/gemini_edit.lua#L163)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/gemini_edit.lua:161](../scripts/characters/gemini_edit.lua#L161) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `geminiEdit` direct write at L37, L87; `geminiEdit` read/alias at L37, L38.


Unresolved syntax: L150: dynamic field target requires manual review; L51: dynamic field target requires manual review; L52: dynamic field target requires manual review; L57: dynamic field target requires manual review; L59: dynamic field target requires manual review; L61: dynamic field target requires manual review; L63: dynamic field target requires manual review.


#### scripts/characters/gemini_paint.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/gemini_paint.lua:102](../scripts/characters/gemini_paint.lua#L102)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/gemini_paint.lua:108](../scripts/characters/gemini_paint.lua#L108)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/gemini_paint.lua:111](../scripts/characters/gemini_paint.lua#L111)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/gemini_paint.lua:118](../scripts/characters/gemini_paint.lua#L118)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/gemini_paint.lua:119](../scripts/characters/gemini_paint.lua#L119)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/gemini_paint.lua:156](../scripts/characters/gemini_paint.lua#L156)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/gemini_paint.lua:167](../scripts/characters/gemini_paint.lua#L167)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [characters/gemini_paint.lua:181](../scripts/characters/gemini_paint.lua#L181)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/gemini_paint.lua:201](../scripts/characters/gemini_paint.lua#L201)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/gemini_paint.lua:196](../scripts/characters/gemini_paint.lua#L196) | `effect.Color` | `Color(1,0.9,0.2,1,0.4,0.35,0)` | indirect |



Risk state roots: `geminiPaint` direct write at L44, L104; `geminiPaint` read/alias at L44, L45.


Unresolved syntax: L137: dynamic field target requires manual review; L162: dynamic field target requires manual review; L62: dynamic field target requires manual review; L63: dynamic field target requires manual review; L68: dynamic field target requires manual review; L71: dynamic field target requires manual review; L73: dynamic field target requires manual review; L75: dynamic field target requires manual review.


#### scripts/characters/glm_queue.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/glm_queue.lua:105](../scripts/characters/glm_queue.lua#L105)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/glm_queue.lua:111](../scripts/characters/glm_queue.lua#L111)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/glm_queue.lua:114](../scripts/characters/glm_queue.lua#L114)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/glm_queue.lua:126](../scripts/characters/glm_queue.lua#L126)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/glm_queue.lua:127](../scripts/characters/glm_queue.lua#L127)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/glm_queue.lua:161](../scripts/characters/glm_queue.lua#L161)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/glm_queue.lua:171](../scripts/characters/glm_queue.lua#L171)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/glm_queue.lua:176](../scripts/characters/glm_queue.lua#L176)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/glm_queue.lua:174](../scripts/characters/glm_queue.lua#L174) | `p.Damage` | `p.Damage*BONUS` | self-dependent |



Risk state roots: `glmQueue` direct write at L41, L107; `glmQueue` read/alias at L41, L42.


Unresolved syntax: L144: dynamic field target requires manual review; L147: dynamic field target requires manual review; L167: dynamic field target requires manual review; L63: dynamic field target requires manual review; L64: dynamic field target requires manual review; L69: dynamic field target requires manual review; L71: dynamic field target requires manual review; L73: dynamic field target requires manual review; L75: dynamic field target requires manual review.


#### scripts/characters/glm_retry.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/glm_retry.lua:94](../scripts/characters/glm_retry.lua#L94)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/glm_retry.lua:100](../scripts/characters/glm_retry.lua#L100)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/glm_retry.lua:103](../scripts/characters/glm_retry.lua#L103)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/glm_retry.lua:110](../scripts/characters/glm_retry.lua#L110)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/glm_retry.lua:111](../scripts/characters/glm_retry.lua#L111)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/glm_retry.lua:164](../scripts/characters/glm_retry.lua#L164)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/glm_retry.lua:167](../scripts/characters/glm_retry.lua#L167)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/glm_retry.lua:165](../scripts/characters/glm_retry.lua#L165) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `glmRetry` direct write at L35, L96; `glmRetry` read/alias at L35, L36.


Unresolved syntax: L45: dynamic field target requires manual review; L46: dynamic field target requires manual review; L51: dynamic field target requires manual review; L53: dynamic field target requires manual review; L55: dynamic field target requires manual review; L57: dynamic field target requires manual review.


#### scripts/characters/gpt_downgrade.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/gpt_downgrade.lua:109](../scripts/characters/gpt_downgrade.lua#L109)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/gpt_downgrade.lua:115](../scripts/characters/gpt_downgrade.lua#L115)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/gpt_downgrade.lua:118](../scripts/characters/gpt_downgrade.lua#L118)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/gpt_downgrade.lua:125](../scripts/characters/gpt_downgrade.lua#L125)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/gpt_downgrade.lua:126](../scripts/characters/gpt_downgrade.lua#L126)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/gpt_downgrade.lua:171](../scripts/characters/gpt_downgrade.lua#L171)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/gpt_downgrade.lua:181](../scripts/characters/gpt_downgrade.lua#L181)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/gpt_downgrade.lua:186](../scripts/characters/gpt_downgrade.lua#L186)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [characters/gpt_downgrade.lua:202](../scripts/characters/gpt_downgrade.lua#L202)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/gpt_downgrade.lua:212](../scripts/characters/gpt_downgrade.lua#L212)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/gpt_downgrade.lua:217](../scripts/characters/gpt_downgrade.lua#L217)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/gpt_downgrade.lua:215](../scripts/characters/gpt_downgrade.lua#L215) | `p.Damage` | `p.Damage*(b.state.verified and VERIFIED_DAMAGE or FALLBACK_DAMAGE)` | self-dependent |



Risk state roots: `gptRouting` direct write at L33, L111; `gptRouting` read/alias at L33, L34.


Unresolved syntax: L138: dynamic field target requires manual review; L177: dynamic field target requires manual review; L61: dynamic field target requires manual review; L62: dynamic field target requires manual review; L67: dynamic field target requires manual review; L70: dynamic field target requires manual review; L73: dynamic field target requires manual review; L75: dynamic field target requires manual review.


#### scripts/characters/gpt_reset.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/gpt_reset.lua:118](../scripts/characters/gpt_reset.lua#L118)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/gpt_reset.lua:124](../scripts/characters/gpt_reset.lua#L124)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/gpt_reset.lua:127](../scripts/characters/gpt_reset.lua#L127)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/gpt_reset.lua:133](../scripts/characters/gpt_reset.lua#L133)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/gpt_reset.lua:134](../scripts/characters/gpt_reset.lua#L134)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/gpt_reset.lua:160](../scripts/characters/gpt_reset.lua#L160)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/gpt_reset.lua:176](../scripts/characters/gpt_reset.lua#L176)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/gpt_reset.lua:183](../scripts/characters/gpt_reset.lua#L183)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [characters/gpt_reset.lua:188](../scripts/characters/gpt_reset.lua#L188)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/gpt_reset.lua:195](../scripts/characters/gpt_reset.lua#L195)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/gpt_reset.lua:200](../scripts/characters/gpt_reset.lua#L200)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/gpt_reset.lua:198](../scripts/characters/gpt_reset.lua#L198) | `p.Damage` | `p.Damage*FULL_SEND_DAMAGE` | self-dependent |



Risk state roots: `gptReset` direct write at L41, L120; `gptReset` read/alias at L41, L42.


Unresolved syntax: L146: dynamic field target requires manual review; L166: dynamic field target requires manual review; L63: dynamic field target requires manual review; L64: dynamic field target requires manual review; L69: dynamic field target requires manual review; L71: dynamic field target requires manual review; L73: dynamic field target requires manual review; L75: dynamic field target requires manual review.


#### scripts/characters/grok_check.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/grok_check.lua:97](../scripts/characters/grok_check.lua#L97)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/grok_check.lua:103](../scripts/characters/grok_check.lua#L103)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/grok_check.lua:106](../scripts/characters/grok_check.lua#L106)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/grok_check.lua:120](../scripts/characters/grok_check.lua#L120)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/grok_check.lua:121](../scripts/characters/grok_check.lua#L121)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/grok_check.lua:166](../scripts/characters/grok_check.lua#L166)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/grok_check.lua:171](../scripts/characters/grok_check.lua#L171)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [characters/grok_check.lua:193](../scripts/characters/grok_check.lua#L193)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/grok_check.lua:203](../scripts/characters/grok_check.lua#L203)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/grok_check.lua:210](../scripts/characters/grok_check.lua#L210)).


Cache flag references: `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/grok_check.lua:207](../scripts/characters/grok_check.lua#L207) | `p.MoveSpeed` | `p.MoveSpeed+VERIFIED_SPEED` | self-dependent |



Risk state roots: `grokCheck` direct write at L36, L99; `grokCheck` read/alias at L36, L37.


Unresolved syntax: L183: dynamic field target requires manual review; L54: dynamic field target requires manual review; L55: dynamic field target requires manual review; L60: dynamic field target requires manual review; L62: dynamic field target requires manual review; L64: dynamic field target requires manual review; L66: dynamic field target requires manual review.


#### scripts/characters/grok_ratio.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/grok_ratio.lua:101](../scripts/characters/grok_ratio.lua#L101)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/grok_ratio.lua:107](../scripts/characters/grok_ratio.lua#L107)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/grok_ratio.lua:110](../scripts/characters/grok_ratio.lua#L110)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/grok_ratio.lua:116](../scripts/characters/grok_ratio.lua#L116)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/grok_ratio.lua:160](../scripts/characters/grok_ratio.lua#L160)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/grok_ratio.lua:165](../scripts/characters/grok_ratio.lua#L165)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/grok_ratio.lua:178](../scripts/characters/grok_ratio.lua#L178)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/grok_ratio.lua:181](../scripts/characters/grok_ratio.lua#L181)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/grok_ratio.lua:179](../scripts/characters/grok_ratio.lua#L179) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `grokRatio` direct write at L40, L103; `grokRatio` read/alias at L40, L41.


Unresolved syntax: L51: dynamic field target requires manual review; L52: dynamic field target requires manual review; L57: dynamic field target requires manual review; L59: dynamic field target requires manual review; L62: dynamic field target requires manual review; L64: dynamic field target requires manual review.


#### scripts/characters/kimi_manager.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/kimi_manager.lua:114](../scripts/characters/kimi_manager.lua#L114)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/kimi_manager.lua:120](../scripts/characters/kimi_manager.lua#L120)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/kimi_manager.lua:123](../scripts/characters/kimi_manager.lua#L123)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/kimi_manager.lua:130](../scripts/characters/kimi_manager.lua#L130)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/kimi_manager.lua:131](../scripts/characters/kimi_manager.lua#L131)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [characters/kimi_manager.lua:183](../scripts/characters/kimi_manager.lua#L183)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/kimi_manager.lua:188](../scripts/characters/kimi_manager.lua#L188)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/kimi_manager.lua:199](../scripts/characters/kimi_manager.lua#L199)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/kimi_manager.lua:202](../scripts/characters/kimi_manager.lua#L202)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/kimi_manager.lua:200](../scripts/characters/kimi_manager.lua#L200) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `kimiManager` direct write at L48, L116; `kimiManager` read/alias at L48, L49.


Unresolved syntax: L174: dynamic field target requires manual review; L66: dynamic field target requires manual review; L67: dynamic field target requires manual review; L72: dynamic field target requires manual review; L74: dynamic field target requires manual review; L76: dynamic field target requires manual review; L78: dynamic field target requires manual review.


#### scripts/characters/kimi_slides.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/kimi_slides.lua:132](../scripts/characters/kimi_slides.lua#L132)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/kimi_slides.lua:138](../scripts/characters/kimi_slides.lua#L138)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/kimi_slides.lua:141](../scripts/characters/kimi_slides.lua#L141)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/kimi_slides.lua:148](../scripts/characters/kimi_slides.lua#L148)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/kimi_slides.lua:149](../scripts/characters/kimi_slides.lua#L149)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/kimi_slides.lua:190](../scripts/characters/kimi_slides.lua#L190)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [characters/kimi_slides.lua:201](../scripts/characters/kimi_slides.lua#L201)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/kimi_slides.lua:211](../scripts/characters/kimi_slides.lua#L211)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: `kimiSlides` direct write at L50, L134; `kimiSlides` read/alias at L50, L51.


Unresolved syntax: L110: dynamic field target requires manual review; L127: dynamic field target requires manual review; L167: dynamic field target requires manual review; L170: dynamic field target requires manual review; L196: dynamic field target requires manual review; L68: dynamic field target requires manual review; L69: dynamic field target requires manual review; L74: dynamic field target requires manual review; L76: dynamic field target requires manual review; L78: dynamic field target requires manual review; L80: dynamic field target requires manual review.


#### scripts/characters/llama_hype.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/llama_hype.lua:104](../scripts/characters/llama_hype.lua#L104)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/llama_hype.lua:110](../scripts/characters/llama_hype.lua#L110)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/llama_hype.lua:113](../scripts/characters/llama_hype.lua#L113)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/llama_hype.lua:119](../scripts/characters/llama_hype.lua#L119)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/llama_hype.lua:120](../scripts/characters/llama_hype.lua#L120)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/llama_hype.lua:158](../scripts/characters/llama_hype.lua#L158)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/llama_hype.lua:168](../scripts/characters/llama_hype.lua#L168)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/llama_hype.lua:171](../scripts/characters/llama_hype.lua#L171)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/llama_hype.lua:169](../scripts/characters/llama_hype.lua#L169) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `llamaHype` direct write at L41, L106; `llamaHype` read/alias at L41, L42.


Unresolved syntax: L138: dynamic field target requires manual review; L164: dynamic field target requires manual review; L59: dynamic field target requires manual review; L60: dynamic field target requires manual review; L65: dynamic field target requires manual review; L67: dynamic field target requires manual review; L69: dynamic field target requires manual review; L71: dynamic field target requires manual review.


#### scripts/characters/llama_release.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/llama_release.lua:104](../scripts/characters/llama_release.lua#L104)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/llama_release.lua:110](../scripts/characters/llama_release.lua#L110)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/llama_release.lua:113](../scripts/characters/llama_release.lua#L113)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/llama_release.lua:119](../scripts/characters/llama_release.lua#L119)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/llama_release.lua:120](../scripts/characters/llama_release.lua#L120)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/llama_release.lua:144](../scripts/characters/llama_release.lua#L144)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/llama_release.lua:158](../scripts/characters/llama_release.lua#L158)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/llama_release.lua:161](../scripts/characters/llama_release.lua#L161)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/llama_release.lua:159](../scripts/characters/llama_release.lua#L159) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `llamaRelease` direct write at L39, L106; `llamaRelease` read/alias at L39, L40.


Unresolved syntax: L131: dynamic field target requires manual review; L150: dynamic field target requires manual review; L57: dynamic field target requires manual review; L58: dynamic field target requires manual review; L63: dynamic field target requires manual review; L65: dynamic field target requires manual review; L67: dynamic field target requires manual review; L69: dynamic field target requires manual review.


#### scripts/characters/mistral_baguette.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/mistral_baguette.lua:102](../scripts/characters/mistral_baguette.lua#L102)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/mistral_baguette.lua:110](../scripts/characters/mistral_baguette.lua#L110)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/mistral_baguette.lua:113](../scripts/characters/mistral_baguette.lua#L113)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/mistral_baguette.lua:119](../scripts/characters/mistral_baguette.lua#L119)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/mistral_baguette.lua:120](../scripts/characters/mistral_baguette.lua#L120)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/mistral_baguette.lua:157](../scripts/characters/mistral_baguette.lua#L157)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/mistral_baguette.lua:162](../scripts/characters/mistral_baguette.lua#L162)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/mistral_baguette.lua:159](../scripts/characters/mistral_baguette.lua#L159) | `p.MoveSpeed` | `p.MoveSpeed+SPEED` | self-dependent |

| [characters/mistral_baguette.lua:160](../scripts/characters/mistral_baguette.lua#L160) | `p.Damage` | `p.Damage*BASE_DAMAGE` | self-dependent |



Risk state roots: `mistralBaguette` direct write at L39, L104; `mistralBaguette` read/alias at L39, L40.


Unresolved syntax: L49: dynamic field target requires manual review; L50: dynamic field target requires manual review; L55: dynamic field target requires manual review; L57: dynamic field target requires manual review; L59: dynamic field target requires manual review; L61: dynamic field target requires manual review; L95: dynamic field target requires manual review.


#### scripts/characters/mistral_pounce.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/mistral_pounce.lua:105](../scripts/characters/mistral_pounce.lua#L105)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/mistral_pounce.lua:111](../scripts/characters/mistral_pounce.lua#L111)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/mistral_pounce.lua:114](../scripts/characters/mistral_pounce.lua#L114)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/mistral_pounce.lua:118](../scripts/characters/mistral_pounce.lua#L118)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/mistral_pounce.lua:163](../scripts/characters/mistral_pounce.lua#L163)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/mistral_pounce.lua:166](../scripts/characters/mistral_pounce.lua#L166)).


Cache flag references: `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/mistral_pounce.lua:164](../scripts/characters/mistral_pounce.lua#L164) | `p.MoveSpeed` | `p.MoveSpeed+SPEED` | self-dependent |



Risk state roots: `mistralPounce` direct write at L37, L107; `mistralPounce` read/alias at L37, L38.


Unresolved syntax: L47: dynamic field target requires manual review; L48: dynamic field target requires manual review; L54: dynamic field target requires manual review; L56: dynamic field target requires manual review; L58: dynamic field target requires manual review; L60: dynamic field target requires manual review.


#### scripts/characters/model_roster.lua


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/model_roster.lua:73](../scripts/characters/model_roster.lua#L73)).


Cache flag references: `CACHE_TEARCOLOR`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/model_roster.lua:79](../scripts/characters/model_roster.lua#L79) | `p.TearColor` | `Color(c.R*k[1],c.G*k[2],c.B*k[3],c.A,c.RO,c.GO,c.BO)` | indirect |

| [characters/model_roster.lua:80](../scripts/characters/model_roster.lua#L80) | `p.TearColor` | `Color(k[1],k[2],k[3],1,0,0,0)` | indirect |



Risk state roots: none detected.


#### scripts/characters/paid_attacks.lua


Callbacks: `ModCallbacks.MC_POST_LASER_INIT` (`default`, [characters/paid_attacks.lua:67](../scripts/characters/paid_attacks.lua#L67)), `ModCallbacks.MC_POST_LASER_UPDATE` (`default`, [characters/paid_attacks.lua:70](../scripts/characters/paid_attacks.lua#L70)), `ModCallbacks.MC_POST_TEAR_UPDATE` (`default`, [characters/paid_attacks.lua:87](../scripts/characters/paid_attacks.lua#L87)), `ModCallbacks.MC_POST_KNIFE_UPDATE` (`default`, [characters/paid_attacks.lua:93](../scripts/characters/paid_attacks.lua#L93)), `ModCallbacks.MC_POST_EFFECT_UPDATE` (`default`, [characters/paid_attacks.lua:103](../scripts/characters/paid_attacks.lua#L103)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/paid_attacks.lua:108](../scripts/characters/paid_attacks.lua#L108)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/paid_attacks.lua:109](../scripts/characters/paid_attacks.lua#L109)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/paid_attacks.lua:110](../scripts/characters/paid_attacks.lua#L110)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L46: dynamic field target requires manual review; L56: dynamic field target requires manual review; L62: dynamic field target requires manual review; L99: dynamic field target requires manual review.


#### scripts/characters/qwen_adapter.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/qwen_adapter.lua:116](../scripts/characters/qwen_adapter.lua#L116)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/qwen_adapter.lua:122](../scripts/characters/qwen_adapter.lua#L122)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/qwen_adapter.lua:125](../scripts/characters/qwen_adapter.lua#L125)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/qwen_adapter.lua:139](../scripts/characters/qwen_adapter.lua#L139)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/qwen_adapter.lua:140](../scripts/characters/qwen_adapter.lua#L140)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/qwen_adapter.lua:186](../scripts/characters/qwen_adapter.lua#L186)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/qwen_adapter.lua:200](../scripts/characters/qwen_adapter.lua#L200)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/qwen_adapter.lua:212](../scripts/characters/qwen_adapter.lua#L212)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_FIREDELAY`, `CACHE_RANGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/qwen_adapter.lua:205](../scripts/characters/qwen_adapter.lua#L205) | `p.TearRange` | `p.TearRange+RANGE_BONUS` | self-dependent |

| [characters/qwen_adapter.lua:207](../scripts/characters/qwen_adapter.lua#L207) | `p.MaxFireDelay` | `FireRate.ScaleInterval(p.MaxFireDelay,TEMPO_INTERVAL)` | self-dependent |

| [characters/qwen_adapter.lua:209](../scripts/characters/qwen_adapter.lua#L209) | `p.Damage` | `p.Damage*POWER_DAMAGE` | self-dependent |



Risk state roots: `qwenAdapter` direct write at L50, L118; `qwenAdapter` read/alias at L50, L51.


Unresolved syntax: L172: dynamic field target requires manual review; L175: dynamic field target requires manual review; L192: dynamic field target requires manual review; L72: dynamic field target requires manual review; L73: dynamic field target requires manual review; L82: dynamic field target requires manual review; L84: dynamic field target requires manual review; L86: dynamic field target requires manual review; L88: dynamic field target requires manual review.


#### scripts/characters/qwen_finetune.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [characters/qwen_finetune.lua:114](../scripts/characters/qwen_finetune.lua#L114)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [characters/qwen_finetune.lua:120](../scripts/characters/qwen_finetune.lua#L120)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [characters/qwen_finetune.lua:123](../scripts/characters/qwen_finetune.lua#L123)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [characters/qwen_finetune.lua:129](../scripts/characters/qwen_finetune.lua#L129)), `ModCallbacks.MC_POST_UPDATE` (`default`, [characters/qwen_finetune.lua:130](../scripts/characters/qwen_finetune.lua#L130)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [characters/qwen_finetune.lua:154](../scripts/characters/qwen_finetune.lua#L154)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [characters/qwen_finetune.lua:172](../scripts/characters/qwen_finetune.lua#L172)), `ModCallbacks.MC_POST_RENDER` (`default`, [characters/qwen_finetune.lua:183](../scripts/characters/qwen_finetune.lua#L183)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_FIREDELAY`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [characters/qwen_finetune.lua:178](../scripts/characters/qwen_finetune.lua#L178) | `p.Damage` | `(p.Damage+s.awards*per)*build.damage` | self-dependent |

| [characters/qwen_finetune.lua:180](../scripts/characters/qwen_finetune.lua#L180) | `p.MaxFireDelay` | `FireRate.ScaleInterval(p.MaxFireDelay,build.interval)` | self-dependent |



Risk state roots: `qwenFineTune` direct write at L45, L116; `qwenFineTune` read/alias at L45, L46.


Unresolved syntax: L141: dynamic field target requires manual review; L160: dynamic field target requires manual review; L67: dynamic field target requires manual review; L68: dynamic field target requires manual review; L74: dynamic field target requires manual review; L76: dynamic field target requires manual review; L78: dynamic field target requires manual review; L80: dynamic field target requires manual review.


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


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/backlog/common.lua:249](../scripts/items/backlog/common.lua#L249)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/backlog/common.lua:380](../scripts/items/backlog/common.lua#L380)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [items/backlog/common.lua:391](../scripts/items/backlog/common.lua#L391)), `ModCallbacks.MC_POST_LASER_UPDATE` (`default`, [items/backlog/common.lua:396](../scripts/items/backlog/common.lua#L396)), `ModCallbacks.MC_POST_KNIFE_UPDATE` (`default`, [items/backlog/common.lua:402](../scripts/items/backlog/common.lua#L402)), `ModCallbacks.MC_POST_BOMB_UPDATE` (`default`, [items/backlog/common.lua:411](../scripts/items/backlog/common.lua#L411)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [items/backlog/common.lua:464](../scripts/items/backlog/common.lua#L464)), `ModCallbacks.MC_POST_ENTITY_KILL` (`default`, [items/backlog/common.lua:521](../scripts/items/backlog/common.lua#L521)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/backlog/common.lua:554](../scripts/items/backlog/common.lua#L554)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/backlog/common.lua:565](../scripts/items/backlog/common.lua#L565)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [items/backlog/common.lua:572](../scripts/items/backlog/common.lua#L572)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [items/backlog/common.lua:587](../scripts/items/backlog/common.lua#L587)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [items/backlog/common.lua:606](../scripts/items/backlog/common.lua#L606)), `ModCallbacks.MC_PRE_USE_ITEM` (`default`, [items/backlog/common.lua:622](../scripts/items/backlog/common.lua#L622)), `ModCallbacks.MC_POST_UPDATE` (`default`, [items/backlog/common.lua:634](../scripts/items/backlog/common.lua#L634)), `ModCallbacks.MC_POST_RENDER` (`default`, [items/backlog/common.lua:663](../scripts/items/backlog/common.lua#L663)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_RANGE`, `CACHE_SHOTSPEED`, `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/backlog/common.lua:253](../scripts/items/backlog/common.lua#L253) | `player.Damage` | `player.Damage*m` | self-dependent |

| [items/backlog/common.lua:257](../scripts/items/backlog/common.lua#L257) | `player.MoveSpeed` | `player.MoveSpeed+add` | self-dependent |

| [items/backlog/common.lua:261](../scripts/items/backlog/common.lua#L261) | `player.TearRange` | `player.TearRange+add` | self-dependent |

| [items/backlog/common.lua:265](../scripts/items/backlog/common.lua#L265) | `player.ShotSpeed` | `player.ShotSpeed+add` | self-dependent |



Risk state roots: `backlog` direct write at L206; `backlog` read/alias at L186, L608, L611.


Unresolved syntax: L132: dynamic field target requires manual review; L193: dynamic field target requires manual review; L210: dynamic field target requires manual review; L273: dynamic field target requires manual review; L282: dynamic field target requires manual review; L296: dynamic field target requires manual review; L299: dynamic field target requires manual review; L300: dynamic field target requires manual review; L316: dynamic field target requires manual review; L323: dynamic field target requires manual review; L331: dynamic field target requires manual review; L444: dynamic field target requires manual review; L534: dynamic field target requires manual review; L549: dynamic field target requires manual review; L618: dynamic field target requires manual review; L97: dynamic field target requires manual review.


#### scripts/items/backlog/deepseek.lua


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/deepseek.lua:27](../scripts/items/backlog/deepseek.lua#L27)), `ModCallbacks.MC_PRE_PICKUP_COLLISION` (`default`, [items/backlog/deepseek.lua:60](../scripts/items/backlog/deepseek.lua#L60)), `ModCallbacks.MC_USE_ITEM` (`default`, [items/backlog/deepseek.lua:90](../scripts/items/backlog/deepseek.lua#L90)).


Cache flag references: none detected.


Direct tracked-field writes: none detected.


Risk state roots: none detected.


Unresolved syntax: L74: dynamic field target requires manual review; L84: dynamic field target requires manual review.


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


Unresolved syntax: L113: dynamic field target requires manual review; L120: dynamic field target requires manual review; L128: dynamic field target requires manual review; L43: dynamic field target requires manual review; L44: dynamic field target requires manual review; L75: dynamic field target requires manual review; L82: dynamic field target requires manual review.


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


Unresolved syntax: L106: dynamic field target requires manual review; L115: dynamic field target requires manual review; L74: multiple assignment requires manual mapping.


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


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/constitution.lua:98](../scripts/items/constitution.lua#L98)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/constitution.lua:103](../scripts/items/constitution.lua#L103)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [items/constitution.lua:106](../scripts/items/constitution.lua#L106)), `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [items/constitution.lua:113](../scripts/items/constitution.lua#L113)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`default`, [items/constitution.lua:122](../scripts/items/constitution.lua#L122)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/constitution.lua:137](../scripts/items/constitution.lua#L137)).


Cache flag references: `CACHE_DAMAGE`, `CACHE_SPEED`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/constitution.lua:141](../scripts/items/constitution.lua#L141) | `player.Damage` | `player.Damage*DAMAGE_MULT` | self-dependent |

| [items/constitution.lua:143](../scripts/items/constitution.lua#L143) | `player.MoveSpeed` | `player.MoveSpeed-SPEED_DOWN` | self-dependent |



Risk state roots: `constitution` direct write at L66; `constitution` read/alias at L45; `constitutionApplied` read/alias at L61, L67; `constitutionBlockUsed` direct write at L67; `constitutionBlockUsed` read/alias at L62.


Unresolved syntax: L60: dynamic field target requires manual review; L92: dynamic field target requires manual review; L93: dynamic field target requires manual review.


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


Risk state roots: `memeExtras` direct write at L43; `memeExtras` read/alias at L27.


Unresolved syntax: L47: dynamic field target requires manual review.


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


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/opus_mode.lua:29](../scripts/items/opus_mode.lua#L29)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/opus_mode.lua:30](../scripts/items/opus_mode.lua#L30)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/opus_mode.lua:68](../scripts/items/opus_mode.lua#L68)), `ModCallbacks.MC_POST_LASER_INIT` (`default`, [items/opus_mode.lua:76](../scripts/items/opus_mode.lua#L76)), `ModCallbacks.MC_POST_BOMB_INIT` (`default`, [items/opus_mode.lua:81](../scripts/items/opus_mode.lua#L81)), `ModCallbacks.MC_POST_PEFFECT_UPDATE` (`default`, [items/opus_mode.lua:87](../scripts/items/opus_mode.lua#L87)), `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [items/opus_mode.lua:101](../scripts/items/opus_mode.lua#L101)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/opus_mode.lua:105](../scripts/items/opus_mode.lua#L105) | `player.Damage` | `player.Damage*mult` | self-dependent |



Risk state roots: `opusTears` direct write at L35; `opusTears` read/alias at L35, L36.


Unresolved syntax: L62: dynamic field target requires manual review.


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


Callbacks: `ModCallbacks.MC_USE_ITEM` (`default`, [items/tests_passing.lua:19](../scripts/items/tests_passing.lua#L19)).


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


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [items/vibe_coding.lua:35](../scripts/items/vibe_coding.lua#L35)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [items/vibe_coding.lua:41](../scripts/items/vibe_coding.lua#L41)), `ModCallbacks.MC_POST_FIRE_TEAR` (`default`, [items/vibe_coding.lua:46](../scripts/items/vibe_coding.lua#L46)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`CallbackPriority.LATE`, [items/vibe_coding.lua:61](../scripts/items/vibe_coding.lua#L61)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [items/vibe_coding.lua:75](../scripts/items/vibe_coding.lua#L75)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [items/vibe_coding.lua:53](../scripts/items/vibe_coding.lua#L53) | `tear.Velocity` | `tear.Velocity*-1` | self-dependent |



Mutator calls: `AddTearFlags` ([items/vibe_coding.lua:55](../scripts/items/vibe_coding.lua#L55)).


Risk state roots: `vibeMistakes` direct write at L30, L91; `vibeMistakes` read/alias at L30, L31, L32.


#### scripts/meal_break.lua


Callbacks: `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [meal_break.lua:94](../scripts/meal_break.lua#L94)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [meal_break.lua:106](../scripts/meal_break.lua#L106)), `ModCallbacks.MC_POST_UPDATE` (`default`, [meal_break.lua:110](../scripts/meal_break.lua#L110)), `ModCallbacks.MC_INPUT_ACTION` (`default`, [meal_break.lua:132](../scripts/meal_break.lua#L132)).


Cache flag references: none detected.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [meal_break.lua:57](../scripts/meal_break.lua#L57) | `player.FireDelay` | `math.max(player.FireDelay,remaining)` | self-dependent |

| [meal_break.lua:88](../scripts/meal_break.lua#L88) | `player.FireDelay` | `math.min(player.FireDelay,b.state.priorDelay or 0)` | self-dependent |



Risk state roots: `mealBreaks` direct write at L15, L96; `mealBreaks` read/alias at L15, L16.


Unresolved syntax: L34: dynamic field target requires manual review; L36: dynamic field target requires manual review; L46: dynamic field target requires manual review; L47: dynamic field target requires manual review; L49: dynamic field target requires manual review.


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


Callbacks: `ModCallbacks.MC_EVALUATE_CACHE` (`default`, [risk.lua:195](../scripts/risk.lua#L195)), `ModCallbacks.MC_POST_GAME_STARTED` (`default`, [risk.lua:201](../scripts/risk.lua#L201)), `ModCallbacks.MC_PRE_GAME_EXIT` (`default`, [risk.lua:213](../scripts/risk.lua#L213)), `ModCallbacks.MC_POST_NEW_LEVEL` (`default`, [risk.lua:222](../scripts/risk.lua#L222)), `ModCallbacks.MC_POST_UPDATE` (`default`, [risk.lua:232](../scripts/risk.lua#L232)), `ModCallbacks.MC_POST_NEW_ROOM` (`default`, [risk.lua:239](../scripts/risk.lua#L239)), `ModCallbacks.MC_ENTITY_TAKE_DMG` (`CallbackPriority.LATE`, [risk.lua:244](../scripts/risk.lua#L244)), `ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD` (`default`, [risk.lua:251](../scripts/risk.lua#L251)), `ModCallbacks.MC_POST_RENDER` (`default`, [risk.lua:257](../scripts/risk.lua#L257)).


Cache flag references: `CACHE_DAMAGE`.


| Location | Target | RHS | Classification |
|---|---|---|---|

| [risk.lua:197](../scripts/risk.lua#L197) | `player.Damage` | `player.Damage*SUSPENDED_DAMAGE_MULT` | self-dependent |



Risk state roots: `[dynamic]` direct write at L188; `[whole table]` direct write at L32, L183, L207; `[whole table]` read/alias at L179; `ip` direct write at L165; `ip` read/alias at L267; `risk` direct write at L132, L136; `risk` read/alias at L93, L132, L150, L271; `sharedUsers` direct write at L173; `sharedUsers` read/alias at L267.


Unresolved syntax: L188: dynamic field target requires manual review.


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
