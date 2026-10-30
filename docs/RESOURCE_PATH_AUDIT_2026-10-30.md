# Resource Path Audit — 2026-10-30

## Status

Offline source audit only. This record does not establish that the game engine accepts a path convention. During publication preparation on 2026-10-30, fetching remote `main` succeeded and confirmed `9888186e649dcd9cbb8eb713572ff7702022f015`, matching the local base. The latest [v2 PR #2](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/2) metadata, changed-file list and discussion were inspected: it remains open and unmerged at head `c6f8bf6b746456474454540bb90e5dab59521dbf`. This supersedes the earlier failed DNS attempt. No runtime files or game state were touched.

The checker is not yet wired into `tools/check.sh`: that gate is part of open v2 PR #2, whose item-art and dossier changes are still awaiting owner testing. Do not edit PR #2 files or merge it as part of this audit.

## Scope and results

| Reference | Offline result | Evidence limit |
|---|---:|---|
| `players.xml` skin, portrait, big portrait and name image references | 88 files resolve with exact case | Existence under configured resource roots only. The [published reference](https://wofsauge.github.io/IsaacDocs/rep/xml/players.html) documents `root`, `portraitroot` and `nameimageroot`; `bigportraitroot` is a source-level candidate. `extraportrait` has no documented path base and fails closed. |
| `entities2.xml` `anm2path` entries | 0 entries; file absent | The [published reference](https://wofsauge.github.io/IsaacDocs/rep/xml/entities2.html) says paths are relative to `anm2root`; the checker requires that root if entries appear. |
| `costumes2.xml` `anm2path` entries | 0 entries; file absent | The [published reference](https://wofsauge.github.io/IsaacDocs/rep/xml/costumes2.html) does not specify a path base. The checker fails closed if an entry is added. |
| `pocketitems.xml` custom-card HUD links | 0 custom cards; current file registers pill effects | The checker verifies a future card HUD animation against `content/gfx/ui_cardfronts.anm2`. |
| Non-deferred ANM2 spritesheets | 3 menu sheets resolve beside their wrappers | The project plan and published ANM2 reference describe different bases; this candidate resolution is not engine acceptance. |
| Dossier ANM2 wrappers | 22 wrappers deferred | They belong to PR #2. The checker still verifies the 22 dynamic dossier target filenames from the manifest, but does not accept their internal sheet paths. |
| Literal `Sprite:Load` / `ReplaceSpritesheet` calls | 0 | Dynamic resource paths fail unless explicitly audited. The dossier loader is checked against its manifest. |
| `Isaac.GetItemConfig` calls | 3 calls have no path argument | This API returns item configuration by ID; these call sites do not load files. |
| Custom EID icon registrations | 0 | Any future custom icon registration must first receive an explicit path rule. |
| Game-resource font candidates | 1 candidate | Syntax and expected font location only; installed font availability remains unverified. |
| `items.xml` collectible and trinket icons | Deferred to PR #2 | Its path rule is covered by PR #2's own offline test, while pedestal/trinket appearance remains untested. |

The checker rejects missing or case-mismatched files, absolute paths, traversal and non-canonical path components. Resource paths are checked beneath the repository root, including symlink resolution. It scans `main.lua` and `scripts/**/*.lua`, masking comments and string contents before finding calls across lines. Literal resource arguments must end at an argument delimiter, so concatenated paths require an explicit rule. Nested layer expressions are handled when locating a `ReplaceSpritesheet` path. This lexical scan is not a complete Lua parser. For a custom card, the [published pocketitems.xml reference](https://wofsauge.github.io/IsaacDocs/rep/xml/pocketitems.html) defines `hud` as an animation name and documents when an `entities2.xml` pickup entry is required.

## Reproduction

Run from the repository root:

```sh
python tests/test_resource_paths.py
python tools/check_resource_paths.py --skip-prefix resources/gfx/ui/dossiers
bash tools/check.sh
git diff --check
```

All four commands were rerun during publication preparation on 2026-10-30 and passed. The focused suite ran 17 tests, including four additional cases for multiline calls, concatenated paths, comment/string masking and nested layer expressions. The source audit reported 88 player references, 3 menu spritesheets, 22 dynamic dossier targets and the counts above. The existing `bash tools/check.sh` does not yet invoke this new checker; that gate result therefore covers only the repository's previously wired checks. On Windows, the gate used the existing Git Bash and `texlua`; the default WSL Bash launcher had no installed distribution.

## Remaining work

1. Resolve the ANM2 spritesheet base rule with authoritative engine evidence. The project plan treats paths as wrapper-relative, while the [published ANM2 reference](https://wofsauge.github.io/IsaacDocs/rep/xml/Anm2_files.html) says paths start at `gfx/`. The current three menu wrappers pass an adjacent-file existence check, which remains only an offline candidate. Do not remove the dossier deferral or present file-existence checks as native acceptance until this conflict is resolved.
2. The owner has confirmed that the v2 PR #2 pedestal, trinket and dossier visuals have not been tested. Keep PR #2 open and do not merge it until those checks and the path-rule review are complete.
3. After PR #2 is resolved, integrate the compatible item-art rule into this audit, wire the checker into `tools/check.sh`, remove resolved deferrals, and update `docs/HANDOFF.md` without mixing v2 PR numbers with old-repository history.
4. The CJK font candidate still requires an availability check in the game resources. Do not claim that offline validation proves it exists on the owner's installation.
5. The published `costumes2.xml` reference does not specify the base for `anm2path`. Keep future entries fail-closed until that rule is verified.
