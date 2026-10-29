# Changelog

## Transparent item icons and dossiers (2026-10-29; art wiring)

- The owner reported transparent item textures in game. `content/items.xml` named every icon as `collectibles/<name>.png` or `trinkets/<name>.png`, but the engine adds that folder itself under `gfxroot`, so it looked for `gfx/items/collectibles/collectibles/<name>.png` and found nothing. All 92 entries now give the bare file name; the PNG files do not move.
- The 22 MAP dossier `.anm2` files named their image as `gfx/ui/dossiers/<key>.png`, but spritesheet paths resolve relative to the `.anm2` folder. They now name `<key>.png`, like the menu wrappers in `content/gfx`.
- `tools/check.sh`, `tools/make_item_art.py` and `tools/check_assets.py` now resolve both paths the way the engine does and reject the old form, and both art importers write the relative dossier path. Not yet confirmed in game.

## Repository move (2026-10-28; documentation)

- Development continues in WaterLily5297/claude-chan-isaac-v2 with main's full history. PR and issue numbers before this entry belong to the original repository, which stays as a read-only record with its old branches.
- No gameplay or file layout change. The mod folder name stays `claude-chan-isaac`, so installed builds and saves are unaffected.

## Open item rules decided (2026-10-28; documentation)

- The owner delegated the remaining rule questions. The implemented rules stand for F3 (Herd Bell, Tibo Reset, Nano Banana, One Small Rock a Day), F5 (Same Model Badge restarts on every uncleared entry) and F14 (Token Recall takes your blue and blood tears). The design table now matches the code.
- No gameplay change. F1 and F7 were decided with code changes in #146 and #147.

## Opus Mode remembers its partial bill (2026-10-28; offline fix)

- Opus Mode counted attacks toward its next coin only in entity data, so saving and continuing reset the count and skipped coins. The count is now saved per player slot and follows its live player, like the F6 fix.
- The other F7 counters (Strawberry/Blueberry, Cheap Relay, Ultrathink, room bonuses) stay transient by design; the owner delegated this decision and it follows the long-term plan.
- tests/opus_continue_test.lua fails on the old code. Installed 8fd6a8c is untouched.

## Compact can start Limited (2026-10-28; offline rule fix)

- When Compact's 50 usage took Claude-chan to 100, she stayed un-Limited until her next attack. Compact now starts Limited at once, like every other paid action, and shows "Usage limit reached".
- Compact during Limited still costs nothing and does not restart the countdown. Car Battery still bills once.
- The owner delegated this rule decision (F1); it follows the long-term plan's recommendation. Installed 8fd6a8c is untouched.

## Vibe Coding bills the right player (2026-10-28; offline fix)

- Vibe Coding saved "took a hit this floor" by player slot only. If another player took over that slot during the floor, or co-op slots were reordered, the next floor's API bill went to the wrong player.
- The mark now follows its live owner within the session, using the same tracking as the F6 fix. Continue and the bill itself are unchanged.
- tests/vibe_persistence_test.lua gains replacement and reorder cases that fail on the old code. Installed 8fd6a8c is untouched.

## Disgrace Loop ignores blocked hits (2026-10-28; offline fix)

- A hit blocked by Sold Out, Red Stamp or Constitution still froze every enemy and used up Disgrace Loop's once-per-room reaction. It now reacts only to a hit those shields let through, the same order You're Absolutely Right! uses since F9.
- The room's reaction list is also cleared on game start and exit. The flag filter, freeze length and once-per-room rule are unchanged.
- tests/disgrace_order_test.lua fails on the old code. Native freeze timing is still unobserved. Installed 8fd6a8c is untouched.

## Saved item state stays with its player (2026-10-28; offline fix)

- Backlog items and the meme extras saved their per-player values by slot only. A new player entity in an old slot (for example after a co-op player leaves and another joins) inherited the old owner's Anniversary Cake, 9.11 > 9.9 and other saved values.
- The slot's live pointer and seed are now tracked for the session, never saved. A replacement or later join starts fresh, reordered players keep their own values with refreshed stats, a removed player's values are not saved, and Continue restores slots as before.
- tests/slot_owner_state_test.lua fails on the old code. Native revival, co-op join and Tainted Lazarus Flip ordering are still unobserved. Installed 8fd6a8c is untouched.

## HUD text fits narrow screens (2026-10-28; offline layout fix)

- A form's HUD line that would run past the screen edge now moves its trailing parts to the second row of the same player's band. At 480 wide only Qwen-chan's longest line (74 characters) wraps; text, colour and order are unchanged.
- Dossier cards keep the portrait clear of the text column and shrink it on narrow screens. At 640 wide and above the placement is unchanged.
- docs/HUD_TEXT_AUDIT.md records the estimates (6 px per glyph) and the open native checks (HUD corners, offset, real font widths). No gameplay change; installed 8fd6a8c is untouched.

## Pose-cell leftovers cleaned (2026-10-27; offline art fix)

- Remove 219 crop-leftover pixels from the complete-pose cells of Tainted Claude, Qwen, Mistral and Doubao (and their tainted skins): neighbour slivers at cell edges and two stray lines under Qwen's feet. Only those pixels change, to transparent.
- tools/clean_pose_cells.py runs as the packer's last step, and the pose geometry gate now fails on any new leftover.
- docs/SPRITE_AUDIT_2026-10-27.md lists poses cut by their source crop on Tainted Claude, Claude, Llama and Doubao. These need the private source atlases and stay open. Installed 8fd6a8c is untouched; no engine check.

## DROP refusal audit (2026-10-27; documentation)

- Add docs/DROP_REFUSALS.md: for all 22 forms, when a DROP tap is refused and whether any text explains it, plus the shared tap rules. Most refusals are silent; only Tainted Qwen-chan and Llama-chan explain one in words.
- Link it from manual check 3. No code, value or cue changes; adding cues is a separate open change.

## Seahorse Emoji lifecycle cases (2026-10-27; offline evidence)

- Add F10's offline owner and lifecycle cases: two players keep separate wisps, replacing one keeps the other, a wisp killed in combat is replaced, and game exit removes every tracked wisp without recreating any.
- Production already passes. Faults that share one owner key or skip pre-exit removal fail the suite. Native save/reload ordering stays open; no behaviour changes and installed 8fd6a8c is untouched.

## Disgrace Loop text matches its filter (2026-10-27; offline text fix)

- The English EID and all three READMEs said self-damage never triggers Disgrace Loop. The unchanged filter only skips fake and penalty-free damage, so your own bomb blasts do trigger it, and the text now says so.
- A regression pins both cases. A penalty-free blast neither freezes enemies nor spends the room's trigger; a plain blast freezes them. Late cancellation, Continue restart and native flag sources remain open. Installed 8fd6a8c is untouched.

## Last twelve designed item icons (2026-10-27; offline art)

- Replace the last six collectible and six trinket placeholders with original drawings: a floor pin, a pipe valve, a ringed coin, a piggy bank, a needle through tears, blueberries, a slashed price tag, a rock on a plate, a moonlit mountain cave, an umbrella against curse drops, a leaking jar and an ice cube in a loop arrow.
- All 92 registered icons are now designed. Review sheets now size to the batch, and earlier sheets stay byte-identical. Glyphs (Blueberry's "B") and the old Disgrace Loop face are gone. Mechanics, XML and installed 8fd6a8c are unchanged; the native look is unaccepted.

## Eighth ten designed item icons (2026-10-27; offline art)

- Replace ten collectible placeholders with original drawings, including a tungsten cube, a glued pizza slice, a strawberry, a bridge tower, a seahorse, a temperature knob, a book stack, a crossed-out letter, a rubber stamp and a cartridge. Add one shared red ramp.
- Remove the cube's dots, the bridge's face-like cable and the envelope's flap lines during review. Eighty icons are designed and twelve remain placeholders. No mechanics change.

## Seventh ten designed item icons (2026-10-27; offline art)

- Replace six Claude collectibles and four trinkets with original drawings, including a speech-bubble heart, a fan-folded printout, an unlatched padlock, headphones with drops, a ticked clipboard, a wiped slate, a doormat, a status monitor, a ribboned form and a support headset.
- Add one shared green ramp, plus an optional author argument so Claude-drawn records say so. Seventy icons are designed and 22 remain placeholders. No mechanics change.

## Rice Cooker reward survives Continue (2026-10-27; offline fix)

- MealBreak already saved Rice Cooker's lunch lockout, but the pending 2x reward was transient, so a Continue during lunch kept the lockout and lost the reward. The reward is now saved per player beside the lockout and restored on Continue (F15).
- A real-module regression covers Continue mid-lunch, the 7-damage reward, no regrant after a second Continue and a new run dropping it. The baseline fails it. Other meals are not refunded or primed.

## Handoff compaction and publishing refresh (2026-10-27; documentation)

- Compact docs/HANDOFF.md to about 15 KB, with a size rule and a "Recent units" table. The previous text is archived verbatim in docs/HANDOFF_HISTORY_2026-10-27.md.
- Refresh docs/PUBLISHING.md with current counts, an owner go-ahead item and an explicit note that Workshop release is not authorized yet.

## Item text corrections (2026-10-27; offline text fix)

- Subagent Swarm's EID in all three languages now says each paid attack costs double usage or Quota for Claude forms (F4). Sanity Test's pickup text now says three separate attacks (F5). Behaviour is unchanged.

## Sixth ten designed item icons (2026-10-27; offline art)

- Replace ten Doubao/Kimi/GLM collectible placeholders with original megaphone, eraser, projection screen, thread spool, transparency stack, lectern, ticket roll, empty shielded crate, winding wheel and pass drawings.
- Add deterministic sources, metadata/provenance and 1x/4x light/dark before-after sheets. Refine fly wings and gear teeth, and correct a projection-foot margin caught by the existing validator. Sixty icons are designed; 32 remain placeholders.
- Preserve other artwork, all Lua/tests/XML, gameplay values and installed 8fd6a8c. The unchanged gate now checks twelve art sheets; native presentation remains unaccepted.

## Charm after ordinary shields (2026-10-27; offline fix)

- Run You're Absolutely Right! after ordinary shields so Sold Out/Red Stamp can refuse a hit before its source is charmed. Preserve the 150-frame effect, owner/source checks, caption, nil return and existing damage-flag behavior.
- Reproduce the old guarded-bullet reaction with real modules, then cover both shield and unguarded paths, Constitution, co-op, source exclusions and explicit early/late callback limits. Four faulty copies fail the new regression; the full gate grows to 73 Lua suites/190 tracked Lua files.
- Preserve existing suites, art, tooling/XML, balance and save formats. Native health/status timing and other F9 cases remain open; installed 8fd6a8c is untouched.

## Ordinary primary-tear integration (2026-10-27; offline evidence)

- Add a real six-module fixture for all 64 loadouts: Hardcoded Output, 1M Context, Strawberry, Pizza Glue, Golden Gate Claude and Blueberry. Check 768 primary tears across two interleaved owners, age/scale/colour/flag composition and targeted controls.
- Capture existing 3.5-to-7 Strawberry composition followed by Context decay; seven isolated faults fail the suite. Production already passes, so no gameplay rule or fix is introduced. Correct item coverage links that previously pointed at character-tint tests.
- Preserve all existing tests, gameplay, assets, save shapes and installed 8fd6a8c. The gate grows to 72 Lua suites/189 tracked Lua files; native compatibility remains unaccepted.

## Fifth ten designed item icons (2026-10-27; offline art)

- Replace ten Llama/Mistral/Doubao collectible placeholders with original 32x32 objects, including an unlocked weight, cowbell, charging cradle, timed parcel, baguette, boots, kitten, compass, truce flag and repaired boomerang.
- Add deterministic drawings, metadata/provenance and 1x/4x light/dark before-after sheets. Refine bread colour/scoring, the boomerang bend and separation around the unlocked shackle during visual review. Fifty icons are now designed; 42 remain placeholders.
- Preserve other art, all Lua/tests/XML, gameplay values and installed 8fd6a8c. The full gate includes all ten review sheets. Native appearance and the kitten's in-room entity sprite remain unfinished.

## Active-item integration and scheduled hardening (2026-10-27; offline evidence)

- Add a filtered two-module fixture for Ignore Instructions and I Panicked: 24 supplied order/slot/owner sequences and four target-death sequences check effects after each callback.
- Demonstrate a dispatch-coverage gap: four wrong/missing item-filter faults pass the existing isolated suites but fail the new integration suite. Production modules already pass the new cases; no new gameplay defect is claimed.
- Review #121-#124 and retain native timing, F12, save/identity and art-acceptance limits. The gate grows to 71 Lua suites/188 tracked Lua files; all existing tests, gameplay, art, balance, save shapes and installed 8fd6a8c are preserved.

## Ignore Instructions distinct Car Battery target (2026-10-27; offline fix)

- Honor the existing description's different-enemy repeat even when the first target is a boss or resists charm. Remember only the latest primary per live owner/active slot; consume that exclusion on the repeat and clear transient records on room entry/game start.
- Preserve ordinary targeting of confused bosses, range, duration, deterministic ties and return fields. Add real-module regressions for four supplied slots, interleaved owners/slots, status refusal, target/owner replacement and cleanup. The original source fails the new two-boss assertion; eight isolated faults pass retained old assertions with expanded API stubs and fail the added cases.
- Native callback timing, actual charge behavior and special-player routes remain open. No balance, save schema, art or runtime change; installed 8fd6a8c remains preserved.

## Pending Birthright timing coverage (2026-10-27; offline evidence)

- Extend the tainted Gemini, Llama, Mistral and Kimi real-module suites with gain/loss/reacquisition while effects are pending. Preserve deployment-time durations, live bake thresholds and per-pulse multipliers according to each existing source contract.
- Verify exact deadlines, progress/resources and owner separation. Four isolated sampling-policy faults pass the old suites and fail the added assertions. This closes a focused test gap without claiming a production gameplay defect.
- Record the timing matrix and native follow-ups. Gameplay, balance, art, saved shapes and installed 8fd6a8c are unchanged; no engine or runtime access.

## Fourth ten designed item icons (2026-10-27; offline art)

- Replace ten Gemini/Grok/Qwen collectible placeholders with original 32x32 objects, including a six-finger glove, paired preview frames, a megaphone, live cable, spring glove, pinned note, wooden mannequin, adapter, weight plates and clockwork mouse.
- Add reproducible 1x/4x light/dark before-after sheets, provenance and manifest entries. Refine finger shape and glove folds after visual review. Forty icons are now designed; 52 remain placeholders. Correct the stale current collectible subtotal.
- Preserve other art, game Lua, existing tests, registration, gameplay values and installed 8fd6a8c. Native appearance remains unverified; all eight review sheets join the unchanged offline gate.

## I Panicked repeat pickup protection (2026-10-27; offline fix)

- Honor the existing source contract that Car Battery repeats damage without deleting newly appeared consumables. Ordinary uses still delete the starting pickup snapshot; boss damage, eligibility, charge return and protected pickup classes are unchanged.
- Add real-module regressions for supplied first-hit and intervening drops, combined repeat flags, four active slots, subsequent co-op use and refusal. Baseline fails the new protection assertion; three isolated faulty implementations are rejected. Clarify the English EID and generated reference.
- Native callback/drop timing remains unverified. Preserve installed 8fd6a8c; no runtime, save, settings or art changes.

## Thumbnail producer repair (2026-10-27; offline hardening)

- Replace removed placeholder APIs with validation of the current registered Ban Hammer and an explicit 512x512 local preview export. Add a read-only comparison mode and prevent writes into game assets or art review sheets.
- Add six Python regression groups to the shared gate and inspect a temporary preview. Keep every tracked image, including the legacy thumbnail, unchanged; the tool does not publish or supply an accepted final cover.
- Review recent art, Cartridge, binding and F12 diagnostic boundaries. Gameplay and installed 8fd6a8c are unchanged; F12 and native acceptance remain open.

## Charged-use replacement audit (2026-10-27; offline evidence)

- Add a standalone diagnostic for refused/accepted active uses followed by supplied slot, item and charge changes. Reproduce false Base Model, Please Come Back and Access Pass observations across slots 0-3.
- Record why charge-only and same-item predicate experiments do not establish a complete replacement: one retains false observations, the other loses accepted/removal cases. Keep production rules and code unchanged until the completion/removal contract can be verified.
- Document native follow-ups and base/optional-extension API limits. The normal gameplay suites remain unchanged; diagnostic exit is not a compatibility pass. Installed 8fd6a8c is preserved.

## Third ten designed item icons (2026-10-27; offline art)

- Replace ten existing collectible placeholders with original cake, guarded bowl, alarm clock, fish jar, target loupe, route receipt, winding power pack, identity badge, banana peel and broad brush drawings.
- Add batch 03 before/after sheets at 1x/4x on light/dark backgrounds, with a dedicated fruit-yellow ramp and warm candle flame refined during visual review. The registry now records 30 designed/62 placeholder icons.
- Preserve all 167 untargeted PNGs, 25 animations and gameplay/registration/tests. Full offline gate checks all six review sheets; installed 8fd6a8c remains owner-untried and unchanged.

## GPT/Grok binding allocation (2026-10-27; offline optimization)

- Reuse unchanged per-slot identity snapshots for normal GPT and tainted Grok, and read each player's type once per binding pass. Preserve pointer/seed/type replacement, missing-slot retirement and all gameplay/save rules.
- Add a repeatable isolated profiler and record allocation/attack-history measurements with explicit native-performance limits. Attack-choice reconciliation and billing are unchanged.
- Extend existing character regressions for stable accounts, slot swaps, departures/rejoins and pointer-only replacements. Full offline gate passes; installed 8fd6a8c remains owner-untried and untouched.

## Cache Cartridge combat expiry (2026-10-27; offline fix)

- End the existing +0.15 entry bonus when a revisited clear room becomes hostile without changing rooms. Observe combat during the shared update and early speed-cache evaluation; clearing again does not regrant the consumed entry bonus.
- Refresh affected holders once while preserving Error Budget, Checkpoint Pin and unrelated players. Keep room-entry eligibility, charge/reward behavior and the transient save boundary unchanged.
- Extend real backlog-module regressions with in-place combat, early-cache, co-op and inventory controls. Native spawn/wave/room-clear timing remains open; installed 8fd6a8c is preserved.

## Second ten designed item icons (2026-10-27; offline art)

- Redraw eight existing collectibles and two trinkets using original object geometry and material ramps. Give Hardcoded Output a tear-casting die instead of numeric text; use distinct injection, house, key, envelope, coin-meter, hourglass, bench, emergency-button and fuse silhouettes for the other effects.
- Add reproducible batch 02 sheets at 1x/4x on light/dark backgrounds. Refine the relay key teeth and exposed gear during visual review. Registry now records 20 designed icons and 72 placeholders.
- Preserve all 165 untargeted PNGs, 25 animations and gameplay/registration/pools. Full offline gate passes; installed 8fd6a8c and native acceptance remain unchanged.

## Claude Usage save validation (2026-10-26; offline hardening)

- Validate normal Claude's Usage and Limited counters independently with their existing integer bounds. Missing, nonnumeric, non-finite, fractional or out-of-range fields recover to the existing zero default; valid debt, countdowns and unrelated progression remain intact.
- Preserve the legacy saved-table shape and item aliases. Extend the real Risk load/character regression with 18 boundary cases and a second detached save/load; retain all existing Continue, owner, timer and item controls.
- Review the recent art pipeline, first icon batch and Thinking Cleared refresh without changing their scope. Native save acceptance and whole-mod performance measurement remain open; installed 8fd6a8c is preserved.

## Thinking Cleared inventory refresh (2026-10-26; offline fix)

- Apply/remove the existing +1 damage when the trinket is picked up/dropped within a room. Damage evaluation reads current inventory even before the next player update; unchanged inventory does not cause repeated cache rebuilds.
- Preserve first-visit primary-charge drain, additive damage, partner isolation and the existing trinket-scaling policy. Add a real-module inventory/cache regression with failing-before evidence and charge controls.
- Native callback timing, special charge types and Continue remain unverified. Preserve the owner-untried installed 8fd6a8c build.

## First ten designed item icons (2026-10-26; offline art)

- Redraw Ban Hammer, Compact, Summary Stapler, Ultrathink, Subagent Swarm, The Constitution, Lunch Break, Rice Cooker, Token Recall and Let's Delve using original pixel geometry, material ramps and transparent margins.
- Provide reproducible 1x/4x before-after sheets on light/dark fields with original project reference shapes. Record source/provenance and review-sheet freshness; registry now has ten designed and 82 placeholder icons.
- Preserve the other 163 existing PNGs, all animation content, character identities and gameplay/registration/pools. Full offline gate passes; native visuals and the owner-untried installed build remain unchanged.

## Explicit item-art production pipeline (2026-10-26; offline)

- Register all 92 item icons with explicit placeholder/designed status, drawing source, provenance, palette/alpha contract and output hash; keep all current PNG bytes unchanged.
- Add a deterministic producer/validator and status-aware asset gate, preserving existing character/menu/pose checks and exact legacy placeholder comparisons. Protect designed icons from the legacy generator's canonical writes.
- Add thirteen regression groups and verify old-gate failure for a valid designed fixture plus four isolated fault rejections. First-batch artwork and native acceptance remain pending; the installed manual-test build is preserved.

## All-item completion audit (2026-10-26; documentation only)

- Map all 80 collectibles, 12 trinkets and five pills to registration, actual source behavior/state, existing fixtures and specific native or semantic gaps; list Agentic, Hydra and Relay Slime separately.
- Reconcile all 80 pool entries over 79 unique collectibles and distinguish shared-service tests, smoke observations and unverified native interactions. Record fifteen follow-up findings without changing gameplay or claiming new regressions.
- Correct stale expansion rollout prose, retain unimplemented design components explicitly, and preserve the owner's untested installed 8fd6a8c checkpoint.

## Resource-text hardening (2026-10-26; offline)

- Clarify normal Llama's dossier: four blue flies solo, two per living co-op recipient; existing mechanics and Birthright are unchanged.
- Clarify DeepSeek's EID in all three language registrations: idle time never refills pocket charge; Thought charging remains unchanged.
- Mark completion-audit T1/T2 corrected in source, regenerate the interaction fingerprint, and retain installed 8fd6a8c and all native acceptance gaps.

## All-form completion audit (2026-10-26; documentation only)

- Map all 22 forms to their implemented loop, approved B1 tradeoff, Birthright regression, actual save boundary and remaining text/compatibility gaps in CHARACTER_COMPLETION.md.
- Distinguish snapshot fixtures from real continuation, special-player mechanics and native weapon acceptance; retain every form as open.
- Correct obsolete rollout and DeepSeek deployment statements. Record the Llama solo-fly dossier omission and DeepSeek pocket-charge wording for a separate readability fix. Installed 8fd6a8c remains unchanged.

## Normal Claude account-owner isolation (2026-10-26; offline)

- Prevent a replacement live player in the same slot from inheriting the retired Claude's age, Usage, Appeals and pending account state; prune observed removed slots and refresh replacement caches.
- Preserve detached Continue, same-entity form-return debt, partner accounts and item aliases. Identity bindings remain transient; no save schema or B1 numerical change.
- Add failing-before replacement, seed-reuse, same-frame, retirement and slot-reorder cases; retain the existing age-cap and Birthright controls. Installed 8fd6a8c is unchanged; native timing remains unverified.

## Static interaction audit (2026-10-26)

- Add a non-executing Lua source scanner and reproducible callback/priority, cache, field-write and Risk-root inventory across 110 production files.
- Classify overlaps conservatively, retain source locations and manual review notes, and record unresolved damage/colour/order/save combinations without changing gameplay.
- Add eleven scanner regression cases and a checked report-freshness gate. Preserve installed 8fd6a8c and all native acceptance limits.

## Art inventory and production specification (2026-10-26)

- Inventory all 198 bundled art files, 22 forms, 92 item icons and native-only pill/Slime/HUD presentation with provenance, defects and target work.
- Replace the stale art specification with current file/pose contracts, item-icon style and a planned deterministic designed-icon validation pipeline. No art or validator code changes yet.
- Record the owner's untested installed `8fd6a8c` checkpoint and the next long-term audit units; preserve installed files and existing evidence boundaries.

## Approved B1 merge and installation (2026-10-26)

- Merge owner-approved #102 at ef7d2dd after successful CI and install its 22 character conditions alongside O4 restoration and O5 Death packing.
- Back up and reread-hash verify 443 prior allowlisted files before replacement; verify all 451 installed tracked files against canonical Git bytes. No paths removed.
- Game closed throughout; no launch, settings/save changes or new engine acceptance. Reconcile current build/rule records and preserve the installed gameplay checkpoint during offline follow-ups.

## Character tradeoffs, all 22 forms (2026-10-26; source implementation)

- Add safe-room Tibo resets and Llama releases, wet paint, sustained-sight fact checks, owner-range demos, combat baking, clear-triggered Apology and connected requests. Existing numerical benefits are preserved.
- Complete the other fourteen conditions: kill-order age review, quiet appeals, cancellable Rice, Peak reservation, focused checks/quotes, editing angles, Adapter installation, pinned builds, stored Pounce direction, aimed Apology, single-speaker focus, task interruption and missed queue calls.
- Add versioned scalar migrations and source-owned meal cancellation. Reconcile same-attack target choices after damage, including delayed piercing hits, without changing native billing. Extend character and integration regressions; synchronize English HUD, dossiers, EID, all READMEs and review/acceptance records. #102 was subsequently owner-approved and merged; #100 remains superseded.
- Implementation was offline; the subsequent authorized installation is recorded above. No new game session.

## Death-pose geometry and all-form preview (2026-10-26; offline)

- Repack three oversized Death cells for all 22 forms using their measured native envelopes and ground anchors; retain Llama's complete Death-start source pose. Existing Hit, walking and other pixels are preserved.
- Add a deterministic 45-pose-per-form review tool and a standard-library geometry gate; retain recorded walk revisions during repacking and support tainted skin-only regeneration.
- No new art, native assets, gameplay rules or runtime deployment in this pose unit. The shared special animations and full native rendering still need acceptance. See the current B1 entry above; numerical draft #100 must not merge.

## Native transformation costume restoration (2026-10-26; offline)

- Restore currently acquired native transformation costumes once when a player leaves a mod form, alongside held item costumes; do not grant transformations or replay effects.
- Add failing-first departure/co-op/form-boundary regressions and an effect-layer source audit. Fixed mod looks remain unchanged; visual timing, shield cues and size/flight cases still need native acceptance.
- Preserve installed f8b2b0b. The owner redirected draft #100 from numerical reductions toward new character-specific gameplay tradeoffs; that draft is not approved.

## Installation checkpoint (2026-10-26; documentation only)

- Record the verified f8b2b0b installation, including DROP pocket restrictions, both new meme effects and the opt-in ancestry observer.
- Document the startup-only Repentance+ attempt, restored settings and pending native cases. No gameplay change or new engine acceptance; preserve the installed version at the owner's request.

## Manual ancestry observation tool (2026-10-26; not run in game)

- Prepare an explicitly enabled, bounded laser init/update observer for E2. It logs native link/frame fields and removes its callbacks on stop; main.lua never loads it.
- Add offline lifecycle/format checks and an authorized-session procedure. No billing policy or gameplay behavior changes; E2 remains pending and no installation was performed during that audit.

## Native meme batch 2 (2026-10-26)

- Add Let's Delve, a six-charge treasure active that delegates to the native shovel, and Six Seven, a pill that grants six or seven native blue flies using the player's seeded RNG.
- Register English pickup/EID text, an original deterministic shovel icon, pool entry and generated item documentation. Totals: 80 collectibles, 12 trinkets, five pills and 22 forms.
- The owner approved charge, pool, quality, fly count and same-effect horse pills before #95 merged. This is offline only; no installation was performed during that audit.

## DROP pocket compatibility (2026-10-26)

- Keep short DROP abilities, but disable them while carrying multiple cards, pills or pocket actives, as selected by the owner. Preserve native input and long-hold dropping.
- Cancel a gesture that encounters multiple pocket items, including same-frame inventory changes; reducing inventory while held cannot trigger an ability on release.
- Add failing-before pocket regressions and shared English control notices. Physical keyboard/controller acceptance remains pending; no installation was performed during that audit.

## Backlog child laser initialization (2026-10-25)

- Remember child identity and inherit an already resolved parent bonus at laser initialization, before Parent can disappear. Preserve the next prime, attack counters and the original expiry.
- Leave primary attacks at their existing first-update payment point. Unresolved children never synthesize a payment; ownership and room/run cleanup still apply.
- Six added regression groups cover initialization ordering; five fail on the prior source and the primary-timing control already passes. Six targeted mutants fail. Installed `220d542` includes PRs #89 and #90 but predates this source correction; engine acceptance remains pending.

## Detached child laser billing (2026-10-25)

- Retain a laser child identity observed at init/update so clearing Parent cannot start another paid observer window. Pause, young-entity filters and window resets do not erase the classification.
- Preserve normal Claude Usage, tainted Claude Quota, tainted GPT Credits and Opus counters while the next independent primary remains paid. Keep Peak's damage-first exclusion and native damage/boost behavior unchanged.
- Seven new regression groups fail on the prior source; eight targeted mutants fail. The full offline gate passes. Installed `c6cd8fc` remains unchanged; native acceptance is pending.

## Tainted DeepSeek child laser boost (2026-10-25)

- Share the parent laser's paid/unpaid Compute decision and original boost window instead of buying another child boost. Preserve native fields and subsequent independent primary payments.
- Retain child classification after parent removal, validate ownership and invalidate transient decisions on room/run or binding changes. Peak's observer exclusion runs before taking a payment window.
- Twelve offline groups pass, eleven fail on the old source, and eight targeted mutants fail. Native acceptance is pending; installed `c6cd8fc` remains unchanged.

## Backlog child laser inheritance (2026-10-25)

- Let validated child lasers share a resolved parent attack and its original expiry without consuming new primes, scheduling Finger or advancing distinct-hit items again. Preserve damage bonuses and the next independent primary.
- Keep detached children classified and reject conflicting owners. Offline regressions cover ordering, ownership, cleanup and expiry; native ancestry and damage dispatch remain pending. Installed `28fed37` is unchanged.

## Child laser resource accounting (2026-10-24)

- Skip normal Claude Usage, tainted Claude Quota and tainted GPT Full Send Credit charges at laser initialization when the direct `Parent` is a laser. This matches the existing Opus and shared paid-attack observer exclusions.
- Preserve primary-start costs and later eligible primary windows. CHILD-LASER-01 is source-only: native parent attribution and callback timing remain unverified, and the installed manual-test checkpoint `28fed37` is unchanged.

## Tainted Llama helper accounting (2026-10-24)

- Route Still Waiting helper tears through the shared derived-shot path before synchronous callbacks. They no longer bill Opus Mode, consume attack primes or advance backlog paid-attack triggers.
- Keep native 0.5x tears, helper position, cadence and duration, including Birthright. Primary shots and Summary Stapler billing are unchanged. This is an offline correction; native timing, weapon interactions and save/continue remain unverified.

## Opus backlog helper billing (2026-10-24)

- Exclude Please Retry and One More Finger helper tears from Opus Mode coin billing before synchronous shot callbacks run. Preserve normal-shot costs, Summary Stapler billing and primed attack bonuses.
- Scope helper creation per player, support nested helpers, and restore the previous scope after nil/error returns. Offline regression uses real callback registration order; engine timing remains unverified.

## Consensus Coin familiar sources (2026-10-24)

- Recognize familiar-fired projectiles as familiar damage for Consensus Coin, including direct spawner and parent ownership links. Familiar contact and different familiar weapons share one source category.
- Keep familiar attacks separate from player attack leases and primed bonuses. The mixed-source window, pulse damage and once-per-target limit are unchanged. Native familiar attribution remains pending engine verification.

## Stored battery charge detection (2026-10-24)

- Count primary plus stored battery charge when observing an owned room-charged active use. Spending only The Battery's second bar now triggers Base Model and Access Pass and resets Please Come Back progress.
- Keep slot eligibility, Car Battery exclusion and charge rewards unchanged. Offline coverage models both bars and real item listeners; native discharge timing, full refunds and special health-charge pools remain unverified.

## Constitution player isolation (2026-10-24)

- Track The Constitution pickup reward and floor shield separately for each player in versioned saved data. One holder no longer consumes another holder's effects. Preserve prior shared consumption on legacy-save migration; keep stat costs, excluded damage and 60-frame refused-hit cooldown unchanged.
- Regression covers two holders, detached continue, new floors, replacement players, ghosts/death and old saves. Native health, serialization and special twin/subplayer behavior remain unverified.

## Paid-attack subscriber isolation (2026-10-24)

- Give each paid-attack subscriber its own transient once-per-attack marker. Opus Mode no longer prevents later character consumers from observing knives, melee swings or Epic Fetus rockets, including when Opus is not owned.
- Keep per-throw reset, duplicate suppression, familiar exclusions, native weapons and all costs unchanged. Real Opus plus multiple real shared-service registrations reproduce the old failure and pass the fix. Offline only; native combat and save/continue remain pending.

## Unreleased meme gameplay batch 1 (2026-10-24)

- Add four meme collectibles, all built on native systems: Em Dash (native piercing, +0.16 shot speed per copy), Blueberry (every third tear gains the native quad split; counted separately from Strawberry), Benchmaxxed (+1.5 damage per copy in boss, mini-boss, challenge and Boss Rush rooms, x0.9 per copy elsewhere, re-evaluated each room) and I Panicked (A6, devil pool: lethal native damage to non-bosses, 15% max HP to bosses, deletes loose consumables; pedestals, trinkets, chests and shop items are safe).
- Original 32x32 icons from tools/make_placeholders.py, EID text, pickup lines, docs/ITEMS.md and all three READMEs. New offline suite tests/meme_batch_test.lua; engine acceptance pending.

## Unreleased fixed character look (2026-10-24)

- All 22 forms keep their own sprite: item, trinket, pill, card and transformation costumes are cleared on mod forms, while every effect, stat, flight and size change still applies (`costume_lock.lua`). Vanilla characters are untouched; leaving a mod form restores held item costumes. Engine acceptance pending.

## Unreleased owner-delegated trait decisions (2026-10-24)

- Tainted DeepSeek: every non-tear native attack pays the phase's Compute price for a 1.3x off-peak boost on that attack; Saving or low Compute keeps native damage.
- GLM's pocket Book of Secrets stays removed. Both choices were delegated by the owner to the community memes.

## Unreleased character trait completion (2026-10-24)

- Bill every native weapon for Claude usage, tainted Claude Quota and tainted GPT Full Send: held beams and Ludovico per 0.2-second window, knife throws, melee swings and Epic Fetus rockets (`paid_attacks.lua`).
- Claude Limited is a 0.4x damage-stat multiplier, so it weakens every weapon. Claude account age is per player, with a migration from the old shared value.
- Eight tainted roster forms start with one key instead of one bomb, per the shared contract; the asset check enforces it.
- Visual-only feedback for Mistral, Doubao, Kimi and GLM abilities (vanilla poofs and fading tints). EID character info for all 22 forms.
- New offline suites for the paid-attack observer and feedback helper; engine acceptance pending.

## Authorized Risk and backlog integration (2026-10-24)

The owner explicitly authorized merging PR #55 and PR #56 while keeping work offline. This source integration includes both fixes and retains their separate evidence below. The earlier PR #50-54 integration remains a historical checkpoint. No game launch, runtime replacement or Workshop release is authorized by this merge; installed source remains the previously verified `2ec15ef`.

COMPOSE-02 applied the published PR #55 head `dc0fdbf7a932f5cc04bbeae7968512d02d1400af` and PR #56 head `9511dcf2723e1ca41da25ac20c55bedc42f006b2` to main `d91eee7`. All non-Markdown files were identical in either application order. The combined gate passed 50 stub suites, 148 tracked Lua files, five XML files and deterministic asset checks. Four Markdown insertion conflicts are reconciled here without dropping either candidate's evidence. Each original candidate separately passed 49 suites; those counts below retain their original scope. Verify the actual final integration commit and CI before reporting synchronization complete.

A separate retained-module interaction fixture checks Red Stamp and Risk together: the old-run block leaves Risk at 50, restart removes the old stamp, and the next ordinary contact adds Risk to 51. A new stamp use blocks again and preserves the clean-room reduction to 49. Reverting either fix independently fails. Both start flags are modeled with HasData=false; the initial missing HasData stub was a harness error corrected before recording results. This does not load serialized data or prove native health loss, callback order or save/continue.

Engine retests remain pending: native shield dispatch, risk threshold, clean-room awards, temporary effects across fresh starts/continue, co-op, later external damage blockers, native entity lifetime and save order. The transient Risk hit latch remains unsaved. Continue the complete menu/input, animation/costume, native-weapon, save/co-op and base Repentance matrix only when the owner is available. No new content is part of this integration.

## Unreleased item descriptions (2026-10-24)

- Rewrite all 87 pickup lines in content/items.xml as short effect hints that keep the meme, so players without EID can tell what an item does. Names, ids, charges, pools and EID text are unchanged.
- Extend tests/eid_test.lua: every collectible, trinket and pill declared in the XML must have a pickup line (collectibles and trinkets) and an English EID entry under the same name.
- Add docs/ITEMS.md, an item reference generated by tools/item_reference.lua; tests/item_reference_test.lua fails when it is stale. Pickup text display is not engine-verified.

## Unreleased Risk damage eligibility (2026-10-24)

- Ignore fake/no-penalty and ordinary-shield-cancelled damage in Risk accounting; observe after default-priority blockers. Ignore damage outside an active run and reset the transient room latch on start/continue.
- Add a real-module regression that fails on main, with shield, clean-room, ordinary-hit, coverage and lifecycle controls. Preserve the shared account, save schema and DeepSeek/roster exclusions. All 49 offline suites pass; engine retests and mid-room hit-latch persistence remain pending.

## Unreleased backlog run cleanup (2026-10-24)

- Clear module-local temporary backlog effects at exit and start/continue, independently of initial room callback order. Remove only owned preview decoys; preserve native familiars and persistent tables. Cleanup does not synthesize room-entry events or rewards.
- Regress stale Kitten repulsion, preview decoys, banana peels, contact stamps, Community Note exposure, pending One Bowl pickups and Consensus source history. All 49 offline suites pass; native save/continue and entity lifetime still need engine validation. This main-based fix is independent of the Risk damage candidate.

## Authorized compatibility integration (2026-10-24)

Source integration checkpoint (2026-10-24): this tree combines PRs #50-54 under the owner's explicit merge instruction. The latest owner constraint remains offline-only. Installed game files remain at main `2ec15ef`; no combined engine acceptance or Workshop release is claimed. Earlier candidate, approval and deployment statements below are historical checkpoint records.

- Preserve familiar attribution, Claude timer guards, helper resource billing, Vibe damage eligibility and bounded hurt-frame observations together. Keep every candidate-specific pending engine checklist.

## Unreleased Vibe Coding damage eligibility (2026-10-24)

- Fake/no-penalty damage and hits cancelled by default-priority shields no longer spoil Vibe Coding's floor bill waiver. Observe damage after ordinary blockers; preserve the existing 25% charge for eligible hits and per-player persistence.
- Add real-module regressions with Sold Out and Red Stamp, ordinary hits, two-player isolation, floor reset and late acquisition. Offline only; no deployment or engine acceptance while the owner requests offline work.
- Offline integration experiment: PR #50-54 source/test changes compose without code conflicts and pass 48 suites together. Record the four overlapping Markdown files for deliberate evidence-preserving resolution. This reporting follow-up does not merge or deploy any candidate.

## Unreleased helper resource billing (2026-10-24)

- One More Finger and Please Retry mark their extra native tears before character callbacks, preventing an extra Thought, Quota or Compute payment. Normal Claude no longer adds usage for those helpers; an already active Limited damage penalty still applies.
- Add a real-module integration regression for all four resource-owning forms, both item schedules, primed bonuses and subsequent primary-shot billing. Offline only; not deployed or engine-accepted. Game testing is deferred at the owner's request.

## Unreleased normal Claude timer guards (2026-10-24)

- Advance normal Claude's Limited countdown and idle usage drain once per player/gameplay frame; freeze paused/dead updates and clear transient guards on start/exit. Balance values and save format are unchanged.
- Extend the real-module usage/save regression with duplicate wrappers, co-op isolation, pause/death, exact expiry, revival and lifecycle resets. Correct the old countdown fixture to advance actual frame values. Offline verified; engine timing and animation/costume acceptance remain pending.

## Unreleased bounded hurt-frame observations (2026-10-24)

- Record actual-damage Hit frame 6 engine markers for all 22 forms and Isaac on main `2ec15ef`, Repentance+ v1.9.7.17. Sixteen mod forms plus Isaac have inspected screenshots; six mod forms still need clean visual coverage.
- Keep the oversized-head report open: complete animations, item costumes, Reactions-disabled cases and fresh menu starts remain unaccepted. No runtime code or artwork changed; test fixtures and private evidence are not shipped.
- Correct stale handoff statements that engine testing was still unauthorized. Keep PR #50 separate from the main-based animation sweep.
## Unreleased targeted ability ownership fix (2026-10-24)

- Exclude familiar contact entities from player-only target attribution. A familiar kill could incorrectly restore normal GPT's Verified status through its player spawner/parent. Native weapon ownership is preserved.
- Add a shared attribution regression and a real GPT callback case; both fail before the fix. Full offline gate: 144 Lua files, five XML files, 46 suites. Two controlled Repentance+ engine cases passed on candidate `aae85fd`: blue-fly contact kill stays Fallback; own native-tear kill restores Verified. Physical DROP input and broader familiar/weapon coverage remain pending.
- Record the fresh-start menu-input blocker and correct stale testing-authorization statements. No new fresh-start acceptance or Workshop release.

## Unreleased handoff audit (2026-10-24)

- Normal and tainted Claude now bill usage/Quota for laser starts and Dr. Fetus bombs, sharing the frame's payment with tears; familiars, placed bombs and knives stay free.
- HANDOFF.md gains a "Status at a glance" section (done, needs the game, needs an owner decision) and drops stale lines found in a line-by-line audit against main.

## Unreleased roster story arcs (2026-10-24)

- Add three short story captions for each of DeepSeek, GPT, Gemini, Grok, Qwen, Llama, Mistral, Doubao, Kimi and GLM (normal or tainted), on run start, stage 3 and stage 5. Seven seconds, non-blocking, once per run, co-op queued in player order, saved in `Risk.state.rosterStory` (version 1).
- New offline suite `tests/story_roster_test.lua` (24 in total). English only; not tested in game.
## Unreleased roster stack landing (2026-10-24)

- Bring the full roster stack to main in one PR: nine normal loops (GPT, Gemini, Grok, Qwen, Llama, Mistral, Doubao, Kimi, GLM), nine tainted forms and the tainted roster art. The stacked PRs #24, #27 and #29-#45 had been merged into each other's branches instead of main.
- Regenerate the nine tainted gameplay sheets from the walk-cycle sheets (#25), which the original derivation predated. Portraits and dossiers are unchanged. 42 offline suites pass; no engine validation.

## Unreleased tainted Claude Appeal Pending (2026-10-24)

- Tainted Claude becomes Appeal Pending: 220 Quota and two Appeal Pages per floor; each paid tear volley costs 1 Quota (2 with Subagent Swarm) at 1.25x damage; at zero she is Suspended at 0.5x. A DROP tap while Suspended spends a Page on a six-second active-combat review that restores 60 Quota (Birthright 90); leaving the room cancels it. Three unique combat clears earn a Page.
- Banked Reset refills Quota and cancels a pending review without returning its Page. Per-player saved state replaces the shared weekly counter; tear color is tinted. English HUD, dossier and EID text. Offline only.

## Unreleased Claude Appeals (2026-10-24)

- Normal Claude becomes One More Day: usage is billed once per same-frame tear volley (Subagent Swarm doubles it inside Claude's billing) and drains 10 per second only while not firing. Appeals start at 1, cap 2, and are earned every two unique combat clears; a DROP tap spends one to remove 40 usage, never during Limited.
- Birthright keeps account age through the first suspension on each floor; a saved latch stops continue from re-judging it. English HUD, dossier, EID and caption `Another love letter.`
- Seventeen offline suites pass, including the new Appeals suite. Account age is still shared; tainted Appeal Pending and non-tear billing remain pending. No runtime or Workshop changes.
## Unreleased native Thought adapters (2026-10-24)

- Normal DeepSeek Thought: delayed bursts share the paid volley until the native firing cycle could repeat (floor of MaxFireDelay, cap 15 updates); Incubus and Twisted Pair tears copy a paid volley without paying; each melee swing hitbox pays once; Epic Fetus rockets pay once and their explosions are re-dealt at that factor.
- New offline suite `tests/thought_adapters_test.lua` (23 in total). Source only; engine attribution for hitboxes, rockets and familiars is unverified.

## Unreleased tainted GLM Please Retry (2026-10-24)

- Register Tainted GLM-chan with the deeper-colour art. Please Retry: damage 0.9x; a DROP tap queues a two-second request on the nearest enemy within 200 units (three-second cooldown); a surviving target takes 2x plus 1x per Retry, consuming them, and an early death adds one Retry (cap 3); Birthright failures also remove one nearby enemy bullet. Offline only.

## Unreleased tainted Kimi You Are the Manager (2026-10-24)

- Register Tainted Kimi-chan with the deeper-colour art. You Are the Manager: damage 0.85x; a DROP tap assigns a task to the nearest unassigned enemy within 220 units, dealing three 0.6x pulses (Birthright 0.7x) two seconds apart; three tasks at once and nine pulses per room; exit cancels tasks without refunding the budget. Offline only.

## Unreleased tainted Doubao I'll Do It Again (2026-10-24)

- Register Tainted Doubao-chan with the deeper-colour art. I'll Do It Again: a DROP tap starts six seconds of Confident (1.35x damage), then four seconds of Apology (0.85x, Birthright three), then ready; timers run only in combat, and an enemy hit during Confident starts the Apology early. Offline only.

## Unreleased tainted Mistral Le Gros Chaton (2026-10-24)

- Register Tainted Mistral-chan with the deeper-colour art. Le Gros Chaton: speed -0.1, damage 0.9x; standing without firing for two seconds bakes a Baguette (cap 2, Birthright 1.5 seconds); a DROP tap sends a slow 120-unit shockwave dealing 2.5x once per enemy, stopped by walls, with a two-second cooldown. Offline only.

## Unreleased tainted Llama Still Waiting (2026-10-24)

- Register Tainted Llama-chan with the deeper-colour art. Still Waiting: damage 0.9x; unique combat clears add Hype (cap 3); a DROP tap spends all of it on a stationary helper that fires one 0.5x native tear per second at the nearest enemy for four seconds per Hype (Birthright five), removed on room exit. Offline only.

## Unreleased tainted Qwen Final Final Fine-Tune (2026-10-24)

- Register Tainted Qwen-chan with the deeper-colour art. Final Final Fine-Tune: in cleared rooms a DROP tap cycles Heavy (1.3x damage, 1.2x interval), Tiny (0.85x, 0.8x) and Balanced, locked in combat; unique clears with all three builds award +0.2 damage for the floor (Birthright +0.3), up to three. Offline only.

## Unreleased tainted Grok Quote Without Reading (2026-10-24)

- Register Tainted Grok-chan with the deeper-colour art. Quote Without Reading: base damage 0.9x; a DROP tap quotes the nearest enemy within 220 units for six seconds (ten-second cooldown); paid hits on other enemies build Ratio (cap three), which lands on the quote as 1x damage pulses at expiry. Birthright moves half the Ratio once if the quote dies. Offline only.

## Unreleased tainted Gemini One More Edit (2026-10-24)

- Register Tainted Gemini-chan with the deeper-colour art. One More Edit: base damage 0.9x; a DROP tap starts a six-second (Birthright ten) chain on the nearest enemy within 180 units; three distinct paid hits go Crop, Recolor, Export and add one 2x damage pulse, once per room. Saved per player. Offline only.

## Unreleased normal GLM Number in Queue (2026-10-24)

- Normal GLM replaces active-item tool links and the forced pocket Book of Secrets. Each unique combat clear advances the Queue (max three); at three, a DROP tap redeems an Access Pass giving +20% damage in each of the next two new hostile rooms (Birthright three). The Queue pauses while the pass is active; revisits never spend or stack it. Saved per player in `Risk.state.glmQueue`.
- The roster module now keeps only identities, dossier lines and the tear tint.
- 26 offline suites pass, including the new GLM Queue suite. No runtime or Workshop changes; engine validation pending.

## Unreleased normal Kimi Another Slide Deck (2026-10-24)

- Normal Kimi replaces flawless-clear pages. Each unique combat clear earns a Slide (cap six); a DROP tap spends three (Birthright two) to present to the three nearest enemies within 220 units, slowing them for four seconds and adding +15% to the owner's damage against them. No audience, no spend. Saved per player in `Risk.state.kimiSlides`.
- 25 offline suites pass, including the new Kimi Slides suite. No runtime or Workshop changes; engine validation pending.

## Unreleased normal Doubao Sorry, You're Right (2026-10-24)

- Normal Doubao replaces the every-third-clear meal. The first enemy-caused hit in each hostile room grants a six-second Apology token (Birthright: until room exit); a DROP tap slows enemies within 100 units for two seconds and removes the four nearest enemy bullets. No health refund. Saved per player in `Risk.state.doubaoApology`.
- 24 offline suites pass, including the new Doubao Apology suite. No runtime or Workshop changes; engine validation pending.

## Unreleased tainted GPT Reset Watcher (2026-10-24)

- Register Tainted GPT-chan with the deeper-colour tainted art. Reset Watcher: 80 Credits per run (Birthright 100); DROP toggles Standard and Full Send (1.5x, one Credit per same-frame paid attack); three unique combat clears bank one Tibo reset that the next tap claims to refill Credits. Saved per player across floors and continue. Kept out of the proxy account. English HUD, dossier and EID. Offline only.

## Unreleased tainted roster art (2026-10-24)

- Add deeper-colour tainted gameplay sheets, stage portraits, dossiers and menu cells for the nine newer families, derived deterministically from the normal art (including the new walk cycle) by `tools/make_roster_tainted_art.py`. Hashes are checked by the asset gate. The forms are not registered yet; each tainted mechanic PR registers its own.
## Unreleased fifty-row backlog, rows 02-50 (2026-10-24)

- Add the 49 remaining collectibles of the fifty-row backlog (EXPANSION_DESIGN.md): four per family for Claude, DeepSeek, GPT, Gemini, Grok, Qwen, Llama, Mistral, Doubao, Kimi and GLM, plus six shared items. 22 actives and 27 passives, all with original 32x32 icons, pool entries and English EID.
- One shared service (`scripts/items/backlog/common.lua`) handles attacks across tears, lasers, knives and Fetus bombs, ordinary-bullet guards, unique clears, timers and versioned per-player saved state.
- Fix Stuck in Mt. Moon to identify rooms by `GetCurrentRoomDesc().SafeGridIndex`.
- Two new offline suites (22 in total). No engine validation, runtime or Workshop changes.

## Unreleased meme extras, batches 4-5 (2026-10-24)

- Add Seahorse Emoji (A3: one room-scoped native wisp of a random vanilla active), Temperature Dial (A2: saved toggle between x1.1 damage and one random native tear flag per tear), Deep Research (A12: native map, compass and secret-room reveal), trinkets As an AI Language Model (removes one non-Labyrinth curse per floor), System Prompt Leak (compass effect per floor) and Disgrace Loop (first real hit in a room freezes enemies 1.5 s), and the Rolled Back pill (all stats up for one room).
- Original icons, English EID and a new offline suite; twenty suites pass. No engine validation.

## Unreleased meme extras, batch 3 (2026-10-24)

- Add Strawberry (every third tear per player is a red 2x "R" tear; tears only) and Golden Gate Claude (native spectral tears, +1.5 range, golden tint, occasional seeded caption). Completes the nine-item meme-extras proposal. Nineteen suites pass; no engine validation.

## Unreleased meme extras, batch 2 (2026-10-24)

- Add three trinkets and one pill outside the fifty-row backlog: Claudius's Discount (refund 1 coin on confirmed purchases of 2+ coins; lose 1 coin per new floor), One Small Rock a Day (once per floor, breaking a rock heals half a red heart; kept while at full health), Stuck in Mt. Moon (six backtracks into cleared rooms reveal the floor map, once per floor) and 9.11 > 9.9 (permanent +0.11 damage, horse pill +0.9).
- Shared versioned per-player state in `Risk.state.memeExtras` (floor-scoped flags, saved pill bonus). Native prices are never rewritten. Original icons, English EID and a new offline suite; nineteen suites pass. No engine validation.

## Unreleased meme extras, batch 1 (2026-10-24)

- Add three collectibles outside the fifty-row backlog: Ignore All Previous Instructions (A4: charm the nearest non-boss within 200 units for 8 s, confuse a boss for 2 s, empty use keeps charge, Car Battery picks a second target), Tungsten Cube (+0.8 damage, -0.15 speed per copy, native knockback tears) and Pizza Glue (25% slowing tears, luck 10-50%, -0.1 shot speed; tears only).
- Original generated icons, pool entries, English EID and a new offline suite. Eighteen offline suites pass. No engine validation, runtime or Workshop changes.

## Unreleased roster walk cycles (2026-10-24)

- GPT, Gemini, Grok, Qwen, Llama, Mistral, Doubao, Kimi and GLM walk with visible legs: a ten-frame stride, alternating front steps, swinging side legs and a one-pixel bob. Each direction uses one stable body, removing the old frame-to-frame jitter. Carry cells get the same legs.
- Deterministic `tools/animate_roster_walk.py`, wired into the hurt-pose rebuild verifier; the asset gate now checks all thirteen atlases against the art manifest. Offline preview: `tools/preview_original_movement.py --walk-roster`. No engine validation yet.

## Unreleased roster review fixes (2026-10-24)

- The nine model roster families leave the proxy IP / risk account. A roster-only or DeepSeek-and-roster run has no IP or risk. In co-op with Claude or a vanilla character, only those covered players raise risk when hit, spoil a clean room or take the suspension damage penalty; DeepSeek no longer takes that penalty in co-op either.
- Qwen chains and Kimi pages ignore deliberate self-damage flagged `DAMAGE_NO_PENALTIES` (Blood Donation, IV Bag, sacrifice rooms), and a hit from a player outside the player list no longer errors.
- Roster tear colors tint the existing color instead of replacing it, so item colors and offsets survive.
- Seventeen offline suites pass, including the new risk coverage suite. No runtime or Workshop changes; engine validation pending.

## Unreleased tainted DeepSeek Peak / Valley (2026-10-24)

- Tainted DeepSeek becomes Wenfeng / Wengu: twelve combat seconds of Valley alternate with twelve of Peak, frozen in cleared rooms and on pause; every floor starts in Valley. Compute starts at 12 (cap 24, Birthright 32) and carries across floors. Paid tear volleys fork into two native half-damage tears for 2 (Valley) or 4 (Peak); Valley recovers 3 per second in combat while not firing. DROP tap toggles Forks On / Saving.
- Remove legacy random Server Busy shot deletion and free unconditional forks. Saved per-player Compute, phase, timer and mode; identity, character change and corrupt data reset safely. English HUD, dossier and EID text.
- Sixteen offline suites pass, including the new Peak / Valley lifecycle suite. Non-tear weapons get no forks yet; engine validation pending. No runtime or Workshop changes.

## Unreleased native Thought adapters (2026-10-24)

- Apply normal DeepSeek Thought to native lasers, flying knives and Dr. Fetus bombs, preserving original weapons and visual/effect fields. Repeated-hit beams and controlled tears use saved six-update windows; single-hit beams and released rings snapshot one attack.
- Stop persistent attacks from regenerating their own Thought. Raw continuous forks inherit the parent factor without paying again, and cleanup removes transient factors before exit. 1M Context snapshots the unboosted continuous baseline, preventing permanent compounded bonuses.
- Fifteen offline suites pass, including a regression that fails against the earlier tear-only Rice module. Epic Fetus, melee, delayed bursts, familiars, conflicting damage writers and engine validation remain pending. No runtime or Workshop changes.

## Unreleased Rice First source candidate (2026-10-24)

- Normal DeepSeek earns rice from unique combat clears and spends a bowl on a short DROP release. A two-second meal grants full Thought and six seconds of +0.15 speed; Birthright halves meal duration. The intrinsic meal never heals. Personal counters, remaining bonuses and pending meals survive continue.
- Remove normal random shot deletion and idle pocket charging. Same-frame tear pellets share one Thought payment, with resolved damage inherited by Swarm and native tear fields unchanged. English HUD, dossier and EID descriptions reflect the actual candidate.
- Fourteen offline suites pass, including meal/save/room/co-op and callback-order regressions. Non-tear and persistent-attack accounting, tainted Peak / Valley, current-engine validation and costume acceptance remain pending. Owner currently requests source/offline work only.

## Unreleased meal lifecycle correction (2026-10-24)

- Lunch Break and Brb, Getting Food share a per-player saved three-second countdown. Suppress directional shooting queries during the meal, preserve movement and other controls, and restore the remaining countdown on continue without changing character types or costumes.
- Lunch Break preserves charge during an existing meal and ignores Car Battery repeats. Offline regressions reproduce the old repeated heal and cover input isolation, pause, continue, duplicate updates, expiry and co-op identity. Charged weapons, persistent attacks and other input mods still require engine acceptance.

## Unreleased DROP tap/hold correction (2026-10-24)

- GPT/Gemini switch mode on a short DROP release rather than immediately on press. Long holds do not switch, and native input remains available for dropping and pocket cycling.
- Cancel pending gestures across pause, transitions, lost control, death, continue and observed identity/controller changes. Preserve saved mode and existing balance. Offline input regressions pass; keyboard/controller and native-drop engine acceptance remain pending.

## Unreleased hurt-pose correction

- Fit all thirteen registered skins' shared hurt-pose cell to the measured vanilla envelope and ground anchor instead of filling a 64px storage cell. Correct Llama's truncated source crop without redrawing its art.
- Source hashes and surrounding atlas pixels are unchanged. The offline regression fails on the previous thirteen skins and passes exact rebuilt corrections. Hit and the four other transitions sharing this cell still need engine acceptance; no runtime installation or Workshop publication.

## Community-meme design and character reference review

- Replace the capability-based character draft with twenty-two meme-led proposals. Source strength and blocked-video limits are explicit; none of these replacement loops is implemented yet.
- Pin three public character/template repositories and inspect vanilla hurt-frame geometry. The oversized hurt-pose bug is still open; no third-party artwork was imported.

## Unreleased Summary Stapler candidate

- First of fifty additional collectibles: Summary Stapler, a four-charge treasure active. Absorbs at most twelve nearby ordinary hostile bullets and emits one native tear with a bounded multiplier. Preserves native tear effects and this mod's limits/forks; no weapon or costume replacement, empty-use charge loss, quota reset or Car Battery repeat.
- Original geometric stapler/paper icon using the existing item-icon generator; English description. Theme: summary-based compaction from [Claude context documentation](https://platform.claude.com/docs/en/build-with-claude/context-editing). Bilibili swarm leads and access limits, 22-form loops, nine darker tainted directions and all fifty item designs are recorded in `docs/EXPANSION_DESIGN.md`.
- Source implementation and offline tests only. No installation, engine acceptance or Workshop publication.

## Unreleased model roster candidate (2026-10-23)

- Owner-requested portrait overhaul: thirteen full illustrations for eleven normal families and both existing tainted characters, imported into menus, transitions and clear-room MAP dossiers.
- Nine new normal characters: GPT, Gemini, Grok, Qwen, Llama, Mistral, Doubao, Kimi, and GLM. Each has a distinct bounded gameplay loop; see `docs/MODEL_ROSTER.md` for exact values and source boundaries.
- Per-player saved progress, duplicate-room reward protection, current-run transient meters and extended Reactions Port Pack fallback support. Existing DeepSeek direct-connection behavior is preserved.
- Normal portraits adapted from credited ZipZipPipe illustrations; approved tainted designs subtly darkened. All thirteen gameplay sheets now match the selected portrait hair, costume and accessories. Separate art credits, source hashes and edit prompts are recorded. No video frames or official avatars are included. Animation polish and engine acceptance remain pending; no Workshop publication.

## v0.5-dev

Characters (owner request: normal + tainted for both; DeepSeek-chan is unrelated to IPs):

- **DeepSeek-chan redesigned.** She connects directly, so a DeepSeek-only run has no IP, no risk and no risk-based difficulty (`Risk:IsActive`). New gimmicks from her own memes: **Deep Think** (深度思考, "已深度思考（用时N秒）"), **Server busy** (服务器繁忙，请稍后再试), and the pocket active **Lunch Break** (飯食ってくる / 去吃饭了), recharged by **slacking off** (摸鱼: 5 s standing still in a cleared room; from the viral Bilibili video 《大肥鱼成精了！在摸鱼！》). The Server busy mechanic also matches DeepSeek's 2026-10-15 global outage. The Support Ticket stays a shop item.
- **Tainted Claude-chan** (周限额): per-floor tear quota instead of the usage meter; pocket Banked Reset refills it. From the weekly-limit posts on X.
- **Tainted DeepSeek-chan** (开源): every tear is forked into two weaker copies; busier servers.
- **Claude-chan: Account age** (账号满月): +0.2 damage per floor without suspension; reset on suspension ("Banned again" / 《又封了》). From the "喜报：Claude满月啦" posts and the Bilibili song 《又封了》.
- Tainted sprites, portraits and menu portraits are recolours of the normal art (`tools/make_tainted_art.py`); `content/gfx/characterportraitsalt.anm2` added.

Sprites:

- Fixed heads spilling over their 32px cells (clipped in game, leaking into neighbouring frames), Claude-chan's cut-off side-shooting head, and DeepSeek-chan's walking bodies (front-facing, arms-raised copies, so she slid sideways). `tools/fix_character_cells.py`.

Items (memes on X):

- **529 Overloaded:** you're left "coding manually" during an outage: you can shoot, at 50% damage (was: no shooting).
- **Vibe Coding:** "Make no mistakes": no hit on a floor waives the next API bill.

Bug fixes:

- Ban Hammer bans no longer let a Relay Slime split. Thinking Cleared only drains on a room's first visit. The Constitution no longer refuses self-inflicted damage (IV Bag, Razor Blade, blood donation).
- The runtime probe now runs on a Claude-chan run (DeepSeek-chan no longer carries the Support Ticket).

## v0.4-dev (2026-10-23)

- Queue simultaneous story captions and save unseen pending chapters, preventing room/floor callbacks from silently dropping dialogue. Add collision/continue regressions and an explicit manual engine probe. Positive-risk insufficient funds, Car Battery and queued-story JSON round-trip passed in Repentance+.

- Reviewed and merged PR #1 (collaboration checks) and PR #2 (RORICO444's 21 item/trinket icons).
- Added Support Ticket: six charges, three coins for risk -20, with failed-use and Car Battery guards.
- Added playable DeepSeek-chan with blue tears, a firing-interval/damage tradeoff, pocket Support Ticket and team-wide no-hit risk recovery.
- Added The Appeal Queue: four original saved captions in en/zh/ja. Early approvals preserve later chapters with approved-route dialogue.
- Added generated Claude/DeepSeek character atlases, portraits, names and menu assets. Runtime fixes preserve faces with Reactions Port Pack, map DeepSeek clothing correctly and fit repaired Claude rear-head/body cutouts into engine cells.
- Moved story captions above the Loadout prompt and away from the upper EID text.
- Seed Silent Update before each floor roll, including pre-start NEW_LEVEL; continue preserves its stored multiplier.
- Fixed Windows Python detection and UTF-8 handling. Checks cover deterministic sprites, character assets, animation bounds, pools and gameplay boundaries.

Validation: required offline checks and initial Repentance+ 1.9.7.17 runtime checks passed, including both custom skins, corrected Claude rear hair, actual ticket use/refusal, an approved-route chapter, subtitle placement and continued runs. Tests were muted and the game was closed normally. Full animation/costume coverage, ordinary Repentance, co-op and a full run remain open; see HANDOFF.md. Character-art permissions and Workshop publication remain separate release requirements.

## v0.3-dev (unreleased, not yet tested in game)

New items, each based on a Claude / AI meme:

- **Compact** (active): the "compacting ate my 5-hour limit" complaints.
- **You're Absolutely Right!** (passive, angel): sycophancy.
- **9.9 Yuan Relay** (passive, devil): cheap relays secretly swapping the model (掺水).
- **Ultrathink** (active, timed): think / megathink / ultrathink and the 31,999-token budget.
- **1M Context** (passive): context rot.
- **Silent Update** (passive): 降智, behaviour changes missing from the changelog.
- **--dangerously-skip-permissions** (passive, devil): no prompts, occasional `rm -rf`.
- **All Tests Passing** (active): reward hacking by deleting assertions.
- **Vibe Coding** (passive): "Claude Code is vibe-coded" and the $1,986 vibe-coding bill video.
- **Banked Reset** (active): Anthropic's save-it-for-later rate-limit reset.
- **Subagent Swarm** (passive, devil): the sessions that spawned excessive parallel subagents.
- **Cat-girl Mode** / **Brb, Getting Food** (pills): DeepSeek-chan memes.
- **Welcome Notice** (trinket): fan lore where DeepSeek-chan swaps Claude-chan's ban card; Ban Hammer recruits instead of bans.
- **Status Page** (trinket): the status page that said everything was fine during outages.
- **The Constitution** (passive, angel): the priority order in Claude's 2026-01-21 constitution.
- **Opus Mode** (passive, shop): "more expensive than gold"; damage for coins.
- **529 Overloaded** (trinket): the July–August 2026 outages.
- **Hardcoded Output** (trinket): special-casing the expected output.
- **Thinking Cleared** (trinket): the cache bug that wiped thinking every turn.

New enemy: **Relay Slime** (placeholder on vanilla Clotty): splits twice on death, appears from risk 30.

EID: descriptions for the pills and for Claude-chan herself (en / zh / ja); language codes checked against EID's source.

New: **Suspended** state at risk 90+ (damage ×0.75), and the **Appeal Form** trinket that resets risk to 50 instead.

New: **Agentic** transformation (any 3 of the 6 Claude Code items): flight, tears up, +0.5 damage.

HUD: risk, IP and usage text now follow the game language (English / 简体中文 / 日本語), falling back to English if no CJK font loads.

Changed: **Ban Hammer** now misbans: 20% of bans hit innocent developers, +3 risk each.

Also: in-game test checklist (`docs/TESTING.md`), goals (`docs/GOALS.md`).

## v0.2

- Playable **Claude-chan** (design by ZipZipPipe): Range +1.5, Shot Speed +0.2, Speed −0.1, pocket Ban Hammer, usage limit mechanic. Placeholder art.
- Art license split from code license; art spec for the pixel artist.

## v0.1

- Risk score and random proxy IP per floor, enemy HP scaling, hydra respawns.
- **Ban Hammer** (active) and **Residential IP** (passive).
- EID descriptions in English, Chinese and Japanese.
