# Art specification and production guide

Updated 2026-10-30 against local v2 `main` at `9888186`. The roster has **11 families / 22 forms, 80 collectibles, 12 trinkets and five pill effects**. [ART_STATUS.md](ART_STATUS.md) inventories every bundled image/animation and the native presentations without custom files. That document is the art queue; this one defines how replacements are produced and checked.

The designed-icon registry, producer and validator are now implemented in source. The pipeline migration preserved all 92 PNGs. The [first](ITEM_ART_BATCH_01.md), [second](ITEM_ART_BATCH_02.md), [third](ITEM_ART_BATCH_03.md), [fourth](ITEM_ART_BATCH_04.md), [fifth](ITEM_ART_BATCH_05.md), [sixth](ITEM_ART_BATCH_06.md), [seventh](ITEM_ART_BATCH_07.md), [eighth](ITEM_ART_BATCH_08.md) and [ninth](ITEM_ART_BATCH_09.md) batches supply all 92 designed icons and 1x/4x before-after sheets; no placeholder icon remains. Native art acceptance remains pending.

## Identity, compatibility and rights

Keep the owner's selected ZipZipPipe AI-personification identities for all eleven normal forms. Preserve the retained tainted Claude and DeepSeek designs. The other nine tainted sets currently deepen the normal palette; a distinct identity requires a combined portrait/front/side/back/hurt preview and owner approval before replacement. Merely darkening a sheet does not finish that work.

Center the face and torso around native pivots while preserving intentional asymmetry such as ornaments, hair or held objects. A mechanically mirrored frame is not proof of appealing anatomy. Claude's selected identity retains orange-red hair, the sun/flower ornament, the cream/black/orange dress and book motif. Use the recorded selected portraits for the other families, not a fresh unofficial design substituted without review.

Follow [COSTUME_COMPATIBILITY.md](COSTUME_COMPATIBILITY.md): mod forms keep a fixed look, with item costume layers cleared but native item effects, weapon flags/colours, flight, size and transformations preserved. Keep this policy in the dedicated costume-lock service. Do not add a separate hair costume, replace a player's full sprite every frame, normalize player scale or change player type merely to display art. Native shield cues, giant states and departure restoration still require the O4 cases.

Code and original placeholder item drawing code/art use the project MIT terms. Character designs and their derivatives have separate credited, non-commercial conditions; DeepSeek retains the documented additional credits and CC BY-NC-SA terms. Read [ART_LICENSE.md](../resources/ART_LICENSE.md), [portrait records](portrait-prompts.json), [sprite records](sprite-prompts.json) and [tainted records](tainted-portrait-prompts.json). Do not infer a blanket licence from AI generation or a curator's catalogue. No fresh direct licence verification is claimed here.

Inspect native geometry privately when necessary, then draw original pixels in project-owned sources. Do not commit extracted native PNGs/ANM2, trace or draw over them for redistribution, import unlicensed mod art, use official company logos, or upload private reference collections. Original reference shapes drawn for contact sheets must be clearly labelled as project examples. Workshop remains unauthorized.

## Runtime file contracts

| Asset | Contract and consumer |
|---|---|
| Gameplay sheet | `resources/gfx/characters/costumes/character_<family>chan[_b].png`, 512x512 RGBA; `content/players.xml` selects the sheet. Keep the current native cell layout and animation pivots. |
| Stage/VS portrait | `resources/gfx/ui/stage/playerportrait_<family>chan[_b].png`, 144x144 RGBA. `portrait` and `bigportrait` deliberately reference the same file. There is no required separate big-portrait file. |
| Name strip | `resources/gfx/ui/boss/playername_<family>chan.png`, 128x32 RGBA; shared by normal and tainted forms. English text is permitted here. |
| Dossier | `resources/gfx/ui/dossiers/<family>[_b].png`, 384x576 RGBA, with a matching `.anm2` wrapper. Keep crop, sprite reference and HUD placement aligned. |
| Menu names | `content/gfx/ai_names.png`, 256x352; maintain all eleven family slots and matching wrapper bounds. |
| Menu portraits | `content/gfx/ai_portraits.png`, 704x64; `ai_portraits_b.png`, 704x128. Preserve the current cells and normal/tainted animation mappings. |
| Menu wrappers | `charactermenu.anm2`, `characterportraits.anm2`, `characterportraitsalt.anm2` under `content/gfx`; no out-of-bounds crops or unresolved sheets. |
| Collectible/trinket icon | `resources/gfx/items/{collectibles,trinkets}/<registered_gfx>.png`, exactly 32x32 RGBA8; retain the `items.xml` reference and pool identity. |
| Pills | Five effects use native random pill presentation. No custom per-effect PNG is required by current registration. |
| Relay Slime | Currently tinted/scaled native Clotty, with no bespoke sheet or animation. W1.6 must add explicit art/registration checks when a custom asset is implemented. |

## Resource path resolution audit

`tools/check_resource_paths.py` audits path-bearing references without changing assets. XML paths must be relative and case-exact. The [players.xml reference](https://wofsauge.github.io/IsaacDocs/rep/xml/players.html) shows `skin`, `portrait` and `nameimage` resolved through `root`, `portraitroot` and `nameimageroot`; the checker also audits the source's `bigportrait`/`bigportraitroot` pair as an offline candidate because that attribute is not described by the reference. `extraportrait` is documented as an ANM2 file, but no path base is documented, so the checker fails closed if one is added. The [entities2.xml reference](https://wofsauge.github.io/IsaacDocs/rep/xml/entities2.html) says `anm2path` is relative to `anm2root`; this mod has no `entities2.xml` entries today. The [costumes2.xml reference](https://wofsauge.github.io/IsaacDocs/rep/xml/costumes2.html) identifies `anm2path` as an ANM2 path but does not specify its base; the checker defers any future path until an explicit rule is verified. The [pocketitems.xml reference](https://wofsauge.github.io/IsaacDocs/rep/xml/pocketitems.html) defines a custom card's `hud` value as an animation name in `content/gfx/ui_cardfronts.anm2`, not a filesystem path. A custom card pickup may also need an `entities2.xml` entry.

The standalone [U0 resource path audit](RESOURCE_PATH_AUDIT_2026-10-30.md) records the checked references, offline results and unresolved native path conventions.

For collectibles and trinkets, the open [v2 PR #2](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/2) encodes the rule that the engine adds the `collectibles/` or `trinkets/` subfolder below the `items.xml` `gfxroot`; each `gfx` value is therefore a bare filename. Its offline regression test checks that interpretation, but the owner has not yet verified a pedestal or trinket in game. The standalone U0 checker defers `content/items.xml` while that PR owns it.

The project audit plan treats each ANM2 `<Spritesheet Path>` as relative to its wrapper file. The [published ANM2 reference](https://wofsauge.github.io/IsaacDocs/rep/xml/Anm2_files.html) instead describes the value as starting from `gfx/`; these rules disagree. The three menu wrappers under `content/gfx/` use adjacent-sheet filenames, and the offline checker currently validates that candidate resolution. Keep the dossier wrappers owned by v2 PR #2 deferred until its path convention is reconciled with engine evidence and the owner checks the images in game. Do not treat either convention as engine acceptance based only on file existence.

`Sprite:Load` and `ReplaceSpritesheet` paths are relative to the mod's `resources/` folder ([Sprite API](https://wofsauge.github.io/IsaacDocs/rep/Sprite.html)). `Font:Load` is a separate exception: its path is relative to the game's `resources/` folder, so the CJK font candidate is not a mod asset and its availability is unverified; the code falls back to English when it cannot load ([Font API](https://wofsauge.github.io/IsaacDocs/rep/Font.html)). `Isaac.GetItemConfig()` returns item configuration by ID; current Lua callers do not pass or resolve a filesystem path. `scripts/eid.lua` registers descriptions by ID and currently declares no custom icon sprite path. `content/entities2.xml` and `content/costumes2.xml` are absent today; their path rules are implemented for future entries.

## Player pose geometry

Use [POSE_REVIEW.md](POSE_REVIEW.md) and `tools/check_pose_geometry.py` as the measured packing contract. The earlier broad instruction to fit every complete pose into 28x32 must not override the distinct Death envelopes below.

| Pose | Visible alpha envelope | Ground anchor in the actual crop |
|---|---|---|
| Hit | At most 28x32 | Bottom 55 |
| Upright Death cells | At most 28x33 | Bottom 57 |
| Fallen Death | At most 36x27 | Bottom 59; crop begins at atlas (192,130), so storage-cell bottom is 61 |

The four contracts pass on all 22 sheets after O5. Do not scale those cells back to the old 58px square. Retain the Llama Death-start crop that includes hands and feet. Match geometry at the measured alpha threshold (128); inspect lower-alpha fringes and actual native rendering separately.

Eighteen sheets still use narrowed-front side bodies; both GLM forms have a seated-looking fallen pose. Proper profiles, anatomical cleanup and consistent walk/carry phases are unfinished. Preserve selected identity and alpha/pivot placement while correcting them. The original four have dedicated side profiles, but they also need native animation acceptance.

Preview all forms at 1x and enlarged nearest-neighbour scale. Include idle/shoot heads, front/back/side walking, carrying, Hit and all Death cells. Shared complete-pose cells also serve pickup, teleport, jump, trapdoor, appear and other special sequences: consult the full list in POSE_REVIEW rather than inferring their success from four envelopes. Offline crops do not model native interpolation, tint, ghost rendering, costume order, collision size or flight.

## Item-icon style

The target is readable beside native pickups at the game's scale, using original project pixels. An icon should identify the object and suggest its existing effect without needing its name. The following requirements apply to new designed icons; legacy placeholder differences are tracked until each icon migrates.

| Property | Designed-icon requirement |
|---|---|
| Canvas | Exactly 32x32, 8-bit RGBA PNG. Transparent background, nonempty visible silhouette, hard pixel edges; alpha only 0 or 255. No antialiasing or blurred resampling. |
| Silhouette | Aim for roughly 24-28px across, with transparent breathing room. Judge at 1x before adding detail; use recognizably different silhouettes for unrelated effects. Do not force every object to be mirror-symmetric. |
| Outline | Dark, usually one pixel around the visible object, with selective interior separation. Shared project ink `#080000` is the starting point. Avoid a doubled dark border after compositing. |
| Material ramps | Three or four shades per main material: shadow, base, light, optional highlight. Prefer two or three materials and at most 16 declared visible colours including ink/accent. Palette exceptions need a documented visual reason. |
| Lighting | Light from the top-left, shadow toward the bottom-right. Keep a coherent light source when an item has several parts. |
| Meaning | One primary object and, where needed, one restrained effect cue. A stapler can bind a bullet bundle; rice items should read as rice/cooker/bowl without text labels. Preserve distinctions among similar family items. |
| Text and branding | No letters, digits, readable UI screenshots, company emblems or logos inside icons. Item names remain in pickup/EID text. Symbol-like objects must work as silhouettes rather than typography. |
| Colour | Separate materials by value as well as hue. Do not use colour alone to distinguish two otherwise identical icons. Check against light and dark preview backgrounds. |
| Resampling | Author at 32x32; enlarge previews with nearest-neighbour only. Do not shrink a detailed portrait into an icon. |

Hardcoded Output now uses an original tear-die object instead of digits in batch 02. Remaining placeholders retain their legacy checks until individually migrated. Existing recognizable object icons may need refinement rather than replacement with an unrelated metaphor. New art does not authorize changing a registered name, effect, charge, quality or pool weight.

## Reproducible item pipeline

Use **deterministic drawing code**, extending the project's existing reproducible approach. Commit the drawing source and generated PNGs, not private generation sessions. [make_item_art.py](../tools/make_item_art.py) produces and validates icons against [item-art-manifest.json](item-art-manifest.json). Keep character production and its existing manifests separate.

Every entry records its exact registered name/gfx path, status, drawing function/version, author/provenance and applicable terms, palette and alpha contract, output SHA-256 and semantic description. Designed entries additionally require a contact-sheet path under docs/art. Track explicit `placeholder` versus `designed` status; never infer a designed icon merely because a file was manually overwritten. A `designed` entry is production status, not owner or engine acceptance.

The source gate dispatches by explicit status. Placeholders must still match the original producer, including its symmetry rules. Designed entries must match their drawing code and declared palette, use hard alpha, have a visible silhouette and a transparent outer pixel margin. More than sixteen declared colours requires a documented reason in the drawing definition. The registry must partition every registered icon; unknown/missing/duplicate paths, name/kind mismatches, unregistered files, stale metadata and invalid collectible-pool references fail. Other character/menu/pose gates are retained.

Commands (Python 3.9+, standard library):

```sh
python tools/make_item_art.py --check
python tools/make_item_art.py --write
python tools/make_item_art.py --write --out /path/to/review-export
python tests/test_item_art.py
```

Check is read-only. Write regenerates registered PNGs and metadata from code after validating every producer; it does not accept manual PNG edits by updating their hashes. Export leaves the repository manifest unchanged and cannot target the canonical icon directory. Bootstrap with --init-manifest is only for a missing registry and refuses to replace an existing one. Do not use bootstrap to reset production statuses.

The legacy make_placeholders.py default, including --out pointing back to the repository icons, now writes only registered placeholders. A separate temporary --out export still provides old artwork for before/after review. Its preview contains the placeholders produced by that invocation. Neither tool deploys to the game installation.

Art-batch workflow:

1. Add original drawing functions and Design definitions keyed by exact registered gfx paths to DESIGNS in make_item_art.py. Supply declared palette, version, meaning, author, original-pixel provenance and a review sheet. The pipeline is for original project MIT icon art; do not use it to relabel character derivatives or imported images.
2. Change only intended registry entries to designed, then regenerate with --write. Review code, output and metadata together. Untargeted PNGs must stay byte-identical; the explicit metadata does not replace visual review.
3. Run the contract regressions and full gate. Thirteen regression groups cover mixed status, malformed candidates, registration/pools, read-only validation and legacy overwrite protection. A valid original test shape passes the new contract but fails the old placeholder equality gate; the fixture is not shipped game art.
4. Migrate about ten icons in a focused main-based PR, supplying the before/after 1x/4x review package and updating ART_STATUS, terms as needed, HANDOFF, TESTING and CHANGELOG. The tooling unit kept all 92 PNGs unchanged; the first subsequent art batch migrates ten. Keep tooling and artwork evidence distinct.
5. After the required full gate, final-head CI and review, merge under the standing source policy. Runtime installation is a separate authorized, backed-up action; an icon PR must not overwrite the owner's manual-test installation.

## Local item preview export (2026-10-27)

`make_thumb.py` now reads the registered Ban Hammer icon through the current item-art producer and manifest. It checks the selected metadata and PNG against the deterministic source, then exports an opaque 512x512 preview on the existing dark background at integer 16x scale. It follows explicit placeholder/designed status rather than the removed legacy ART/PALETTES API.

```sh
python tools/make_thumb.py --out work/previews/ban-hammer.png
python tools/make_thumb.py --out work/previews/ban-hammer.png --check
```

An output path is required. Importing the module or omitting `--out` does not generate a preview. `--check` compares without creating or repairing files, and fails on a missing/stale output. Stale source metadata or icon bytes fail before output replacement. PNG destinations inside resolved `resources`, `content` or `docs/art` directories are rejected so this utility cannot replace game art or existing review sheets. An explicitly selected root `thumb.png` destination is possible for a future reviewed replacement, but was not used during this repair.

Six regression groups cover current designed pixels/scale/determinism, CLI export/read-only checks, inert preview behavior, stale input rejection, protected destinations and explicit placeholder status. A temporary output was visually inspected. The tracked `thumb.png` remains the historical placeholder; the new item preview is neither an exact reproduction of that old file nor a final cover. No image or animation is changed by the tooling repair, and no Workshop upload is implemented or authorized. The exported Ban Hammer image retains its original project MIT terms.

## Review package and acceptance

Every icon batch supplies a labelled contact sheet at actual 1x and nearest-neighbour 4x, on light and dark backgrounds, beside a few **original project-drawn reference shapes**. Labels belong outside the icon. List each icon's current effect/meme, intended visual cue, provenance and changed files. Include before/after comparisons and the deterministic output check. Do not use extracted game icons in the public comparison sheet.

Review silhouette and material separation at 1x, outline thickness, light direction, unintended text/logos, repeated motifs, transparent margins and distinction from neighbouring items. Confirm that non-target files stayed unchanged. Character corrections additionally show front/side/back/hurt/death samples and preserve the selected face, hair and costume identity.

The offline gate covers file contracts, deterministic production and relevant regressions. Native acceptance separately covers menu starts, room pickup presentation, pedestals/EID, light/dark rooms, size/flight/weapon combinations, hit/death/special animations and co-op HUD placement. Record exact build and game version for observed cases. The owner's oversized-hurt-head report remains open in the engine until those cases are observed.

Generic placeholder item replacements and geometric repairs can proceed without a new approval round. Replacing an owner-approved look or any character identity requires a concrete preview and approval. No gameplay/balance or Workshop approval is implied by this style guide.
