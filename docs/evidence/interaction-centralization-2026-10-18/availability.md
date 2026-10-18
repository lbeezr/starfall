# Shared availability without broader input locks

**Result:** Verified development checks · **Owner:** current implementer · **Date:** October 18, 2026

`SkyInputPolicy` returns one global or column availability reason to contact, clear, trace and technique admission. Core still validates legality, and generation/snapshot tickets still reject stale commits. The existing Boolean contracts wrap this policy, so physical, native-button and accessibility routes continue to share store admission. Only rejection copy changes: a due shower is described as arriving rather than as settling stars.

**Next action:** Merge separately for issue #78, then implement interruption teardown.

| State | Expected shared behavior |
| --- | --- |
| Explicit pause | Taps, traces and techniques remain available under their own rules. |
| Settings/background suspension | Shared global rejection. |
| Finished sky | Shared global rejection; result controls retain ownership. |
| Shower already due | Reject new actions until its committed delivery; never queue a coordinate. |
| Moving columns | Reject affected targets/committed turn columns; unrelated ready columns remain usable. |
| Empty trace | Unavailable selection, independent of legal-clear explanation. |
| Whole-board controls | Retain their broader readiness contract; not a replacement for per-cell admission. |

Tests target independent completions/save order, paused play, affected versus unrelated columns and a deferred shower that commits once without replaying rejected input. No rule, save, clock, geometry, artwork or motion changes. Initial checkpoint: 149 Core and 79 hosted checks passed, including FallingSkyStoreTests (41), ResponsiveInputTests (10), SkyTechniqueStoreTests (10), StarlightCelebrationTests (6) and TraceInputPolishTests (12). The Debug simulator test build passes. Those native checks are superseded by final validation below; physical feel and actual VoiceOver remain separate acceptance.

Source: main `e4c8f2b` plus [snapshot e0d85ed68e5d](source-availability.json); only FallingSkyStore.swift and ResponsiveInputTests.swift affect this batch's build. Same Xcode 27.1/Swift 6.4, Forecast QA iPhone 17e/iOS 27.0/arm64 configuration and signed Debug command as [session verification](session.md), selecting the five hosted suites above. Core uses `swift test`. Raw logs: `/tmp/starfall-availability-core.log` and `hosted-recovered.log` with that prefix.

The first hosted launch failed during simulator boot before tests. Both simulator lists and launches then hung. A one-second process sample of CoreSimulatorService showed all 64 dispatch threads blocked. Graceful termination could not exit that daemon; forced restart restored requests. Existing simulator runtime processes exited, and only Forecast QA was rebooted for this run; no device data was erased. Abandoned local spawn/list/create commands were cancelled. The recovered run passed unchanged assertions. Raw infrastructure diagnostic: `/tmp/starfall-core-service.sample`; initial launch output: `/tmp/starfall-availability-hosted.log`. This recovery changed no app source or delivery tooling.


## Native isolation and current-main reconciliation

The initial native run passed tap drift, cancellation recovery and empty-opening controls, but its automatic-opening runner was killed by signal 9 during a dynamic element query, without an assertion result. Diagnostic session logs identify the runner PID; the app was not reported as crashing. Another worktree's hosted test had targeted Forecast QA concurrently; the kill's origin is unconfirmed. The unchanged-main `e4c8f2b` baseline passes that method. Restored the candidate files byte-for-byte (snapshot e0d85ed68e5d), created/booted a dedicated iPhone 17e `BBB2B108-1A26-45E6-9A59-5C572306BD4B` named Starfall Input Centralization QA, and ran the same assertions there. No skips, timing-assertion changes or animation suppression were added. Initial failed-run and clean-baseline result bundles remain under `/tmp/starfall-availability-{native,baseline-opening}.xcresult`; diagnostic logs are in `/tmp/starfall-availability-diagnostics`.

The dedicated run passed three sibling cases but the opening assertion failed: the broad first-legal query was retried while waves changed, taking about seven seconds between first query and event. Its target reached a different timing boundary before the real tap. Pinning the resolved native cell identifier removes repeated dynamic selection; it retains score gain, pre-fourth-shower, full-motion and rapid-input assertions. This is a test-driver correction, not a coordinate queue or relaxed gameplay requirement. Final revalidation follows below.


## Final verification on current main

Reconciled onto `ac6aeb3` (including main's nested score-anchor correction). [Final snapshot 5fd9fcaea1a6](source-availability-reconciled.json) identifies the two changed Swift app/hosted files and the stable-identifier native test change. Final 149 Core, 80 hosted and four native tests pass with zero skips/failures. The Debug simulator test build passes; no target membership changes. Hygiene and diff checks pass. Release is not repeated for this policy-only extraction; no routing, resources, build settings or Debug fixtures changed.

Final native cases: `FallingSkyInteractionTests/testOpeningCascadeAllowsNativeClearBeforeLastWave`; both `ResponsiveInputUITests` methods; `SkyTechniqueInteractionTests/testEmptyOpeningKeepsShowerControlsUntilStarsArrive`. The first checks a real clear before the fourth wave, full motion, rapid taps and menu dismissal, restoring the original system preference afterward. Drift clears once at normal and largest text; incomplete drawing cancels and permits a subsequent tap. No automatic coordinate replay. [Compact native summary](native-availability.json).

Final hosted suites/counts: FallingSkyStoreTests 41, ResponsiveInputTests 10, SkyTechniqueStoreTests 10, StarlightCelebrationTests 7, TraceInputPolishTests 12. Commands follow the signed Debug invocation in [session evidence](session.md), using dedicated device `BBB2B108-1A26-45E6-9A59-5C572306BD4B` and the selectors above; native adds `-test-timeouts-enabled YES -maximum-test-execution-time-allowance 180 -resultBundlePath /tmp/starfall-availability-final-native.xcresult`. Toolchain/OS remain Xcode 27.1, Swift 6.4, iOS 27.0 (24A434), iPhone 17e/arm64. Raw final logs: `/tmp/starfall-availability-reconciled-{core,hosted}.log`, `/tmp/starfall-availability-final-native.log`.

Rules, save compatibility and committed clocks retain their existing owners and test coverage. No actual VoiceOver or physical-device gesture measurement. No new UI layout/artwork; the selected capture index is unchanged by this batch. Rendered Markdown not inspected.
