# Trace feedback uses the existing device-feedback owner

**Result:** Verified development checks · **Owner:** current implementer · **Date:** October 18, 2026

The view now sends trace selection values and count changes through the store's injected feedback capability. `GameFeedback` owns both announcement transport and the bounded selection generators. Generation/hold checks reject cancelled or replaced speech; live contact ownership and shared preferences gate selection haptics. Wording, count-five readiness intensity and ordinary step intensities are preserved. The existing announcement owner stops sound before VoiceOver speech. No new delayed task or speech queue is introduced.

**Next action:** Merge the fourth separate PR for issue #80; observe physical feel at the next device playtest and actual VoiceOver at RC.

## Acceptance and extent

- Exact existing selection/cancellation wording reaches injected feedback once per synchronous event.
- Released/replaced hold tickets, restart generations and suspended input cannot announce a stale selection.
- Selection haptics require active input and honor the stored haptic preference and quiet presentation; the device owner also checks system Reduce Motion and VoiceOver.
- Feedback cannot mutate rules, score, committed save bytes or shower scheduling.
- Fast physical traces/swaps, largest text and automatic-shower menu/background/resume remain usable; actual VoiceOver and physical haptic quality remain RC/device acceptance work.

Reviewed every explicit `UIAccessibility.post`, impact/notification generator and feedback call site under App. Direct trace announcement/generator calls are removed from FallingSkyView, including its UIKit import and private hardware-feedback state. The sole explicit announcement post and all haptic generators now live in GameFeedback. Native focus/label semantics and the original puzzle's feedback interface retain their owners. Speech already handed to iOS remains outside this synchronous cancellation gate; no claim of cancelling OS-queued speech or hardware feel.

## Verification

149 Core and 94 hosted checks pass. Hosted counts: FallingSkyStoreTests 41, QuietTuckPlayerTests 11, ResponsiveInputTests 12, SkyTechniqueStoreTests 10, StarlightCelebrationTests 7, TraceInputPolishTests 13. New regressions cover exact messages, old holds/generations, preference/quiet flags and unchanged committed game/save data; existing sound, clock, motion, input and celebration checks pass. Debug simulator test build passes; no new target members.

Source: main `90ef9ed` plus [snapshot 4f434858464f](source-feedback.json). Dirty build inputs are limited to FallingSkyStore.swift, FallingSkyView.swift, GameFeedback.swift and ResponsiveInputTests.swift. Same Xcode 27.1 / Swift 6.4, dedicated iPhone 17e/iOS 27.0 (24A434)/arm64 simulator and signed Debug invocation as [availability evidence](availability.md), selecting the six suites above. Core command: `swift test`. Raw output: `/tmp/starfall-feedback-core.log` and `/tmp/starfall-feedback-hosted.log`.

Four native checks and the combined Release simulator build pass, with zero native failures/skips. Native selectors: `ConstellationTraceNativeTests/testNativeSwipeClearsChosenFiveAndLeavesSixth`, `testBuildIDMenuAndLargestTextTrace`; `SkyTechniqueInteractionTests/testSwipeAndHoldSwapsWithoutArrangeAndEmptyDestinationFalls`; `ShowerForecastInteractionTests/testCadenceForecastMenuBackgroundAndSafeAreaFallback`. These cover a selected-five fast swipe, largest-text drawing/menu dismissal, held/flick/empty-destination exchange, and real automatic-shower menu/background/resume plus accessible forecast fallback. The prior interruption batch separately covers full win/loss/replay and system Reduce Motion. [Native summary](native-feedback.json).

Final native uses the signed Debug command above with those selectors and `-test-timeouts-enabled YES -maximum-test-execution-time-allowance 180 -resultBundlePath /tmp/starfall-feedback-native.xcresult`. Raw output: `/tmp/starfall-feedback-native.{log,xcresult}`. Release command: `xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/starfall-input-release CODE_SIGNING_ALLOWED=NO build`; raw `/tmp/starfall-feedback-release.log`. Hygiene and diff checks pass. No failing check in this final batch. No new UI layout/artwork or affected capture-index entries. Routine images stay disposable; rendered Markdown not inspected. Actual VoiceOver is intentionally not run during this development iteration.
