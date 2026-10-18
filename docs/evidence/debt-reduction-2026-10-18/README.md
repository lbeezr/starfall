# Independent technical debt reductions

**Result:** Partially verified · **Owner:** current implementer · **Date:** 2026-10-18

Six independent batches are merged in PRs #108–#113: save recovery, native diagnostics, coordination, measured input work, historical mechanics and build gates. Deterministic replay and scoped native checks pass. RC remains blocked by unavailable iOS 17 coverage and a tablet largest-text Welcome failure; historical intermittency remains cause-unknown. No gameplay/save-schema/RNG change.

**Next action:** follow the active tablet/minimum-OS/physical RC blockers; canonical device delivery waits for the configured iPhone. [Plan](../../TECH_DEBT_PLAN.md).

## Task 1 — save recovery

Source: `be75cc5` plus `App/SkySaveArchive.swift`, `App/FallingSkyStore.swift`, `AppTests/SkySaveArchiveTests.swift`; documentation does not affect the build. Xcode 27.1 (27A9275), Debug, Starfall Forecast Fallback QA / iOS 27.0, simulator `1E9DCEF5-BF64-4052-AF8D-A6A205F711EE`.

| Check | Result |
| --- | --- |
| `swift test` | 162 passed, zero failures. |
| `python3 scripts/ci-hygiene.py`; `git diff --check` | Passed. |
| `test_sim`, only SkySaveArchiveTests and FallingSkyStoreTests | Initial 50 passed; final archive suite including failed-encoding regression: 10 passed. |
| `test_sim`, SkyFlowInteractionTests/testWelcomeEntryBackgroundAndAnotherSky | Passed; native clear, background, retained round, relaunch, Continue and new-sky staging. |
| Debug simulator compilation | Passed as part of both native test runs. |

Native commands used the shared Starfall scheme, sequential testing, ad-hoc simulator signing (`CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual`). Raw logs/results are under the ignored XcodeBuildMCP workspace `~/Library/Developer/XcodeBuildMCP/workspaces/Starfall-614375984f0e/`; portable logs under ignored `artifacts/debt/`.

Root cause: the optional load result collapsed rejection and absence; activation then wrote the replacement. Examined current and retained-key precedence, initialization, activation, restart and encoding-failure paths. Tests cover corrupt data, wrong types, future schema, old bytes, no downgrade and failed encoding. The recovery slot intentionally retains only the most recent rejected value; no automatic repair or recovery UI is added. UserDefaults offers no synchronous disk-durability acknowledgement; `saveFailed` reports encoding/validation failure, not disk health.

Visual/animation changes: none. Actual VoiceOver: deferred to RC; not run on this development build. Physical device delivery: updater reported waiting for configured iPhone; no installation claimed.

## Task 2 — native acceptance diagnostics

Source: task-1 main `513f9cc`; test-only changes in `AppTests/DuskProductionTests.swift` and `UITests/FallingSkyInteractionTests.swift`. Same Xcode, Debug and iOS 27.0 simulator as task 1.

The original First Light win/replay/full-sky/restored-ending method and the existing CrystalCelebrationArtwork, DuskProduction and StarCast suites passed: **34 tests, zero failures/skips**. This includes the original full-motion collapse; the historical failures did not reproduce. No gameplay synchronization change is justified by this result.

The final test patch splits Dusk's completion/well/infall/arrival assertions into separate diagnostic messages and explicitly runs its normal-motion collapse/cancellation contract after the two existing StarCast material-sheet methods. First Light's original five-second settle assertions now include app state, board summary, score, outcome presence and Next existence/enabled state. No retries, relaxed waits, removed checks or forced reduced motion.

Final diagnostics/mixed-order run: **9 passed, zero failures/skips**, including the unchanged First Light assertions and the explicit material-sheet sequence. Debug simulator compilation passed. `swift test`: 162 passed. Updater behavior checks: 21 passed; native matrix policy: 3 passed. These scripting checks do not establish device installation. Actual VoiceOver remains deferred to RC. The root cause of the historical intermittency remains unknown; a failing future run now identifies the phase and preserves native state instead of giving a combined assertion alone.

## Task 3 — separate dialogue selection and presentation tickets

Source: task-2 main `879788b` plus `App/FallingSkyStore.swift`, `App/FallingSkyPresentation.swift`, `App/SkyDialogueLibrary.swift` and `AppTests/SkyPhasePresentationTests.swift`. No target membership changes: all owners were already target members. Same Debug simulator/toolchain as task 1.

`SkyDialogueLibrary.result` reads only committed turn/game values and narrow trace/recipe/relay inputs. It has no store or session reference. `SkyPresentationLedger` owns ticket epochs, outstanding turns, pending forecast precedence and changing-column reservations; it cannot schedule, save or render. The store retains input generations, single deadline, session/speech policy, and save-before-animation ordering. The original result precedence and simultaneous presentation behavior are preserved.

Core: 162 passed. Hosted Store, ResponsiveInput, SkyPhasePresentation, SkyDialogue, StarlightCelebration and SkyTechnique suites: **96 passed, zero failures/skips**. A new behavioral check covers two outstanding turns, reverse completion, duplicate completion, invalidation and stale completion against a replacement. Debug simulator build passed. Native responsive-input suite: **2 passed**, covering small-drift taps at normal/maximum text and incomplete-trace cancellation followed by a valid tap. Hygiene/diff checks passed. Initial compilation caught an omitted trace-count input during extraction; it was corrected before successful verification. No gameplay/save/visual contract changes. Actual VoiceOver deferred to RC.

## Task 4 — avoid idle admission simulations

Source: task-3 main `1de9a6a`, first with only the new dense admission characterization in `AppTests/ResponsiveInputTests.swift`, then with two idle exits in `App/FallingSkyStore.swift`. Same Xcode 27.1 / Debug / iOS 27.0 simulator.

Reproducible scenario: restore `ObservatoryReviewFixture.game(dense: true)`, activate while paused, and query all 49 cells 100 times (4,900 clear queries and 4,900 nonempty trace queries). Admission checks must allow invalid/empty targets to reach Core explanations; empty traces and suspension retain their explicit reasons. Snapshot/archive must remain unchanged.

| Measurement | Before | After |
| --- | --- | --- |
| Entire assertion/query loop | 0.078438 seconds | 0.003708 seconds |
| Clear admissions | 4,900 | 4,900 |

This is a bounded simulator CPU characterization, not an Instruments device trace, FPS measurement or battery claim. The baseline precedes the production edit. Without outstanding presentations there are no reserved columns, so action simulation cannot affect admission. Busy-board simulations and all actual commit/snapshot/generation checks remain unchanged. No cache or duplicate Core legality implementation was added.

Core: 162 passed. Hosted ResponsiveInput, NativeInputWindow, TraceInputPolish and FallingSkyStore suites: **78 passed, zero failures/skips**; includes due/contact order, partial columns, pauses and stale input. Debug simulator build passed. Native stationary hold and Settings/background gesture recovery: **2 passed**, zero failures/skips. Hygiene/diff checks pass. Actual VoiceOver deferred to RC; no physical-performance claim.

## Task 5 — isolate historical mechanics and neutral shared presentation

Source: task-4 main `370eb3d` plus the Core/app paths in this batch. New Core files are automatically included by the local Swift package; no app file was added. Same Debug simulator/toolchain as task 1.

Historical collision, rotation/release, identity accounting and validation now live in `HistoricalGravityState`, a value with board/orbit/allocator inputs. It cannot access a game store, clock, score, save or RNG. FallingSky retains every encoded property and applies that state at its committed boundary. Current/old stable compaction shares `SkyBoardSettling`, replacing the duplicate ordinary-clear loop. Shared collapse/orbit snapshots and timing use `SkyPresentationPhase` / `PhaseTimeline`; old public phase spellings remain compatible. Historical fixtures and raw replay are retained deliberately, not routed into normal play.

Core: **162 passed**. Hosted gravity, Dusk, critical mass, archives, native input-window and responsive-input checks: **52 passed**, zero failures/skips. Final neutral-name compilation/native critical-mass/retained-Dusk checks: **12 passed**, zero failures/skips. Covers warning/swallow/restore/settings, rescue scoring, maximum-text calm/help, actual system Reduce Motion outcome, retained full-motion collapse and stale cancellation. Hygiene/diff checks pass.

A separately compiled before/after driver (`swiftc -DDEBUG` with all Core sources and the adjacent `main.swift`) compares pre-refactor main to this Core. It emits sorted JSON round trips across all five generation IDs at seeds 5/28/180, all gravity fixtures, retained Dusk, current critical mass and First Light, both raw and gravity-retired/feeding-adopted, plus replay. **1,337 archives on each side are byte-identical.** Raw output/executables are disposable under `/tmp/starfall-debt-replay/`; the small driver is retained here for reproduction. This supplements rather than replaces the hosted envelope-migration tests.

No rule/save/geometry/artwork/timing change is intended. Actual VoiceOver remains deferred to RC; no device/performance acceptance is claimed. The first replay harness attempt used a Python tarfile option unavailable on the host; rerunning with the trusted local Git archive and the supported API completed the comparison.

## Task 6 — Release gate and explicit RC platform ownership

Source: task-5 main `9903d7f`; changes only to CI scripts/workflow and documentation. Runtime sources/resources are unchanged. Xcode 27.1, iOS 27.0.

Every existing native CI job now also builds Release and checks its compiled catalog. The same public-main/manual-budget trigger, runner count, permissions and 35-minute bound remain. Manual runs expose dev/rc selection. The iPhone matrix names the one tablet-only exclusion explicitly; RC owns that test on an iPad and still restores all six actual-VoiceOver sessions.

`rc-platforms.py` selects by real device type and runtime, including renamed QA devices. It requires an installed iOS 17 iPhone and iPad, preflights before expensive RC work, runs three focused native tests per role with subprocess/test timeouts, and checks exact pass counts with zero failures/skips. It performs no downloads. The existing complete physical-iPhone VoiceOver gate remains separate.

| Check | Result |
| --- | --- |
| Release simulator build via `build_sim`, shared scheme, ad-hoc signing | Passed, 22.5 s. |
| Packaged Release bundle ID, LaunchScreen declaration, Assets.car and matching privacy manifest | Passed on actual compiled bundle. |
| Core | 162 passed. |
| Updater / native matrix / RC selector-count-command policy tests | 21 / 3 / 5 passed. |
| Workflow YAML / Bash syntax / hygiene / diff | Passed. |
| Real RC inventory preflight | Correctly **blocked**: this Mac has iOS 27.0/27.1, no iOS 17 runtime. Minimum OS is unverified. |
| iPad mini (A17 Pro), Starfall Observatory Tablet QA `147FF35E-5EAE-4676-B941-B82BE8119054`, Debug / iOS 27.0 | **2 passed, 1 failed, 0 skipped.** Landscape Welcome/Entry/preferences and largest-text critical-mass/help passed. Largest-text Welcome failed the existing `isHittable` assertion for Settings (`SkyFlowInteractionTests`, helper line 675). |

The tablet failure remains an RC blocker; no assertion was removed or weakened. The inspected `flow-largest-welcome-actions-first` capture shows Settings visibly present, but that does not prove physical activation or identify whether native hit testing, orientation or the AX result is responsible. Original XCTest result and exported screenshots/movie remain under the ignored XcodeBuildMCP workspace and `/tmp/starfall-debt-tablet-attachments/`. Do not close it from the separate landscape pass. Trigger: next tablet/Welcome/RC change; compare actual activation, frame/orientation, scroll and focus with this exact largest-text failure before changing geometry or assertions. No source/UI workaround is bundled into the CI task.

The complete remote CI job was not rerun locally (it owns its disposable-runner setup); its constituent new build/planning/policy checks were run. No full RC or physical-device acceptance is claimed. Actual VoiceOver deferred to RC. The automation enforces missing coverage instead of declaring support from one newest-OS phone.

## Task 7 — active engineering register

Source: task-6 main `71b3c7b`; documentation-only changes. The new active index names present risks, priorities, triggers and closure checks, links each shipped reduction, and keeps minimum-OS/tablet/physical acceptance visible. The original dated follow-ups remain intact beneath a historical disclosure; stable engineering guidance remains available above it. The obsolete duplicate-coordinate-mapping claim is corrected against the existing `ObservatoryGeometry` owner. README/roadmap link the active index and no longer prescribe the old Xcode-drift fix despite verified current builds.

No app/code/resource/test behavior changes. Hygiene/diff checks passed; all 15 new local Markdown link targets exist. A fresh all-hosted run on combined main `71b3c7b` (only documentation dirty) passed **259 tests, zero failures/skips** on the original Debug / iOS 27.0 QA iPhone. This additional integration evidence does not replace the failed tablet result. Markdown rendering was not checked in a dedicated document viewer. This technical register needs no new product concept or artwork.
