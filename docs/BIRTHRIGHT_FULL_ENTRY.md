# Birthright timing through the full mod entry point

U5/G4, 2026-10-30, based on v2 main `9e200eb`. Source review and offline evidence only. No gameplay implementation, values, save shapes or art changed. Installed `8fd6a8c` remains untouched and unaccepted.

The earlier [four-form timing review](BIRTHRIGHT_TIMING.md) established that Birthright intentionally samples inventory at different events. This unit preserves those policies and adds [one full-entry suite](../tests/full_mod_birthright_timing_test.lua) with all 22 forms. Each case loads actual `main.lua` and two copies of the form with opposite inventories. Changes during pending work, loss/reacquisition, repeated same-frame observations and positive outcomes expose stale sampling, duplicate rewards and ownership mistakes.

## Current policies and tested boundaries

| Form | Sampling event | Full-entry assertions |
|---|---|---|
| Claude N | Newly observed suspension; one saved shield per floor | Gain cannot rescue already lost age; loss cannot undo an already handled suspension; reacquisition cannot renew the spent shield. Two owners keep separate age/shield records despite shared Risk. |
| Claude T | Review completion | Opposite inventory changes during the six-second Review preserve its Page cost and deadline. Completion restores 90 or 60 according to current inventory, once. |
| DeepSeek N | Meal start | Purchased 30/60-frame meals retain their exact deadlines through inventory changes. The next meal uses the new duration; no bowl refund or second charge occurs. |
| DeepSeek T | Each resource update and future recovery | Losing Birthright clamps total Compute including the four reserved units. Reacquisition grants nothing immediately; the phase releases only its existing reservation, then recovery respects 32/24 caps. |
| GPT N | Pending check resolution | One hit remains pending through gain/loss. Two hits complete an enhanced check; acquiring Birthright can complete already earned two-hit progress. Losing it never revokes completed verification. |
| GPT T | Live cap and reset claim | Credit cap loss is irreversible; reacquisition alone does not refill. A banked safe-room reset claims the current 100/80 cap once. |
| Gemini N | Each dry-mark hit | The same active mark alternates 1.2x/1.3x with its owner's inventory through repeated changes, without another Paint payment. |
| Gemini T | Chain start | A paid step remains pending through changes. Original 180/300-frame deadlines expire exactly; expiry is not Export. A later chain uses current inventory. |
| Grok N | Verification | Both checks actually complete; only the currently enhanced owner clears its nearest three bullets. Later acquisition cannot replay the reward. |
| Grok T | Early target loss | Four replies reach the existing three-stack cap. Only the eligible owner's quote transfers one stack, preserving its original deadline; later acquisition cannot revive the cancelled partner quote. |
| Qwen N | Live stock cap | Loss clamps stock without restoring it on reacquisition. A paid installation retains its 30-frame deadline and Power bonus while inventories change. |
| Qwen T | Each damage cache evaluation | Three earned awards use the current 0.2/0.3 coefficient. Repeated cache resets do not compound damage or erase awards. |
| Llama N | Release activation | An inventory change during the supplied press/release changes only the owner's extra flies. Shared recipients still receive their normal flies; later inventory changes cannot replay a spent Release. |
| Llama T | Helper deployment | Purchased 120/150-frame helpers keep their final shot and expiry. Hype is not refunded; the next deployment uses current inventory. Actual helper callbacks and emitted tears are loaded. |
| Mistral N | Ready Pounce activation | Gain/loss during charge does not erase readiness. Only the inventory at activation grants the 100-unit target hit; later acquisition cannot replay the swipe. |
| Mistral T | Each eligible baking update | Gain at frame 40 completes at 45; loss at 40 requires 60. Reacquisition uses retained progress once, without early bread from duplicate observations. |
| Doubao N | Qualifying enemy hit | Existing tokens retain the initial 180-frame or room-bound lifetime. Room exit cancels both; the next qualifying hit samples current inventory. |
| Doubao T | Transition into Apology | Inventory just before the transition selects 90/120 frames. Later changes do not resize that recovery; the next enemy-hit transition samples inventory again. |
| Kimi N | Presentation activation | An active presentation keeps its original payment and speaker bonus. Replacing it pays the current cost; loss can make the next use unaffordable, and reacquisition grants no Slides. |
| Kimi T | Each scheduled pulse | All three pulses use each owner's current 0.6/0.7 coefficient at the original deadlines. Changes cannot add a fourth pulse or restore spent room budget. |
| GLM N | Access Pass redemption | Existing two/three-room passes retain their purchased budgets and active-room bonus through changes. The next redemption uses current inventory. |
| GLM T | Early request failure | Each owner earns one Retry; only the currently enhanced failure removes its nearest bullet. Later acquisition cannot replay either reward. |

## Evidence strength and limits

The unchanged implementation passes all 22 cases. Six isolated faulty production copies fail the intended assertions: renewing Claude's spent shield after loss; sampling Appeal inventory at Review start; resizing an active Edit chain; caching Fine-tune's first coefficient; granting Release flies from another player's inventory; and revoking an already earned room-bound Apology lifetime. The unmodified minimal-copy control also passes. These faults validate the regression assertions; they are not claims that these six bugs existed in current main.

The fixture supplies inventory booleans, native cache inputs, player identities, enemy/projectile stand-ins, DROP events and callback ordering. It invokes actual mod logic and checks resulting resources, damage, emitted flies/tears, bullet removal, deadlines and HUD state. It does not execute native pickup/reroll code, damage physics, JSON, rendering or special-body identity. HUD assertions check text state, not layout or screenshots. Counter setup represents valid earned progress; it does not certify every route that earns those counters.

All 22 forms now have a named full-entry timing case, but this does not close G4's native matrix or G1-G7/S1-S4. Actual Birthright pickup and removal, rerolls, native cache scheduling, special-player transformations, save/Continue at these boundaries and both game versions remain unaccepted. Selected event timings are not every possible frame/weapon/item combination. Preserve the existing per-form policy unless a demonstrated defect or an authorized design change requires otherwise.

The focused handoff is this record plus TESTING and CHARACTER_COMPLETION. HANDOFF/CHANGELOG consolidation remains deferred while open v2 PR #2 owns those files. No engine, input, installation, save/settings or Workshop operation was performed.
