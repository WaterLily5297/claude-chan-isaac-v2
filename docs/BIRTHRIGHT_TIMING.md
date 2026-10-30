# Birthright changes during pending abilities

Source checkpoint `9076bc0`, reviewed 2026-10-27. This focused G4 record covers four tainted forms whose pending effects sample Birthright at different times. It preserves their current source behavior; it does not impose one policy across all characters or add balance/persistence rules. The original suites passed; the added boundary cases also pass without production changes.

The later [full-entry timing matrix](BIRTHRIGHT_FULL_ENTRY.md) loads all 22 forms in duplicate pairs and extends selected gain/loss/reacquisition boundaries. The counts and scope below remain the historical four-form record; neither review establishes native pickup, reroll or cache ordering.

## Observed source contracts and offline evidence

| Form / source | When Birthright is read | New real-module boundary cases |
|---|---|---|
| [Gemini T](../scripts/characters/gemini_edit.lua) | At chain creation: six seconds normally, ten with Birthright. The active chain retains that duration. | [Fixture](../tests/gemini_edit_test.lua): normal/enhanced starts, repeated gain/loss/reacquisition after a paid step, exact final-frame expiry and duplicate updates. Progress stays intact; expiry does not export or spend the partner's room. A later chain uses the current inventory. |
| [Llama T](../scripts/characters/llama_hype.lua) | At helper deployment: four seconds per spent Hype normally, five with Birthright. The bought lifetime remains fixed. | [Fixture](../tests/llama_hype_test.lua): both initial states, repeated inventory changes, exact final-frame expiry and duplicate updates. Hype is neither refunded nor taken from the partner; a new deployment reads the current inventory. The injected tear service is a stub, so this adds no helper billing or native weapon evidence. |
| [Mistral T](../scripts/characters/mistral_baguette.lua) | Every eligible baking update: 60 frames normally, 45 with Birthright. Accumulated progress is retained when the threshold changes. | [Fixture](../tests/mistral_baguette_test.lua): gain at frame 40 completes at 45; loss at 40 completes at 60; loss/reacquisition during the same bake retains progress. Duplicate updates cannot grant early bread, and the partner retains its own threshold. |
| [Kimi T](../scripts/characters/kimi_manager.lua) | At each scheduled pulse: 0.6x current damage normally, 0.7x with Birthright. The pending task does not store the multiplier. | [Fixture](../tests/kimi_manager_test.lua): two owners start with opposite inventories, then gain/lose/reacquire between pulses. All six resulting pulse amounts use the respective owner's current inventory. The original deadlines, three-pulse limit and each owner's spent budget remain unchanged. |

These are eight added scenario groups: two Gemini starts, two Llama starts, three Mistral threshold transitions and one simultaneous two-owner Kimi sequence. They supply inventory booleans and callback inputs to the real modules. They do not execute actual Birthright pickup, reroll, cache scheduling, native damage cancellation, special-player transformations or controller input.

## Coverage-strength check

Four isolated private source copies intentionally change the sampling policy: Gemini/Llama adjust an already running duration when inventory changes; Mistral captures the bake threshold at its start; Kimi captures the multiplier when assigning the task. Each old suite passes its corresponding faulty copy, while each extended suite rejects it at the new timing assertion. The production sources are never replaced by these copies. This comparison demonstrates a specific previous coverage gap, not a previously confirmed gameplay defect.

All prior assertions remain. The full gate still contains 70 Lua suites, 11 Python scanner cases, 13 item-art groups and six thumbnail groups. All gameplay source, art, XML, saved shapes and numeric values are unchanged. The scope does not include other forms' timing policies, child-laser/Parent/derived-shot billing or the unresolved F12 charged-use observation.

## Native acceptance still required

When an engine block is authorized, record the exact build, form, equipment and inventory-change mechanism. Gain and remove Birthright while each listed effect is pending, then reacquire it. Check visible deadlines, actual emitted damage, resource/budget preservation and the next activation. Test actual rerolls and relevant special-player/revival routes separately; a boolean toggle is not evidence of their native identity or callback order.

Continue handling remains exactly as documented in [CHARACTER_COMPLETION.md](CHARACTER_COMPLETION.md): these four live effects/progress are transient where stated. This unit introduces no persistence or refunds. All 22 broad form rows and G4's complete native matrix remain open. Installed `8fd6a8c` remains owner-untried and preserved; no runtime, game, settings or saves are accessed.
