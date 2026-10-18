# Independent technical debt reductions

**Result:** Partially verified · **Owner:** current implementer · **Date:** 2026-10-18

Task 1 preserves rejected archives through activation/restart without falling back to an older round. One recovery slot is bounded by count; it preserves the exact rejected property-list value. Encode/validation failure leaves both slots untouched. No save schema, rule, RNG, navigation or artwork change.

**Next action:** publish task 1 and reproduce the native failures in task 2. [Plan](../../TECH_DEBT_PLAN.md).

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
