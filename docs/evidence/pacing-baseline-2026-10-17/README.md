# Opening and tracing prerequisite baseline

**Result:** Partially verified · **Owner:** current implementer · **Date:** October 17, 2026

Remote main `ba348d758b2b2e5dcc63bf0f4fccf75bc357a7fc` contains selected constellation tracing but lacks the approved opening. Branch `codex/pacing-baseline` applies the existing opening commit `8654b63` as `c78d22d`, then adds one combined deadline regression in `571ccd1` and corrects its fixture in `21aae674dc74752a5617679affcea0837431d680`. No reimplementation or unrelated local-main work is included.

**Next action:** Downstream work may use the exact local baseline below, as authorized by the coordinator; publish and integrate this scoped branch through an authenticated Git transport when available. A dry-run push fails because this host cannot read a GitHub username; `gh auth status` also reports signed out. Remote-main integration is therefore still open.

## Acceptance and source boundary

The prerequisite is one production Falling Sky route with selected tracing, an empty four-wave opening (0.25 seconds, then three 1.8-second gaps), three-second new-sky default, unchanged wave generation and falling presentation, and clearing between settled waves. Old saves, First Light, replay, interruption guards and the single-deadline clock retain their contracts. No phase cycle, HUD redesign, measurement framework, app identity/updater changes or phone installation belongs to this batch.

Application source changed only in `App/FallingSkyMenu.swift`, `App/FallingSkyStore.swift`, `Sources/StarfallCore/FallingSky.swift` and `Sources/StarfallCore/StarfallBalance.swift`. Regression paths are `AppTests/FallingSkyStoreTests.swift`, `Tests/StarfallCoreTests/FallingSkyPacingTests.swift`, `Tests/StarfallCoreTests/FallingSkyTests.swift` and `UITests/FallingSkyInteractionTests.swift`. Other paths document the adopted opening and retain its historical images/evidence. No project/resource membership changes were needed. Debug and Release still route through `FallingSkyView`; native trace classes already belong to the existing app/UI targets.

Documentation conflicts retained remote tracing and delivery records alongside opening records. The new hosted regression uses seed 4 after opening wave three, builds a legal five-star trace, commits wave four at its original deadline, and checks snapshot invalidation, rejection of stale completion, saved committed state and the next three-second deadline. Existing checks cover selected-set clearing and restore, legacy cadence, First Light and repeated interruption paths.

## Verification context

**Baseline source:** `21aae674dc74752a5617679affcea0837431d680`. Core passed at clean `c78d22d`; native UI and Release passed at clean `571ccd1`. Final hosted/Debug checks passed at `21aae67` with only this report and its index dirty; no dirty build paths. The only source difference after the native/Release run is the corrected hosted test fixture. All app/core sources are identical across those runs. The evidence commit changes no app/test source.

**Environment:** Xcode 27.1 (`27A9275`), arm64 simulator; iPhone 17e / iOS 27.0, simulator `4103C352-DFC2-493E-A224-DE4CE3D50889`. Signing disabled. Physical phone and installed app/updater unchanged.

| Check | Result |
| --- | --- |
| `swift test` | 65 tests pass; includes 200-seed opening/generator round trips and historical save cadence. Raw log `/tmp/starfall-pacing-core.log`. |
| Hygiene / whitespace | `python3 scripts/ci-hygiene.py` and `git diff --check` pass. |
| Release simulator build | Pass; raw log `/tmp/starfall-pacing-release.log`, DerivedData `/tmp/StarfallPacingBaselineRelease`. |
| Debug build / hosted | Pass: all 28 store tests at `21aae67`, including combined opening trace invalidation. Raw log `/tmp/starfall-pacing-hosted-final.log`; result `/tmp/StarfallPacingBaseline/Logs/Test/Test-Starfall-2026.10.17_17-13-02--0400.xcresult`. |
| Native UI | All 10 selected tests pass at `571ccd1`: 3 tracing tests and 7 opening/play/interruption/accessibility tests. Result `/tmp/StarfallPacingBaseline/Logs/Test/Test-Starfall-2026.10.17_17-04-45--0400.xcresult`. |
| Visual / animation | Inspected exported opening-clear and largest-text game screenshots: sampled layout/text readable. Opening-clear capture includes falling stars/trails. Normal-motion native test explicitly turns Calm and system Reduce Motion off and restores the system preference; separate actual system Reduce Motion manual-play test passes. No new continuous-animation review or smoothness claim. |
| Actual VoiceOver / physical device / human pacing | Not run; full VoiceOver is an RC check, and this task excludes phone installation. |

Release command: `xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/StarfallPacingBaselineRelease ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build`.

Debug command uses `-configuration Debug -destination 'platform=iOS Simulator,id=4103C352-DFC2-493E-A224-DE4CE3D50889' -derivedDataPath /tmp/StarfallPacingBaseline ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO`, selecting `StarfallAppTests/FallingSkyStoreTests`, `StarfallUITests/ConstellationTraceNativeTests`, and the opening, automatic pause/growth/clear/replay/settings, background/relaunch/overflow, First Light win and loss, largest-text dismissal and system Reduce Motion methods from `StarfallUITests/FallingSkyInteractionTests`, followed by `test`. Raw log `/tmp/starfall-pacing-native.log` retains native output and the result path.

## Fixture correction and limits

The initial combined command reports `TEST FAILED`: all 10 UI tests passed, but the new hosted test could not begin a trace from a three-star first wave. This is a test setup error, not a runtime failure. Seed 4 at wave three has a legal five-star horizontal trace; the corrected test asserts that precondition and visits every selected cell before testing invalidation by wave four. All 28 hosted checks then pass; no runtime guard or assertion was weakened. Only hosted checks were repeated because only their fixture changed.

Exported captures and their manifest are under `/tmp/starfall-pacing-captures/`. They are temporary raw output, not durable artwork. Historical evidence remains source-bound; no new screenshot binary was added to the repository.

## Limits

A passing native opening tap and a separate fixture swipe do not establish comfortable tracing during the short automatic opening windows. The hosted combined test proves deadline invalidation, not human timing. Existing [opening evidence](../opening-cascade-2026-10-17/README.md) retains source-labeled animation captures; those historical images are not new visual evidence for this branch. Physical-device comfort, sparse-seed interest and human preference remain the [existing follow-up](../../ENGINEERING.md#opening-cadence-acceptance--october-17-2026).

## Core handoff integration

Task 2 commit `15c10288dc21832742005d0406b11b017b5b4e16` was applied as `8ba948f647178f1006c15de49c371048d06df96b` on the baseline branch, preserving the corrected `21aae67` opening-trace fixture. No conflicts or additional runtime changes. Review covered the version lookup, persisted-marker fallback/validation and replay boundary; the Store adoption remains task 3's responsibility. The coordinator owns later dispatch and shared design/protocol documents.

Clean `8ba948f` passes 72 Core tests, all 28 hosted store tests, Debug simulator build (through the hosted invocation), Release arm64 simulator build, hygiene and whitespace checks. Commands and destinations match the baseline commands above; logs are `/tmp/starfall-pacing-integrated-{core,hosted,release}.log`. Hosted result: `/tmp/StarfallPacingBaseline/Logs/Test/Test-Starfall-2026.10.17_17-15-53--0400.xcresult`. No native UI or visual checks repeated for this Core-only integration; their prior source boundary remains explicit. This evidence-only follow-up does not change tested sources. Remote publication, phone installation and updater changes remain excluded.

## Store handoff integration

Task 3 runtime/fixture contract `3c09532d78400f877b4961073de05de3afa33828` and evidence `1316f815591f18a183c8bf5c9a72d97b618e909b` were applied as `e9b2a53` and `18b78e2`. No conflicts. App, Core, test and project contents match the task 3 handoff exactly; the sole difference is the earlier baseline Core-integration evidence paragraph. The corrected opening-trace fixture remains present. Review covered cadence refresh before scheduling, retained deadline during busy deferral, cancellation/generation guards, same-sky replay, Debug-only observation boundaries and canonical B fixture membership in test targets only.

Clean `18b78e2` passes 72 Core tests, all 33 hosted store tests, Debug simulator build through the hosted run, Release arm64 simulator build, hygiene and whitespace checks. Commands/destinations match the previous integration checkpoint; raw logs are `/tmp/starfall-pacing-store-integrated-{core,hosted,release}.log`. Native UI/visual checks are deferred to combined task 6 acceptance after cues and tooling; no new native UI, animation, actual VoiceOver or device claim follows from this checkpoint. No remote publication, shared-main mutation, phone installation or updater change. Tasks 4/5 remain coordinator-owned parallel work from the task 3 contract.

## Tooling handoff integration

Task 5 `7040bfa1853e34ee24587c868a18dc999b424930` applied without conflicts as `6919396`. Tool source is byte-identical to its verified handoff; no App/Core/project edits. Review confirmed visible-board policy selection, canonical B lookup reuse, actual Store/trace-intent execution, bounded full-component walks and same-action committed-state replay. The trace policy does not enumerate deliberate smaller subsets; presentation/reaction timing remains a model, not native acceptance.

Clean `6919396` reran `python3 tools/mechanics/compare-pacing.py --seeds 16 --seconds 120 --output artifacts/pacing-integrated`: 192 runs and 8,765 committed replay checks pass. Integrated `runs.json` and `summary.json` match task 5's retained outputs byte-for-byte; `source.json` records this integration source and empty dirty status. Hygiene and whitespace checks pass. Outputs remain ignored. No native suite repeated for this tool-only batch; task 6 will validate the combined cue/runtime source. Mixed B outcomes remain counterexamples, not adoption evidence.

## Reconcile accepted current-main work before final acceptance

Remote-tracking main advanced independently to `ca7f12e46a7d61cdb6c7c8f8d475ef9a9fa9961c`. Separate local merge `403aa58` preserves its accepted Welcome/Entry/Ending flow, menu/footer and native lifecycle tests before combined pacing acceptance. Pacing Core, Store seams and canonical fixture remain intact. Documentation/project conflicts retain both owners' entries; an obsolete duplicated updater-contract paragraph was removed. Updater/CI files under `scripts/` and `.github/` are byte-identical to that origin source; no delivery behavior was edited by this work. No shared-main mutation, remote publication, phone installation or updater invocation occurred.

Clean `403aa58` passes 72 Core tests and Release simulator build; Debug compilation through the selected hosted-test command completes. The hosted runner did not launch or produce XCTest output on simulator `4103C352-DFC2-493E-A224-DE4CE3D50889`; its owned xcodebuild was interrupted after approximately three minutes without resetting that shared simulator. This is **not a hosted pass**. Raw logs are `/tmp/starfall-pacing-reconciled-{core,hosted,release}.log`. Task 6 must run combined hosted/native acceptance on its private healthy simulator after cue integration. Hygiene and whitespace checks pass. No source-dependent pre-merge native result is promoted to acceptance of this merge.

## Cue handoff and exact combined candidate

Task 4's specialist commits through `9ec3ba4` are integrated in small commits after the current-main reconciliation, explicitly as a **partial handoff for validation**, not B adoption. Largest-text and normal-motion B flows passed on its candidate source `c9cde8a`; reduced-motion Settings completion, final capture review and combined-main native acceptance were open. Those branch results do not verify this adapted source.

Combined runtime/export source is `5e56d5ae63e2bf34667e5d46013c0d643a33ecfe`. Integration preserves current main's ceremony ZStack, Welcome/Entry/Ending routing, guides and suspension boundaries. Cue copy and transition speech additionally require no ceremony; Settings removes the real cue. The isolated B export retains its measured fixed slot from round start, including underneath Settings/ceremony, so phase changes cannot resize the scene. A retains its prior layout. Export initializer/fallback now preserves `forSkyFlowApp`; project membership anchors the exact app sources phase rather than assuming its first file. The initial stale-order export was rejected and not built.

Clean `83a9126` passed 72 Core tests and normal Debug/Release arm64 simulator builds; the only later source change is the exporter membership anchor. Clean `5e56d5a` successfully exports and passes the exported Debug simulator build. Export integrity compares ten Core/Store/ceremony/fixture files byte-for-byte and checks the fixed slot, ceremony guards and source membership. Canonical fixture SHA-256: `873a78ded0501fcc4bb14123a92b93d634a10015aa16a97083eaa07b7d0e51e0`. Updater/CI still match `ca7f12e` exactly. Hygiene and whitespace checks pass. Raw logs `/tmp/starfall-pacing-final-{core,debug,release,export-debug}.log`; export manifest `/tmp/starfall-pacing-combined-final/pacing-candidate-manifest.json`.

Reproduce with `python3 tools/mechanics/prepare-pacing-candidate.py --source 5e56d5ae63e2bf34667e5d46013c0d643a33ecfe --output <new-directory>`. Export build uses the earlier Debug generic-simulator command with that exported project and `/tmp/StarfallPacingCombinedExport` DerivedData. Task 6 owns fresh combined hosted/native acceptance on a healthy private simulator, including the explicit reduced-motion/settings, capture/motion, ceremony/cue and trace/clock gaps. No further attempt used the stalled baseline hosted runner. Human comparison and publication remain pending; no phone or updater operation occurred.

## Pinned forecast reconciliation after the initial acceptance source

A single additional reconciliation is pinned to main `b88fcfcd97e73129cf889919c289b487e98829e8`; further upstream movement is outside this integration cycle. Separate merge `b42eba357515793c834fec7d9125907ca106a22f` preserves its accepted camera-aware forecasts, theme, geometry/native tests and notification-planning documentation. It does not change Core, Store, canonical cadence fixture or ceremony code relative to `5e56d5a`. Updater/CI remain byte-identical to pinned main. Task 6's existing committed `5e56d5a` export/worktree/simulator were not modified by this merge.

View conflict resolution composes the cue sibling and ceremony gating with the incoming placement guard and forecast parameters. A has no cue slot and retains the calibrated camera/header selection. B's fixed slot changes the offered viewport/top inset; the inherited conservative camera guard may select the header fallback. No forced camera placement or pilot flag is added. Follow-up native acceptance must inspect A on calibrated hardware, B cue/header coexistence, largest text, forecast labels and touch/render alignment. Prior-source captures are not evidence of that interaction.

Clean `b42eba3` passes 72 Core tests, normal Debug/Release arm64 simulator builds, export integrity and the exported Debug build. Raw logs `/tmp/starfall-pacing-forecast-{core,debug,release,export-debug}.log`. Export: `python3 tools/mechanics/prepare-pacing-candidate.py --source b42eba357515793c834fec7d9125907ca106a22f --output <new-directory>`. Existing `/tmp/starfall-pacing-forecast-b42eba3` is a successful frozen export; no install performed. Export checks verify unchanged rules/store/ceremony/fixture and inherited updater/CI files; fixture hash remains the same. Hygiene and whitespace pass. Combined hosted/native acceptance is still pending on the explicitly named sources, not inferred from builds.
