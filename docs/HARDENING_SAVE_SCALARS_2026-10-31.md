# Scheduled review: isolate damaged core save fields

Reviewed v2 main `2da0add81dfa3ae6afc342e5431b944344f77328` after three substantive units since the [save-barrier review](HARDENING_SAVE_BARRIER_2026-10-30.md):

| Unit | Reviewed evidence and remaining boundary |
|---|---|
| [#24](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/24), Constitution ownership | The six full-entry rotation/Continue cases, lifecycle controls and separate body fixture still pass. Save-hook failure still prevents a mixed snapshot from being written. Unknown first-hidden-body movement and native identity remain unresolved; no policy change is made here. |
| [#25](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/25), approved tainted sources | All nine source PNGs and their comparison still match the approval registry hashes. They are approved design inputs, not installed gameplay skins. Generator/importer integration remains dependent on PR #2. |
| [#26](https://github.com/WaterLily5297/claude-chan-isaac-v2/pull/26), GLM pose repair | Published-source re-packing and cross-family pixel isolation pass. All 22 Hit cells remain unchanged against `1206a32`. Existing darkened tainted GLM inherits the repaired geometry; the approved white-haired identity is still pending. Native animation remains unaccepted. |

## Reproduced finding F22

`Risk:Load` previously copied every successfully decoded value into the live state without validating its base scalar fields. Three independently supplied malformed records reproduce failures in actual production consumers on the baseline:

- `risk="damaged"`: suspension comparison throws after Continue.
- `sharedUsers={}`: the Risk HUD's integer formatter throws.
- `silentMult={}`: Silent Update's damage-cache multiplication throws, including on a non-Claude form.

Fractional risk/shared-user values also cannot be passed to the existing integer HUD format. The older field-by-field save fixtures did not exercise these damaged core values. These are source/offline reproductions with a detached table codec, not a report that the owner has encountered corrupted saves or that native JSON/disk recovery has been tested.

## Narrow loading correction

After decoding and merging, Risk validates only its eight existing base fields. Each invalid field gets its own existing default; valid neighbouring fields and unknown/versioned module roots are preserved for their own migration code.

| Field | Accepted existing domain | Invalid/missing default |
|---|---|---|
| `risk` | Finite integer, 0 through `Constants.RISK_MAX` | 0 |
| `ip` | String containing exactly four 1-3 digit octets, each 0-255 | `0.0.0.0` |
| `sharedUsers` | Finite integer, 0-220 (initial zero or the existing RollIp maximum of 20+200) | 0 |
| `silentMult` | Finite number, 0.8-1.3 (the existing Silent Update range) | 1 |
| `residentialApplied`, `relayApplied`, `constitutionApplied`, `constitutionBlockUsed` | Actual booleans | false |

Strings containing numbers or the word `true` are not coerced. NaN and infinities are rejected by the numeric checks. Default values apply only when loading malformed/missing values; valid saved Risk, rolls, pickup consumption and character/item maps retain their existing behavior. There is no balance change, save-version change, entity serialization or whole-save reset. DeepSeek and the other non-Claude forms still never acquire Risk/IP mechanics. Silent Update remains an item effect on eligible holders of any form.

The scalar domains must remain aligned with their producers if a future deliberate gameplay change alters those ranges. This does not normalize every module's nested state, mask a failed synchronizer, recover failed disk reads/writes or add general callback isolation. SaveSync's failure-before-write policy remains intact.

## Offline regression evidence

[full_mod_save_scalars_test.lua](../tests/full_mod_save_scalars_test.lua) loads actual main.lua and production modules:

- 45 isolated malformed field cases preserve every other valid core field, a synthetic unrelated versioned module map and the old `accountAge` migration field; rendering runs after each repaired load. Boundary controls preserve valid minimum/maximum values. Missing/non-table payloads, a supplied decode error and nine supplied non-finite parser-return cases fall back safely. The latter are fault inputs, not a claim that native JSON accepts non-finite numbers.
- All 22 forms earn Constitution's pickup and consume its shield, save, then resume with damaged core fields and intact inventories/maps. Before advancing callbacks, every non-core saved module is compared with its pre-Continue value. Subsequent updates, HUD rendering, damage caches, ordinary damage and re-saving retain finite damage and consumed Constitution effects. Only Claude forms accept the later Risk increase; the other twenty remain at zero exposed Risk.
- A valid legacy snapshot retains shared Constitution consumed bits and migrates Claude's account age through actual startup. This control passes on both baseline and corrected source.

The fixture supplies `Entity:IsEnemy()` for its player/enemy damage stand-ins, matching the [base Entity API surface](https://wofsauge.github.io/IsaacDocs/rep/Entity.html#isenemy); that explicit response is not native callback evidence. The detached codec, entity methods and callback order remain supplied test inputs.

An unchanged isolated-source control passes. Baseline source fails the invalid-field and all-form Continue selectors; its valid-legacy selector passes. Eight syntax-valid source faults are rejected: omitting normalization, omitting IP validation, omitting Silent Update validation, accepting fractional risk, accepting fractional shared users, coercing truthy pickup flags, deleting the Constitution map and dropping the legacy age field. Fault copies and synthetic snapshots stay private; they contain no owner save data.

Twenty-six existing isolated save fixtures supplied a partial Constants table without `RISK_MAX`. They now supply the existing value 100 needed by the real loader; their previous assertions are unchanged. The first full-gate run exposed this fixture dependency, and all 26 targeted rechecks pass after filling it in.

Run `texlua tests/full_mod_save_scalars_test.lua .`, the existing Constitution/save-barrier suites and `bash tools/check.sh`. The standard gate automatically discovers the new Lua suite. The source interaction inventory is refreshed. CI/stubs do not establish real Continue, native JSON migration, health limits or gameplay acceptance.

## Handoff

This record, TESTING, ITEM_COMPLETION F22 and CHARACTER_COMPLETION provide the update while HANDOFF/CHANGELOG remain protected by open PR #2. PR #2's icon/dossier test and path reconciliation, draft #7, RC1 and approved-tainted production retain their dependencies. No game, installation, owner saves/settings or Workshop action occurred; installed `8fd6a8c` remains preserved.

Continue the remaining U3/U4/U5 compatibility, migration, error/performance isolation and native cases, alongside the eight remaining normal-family profile repairs and the full approved-tainted production queue. The overall brief is incomplete. The next scheduled hardening review is due after another three to five substantive units or a concrete new failure.
