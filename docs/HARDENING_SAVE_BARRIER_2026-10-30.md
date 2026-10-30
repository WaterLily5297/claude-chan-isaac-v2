# Final ownership observation before saving

## Scheduled review and reproduced defects

This U4 review follows v2 PRs [#20](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/20), [#21](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/21) and [#22](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/22), against main `cdd0a98`. The previous [save composition review](HARDENING_SAVE_COMPOSITION_2026-10-30.md) and [character ownership correction](CHARACTER_SLOT_OWNERS.md) explicitly left the interval between a final roster change and serialization open.

**F20:** Risk saved the existing slot maps without observing a final roster change. Two tainted GPT owners with 28 and 7 Credits, swapped immediately before exit without another update, saved 28 for the owner who had earned 7 and vice versa. The new test rejects the old production files for every form, including normal Rice. Existing observed-move tests were insufficient: they ran the ownership update before saving.

A related shared-map defect appears when two independent includes of MemeState observe the same rotation: their separate observers remap the same table twice. The new supplied-include case fails on the old MemeState at the second observer. Sharing the observer by Risk instance removes that replay. The fixture uses separate Lua evaluations for includes; it does not establish native include caching or claim this sequence was observed in the game.

## Source correction

- [SaveSync](../scripts/save_sync.lua) stores named reconciliation hooks on the transient Risk service, outside `Risk.state`. Registering a name again replaces its callback without adding another entry. Synchronizers use the modules' existing bind/observe logic, not their gameplay update handlers.
- Risk runs the hooks before encoding a live save. All 22 character maps, MealBreak, backlog players, meme players, Opus tear counts and Vibe mistake flags participate. Valid state follows existing ownership policies; actual replacement/type-departure policies remain intact, including normal Claude's same-owner debt exception.
- The exit save runs at EARLY priority, before this mod's ordinary cleanup clears live bindings. The floor checkpoint runs at LATE priority, after this mod's normal POST_UPDATE handlers settle caps and ownership. The checkpoint flag clears only after a successful save. A non-saving exit ends the session without writing; duplicate exit callbacks do not serialize cleaned-up state.
- A failed synchronizer propagates its error before encoding or writing. This preserves the previous stored snapshot and leaves a pending floor checkpoint eligible for a later retry. It is not rollback of in-memory changes, suppression of the error or general module failure isolation.
- MemeState holds one transient ownership observer per Risk instance. Its hook is registered once on first access; normal state reads do not allocate a new hook closure. A different saved map resets the observer through its existing map-identity check.

No balance values, rewards, save versions, weapon payment policy or transient attack persistence rules change. The [priority API](https://wofsauge.github.io/IsaacDocs/rep/ModReference.html) and [priority enum](https://wofsauge.github.io/IsaacDocs/rep/enums/CallbackPriority.html) describe relative callback ordering. The [exit callback contract](https://wofsauge.github.io/IsaacDocs/rep/enums/ModCallbacks.html#mc_pre_game_exit) documents ShouldSave and possible duplicate calls. Those contracts do not prove native player lifetime or another mod's ordering.

## Offline evidence

The [full-entry regression](../tests/full_mod_save_barrier_test.lua) loads actual main.lua and production modules:

| Case | Assertion |
|---|---|
| All 22 forms | Four duplicate owners and mixed form/vanilla owners, direct save and exit save: 88 rotation/Continue scenarios. Slot rotation occurs without an intervening update; mixed cases are paused. Direct saves include a second rotation and an unchanged repeated save. Complete selected form maps follow the original owners. |
| Replacement/type boundaries | Each form has an additional two-owner case: changing one InitSeed immediately before saving starts fresh without disturbing the partner. A later type departure removes former-form progress, with the existing normal-Claude debt exception. |
| Item/meal composition | Four owners earn different backlog selections, meme choices, Opus counts and Vibe flags. Normal Rice meals and item-owned Cooker meals start at different times, rotate immediately before exit, then Continue with recreated identities and retained inventories. Only the proper owners receive the completion rewards. |
| Shared meme observer | Two distinct service includes read both owners before and after a swap. Neither the second observer nor a repeated save reverses the mapping. |
| Floor checkpoint | A slot change and Birthright loss occur before the next update. The snapshot has the correct owners and settled 80-Credit cap; the next update does not write again. |
| Exit lifecycle | Saving and non-saving exits are each followed by cleared live state and a duplicate saving-exit callback. The first exit's stored result remains unchanged. |
| Failure and recovery | A named hook throws: no encoding or writing occurs. A floor checkpoint remains pending; replacing the hook permits exactly one later write and clears that checkpoint. |

All form states in the rotation matrix are deliberately supplied valid scalar records. This validates ownership and serialization boundaries, not that every form earns every field through native play. Normal Doubao's replacement record includes a distinct valid prior-room marker; comparing a default aim against itself would not test replacement. The item/meal case separately drives actual use/fire/damage/DROP callbacks.

The isolated unchanged-source control passes the complete suite. Old production fails all 22 direct-save form selectors and the separate meme-import case. Eight syntax-valid faults fail the intended assertions: encoding before reconciliation, omitting the GPT hook, saving after exit cleanup, checkpointing before cap settlement, omitting the meal hook, swallowing synchronizer errors, clearing the pending checkpoint before a failed save, and reinstating private meme observers. These private copies are test controls, not eight additional shipped defects.

Run `texlua tests/full_mod_save_barrier_test.lua .` and `bash tools/check.sh`. The full gate discovers the new suite automatically. Existing save, ownership, item, cache and weapon suites remain required. The fixture adds the EARLY priority; its supplied callback order and detached plain-table codec are not an engine simulation or native JSON test.

## Remaining boundaries and next work

Follow-up on 2026-10-30: the [Constitution ownership correction](CONSTITUTION_OWNER_CONTINUITY.md) reproduces the concern below and adds its save hook with slot/body-group regressions. The paragraph below describes this earlier review's scope; native special-body and save-order acceptance remain open.

Constitution's saved state uses a separate lazy slot/body-key policy, including Forgotten and Lazarus handling. It is not registered with this barrier. Its behavior on an ordinary same-owner slot move needs a separate reproduction and focused review; this unit does not claim that all saved maps or special bodies are covered.

Native save/exit/Continue, player-list availability during exit, special bodies and revival, external callback priorities, native inventory restoration, older-version migration beyond existing fixtures, disk errors and broader error/performance isolation remain open. Saving after another mod has already destroyed identities cannot reconstruct them. No new child-laser/Parent/derived billing rule is authorized by this result; E2 still gates that work.

This record, TESTING, ITEM_COMPLETION F20, CHARACTER_COMPLETION and INTERACTIONS provide the handoff. HANDOFF/CHANGELOG consolidation remains deferred because of open PR #2's overlapping files. PR #2's icon/dossier evidence, draft #7 and RC1 retain their gates. Installed `8fd6a8c` remains owner-untried and unchanged; no game, runtime installation, saves, settings or Workshop action occurred. Continue the remaining U3/U4/U5 requirements and schedule the next hardening review after three to five substantive units or a concrete failure.
