# One logical contact owns trace, swap and hold cleanup

**Result:** Verified development checks · **Owner:** current implementer · **Date:** October 18, 2026

`SkyInteractionSession` owns the trace, technique selection and shower-hold ticket. UIKit still owns physical contacts; the store still owns the single deadline and committed generations. No rule, save, hit-target, dwell or drawing-threshold changes are included. This extraction addresses distributed cleanup observed in source review, not an additional reproduced gameplay failure.

**Next action:** Merge this extraction, then centralize shared input availability in a separate PR.

## Ownership and acceptance

| Transition | Owner and invariant |
| --- | --- |
| Eligible contact | Session acquires one store ticket; repeated acquisition retains it. |
| Drawing to swap | Session replaces trace selection with swap selection without releasing the ticket. |
| Release/cancel | Session clears local contact state before returning the ticket exactly once. |
| Stale release | A mismatched terminal ticket cannot affect a replacement contact. |
| Lifecycle invalidation | Session cancels both selections; recognizer configuration and store generations retain their independent stale-callback guards. |
| Explicit arranging | Contact cancellation keeps arrange selection; lifecycle invalidation cancels selection while preserving the chosen mode. |

The moved `ConstellationTraceIntent` is otherwise unchanged. The view retains point mapping, rendering and synchronous commit ordering, passing narrow acquire/release capabilities instead of the whole store.

## Current-main reconciliation

After the initial checks below, main merged calibration and celebration work in PRs #81/#82. Rebased onto `1952312`, preserving empty-sky technique reconciliation and the new celebration boundary. The session now delegates committed-game reconciliation to `SkyTechniqueIntent.reconcile`, with a focused empty-sky regression. Final [source snapshot 258a5b053281](source-session-reconciled.json) includes every changed runtime/test input; no unrelated dirty build inputs.

Final checks: 149 Core, 36 hosted (the prior three suites plus six StarlightCelebrationTests; current SkyTechniqueStoreTests has ten cases), four native, Debug build and Release simulator build pass. Final native methods are the same fast rim swipe, held swap and settings/background methods below, plus `SkyTechniqueInteractionTests/testEmptyOpeningKeepsShowerControlsUntilStarsArrive`. [Final native summary](native-session-reconciled.json) reports four passes and zero failures/skips. Final checks use the same Forecast QA device and toolchain described below. Raw final output uses `/tmp/starfall-session-reconciled-{core,hosted,release}.log` and `/tmp/starfall-session-reconciled-daemon-native.{log,xcresult}`. Native uses bounded 120-second execution allowances.

A native attempt failed before any test with an AX-loaded initialization timeout; an alternate existing Compact QA device also stalled before tests and was interrupted. Restarting only the Forecast simulator's testmanagerd restored execution; the unchanged tests then passed. An attempted dedicated simulator creation stalled and was interrupted; no new simulator was registered. No existing simulator was erased, shut down or reset. These are infrastructure failures, not passing interaction evidence. No blanket retries or weakened assertions.

## Initial verification before reconciliation

149 Core, 29 affected hosted and five native tests pass, with zero native skips/failures. Debug test build and Release simulator build pass. Existing Xcode target members contain the extraction; no membership changes. Hygiene and diff checks pass.

Native methods: `ConstellationTraceNativeTests/testNativeSwipeClearsChosenFiveAndLeavesSixth`, `testShortTraceAndOutsideReleaseCancelThenOrdinaryTapWorks`; `SkyTechniqueInteractionTests/testSwipeAndHoldSwapsWithoutArrangeAndEmptyDestinationFalls`, `testSettingsAndBackgroundCancelSelection`, `testLargestTextRecipeActionsRemainReachable`. Hosted suites: TraceInputPolishTests (12), ResponsiveInputTests (8), SkyTechniqueStoreTests (9). These cover physical drawing/partial/outside release, flick versus hold, empty-destination falling, follow-up tap, settings/background cancellation, stale ownership, largest text and scrolling. Full win/loss and system Reduce Motion are deferred to the interruption batch; Core outcomes are unchanged.

Source: base `70cd96b` plus [snapshot a88d637f204f](source-session.json). No other dirty runtime inputs. Xcode 27.1 (27A9275), Swift 6.4; iPhone 17e / Starfall Forecast Fallback QA `1E9DCEF5-BF64-4052-AF8D-A6A205F711EE`, iOS 27.0 (24A434), arm64, Debug. Technique fixtures request full effects; trace fixtures retain their preference. System motion was unchanged. Release targets generic arm64 simulator. No phone installation or actual VoiceOver session; no measured physical latency.

Commands: `swift test`; `xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=1E9DCEF5-BF64-4052-AF8D-A6A205F711EE' -derivedDataPath /tmp/starfall-input-derived -parallel-testing-enabled NO -collect-test-diagnostics never ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual test` with `-only-testing:<target>/<suite>/<optional method>` above. Native adds `-resultBundlePath /tmp/starfall-session-native.xcresult`. Release uses `-configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/starfall-input-release CODE_SIGNING_ALLOWED=NO build`.

Raw logs: `/tmp/starfall-session-{core,hosted-final,native,release}.log`; [compact native summary](native-session.json). The initial hosted compile caught an incorrect test-fixture name; corrected before passing checks. A prior hosted run on Physics Review stalled before tests and was interrupted; final checks ran on Forecast QA with current source. No weakened assertions or test retries.

Inspected exported native `trace-five-from-six` and `technique-largest-text-selected-controls`: the survivor and score remain visible; the wrapped recipe copy and Clear square/Cancel actions remain readable and reachable after scrolling. Routine PNGs stay in `/tmp/starfall-session-attachments`. No layout/artwork or capture-index change; existing selected captures remain source-bound. Stills do not establish motion quality. Rendered Markdown not inspected.
