# O5: all-form pose review (2026-10-26)

Baseline `ffc52bf`; offline geometry review and mechanical packing correction only. Installed `f8b2b0b` is preserved. No game was launched. The owner's historical oversized-hurt-head report remains unclosed in the engine.

Later follow-up: [GLM profile/carry/fallen repair](GLM_PROFILE_POSES_2026-10-31.md) replaces the two GLM side/fallen findings offline. The tables below retain the original O5 observations; they are not the current GLM art status. The [GPT/Gemini body repair](GPT_GEMINI_PROFILE_POSES_2026-10-31.md) subsequently replaces their normal/legacy-tainted side and carry bodies, with a foreground face-clearance check. Their head views and all Hit/Death pixels are unchanged. The later [GLM carry-fit correction](GLM_CARRY_CLEARANCE_2026-10-31.md) adds face clearance while retaining its fallen pose. The [Grok/Qwen follow-up](GROK_QWEN_CARRY_PROFILES_2026-10-31.md) replaces their side-walking and four-direction carry bodies while preserving all head/Hit/Death pixels. Other carry bodies still need structural review. Native acceptance remains open.

## What was found and changed

The eight-frame Hit sequence already fits its measured 28x32 envelope on all 22 skins. Death alternates that corrected cell with three other cells still fitted to the old 58-pixel square. All 22 forms therefore had an offline size discontinuity. The two upright Death cells now fit 28x33 with visible bottom 57; the fallen cell fits 36x27 with visible bottom 59 in its actual crop. These are separate measured native envelopes, not a global 28x32 rule. Horizontal packing stays centered.

The fallen crop starts at (192,130), two rows below its storage cell: packing ends at local storage y=61. The upright crops start at (0,128) and (0,192). Llama's (0,192) source crop also stopped through the body; it now uses the same corrected source-row bounds as its existing hurt pose, retaining hands and feet. No pixels were drawn or source illustrations changed.

The thirteen original source atlases were rebuilt from their hash-verified references, preserving the four movement revisions and nine walk-cycle revisions. Nine tainted skins were regenerated from the corrected normal skins. Pixel comparison against the baseline confirms that only these three storage cells changed across all 22 sheets. Menu, portrait, dossier and all other skin pixels remain byte/pixel-identical as applicable.

## Per-form findings

Each size is visible width x height at alpha >= 128, before correction. Every listed form had all three oversized Death cells. After correction all four pose contracts pass, all sampled cells are nonempty, no sampled cell touches a crop edge, and left/right side samples are exact mirrors about the native pivot. Mirror equality does not prove anatomical symmetry or appealing art. Ten side-body keys exist per form; repeated stride poses yield six distinct images in the original four and five in the other eighteen, not missing keys.

| Form | Death start | Death recoil | Death fallen | Other visible/source limitation |
|---|---|---|---|---|
| Claude-chan | 58x52 | 58x56 | 58x39 | Dedicated side profile; full native motion remains unobserved. |
| DeepSeek-chan | 58x57 | 55x58 | 58x45 | Dedicated side profile; full native motion remains unobserved. |
| Tainted Claude-chan | 58x51 | 57x58 | 58x42 | Dedicated side profile; full native motion remains unobserved. |
| Tainted DeepSeek-chan | 58x57 | 55x58 | 58x44 | Dedicated side profile; full native motion remains unobserved. |
| GPT-chan | 58x57 | 58x57 | 58x48 | Side body remains a narrowed front, requiring later art review. |
| Tainted GPT-chan | 58x57 | 58x57 | 58x48 | Side body remains a narrowed front, requiring later art review. |
| Gemini-chan | 58x56 | 58x56 | 58x41 | Side body remains a narrowed front, requiring later art review. |
| Tainted Gemini-chan | 58x56 | 58x56 | 58x41 | Side body remains a narrowed front, requiring later art review. |
| Grok-chan | 58x52 | 58x51 | 58x39 | Side body remains a narrowed front, requiring later art review. |
| Tainted Grok-chan | 58x52 | 58x51 | 58x39 | Side body remains a narrowed front, requiring later art review. |
| Qwen-chan | 53x58 | 52x58 | 58x38 | Side body remains a narrowed front, requiring later art review. |
| Tainted Qwen-chan | 53x58 | 52x58 | 58x38 | Side body remains a narrowed front, requiring later art review. |
| Llama-chan | 58x47 | 58x56 | 58x43 | Death-start source crop repaired; narrowed-front side body remains. |
| Tainted Llama-chan | 58x47 | 58x56 | 58x43 | Death-start source crop repaired; narrowed-front side body remains. |
| Mistral-chan | 58x52 | 58x53 | 58x38 | Side body remains a narrowed front, requiring later art review. |
| Tainted Mistral-chan | 58x52 | 58x53 | 58x38 | Side body remains a narrowed front, requiring later art review. |
| Doubao-chan | 58x55 | 58x57 | 58x47 | Side body remains a narrowed front, requiring later art review. |
| Tainted Doubao-chan | 58x55 | 58x57 | 58x47 | Side body remains a narrowed front, requiring later art review. |
| Kimi-chan | 58x52 | 58x54 | 58x39 | Side body remains a narrowed front, requiring later art review. |
| Tainted Kimi-chan | 58x52 | 58x54 | 58x39 | Side body remains a narrowed front, requiring later art review. |
| GLM-chan | 56x58 | 58x56 | 58x38 | Fallen pose still reads seated; redraw is outside this mechanical fix. |
| Tainted GLM-chan | 56x58 | 58x56 | 58x38 | Fallen pose still reads seated; redraw is outside this mechanical fix. |

## Reproduce and inspect

`tools/preview_character_poses.py OUTPUT --animation-reference PLAYER_ANM2 --reference-skin ISAAC_PNG` reads a privately extracted base player animation and optionally measures its skin. It renders only this mod's pixels; it never copies native artwork into the output. It rejects unsupported root transforms and missing/frame-coverage errors. The output directory must be outside shipped resources/content. Pillow is required only for preview/repacking; the CI geometry check uses the standard library.

Outputs: `all-character-poses.png` contains 22 rows and 45 sampled poses per row (seven Hit keys, sixteen Death skin-layer keys, ten left-walk keys, ten right-walk keys and two firing-head samples). `selected-character-poses.png` is a compact overview. Each form also receives its own sheet. `pose-review.json` records input hashes, per-cell bounds, warnings, mirror results, current commit and working-tree changes. No private input paths are recorded.

Repacking uses `tools/pack_selected_sprites.py SOURCE --movement-source MOVEMENT_SOURCE`, which now retains the recorded walk-cycle pass automatically. Follow it with `tools/make_roster_tainted_art.py --skins-only` to preserve menu/portrait bytes. Both commands reproduced the candidate asset bytes exactly in the local check. Original source hashes and the art license remain unchanged.

`tools/check_pose_geometry.py` is part of `tools/check_assets.py` and the full gate. It failed on all 66 pre-fix Death cells and passes on the corrected sheets while retaining the existing Hit limits. Its RGBA8 decoder was compared byte-for-byte with Pillow for all 22 candidate sheets. The preview was also regenerated to check deterministic PNG output.

## Evidence limits and remaining engine cases

The renderer samples native keyframe positions, pivots, scale and rotation, with an idle side head or the explicitly labelled firing sample. It omits interpolation, tint flashes, native ghost sprites, overlays, items, shaders, camera and game input. Absence of edge contact does not prove that the generated anatomy is complete. The darker tainted palettes and narrowed-front side bodies are retained; bespoke side/tainted redesign needs owner art direction.

These storage cells are shared beyond Death. The (0,128) cell also appears in ForgottenDeath and LightTravel; (192,128) is shared by Appear and DeathTeleport. The (0,192) cell is referenced by Appear, FallIn, ForgottenDeath, Happy, HideItem, Jump, LeapDown, LiftItem, LightTravel, LostDeath, MinecartEnter, Pickup, Pickup_Online, Sad, SuperLeapDown, TeleportDown, TeleportUp, Trapdoor and UseItem. Those are source-reference findings, not engine results.

Later acceptance must observe damage and recovery, all Death stages and ghost, the shared animations above, both side directions with/without firing, size/flight changes, revival, item and weapon overlays, co-op and Reactions Port Pack. No native animation XML or extracted vanilla pixel is distributed; runtime files and game settings were not touched.
