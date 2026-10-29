# Claude handoff: current development checkpoint

## Start here

Updated 2026-10-30. Read [CLAUDE.md](../CLAUDE.md), [CONTRIBUTING.md](../CONTRIBUTING.md), [TESTING.md](TESTING.md) and [art terms](../resources/ART_LICENSE.md) before editing. Histories ([2026-10-30](HANDOFF_HISTORY_2026-10-30.md), [2026-10-27](HANDOFF_HISTORY_2026-10-27.md), [2026-10-25](HANDOFF_HISTORY_2026-10-25.md), [2026-10-24](HANDOFF_HISTORY_2026-10-24.md)) keep their original evidence scope and are not current acceptance.

- **Repository:** development moved on 2026-10-28 to [claude-chan-isaac-v2](https://github.com/WaterLily5297/claude-chan-isaac-v2) with main's full history; PR numbers restart there. Earlier PR numbers (#1-#148) and old work branches refer to the read-only [original repository](https://github.com/WaterLily5297/claude-chan-isaac), which keeps superseded draft PR #100 (never merge). The mod folder name stays `claude-chan-isaac`.
- **Current main:** [live main](https://github.com/WaterLily5297/claude-chan-isaac-v2/tree/main). Fetch it and inspect open PRs before editing.
- **Open v2 PR #2:** [item icon and dossier path fix](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/2) has green CI; the owner had not tested it as of 2026-10-30. Static audit confirms its 92 item-icon paths resolve through item-category routing, but the 22 dossier ANM2 basenames do not resolve under the published [ANM2 `gfx/`-root rule](https://wofsauge.github.io/IsaacDocs/rep/xml/Anm2_files.html). This convention conflicts with the PR's adjacent-file assumption; keep it unverified and do not merge until reconciled with engine evidence.
- **Installed manual-test build:** exact source `8fd6a8c8a543226f414a01c654ff1f85bde1214c` (gameplay `ef7d2dd`, #102 plus O4/O5), installed 2026-10-26 after a fresh allowlisted backup of 443 files passed reread SHA-256 verification; all 451 tracked files reverified. Preserve it during source follow-ups; replacing it needs separate owner authorization.
- **Owner testing:** the owner replied "not tested yet" on 2026-10-26. No manual case is accepted. Keep the [14-item manual checklist](MANUAL_TEST_CHECKLIST.md) available without repeating the question in the same session.
- **Evidence level:** the offline gate (`bash tools/check.sh`, also run by CI) passes: Lua suites, interaction scanner, item-art, thumbnail, XML, deterministic assets and inventory freshness. Stubs do not prove native callbacks, animation, input, real Continue or playability. Engine evidence is historical only: [ENGINE_AUDIT_2026-10-26.md](ENGINE_AUDIT_2026-10-26.md).
- **Desktop gate:** before each engine block, obtain a fresh owner confirmation of being away from the keyboard for a stated duration. On user-input, missing-monitor or obscured-window errors, stop immediately; do not retry or send keys. Close only the process launched for that block and restore settings. One attempt per go-ahead.
- **Owner long-term plan (2026-10-27):** phases 0-5 (stabilize and test, playable alpha, character art, completion and compatibility, approved new content, publishing prep) with pending owner decisions. The plan lives in the project's shared files, not in this repository; the queue below follows it.

## Current queue

Pick the top unit that is not gated. A bug the owner reports beats everything.

1. **Owner-visible correctness first.** Remaining [ITEM_COMPLETION.md](ITEM_COMPLETION.md) finding F10's native save/reload case; F12 waits for native completion/removal evidence. F1, F3, F5, F7 and F14 were decided on 2026-10-28 (owner delegated).
2. **Art.** All 92 icons are designed offline; their native pedestal/EID look is unreviewed ([ART_STATUS.md](ART_STATUS.md)). Character work: proper side profiles for the nine newer families, GLM's fallen pose, special poses, Relay Slime and `thumb.png`. Distinct designs for the nine derived tainted families need an owner preview first.
3. **Characters.** [CHARACTER_COMPLETION.md](CHARACTER_COMPLETION.md) keeps all 22 rows open on shared gaps G1-G7 and special cases S1-S4; W2.4 refusal conditions are audited in [DROP_REFUSALS.md](DROP_REFUSALS.md) and narrow-screen HUD text in [HUD_TEXT_AUDIT.md](HUD_TEXT_AUDIT.md); refusal cues and native HUD-corner checks remain.
4. **Compatibility and stability.** Interaction candidates in [INTERACTIONS.md](INTERACTIONS.md), the wider vanilla matrix (special characters, Greed, challenges), seeded mod-item combination invariants, O6 save/continue audit and a whole-mod performance budget ([PERFORMANCE.md](PERFORMANCE.md)).
5. **Gated content.** Meme batch 3 (O7), character synergies (W5), Chinese/Japanese roster story text and Workshop all need explicit owner decisions.

No further child-laser/Parent/derived-shot billing PR without native E2 evidence. Repeat a scheduled hardening review after three to five substantive units or a concrete failure.

## Recent units (v2)

Merged units use v2 PR numbers. The old-repository PR #104-#148 table is preserved verbatim in [HANDOFF_HISTORY_2026-10-30.md](HANDOFF_HISTORY_2026-10-30.md).

| PR | Area | Result | Evidence |
|---|---|---|---|
| [#1](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/1) | Repo move | Pointed links to v2 and recorded the PR reset; gameplay unchanged. | CI passed; docs only. |
| [#3](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/3), [#4](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/4) | Handoff | Archived old PR table; started v2 history. | CI passed; docs only. |

## Long-term completion gates

| Area | Current evidence and remaining work |
|---|---|
| Art | All 92 icons designed (offline review only). Side profiles, GLM fallen pose, cut complete poses ([sprite audit](SPRITE_AUDIT_2026-10-27.md)), nine distinct tainted identities, Relay Slime, thumbnail and native visuals remain open. |
| Characters | All 22 forms have a loop, B1 tradeoff and Birthright in source; every completion row is open pending G1-G7/S1-S4 and real fresh starts/combat floors. |
| Items | 80 collectibles, 12 trinkets and five pills registered. F2, F4, F8, F9, F11, F13 and F15 are fixed in source and F10 has offline cases; the rest and mechanism-by-mechanism native acceptance remain open. |
| Compatibility | Source scanner and focused fixtures exist; candidate semantics, combinations and the native matrix remain open. |
| Optional synergies | Proposal and rule approval required before implementation. |
| Stability | Save/performance/integration hardening and one full run to Mom per family group remain open; green CI is not playability acceptance. |

## Implemented source

| Area | Current implementation | Reference |
|---|---|---|
| Characters | 11 families, 22 normal/tainted forms: Claude, DeepSeek, GPT, Gemini, Grok, Qwen, Llama, Mistral, Doubao, Kimi and GLM. Each has its own meme loop, one owner-approved B1 tradeoff, Birthright behavior, starting-pickup contract, EID and dossier. | [Actual behavior](MODEL_ROSTER.md), [design targets](CHARACTER_GAMEPLAY.md), [B1 tradeoffs](DIFFICULTY_FEATURES.md) |
| Items | 80 collectibles (25 originals, meme batches 1-2 and all 50 requested backlog rows), 12 trinkets, five pills, meme extras and the Relay Slime enemy. | [Generated reference](ITEMS.md), [backlog](EXPANSION_DESIGN.md), [batch 2](MEME_BATCH_2.md) |
| Shared mechanics | Native-weapon resource observers, DeepSeek Thought adapters, DROP tap recognition (disabled with multiple pocket items), meal countdown, scoped helper shots, tear tint, feedback and co-op HUD bands. | [Native Thought](NATIVE_THOUGHT.md), [DROP review](DROP_POCKET_REVIEW.md), `scripts/characters/` |
| Risk and saves | Risk covers Claude forms only; DeepSeek has no proxy/IP/risk mechanics. Versioned per-player state and floor checkpoints. | `scripts/risk.lua`, [save cases](TESTING.md) |
| Appearance | All 22 skins, menus, stage portraits and MAP dossiers are wired. The fixed-look service clears item costume layers on mod forms while keeping item mechanics; O4 restores native transformation costumes after leaving a mod form. O5 corrected Death cell packing. | [Costume contract](COSTUME_COMPATIBILITY.md), [pose review](POSE_REVIEW.md) |
| Story | Appeal Queue (en/zh/ja) plus three-chapter English arcs for the other ten families. | [Story](STORY.md), `scripts/story_roster.lua` |

Compatibility fixes through #91 (fire-rate scaling, ghost guards, safe doors, co-op HUD, floor saves, Claude-only Risk, battery charge, familiar attribution, per-player Constitution, helper billing, Ludovico exemption) are merged in source. Use the individual cases in TESTING.md rather than treating this list as native acceptance.

## Decided rules and open owner decisions

Already decided; do not reopen: tainted DeepSeek non-tear weapons pay Compute for the 1.3x off-peak boost; normal GLM's forced Book of Secrets stays removed; fixed mod looks (costumes cleared, effects kept); short DROP stays and abilities are disabled with multiple pocket items; the #102 tradeoffs; Let's Delve and Six Seven rules.

Still the owner's call: distinct tainted designs (preview first), meme batch 3 and synergy rules, the broad Continue target versus explicit transient attempts ([CHARACTER_COMPLETION.md](CHARACTER_COMPLETION.md) follow-up 2), F3 target gaps, an effect-layer allowlist for the fixed look, difficulty feel after play, Chinese/Japanese roster story text, replacing the installed build, and Workshop publication (not authorized).

## Waiting for owner availability: engine acceptance

| Unit | Required observation | Status |
|---|---|---|
| E1 | Preserve the current installation; a later requested replacement needs a fresh allowlisted backup and reread-hash check. | Complete for `8fd6a8c`; preserve it. |
| E2 | One ancestry probe: Parent, SpawnerEntity and FrameCount at init/update for Tech X splits, Prism reflections, Trisagion and Brimstone/Tech combinations. | [Observer](ENGINE_ANCESTRY_PROBE.md) ready; attempted session produced no samples. Prerequisite to more child-billing work. |
| E3 | Real menu fresh starts and first room for every normal/tainted form: stats, pockets, HUD, fixed look, dossier, story and errors. | Waiting; type-change smoke does not satisfy this. |
| E4 | Physical keyboard/controller DROP taps and holds, card/pill plus pocket active, pause, disabled controls, room changes, death and reassignment. | Waiting; stubs cannot accept native input. |
| E5 | COSTUME-LOCK-01 and VANILLA-COMPAT-01, O3/O4 cases, MEME-BATCH-02, the B1 native matrix, then the remaining animation, combat, weapon, save, co-op and item matrix. | Waiting. |
| E6 | One full run to Mom per family group without mod errors ([GOALS.md](GOALS.md) first-playable milestone). | Not started. |

For an authorized run: E:/ba backup workflow before replacement; preserve other mods and saves (File 1's run is disposable); mute tests, close the game and restore settings afterward. Record game version, installed commit, case and evidence level, in base Repentance and Repentance+. Review historical `runtime_probe.lua` fixtures before running them.

## Known risks

- **Appearance:** Hit/Death envelopes pass offline ([POSE_REVIEW.md](POSE_REVIEW.md)); pose-cell leftovers are cleaned and gated, cut poses need source re-crops ([SPRITE_AUDIT_2026-10-27.md](SPRITE_AUDIT_2026-10-27.md)). Narrowed-front side bodies and GLM's fallen pose need redraws. Native motion, special poses, flight and revival remain to inspect.
- **Fixed look:** ClearCostumes may hide wings, Holy Mantle or other effect layers, or allow a one-frame pickup flash. Temporary/trinket/external layers and native reconstruction order remain open. Preserve size, flight, weapons and transformation mechanics.
- **Input:** abilities are disabled when the observer sees multiple pocket items; native timing and inventory changes between samples remain E4 cases. Meal hooks block directional shooting, not every charged/programmatic/familiar attack.
- **Native attacks:** Incubus/Twisted Pair timing, melee hitbox lifetime, knife flight, Epic Fetus attribution, Ludovico steering, multi-shot allowance limits and Peak's 1.3x non-tear boost require engine cases. Modeled Parent ordering is not observed engine evidence.
- **Composition and saves:** CollisionDamage writer order with other mods, native save/exit order, exit during knife flight, Seahorse wisps, player-type changes and co-op reassignment remain open. F12 can falsely observe a refused charged use after inventory replacement.
- **New mechanics:** #102 migrations and conditional rewards pass supplied offline callbacks only; actual FireDelay and kill ordering remain unobserved. See DIFFICULTY_FEATURES.md and the B1 native matrix.
- **Environment:** historical Stackable Items v2 load errors belong to that mod and must not be claimed fixed here.

## Direction and contributor workflow

Build recognizable community-meme choices: Claude bans/appeals, DeepSeek rice and Peak/Valley, GPT downgrade/Tibo resets. [Meme research](COMMUNITY_MEME_RESEARCH.md) distinguishes viewed sources, indexed titles, secondary claims and blocked pages. Fictional mechanisms are parody, not factual accusations. No real-person/nationality enemies, Grok July 2025 offensive references or official logos.

Use native systems and preserve their effects. Never restore DeepSeek proxy/IP/risk. Keep new code, comments, Markdown and UI English. Character design/art is not MIT: preserve ZipZipPipe and DeepSeek credits and the applicable non-commercial/share-alike terms; no extracted vanilla or unlicensed mod assets.

Fetch main, preserve drafts, use one focused main-based PR (no stacks or history rewrites), run `bash tools/check.sh`, update this handoff and evidence, verify CI. Own compatible fixes may merge after checks when no bug or design/balance decision is open. No Workshop release; keep private paths, backups, saves, logs and source references out of commits.

New-item checklist: register module/constants/XML with ASCII pickup text; wire main in the right callback order; add EID, icon and pool entry; update `tests/eid_test.lua` counts; regenerate `docs/ITEMS.md` (`lua5.4 tools/item_reference.lua .`) and the interaction inventory (`python3 tools/audit_interactions.py --write`); update all three READMEs and the relevant design records.

**Keeping this file short:** stay under about 15 KB. Add each unit as one row in "Recent units" (or one line in an existing row) and put detailed evidence in TESTING.md or a dated audit. When the table outgrows about 30 PRs, move it verbatim to a new dated history file and start a fresh table.

Core files: `main.lua`, `scripts/constants.lua`, `content/*.xml`, `scripts/risk.lua`, `scripts/characters/`, `scripts/items/backlog/`. Tests are offline stubs; generated assets and item references are checked by `tools/check.sh`.
