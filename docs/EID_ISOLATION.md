# Optional EID registration isolation

U4 compatibility fix, 2026-10-30, based on v2 main `4fadee1`. This is source and offline verification only. No game, installation, settings or saves were changed.

## Reproduced failure

The old adapter checked only whether the global `EID` was truthy. A non-table global, missing registration method or exception from an external registration method escaped `Eid:Init()`. Because `main.lua` calls it directly, that exception prevented the later Reaction Pack and developer-probe registrations from being reached. This was reproduced with supplied external APIs; it is not a reported failure of a particular installed EID version.

## Behavior

- Absent or false EID remains silent. A truthy non-table value skips this optional integration with one log message.
- Each description registration has a protected external API boundary, including method lookup and invocation. A missing method or rejected entry does not stop the other entries or categories.
- The original EID table is retained as the method receiver. No external table is patched and no failed entry is retried.
- Failures emit at most one English log line per category during this initialization. There is no HUD popup, sound, frame callback or automatic retry. Healthy registration stays quiet.
- Descriptions, registered IDs, language variants, gameplay values, callback order and save formats are unchanged.

This isolates the optional EID adapter only. It does not promise to recover arbitrary production-module failures, roll back side effects inside a failing external method, handle later EID runtime errors, or register a mod that becomes available only after initialization.

## Verification

`texlua tests/eid_isolation_test.lua .` fails on the baseline at the malformed-global case. With the fix it covers absent and malformed globals, absent/non-callable methods, throwing property lookup, one wholly failing category and one rejected collectible in three languages. Unaffected records must exactly match healthy registration; diagnostics stay bounded and supported entries are neither lost nor duplicated.

The same test runs the real `main.lua` and existing callback smoke scenarios with a failing EID method. The smoke fixture now explicitly requires the final developer-probe registration to be present, so completing only the earlier gameplay registrations is insufficient. This uses supplied Isaac APIs, not a native startup.

The existing `eid_test.lua` remains the independent reference for English XML names, all 97 collectible/trinket/pill entries, all 22 forms and valid description strings. Run both focused suites, `python tools/audit_interactions.py --check`, `bash tools/check.sh` and `git diff --check` before committing. Native startup with EID absent/present, displayed descriptions and the optional Reaction Pack behavior remain unverified.

Both focused suites, the full offline gate (including the new isolation fixture), interaction inventory freshness and whitespace checks passed on 2026-10-30 with Git Bash, Python and `texlua`. No native acceptance is inferred from those results.

## Handoff

The preceding independent units are merged as [v2 PR #8](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/8) (Agentic/fixed-look composition) and [v2 PR #9](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/9) (Greed clear-state guard). Their full offline checks and remote tree equality passed. Their native cases remain open.

Open v2 PR #2 still awaits owner testing and resolution of the dossier path-rule conflict; this unit avoids all its files. HANDOFF and CHANGELOG integration remain deferred under that file restriction. The U0 path audit remains in draft PR #7. Installed `8fd6a8c` is preserved and owner-untried. Continue with real character/item combinations, O6 saves, whole-mod performance and the remaining optional-module boundaries; this narrow correction does not complete U3 or U4.
