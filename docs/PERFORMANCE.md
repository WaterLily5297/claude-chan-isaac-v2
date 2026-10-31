# Offline performance measurements

## Live Wire observation budget (2026-10-31)

This U4 unit compares v2 main `3949af70fe30bf1411684513de6a19be1a67b5de` with a focused Live Wire optimization. The item needs a yes/no answer, but previously enumerated the room and sorted matching bullets separately for every holder on each fifth update. It now stops on the first eligible nearby bullet and shares the room enumeration among holders within that update. The list is local to that callback and is discarded after any Live Wire cache refresh: synchronous cache callbacks may create/remove projectiles before the next owner is observed. Eligibility and position are still checked for each owner. No global or cross-frame entity cache is introduced.

The existing ordinary-bullet predicate, inclusive 100-unit radius, five-frame cadence, +0.15 speed, non-stacking rule, owner order and cache-on-change behavior are preserved. Other users of the sorted `Common.Bullets` service remain unchanged. This is a measured performance improvement, not a newly claimed gameplay defect; no balance, save format, weapon, billing or art rule changes.

```sh
texlua tests/full_mod_live_wire_test.lua .
texlua tools/profile_mod_updates.lua . 180 wire_4_96
texlua tools/profile_mod_updates.lua . 180 mixed_items_four
```

The profiler adds six stable Live Wire workloads (one/four vanilla holders with 0/12/96 supplied bullets) to its previous 27 scenarios. Each new case has 48 enemies plus a separate bullet spawner; holders stand 150 units apart. A five-frame warmup settles speed transitions before measurement. All 33 scenarios complete. Export the baseline Grok module outside the repository and pass its path as the fifth argument after `-` for an omitted Gemini override to repeat the before/after comparison.

| Supplied workload, 180 updates | Room queries before / after | Fixture entries before / after | Heap KiB before / after |
|---|---:|---:|---:|
| One holder, no bullets | 36 / 36 | 1764 / 1764 | 1491.396 / 1487.428 |
| One holder, 12 bullets | 36 / 36 | 2196 / 2196 | 1602.209 / 1491.646 |
| One holder, 96 bullets | 36 / 36 | 5220 / 5220 | 2481.959 / 1599.646 |
| Four holders, no bullets | 144 / 36 | 7056 / 1764 | 4159.053 / 4029.365 |
| Four holders, 12 bullets | 144 / 36 | 8784 / 2196 | 4423.428 / 4071.553 |
| Four holders, 96 bullets | 144 / 36 | 20880 / 5220 | 6690.303 / 4179.553 |
| Four mixed forms, all item IDs, Preview and DROP | 180 / 72 | 10200 / 4080 | 4729.075 / 4599.388 |

The mixed workload retains 36 Preview scans and now makes 36 Live Wire scans; it still includes the real Kimi/GLM scheduled callbacks. It executes 17,700 callbacks and four cache rebuilds. Callback/player/type-read/cache counts match before and after for every compared workload. These current-baseline numbers supersede neither the older Preview comparison nor its original source/fixture checkpoint.

Heap growth is GC-stopped allocation pressure under local Lua 5.3, including stand-in query copies; it is not retained memory or native FPS. Fixture entries count room snapshots, not every predicate iteration or the engine's spatial work. Frequent speed transitions can still require one query per holder because cache callbacks invalidate the observation. No portable CPU/heap threshold is added to CI.

### Regression and handoff

The new automatically discovered [full-entry suite](../tests/full_mod_live_wire_test.lua) covers all 22 forms with a separate vanilla owner, unchanged cadence, exact radius, movement, removal and one-time speed changes. It also preserves ten projectile exclusions and the existing acceptance of non-friendly dead/invulnerable NPC spawners; the latter is current predicate behavior, not a new rule. Item removal/reacquisition, multiple copies, room replacement, detached Continue and restart are supplied explicitly. Four cache-callback controls spawn/remove/move/change allegiance of bullets before the next owner is sampled.

Six steady-population cases assert one query per refresh regardless of holder count, zero queries without holders and no repeated stable-state cache rebuilds. The baseline passes the complete behavior selector but intentionally fails the budget. An isolated current-source control passes; seven source faults are rejected: missing post-cache invalidation, retaining the snapshot across updates, exclusive radius, skipped eligibility, per-owner query, missing speed refresh and wrong owner position. Existing full-entry Preview, backlog item and lifecycle controls pass.

This section, TESTING and CHARACTER_COMPLETION provide the focused handoff while PR #2 protects consolidated HANDOFF/CHANGELOG edits. The interaction fingerprint is refreshed. PR #2/draft #7, all artwork, approved tainted designs and installed `8fd6a8c` are unchanged. No game, input, installation, owner save/settings or Workshop action occurs. Native projectile/callback lifetime, collector/frame-time behavior, full combat/familiar workloads and long-run/error isolation remain open. This is the first substantive unit since PR #31 hardening; retain the three-to-five-unit review cadence.

## Full entry-point update workloads and Preview scans (2026-10-30)

U4 follow-up from v2 main `1e20c4c`. The earlier two-binder measurement below remains valid within its original scope. This unit loads the real `main.lua` and measures supplied update/render workloads through all registered modules:

```sh
texlua tools/profile_mod_updates.lua . 180
texlua tools/profile_mod_updates.lua . 180 preview_four
texlua tests/full_mod_update_budget_test.lua .
```

The profiler has 27 scenarios: vanilla, each of 22 forms, four mixed forms, one/four Preview users, and four mixed forms carrying all 80 registered collectible IDs. Individual forms have 12 enemies; four-player and Preview workloads have 48. The mixed-item case uses Unchanged Preview and one supplied DROP gesture per player, including actual Kimi task and GLM request loops. It does not activate or exercise every held item. Preview is used once and expires after its existing 180-frame lifetime, so longer measurement intervals include later idle time.

`tests/lib/full_mod_env.lua` supplies explicit engine stand-ins and loads every production module through the entry point, including the real Risk and meal services. It dispatches POST_UPDATE, each player's PEFFECT/PLAYER_UPDATE and POST_RENDER in a documented fixture sequence, preserving registered priority/filter order and nested damage callbacks. Other events run only when explicitly supplied by setup/abilities. It does not synthesize all weapon, NPC, input, physics or native rendering callbacks. Optional EID and Reactions are absent; MAP is not held. Engine object accessors are cached before measurement, while query result arrays are copied to represent their visible Lua allocation. Missing API methods fail rather than becoming automatic no-ops.

The counters record executed callbacks, player/type reads, room/type/radius queries, cache rebuilds and fixture entity entries examined. Scan attribution identifies the registered callback source; a family listener dispatched by the shared backlog service is attributed to `common.lua`. The fixture's linear radius/type search is not evidence about the native engine's spatial indexing. GC-stopped heap growth includes instrumented Lua, query-array copies and other stand-in allocations; it is allocation pressure, not retained memory or a leak. Printed CPU time is diagnostic only. Neither heap nor timing is a portable CI threshold or a native FPS claim.

### Measured hotspot and source change

Unchanged Preview previously called `Common.Nearby` for each live marker, enumerating and sorting enemies twice per owner on every fifth frame. The update now lazily collects the eligible enemy list once for all Preview owners in that callback and selects each owner's nearest marker directly. The list never survives the callback, and owner iteration order, the first marker on an equal-distance tie, the inclusive 200-unit radius, exclusions and five-frame cadence remain. Dead/removed markers, replacement and room/run cleanup keep their existing behavior. No duration, balance, save or native weapon field changes.

The following before/after measurements use the same full fixture and 180 updates under Lua 5.3 (`texlua`). The baseline substitutes only `scripts/items/backlog/gemini.lua` exported from `1e20c4c`; the fourth profiler argument accepts that exported module path.

| Workload | Queries before / after | Fixture entries before / after | Heap KiB before / after |
|---|---:|---:|---:|
| One Preview user, 48 enemies | 72 / 36 | 3600 / 1800 | 3450.733 / 1602.819 |
| Four Preview users, 48 enemies | 288 / 36 | 16128 / 2016 | 12212.928 / 4593.764 |
| Four forms, all collectible IDs, Preview and DROP | 432 / 180 | 24480 / 10200 | 12428.208 / 4809.114 |

The mixed case retains 144 Live Wire bullet queries (four holders, every fifth frame); this unit does not cache those separate observations. It executes 17,540 callbacks and four cache rebuilds during measurement, with scheduled Kimi/GLM damage retained. Callback/player/type-read counts are identical before and after in all three compared workloads.

For context, the 180-frame idle-form scenarios made zero entity queries and allocated 1478.329-1571.858 KiB each in the fixture. Vanilla allocated 1470.289 KiB; four idle forms allocated 4317.323 KiB. Most solo cases ran 12,060 callbacks, with one normal-Qwen cache refresh adding 280. These measurements expose whole-entry-point idle/update overhead but do not complete the whole-mod performance budget for combat, large projectile/familiar populations or long runs.

### Regression and acceptance

The new gate fixture runs all 22 idle forms with real entry-point registration, then one/four Preview owners with 0/12/96 enemies. It requires one room enumeration per five-frame refresh independent of marker/owner count, zero queries after expiry/room cleanup, and the actual nearby target effect. Its scan-budget assertion fails against the exported baseline; the separate behavior mode passes on both baseline and revised code.

Target controls check closest marker, ties, inclusive radius, bosses, friendly/invulnerable/dead enemies, newly spawned enemies, marker movement/removal and reuse. The mixed-item control arms the real Kimi task loop, observes Kimi/GLM damage and checks finite cache values. Existing backlog item/lifecycle fixtures remain active. The assertions are not native AI or all-item compatibility acceptance.

The 27-scenario profiler, baseline comparison/behavior controls, new gate fixture, existing backlog/lifecycle suites, full `bash tools/check.sh`, interaction freshness and whitespace checks passed on 2026-10-30 using Git Bash, Python and `texlua`. The baseline intentionally fails the new scan budget.

Pending engine checks: Preview with one/four holders in crowded rooms, enemy targeting/obstacles, other mods changing NPC targets, live frame time and collector pauses. Other Lua workloads, weapon/NPC callbacks, whole-mod persistent allocation and broader U4 error isolation remain open. Installed `8fd6a8c` is untouched. This unit avoids PR #2's files; HANDOFF/CHANGELOG consolidation is deferred under that restriction, with this section and TESTING serving as the focused handoff. No installation, game, save, settings, art or Workshop operation occurred.

## GPT and tainted Grok binding allocation (2026-10-27)

The measured source baseline is `7b96386`. Run from the repository root:

```sh
texlua tools/profile_target_hotpaths.lua . 6000
```

The tool loads the real `gpt_downgrade.lua` and `grok_ratio.lua` modules and uses Lua debug introspection to obtain each update callback's binding closure. It supplies cached game/player stand-ins, warms the binder twenty times, then invokes it 6,000 times with unchanged identities. All players either match the module's form or are unrelated. GPT's award set is empty. No complete update, rendering, native engine work or active ability is exercised.

Garbage collection is stopped only during each measured loop. Heap growth therefore estimates temporary allocation pressure in this Lua interpreter; it is neither retained memory nor evidence of a leak. CPU time is printed for local diagnosis, with no CI timing threshold or frame-rate claim. The recorded local interpreter is Lua 5.3 via `texlua`; other Lua versions/builds may allocate differently.

Both modules produced the following results independently. Values are KiB over all 6,000 calls, not per frame:

| Players | Form match | Baseline heap growth | Revised heap growth | Baseline type calls | Revised type calls |
|---|---|---:|---:|---:|---:|
| 1 | No | 1921.875 | 843.750 | 12000 | 6000 |
| 1 | Yes | 2017.602 | 939.477 | 18000 | 6000 |
| 4 | No | 5718.750 | 1406.250 | 48000 | 24000 |
| 4 | Yes | 6095.727 | 1783.227 | 72000 | 24000 |

All eight binding scenarios made zero entity-scan calls. That observation applies only to the isolated binder, not the whole character callback or mod. The retained per-slot identity snapshot is now reused only while pointer, seed and character type match. A changed slot receives a fresh snapshot; missing slots still retire state. The player type is read once per player per binding pass. The two replacement maps and all existing state validation remain, so this is a bounded reduction rather than removal of all per-frame allocation.

The two real-module gameplay suites retain all earlier assertions and add stable-account, occupied-slot swap, departure/rejoin and pointer-only replacement controls. These new behavior controls also pass on the baseline: this unit optimizes existing semantics rather than fixing a newly claimed gameplay failure. Separate private faults retaining absent-slot state or reusing a stale identity snapshot fail the departure control in each module. Existing seed/type/Continue, duplicate-frame, Birthright and attack-order tests remain intact.

## Attack-choice history

The same tool separately loads the unchanged real `attack_choices.lua`. A proxy counts numeric entry reads inside `Resolve`; it does not time the instrumented representation. Synthetic unique keys bypass weapon attribution entirely.

| Supplied scenario | Retained entries | Entry reads during Resolve |
|---|---:|---:|
| Append and resolve 600 alternating unfavorable/favorable attacks | 600 | 1199 total |
| Resolve the unchanged ledger 6000 times | 600 | 0 |
| Repeat 600 already-recorded keys without upgrading them | 600 | 0 |
| Upgrade the first attack after all 600 were resolved | 600 | 600 |
| Append one Birthright-style half marker and resolve | 601 | 2 |

Ordinary unchanged resolution already avoids replay. Appending needs only the new suffix plus the prior accumulated value. Revising an early attack still replays the suffix to preserve historical clamps and half markers; duplicate hits do not add entries. No ledger truncation, attack-key, billing or transfer-rule change is included.

The 600-entry sequence is a synthetic stress case, not an observed attack rate. GPT retains its ledger until its current check ends; Grok retains it for its quote. This tool does not establish a native maximum lifetime/history size, sample child-shot ancestry, or validate E2. Whole-mod entity scans, large GPT award sets, collector pauses, live ability updates and native multiplayer/performance remain follow-ups. Installed `8fd6a8c` is preserved and still owner-untried.
