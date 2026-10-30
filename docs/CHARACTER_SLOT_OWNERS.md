# Character state across observed player-slot moves

U3/U4/G3, 2026-10-30, based on v2 main `e7e3921`. Source and offline evidence only. Installed `8fd6a8c` remains unchanged.

## Defect and continuity rule

Twenty-one form implementations treated a different slot as a new owner even when the same live player pointer and InitSeed remained present. Moving four existing players cyclically reset their personal progress: for example, Tainted GPT's 28 Credits became the initial 80, normal Claude lost age 4 and Usage 52, and Grok's cooldown disappeared. Marks, tasks and other transient bindings were also recreated. Normal DeepSeek already retains this state under the earlier [Rice/Meal fix](O6_RICE_MEAL_IDENTITY.md).

**Owner delegated:** apply personal-state continuity to a continuously observed player, independently of slot position. The conservative reset expectations in the older normal-Claude, normal-GPT and tainted-Grok fixtures are superseded for this case. Their protection against an actual replacement remains. This is a correction to reassignment behavior, not evidence that a native Flip or revival preserves an entity.

Twenty binders now read a retained owner's old slot before rebuilding the saved slot map. The existing binding, including its clock, target reference, task list, cooldown or helper, remains attached to that owner. All reads complete before any old slot is overwritten; a cyclic move cannot steal or erase another owner's state. Migrations, fresh defaults and saved versions keep their existing rules.

Normal Claude uses a separate account observer. It stages accounts and paid volleys by pointer/seed, retains per-owner update/cache guards, and retires only identities actually absent or replaced. An unchanged roster takes the fast path without allocating the staging maps. Moving slots cannot erase debt, grant a fresh Appeal or bill a same-frame volley again.

The boundary stays explicit:

- A new pointer or InitSeed starts a fresh form record. An observed departure prunes the old record; a later join does not revive a parked character account.
- Changing away from a form still discards its state, except normal Claude's existing same-owner debt/allowance/age policy. Claude's separate Review module still cancels its task on type departure.
- Continue first clears live bindings and then attaches the loaded slot records to recreated players. No pointer, entity, binding or target reference is added to saves.
- Room/floor rules, costs, cooldown durations, Birthright policies, input cancellation and derived-shot billing remain unchanged. Reassignment keeps the current clocks; it does not extend them or refund attempts.

## Offline evidence

`tests/full_mod_form_slots_test.lua` loads actual `main.lua` for all 22 forms. Each form runs four-player duplicate and mixed-vanilla rotations, same-frame repeated observations, a paused move, wrapper/controller changes, and a final observed move before detached save/Continue. Separate cases cover shrinking the roster, joining, pointer-only and seed-only replacement, and observed type departure/return. Saved counters, choices, per-room ledgers and clocks are compared by the original owner. The fixture supplies valid distinct progress to make accidental resets or transfers visible.

`tests/full_mod_form_slot_abilities_test.lua` compares moved and stationary versions of 17 two-owner scenarios for 300 frames each. Positive controls confirm actual Appeal/Review, Rice, paid primary-beam damage, Sanity Check, Paint, Export, fact check, Ratio, adapter installation, Hype helper, Pounce, Baguette, Confident/Apology, presentation, task pulses and requests. The comparison checks scalar state, damage, shooting delay, helper shots, meal countdown and primary-beam hit results at every frame. Repeated moves include same-frame attacks, so a reset cannot hide behind eventual completion.

Baseline `e7e3921` fails the first rotation for all 21 changed forms; normal Rice already passes. A minimal copy of current production passes both suites. Seven isolated faults are rejected: reading the destination slot, writing before all owners are read, ignoring InitSeed, recreating a moved edit-chain binding, mixing Claude's accounts by destination slot, forgetting Claude's paid volley, and passing that volley to the other owner. The asymmetric attack control pays only owner 1 before a move, then checks their free sibling and owner 2's independent first payment. Existing Claude/GPT/Grok replacement tests retain their fresh-owner and departed-owner assertions while updating the continuously observed swap expectation.

The detached codec and supplied identities, APIs, input and callback order are test inputs. They are not an Isaac emulator, native JSON test or actual co-op session.

## Remaining acceptance and handoff

Follow-up on 2026-10-30: the [final-save review](HARDENING_SAVE_BARRIER_2026-10-30.md) adds an explicit pre-serialization observation and offline cases without an intervening update. It narrows the last-rebind gap below for all 22 form maps; native identity and exit-order acceptance remain open.

Native Jacob/Esau, Forgotten/Soul, Tainted Lazarus/Flip, revival and join/leave must establish their real pointer/seed/slot lifetimes before this rule can be applied to those events. A disappearing body is still an observed departure under this implementation; no unobserved or parked body is guessed to be the same player. The tests observe reassignment before saving and do not establish that native exit callbacks always allow a final rebind before Risk serializes. Real Continue, pending native weapons, cache/render order, other mods and both engine versions remain open.

This unit updates TESTING, CHARACTER_COMPLETION and the interaction inventory. HANDOFF/CHANGELOG consolidation remains deferred because open v2 PR #2 owns those files. Its icon/dossier evidence, RC1 and draft U0 PR #7 remain unresolved. No installation, game input, settings, saves, art, balance values or Workshop publication were changed.
