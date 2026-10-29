# Old-repository handoff table archived 2026-10-30

The following table is preserved verbatim from the old repository handoff. Its PR numbers #104-#148 refer to `WaterLily5297/claude-chan-isaac`, not the v2 repository.

## Recent units (#104-#148)

All are offline source/tooling/documentation work; none is installed or engine-accepted. Full entries: [history](HANDOFF_HISTORY_2026-10-27.md).

| Area | PRs | Result |
|---|---|---|
| Audits | #105, #106, #108, #110 | [ART_STATUS.md](ART_STATUS.md), [INTERACTIONS.md](INTERACTIONS.md) scanner, [CHARACTER_COMPLETION.md](CHARACTER_COMPLETION.md) (22 forms, G1-G7/S1-S4), [ITEM_COMPLETION.md](ITEM_COMPLETION.md) (97 registrations, F1-F15). |
| Item art | #111, #112, #115, #118, #122, #126, #129, #134, #135, #136 | Icon pipeline and validator ([make_item_art.py](../tools/make_item_art.py)); all 92 icons designed with 1x/4x review sheets ([batch 01](ITEM_ART_BATCH_01.md) to [09](ITEM_ART_BATCH_09.md)). |
| Item fixes | #113, #116, #121, #124, #128, #130, #132, #137, #139, #143, #144, #145, #146, #147 | F8, F13, F11, F2, F9 [charm after shields](CHARM_DAMAGE_ORDER.md), F4/F5 text, F15 Rice Cooker Continue, Disgrace Loop text (own bombs count), F10 Seahorse co-op/exit tests, F6 saved item state (and Vibe Coding marks) follows its live owner, Disgrace Loop after shields, F1 Compact enters Limited, F7 Opus partial bill saved. Details in [ITEM_COMPLETION.md](ITEM_COMPLETION.md). |
| Character art | #141 | [Sprite audit](SPRITE_AUDIT_2026-10-27.md): crop leftovers removed from 7 sheets and gated; cut poses on 4 families need source re-crops. |
| Characters | #107, #109, #123, #140, #142 | Normal Claude live-owner isolation, T1/T2 text, [Birthright timing](BIRTHRIGHT_TIMING.md) for four tainted forms, [DROP refusal audit](DROP_REFUSALS.md), [HUD text audit](HUD_TEXT_AUDIT.md) (long lines wrap to row 1, dossier portraits clear the text). |
| Evidence only | #119, #127 | F12 [charged-use replacement](CHARGED_USE_AUDIT.md) reproduced, not fixed; [primary-tear composition](PRIMARY_TEAR_COMPOSITION.md) matrix, no defect found. |
| Stability | #114, #117, #120, #125 | Usage/Limited load validation, GPT/Grok binding allocation ([PERFORMANCE.md](PERFORMANCE.md)), thumbnail exporter repair, scheduled [hardening](HARDENING_2026-10-27.md). |
| Install record | #104 | Documentation sync installed as `8fd6a8c`. |
| Documentation | #131, #133, #138, #148 | Handoff compacted (D2 in TESTING.md), [PUBLISHING.md](PUBLISHING.md) refreshed (Workshop still not authorized), CHANGELOG caught up, F3/F5/F14 decided as coded. |
