# In-game test checklist

Current acceptance status is summarized in HANDOFF.md. Dated sections preserve their original evidence scope. The installed gameplay checkpoint is `ef7d2dded1f5d849c8a638a310074278a90e81c2`, including owner-approved B1 PR #102, O4 transformation costume restoration and O5 Death packing. On 2026-10-26, 443 prior allowlisted files were backed up and reread-hash verified before replacement; all 451 installed tracked files then matched canonical Git bytes. No files were removed. No game was launched or controlled, and saves, settings and other mods were untouched. The game was closed during installation. Preserve this manual-test checkpoint during offline follow-ups. Documentation sync #104 installed exact source `8fd6a8c8a543226f414a01c654ff1f85bde1214c` and independently reverified all 451 tracked files. The owner replied "not tested yet" for that build; source follow-ups preserve it. Installation and successful CI are not engine acceptance. The earlier f8b2b0b startup attempt remains historical in ENGINE_AUDIT_2026-10-26.md.

## U5/G4: all-form Birthright timing (2026-10-30; offline)

The [full-entry timing matrix](BIRTHRIGHT_FULL_ENTRY.md) adds 22 duplicate-form cases through actual main.lua. Opposite owner inventories change while Reviews, meals, marks, checks, quotes, installations, helpers, charge/recovery phases, presentations, tasks and passes are pending. Assertions cover exact selected deadlines, live caps/thresholds/cache coefficients, activation costs, emitted effects and one-time completion rewards. Existing snapshot-versus-live policies and all gameplay values remain unchanged.

The unchanged-source control passes. Six deliberately faulty isolated copies fail the intended assertions: renewing a spent age shield, sampling Review inventory too early, resizing a bought chain, caching Fine-tune awards, using a teammate's Release inventory and revoking a room-bound Apology token. This is new regression coverage, not six discovered bugs. Actual pickup/reroll, native cache scheduling, special bodies, save/Continue at these boundaries and rendering remain unaccepted. Installed `8fd6a8c` is untouched; this record and the focused matrix provide the handoff while PR #2 prevents consolidated HANDOFF/CHANGELOG edits.

## U3/U4/G3: character state follows observed owners (2026-10-30; offline)

[Character slot continuity](CHARACTER_SLOT_OWNERS.md) reproduces resource resets on all 21 previously slot-bound forms (normal Rice already passes): a same-owner move could reset Credits, age, cooldowns and pending bindings. Atomic remapping now preserves each continuously observed pointer/seed's state, including Claude's paid volley, while actual replacements and observed departures remain fresh-owner boundaries.

All 22 forms have duplicate/mixed four-player moves, pause, wrapper/controller, departure/join, pointer/seed/type replacement and observed-move-before-Continue cases through main.lua. Seventeen actual ability timelines compare moved and stationary owners for 300 frames each, with explicit positive controls. Baseline fails each changed form; seven intentional production faults fail the intended assertions. Older Claude/GPT/Grok swap-reset expectations are explicitly superseded by the owner-delegated continuity rule, while their replacement tests remain.

Native special-body identity, Flip/revival, callbacks before the next rebind, real save/exit order, rendering and both engine versions remain unaccepted. This does not close S1-S4 or E2-E6. Installed `8fd6a8c` and PR #2's files remain untouched; the focused record is this unit's handoff pending consolidated HANDOFF/CHANGELOG updates.

## U5/G6: quiet DROP refusal cues (2026-10-30; offline)

[DROP_REFUSALS.md](DROP_REFUSALS.md) records the owner-delegated choice and current per-form conditions. Refused taps show one English line for 45 frames in the tapping player's existing HUD band; no shared caption, sound or extra row. A separate feedback observer preserves the original action cancellation rules, costs, cooldowns and native pocket/hold ownership.

New coverage exercises 49 four-player refusal cases through main.lua, 44 all-form multi-pocket/long-hold cases, mixed-family isolation, accepted Qwen/target actions, detached saves and room/Continue cleanup. Direct observer cases cover eligibility changes during a held gesture, duplicate frames, controls, ghosts, identity changes, expiry and repeated refusal/success. The existing DROP contract suite remains unchanged. Physical input, native timing/fonts, HUD corners and actual Continue are still E4/E5 work. Installed `8fd6a8c` is preserved; this record and the focused refusal document are the handoff while PR #2 prevents HANDOFF/CHANGELOG consolidation.

## U3/U4: active target composition review (2026-10-30; offline)

The [scheduled target-ability review](HARDENING_TARGET_COMPOSITION_2026-10-30.md) reproduces F19: a backlog replacement's global recursion guard skipped an independent tainted-Gemini Export pulse's item modifier (`11.34` instead of `15.309`). A source/target-scoped guard now restores nested state even on errors, while explicit common pulses retain their exemption. The new suite runs 25 two-owner weapon/active-loop cases, an actual Retry pair and supplied nested/error controls through main.lua. Old production and six isolated production/fixture faults are rejected.

The fixture now supplies distinct room SpawnSeeds instead of changing only SafeGridIndex. This models room identities, not the engine's seed formula. Native callback order, event identity, all active phases and real Continue remain unaccepted. Installed `8fd6a8c` and PR #2's files are unchanged; this focused review is the handoff until HANDOFF/CHANGELOG consolidation can proceed.

## U3/G2: full entry-point primary weapons (2026-10-30; offline)

The [full weapon matrix](FULL_MOD_WEAPON_COMPOSITION.md) adds 176 two-owner cases across all 22 forms and eight supplied weapon categories, plus eight earned Rice/Thought compositions. A four-owner primary-beam regression reproduces and fixes tainted DeepSeek's later primary beam losing its paid window bonus or keeping an old bonus at an unaffordable boundary. The optional sharing hook copies the existing decision without another payment or a renewed deadline. Old main and four isolated faults fail the intended assertions.

Exact source/window bills, hit composition, exhaustion, owner replacement, pause, room reset and detached save controls are offline only. This does not change child-laser classification/billing policy or accept native E2, all active loops, ancestry, weapon physics or Continue. Installed `8fd6a8c` is preserved; HANDOFF/CHANGELOG consolidation remains deferred because of open PR #2.

## U3/G2: full entry-point ordinary primary attacks (2026-10-30; offline)

The [full-main primary matrix](FULL_MOD_PRIMARY_COMPOSITION.md) covers 22 duplicate-form pairs, an earned Thought/Cooker case, five synchronous One More Finger helper cases and 88 mixed two-owner inventories. Actual fire/update/hit callbacks check resolved damage, raw forks, Context aging, owner-specific resource payments, Opus charges and removal/room cleanup. Four isolated source faults fail the intended assertions. No production defect or gameplay change is claimed.

The fixture now supplies typed raw tears and distinct raw-Spawn/synchronous-FireTear paths. Those event contracts, projectile properties and RNG are modeled inputs. Native weapon physics, callback ancestry, all active loops and engine acceptance remain open; E2 still gates child-billing changes. Installed `8fd6a8c` is preserved.

## U3/W4.4: full entry-point cache mixtures (2026-10-30; offline)

The [full-main cache matrix](FULL_MOD_CACHE_COMPOSITION.md) loads actual form and item modules. It covers 46 initial-form arithmetic/wallet cases, a native-input/removal control and 176 two-owner inventory cases (22 holding all 80 IDs, 154 sampled). Repeated evaluation, partner isolation, inventory replacement/removal, flight, flags and colour are checked. Four deliberate source faults fail the intended assertions; no new production bug or value change is claimed.

The full-entry fixture now supplies the formerly omitted tear-flag cache branch. Native stats, full cache evaluation and inventory changes remain fixture inputs; actual invalidation, firing, damage, item activation, later form phases and native reroll/Continue are not accepted. U3 and character completion remain open. Installed `8fd6a8c` is preserved.

## U4: full entry-point save composition (2026-10-30; offline)

The [scheduled integration review](HARDENING_SAVE_COMPOSITION_2026-10-30.md) runs actual `main.lua` and all production modules through detached snapshot save/Continue cases: 22 form/item pairs, a four-owner Rice/Cooker rotation, an actual Kimi task budget, same-session Continue/fresh-start controls and a runtime-object rejection control. Distinct item choices, pending rewards and meal locks restore; Preview markers and explicitly transient task/room effects do not. Five isolated source faults fail the intended assertions. No new production defect or balance change is claimed.

The codec and startup order are supplied offline inputs. Native serialization, callbacks, inventory, weapons, special subplayers, unobserved slot changes before saving and all-form gameplay/Continue acceptance remain open. The existing update-budget suite remains active. Installed `8fd6a8c` is preserved, and HANDOFF/CHANGELOG consolidation remains deferred while their files overlap open PR #2.

## U4: full entry-point update budget (2026-10-30; offline)

The [performance workload](PERFORMANCE.md) loads real `main.lua` and all production modules. The new gate fixture checks 22 idle forms, one/four Preview holders with 0/12/96 enemies, target/lifecycle controls and a four-form mixed inventory with actual Kimi/GLM scheduled damage. The exported `1e20c4c` Gemini module fails the query budget but passes the behavior controls. Preview now shares one enemy enumeration per five-frame refresh across owners/markers; no list is retained between callbacks. Four holders over 180 supplied updates reduce room scans from 288 to 36.

The profiler records 27 workloads and instrumented allocation/time with explicit limits. Native AI/physics/rendering, all weapon callbacks, actual frame rate, optional-mod interactions and full combat/performance acceptance remain open. No installed file changes are made.

## U4/O6/F18: Rice and shared-meal ownership (2026-10-30; offline)

The [O6 identity fixture](O6_RICE_MEAL_IDENTITY.md) initializes real Risk, MealBreak and Rice/Thought callbacks with detached snapshot serialization. Baseline `941b4af` independently loses meal debt and Rice progress when the same live players change slots. The corrected binders preserve their own state and transient clocks through an atomic map rebuild; actual replacements still start fresh.

Eight supplied scenarios cover three/four-player moves, pause, owned cancellation/refund, foreign cooldowns, controller/type changes, departure/replacement, reordered saves, both restart styles, version-1 migration and knife-flight exit cleanup. Runtime objects are rejected from the exercised save snapshot. Native identity, serializer, callback/save ordering, continued weapons and special subplayers remain open; no all-form O6 or engine acceptance is claimed. Installed `8fd6a8c` is preserved.

## U3/F17: Rate-Limit Valve inventory loss (2026-10-30; offline)

The [inventory-loss fixture](VALVE_REMOVAL.md) reproduces an unspent passive bonus surviving removal on baseline `359665e`, both with an update and when the next event is an attack. Six scenarios check cleanup, the attack-time ownership guard, remaining copies, another holder, resolved same-frame/in-flight attacks, an independent completed Rice Cooker reward and reacquisition under the existing idle threshold. The fixture uses real backlog modules with supplied inventory, attack and damage events.

Native D4/D100/Clicker/Genesis timing, charged/controlled weapons and real Continue remain unverified. No active reward is newly tied to item ownership, and no save or installed file changes are made. The earlier DeepSeek composition matrix remains active.

## U3/F16: DeepSeek, meals and backlog composition (2026-10-30; offline)

The [scheduled integration review](HARDENING_2026-10-30.md) loads real MealBreak, all backlog modules, DeepSeek base stats, Rice First/Thought and Peak/Valley callbacks. Twelve seeded four-player scenarios check independent locks, character-meal cancellation/refund, active completion, inventory removal, same-frame Thought/Compute payment, nested item/knife damage, both scheduled phases and room cleanup. Native APIs, event order and weapon states are supplied; this is not all-form or engine acceptance.

F16 fails on baseline `6af1bc7`: a death-cancelled Rice Cooker meal grants the unfinished reward. The correction clears the pending flag without granting a new prime. Controls preserve completed rewards and prevent an already earned prime being refreshed by another cancelled meal. Real Continue, native revival and the separate unspent Rate-Limit Valve removal candidate remain open.

## U4: optional EID isolation (2026-10-30; offline)

The [EID isolation regression](EID_ISOLATION.md) reproduces optional registration errors escaping the adapter on baseline `4fadee1`. The source fix skips failed descriptions while retaining healthy entries and completing the rest of `main.lua`. Cases cover malformed globals, partial APIs, lookup/call errors, one rejected collectible and bounded startup diagnostics. The existing EID content assertions remain unchanged; the full entry-point smoke fixture runs with an injected external error and requires its final callback registration.

This proves only the supplied API boundary. Native startup with EID absent/present, description rendering, external side effects and late-loading integrations remain open. Other production modules, actual saves and installed `8fd6a8c` are unchanged.

## U3: All Tests Passing in Greed modes (2026-10-30; offline)

`tests/door_safety_test.lua` reproduces an uncleared ordinary room being force-cleared by All Tests Passing on main `9888186` with a supplied true `Game:IsGreedMode()` result. The guard now refuses while the room is uncleared, retaining the item and charge request and showing the existing required-review caption. The expanded fixture covers repeated attempts, ordinary/boss rooms, no `SetClear` call or door mutation on refusal, cleared-room use, special-exit preservation, and a later ordinary-mode use. The Greed/Greedier labels both supply the same documented boolean; they are not two engine runs.

Native checks remain open: in both Repentance and Repentance+, use the item during Greed and Greedier waves, between waves and after the arena is cleared. Check actual charge retention, continued waves/rewards, no premature doors, and ordinary-room use in a later normal run. Native `IsClear()` timing between waves is not modeled. See [the focused handoff](GREED_CLEAR_SAFETY_2026-10-30.md). The installed checkpoint remains unchanged.

## U3/G7: Agentic and fixed-look composition (2026-10-30; offline)

The [shared-service composition fixture](AGENTIC_COSTUME_COMPOSITION.md) runs the real backlog, Agentic transformation and costume-lock callbacks across 264 seeded four-slot cases covering all 22 registered normal/tainted IDs. It checks distinct-item thresholds, finite and repeatable cache rebuilding, independent native flight, size preservation, vanilla costume controls, type departure/return, inventory removal and room-state cleanup. Three injected source faults fail the intended assertions.

The fixture does not load family-specific ability callbacks or the non-backlog individual item modules, and its native flight/delay/scale values are supplied inputs. It therefore does not establish full item/character combinations, no double billing, no stuck shooting locks or native visual/gameplay acceptance. See the record for commands and exact limits. The existing gate automatically includes the new Lua test.

## U3: seeded backlog cache mixtures (2026-10-30; offline stub)

`backlog_seeded_compatibility_test.lua` samples 32 fixed seeds, with two owners and inventory sets drawn from all 80 registered collectible IDs. It loads the real backlog service/family modules, evaluates damage, speed, range and shot-speed caches, dispatches three updates and one supplied ordinary tear hit per owner, then removes inventory before a room transition. The matrix checks finite stats, baseline cache restoration and cleared room-scoped backlog data. The fixture passed under `texlua`.

This is not a 22-form integration test: it does not load character callbacks or the non-backlog item modules. It does not prove no double billing, release every character shooting lock, or define persistence for every item after removal. Focused existing suites cover selected real-module billing/lifecycle rules; all native timing, damage and visual checks remain open. PR #2's pedestal, trinket and dossier appearance is still untested by the owner.

## W1.3 batch 06: ten original item icons (2026-10-27; offline)

[Batch 06](ITEM_ART_BATCH_06.md) replaces ten Doubao/Kimi/GLM placeholders with original object drawings, explicit palettes/provenance and deterministic hashes. Initial/final 1x/4x sheets were viewed on light/dark fields. Fly wings and gear teeth were separated; the existing margin check caught a projection-foot edge contact, corrected before the final generation and review. Names, effects and registration remain unchanged.

Isolation covers ten changed old PNGs, 173 other PNGs/25 canonical ANM2 files unchanged, 82 unchanged registry records, unchanged prior drawing/preview functions and all Lua/tests/XML unchanged. The full gate retains 73 Lua suites, 11 scanner cases, 13 item-art groups, six thumbnail groups, XML/assets/poses/report and now twelve sheets. Native pedestal/EID/lighting/pickup cases and all mechanism rows remain open. No runtime/game/settings/save access occurs; installed 8fd6a8c stays owner-untried and preserved.

## W3 F9: charm and shield ordering (2026-10-27; offline)

[absolutely_right_damage_test.lua](../tests/absolutely_right_damage_test.lua) loads real charm, Constitution and backlog modules in relative main.lua order, with priority/filter/first-return dispatch. Baseline 7380715 passes ordinary/flag/limit groups but fails the guarded-bullet no-charm assertion. The LATE observer passes Sold Out/Red Stamp/Constitution, two-owner, positive-source, exclusion, existing-flag and explicit later-veto controls in both supplied status models. Four syntactically valid faulty copies fail assertions.

[The evidence and engine queue](CHARM_DAMAGE_ORDER.md) preserve the distinction between pre-damage callbacks and final health/status results. No blanket fake/no-penalty exclusion is added to this beneficial effect. The gate grows to 73 Lua suites/190 tracked Lua files; old suites, all 208 art files, tooling/XML, values, save shapes and installed 8fd6a8c remain unchanged. Native later cancellations, invulnerability, status immunity, special players and other F9 reactions stay open. No runtime/game/settings/save access occurs.

## W4: ordinary primary-tear matrix (2026-10-27; offline)

[primary_tear_composition_test.lua](../tests/primary_tear_composition_test.lua) exercises 64 subsets of six real modules in their relative main.lua registration order. Two owners fire 768 supplied ordinary tears with different incoming damage; repeated updates cover initial frames 0/1 and ages 30, 62, 63, 90 and 180. Assertions preserve resolved fire damage, noncompounding Context decay, inherited scale, all colour channels, flags, counters and RNG. Separate controls cover already-slow tears, delayed first update, Ludovico and missing/non-player ownership.

[The evidence record](PRIMARY_TEAR_COMPOSITION.md) distinguishes fixture dispatch/cache inheritance from the engine. Seven isolated faults fail this suite; production already passes. No old assertions, gameplay, art, tooling, XML or save formats change. The gate grows to 72 Lua suites/189 tracked Lua files and retains the Python, asset and ten-sheet checks. Native order/damage/rendering, descendants, other writers and Continue remain open; the E2 child-billing gate is unchanged. No runtime/game/settings/save access occurs; installed 8fd6a8c stays owner-untried and preserved.

## W1.3 batch 05: ten original item icons (2026-10-27; offline)

[Batch 05](ITEM_ART_BATCH_05.md) changes Open Weights, Herd Bell, Please Come Back, Release Soon, Emergency Baguette, Slipstream Boots, Very Large Kitten, Edge Compass, Instant Apology and Next Time Again. Names, effects, charge, quality and pools remain unchanged. Original pixel geometry replaces the placeholders; no external/native artwork or official logos are imported.

The initial and final 1x/4x sheets were viewed at original resolution on light/dark backgrounds. Bread scoring/colour, the boomerang's bend and separation around the open weight shackle were refined. Metadata, hard-alpha margins, declared palettes and deterministic bytes pass the existing producer checks. Exactly ten old PNGs change; 171 other PNGs, 25 canonical ANM2 files, 82 other registry entries, all old drawing/preview functions and all Lua/tests/XML remain unchanged. Two new sheets bring the complete art inventory to 208 paths; designed icons total 50, with 42 placeholders left.

The full gate retains 71 Lua suites, 11 scanner cases, 13 item-art groups and six thumbnail groups, with 188 tracked Lua files, five XML files, assets/poses, interaction freshness and ten sheet checks. This art unit adds no gameplay regression expectations. All broad mechanism rows and native pedestal/EID/lighting/pickup cases stay open; the kitten icon is not a bespoke in-room kitten sprite. No runtime/game/settings/save access occurs; installed 8fd6a8c remains owner-untried and preserved.

## W6: filtered active-item integration (2026-10-27; offline)

`texlua tests/active_pair_test.lua .` loads Ignore Instructions and I Panicked together, in their relative main.lua order, and dispatches MC_USE_ITEM only to matching registered item filters. The 28 supplied sequences and review boundaries are in [HARDENING_2026-10-27.md](HARDENING_2026-10-27.md). Four slots, same/separate owners and three callback orders check each intermediate effect; four more cases remove the first status target through the partner's damage callback before its repeat. Unrelated actives must invoke neither handler.

The original production modules pass all new cases. Four private wrong/missing registration-filter faults pass their respective existing isolated suites, whose dispatch ignores the optional item filter, but fail the new pair fixture. No old suite/assertion or production behavior is changed. This demonstrates useful additional integration coverage, not a newly fixed gameplay bug.

The full gate grows to 71 Lua suites and 188 tracked Lua files, retaining 11 scanner cases, 13 item-art groups, six thumbnail groups, five XML files, assets/poses and eight art sheets. Production Lua, tooling, art, balance and save shapes are unchanged. Native callback order, actual charge/death/drop/status processing, Void routing, special-player identity and recursive external uses remain open. F12 is not resolved by simulated return fields. No runtime/game/settings/save access occurs; installed 8fd6a8c stays owner-untried and preserved.

## W3 F2: Ignore Instructions / Car Battery targeting (2026-10-27; offline)

The new two-boss sequence in `texlua tests/meme_items_test.lua .` fails against 4f17b34: the nearest boss receives confusion twice and the second boss receives none. The correction implements the existing EID promise of a different second enemy. The [repeat flag](https://wofsauge.github.io/IsaacDocs/rep/enums/UseFlag.html) identifies the callback, while [EntityPtr](https://wofsauge.github.io/IsaacDocs/rep/EntityPtr.html) and seed checks keep transient references separate from saved state. These API documents do not establish a native repeat delay or complete use-order guarantee.

The latest ordinary use replaces the prior primary for that owner/slot, including clearing it on refusal. The repeat consumes its exclusion; an unmatched repeat retains the former ordinary selection behavior. Room entry and game start clear all records. The implementation does not exclude all confused bosses, change status durations/range/tie order, serialize references or add a fixed frame expiry. Supplied callbacks use slots 0-3 and combined flags; no claim is made that every native item route emits those exact arguments.

Added cases cover two/one bosses, status resistance, the inclusive 200-unit boundary, ordinary Void/mimic/nil-flag use, interleaved owners and active slots, each repeat's target, primary replacement/refusal, one-time consumption, room/start reset, removed/reseeded targets, equivalent Lua wrappers and owner replacement. All old assertions remain. Eight isolated faults pass those retained assertions with the expanded API stubs, then fail the extended cases: missing exclusion, flag equality, shared owner, shared slot, unconsumed pairing, absent lifecycle clearing, missing target-seed check and wrapper equality. An initial slot fixture only compared totals and missed the shared-slot fault; checking the first repeat independently now rejects it.

The full gate passes 70 Lua suites, 11 Python scanner cases, 13 item-art groups and six thumbnail groups, plus 187 tracked Lua files, five XML files, assets/poses and all eight art review sheets. The inventory increases only by two lifecycle callbacks to 401; candidate field writes stay 109. All 206 art files, XML, balance values, EID text and other gameplay modules are unchanged. No runtime/game/settings/save access or native acceptance occurs.

Pending native case: use Ignore Instructions with Car Battery against two bosses, one boss, a boss plus a regular enemy, and a charm-resistant enemy. Observe actual target order, status application, captions and charge/refusal behavior. Then try a later ordinary use on the confused boss, room transition, co-op, Schoolbag/pocket and Void routes. Native callback pairing, special-player replacement and same-owner/same-slot recursive external uses have no unique invocation ID in this implementation and still need observation. Installed 8fd6a8c remains owner-untried and untouched; F2's broad item row stays open.

## W2 G4: Birthright changes while abilities are pending (2026-10-27; offline)

The extended `gemini_edit`, `llama_hype`, `mistral_baguette` and `kimi_manager` suites run the unchanged real character modules. [BIRTHRIGHT_TIMING.md](BIRTHRIGHT_TIMING.md) lists the exact source contracts and limits. Two initial-duration sequences each cover Gemini and Llama, three in-progress threshold sequences cover Mistral, and one simultaneous two-owner sequence covers all three Kimi pulses. Inventory gain/loss/reacquisition does not incorrectly reset progress, spend/refund resources, transfer a partner's state or alter deadlines beyond each existing policy. Duplicate updates preserve last-frame boundaries where relevant.

Each of four private faulty module copies changes a snapshot/live sampling policy. The old corresponding suite passes; the extended suite fails the intended new assertion. The unchanged production modules pass both their earlier expectations and the added cases. This is evidence of stronger regressions, not a gameplay fix. The injected Llama helper service remains a stub; no new derived-shot/billing acceptance is asserted.

The full gate passes 70 Lua suites, 11 scanner cases, 13 item-art groups and six thumbnail groups, plus 187 tracked Lua files, five XML files, assets/poses/eight review sheets and inventory freshness. All prior assertions, gameplay Lua, tooling, XML, art and save shapes are preserved. Native inventory mutation, actual reroll/cache/callback ordering and special-player behavior remain unverified. No runtime/game/settings/save access occurs; installed 8fd6a8c remains owner-untried and untouched.

## W1.3 batch 04: ten original item icons (2026-10-27; offline)

[Batch 04](ITEM_ART_BATCH_04.md) changes One More Finger, Unchanged Preview, Is This True?, Live Wire, Quote Retort, Community Note, Base Model, Another Adapter, Final Final Weights and Tiny Variant. Reproducible drawing code and explicit registry entries retain the existing names, paths, effects, charge, quality and pools. New geometry replaces placeholder lettering/symbols with object silhouettes; no native or third-party pixels are imported.

The 1x/4x sheets were inspected at their original resolution on light/dark fields. The glove initially had narrow, rigid fingers; rounded wider tips improve its intentional six-digit reading. The boxing glove's two vertical creases looked like eyes and were replaced with a single side fold. Both final sheets were reviewed after these refinements. This is offline visual review, not owner aesthetic approval or native acceptance.

The full gate retains 70 Lua suites, 11 scanner cases, 13 item-art groups and six thumbnail groups, plus 187 tracked Lua files, five XML files, character/pose checks and eight review-sheet freshness checks. Isolation checks cover exactly ten changed existing PNGs, 169 unchanged PNGs, 25 unchanged canonical ANM2 files, 82 untouched registry records and all production Lua/tests/XML. Two new sheets bring the exact linked art inventory to 206 files. Current inventory subtotals now correctly report 38 designed collectibles and two designed trinkets, with 42 collectible/ten trinket placeholders.

No engine, runtime, save or settings access occurs. Installed 8fd6a8c remains preserved and owner-untried. Native pedestal/EID sizing, room lighting and pickup presentation for these icons remain pending; no broad mechanism row is closed by this art work.

## W3 F11: I Panicked / Car Battery pickups (2026-10-27; offline)

`texlua tests/meme_batch_test.lua .` retains all previous assertions and adds a sequence around the real item callback. At baseline 5e3f392, a surviving boss keeps the repeat eligible and the first new pickup-protection assertion fails. The fixture explicitly supplies drops during damage and another pickup between callbacks; it does not observe native death or reward timing.

The correction uses the documented [USE_CARBATTERY bit](https://wofsauge.github.io/IsaacDocs/rep/enums/UseFlag.html) to skip pickup collection only on the repeat. This implements the source's existing "deletes nothing new" comment. The [use callback](https://wofsauge.github.io/IsaacDocs/rep/enums/ModCallbacks.html#mc_use_item) return fields are retained; documentation of those fields is not evidence of actual native charge/discharge order. No new balance, persistence or target policy is introduced.

Across supplied slots 0-3, regressions check the original consumable removal, first-hit/intervening/second-hit drop preservation, dead-target exclusion, repeated boss/non-boss damage attributed to the user, one caption, and a later ordinary use by another owner that still removes current consumables. Additional controls cover Void/mimic bits without the repeat bit, nil flags and an ineligible repeat. Existing protected-pickup and no-target cases remain. Three private faulty copies (delete again, skip all repeat damage, compare flags by equality) fail the intended assertions; production files are never replaced by those copies.

The full gate passes 70 Lua suites, 11 scanner cases, 13 item-art groups and six thumbnail groups, with 187 tracked Lua files, five XML files, assets/poses/six review sheets and interaction-report freshness. The report's source fingerprint changes; its 399 callbacks/109 candidate field writes do not. All art and XML are unchanged. No runtime/game/settings/save access or native acceptance occurs.

Pending native case: with I Panicked and Car Battery, use it in a room containing a surviving boss, ordinary enemies and loose/protected pickups. Verify both damage passes, preservation of drops that actually appear between them, charge/caption behavior, refusal after all targets die, and a later ordinary use. Repeat with primary/Schoolbag/pocket routes and co-op as available; record the game build and actual item/drop source. Stubbed slots and damage calls do not close this matrix. Installed 8fd6a8c remains owner-untried and preserved.

## W6: thumbnail export repair and scheduled review (2026-10-27; offline)

At 02ba07c, running the legacy thumbnail command fails at `make_placeholders.ART`; the old palette and write_png interfaces are also obsolete. The baseline failure was captured with the tracked thumbnail hash unchanged. The repaired command validates the current registered Ban Hammer metadata and canonical PNG, then generates a 512x512 opaque preview at integer 16x scale. It requires an explicit output; `--check` is read-only. Game-asset and review-sheet destinations are protected after path resolution.

`tests/test_thumbnail.py` adds six groups: current designed output dimensions/opaque background/sample-block colours/determinism and source preservation; CLI export/check plus missing/stale output; import/no-output behavior without preview generation; stale source/metadata rejection before replacement; protected destinations/non-PNG suffixes; and explicit placeholder-registry dispatch. A private 512x512 export was visually inspected for clipping, hard edges, orientation, material colours and background. The legacy tracked thumb.png is unchanged and is not claimed to match the new export. Separate isolated faults dropping metadata validation or output protection fail the intended assertions without unexpected errors.

Scheduled review covers #115/#118 art source/manifest isolation, #116 Cartridge expiry without cache recursion or regrant, #117 immutable slot snapshots with pointer/seed/type checks and missing-slot retirement, and #119 diagnostic-only fixture reporting. No additional confirmed gameplay defect is identified in those reviewed changes; this is not a whole-mod or native certification. The F12 ambiguity remains open. The last main CI succeeded with a checkout Node/runner migration warning; this tooling PR does not bundle an unverified workflow migration.

The full gate now includes six thumbnail Python groups alongside the existing 70 Lua suites, 11 scanner cases and 13 item-art groups, 187 tracked Lua files, five XML files, all character/pose/assets checks, six review sheets and interaction freshness. All 204 tracked art files, production Lua, XML and existing tests retain their prior content. No runtime/game/settings/save access or current game-state observation occurs. Installed 8fd6a8c remains owner-untried and untouched; final-cover, native gameplay and visual acceptance remain pending.

## W3 F12: charged-use observation diagnostic (2026-10-27; offline evidence)

`texlua tools/probe_charged_use.lua .` runs seven supplied histories in each active slot 0-3 through the real backlog modules and Red Stamp handler. No target returns Discharge=false; a supplied nearby target returns true. Inventory/charge changes are then assigned by the fixture before three updates. Refusal plus replacement/removal/swap incorrectly triggers all three listeners in the baseline; unchanged refusal does not, and same-item Battery spending triggers once. The CSV reports event count, Base Model prime, Please Come Back progress, Access Pass spending and damage. Successful exit validates fixture setup only, not absence of these known false observations.

Two isolated common-module copies compare charge-only and same-item-plus-charge predicates. The former still accepts refused lower-charge replacements/removals; the latter also rejects accepted/removal. The accepted/removal case deliberately removes Red Stamp after success, not native self-removal by that item. All slot/charge transitions and event timing are supplied, so no Schoolbag, Butter!, native consumable, extension or other-mod ordering is accepted. [The detailed report](CHARGED_USE_AUDIT.md) records exact results, API references and the remaining native evidence boundary.

No production Lua, existing tests, item rules, assets, XML or interaction inventory change. The full gate still passes 70 Lua suites, 11 scanner cases and 13 item-art groups; tracked Lua becomes 187 because the optional diagnostic is syntax-checked. The diagnostic's 28 rows and 56 private candidate rows are not extra CI/gameplay suites. F12 remains open and production behavior is unchanged. Installed 8fd6a8c, game, settings and saves are untouched.

## W1.3 third icon batch (2026-10-27; offline art)

[Batch 03](ITEM_ART_BATCH_03.md) redraws ten registered collectibles after reading their real item modules: Anniversary Cake, One Bowl Only, Wengu Clock, Seven-Second Memory, Sanity Test, Routing Receipt, Tibo Reset, Same Model Badge, Nano Banana and Undo Brush. Both 1x/4x sheets were reviewed on light/dark backgrounds; fruit-yellow and candle-flame colours were refined and both final sheets rechecked. Original reference shapes are project drawings rather than extracted native art.

Isolation against 81b9976 confirms exactly ten old PNG changes, 167 other PNG byte matches and 25 canonical ANM2 matches. Two new sheets bring the inventory to 204 uniquely linked files (179 PNGs/25 ANM2). All 82 untargeted icon records remain identical. All Lua, tests and XML/pools are unchanged; existing validators are not relaxed. Registry status is 30 designed/62 placeholder icons, comprising 28 designed collectibles and two trinkets.

Each new icon passes the declared palette, 32x32 RGBA8, hard alpha, transparent outer margin and exact regeneration contracts. The full gate retains 70 Lua suites, 11 Python scanner cases, 13 Python item-art groups, 186 tracked Lua files, five XML files, character/pose checks, unchanged interaction inventory and all six review sheets. Counts and deterministic bytes do not certify visual quality by themselves; the separate sheet inspection is the offline visual evidence.

No gameplay rule, charge, pool, schema, character-look or derived-shot policy change is bundled. Native pedestal/EID rendering, lighting, pickup presentation and the outstanding hurt/animation cases remain unaccepted. Installed 8fd6a8c, game, settings and saves are untouched; no private art or engine files are published.

## W6: measured target-binding allocation (2026-10-27; offline)

`tools/profile_target_hotpaths.lua` measures the actual GPT/Grok binding closures under fixed one/four-player matching/unrelated scenarios with cached engine stand-ins and collection stopped during 6,000 binding calls. [PERFORMANCE.md](PERFORMANCE.md) records exact baseline/revised heap growth, player-type calls and zero entity scans within those isolated closures. The script is optional diagnostic tooling; its wall-clock or heap numbers are not platform-independent pass/fail thresholds and are not native FPS evidence.

Both modules now reuse an immutable slot snapshot while pointer/seed/type are unchanged, replacing it on any observed identity change and pruning absent accounts as before. The two existing real-module suites add stable repeated updates, occupied-slot swaps, departure/rejoin and pointer-only replacement checks. All new behavior checks pass against both 7b96386 and the revised implementation. Separate private faults removing slot pruning or keeping a stale snapshot fail the intended departure assertion in both modules. Existing attack ordering, seed/type, Continue, Birthright and duplicate-frame expectations remain unchanged.

A separate proxy counts entry reads during real attack-choice resolution. Six hundred append/resolve operations read 1,199 entries; 6,000 unchanged resolves and 600 non-upgrading duplicates read none. A delayed upgrade of the first attack replays 600 entries; a half marker adds one entry and reads two. These are supplied keys, not native weapon observations. Attack-choice code, billing, ledger lifetime and transfer rules are unchanged.

The full gate retains 70 Lua suites, 11 scanner cases, 13 item-art groups, five XML/assets/poses/four review-sheet/report checks, and now 186 tracked Lua files (the new profiler is syntax-checked, not an extra gameplay suite). The regenerated interaction inventory retains 399 callbacks. Native callback timing, engine GC, FPS, full-mod scans, large award sets, shared bodies and E2 remain unaccepted. No runtime/game/settings/save access occurred; installed 8fd6a8c is preserved.

## W3 F13: Cache Cartridge combat transition (2026-10-27; offline fix)

The real shared backlog module at 188c734 leaves Cartridge speed active after the fixture changes `Room:IsClear()` to false without `MC_POST_NEW_ROOM`. In a supplied combination with Error Budget, expected speed 1.2 remains 1.35. The fix consumes only the transient Cartridge flag when either the existing general update or a speed-cache evaluation observes combat. An update-triggered expiry refreshes that player once; cache-time expiry needs no recursive refresh. Only another eligible room entry can grant the bonus again, matching the existing until-combat rule.

Two added cases in `backlog_more_test.lua` cover two holders plus a non-holder; preservation of Error Budget and Checkpoint Pin state; unchanged room identity; no repeated invalidation during combat; clear/explicit-cache without regrant; no charge/pickup reward; eligible re-entry; early cache before update; and loss/regain around combat. The previous first-visit/revisit/new-combat-room assertions remain intact. Separate private faults removing update-time refresh or early-cache observation each fail the intended speed assertion. The backlog lifecycle suite's no-entry-reward control also passes.

The fixture explicitly supplies room flags, cache resets and event order; creating its NPC does not emulate how Isaac changes room-clear status. It does not prove native challenge buttons, Greed/Boss Rush waves, ambushes, item-created enemies, shared bodies, Continue reconstruction or pause/event timing. The independent-effect combination verifies state preservation under supplied callbacks, not native ordering acceptance.

The full gate remains 70 Lua suites, 11 scanner cases, 13 item-art groups, 185 tracked Lua, five XML/assets/poses/review-sheet/report checks. The interaction report still counts 399 native callbacks: the fix reuses an existing update listener rather than adding a new registration or entity scan. No performance budget claim, stat coefficient, persistent schema, charge rule, art or runtime change is included. Installed 8fd6a8c, game, settings and saves are untouched.

## W1.3 second icon batch (2026-10-27; offline art)

[Batch 02](ITEM_ART_BATCH_02.md) replaces eight collectible and two trinket placeholders with original pixel objects. Exact-size and nearest-neighbour 4x sheets were inspected on light/dark fields. Relay key teeth were extended beyond the shaft and the hidden update gear was raised to expose its teeth/centre. Hardcoded Output's numeric display becomes a steel tear die; item labels remain outside icon pixels. Existing effects and registration determine the visual cues; no mechanic or pool changes are bundled.

Against c22310f, exactly the ten intended PNGs change. All other 165 existing PNGs are byte-identical, including the ten first-batch icons and both first-batch sheets. All 25 ANM2 files retain canonical content after Git EOL normalization. The registry partitions into 20 designed/72 placeholder icons; the two new sheets bring the art inventory to 202 unique linked files (177 PNG, 25 ANM2). All relevant local document links resolve.

The preview producer accepts a selected batch and defaults to all batches. The normal asset gate checks all four sheet outputs exactly; no old comparison is removed. New drawings pass 32x32 RGBA8, hard-alpha, declared palette, transparent-margin, metadata and deterministic-byte checks. Existing 13 item-art regression groups pass without edits. The full gate retains 70 Lua suites, 11 scanner cases, five XML/assets/poses/report checks and 185 tracked Lua files.

These are source/art-contract and offline visual observations. No owner aesthetic acceptance, native pedestal/EID/room-lighting behavior, pickup animation or character/hurt-pose acceptance is inferred. Installed 8fd6a8c, game, settings and saves are untouched. No private/native reference images or official logos are published; the original icon terms remain separate from character-design rights.

## W6: normal-Claude counter validation and recent-change review (2026-10-26; offline)

The real Risk loader accepts nested account tables, while normal Claude previously normalized appeals/age but not `value`/`limited`. Against 4c2b721, extending `claude_usage_save_test.lua` reproduces missing/boolean/string Limited comparisons failing during the Continue damage cache, and invalid Usage/countdown values surviving unchecked. The fifteen malformed cases fail; three valid boundary controls pass. Each counter now uses the existing integer predicate and maximum (Usage 100, Limited 150), recovering only invalid fields to zero. This retains the legacy shape and does not coerce numeric strings, invent a penalty, replace the account table or add a version/schema field.

All 18 cases pass: missing fields independently, wrong types, negative/excess/fractional values, NaN/infinity, valid zero/maxima and the last Limited frame. They retain age, Appeals, clear progress, room awards, a valid partner, saved-table aliases and damage from valid countdowns, then perform a second detached save/load and render. Existing wrapper/seed/replacement/Continue/type-return, item mutation, pause/death and duplicate-frame controls remain unchanged. Separate private copies removing each counter guard fail the intended regression. Non-finite values are in-memory robustness cases; the detached JSON stub is not evidence that native JSON can serialize them. No real save is read or written.

The scheduled review after #110-#113 checks the item-art writer's validate-before-write pass, explicit registration/status partition, read-only checker/export boundary and legacy-generator protection; the ten-icon batch's deterministic review sheets and unchanged character/animation scope; and Thinking Cleared's current-inventory predicate, transition-only invalidation and separate room-charge boundary. No additional defect was established in those paths. Existing regression groups and the full gate cover their recorded behavior; visual appeal, native ordering and independent art-rights acceptance are not inferred from those checks.

The final gate passes 70 Lua suites, 11 scanner cases and 13 item-art groups, 185 tracked Lua, five XML files, assets/poses/review sheets and the regenerated interaction report (399 callbacks). No old assertion is relaxed and no test is removed. Whole-mod allocation/entity-scan cost and GPT/Grok history growth remain unmeasured follow-ups; this small validation fix makes no performance claim. Installed 8fd6a8c remains owner-untried and untouched, with no game/settings/save access. Native Continue, special-player identities, R Key/Genesis and broader save normalization remain open.

## W3 F8: Thinking Cleared inventory/cache (2026-10-26; offline fix)

`tests/thinking_cleared_test.lua` loads the real item module. At baseline 9c83196, its pickup, drop, cache-before-update and independent-owner cases fail their intended damage assertions; the first-room/revisit charge control already passes. After the fix, all five cases pass. Separate temporary faults restoring the cached damage predicate and forcing unconditional refresh fail the immediate-pickup and unnecessary-rebuild assertions, respectively. These copies are not shipped.

Coverage includes same-room gain/loss/regain, damage evaluation before the next update, additive recalculation from a changed base, unrelated cache flags, repeated unchanged observations, co-op isolation and a fresh replacement entity. Charge controls retain one positive primary-charge decrement on first entry, no revisit decrement, a zero floor, unchanged secondary/pocket charge, and no charge writes from pickup/update/cache evaluation even in a first-visit room. The fixture supplies engine events and resets base damage; it does not observe native cache ordering or certify native damage composition.

The full gate now runs 70 Lua suites, 11 scanner cases and 13 item-art regression groups, with 185 tracked Lua files, five XML files, assets/poses and interaction-report freshness. The inventory has 399 callback registrations; the one added callback observes inventory without serializing new state. Existing tests and expectations remain unchanged.

Native acceptance remains open: same-room pickup/drop and swallowed-trinket transitions, Continue and rerolls, shared-body/Flip timing, other damage modifiers, golden trinkets/Mom's Box, and timed/special active charge behavior. No charge-type eligibility, scaling, duplicate-room-event or persistence rule is introduced. No installed files, game, settings or saves were accessed; installed 8fd6a8c remains owner-untried.

## W1.3 first icon batch (2026-10-26; offline art)

[ITEM_ART_BATCH_01.md](ITEM_ART_BATCH_01.md) records ten original collectible redraws and their effect cues. Before/after sheets were inspected at exact 1x and integer 4x on both light and dark backgrounds; the stapler's open lever/hinge was refined during review. Original project reference shapes and label pixels are included; no native or private source images are published.

Against 7e91788, exactly the intended ten PNGs change. The other 163 existing PNGs match canonical bytes, and all 25 ANM2 files match after Git line-ending normalization. Initial raw animation comparisons detected checkout CRLF versus canonical LF; this was a verifier distinction, not an animation edit. The 92 registered icon paths now partition into ten designed and 82 placeholder entries. Each new icon passes hard-alpha, palette, margin and 32x32 RGBA8 checks; actual visible colour counts are 7-13. Two new review sheets bring the art inventory to 200 files.

The standard-library review producer is reproducible, and check_assets.py now checks both sheet outputs. The full gate passes 69 Lua suites, 11 Python scanner cases and 13 item-art regression groups plus XML/assets/poses/report freshness. One fixture now injects an empty design map explicitly for the missing-producer case, because a real Ban Hammer drawing now exists; the missing-producer assertion is retained. No gameplay or numerical test expectation changes.

This is offline visual/source evidence only. Native pickup/pedestal/EID presentation, room lighting and all character/weapon/hurt cases remain unaccepted. Installed 8fd6a8c, game, settings and saves are untouched. Original-code MIT icon terms do not replace character-design credits or authorize publication.

## W1.2 item-art pipeline (2026-10-26; offline tooling)

The new manifest partitions all 92 XML icon paths into explicit placeholder/designed status; initially all 92 remain placeholders. Every tracked item PNG was independently compared with canonical 2e63eb5 bytes and remained identical. No gameplay, registration, pool value, character art or runtime file changed.

Thirteen unittest groups in tests/test_item_art.py exercise the real producer and validator with isolated XML, manifests and PNGs: mixed statuses; missing/unknown/duplicate paths; name/kind mismatches; undefined/trinket pool references; missing/extra files; wrong dimensions/RGB; empty/opaque silhouettes; undeclared alpha/colour; transparent margins; stale pixels/metadata; missing producer/provenance/contact; unsafe paths; export/bootstrap rules; and legacy-generator protection for default and explicit canonical destinations. The repository check is verified read-only. The original test shape is not shipped artwork or a visual-quality test.

A separate temporary fixture executes the old 2e63eb5 asset checker and receives its expected generated-sprite mismatch for that valid designed icon; the new gate accepts it alongside two unchanged placeholders. Four isolated faults (metadata comparison, alpha validation, pool-name validation and legacy overwrite protection removed) each fail the corresponding regression. Production files are not replaced by these fault copies. No existing character/menu/pose check is removed.

The full gate passes 69 Lua suites, 11 Python scanner cases and these 13 item-art groups, plus XML/assets/poses/report freshness. Deterministic pixels and declared provenance do not establish attractive silhouettes, independent licensing clearance or native pickup/EID rendering. First-batch before/after 1x/4x review remains required. Installed 8fd6a8c, game, settings and saves are untouched; native acceptance is unchanged.

## W3.1 all-item completion audit (2026-10-26; documentation only)

[ITEM_COMPLETION.md](ITEM_COMPLETION.md) reviews source a29bdfe against registration, generated English item text and expansion targets. It has exactly one row per 80 collectibles, 12 trinkets and five pills, plus three separately counted systems. Relative source/test/document links resolve. Quality, charge type/count and pool membership match XML: 80 pool entries represent 79 unique collectibles (Residential IP in two pools, starting-pocket Lunch Break in none), with Weight 1, DecreaseBy 1 and RemoveOn 0.1 throughout.

The audit maps existing fixtures without claiming each item has exhaustive assertions: smoke observations, shared-service coverage, detached snapshots and supplied callback order are explicitly distinguished. All 97 rows remain open. Fifteen findings cover actual target/text differences and source hypotheses; no new failing-before regression or bug fix is claimed. Broad native active/charge/Virtues, inventory/reroll, weapon, trinket-scaling, horse-pill and special-player matrices remain untested. Known transient versus saved boundaries are documented, not silently changed.

The baseline and documentation gate pass the existing 69 Lua suites and 11 Python scanner cases, plus XML/assets/poses/report freshness. Production Lua, XML, art and generated item text are unchanged. No new mirrored documentation test is added. Installed 8fd6a8c remains owner-untried; this unit does not access runtime, game, settings or saves. Future fixes must add focused behavioral evidence and keep native acceptance separate.

## Resource-text hardening (2026-10-26; offline source text)

Direct source/text review found that Llama's dossier omitted the solo-four exception and DeepSeek's EID did not identify pocket charge in its idle-refill denial. The four changed strings now match existing Lua behavior and existing Llama/Rice assertions. Existing EID and roster tests plus the full gate verify registration/integration; no test expectation or gameplay branch is changed and no mirrored text-only unit test is added. Actual in-game layout remains unobserved.

The hardening review revisited the recent art guide, scanner, normal-Claude owner fix and completion audit. It preserves #107's pointer/seed, swap-cache, Continue and same-entity debt controls. Static interaction counts remain 110 source files, 398 callbacks and 109 candidate field writes; only source fingerprints change. Inspection of hot-path binding allocations and legacy Claude Usage/Limited normalization adds W6 review candidates; no whole-mod budget, malformed-save acceptance or rule decision is claimed.

The gate still covers 69 Lua suites and 11 Python scanner cases, five XML files and assets/poses/report freshness. There are 184 tracked Lua files in CI; the local shell gate currently compiles 199 Lua paths because it also finds 15 ignored private fixture copies. These extra syntax checks are not extra registered suites or public files. No private evidence is staged. Installed `8fd6a8c`, game, settings and saves are untouched; no engine acceptance is added.

## W2.1 all-form completion audit (2026-10-26; documentation only)

[CHARACTER_COMPLETION.md](CHARACTER_COMPLETION.md) has exactly one row for each of the 22 normal/tainted XML registrations. Its relative source/test/document links resolve. The audit compares gameplay/B1 targets, principal module callbacks, English EID/HUD/dossiers and existing real-module fixtures at `28aed35`. It records implemented branches and actual scalar/transient save boundaries, including normal Claude's #107 owner correction.

Every form has a core loop and baseline Birthright case, but none has current-build native acceptance. Generic pointer/seed/type fixtures do not cover Tainted Isaac inventory, Tainted Eden rerolls, Tainted Lazarus Flip, Clicker, Genesis, R Key or every shared-body identity. The audit records these as common gaps, alongside the full weapon/BR-timing/co-op/save matrix. Snapshot JSON stubs do not prove native serialization or a game restart. Two concrete text issues remain queued: normal Llama's solo-four dossier omission and ambiguous DeepSeek idle pocket-charge wording. Broad Continue targets versus explicit transient checks/tasks/cooldowns require reconciliation before any behavior change.

This unit changes documentation only. No stub, gameplay expectation, registration, art or save schema changes. The required full gate remains 69 Lua suites, 11 Python scanner cases, 184 Lua files, five XML files, assets/poses and interaction-report freshness. No runtime/game/settings/save access or new engine evidence; installed `8fd6a8c` remains untested by the owner.

## W2 audit finding: normal-Claude owner isolation (2026-10-26; offline only)

Baseline `cce5afd` fails an extension of `claude_usage_save_test.lua`: after a new live entity takes slot zero, its account still has the prior owner's age 5. Existing tests verified detached Continue, wrappers, two separate accounts and same-entity form-return debt; those are not the same as a different entity replacing an active-run owner.

The final regression also rejects four isolated faults: removing the pointer guard, removing the seed guard, retaining live identities across exit/start, and omitting replacement cache refresh. Each fails its intended account, Continue or damage assertion. Mutants run against private copies; they do not replace repository source.

The fix keeps pointer/InitSeed identity only in transient bindings. A changed live slot retires its saved account and stale item alias/volley/update/cache markers. Removed slots are pruned when observed. Continue clears the identity map before rebinding recreated players to the saved slot accounts. Same entity, same seed and a changed form still retain the deliberate old debt rule. No identity is serialized and no schema migration is needed.

New real-module cases cover a changed pointer with the same seed, reused pointer with a new seed, immediate cache correction, repeated unchanged observations without extra cache rebuilds, a shot before the next general update on the retired owner's frame, partner isolation, Compact's new-table alias, slot removal before save and later join, simultaneous slot reorder, and same-session Continue without reloading Lua. A review case exposed one replacement clearing the other's pending cache refresh during a swap; the correction finishes retirements before marking new refreshes. These remain supplied identity/callback fixtures, not observed native ordering.

`claude_appeals_test.lua` previously asserted that a replacement retained age 8 while losing only its pending Review. That single expectation now requires age 0 because the account belongs to the retired entity. The separate eight-award cap, Birthright shields, same-entity type-return debt, detached Continue and legacy shared-age migration controls are preserved. No test is removed/skipped; no B1 coefficient, reward or resource price changes.

The integrated gate remains 69 Lua suites plus 11 Python scanner cases, 184 Lua files, five XML files and asset/pose checks. Regenerate the interaction inventory for the changed source. No installation/game/settings/save access occurred; installed `8fd6a8c` remains untested. During a future authorized engine block, distinguish same-owner wrappers/Continue from actual replacement, revive/type changes and co-op join/leave/reorder; verify debt, age, pocket charge, caches and the unaffected partner. A removal not observed before the engine saves remains a timing case, not claimed coverage.

## W4.1 interaction scanner (2026-10-26; source tooling only)

`tools/audit_interactions.py` scans main.lua and all 109 production modules without executing Lua. At #106 its checked report contained 397 callback registrations, 109 candidate direct field writes, 11 selected mutator calls, cache-flag references and direct Risk state-root accesses. An independent literal-call count matched all 397 source locations; report links resolved within source line bounds. The checked report regenerates for later source changes. Shared fields do not prove shared receivers or erroneous order.

Eleven Python fixture cases test ignored comments/quoted/long strings, source lines, explicit/default priorities, multiline writes, direct versus indirect/literal assignments, misleading field-name prefixes, multiple assignments, cache flags/mutators, state read/write/dynamic/whole-table access, malformed regions, deterministic output and stale-report rejection. Initial fixtures fail because the tool is absent; additional review fixtures exposed omitted multi-assignment targets and false self-dependency substring matches, both corrected. The Tungsten source check deliberately classifies its local `speed` assignment as indirect, not a confirmed overwrite. No Isaac stub or gameplay expectation changed.

The full gate now runs 69 Lua suites plus 11 Python scanner cases and inventory freshness, with 184 tracked Lua files, five XML files and existing asset/pose checks. Run `python tools/audit_interactions.py --write` after production-source edits and review the generated section. The freshness gate does not certify candidate semantics or require the warning list to be empty. See [INTERACTIONS.md](INTERACTIONS.md) for scope limits and follow-ups, including ordinary-tear damage composition and source-owned state review. No child-billing policy work is reopened before E2.

No runtime, game, save or settings access occurred. Installed `8fd6a8c` remains untested; no new engine/visual acceptance.

## W1 inventory and style specification (2026-10-26; source audit only)

Baseline `8fd6a8c`. Reconcile `git ls-files` PNG/ANM2/font paths with [ART_STATUS.md](ART_STATUS.md): 198 unique documented paths, 173 PNGs and 25 ANM2, no missing/duplicate paths or bundled fonts. PNG headers confirm 22 512x512 sheets, 22 144x144 stage portraits, 22 384x576 dossiers, 11 128x32 names, 92 32x32 icons, three menu sheets and one thumbnail. XML supplies 22 forms, 80 collectibles, 12 trinkets and five pills without custom image references. Every icon stem resolves to its existing drawing function; each form's portrait/bigportrait share the same file.

The audit reads source/manifests and carries forward O5's visual findings; it does not newly render or accept the artwork. [ART_SPEC.md](ART_SPEC.md) selects a deterministic designed-icon pipeline and specifies its future validation tests. `check_assets.py` is unchanged and still requires exact placeholder bytes. W1.1 and the W1.2 guide are documented; W1.2 implementation and W1.3-W1.6 art production remain open. Static inspection also finds removed `ART`/`PALETTES` lookups and an obsolete PNG-writer signature in `make_thumb.py`; repair is queued separately, with no thumbnail overwrite in this unit.

The required full gate covers 69 offline suites, 184 Lua files, five XML files, deterministic assets and 22 skin envelopes. No new gameplay test is added for this documentation-only change. Native evidence is unchanged; the owner reported installed `8fd6a8c` untested. No game, settings, save or installed-mod access occurs in this unit.

## B1 installation (2026-10-26; files verified, game not launched)

The owner approved #102 and local installation. Its reviewed head 5eab1c2 merged at ef7d2dd; both have tree 206bec8ea1e44b6a4b0fd768fcd2de168dd1ed6d. PR-head and merged-main CI passed. The earlier 69-suite source gate therefore covers the identical merged tree.

Preflight matched every one of the 443 prior installed tracked files to f8b2b0b. A fresh allowlisted backup passed reread SHA-256 verification before any replacement. Installation updated 102 paths including eight new paths; all 451 tracked files matched canonical ef7d2dd bytes afterward. No paths were removed. Private receipts and backup manifests remain local.

The game was closed before and after replacement; no launch, input, settings edit or save access occurred. This verifies deployment only, not any B1, O4, O5 or E2-E5 native case. Documentation-only synchronization may follow; the local receipt records its exact deployed SHA separately from this gameplay checkpoint.

## B1 revision status (2026-10-26; all 22 features, offline only)

The owner rejected direct numerical weakening in draft #100 and requested added character-specific features/tradeoffs. #100 is superseded and must not merge. [DIFFICULTY_FEATURES.md](DIFFICULTY_FEATURES.md) specifies the 22 conditions implemented in #102 while preserving the original coefficients. #102 is now owner-approved, merged and installed as recorded above. No game version has exercised these new mechanics. The integrated offline gate covers 69 suites, 184 Lua files, five XML files, deterministic assets and all 22 skin envelopes; PR-head and merged-main CI passed. These counts are offline evidence only.

The first eight conditions were committed at 1422d81: safe-room reset/release, drying delay, one-second sight loss, helper range/lifetime, combat-only baking, clear-triggered recovery and completion range/sight. Fourteen more extend the same PR. Existing character suites retain baseline damage, resource, pause, duplicate, co-op and continuation controls while gaining the following regressions:

- Claude: unearned floor age is withheld; early/last/simultaneous kills, deterministic selection, target loss, saved target keys, identity/type changes and the age cap. Tainted review freezes during shooting without spending another Page; its six-second reward stays unchanged.
- DeepSeek: movement refuses/cancels intrinsic Rice once, refunds within cap, grants no cancellation reward and leaves partners/unrelated meals/foreign cooldowns intact. Peak reserves and refunds existing Compute once across phase, floor, Continue and Birthright-cap changes; existing non-tear 1.3x and payment controls remain.
- GPT/Grok: paid attacks are aggregated independently of target callback order, including a later piercing hit and zero/cap clamps. Partners, helpers and unpaid hits are excluded. Birthright mid-check cannot recover lost historical progress; quote transfer preserves prior attack identity. The integrated Llama-helper fixture now waits for the real end-of-update settlement instead of expecting immediate verification.
- Gemini: 29-degree rejection, 30-degree acceptance, zero separation, repeated paid identity, partners, timer and Birthright. Qwen: continuous silent installation/restart, room exit and saved partial install; pinned choices, unique clears, award-cap release, fresh floor and legacy migration.
- Mistral: stored movement direction despite changed aim, initial free turns, steady replacement charge, gradual-turn rejection, pause/duplicates, Continue and legacy Down fallback. Doubao: cone boundary and range, behind-player bullet relief, saved aim and owner isolation.
- Kimi: only the current speaker is amplified, focus advances without returning to a revived earlier member, all audience slows persist, and invalid targets are removed. Tainted paid hits refresh a one-second pause without stacking; helpers/direct task pulses/partners do not, and room budget is unchanged. GLM: one missed-ticket decrement per new hostile entry, with revisit, safe-room and Continue controls.

The full-module smoke fixture now models native position/enemy queries needed by Review and verifies that merely changing floors earns no age. Its remaining cache/suspension controls explicitly seed earned age. Supplied fixtures test module behavior, not native input filtering, callback order, entity reconstruction or balance. Legacy state migrations and limits are detailed in DIFFICULTY_FEATURES.md; broad O6 save/continue work remains separate.

During a separately authorized game session, run this B1 matrix in addition to E3-E5. Record exact build/game version, form, equipment, observed HUD and outcome; a table row is not an acceptance claim.

| Family | Normal form: required native cases | Tainted form: required native cases |
|---|---|---|
| Claude | Two-enemy review, early versus last/simultaneous kills, suspension, multi-phase boss, room exit and Continue. | Hold/charge/release native weapons during review, then stop; timer, Page and Quota, pause and Continue. |
| DeepSeek | Stand/move/knockback, cancel at meal end, overlapping Lunch Break/food, native FireDelay, Continue and co-op. | Valley/Peak with 0-4 and full Compute, Saving, BR gain/loss, floor/Continue; confirm original tear and non-tear costs. |
| GPT | Off-target versus focused hits, piercing/explosion order and delayed hits, BR mid-check, long sustained combat and helper control. | Bank Tibo, attempt during combat, claim safely once; Full Send toggling and Continue. |
| Gemini | Drying boundary, early target kill, BR and ordinary/native area weapons. | Orbit by less/more than 30 degrees, overlap target, leave/return, multi-hit weapons, Export once. |
| Grok | Brief and sustained cover around rocks/doors, target invalidation, verification and spent room attempt. | Quote-only versus another enemy, same/delayed attack on both, Ratio clamps, BR transfer and expiry. |
| Qwen | Stop/hold/charge fire through installation, exit before finish, co-op and Continue. | Choose in safety, reject while pinned, two unique clears, revisits, award cap, floor reset and Continue. |
| Llama | Reject combat Release without spending, use safely with co-op/BR and native fly modifiers. | Cross 120-unit boundary around a stationary demo, expiry while away, return without catch-up, helper accounting. |
| Mistral | Turn aim after charge, initial free turns, stable replacement, slow rotation, idle loss, walls and saved direction. | Bake only during hostile combat, safe partial pause, held bread, firing/movement, room/Continue. |
| Doubao | Aim/no aim, 60-degree edges, enemies at 100 units, bullets behind, saved aim, no healing. | Clear while Confident versus Apology, duplicate/wave clears, safe-room pause and next-room recovery. |
| Kimi | Three audience members, visible current speaker, death/friendly/revival ordering and expiry. | Assign then shoot versus leave delegated, rapid refresh, own helper/partner controls, resume without catch-up and same budget. |
| GLM | Queue 3 claim versus missed next new fight, revisits, peaceful rooms, active pass and Continue. | Completion inside/outside 200 units with/without sight, early death versus invalid target, Retry and cooldown. |

O4 #101 and O5 #103 are included in installed gameplay checkpoint ef7d2dd. The owner supplied no usable checklist result. Implementation was offline; the later installation above did not add native acceptance.

## O5: Hit, Death and side poses (2026-10-26; offline geometry only)

Baseline ffc52bf. [All 22 findings, commands and limitations](POSE_REVIEW.md). The preview samples 45 native skin-layer keyframes/combinations per form using only mod pixels; native ghost, tint, interpolation, overlays and input are omitted. Reference ANM2/skin remain private. No game was launched or installed file changed.

All 22 Hit cells already meet 28x32/bottom-55. The three other Death storage cells were oversized; the new standard-library check fails on all 66 cells before correction and passes afterward. Upright limits are 28x33/bottom-57; the actual fallen crop is 36x27/bottom-59 (storage bottom-61). Llama's Death-start source crop also needed its full body retained. No anatomical redraw.

All 22 sheets have nonempty sampled cells, no sampled crop-edge contact and mirrored left/right geometry. Each has ten side-body keys, with five or six unique stride images. Repacking reproduces the candidate bytes; comparison to baseline confines changes to three storage cells. Menu/portrait bytes and all other skin pixels are preserved. The decoder equals Pillow's RGBA bytes for all 22 skins. Full offline gate and preview determinism are required before commit; no engine/visual acceptance follows from them.

Shared cells also affect Appear, pickups, travel, jumps and other animations listed in POSE_REVIEW.md. Native acceptance must cover those, damage recovery, the full death/ghost sequence, movement/fire, costumes, size, flight, revival and other mods. B1 status is maintained above and #100 is superseded; these geometry results do not validate difficulty changes.

## O4: effect layers and departure restoration (2026-10-26; source and stubs only)

Baseline `aef6de9`; installed `f8b2b0b` is preserved. This audit reads the service, the existing bundled vanilla resource XML and public API documentation; no game version was run. Resource files remain private. `ClearCostumes` covers all costumes, while `AddPlayerFormCostume` restores a transformation's visual layer. The service never calls `ClearTemporaryEffects`, removes a weapon/effect entity or writes flight/scale. That is a source boundary, not proof of native rendering or mechanical compatibility.

| Item/state | Costume versus separate effect | Does the current lock remove it? | Player-visible consequence / uncertainty | Required engine case |
|---|---|---|---|---|
| Fate | Passive costume 179 (`179_Fate.anm2`), marked `isFlying`; item caches flight. | Its costume is cleared; flight cache is not written by the lock. | Wings may disappear while pit crossing still works. | O4-FLIGHT: acquire Fate, cross pits, room/continue; compare Isaac. |
| Holy Grail | Passive costume 184, `isFlying`; item caches flight and grants health. | Costume yes; no inventory/health mutation. | Wing/body layer can disappear; actual flight and heart grant require observation. | O4-FLIGHT: Grail alone, then opposite order with a face item. |
| Dead Dove | Passive costume 185, flying and skin-color attributes; item caches flight/tear flags/color. | Costume yes; flags/cache fields not directly removed. | Ghost/wing presentation can be hidden; test spectral shots separately. | O4-FLIGHT: pits, rocks and wall-adjacent shots, restart. |
| Spirit of the Night | Passive costume 159, flying and skin-color attributes; flight/tear cache. | Costume yes; no direct weapon/effect deletion. | Black/ghost appearance can be hidden; do not infer broken flight from that. | O4-FLIGHT: flight and spectral behavior, with normal/tainted forms. |
| Seraphim / Beelzebub / Leviathan | `playerforms.xml` maps forms 3/1/8 to null costumes 21/3/26, separately listing flight cache. | Cleared while locked. O4 now requests their acquired costumes once after leaving a mod form. | Fixed mod look remains. A vanilla destination previously had no explicit form-layer restoration; final priority/timing still needs observation. | O4-EXIT: acquire each naturally, Clicker/revival to vanilla, leave/return/continue; verify flight and form flags. |
| Holy Mantle / Holy Card shield | Mantle has passive costume 313; `items.xml` sets `addcostumeonpickup=false`, indicating state-driven rather than unconditional pickup appearance. Shield state and any break feedback are separate native behavior; XML alone does not identify every render component. | Costume 313 is cleared when present. This service does not remove a temporary effect or intercept damage. | May hide the readiness cue. Generic `AddCostume` on departure may also show an inappropriate state cue; whether the engine immediately corrects it is unobserved. Do not restore shields with `AddCollectibleEffect` just to draw a cue. | O4-SHIELD: ready/spent Mantle and Holy Card, blocked first hit versus next hit, new room, exit from mod form and continue. |
| Godhead | Player costume 331; tear properties/aura are not the player's costume object. | Player costume yes. No tear or effect sprite is directly cleared by this service. | Face/halo layer may vanish; actual tear halo/damage and render ordering remain native cases. | O4-WEAPON: fire ordinary/homing tears before/after sweep; compare aura and damage on Isaac. |
| Brimstone | Passive costume 118 plus null variant 45; the beam is a native laser entity. | Costume yes; no laser removal or flags written by the lock. | Facial overlay can disappear; beam origin, charge/fire pose and mixed weapons need observation. | O4-WEAPON: charge, hold/release, room changes, Brimstone + Technology, with size/flight. |
| Mega Mush | Active costume 625 (`big_isaac.anm2`, priority 1000); item has a persistent timed effect and cache-all. | High costume priority does not exempt it from `ClearCostumes`; the timed effect itself is not removed here. | Giant replacement can be suppressed while native scale/collision persists. This may be confusing or misaligned; it is not accepted. | O4-SIZE: activate, move, stomp/fire, expire, room exit and continue; inspect hitbox/pose alignment. |
| Magic Mushroom / Binky / size pills | Items cache size; Binky also has costume 438. Scale and a costume are different mechanisms. | Binky costume yes; service never writes SpriteScale/Size or size cache. | Body/weapon scaling may still work, but baked art could clip. | O4-SIZE: repeated size changes in both orders with wings/weapons, then removal/reroll. |
| Leaving any mod form | Held-item restoration and, after O4, currently acquired native form costumes. Temporary/trinket/external layers have no generic replay here. | Clear stops after departure; restore runs once, not every vanilla update. | Repairs the explicit form omission. Native destination rebuild timing, remaining layers and duplicate visual priorities remain open. | O4-EXIT: vanilla partner control, mod-to-mod, mod-to-vanilla, multiple forms, D4/D100, revive and restart. |

The O4 fix asks `HasPlayerForm` for IDs below the runtime `PlayerForm.NUM_PLAYER_FORMS` sentinel and calls only `AddPlayerFormCostume` for acquired forms after departure. It does not use AddCollectible, AddCollectibleEffect, ChangePlayerType or cache evaluation. The added costume-lock regression fails on aef6de9 at the missing transformation restoration, then passes with the fix. It covers Guppy/form zero, multiple acquired forms, no false forms, one-time restoration, mod-to-mod exclusion, a vanilla partner, changing form sets and an expanded runtime sentinel. Flight/scale/damage stay unchanged in the stub; these assertions do not emulate the renderer.

Visual-policy options remain open: (A) retain the current fixed costume rule and report missing native cues; (B) after observing the native states, allow specific readiness/flight costumes while retaining the skin; (C) a new minimal cue designed separately. B changes the appearance policy and C adds UI/art, so neither is implemented without the owner's choice. No broad allowlist is inferred from possession alone, especially for spent Mantle or an expired timed effect. O4-EXIT is a bounded source fix; O4-FLIGHT/SHIELD/WEAPON/SIZE remain E5 acceptance work.

Sources: [EntityPlayer costume APIs](https://wofsauge.github.io/IsaacDocs/rep/EntityPlayer.html#clearcostumes), [PlayerForm enumeration](https://wofsauge.github.io/IsaacDocs/rep/enums/PlayerForm.html), [costume XML fields](https://wofsauge.github.io/IsaacDocs/rep/xml/costumes2.html), [temporary effects](https://wofsauge.github.io/IsaacDocs/rep/TemporaryEffects.html). Bundled XML was inspected locally, not redistributed. Full offline gate required before commit; no deployment or new engine evidence.

## M1/D2: owner reporting and current-record consistency (2026-10-26; documentation only)

MANUAL_TEST_CHECKLIST.md supplies 14 checks and explicit OK criteria for one or two ordinary runs, including current difficulty feedback. It does not claim the unapproved difficulty pass is installed. Current records separate live main, reviewed gameplay and installed f8b2b0b; obsolete installation claims were removed without editing history files. The full offline gate is required before commit; no additional game session is performed.

## E1 deployment / E2 attempt (2026-10-26; installation verified, gameplay deferred)

See [the dated record](ENGINE_AUDIT_2026-10-26.md) for the exact source/tree and startup limits. E1 is complete at f8b2b0b; E2 has zero native samples and E3 has zero fresh starts in this session. No E4/E5 case ran. The explicitly loaded observer remains inactive. Physical input, costumes, weapons, saves, co-op, new items and base Repentance remain unaccepted. Do not reopen child-billing fixes from this startup attempt.

## E2-PREP: explicit native ancestry observer (2026-10-26; offline preparation)

The observer in `tests/laser_ancestry_probe.lua` is never loaded by main.lua. It records scalar laser/Parent/SpawnerEntity fields at actual init/update callbacks only after explicit Start, with 900-frame and 2000-attempt bounds and automatic callback cleanup. It does not create the test scenario or change billing. The old runtime_probe changes gameplay/save state and is not this observer.

`tests/laser_ancestry_probe_test.lua` passes inert loading, metadata validation, nil/changing link snapshots, duplicate-start protection, manual/room/run/exit/time/cap/error cleanup and a main.lua non-activation check. Its supplied entities are not observed engine entities. The integrated gate passes 69 offline suites; the branch contains 182 tracked Lua files, five XML files and deterministic assets. No game version was exercised, and no installation or settings changed.

Follow [ENGINE_ANCESTRY_PROBE.md](ENGINE_ANCESTRY_PROBE.md) only after the owner authorizes a backed-up installation and muted disposable-run session. E2 still needs actual Tech X, Prism, Trisagion and Brimstone/Technology observations with verified source, game version, scenario and bounded redacted logs. E3-E5 and new-item engine checks remain pending. This preparation does not reopen child-laser billing work.

## O3: native transformations and Tainted mechanics (2026-10-26; source audit only)

Reviewed main `ef42b13`; no game version was exercised. This table records source paths and inferred risks, not engine compatibility. No clear source defect was established in these paths, so this audit changes no gameplay code. The audited ef42b13 passed the 67-suite gate and contains 177 tracked Lua files. Integration with merged O2 at 178269b passes 68 suites with 180 tracked Lua files; it changes no O3 gameplay path. Engine cases remain part of E4/E5, waiting for owner availability. No installation was performed during that audit; see the current checkpoint above.

| Item or mechanic | Our code path | Expected risk, not a confirmed engine bug | Engine case to run |
|---|---|---|---|
| Guppy, Beelzebub, Seraphim and Spun | `characters/costume_lock.lua` clears costume layers only for roster forms. `transformation.lua` separately caches the mod's Agentic bonuses. | Cleared wings/effect layers can hide a working native transformation. Stats and flight compose with mod cache callbacks; visual absence alone does not prove loss of the native effect. | Acquire each transformation normally; record native form flags, flight/size/stats and actual attacks. Compare mod and vanilla forms before/after a room change and continue, with and without Agentic. |
| Agentic with D4/D100 or native inventory changes | `transformation.lua:countSet` checks current holdings on the next player-effect update, then refreshes flight, tears and damage. Active uses mark the costume lock dirty. | The latch can retain the previous inventory decision until that update. Native reroll/cache order and concurrent flight effects are unobserved. | Reroll from three qualifying items to fewer and back. Check that the mod bonus follows current holdings, native flight remains when independently granted, and there is no permanent stat accumulation after continue. |
| Bag of Crafting and Tainted Cain | No bag-recipe or bag-content override. `drop_tap.lua` observes DROP; `meal_break.lua` suppresses directional shooting during meals. `items/backlog/deepseek.lua` and `items/claudius_discount.lua` observe heart gains/purchases rather than bag contents. | Native bag controls may share actions with mod abilities or meal suppression. The multi-pocket guard does not establish safety for every single-pocket native action. Crafting is not equivalent to an ordinary pickup. | Test collecting, cycling bag contents and crafting with Bag as main/pocket active, alone and with a card, during/after meals. Compare Tainted Cain, vanilla Isaac and mod forms; inspect One Bowl/discount rewards and ensure no unintended ability fires. Do not infer Tainted Cain's full trait from item ownership. |
| Tainted Eden damage rerolls and changing player type | No Eden-specific reroll implementation. Item modules re-check holdings; Agentic updates as above. `costume_lock.lua:Restore` restores held collectible costumes on leaving a mod form, not transformation/temporary layers. | A D4 test on a mod form does not test Tainted Eden's native damage mechanic. Form transitions can leave missing non-collectible layers or stale character state; callback order is unobserved. | Run actual Tainted Eden with mod items, then permitted Clicker/revival transitions between vanilla and mod forms. Check inventory, cache bonuses, character HUD/resources and layers after a real hit, room change and continue. Record the actual player type. |
| Holy Card, Tainted Lost and The Constitution | No Holy Card/Mantle override. Card use marks the costume lock dirty; `items/constitution.lua` may cancel an eligible real hit before later callbacks, without inspecting Mantle charges. | Fixed looks may hide shield visuals. Native shield consumption versus Constitution cancellation order is unobserved; two protections might be consumed together. A carried Holy Card is not the Tainted Lost player type. | Test Holy Card with and without Constitution on mod forms and actual Tainted Lost. Record shield state, first/second eligible hit, Constitution's used flag, health/death, room changes and continue. Compare visible shield and actual protection separately. |

Read-only inspection covered the named modules, their registration order in `main.lua`, roster identity and existing costume/meal/Constitution fixtures. The source has no Bag of Crafting, Tainted Cain/Eden/Lost or Holy Card-specific overrides; that absence is not a compatibility pass. Existing fixtures do not model native transformations, crafting recipes, Eden rerolls or shield consumption. Do not add replacements based only on these inferred risks.

API boundaries: community [ClearCostumes](https://wofsauge.github.io/IsaacDocs/rep/EntityPlayer.html#clearcostumes) documents costume removal, while [HasPlayerForm](https://wofsauge.github.io/IsaacDocs/rep/EntityPlayer.html#hasplayerform) and [ChangePlayerType](https://wofsauge.github.io/IsaacDocs/rep/EntityPlayer.html#changeplayertype) distinguish form queries from changing character type. REPENTOGON exposes [bag-content access](https://repentogon.com/EntityPlayer.html#getbagofcraftingcontent) and [RerollAllCollectibles](https://repentogon.com/EntityPlayer.html#rerollallcollectibles), but those extension APIs are not base Repentance contracts and are not introduced here. Repeat acceptance on base Repentance and Repentance+ before claiming both supported.

## MEME-BATCH-02: native shovel and Six Seven (2026-10-26; offline passed, engine pending)

Source: PR #95 (`codex/meme-batch-two`, head a58be61), merged at 178269b after the owner approved the exact rules and merge on 2026-10-26. No game version was exercised and no installation was performed during that audit. The full gate passes 68 offline suites; the source contains 180 tracked Lua files, five XML files and deterministic assets. The inventory is 80 collectibles, 12 trinkets and five pills; new XML entries are appended, preserving existing order. The original shovel placeholder was inspected at its native 32x32 size, which is not in-game visual acceptance.

`tests/meme_batch_two_test.lua` checks one native shovel delegation per primary wrapper use, a modeled nested callback without recursion, Car Battery repeat suppression, independent uses, no delegated active-slot ownership, no duplicate animation/wisp request, NOHUD, both seeded six/seven outcomes, repeat pill uses and co-op isolation. It does not execute any native effect. Registration, EID counts, English descriptions, generated ITEMS.md and icon reproducibility pass the existing gate. [Design, approved rules and API references](MEME_BATCH_2.md).

After an authorized installation, test ordinary and restricted shovel rooms, crawlspaces/trapdoors and floor transitions; primary, Schoolbag and pocket use; stored charge, Car Battery, Void and Book of Virtues. Test Six Seven with ordinary/horse/golden pills, Placebo, Echo Chamber, Fish Tail, co-op and continue. Observe actual flies, damage, charge, animation and text on both Repentance and Repentance+. Every pill size intentionally uses the same six-or-seven roll; native fly modifiers may change the actual number spawned. This is the owner-approved balance rule, not a verified horse-pill interaction.

## O1: reserve multi-pocket DROP for native cycling (2026-10-26; offline correction, engine pending)

Owner choice: retain short DROP; disable character abilities when multiple pocket items are present. The shared tracker covers cards/pills in slots 0-3 and both pocket actives, excludes main/Schoolbag actives, and cancels a conflicted gesture until release even if the inventory later shrinks. It never intercepts native input. All 22 form consumers retain their existing timing and readiness rules.

The expanded `tests/drop_tap_test.lua` fails on main `2182cb1` at card + pocket active, then passes with the correction. It covers all card/pill slot pairs, pocket-active combinations, empty/single controls, inventory changes at press/hold/release and twice within one frame, clean rearming, co-op and the existing interruption/hold rules. The real Rice/Meal regression supplies pocket rotation before or after a mod update and now verifies no bowl or meal is spent, while native polls and another controller remain untouched. This is modeled input, not native pocket timing. See [the review](DROP_POCKET_REVIEW.md) for API references and limits.

All character ability instructions below assume at most one pocket item. E4 must additionally test card + pocket active, multiple cards/pills, both pocket actives, slot 2/3 contents, item use/pickup during a press, keyboard/controller, long holds, pause, room changes, death/ghost, co-op and rearming after inventory reduction. Check ordinary cycling/use/drop, MAP/EID readability, Schoolbag/Marked and both supported game variants separately. The full gate passes 67 suites, 177 tracked Lua files, five XML files and deterministic assets; five focused mutations fail the pocket regression. This is offline only; no deployment was performed during that audit. Game version: not exercised in this audit.

## D2: second handoff compaction (2026-10-27; documentation only)

The canonical `docs/HANDOFF.md` from main `61f7f17` (after #130) is retained in full after the archive preface in `docs/HANDOFF_HISTORY_2026-10-27.md`. A byte comparison verifies all 51918 original bytes, SHA-256 `3715290315b7166adeeeecd58dab33da5c7218c98121a38c7bf5e1bdbce83012`, including every dated entry for #104-#130. Older archives are unchanged.

The current handoff is about 15 KB. Twenty-seven dated entries become one "Recent units" table that links each audit. The queue, decided rules, open owner decisions and an E6 full-run row are stated once, together with a size rule for future entries. No gameplay, assets, saves or installed files change, and no engine or visual acceptance is added. The complete offline gate passes.

## D1: handoff compaction (2026-10-26; documentation only)

The canonical `docs/HANDOFF.md` from main `a1d4d7a` is retained in full after the archive preface in `docs/HANDOFF_HISTORY_2026-10-25.md`. A byte comparison verifies all 104075 original bytes, SHA-256 `710299327fb32162c5657ef9fa91601d927ce61892a3f98014b90be1d6f8553a`. This includes every dated log older than 2026-10-25 and the full recent notes; no historical wording or old evidence is rewritten. The older 2026-10-24 archive is unchanged.

The current handoff is under 30 KB, begins with Start here and keeps its new dated entries to at most five lines each. Its source/install/owner-feedback summary and contributor entry points now agree. Review the docs-only diff and run the complete gate: 67 offline suites, 177 tracked Lua files, five XML files and deterministic assets. No runtime, saves or game settings are changed; no engine or visual acceptance is added.


## BACKLOG-LASER-INIT-01: Parent loss before the first update (offline passed; engine pending)

The backlog observes laser initialization to retain a known child and any already resolved parent lease. This does not create a primary attack: first-update payment remains unchanged. The expanded child-laser fixture passes 16 groups. Five of the six new groups fail on immutable `220d542`; the new primary-timing control and ten existing groups pass. Six targeted faults fail: missing init observation, classification without inheritance, primary payment at init, child payment at init, renewed expiry and lost classification on a room reset. These are supplied callbacks, not observed native ordering.

After an authorized deployment, record Parent and SpawnerEntity at initialization, first update and damage for Brimstone/Technology reflections and Tech X splits. With a resolved Base Model/Rice Cooker parent bonus and a different next prime, a child that loses Parent before first update should retain only the parent's bonus and identity; the next primary should still consume its prime. Check One More Finger, Sanity Test, Community Note and Consensus Coin for extra attacks/hits, including a child hitting before its first update and nested generations. Repeat with Peak, Opus and other damage callbacks; inspect actual damage rather than relying only on counters.

Test unresolved child-first ordering: it must not synthesize a parent attack. It may inherit after the parent resolves while an explicit ancestry link remains available. If the link disappears before any parent lease is resolved, the child remains free and unboosted. Test non-laser parents, missing spawners, conflicting players/familiars, the original 120-frame expiry, room transitions, new runs and native save/continue on both game editions. Native init fields may be incomplete; unknown or later-only ancestry is not accepted by these stubs. Keep current installed `220d542` unchanged during owner testing until another installation is requested.

## DETACHED-LASER-01: child identity after Parent loss (offline passed; engine pending)

`tests/child_laser_billing_test.lua` now passes 14 real-module callback groups: the original seven pass on baseline `9fc2786`, while all seven new detached-child groups fail there. The new groups register real Opus, backlog and three allowance forms in main's order. They check resource/coin balances, the next primary window, unchanged native fields, init-only and update-only classification, paused/young updates, room/run boundaries, a new entity reusing a pointer hash, item acquisition and changed co-op ownership. `tests/peak_child_laser_test.lua` adds a passing damage-first child control (13 groups total), retaining Peak's optional exclusion when shared init/update callbacks never saw the Parent. Eight targeted mutations fail. Native callback order, entity recreation and save serialization are not simulated acceptance.

After an authorized verified deployment, test native reflections and split lasers on normal Claude, tainted Claude, tainted GPT and tainted DeepSeek, with and without Opus. Observe whether Parent is set at init or an early update and whether it disappears while the child survives. When that ancestry was observed, subsequent child updates must not change allowances, Compute, Opus's counter or wallet. With Opus at nine attacks, the next independent primary must still spend one coin; children cannot spend it or delay that primary's payment window. Check pause, released versus held beams, nested splits, room/floor changes, save/continue, two players and other mods on both game editions.

Record actual Parent/SpawnerEntity values, frames, damage and visuals. A child whose ancestry is never observed remains unresolved; this change does not guess from its player spawner or refund an earlier initialization payment. Damage and parent-boost behavior remain subject to the separate BACKLOG-CHILD-LASER-01 and PEAK-CHILD-LASER-01 cases. Installed `c6cd8fc` includes the backlog correction but predates Peak and detached-observer corrections.

## PEAK-CHILD-LASER-01: parent Compute and boost (offline passed; engine pending)

`tests/peak_child_laser_test.lua` drives real Opus, backlog, Peak and paid-observer callbacks in main's order. Twelve groups pass; eleven fail on immutable `c6cd8fc` and the existing identity-exclusion control passes. Eight injected faults fail. Cases cover Valley/Peak prices, duplicate and delayed children, primary controls, paid/unpaid decisions, inclusive expiry, subsequent held windows, child-first/nested ancestry, detached or despawned parents, cycles, conflicting sources, co-op bindings, room/run cleanup and one modeled damage application through combined modifiers. Existing Peak lifecycle and shared-observer suites also pass. The fixture's continue boundary reuses modeled saved state; it is not a native save/continue test.

After an authorized verified deployment, test Brimstone/Technology reflections and Tech X splits on tainted DeepSeek. Compare Compute and actual damage in Valley, Peak, Saving mode and low-Compute states: children should cost nothing extra and share only the parent's resolved 1.3x boost. Held children must stop at the parent's original deadline, follow a later paid window and lose the boost immediately when the parent receives an unpaid window. A child's OneHit/ring flags must not extend that deadline. Verify primary starts and later windows still cost 2/4 Compute.

Record native Parent/SpawnerEntity values and callback timing for child-first creation, multiple generations, parent removal and surviving child hits. Unknown or late Parent links remain unaccepted; the source does not infer ownership or retroactively refund a callback already billed before its ancestry was known. Check two owners, familiars, ordinary character changes, pause, room/floor changes, save/continue and both game editions. Repeat with Opus, Base Model/Rice Cooker, Finger, Sanity Test and other damage mods: no extra wallet charge, consumed prime or duplicate applied damage. Detached-child handling for other paid-observer subscribers remains a separate review area.

API references: [Entity.Parent](https://wofsauge.github.io/IsaacDocs/rep/Entity.html#parent), [Entity.GetData](https://wofsauge.github.io/IsaacDocs/rep/Entity.html#getdata), [EntityLaser.OneHit](https://wofsauge.github.io/IsaacDocs/rep/EntityLaser.html#onehit). These describe fields and transient storage, not the timing or compatibility of this implementation. Installed `c6cd8fc` predates this correction.

## BACKLOG-CHILD-LASER-01: inherited parent attacks (offline passed; engine pending)

The backlog now inherits a resolved parent laser lease without consuming new primes, emitting an attack event or restarting its 120-frame lifetime. Parent and child share the laser source category and attack identity. Child-first updates/hits never synthesize a payment; later callbacks can resolve a subsequently observed parent. Detached resolved children retain the original lease, while foreign/familiar/unknown ownership, expiry and room/run cleanup prevent inheritance. These source rules do not establish when native Parent links appear or disappear.

`tests/backlog_child_laser_test.lua` drives ten real-module groups; all fail on `475bd15` and pass with the correction. Five targeted mutations fail. Coverage includes primed parent versus next-primary damage, Finger scheduling and LastAttack, shared Sanity/Community Note progress, first-hit and Consensus categories, inclusive expiry, nested/child-first ordering, detached references, room/run resets, co-op owner conflicts, familiars and unknown sources. Native laser fields remain unchanged in the fixture.

After a separately verified deployment, test Brimstone/Technology reflections and Tech X splits with primed Rice Cooker or Base Model, One More Finger, Sanity Test, Community Note and Consensus Coin. A child must carry its parent's resolved bonus and attack identity without consuming a newly primed next attack. Parent plus children cannot count as multiple distinct hits on one target. An independent primary still consumes its prime and advances items. Observe actual source/parent links, before/after-parent callbacks, parent removal, lease expiry, co-op, room transitions and save/continue on both game editions. Check damage once through other callbacks, including Peak and other mods. Do not assume unknown native ancestry is covered. Installed `28fed37` predates this correction; Peak's separate child Compute/boost issue remains unresolved.

## LLAMA-HELPER-01: stationary helper accounting (source correction; engine pending)

Tainted Llama's helper uses the shared scoped `FireDerived` path, preserving its native tear arguments, stationary origin, nearest-enemy aim and 0.5x damage multiplier. This excludes it from Opus's ten-attack coin counter, next-attack primes and backlog paid-attack item events. Main passes the initialized backlog service; Hype costs, duration, Birthright and saved state are unchanged. The installed `28fed37` checkpoint predates this correction.

`tests/llama_helper_billing_test.lua` drives seven real-module groups: wallet/prime retention, Finger and Sanity triggers, stationary native shot arguments and modeled damage, co-op isolation, nil recovery and later Ludovico windows. All seven fail on `28fed37` and pass with the correction; three targeted mutants fail. The separate Hype lifecycle test retains duration, pause, replacement and saved-state coverage. Synchronous callback order and engine field inputs are simulated, not observed in game.

After verified deployment, create a helper with Opus, a primed Base Model, One More Finger and an active Sanity Test target. Observe helper shots without firing: the helper should hit normally without spending coins or primes, scheduling Finger extras or advancing Sanity Test. Then fire primary shots: primes and item counters must work normally, and ten primary attacks must still cost one coin. Test helpers near expiry, replacements and room exit, nil/failed native creation where observable, pause and save/continue; Hype persists but the transient helper does not. Repeat with two owners, native homing/piercing/split effects, Swarm, 1M Context, Ludovico and weapon replacements. Record native callback order, damage and ownership separately from the offline fixture.

## OPUS-DERIVED-01: backlog helpers and coin billing (offline passed; engine pending)

`tests/opus_derived_test.lua` registers real Summary Stapler and Opus before the real backlog, matching main.lua. On `3482ea1`, seven of eight groups fail; Summary Stapler's intentionally normal-shot billing passes. The corrected path keeps the wallet and attack primes unchanged for FireDerived, Please Retry and One More Finger, including nested creation, another player's synchronous normal shot, nil/error returns and explicitly marked derived tears. The next ordinary shot still counts, and the tenth costs one coin. Nine injected faults independently fail. Existing `derived_billing_test.lua` separately covers four character resource balances and an active Limited penalty. Neither fixture proves native dispatch or save timing.

When engine testing resumes on this candidate, use Opus with Please Retry and One More Finger. Compare the coin counter and wallet after helper volleys, the fifth-shot helper and ten primary shots. Check damage/tear effects, primed Base Model, held Ludovico helpers, room changes, pause, co-op owners and save/continue. Summary Stapler must keep normal-shot billing. Repeat representative cases with Swarm and weapon replacements on Repentance and Repentance+. Tainted Llama's separately emitted helper is outside PR #82 and has its own LLAMA-HELPER-01 follow-up above. Record the installed commit; the manual-test build `28fed37` includes PR #82 but not LLAMA-HELPER-01.


## CONSENSUS-FAMILIAR-01: familiar projectile attribution (offline passed; engine pending)

`tests/consensus_familiar_test.lua` exercises the real backlog service and Consensus Coin listener with direct familiar contact and familiar-linked attack entities. Main `797a560` resolves a familiar spawner's owner but labels the projectile `other`, missing a pulse after the owner's tear. The correction keeps familiar attribution, including the Parent fallback, without creating player attack leases. Six regression groups cover source categories, repeat hits, two owners, unknown sources and retained player primes; five injected faults fail. These entity shapes simulate ownership; they do not prove native Incubus, Twisted Pair or other familiar ancestry.

When engine testing resumes, hold Consensus Coin and hit one target with an own tear, then an owned Brother Bobby/Incubus/Twisted Pair tear within two seconds: expect one 0.5x owner-damage pulse. Test blue-fly contact, a familiar beam and a familiar knife; record actual SpawnerEntity/Parent links. Familiar contact plus familiar projectiles alone must not count as two categories. Repeat after the window, with repeated hits, a second target, another player's familiar, a primed Base Model attack, helper tears, room changes and save/continue. Familiar attacks must not consume player primes or advance paid-attack item counters. Verify player-only character target abilities remain separate. Test base Repentance and Repentance+ before claiming compatibility.

## CHARGED-USE-01: The Battery and charged-use rewards (offline passed; engine pending)

`tests/backlog_more_test.lua` uses the real backlog service and family listeners with separately modeled primary and battery charge. Main `a476559` misses a `4+4 -> 4+0` stored-charge use; the corrected observer compares the sum for the used slot. Positive controls cover ordinary depletion and all four active slots. Negative controls cover an unchanged/refused use, equal-total transfers, net gains, foreign-player/slot changes and excluded callbacks. The test checks Base Model's prime, Please Come Back's progress reset and Access Pass's benefit. Neither charge bars nor discharge callback timing are native in this fixture. The API exposes them separately: [GetActiveCharge](https://wofsauge.github.io/IsaacDocs/rep/EntityPlayer.html#getactivecharge) and [GetBatteryCharge](https://wofsauge.github.io/IsaacDocs/rep/EntityPlayer.html#getbatterycharge).

When engine testing resumes, give a holder The Battery and an ordinary room-charged active, fill both bars, and test the first use followed by the second. Check Base Model's next attack, Please Come Back's clear counter and Access Pass's once-per-floor damage benefit in hostile and cleared rooms. Repeat with Schoolbag, a pocket active, Car Battery, a refused use, a second co-op holder and save/continue. Record the charge values before use and over the following two updates. Confirm no charge is added or consumed by this observer. Full immediate refunds can leave no net charge loss; Bethany soul/blood pools and any longer native discharge delay remain outside this fix's acceptance scope.

## CONSTITUTION-COOP-01: independent holders (offline passed; engine pending)

`tests/constitution_players_test.lua` exercises the real item callbacks with two holders. Main `9805683` fails both reward and shield isolation. The fixture preserves independent consumed bits through a detached save/load, models Risk loading after Constitution's start callback, resets only shields on new floors, and tests live slot replacement, legacy migration, ghost/death and excluded damage. Ten injected faults independently fail. Normal/tainted Forgotten fixtures share their root holder's reward and shield. Tainted Lazarus fixtures alternate active entities, revisit both consumed bodies, continue, expose a Birthright twin and migrate a hidden body. The initial candidate failed the Flip-back regression before this correction. This is not native JSON, health or callback-order acceptance. API reference: [EntityPlayer.GetSubPlayer](https://wofsauge.github.io/IsaacDocs/rep/EntityPlayer.html#getsubplayer).

Jacob and Esau are additionally modeled as separate slots (player IDs 0 and 1 in the official API) with reciprocal `GetOtherTwin` links. The fixture confirms independent pickup and floor shield state; it does not settle native pickup-health behavior. See [Isaac.GetPlayer](https://wofsauge.github.io/IsaacDocs/rep/Isaac.html#getplayer) and [EntityPlayer.GetOtherTwin](https://wofsauge.github.io/IsaacDocs/rep/EntityPlayer.html#getothertwin).

In a muted disposable run, give The Constitution to two players: each eligible holder gets one soul heart once per run and independently blocks the first ordinary hit each floor with hurt invincibility. The second hit on each must damage normally; dropping/regaining the item must not farm hearts. Save with one shield spent and the other unused, fully close, continue, and check both separately. Next floor rearms both but grants no new hearts. Test ordinary co-op, join/replacement, death/revival, Jacob/Esau, both Lazarus forms (repeated Flip, with/without Birthright, after continue and legacy migration) and normal/tainted Forgotten/Soul identities. With an old shared-state save, existing consumed bits are inherited conservatively by players present during migration; a later new player starts independently. Verify IV Bag, blood donation, fake/no-penalty hits, shield ordering and native soul-heart restrictions/conversions.

## PAID-OBSERVERS-01: independent weapon consumers (offline passed; engine pending)

`tests/paid_observers_test.lua` registers real Opus Mode first, as main.lua does, followed by multiple real paid-attack observers (both repeated registrations on one module and fresh includes). Main `f7d7873` fails knives, melee hitboxes and target-linked Epic Fetus rockets: later observers receive nothing. With subscriber-local transient keys, each receives one event per attack; repeated callbacks do not duplicate it, a returned knife can pay again, and a second owner and familiar weapons remain isolated. Ten attacks cost one Opus coin only when held. This exercises the service and real Opus, not every character's resource implementation or native entity lifetime.

In the engine, test normal Claude usage, tainted Claude Quota, tainted GPT Full Send Credits and tainted DeepSeek Compute with Mom's Knife, Spirit Sword and Epic Fetus, first without Opus, then with Opus. Each attack must update the character meter and, separately, Opus's ten-attack coin counter. Repeat throws on the same knife, multi-shot builds, pause, room changes, co-op, familiar weapons and save/continue. Confirm actual damage and tainted DeepSeek's boost separately. Held-beam/Ludovico windows retain their existing dedicated regression and still need native acceptance.

## CHILD-LASER-01: child-beam initialization accounting (source correction; engine pending)

A private real-module fixture on `8c1ca789` initialized normal Claude, tainted Claude, tainted GPT and Opus. A primary laser produced Usage 4, Quota 219, Credits 79 and Opus count 1. On a later frame, a laser with the same player spawner and a laser Parent changed the character resources to 8/218/78 while Opus stayed at 1. The correction from `eb0ad1e` gives the three form initialization handlers Opus's existing direct parent-laser exclusion. It preserves their primary costs and the shared observer's later-window rules. The installed `28fed37` build predates this correction.

`tests/child_laser_billing_test.lua` drives real Opus, backlog and all three form modules. Seven groups separate delayed/same-frame child exclusion from primary payment, threshold transitions, Swarm prices, non-laser parents, familiar/enemy ownership and later held-primary windows. Six groups fail on immutable `eb0ad1e`; all seven pass with the correction. Five targeted mutants fail. Resource, wallet, cache/caption and native field assertions are offline simulations.

After verified deployment, test delayed child beams, reflected lasers and split rings with actual weapons. Record Parent/SpawnerEntity and initialization frames, and compare all three form resources and Opus against a true new primary beam. Include same-frame children, later-frame children, Swarm, near-limit resources, co-op, room changes and continued attacks. Verify primary held-beam windows and actual damage. A Parent assigned after initialization is outside this guard's evidence; record that timing instead of assuming every split or reflection is covered. This is not native acceptance or a change to tainted DeepSeek's separate boost policy.

Historical follow-up probe before BACKLOG-CHILD-LASER-01: a private real-module probe with the same supplied ancestry found Peak Compute 12 -> 10 for a primary, then 10 -> 8 for a later child. That child gets its own boost. At its first backlog update it consumes a held 2x prime, advances One More Finger 4 -> 0 and Sanity Test 0 -> 1; a modeled base-5 hit becomes 13 after the prime and Peak boost. A laser-spawned child has no player ownership in these handlers. BACKLOG-CHILD-LASER-01 above now addresses the backlog path; Peak is still unresolved. Preserve the ancestry distinction and do not interpret either correction as native acceptance of every child-beam consumer.

## VANILLA-COMPAT-01: vanilla item interactions (offline passed; engine pending)

Source fixes #63-#75 have offline regressions; the complete vanilla-compatibility matrix remains unaccepted in the engine. Check with a muted game when the owner is available:

- Soy Milk or Almond Milk plus Cat-girl Mode, Rolled Back or Agentic: tears per second must rise, never fall.
- Co-op: a dead player's ghost taps DROP; no form ability fires.
- The Constitution: walk into a contact enemy; the refused hit is followed by hurt invincibility, and Blood Donation or sacrifice spikes do not spend the block.
- Pizza Glue with Ipecac or Spoon Bender: sticky tears keep the item color under the glaze.
- --dangerously-skip-permissions in the Chest/Dark Room start room (Mega Satan door stays locked), Boss Rush and Hush doors, Mausoleum/Mines/Downpour exits, and an rm -rf roll beside the big chest or a trophy.
- All Tests Passing in an uncleared boss, Boss Rush and challenge room (refused, charge kept), in a normal room (doors open), and next to a secret room (wall stays closed).
- Two to four co-op players with mixed forms (Claude plus DeepSeek plus a roster form): HUD lines and story captions never overlap.
- Crash recovery: play to floor 2, force-close the game, continue; mod state matches the floor start. Confirm vanilla's own continue point after a crash.
- Vanilla Isaac with the mod enabled: no IP/Risk line other than "Direct connection", no enemy HP scaling, no Hydra or Relay Slimes.
- Opus Mode with Brimstone, Technology, Mom's Knife, Dr. Fetus, Epic Fetus and Ludovico: coins drain while firing.
- Compact with Car Battery as Claude: usage rises by 50 once.
- Co-op with one dead player (ghost): Llama's Release and Open Weights give the living player the solo four flies.
- Horse Brb, Getting Food: heals two red hearts, shooting locked 3 seconds.
- Ban Hammer with Car Battery: one set of misbans and Risk, bosses hit twice. Void absorbing Is This True? and Base Model/charged backlog items: using Void raises no Lua error.
- 1M Context with Ludovico: the orb keeps full damage after several seconds; ordinary tears still weaken in flight.

## COSTUME-LOCK-01: fixed character look (offline passed; engine pending)

Start with one original normal form, one original tainted form, one newer roster form and vanilla Isaac as a control; complete all 22 forms before full acceptance. Pick up Sad Onion, Brimstone, Mom's Contacts and The Virus, then complete Guppy. Use The Bible, Book of Belial, size pills, D4 and D100, then repeat representative combinations in reverse pickup order. On mod forms, expect a fixed skin with native weapon effects, flight, size and stats still functioning. Hidden costume artwork is intentional; missing gameplay effects are not. On Isaac, native costumes and effects remain the control. Record any one-frame pickup flash, hidden Holy Mantle/flight feedback, hurt-frame regression or detached weapon origin.

Enter a new room, save/exit, close the process and continue: the mod look and native effects should remain correct. Use Clicker and revival to leave a mod form: the current source re-adds held collectible costumes only; transformation, temporary and other non-collectible layers are not explicitly rebuilt. Inspect them separately instead of assuming full restoration. Test two players with mixed mod and vanilla forms, and repeat animation cases with and without Reactions Port Pack. Full scenarios and evidence requirements are in COSTUME_COMPATIBILITY.md. No engine pass is implied by this documentation correction.

## Authorized Risk and backlog integration (2026-10-24)

The owner explicitly authorized merging PR #55 and PR #56 while keeping work offline. This source integration includes both fixes and retains their separate evidence below. The earlier PR #50-54 integration remains a historical checkpoint. No game launch, runtime replacement or Workshop release is authorized by this merge; installed source remains the previously verified `2ec15ef`.

COMPOSE-02 applied the published PR #55 head `dc0fdbf7a932f5cc04bbeae7968512d02d1400af` and PR #56 head `9511dcf2723e1ca41da25ac20c55bedc42f006b2` to main `d91eee7`. All non-Markdown files were identical in either application order. The combined gate passed 50 stub suites, 148 tracked Lua files, five XML files and deterministic asset checks. Four Markdown insertion conflicts are reconciled here without dropping either candidate's evidence. Each original candidate separately passed 49 suites; those counts below retain their original scope. Verify the actual final integration commit and CI before reporting synchronization complete.

A separate retained-module interaction fixture checks Red Stamp and Risk together: the old-run block leaves Risk at 50, restart removes the old stamp, and the next ordinary contact adds Risk to 51. A new stamp use blocks again and preserves the clean-room reduction to 49. Reverting either fix independently fails. Both start flags are modeled with HasData=false; the initial missing HasData stub was a harness error corrected before recording results. This does not load serialized data or prove native health loss, callback order or save/continue.

Engine retests remain pending: native shield dispatch, risk threshold, clean-room awards, temporary effects across fresh starts/continue, co-op, later external damage blockers, native entity lifetime and save order. The transient Risk hit latch remains unsaved. Continue the complete menu/input, animation/costume, native-weapon, save/co-op and base Repentance matrix only when the owner is available. No new content is part of this integration.

## RISK-01: damage eligibility (offline passed; engine pending)

The real Risk, Constitution and backlog blockers are loaded in main's registration order by `tests/risk_damage_test.lua`. It models priority and the documented first-non-nil damage short circuit. Main `d91eee7` fails fake/no-penalty, shield cancellation and out-of-run cases; the candidate passes those cases, clean-room accounting, ordinary damage, Claude/vanilla coverage and excluded normal/tainted DeepSeek/roster co-op controls. Removing the flags, priority, active-run guard or start latch reset independently fails. The unchanged coverage suite also passes. The full gate has 49 suites and 147 tracked Lua files; local syntax traversal additionally includes two excluded probes.

When engine work resumes: with normal/tainted Claude and a vanilla character, inspect risk around fake/no-penalty events, Sold Out projectile guards, Red Stamp contact guards, Constitution's first refused hit and the next actual hit. Repeat at 89 risk to check suspension is not triggered by a refused event, then clear the room. Repeat with DeepSeek and roster co-op partners, after a fresh run and process-restart continue. Record native health loss separately from pre-damage callbacks. Check later-priority external blockers and callbacks returning true: this observer cannot guarantee final health loss or observe an event whose dispatch was stopped earlier. Mid-room hit-latch persistence remains an open save-matrix case; no save-schema change is included. Do not infer engine acceptance from these stubs.

## BACKLOG-LIFECYCLE-01: temporary effects across runs (offline passed; engine pending)

`tests/backlog_lifecycle_test.lua` keeps the real backlog modules loaded across exit/start instead of constructing fresh closures per case. Main `d91eee7` fails stale Kitten repulsion, decoy cleanup, peel slow, stamp contact immunity, Community Note exposure, pending heart guard and Consensus-history cases. The fixed candidate passes those, native-familiar preservation, persistent-table preservation and no-synthetic-room-reward controls. Six module reverts and removal of either lifecycle dispatch independently fail. Full gate: 49 suites and 147 tracked Lua files; local syntax traversal additionally includes two excluded probes.

When game testing resumes, activate each effect late in a disposable run, quit and start a new run without closing the application. Repeat save/continue and full process restart, including two owners. Observe the initial room callback order instead of assuming the fixture's order. Confirm temporary effects do not cross runs, preview decoys disappear while vanilla familiars remain, actual room-entry benefits occur once, and saved banks/progress are preserved. Native serialized entities and exact quit/save ordering are not modeled; Seahorse wisps and Thought knife flight remain separate pending cases. The original PR #56 branch excluded PR #55's Risk changes; this integration includes both.

## Current integration scope

Source integration checkpoint (2026-10-24): this tree combines PRs #50-54 under the owner's explicit merge instruction. The latest owner constraint remains offline-only. Installed game files remain at main `2ec15ef`; no combined engine acceptance or Workshop release is claimed. Earlier candidate, approval and deployment statements below are historical checkpoint records.

All pending cases below remain open. The combined offline gate covers registration, syntax, assets and stubbed regressions only. Re-run on the final source commit and record the CI link. Historical COMPOSE-01 document conflicts are reconciled in this integration; that earlier experiment remains separate evidence.

## COMPOSE-01: pending source composition (offline only)

The exact PR #50-54 input heads listed in the engine audit were applied in numerical order to an isolated main `2ec15ef` export. All source/test changes applied without conflict, including the overlapping normal-Claude implementation and usage regression from #52/#53. The combined gate passed **48 stub suites, 146 Lua files, five XML files and asset checks**. No private probes were in this test tree. Documentation conflicts were kept outside the tested tree for review; this is not a resolved release tree or a merge authorization. PR #54 alone still has 46 suites. Run the gate again after any authorized final integration, and complete candidate-specific engine retests before accepting runtime compatibility.

## VIBE-01: floor bill eligibility (offline candidate)

The owner currently requests offline work only; no game session or deployment took place. `tests/vibe_damage_test.lua` loads real Vibe Coding before the real backlog, matching main.lua, and models stable callback priorities and early termination on a non-nil damage result. Fake/no-penalty hits, Sold Out bullet cancellation and Red Stamp contact cancellation leave two players at 40 coins after the floor transition; old main incorrectly charges 10 coins. Ordinary damage still charges the hit player's 25% bill once, a clean following floor waives it, and buying Vibe after a real hit does not erase that hit. Exit disables tracking. The existing Vibe persistence fixture remains separate from native save-file validation.

The dispatch model follows [IsaacDocs' damage callback contract](https://wofsauge.github.io/IsaacDocs/rep/enums/ModCallbacks.html#mc_entity_take_dmg). It is not a post-health-loss event. A later external callback can still cancel damage, or an earlier callback returning true can suppress later observers; those environments are not accepted by this test.

Pending engine cases: Vibe with 40 coins and no real damage; fake damage; no-penalty damage; Sold Out blocking one hostile bullet; Red Stamp blocking contact; one ordinary hit; two players with only one hit; save/exit/continue before changing floors. Observe health, guard consumption, HUD and exact coins at the next floor. Repeat representative cases on base Repentance and with the installed mod set. Other risk, trinket and character damage observers are outside this fix's acceptance scope.

## DERIVED-01: helper resource billing (offline candidate)

The owner currently requests offline work only. The game remains closed and this candidate is not installed. `tests/derived_billing_test.lua` loads the real backlog, One More Finger, Please Retry, normal/tainted Claude and normal/tainted DeepSeek together. Synchronous FireTear dispatch is modeled; this is not an engine observation. On main, one helper per form changes usage/Quota/Thought/Compute from `0/220/150/12` to `4/219/0/10`. The candidate preserves those resources, keeps primes available and bills the next primary shot. Actual three-retry and fifth-shot helper schedules are covered. An active Limited penalty still weakens helper tears; a helper cannot start a new Limited interval.

Pending engine retest after availability and a fresh verified backup: use both items on each of these four forms, compare helper and primary-shot resource deltas, inspect the native helper damage and flags, repeat with Swarm and 1M Context, test empty Thought/Quota/Compute and active Limited, then room exit and save/continue. Confirm no helper-induced fork/resource chain or new Lua error. Other target-ability hit attribution, Llama's helper and other Lua-fired attacks are outside this regression's acceptance scope.

## Targeted ability familiar attribution (offline passed; two controlled engine cases passed)

On PR #50 candidate `aae85fd`, Repentance+ v1.9.7.17 passed a normal GPT blue-fly contact-kill negative control and an own native-tear kill positive control. The HUD showed an active Sanity Check before the familiar kill; real damage callbacks reported familiar source type 3 and tear source type 2. Fallback stayed at 2.800 after the familiar kill, then Verified returned at 4.025 after the native tear. The fixture used frozen spawned enemies, scripted placement/room clears and temporary synthetic DROP input. Physical keyboard/controller input, other familiar types and the wider matrix below remain pending. Details and unsuccessful fixture attempts are in [the engine audit](ENGINE_AUDIT_2026-10-24.md#controlled-gpt-engine-follow-up-pr-50).

In normal GPT Fallback, tag an enemy with Sanity Check. Let a contact familiar (for example a blue fly or an orbital) deliver every hit and the kill: GPT must stay in Fallback. Repeat with familiar projectiles and another player's attacks, then verify that GPT's own tears, bombs, lasers and knives can still advance or complete the check. Include parent-linked and spawner-linked native attacks.

For normal Gemini, Grok and Kimi, verify that their owner-only target damage bonuses do not multiply contact familiar damage. Test their documented player attacks as positive controls. Also check tainted Gemini/Grok attack counting. The shared helper now excludes the familiar entity itself, in addition to attacks spawned by familiars. `target_owner_test.lua` and the real GPT callback regression fail on the old helper and pass on the fix; they do not establish engine source attribution or kill timing.

Fresh menu starts remain pending: the latest 2ec15ef Repentance+ attempt reached File 1's main menu, but automated directional input did not select New Run. No case was passed from that attempt. The game was closed and its prior audio restored.

## Native Thought adapters (source candidate; no engine acceptance)

Follow [NATIVE_THOUGHT.md](NATIVE_THOUGHT.md) for the current adapter table and weapon-specific engine matrix. The owner resumed muted engine testing on 2026-10-24; see [the engine audit](ENGINE_AUDIT_2026-10-24.md) for actual coverage. Ordinary tears, single-hit/released-ring lasers, repeated-hit beams, flying knives and Dr. Fetus now have source paths; Ludovico and repeated-hit beams use six-update windows. The earlier Rice checklist below describes the initial tear-only candidate. Epic Fetus, melee, delayed bursts and Incubus/Twisted Pair now have source adapters; their combat behavior still needs engine acceptance.

Verify actual callback order, damage refresh behavior, charged releases during food lockout, continuous fork update order, 1M Context decay, pause and mid-window save/continue before accepting any native weapon case. Source field assertions do not establish damage dealt, player appearance, steering or engine serialization. This follow-up does not pass the costume matrix.

## Tainted Gemini One More Edit (source candidate; engine acceptance pending)

Select Tainted Gemini-chan: deeper-colour Gemini art, damage 0.9x of Isaac's. HUD reads `DROP: start an edit`. In combat, tap/release DROP near an enemy (within about 180 units): `One more edit`, HUD `Crop 0/3  6s`. Hit it with three separate volleys: Recolor, Export, then `Exported` and one extra hit of double your damage. Tapping again in that room does nothing. In a new room, tap, hit twice, tap again: progress resets. Kill the target early or wait six seconds: the chain ends without the pulse. Birthright: 10 seconds. Save/continue in an exported room keeps it exported. Test Brimstone and 20/20 (each volley or beam window counts once).

## Tainted Grok Quote Without Reading (source candidate; engine acceptance pending)

Select Tainted Grok-chan: deeper-colour Grok art, damage 0.9x. HUD reads `DROP: quote someone`. Tap/release DROP near enemies: `Quoted`, HUD `Ratio 0/3  6s`. Hit other enemies with three separate volleys: Ratio 3/3. Hits on the quoted enemy do not count. After six seconds it takes three extra hits of your damage and `Ratio'd` appears. The HUD then shows the cooldown until ten seconds after you quoted. Kill the quoted enemy early: nothing lands. With Birthright, half the Ratio moves to the nearest survivor once. Save/continue keeps the cooldown.

## Tainted Qwen Final Final Fine-Tune (source candidate; engine acceptance pending)

Select Tainted Qwen-chan: deeper-colour Qwen art. HUD reads `Balanced  Variants 0/3  Awards 0/3`. In a cleared room, tap/release DROP: Heavy (hits harder, fires slower), Tiny (weaker, faster), Balanced. In combat the tap does nothing. Clear new combat rooms with each of the three builds: `Final final version` and +0.2 damage. Repeating a build or re-clearing a room does not count. Three awards at most. A new floor resets everything. Birthright makes each award +0.3. Save/continue keeps build, checklist and awards.

## Tainted Llama Still Waiting (source candidate; engine acceptance pending)

Select Tainted Llama-chan: deeper-colour Llama art, slightly lower damage. HUD reads `Hype 0/3`. Clear new combat rooms: Hype rises to 3 and stops. Tap/release DROP: `Still waiting...`, Hype empties and the HUD shows `Helper 12s` at three Hype. From the spot where DROP was tapped, a weak tear flies at the nearest enemy each second; none with no enemy within range. Leaving the room removes the helper. Birthright makes each Hype five seconds. Check the tears with Brimstone, Technology, knife and Dr. Fetus. Save/continue keeps Hype.

## Tainted Mistral Le Gros Chaton (source candidate; engine acceptance pending)

Select Tainted Mistral-chan: deeper-colour Mistral art, slightly slower and weaker. HUD reads `Baguettes 0/2`. Stand still without firing for two seconds: `Baguette baked`; a third never bakes. Tap/release DROP while aiming: `Baguette!`, and enemies along a 120-unit line take one heavy hit each as the wave passes, over about a second. A rock or wall stops it. The HUD shows a two-second cooldown. Leaving the room mid-wave cancels it. Birthright bakes in 1.5 seconds. Save/continue keeps Baguettes.

## Tainted Doubao I'll Do It Again (source candidate; engine acceptance pending)

Select Tainted Doubao-chan: deeper-colour Doubao art. HUD reads `Ready to promise`. Tap/release DROP: `Leave it to me!`, damage rises and the HUD shows `Confident 6s`, which only counts down while enemies remain. After it, `Sorry, you're right`, lower damage for four seconds, then `I'll do it again`. Get hit by an enemy or bullet during Confident: the Apology starts at once and the hit still hurts. Blood donation or IV Bag do not count. Birthright makes the Apology three seconds. Save/continue mid-phase keeps the phase and damage.

## Tainted Kimi You Are the Manager (source candidate; engine acceptance pending)

Select Tainted Kimi-chan: deeper-colour Kimi art, lower damage. HUD reads `Tasks 0/3  Budget 9/9`. In a hostile room, tap/release DROP three times: `You are the manager` and three enemies each take three small hits two seconds apart. A fourth tap does nothing. After that the room's budget is empty. Killing an assigned enemy early frees its slot only. Leave mid-task: the task stops; return and the budget is still spent. Birthright makes pulses stronger. Save/continue keeps budgets but not tasks.

## Tainted GLM Please Retry (source candidate; engine acceptance pending)

Select Tainted GLM-chan: deeper-colour GLM art, slightly lower damage. HUD reads `Retries 0/3`. In a hostile room, tap/release DROP: `Request queued` and `Request Pending 2s`; two seconds later the nearest enemy takes a heavy hit (`Request complete`). DROP is blocked for three seconds from selection. Kill the target before the request lands: `Please retry` and one Retry. With three Retries, a successful request hits at 5x and resets them. Leaving mid-request cancels it with no Retry. With Birthright, a failed request also removes the nearest enemy bullet. Save/continue keeps Retries.

## Tainted GPT Reset Watcher (source candidate; engine acceptance pending)

Select Tainted GPT-chan from the tainted menu: deeper-colour GPT art, one red and two soul hearts, one key. HUD reads `Credits 80/80  Standard  Next Reset 0/3`. Tap/release DROP: `Full Send`, damage 1.5x, and each volley (one 20/20 volley, one Brimstone beam, one Dr. Fetus bomb) costs one Credit. At zero she returns to Standard and a tap cannot re-enter Full Send. Clear three different hostile rooms: `Tibo: Reset Ready`; further clears do not advance while it is banked. The next tap refills Credits and does not toggle the mode. Birthright raises cap and refill to 100. New floor and save/continue keep Credits, mode, progress and the banked reset. Check that no proxy IP / risk HUD appears for her, that a long DROP hold drops trinkets normally, and the MAP dossier. Stub coverage is `tests/gpt_reset_test.lua`.

## Tainted DeepSeek Peak / Valley (source candidate; engine acceptance pending)

Start a new run: HUD reads `Compute 12/24  Valley 12.0s  Forks On`. In a hostile room the timer counts down and switches to Peak after twelve seconds, then back. In a cleared room and on the pause menu it must stop. Each new floor starts in Valley with the same Compute. In Valley, stop firing during combat: Compute rises by three per second up to 24 (32 with Birthright). Waiting in a cleared room must not add Compute.

Fire ordinary tears: each paid volley adds two half-damage forks at ±12° and costs 2 in Valley or 4 in Peak. With 20/20, Mutant Spider or Monstro's Lung, check one payment per same-frame volley and judge whether forking every pellet is too strong. Below the cost, only the main tear fires and no tear ever disappears. Tap/release DROP toggles `Saving`; a second tap inside one second is ignored, and holding DROP keeps native trinket dropping. Test pocket cycling with a pocket item.

Save/quit/continue mid-phase and in Saving mode: Compute, phase, remaining time and mode must return unchanged; the toggle cooldown intentionally resets. Test a new run, character change (Clicker), co-op with two tainted DeepSeeks (separate Compute) and death. Brimstone, Technology, knife, Dr. Fetus and Ludovico builds should attack normally with no forks and no Compute cost. Stub coverage is `tests/deepseek_peak_test.lua` and `tests/swarm_resolution_test.lua`; no engine pass is recorded.

## Normal GPT Same Name, Smaller Brain (source candidate; engine acceptance pending)

Start a new run: HUD reads `GPT-chan: Verified  Routing 0/3` and damage is 1.15x. Clear three different hostile rooms: Routing reaches 3/3. Re-entering a cleared room or clearing a room that never had enemies adds nothing. The next room with enemies must announce `Fallback` and drop damage to 0.8x. Firing rate stays native (the old Deliberate / Instant modes are gone).

In Fallback, tap/release DROP near an enemy (within about 200 units) to tag it as a Sanity Check; the HUD shows `Check 0/3`. Tapping with no enemy nearby spends nothing. Hit it with three separate volleys: Verified returns and Routing resets. A 20/20 or Mutant Spider volley must count once, as must a Brimstone beam within one fifth of a second. Kill a tagged enemy with your own hit: Verified returns immediately. Let another player or a familiar kill it, or leave the room: the check fails and Fallback stays until the next room. Birthright needs two hits. Holding DROP keeps native trinket dropping; test pocket cycling with a pocket item.

Save/quit/continue in Fallback: Fallback, Routing and the spent room check return unchanged, and a second tag in the same room is refused. A new floor restores Verified with Routing 0. Test co-op with two GPTs (separate Routing and checks), character change (Clicker) and death. Stub coverage is `tests/gpt_downgrade_test.lua`; no engine pass is recorded.

## Normal Mistral Le Chat (source candidate; engine acceptance pending)

Speed is +0.1 over Isaac. Move while firing for two seconds: HUD goes from `Charge N%` to `Pounce Ready`. Stand still for a second and it is lost. Tap/release DROP while aiming at enemies within about 80 units: each one in that line takes double your damage once, `Pounce!` appears, and `Cooldown 3s` follows. Enemies behind you, off to the side, beyond reach or behind rocks and walls are not hit. You do not move or gain invincibility. Birthright reaches about 110 units. Save/continue keeps a ready Pounce. There is no swipe animation yet; note how readable it is. Stub coverage is `tests/mistral_pounce_test.lua`.

## Normal GLM Number in Queue (source candidate; engine acceptance pending)

New run: HUD reads `GLM-chan: Number in queue 0/3`, with no pocket item. Each combat clear adds one, up to three; re-clearing a room or peaceful rooms add none. At three the HUD says `Your turn! Tap DROP`. Tap/release DROP: `Access granted`, `Access 2 room(s)`. The next two hostile rooms you have not entered yet this floor each give +20% damage while you stay in them (`Access active`). Rooms already visited and peaceful rooms do not use the pass. The Queue does not move until the pass is used up and you have left its last room. Birthright gives three rooms. Save/continue inside a boosted room keeps the bonus without spending again. Test two GLMs in co-op. Stub coverage is `tests/glm_queue_test.lua`.

## Normal Kimi Another Slide Deck (source candidate; engine acceptance pending)

New run: HUD reads `Kimi-chan: Slides 0/6  Cost 3`. Each combat clear adds a Slide, up to six; re-clearing a room or peaceful rooms add none. With three Slides, tap/release DROP near enemies: `Another slide deck`, up to three nearest enemies within about 220 units get a light blue tint and slow down for four seconds, and HUD shows `Presenting 4s`. Your hits on them deal 15% more; a partner's hits do not. Tapping with no enemy nearby or fewer than three Slides spends nothing. A second deck replaces the first. Leaving the room ends it without refund. Birthright makes the cost two. Check the tint is readable and never covers the screen. Test two Kimis in co-op. Stub coverage is `tests/kimi_slides_test.lua`.

## Normal Doubao Sorry, You're Right (source candidate; engine acceptance pending)

New run: HUD reads `Doubao-chan: No apology needed`. Get hit by an enemy or its bullet in a hostile room: `Apology ready`, then `Apology Ready 6s` counting down. A second hit in the same room grants nothing, even after the token expires. Blood Donation, IV Bag, Curse Room doors, spikes and your own bombs must not grant one. Tap/release DROP within six seconds: `Sorry, you're right.`; enemies within about 100 units are tinted and slowed for two seconds, and up to four nearby enemy bullets vanish. The hit's damage stays. Leaving the room drops the token. With Birthright the token reads `Apology Ready` and lasts until room exit. Save/continue keeps the token and the spent-room flag. Test two Doubaos in co-op. Stub coverage is `tests/doubao_apology_test.lua`.

## Normal Llama Please Stay Open (source candidate; engine acceptance pending)

New run: HUD reads `Llama-chan: Releases 1/2  Next 0/2`, damage 0.95x. Solo, tap/release DROP: four blue flies, Releases 0/2. In co-op each living player gets two flies (at most four players). Clears no longer give flies automatically; every two unique combat clears add a Release (cap 2). Birthright gives Llama two extra flies per Release. Save/continue keeps Releases and progress. Stub coverage is `tests/llama_release_test.lua`.

## Normal Qwen Everyone's Base Model (source candidate; engine acceptance pending)

New run: HUD reads `Qwen-chan: Adapters 1/2  Next Range  Active none`. Tap/release DROP to cycle Next through Range, Tempo and Power; nothing is spent. Walk into a new room with enemies: one Adapter is spent and `Active` shows the pick (Range +60, Tempo faster fire, Power +10% damage) until you leave. Re-entering a room you already fought in never spends. With no Adapters stats are normal. Every two unique combat clears add one (cap 2, Birthright 3). Save/continue mid-room keeps the active pick and does not spend again. Stub coverage is `tests/qwen_adapter_test.lua`.

## Normal Grok Is This True? (source candidate; engine acceptance pending)

In a hostile room, tap/release DROP near an enemy (about 220 units): `Is this true?` appears and the HUD shows `Check 0/3  6s`. In a cleared room, or with no enemy nearby, nothing happens and the room's check is not spent. For six seconds your damage to that enemy is 1.3x and to every other enemy 0.9x; a partner's damage is unchanged. Three separate volleys (a 20/20 volley or a 0.2-second Brimstone window counts once) or killing it yourself shows `Verified` and +0.15 speed until you leave the room. Timeout or another killer gives nothing. A second tap in the same room does nothing, including after save/continue. With Birthright, verifying removes the three nearest enemy bullets. Check on-hit effects with the re-dealt damage. Stub coverage is `tests/grok_check_test.lua`.

## Normal Gemini Nano Banana (source candidate; engine acceptance pending)

New run: HUD reads `Gemini-chan: Paint 2/3`. Tap/release DROP near an enemy (about 180 units): Paint drops by one and the HUD shows `Edit 8s`. With no enemy nearby nothing is spent. Your tears, Brimstone, knives and bombs should deal 20% more to the painted enemy only; a co-op partner's damage is unchanged. Check that damage numbers, i-frames, knockback and on-hit effects behave normally with the re-dealt hit, including other damage mods. Kill the painted enemy yourself: a yellow slowing creep appears for four seconds and slows enemies; a second peel removes the first. Leaving the room ends the mark without refund. Each unique combat clear adds one Paint up to three. Birthright makes it 30%. Save/continue keeps Paint; the live mark is intentionally dropped. Stub coverage is `tests/gemini_paint_test.lua`.

## Rice First (source candidate; engine acceptance pending)

Muted engine testing is authorized. Keep this checklist pending until its individual cases are actually exercised; source and offline results are not engine acceptance.

As normal DeepSeek, verify one starting bowl, a two-bowl cap and one bowl per two newly cleared hostile rooms. Re-enter and repopulate a completed room: no extra reward. Test bosses, challenge waves, alternate floors, mirror rooms, two-player co-op and dead/revived players. Wait in an empty room: Thought can fill, but neither bowls nor pocket charge should increase.

Tap/release DROP: spend one bowl and lock directional shooting for two seconds, retaining movement and vulnerability. Verify no healing or pocket-charge change. Completion grants full Thought and +0.15 speed for six seconds. Birthright shortens the intrinsic meal to one second. Holding DROP must keep native dropping without spending rice; short pocket cycling may still happen and requires review. Test pause, disabled controls, transition and death during gestures and meals. A shared Lunch Break lockout blocks intrinsic meals; a food pill extends the shared countdown without a second reward.

Save/quit/restart during a meal, during the speed bonus, at half Thought and after the first of two clears. Verify each player's remaining resources/time and the single reward, including a new run, old save, character change and joining/leaving co-op. Verify speed cache recalculation after expiry and death. Inspect the Thought/Rice HUD alongside existing co-op HUDs and the MAP dossier.

With ordinary tears, charge Thought while moving, then fire four-eye/20/20/Monstro volleys: all same-frame pellets should share the multiplier. Swarm should copy half of the resolved parent damage without a second payment. Native tear size, flags, color and flight must remain intact; normal shots no longer randomly disappear. Test a shot-producing active and two players firing on the same frame.

Delayed burst, Brimstone, Technology, Mom's Knife, Dr. Fetus, Epic Fetus, Ludovico, persistent lasers and familiar ownership still need attack adapters; do not mark those cases passed from ordinary-tear tests. In particular, a persistent tear is not yet divided into six-frame windows. Full native-weapon compatibility remains a required next implementation step, not a claimed result. Tainted DeepSeek now uses Peak / Valley Compute; see its own section below.

Offline coverage is in `tests/deepseek_rice_test.lua`, `tests/content_test.lua` and `tests/swarm_resolution_test.lua`. The real modules are invoked with stubbed engine entities and detached Risk snapshots. This does not establish actual engine JSON, callback timing, analog controls, item visuals or save-slot identity.

## Shared food countdown (engine acceptance pending)

Use Lunch Break as normal DeepSeek and as a vanilla character, then use Brb, Getting Food. Verify the three-second directional shooting lock while movement, vulnerability, bombs, active/pocket use and DROP remain available. Use Car Battery: one heal, one slowdown, one meal only. A second Lunch Break use during a meal must preserve charge and grant no extra heal; a food pill can refresh the meal. Verify a longer existing shooting cooldown is not shortened.

Save/quit/restart at one second and just before expiry. Each player must retain only their own remaining time; pause and menu time must not advance it. Cross rooms/floors, die/revive, change character, leave/join co-op and test two players sharing a controller. No permanent lock, wrong-owner lock or forgotten timer is acceptable. Test keyboard and analog aiming separately, including pause-menu confirmation.

Repeat while charging Brimstone, Technology X, Monstro's Lung and Chocolate Milk, and with Mom's Knife, Dr. Fetus, Epic Fetus, continuous lasers, Ludovico, Marked, familiars and a shot-producing active. Record whether a charged release leaks through, whether existing controlled attacks remain steerable and whether another input mod bypasses or overrides the hook. Existing attacks are not deleted and programmatic FireTear calls are not intercepted. These cases are deliberately not passed by the input stub. Evaluate the intended distinction between blocking new normal shots and preserving already-emitted/active-item attacks before accepting the Rice ability that now uses this service.

Offline `tests/meal_break_test.lua` uses the real item/pill/input modules plus detached save snapshots. It covers typed hook returns, non-shooting pass-through, Car Battery, overlap, exact countdown expiry, duplicate updates, pause, continue, migration and player identity. The old item module from `413d02d` fails its first Car Battery assertion. Actual engine JSON, charged-release timing and co-op slot identity remain unverified.

## DROP tap/hold compatibility (engine acceptance pending)

For GPT and Gemini separately, test keyboard and controller: a short press must leave mode unchanged while down and switch once on release; a long hold must drop the intended vanilla trinket/pocket pickup without switching. Repeat when holding multiple pocket items, including native short-tap cycling. The observer does not suppress that cycling, so record any undesirable double action rather than marking it passed from Lua coverage.

Test releases after pause, hidden-HUD pause, a big-book animation, disabled controls, room/floor transition, death/revive, save/quit/continue, controller reassignment and character change. No interrupted gesture may switch mode. Once controls return, release and make a fresh tap to verify recovery. Repeat with two players on separate controllers, then supported shared-controller/twin arrangements and other input mods. Verify the chosen mode persists across continue but an unfinished press does not. The 1–12-frame threshold is a source rule, not a measured vanilla drop threshold; assess actual feel and latency before acceptance.

The helper and real roster callback tests cover release timing, long holds, interruption cancellation, fresh wrappers and player/controller isolation. The updated roster regression fails against the previous model_roster.lua at 5f97401 before its release assertion, then passes with this correction. No native input hooks or inventory-drop calls are installed. These facts do not prove native dropping or controller behavior in the engine.

## Hurt-pose correction (source fixed, engine acceptance pending)

The owner reports all characters developing an oversized head after damage. Exact runtime revision and item setup were not captured. Source now corrects the measured shared-cell envelope/anchor in all thirteen skins and restores Llama's full source pose. ANIM-01 on main `2ec15ef`, Repentance+ v1.9.7.17, observed actual health loss and engine-selected Hit frame 6 for all 22 forms plus Isaac. Sixteen mod forms plus Isaac have inspected screenshots without an obvious oversized full-body replacement at that frame. Reactions was enabled; zero collectibles were recorded at arming. Tainted GPT, normal Gemini, both Groks and tainted Qwen lack inspected screenshots; tainted GLM needs a clean repeat because movement/pickup input overlapped its capture. See the [per-form table and fixture limits](ENGINE_AUDIT_2026-10-24.md#anim-01-actual-damage-bounded-hit-frame-observation). Logs alone do not pass visuals, type changes do not pass fresh starts, and holding playback does not pass recovery. The reported bug remains open.

Compare every form with vanilla Isaac at the same scale, then repeat real damage with face costumes, flight, size items and transformations. Capture pre-hit, all Hit frames and recovery. Check pivot stability, full-body pose, costume retention and no stale color/scale. Also test Death, FallIn, JumpOut and DeathTeleport, which reuse this cell. Repeat without and with Reactions Port Pack. Historical v0.4 evidence does not pass this case.

Offline reproduction requires Pillow plus the recorded generated sources, kept outside the repository. Run `python tools/verify_hurt_poses.py SOURCE_DIRECTORY MOVEMENT_SOURCE_DIRECTORY REVIEW_OUTPUT_DIRECTORY --before-ref d1c0daf`. This fails the geometry contract on the old thirteen skins and passes the corrected ones, verifying source/packed hashes, exact atlas rebuilding and pixel equality outside the shared hurt cell. It writes an engineering comparison and JSON evidence; it neither installs files nor runs the game. CI's standard asset checks do not execute this optional source-dependent review.

## Fifty-row backlog acceptance (pending)

Rows 02-50 (`scripts/items/backlog/`). Offline suites: `tests/backlog_items_test.lua`, `tests/backlog_more_test.lua`. In game, per item: spawn it, read the EID, check the icon, use or trigger it once and confirm no console error.

- Every active: Car Battery adds nothing; targeted actives keep their charge in an empty room; Void/wisp uses are harmless.
- Primes (Rice Cooker, Wengu Clock, Base Model, Quote Retort, Next Time Again, Rate-Limit Valve): one boosted attack each with tears, Brimstone, Technology, knives, Dr. Fetus and Ludovico; multi-shot volleys boost every tear once.
- Guards (One Bowl Only, Sold Out, Release Soon, Token Recall): an ordinary enemy shot is absorbed; champion/special shots, contact, Blood Donation and IV Bag are not.
- Unique clears (Routing Receipt, Final Final Weights, Herd Bell, Please Come Back, Smiling Correction, Overtime Slides, Queue Ticket): re-entering, continuing and boss rooms count once; Glowing Hourglass behavior is recorded.
- Saved state: save/exit/continue keeps Anniversary Cake, Tibo Reset, Error Budget and counters; a new run resets them; co-op players stay separate.
- Helpers: Unchanged Preview decoys draw nearby enemies and Stand-Up Meeting recalls them; Open Weights flies are native blue flies.
- Stats: Tiny Variant, Another Adapter, Slipstream Boots, Edge Compass, Live Wire and Cache Cartridge do not change sprite size or fight other stat items.

## Meme extras batch 1 acceptance (pending)

- Ignore All Previous Instructions: charmed target fights for you for 8 s and is not re-targeted by Car Battery; bosses only confused; empty room keeps charge; check with Compact and You're Absolutely Right!.
- Tungsten Cube: damage/speed in the stat HUD, knockback with tears, Brimstone, Technology, Mom's Knife and Dr. Fetus; stacking with D4/D100 rerolls.
- Pizza Glue: slowing tint and effect on tears; shot speed change; no effect on lasers/knives/bombs; Swarm and Peak/Valley fork copies; continue keeps the native item RNG sequence.

## Meme extras batches 4-5 acceptance (pending)

- Seahorse Emoji: wisp appears, fights and is removed on room exit; save/exit mid-room (untracked wisp risk); Book of Virtues and other wisp items unaffected.
- Temperature Dial: toggle text and damage; each listed flag visibly applies; interaction with other tear-flag items; continue keeps the temperature.
- Deep Research: full reveal including secret and super secret rooms; Curse of the Lost/Unknown display.
- As an AI Language Model: removal of each curse type mid-floor (Darkness, Lost, Unknown, Maze, Blind, Giant), Labyrinth kept, continue does not refuse twice.
- System Prompt Leak: compass reveal on each floor and on mid-floor pickup.
- Disgrace Loop: freeze on bosses and freeze-immune enemies; Holy Mantle hits; co-op once per player.
- Rolled Back: stat HUD, horse pill detection, room change rollback, continue mid-room drops the bonus.

## Meme extras batch 3 acceptance (pending)

- Strawberry: count with 20/20, Inner Eye, Mutant Spider, Monstro's Lung and Summary Stapler tears; interaction with Hardcoded Output, DeepSeek Thought/forks and Swarm copies; red tint over item colors.
- Golden Gate Claude: spectral tears over rocks and through poop/fires as vanilla Ouija Board; range stat display; tint with Ipecac/Spoon Bender; caption frequency.

## Meme extras batch 2 acceptance (pending)

- Claudius's Discount: shop items, hearts, keys and restocks priced 2+ refund once; 1-coin items do not; devil deals, free items and Keeper are unaffected; Steam Sale and coin-cost items from other mods; new floor charge once, and not again on continue.
- One Small Rock a Day: rocks broken by bombs, tears (Terra/Ipecac), enemies and stomps; tinted/special/spiked rocks; full health and soul-only characters; continue on the same floor does not restore the rock.
- Stuck in Mt. Moon: callback order on continue, curse rooms, red rooms, and the vanilla map display after the effect.
- 9.11 > 9.9: whether the game passes pill color (horse pill), PHD/False PHD, pill identification text, continue and co-op.

## Summary Stapler acceptance (pending)

Give Summary Stapler in a disposable run. Verify four room charges, empty use preserving charge, nearest-first absorption capped at twelve within 120 units, and exclusion of special-flag/variant, friendly, player/familiar, dead or source-less projectiles. Aim diagonally and use without shooting; check the speed-6 native tear and base damage multiplier 1 + count/4. Car Battery must neither absorb a second batch nor fire again. Verify co-op ownership and both active slots.

Test homing, piercing, spectral, explosive, split/orbit/controlled tear items and Tractor Beam. Brimstone, knives, lasers and bombs must remain the primary weapon; the active emits a separate tear and must not replace their appearance. Check native callback timing with Swarm, Claude's usage/limited damage, tainted quota, Deep Think, and DeepSeek cancellation/forks. Successful absorption consumes charge even if character logic cancels the retaliation. Test save/restart with the item charged and discharged, room transition, reroll/removal and the costume matrix. Special modded projectiles that look ordinary may need explicit compatibility rules; generic filtering does not prove every other mod is safe.

## Vanilla item appearance acceptance (pending)

Run the per-form matrix in [COSTUME_COMPATIBILITY.md](COSTUME_COMPATIBILITY.md): isolated items, mixed pickup orders, flight, scale, transformations, removal, reroll, restart and co-op/type changes. The nine added normal skins have an offline head/carry alignment correction; this is not engine acceptance. Existing four-character art and the planned nine tainted forms require the same matrix. Record screenshots and exact versions; Lua tests and texture dimensions cannot establish visual compatibility.

## Normal Claude Appeals (source candidate; engine acceptance pending)

HUD shows `Usage N%  Appeals 1/2` on a new run. Fire single tears and a 20/20 or Mutant Spider volley: each volley adds 4 usage (8 with Subagent Swarm), not 4 per pellet. Stop firing: usage drains 10 per second; holding fire stops the drain. The volley that reaches 100 keeps full damage, then Limited weakens tears for five seconds.

Tap/release DROP at about 60 usage: one Appeal is spent, usage drops by 40, caption `Appeal filed / Another love letter.`. A tap at zero usage, at zero Appeals or during Limited must spend nothing. Holding DROP must keep native trinket dropping; check pocket cycling with a second pocket item. Clear two new hostile rooms: +1 Appeal (cap 2); re-entering a cleared room or clearing an empty room gives nothing.

Get Birthright and reach 90+ risk: `Banned again / Birthright kept your account age`, age unchanged and the Suspended penalty still applies. A second suspension on the same floor resets age; the next floor renews the shield. Save/continue while suspended must not reset age. Save/continue mid-progress keeps Appeals and the clear count. Co-op with two Claude-chans keeps separate usage and Appeals. With Brimstone or Technology, each laser start bills 4 usage (once per frame with tears); a held Tech 2 beam pays once; Dr. Fetus bombs bill; knives and placed bombs do not. Tainted Claude pays Quota the same way. Stub coverage: `tests/claude_appeals_test.lua`, `tests/claude_usage_save_test.lua`, `tests/swarm_resolution_test.lua`.

## Normal Claude usage save acceptance (pending)

TIMER-01 source candidate adds per-player/frame deduplication and explicit pause/death freezes for Limited and idle drain. The expanded `claude_usage_save_test.lua` fails against main `2ec15ef` when a duplicate wrapper callback reduces the timer twice. It also checks two-player isolation, exact expiry over active frames, paused/dead callbacks, revival without catch-up, drain deduplication and fresh/continued runs at the same frame. The older 149-step countdown fixture now advances 149 actual frame values rather than invoking one frame repeatedly. These are offline assertions, not evidence that the engine normally invokes duplicate callbacks.

Engine retest pending: reach Limited naturally, verify the five-second countdown over active gameplay updates, pause/resume, die/revive, and save/continue mid-countdown. Confirm idle drain stays ten per second, held fire blocks drain, two Claudes remain independent, and pause/death interrupts DROP without consuming an Appeal after recovery. If using an explicit duplicate-callback fixture, distinguish it from normal engine delivery. Do not close timer acceptance from this regression alone.

As normal Claude, save with a partially filled meter, close the process, restart and continue. The meter must resume rather than clear. Repeat during the five-second limited-damage interval and confirm the remaining game-frame countdown and 40% damage. Repeat with two Claude players at different usage levels, with Swarm (including the first continued shot), after Compact, and immediately after Banked Reset. Continue must preserve the item changes and keep players independent. Verify a fresh run resets both meters and an older save without usage fields loads safely. Check Clicker away/back, co-op join/leave, and supported twin/subplayer forms separately; the slot-keyed stub does not prove their engine identity behavior. The penalty expires through gameplay frames; offline wall-clock time is not credited.

## Original character movement revision (engine acceptance pending)

Inspect normal and tainted Claude/DeepSeek at actual gameplay scale. Check idle and firing faces in all directions, mirrored left profiles, rear silhouettes, body/head attachment during walking, and carrying an item while walking. Confirm the carry-head frame does not produce a second body. Test body visibility against dark rooms and with costumes. Compare save/continue appearance, then inspect retained flying, hurt, death and special poses for style and alignment differences. The offline preview and atlas checks do not complete these tests.

## Fork property inheritance acceptance (pending)

Test tainted DeepSeek alone, Isaac holding Subagent Swarm, tainted DeepSeek with Swarm, and normal DeepSeek's fully charged Deep Think with Swarm. Compare the natural tear and its children using Spoon Bender, Cupid's Arrow, Ouija Board, My Reflection, Ipecac and Cricket's Body. Check actual tracking, piercing, wall passage, trajectory/range, explosions and bounded splitting; copied flags alone do not prove those effects work in the engine. Deep Think children should display the boosted size and retain half the resolved parent damage. No DeepSeek shot is randomly removed any longer.

Also test Tiny Planet, Anti-Gravity, Eye of the Occult and Ludovico separately: these flags can depend on engine-managed motion or controller state that is not recreated by copying fields. Record unsupported behavior explicitly rather than claiming universal tear compatibility. Recheck both Claude limits, two-player ownership, split-shot growth, other mods' tear-init callbacks and frame time under high fire rate. The new regression verifies property transfer and existing spawn counts only; it provides no FPS or engine-pass evidence.

## Eleven-family expansion acceptance (all pending)

Offline coverage is described in `MODEL_ROSTER.md`; it does not tick these boxes.

- Select all eleven normal families and both existing tainted characters. Check the correct name, bust, stage portrait and full MAP dossier. No missing textures or duplicate menu entries.
- Roster-only and DeepSeek-plus-roster runs show no IP/risk HUD. With Claude in co-op, a roster player's hit adds no risk and suspension lowers only Claude's damage. Blood Donation, IV Bag and a sacrifice room never grant Doubao an Apology. Roster tears keep Ipecac/Spoon Bender colors under the family tint.
- Inspect every new skin facing front, right, rear and left, while walking, firing, holding an item, flying, hurt and dead. Check for clipping, stray neighboring pixels, incorrect back views and doubled heads. Alternate arm poses remain provisional.
- For GPT and Gemini, tap DROP through both modes, then save/quit/close/restart/continue. The mode must persist. Check the original DROP behavior with held trinkets and controller input.
- For Grok and Mistral, reach maximum movement/firing charge, stop, change rooms, and start a new run. Temporary charge must reset and stay bounded.
- For Kimi, save and continue right after a clear, then revisit the room. The Slide must not be awarded twice.
- For Llama, reach the reward threshold, save/continue, and revisit the same room. Rewards must not duplicate. Include dead players, two holders and a non-holder in co-op.
- For GLM, redeem an Access Pass, save/continue inside a boosted room and on a new floor. The pass must not spend twice or stack.
- For callback identity, compare Grok's HUD momentum with its damage increase through repeated cache refreshes; confirm Mistral gains spectral tears at full wind and loses them when stopping. Repeat with two players and character-changing effects. Distinct-wrapper stub coverage passes; these engine checks remain pending.
- Check Brimstone, Technology, Mom's Knife, Dr. Fetus, Epic Fetus, multishot, familiars, D4, transformations, costume-changing items, EID and Reactions Port Pack. Cache-based code alone is not compatibility evidence.
- Repeat in base Repentance and Repentance+, finish full runs, then close the game. Do not publish to Workshop before acceptance and art-permission review.

Offline tests, historical v0.4 engine observations, and v0.5 runtime validation are separate evidence. See HANDOFF.md for their scope. The checks below are acceptance targets, not claims that they passed.

## Setup

1. Put the folder in `…/The Binding of Isaac Rebirth/mods/claude-chan-isaac/`.
2. `options.ini` → `EnableDebugConsole=1`.
3. Start the game, open the mods menu and check **Claude-chan: Risk Control** is enabled.
4. In a run, press `~`. **Any red text in the console is an error. Copy it exactly and send it to Claude.**

Useful console commands: `giveitem <name>` for items, `giveitem t<name>` for trinkets (e.g. `giveitem t529 Overloaded`), `stage 2` to change floor, `debug 3` for god mode, `luamod claude-chan-isaac` to reload after a fix.

## Checklist

| # | Test | Expected | OK? |
|---|---|---|---|
| 1 | Character select | Claude-chan is listed with the custom character artwork | |
| 2 | Start as Claude-chan | Ban Hammer in the pocket slot; orange tears; IP + Risk + Usage on the bottom-left | |
| 3 | Shoot non-stop for ~20 s | "Usage limit reached", grey weak tears for 5 s, then meter resets | |
| 4 | `stage 2`, `stage 3` | New IP each floor, risk goes up | |
| 5 | Get hit / clear a room without a hit | Risk +1 / −1 | |
| 6 | Risk ≥ 40, kill enemies | Some come back red, only once each | |
| 6b | Risk ≥ 30 (`stage 4`+), enter new rooms | Sometimes a big green Clotty; killing it gives 2 smaller, then 2 smaller each again (7 total) | |
| 7 | Use Ban Hammer in a room with many enemies | Non-boss enemies die, "BANNED", none come back; sometimes "misban(s) - appeal pending" and risk goes up | |
| 8 | `giveitem Residential IP` | Risk −30 once | |
| 9 | `giveitem Compact`, use it | Enemy shots vanish, enemies confused; Claude-chan usage +50 | |
| 10 | `giveitem You're Absolutely Right!`, get hit | That enemy becomes friendly for 5 s | |
| 11 | `giveitem 9.9 Yuan Relay`, change rooms | Sometimes "Model quietly downgraded"; risk +15 once | |
| 12 | `giveitem Ultrathink`, use 3× in one room | think / megathink / ultrathink, damage goes up; resets next room | |
| 13 | `giveitem 1M Context` | Long range; far tears do less damage | |
| 14 | `giveitem t529 Overloaded`, fight | Every 20 s enemies freeze for 2 s; you can still shoot, but those tears are weaker ("coding manually") | |
| 15 | `giveitem Silent Update`, change floors | "Changelog: no changes", damage changes | |
| 16 | `giveitem --dangerously-skip-permissions` | Locked doors/chests open; sometimes "rm -rf" deletes pickups | |
| 17 | `giveitem All Tests Passing`, use with enemies alive | Doors open, enemies stay. **Do the doors stay open?** | |
| 18 | `giveitem tHardcoded Output` | Tears always deal 3.5 | |
| 18b | `giveitem tThinking Cleared`, change rooms | Damage +1; active item loses a charge per room | |
| 18c | `giveitem Vibe Coding`, shoot, `stage 2` with coins | Tears get mixed effects, a few fly backwards. Got hit on the floor: coins −25% on the new floor. No hit: "Made no mistakes", no bill | |
| 18d | As Claude-chan, hit the usage limit, then `giveitem Banked Reset` and use it | Usage meter back to 0, risk −25 | |
| 18e | `giveitem Subagent Swarm`, shoot | 3 tears per shot in a fan; Claude-chan's meter fills about twice as fast | |
| 18f | Console `giveitem p<n>` is awkward for modded pills; instead find pills in a run, or check they appear in the pill pool | "Cat-girl Mode" doubles fire rate at lower damage for the room; "Brb, Getting Food" heals and pauses shooting | |
| 18g | `giveitem tWelcome Notice`, use Ban Hammer | "WELCOME!", regular enemies become allies and stay allies | |
| 18h | `giveitem tStatus Page` | HUD says "Risk: all systems operational"; risk still rises, a bit slower | |
| 18i | `giveitem The Constitution`, take 2 hits on one floor | +1 soul heart; first hit shows "I can't help with that" and does no damage or risk; second hit lands | |
| 18j | `giveitem Ultrathink`, `giveitem Compact`, `giveitem Vibe Coding` | "Agentic!" with a sound; you can fly over rocks and pits; tears faster | |
| 18k | Push risk to 90+ (many floors / misbans) | "Account suspended", damage drops; when risk falls below 90 damage returns | |
| 18l | Same, holding `giveitem tAppeal Form` | "Appeal approved", trinket gone, risk 50, no damage drop | |
| 18m | `giveitem Opus Mode` with a few coins, shoot | Big damage; coins tick down every 10 tears; at 0 coins "Out of credits" and weak damage; pick up a coin and damage comes back | |
| 19 | Save & quit, continue | Risk, IP and Silent Update value are kept | |
| 19b | Set the game language to 简体中文 (or 日本語), start a run | HUD shows 风控值 / リスク値 in that language. If it's still English, the CJK font path is wrong: tell Claude | |
| 20 | With EID installed | Item descriptions show (try Chinese/Japanese in EID settings) | |

Items most likely to need fixes: **#17** (doors may re-close while enemies are alive) and the placeholder Relay Slime (#6b).

Overloaded lifecycle acceptance (pending): trigger an outage late in a disposable run, quit during its two-second window, then start a new run without closing the application and acquire the trinket. Tears must have normal damage until that new run's first outage. Also test save/continue, dropping the trinket during an outage, and normal recovery at two seconds. Offline lifecycle coverage does not mark these engine checks as passed.

Subagent Swarm resolution acceptance (pending): test both DeepSeek characters with Swarm in a populated room. Neither DeepSeek form may randomly remove a shot; a normal shot after five seconds of Deep Think must give children half its boosted damage. On both Claude characters, children must deal half the already-limited parent's damage and share its grey color. Check normal DeepSeek plus Swarm produces three total tears, while tainted DeepSeek plus Swarm produces five when Compute pays for the forks (three in Saving mode or when Compute is short), with no recursive growth. In co-op, a non-holder must not gain children from the holder. Also test another mod's late tear callback; this mod's late registration does not establish universal ordering across third-party callbacks. These assertions have stub coverage only, not a recorded engine pass.

### Opus Mode immediate wallet state

Acquire Opus Mode at zero coins and inspect the damage stat before and after the next player update; its multiplier should be x0.6 throughout. Repeat with positive coins for x1.8. Pick up a coin, spend the last coin, and trigger a damage-cache refresh in the same frame: the refreshed value must use the current wallet. Reroll away and reacquire the item after changing the wallet, and repeat after a real save/quit/continue. In co-op, check each owner separately. The regression uses stub cache calls and stale notification flags; it does not prove the game's callback order or cover weapon-family billing.

### API checked against the community docs (wofsauge/IsaacDocs, 2026-10-22)

These calls exist with the signatures the mod uses, so they shouldn't crash: `GridEntityDoor:TryUnlock(player, force)`, `IsLocked()`, `Open()`; `EntityPickup:TryOpenChest(player)`; `Entity:AddCharmed(ref, -1)` (−1 = permanent, the ally follows you between rooms); `AddConfusion`, `AddFreeze`; `Room:SetClear`, `GetFrameCount`, `GetCenterPos`; `EntityPlayer:SetPocketActiveItem`, `GetActiveCharge`, `SetActiveCharge`, `AddSoulHearts`, `HasTrinket`; `EntityTear:AddTearFlags`; `MC_USE_PILL (effect, player, flags)`; `MC_USE_ITEM` returning `true` plays the use animation; `MC_ENTITY_TAKE_DMG` returning a value skips later callbacks (so The Constitution's refused hit adds no risk).

What the docs can't tell us is whether the gameplay *feels* right. That's what this checklist is for.

## v0.4 focused checks

### Vibe Coding persistence acceptance (pending)

In a disposable run, hold Vibe Coding and 40 coins, take a hit, save and quit, close the application, then continue and change floors. Coins must remain 40 on continue and become 30 on the next floor. Repeat without a hit: coins stay 40. On the following no-hit floor no second bill is due. Repeat with two players: only the damaged holder pays. Include The Constitution's refused first hit, and check a fresh run does not inherit the previous run's hit flag. The lifecycle regression is stub coverage; it does not mark these engine checks as passed.

### Other v0.4 checks

- *(v0.4 DeepSeek-chan check superseded by the v0.5 redesign below.)*
- `giveitem Support Ticket`: with 2 coins or risk 0, no coins/charge spent; with 3 coins and positive risk, spend 3 and lower risk by up to 20. Repeat with Car Battery.
- See story chapters at run start, stage 3, stage 5, and the next room after successful review. Save and continue: completed chapters stay completed. Hide the HUD: captions hide too.
- Roster arcs: start a run as any non-Claude family (normal or tainted) and see its chapter 1, then chapter 2 at stage 3 and chapter 3 at stage 5. With Claude in co-op, both captions show without overlapping. Save and continue mid-caption: it does not repeat, and a queued one still plays. Offline suite: `tests/story_roster_test.lua`.
- Inspect both custom character skins, four head directions, all movement/hurt/death poses, character select, stage/boss portraits and names. Check D4 and costume interactions. **Initial custom-art runtime checks passed in Repentance+; the complete animation/costume matrix is pending. See HANDOFF.md for exact observations.**
- Subtitle position was moved above the lower HUD after observing EID overlap; confirm it with EID enabled.
- Use Support Ticket on the first floor, then reach stage 3 and stage 5: both later chapters must still appear with their approved-route dialogue. Continue after all four chapters: none should repeat.
- Repentance+ 1.9.7.17 gameplay startup was observed on 2026-10-23. This is not evidence of a full-run pass, normal Repentance compatibility or local co-op correctness.

## v0.5 focused checks (characters)

With Reactions Port Pack enabled, trigger a pickup/reaction for each of the four characters. Their custom skins must remain visible instead of receiving the pack's default Isaac face. Explicit character support supplied by the pack must remain intact. The tainted fallback regression currently has stub coverage; in-game visual verification remains pending.

| # | Test | Expected | OK? |
|---|---|---|---|
| C1 | Character select: press E (keyboard) / RB (controller) to switch to the tainted menu | Tainted Claude-chan (crimson) and Tainted DeepSeek-chan (teal) are listed with their menu portraits. Per the Isaac Blueprints tainted-unlock tutorial, without REPENTOGON a modded tainted character **can't be locked in the menu**, so they should be selectable from the start; the tainted toggle itself may need a save that has unlocked vanilla tainted characters. **If they don't appear, tell Claude** | |
| C2 | Walk and shoot in all four directions as each of the 4 characters | Heads are never clipped at the edges, no stray hair bits next to heads; DeepSeek-chan faces sideways when walking sideways (no more front-facing slide) | |
| C3 | Start as DeepSeek-chan | HUD says "Direct connection - no proxy needed" (直连・无需代理), no IP/risk line; enemies are not tougher on later floors; pocket item is Lunch Break | |
| C4 | DeepSeek-chan: stop shooting for 3-5 s, then shoot | Big tear, HUD "Thought for N s" (已深度思考（用时N秒）) | |
| C5 | DeepSeek-chan in a room with many enemies | Some shots don't come out, HUD "Server busy, please try again later" | |
| C6 | Use Lunch Break | +1 red heart, enemies slowed, you can't shoot for 3 s | |
| C6b | DeepSeek-chan: clear a room, then stand still ~5 s | HUD "Slacking off... Lunch Break +1" (摸鱼中……), pocket charge +1; nothing happens while moving or in a fight | |
| C7 | Tainted DeepSeek-chan: shoot | With enough Compute each volley comes out as 3 tears in a fan and the HUD Compute drops by 2 (Valley) or 4 (Peak); at low Compute or in Saving mode only the main tear fires; still no risk HUD | |
| C8 | Co-op: Claude-chan + DeepSeek-chan | Risk HUD and IP are back (the system only sleeps when everyone is DeepSeek-chan) | |
| C9 | Claude-chan: `stage 2`, `stage 3` without reaching risk 90 | HUD "Account age: 2 floor(s)", damage up a little; reach 90+ risk: "Banned again", age back to 0 | |
| C10 | Tainted Claude-chan: shoot ~220 volleys on one floor | HUD `Quota N/220  Pages 2/2` drops by one per volley (two with Subagent Swarm); at zero `Suspended`, half damage, grey-tinted tears; DROP tap starts `Under Review: 6s` (frozen in cleared rooms/pause, cancelled by leaving) then +60 Quota; next floor refills; Banked Reset refills and cancels a review | |

### Repeatable manual engine probe

Use only a disposable, owned stage-1 **Claude-chan** run (since v0.5-dev; the probe puts a Support Ticket into her pocket slot, replacing the Ban Hammer for that run). The passes below were recorded on the v0.4 build in a DeepSeek-chan run, before the redesign. In the game debug console run:

```lua
lua Isaac.RunCallback("ClaudeChan:RunRuntimeProbe")
```

Close the console and let the simulation run for about 13 seconds. This sets test coins/risk, uses the real pocket-item input, adds Car Battery, changes to stage 3 and round-trips this mod's run data. It does not change other mods' settings. Do not invoke it in a run you intend to preserve. Normal gameplay never calls it. A duplicate probe is rejected; input is removed on completion, failure or game exit.

The probe must print `CCQA PASS` for insufficient funds (2/50/6), Car Battery (3/30/0), simultaneous captions (one pending), queue save/load (seen=11, pending=0), and completion. These assertions passed in Repentance+ 1.9.7.17 on 2026-10-23. They use the active shared Risk object, never a fresh `include("scripts.risk")`. The save/load case exercises the real mod JSON persistence and story-start handler; it does not replace a full application-restart/save-slot test.

## Native Thought adapters: bursts, familiars, melee, Epic Fetus

Offline suite: `tests/thought_adapters_test.lua`. In game, as normal DeepSeek-chan with full Thought:

- Cursed Eye: one charged burst spends Thought once and every tear of the burst is boosted.
- Incubus or Twisted Pair: copies fired with a boosted volley are boosted; copies alone never spend Thought.
- The Forgotten's club and Spirit Sword: each swing spends once; holding the weapon spends nothing.
- Epic Fetus: each rocket spends once and its explosion deals the boosted damage; Dr. Fetus bombs are not boosted twice.
- Pause or leave the room mid-burst: no extra payment and no lasting damage change.

## Every-weapon billing and ability feedback (2026-10-24, source only)

Offline: `tests/paid_attacks_test.lua` drives the real observer; removing the start-window skip, the per-player window, the throw reset, the swing or rocket once-flag, the Ludovico firing check or the familiar exclusion each makes it fail. Engine cases, pending:

- Normal Claude, tainted Claude and tainted GPT in Full Send, each with Brimstone, Technology (held), Mom's Knife, the Forgotten's club or Spirit Sword, Epic Fetus and Ludovico: the meter moves once per 0.2 seconds of held beam or steered Ludovico, once per throw, swing or rocket; an idle Ludovico tear, a knife resting on the player, Incubus copies and other familiar weapons cost nothing.
- Normal Claude Limited: every weapon above deals 40% damage for five seconds; damage returns afterwards and after Banked Reset ends Limited early. Check that a 20/20 volley reaching 100 keeps full damage on every pellet.
- Two-player Claude co-op with different account ages: floors age each player, a suspension resets each player once, Birthright shields only its owner. Continue an old save from before this change: each Claude gets the previous shared age.
- New tainted Gemini/Grok/Qwen/Llama/Mistral/Doubao/Kimi/GLM runs start with one key and no bomb.
- Mistral Pounce and Baguette, Doubao Apology, Kimi tasks and GLM requests show their poof or tint, which never hides an enemy, blocks a shot or lingers after room exit.
- Tainted DeepSeek with Brimstone, Technology, Mom's Knife, a melee weapon, Dr. Fetus and Epic Fetus: in Forks On with enough Compute, each paid attack costs 2 (Valley) or 4 (Peak) Compute and hits for 1.3x; in Saving or at low Compute, native damage and no cost. A held beam boosts only while its windows are paid; a knife resting on the player is never boosted.
