# CI failures separated; retained-Dusk regression repaired

**Result:** Partially verified · **Owner:** current implementer · **Date:** October 19, 2026

All 18 available job logs in the original 20-run sample were inspected. Five failures stop at the 30-second simulator inventory limit; six fail Swift type checking in historical `FallingSkyView` revisions. Nine runs were cancelled, including two with UI failures; two have no jobs. No sampled run completed successfully. [Exact source/run/job records](ci-diagnosis.json).

One deterministic test-setup defect is corrected: `testDarkStarInfluenceRestoreAndAdjacentClear` waited for Dusk in a fresh survival sky where Dusk supply is disabled. It now uses the existing `unfed` committed fixture in the isolated dialogue-review defaults domain, restores that same domain, and checks the known one-starlight reward before and after restore and after a real native tap. It preserves the retained-Dusk and adjacent-removal assertions without changing gameplay, adding a fixture or weakening timeouts/counts.

**Next action:** the CI/native-test owner should resolve the remaining four locally reproduced UI failures and compare the guide failure on remote-equivalent Xcode 26.3. Diagnose inventory startup separately; require a complete development matrix before claiming healthy CI. Guidance/skill work can integrate independently.

## Remote evidence and limits

| Category | Runs | Observed mechanism / remaining uncertainty |
| --- | ---: | --- |
| Inventory timeout | 5 | `simctl list devices available --json` reaches the existing 30-second bound, exit 124; measured receipts 30.015–30.177 seconds. Why CoreSimulator stalls is unknown. Preserve group cancellation; no evidence justifies a blanket retry or longer bound. |
| Compiler failure | 6 | Historical `FallingSkyView.body` cannot type-check in reasonable time, exit 65. Later sampled revisions reach UI execution. This is source-specific history, not proof that current code fails compilation. |
| Cancellation with UI failures | 2 | Preserve assertions despite cancelled workflow status. Latest job lasts 2,140 seconds against a 35-minute job budget; budget exhaustion is plausible, not confirmed. |
| Other cancellations | 7 | Five have logs, two no jobs. Superseding pushes overlap some jobs; metadata alone does not establish every cancellation's cause. |

Successful-run duration/cost savings cannot be estimated from this sample. Job elapsed times are recorded, not billed minutes. The latest cancelled run skipped artifact upload. No manual dispatch, rerun, timeout change, workflow split or test exclusion was introduced.

## Local reproduction and focused fix

Baseline runtime/test source: `548660b1f78e9d34775eb0ee601e91f146a898ac`; only documentation differed during baseline execution. Six methods from the latest remote failure were selected serially on Xcode 27.1 (27A9275), Debug, arm64, iPhone SE (3rd generation) simulator `EA0F7A30-21E1-4995-93F5-C4A983F4A354`, iOS 27.0. Remote Xcode 26.3 is not installed locally, so this is not environment parity.

| Selected UI method | Baseline result | Finding / next check |
| --- | --- | --- |
| `ConstellationTraceNativeTests/testCurrentOrbitFollowUpGuideReadsToEndWithoutMovingActionsOrBoard` | Pass, 36.056 s | Remote score assertion did not reproduce; preserve its assertion and compare native environment/order. |
| `FallingSkyInteractionTests/testBalanceControlsPreserveBoardPersistAndChangeArrivals` | Fail, 13.488 s | Compact menu not hittable in pause helper. Remote also shows obsolete `Gentle · 6s` label; current copy is `Gentle · 6 seconds`. Fresh skies hide the historical Dusk-frequency control. Separate current and retained fixture expectations. |
| `…/testCompactHUDMenuSuspendsWithoutChangingPauseChoice` | Fail, 7.981 s | Immediate transient-message assertion; investigate timing/visibility before changing copy expectations. Later remote failure is a control assertion. |
| `…/testCompactPlayfieldKeepsControlsVisible` | Fail, 5.559 s | Old >70%-of-screen board-height assertion fails locally; inspect current native geometry and control access before changing the acceptance contract. |
| `…/testDarkStarInfluenceRestoreAndAdjacentClear` | Fail, 61.146 s → pass, 19.300 s | Replaced impossible fresh-sky setup with retained fixture; removed obsolete forced parsing of dynamic accessibility text, asserting the fixture's exact reward instead. |
| `…/testOpeningCascadeAllowsNativeClearBeforeLastWave` | Fail, 33.072 s | Calm-effects row is not materialized before scrolling in the menu. Reveal it with the existing menu helper, then retain the original full-motion, before-last-wave scoring assertion. |

Related paths examined: existing `DuskInteractionTests`, `NativeSkyControls`, menu scrolling, `DuskFixture`, `SkyDefaults`, restore/replay/fresh entry and balance controls. This bounds the diagnosis; it does not eliminate every UI failure class.

Fix source: current main `a1398d1b971c30c7557a8059b2d0b3466696ba66` (includes independently merged Lantern Landing PR #154) plus **only build-affecting dirty path** `UITests/FallingSkyInteractionTests.swift`, SHA-256 `fdbc8cad02186ad951e5ec6ad2f93aa07144a5a6dacf97f12f49a1599a8d60e5`. Concurrent instruction/document drafts do not enter the app build. App/Core/resources/project files are unchanged relative to that main. The baseline and candidate therefore have different app revisions; the durations are observations, not a controlled performance comparison.

| Check | Result |
| --- | --- |
| `swift test` | 177 passed, zero failures. Initial sandbox attempt could not write the compiler cache; authorized execution passed. |
| Debug simulator build + selected native tests | 9 passed, zero failures/skips: the repaired method, two Dusk sibling UI methods (early/zero clear and five-feed/background/settings/restore), all six `CriticalMassProductionTests` (fresh/replay pressure disabled, retained cadence/save migration and committed interruptions). |
| Hygiene and whitespace | `python3 scripts/ci-hygiene.py`, `git diff --check` passed. |
| Visual inspection | Two exported Dusk attachments were inspected. They show partial/empty rendering with a large black region, so **visual acceptance fails** despite passing interaction assertions. Retain raw attachments for capture/render diagnosis; do not promote them to the selected screenshot index. No app UI/artwork changed here. |
| Full animation / actual VoiceOver / physical device | Not accepted from this test-only correction. No movie or physical session; full VoiceOver remains an RC gate. |
| Release / full development matrix | Not run for this test-only change; no routing, resources, settings or fixture implementation changed. Remote health remains open. |

Reproduction uses XcodeBuildMCP `test_sim`, shared scheme `Starfall`, temporary DerivedData `/private/tmp/starfall-maintenance-derived`, ad-hoc simulator signing (`CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual`). Select the methods above with `-only-testing:StarfallUITests/<class>/<method>` and `-only-testing:StarfallAppTests/CriticalMassProductionTests`; use `-parallel-testing-enabled NO -test-timeouts-enabled YES -default-test-execution-time-allowance 90 -maximum-test-execution-time-allowance 240`. Do not run `ci-simulator.sh` on this non-disposable Mac.

Raw baseline: XcodeBuildMCP result bundle `test_sim_2026-10-19T14-32-18-930Z_pid95357_4e962ded.xcresult`. Focused result: `test_sim_2026-10-19T14-42-39-447Z_pid95357_535f6025.xcresult`, both under `~/Library/Developer/XcodeBuildMCP/workspaces/Starfall-5baffeb4084c/result-bundles/`. Logs use the matching timestamp under `logs/`. Disposable inspected attachments: `/private/tmp/starfall-maintenance-dusk-attachments/`; core log: `/private/tmp/starfall-maintenance-swift-test.log`. These local paths are reproduction aids, not durable public attachments.
