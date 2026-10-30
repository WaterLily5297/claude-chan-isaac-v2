# O6: Rice and shared meals across player-slot moves

U4/F18, 2026-10-30, based on v2 main `941b4af`. Source and offline evidence only. Installed `8fd6a8c` remains unchanged and owner-untried.

## Reproduced defect and correction

Both the shared MealBreak service and normal DeepSeek's Rice economy previously treated a change of player slot as a replacement entity. Reordering the same live players erased their remaining meal lockouts and reset Rice/Thought progress. This could remove a food item's shooting restriction before its countdown completed. The `meal_move` and `rice_move` scenarios independently fail against baseline `941b4af`.

The binders now find a continuously observed owner by its existing pointer and InitSeed, read the previous slot's state, and rebuild the saved slot map only after every owner has been read. This handles cyclic moves without overwriting another player's record. The same transient binding retains its update guard, meal delay lease, resolved volley and Thought window clock. No additional per-pass map or entity scan is introduced; the existing next-bindings map also stages the final saved mapping.

An actual new pointer or seed still starts fresh. An observed departure removes the record; this change does not park missing players for later joins. Changing away from normal DeepSeek still discards Rice rewards, while the shared food countdown continues under its existing rule. Continue clears live identities before binding the loaded slot map to recreated players. Save version 2, all durations, rewards and callback registrations remain unchanged. Pointer/seed ownership and weapon leases remain transient, never serialized.

This implements the personal-state and food-lockout contracts under the owner's U4 co-op reassignment requirement. It does not extend this rule to other character binders or decide their separate type-return policies.

## Offline evidence

Run `texlua tests/deepseek_o6_save_test.lua .`. An optional second argument selects a named scenario. The fixture initializes the real Risk, MealBreak and Rice/Thought services in their relative entry-point order. Its eight scenarios cover:

1. Independent shared meals and shooting restrictions after a three-player slot rotation, including a vanilla control.
2. Rice, Thought, clear awards and update deduplication following the same owners.
3. Repeated cyclic moves, reordered saved slots, process-style reload with new player identities, and one completion reward while a partner's separate food timer continues.
4. Movement cancellation after reassignment, exactly one bowl refund, and preservation of an unrelated longer FireDelay.
5. Another Lua wrapper, controller reassignment, type departure/return, leave/join, pointer-only and seed-only replacement, and same-session Continue.
6. A four-player move while paused: a paid continuous window and another player's meal keep their remaining budgets and expire on the original clocks.
7. Exit during supplied knife flight: tracked factors are removed at exit, spent Thought is saved without refund, and a recreated attack cannot manufacture the former transient multiplier. A same-frame sibling retains its resolved volley across a slot move before exit.
8. Version-1 Rice and shared-meal migration, missing partner records, unsupported versions and fresh-run reset. Legacy timers gain no invented Rice ownership token.

The serializer is a detached snapshot stand-in that rejects functions, metatables, cyclic tables, non-finite values and runtime owner/entity keys in the exercised state. It does not execute Isaac's JSON codec or write a real save. Native APIs, entity lifetimes, input polls, callback order and weapon flags are supplied. Existing Rice, MealBreak and native-Thought fixtures remain active.

All eight scenarios, the existing focused composition/weapon suites, the full `bash tools/check.sh`, interaction-inventory freshness and whitespace checks passed on 2026-10-30 using Git Bash, Python and `texlua`.

## Native acceptance and remaining O6 work

Follow-up on 2026-10-30: the [final-save review](HARDENING_SAVE_BARRIER_2026-10-30.md) now observes MealBreak and Rice ownership before encoding, including an earned four-owner meal/Continue case with no intervening update. This closes that supplied-event gap, not native save/cleanup acceptance.

No native save, input, co-op or weapon case is accepted here. In a future authorized session, inspect actual slot identities across co-op join/leave and revival, confirm meal locks and a single refund/reward, then save and fully restart with different players' counters. Test both engine versions. Recreated knife state, actual save/cleanup order, callbacks before the next binding observation and special twin/subplayer identities remain unverified. In particular, the fixture observes a slot change before saving; it does not establish a native guarantee that rebinding always precedes save serialization.

The current source deliberately does not persist a knife entity or its discrete multiplier; this fixture records that boundary, not a new promise to resume the original in-flight attack. Other forms, backlog state composition, Seahorse wisps, broader migration, whole-mod performance and error isolation remain open. No child-laser/Parent billing changes are included; native E2 still gates those changes.

## Handoff

TESTING, character/item ledgers, the Thought contract and interaction inventory record this unit. It avoids all files changed by open PR #2; consolidated HANDOFF/CHANGELOG updates remain deferred until that restriction clears. PR #2's icon/dossier evidence and draft U0 PR #7 remain unresolved. No game, installation, settings, saves, art or Workshop publication was changed.
