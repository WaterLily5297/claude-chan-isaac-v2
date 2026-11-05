# Constitution state follows its owner

## Reproduced finding and correction

Follow-up to the open Constitution boundary in the [final-save review](HARDENING_SAVE_BARRIER_2026-10-30.md), based on v2 main `b972330`.

**F21:** Constitution treated a live owner moving slots as a replacement. A holder who had received the pickup reward and spent the shield gained another reward on the next effect update, and another eligible hit could be refused on the same floor. The supplied two-player probe records `AddSoulHearts` totals of 4 instead of 2 after a swap. Moving immediately before saving also wrote the consumed bits under the old slot. The previous lazy per-slot binding checked only the destination, without finding the owner's original record.

The module now observes the whole roster and atomically remaps its slot/body records. Known pointer/InitSeed identities identify the original slot before any destination is written. A genuinely replaced owner starts fresh; an observed departure removes that group from saved state. Wrapper/controller changes retain a continuous identity. Effect and damage callbacks observe before consuming a reward or shield, and a SaveSync hook observes before Risk encodes the final snapshot. Observation itself never grants a pickup or spends a shield.

The version-1 save shape is unchanged: ordinary owners use the slot key, and Lazarus bodies use `slot:bodyType`. The transient observer stores identity values outside the saved map. It rebuilds only when the map or observed roster changes; unchanged observations do not create new group tables or reconciliation closures. No whole-room entity scan is added. This is a source-path property, not a native performance benchmark.

## Existing body and reward rules

- Forgotten/Soul callbacks share the root's item state. Tainted Forgotten retains the existing OtherTwin fallback. Jacob and Esau remain separate root owners even when they expose one another as twins.
- Known Lazarus body identities locate their entire slot group, carrying hidden-body records with it. A visible known counterpart can locate a newly exposed body's group during a move. Replacing one body within a known group resets only that body's consumed bits.
- An initially hidden Lazarus body can still adopt the existing slot's saved/legacy record on its first Flip. This fallback is restricted to an unclaimed slot: an unknown join cannot inherit records whose known owner has moved elsewhere. Without any known body/counterpart, identity is unresolved; a compatible unclaimed slot retains the existing lazy adoption, otherwise the body starts fresh. Simultaneous first exposure and movement among such unclaimed slots can still adopt the destination's hidden record. Native evidence is required to identify that ambiguous sequence; this correction does not guarantee its ownership.
- Legacy shared consumed bits still seed both Lazarus bodies conservatively. Dead/ghost holders cannot consume effects, excluded damage does not spend a shield, removal/reacquisition does not renew an applied pickup, and a new floor rearms shields without granting hearts.

The existing pickup call is `AddSoulHearts(2)`, meaning one full soul heart under the [EntityPlayer API](https://wofsauge.github.io/IsaacDocs/rep/EntityPlayer.html#addsoulhearts). The item ledger's former wording "two soul hearts" is corrected; the reward amount is unchanged. Damage remains x0.9, speed -0.1 and refused-hit cooldown 60 frames.

## Offline evidence

The [full-entry suite](../tests/full_mod_constitution_owners_test.lua) runs six four-player rotation/Continue scenarios: ordinary and mixed mod-form rosters, each with update, direct-save and exit-save observations. All four combinations of applied/used bits are earned through supplied effect/damage/item-removal events. It checks repeated rotations and saves, correct detached Continue inventories and each owner's pending pickup/shield. A lifecycle case covers damage before the next update, wrapper/controller changes, removal/reacquisition, floor rearming, seed replacement, observed departure and later join. A save before the first effect update keeps the pickup unclaimed until Continue's effect update.

The [focused body suite](../tests/constitution_players_test.lua) retains its existing reward, shield, legacy, inactive-holder, self-damage and stat assertions. Added cases cover asymmetric Jacob/Esau moves; two Lazarus pairs with hidden-body group rotations and recreated Continue identities; first exposure plus movement with a known counterpart; replacement of one body; an unknown join at a claimed old slot; and normal/tainted Forgotten shared-state moves. These are supplied identities and API responses, not observed native Flip or co-op behavior.

Both current suites pass in isolated copies. Old production fails each of the full-entry update/direct/exit/lifecycle selectors and the extended body fixture. Eight intentional source faults fail the intended assertions: omitting the save hook, ignoring a known root, discarding hidden records, reusing a claimed source slot, ignoring a known counterpart, inheriting a replaced body's bits, ignoring a root seed change and retaining departed records. The fault copies remain private and are not additional shipped defects.

Run `texlua tests/full_mod_constitution_owners_test.lua .`, `texlua tests/constitution_players_test.lua .` and the complete `bash tools/check.sh`. The full gate discovers the new suite. The interaction inventory is refreshed after the source edit.

## Remaining acceptance and handoff

Native body/root identity, first-hidden-body ambiguity, Flip/revival/Clicker, player-list availability during exit, actual health-container restrictions, invulnerability/cancellation order, real Continue and inter-mod callbacks remain unaccepted. Counting calls does not prove the engine grants health to every special character. This item correction does not certify the character economies or close G1-G7/S1-S4, F10/F12 or E2-E6.

This record, TESTING, ITEM_COMPLETION F21, CHARACTER_COMPLETION and the prior save review provide the handoff. HANDOFF/CHANGELOG remain untouched because of PR #2's overlap; its icon/dossier evidence, draft #7 and RC1 remain gated. No game, runtime installation, private saves/settings or Workshop action occurred; the recorded installed `8fd6a8c` checkpoint is preserved. Continue the broader U3/U4/U5 and art requirements. This is the first substantive unit after the PR #23 hardening review.
