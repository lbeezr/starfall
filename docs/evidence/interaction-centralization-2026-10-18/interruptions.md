# Shared interruption teardown with explicit clock ordering

**Result:** Verified development checks · **Owner:** current implementer · **Date:** October 18, 2026

`interruptPlay` freezes the single deadline, then delegates to feedback stop and presentation settling. Layout and motion call that presentation-only boundary directly, preserving clock phase. Callers still own pause/suspension flags, committed game replacement, cadence changes and saves. Balance changes now stop sound tails through the same cleanup; they freeze before changing cadence and settle afterward. No rules, saves, RNG or catch-up scheduling change.

**Next action:** Merge this third batch for issue #79, then route trace feedback through the existing feedback owner.

## Lifecycle contract

| Caller | Clock and state ordering |
| --- | --- |
| Pause, restart, challenge, Debug fixture replacement | Choose paused state, freeze, stop feedback, invalidate input and pending presentation, then replace/reset as applicable. |
| Settings/background/scene detachment | Set suspension before freeze/cleanup; resume retains the existing explicit arm/save path. |
| Balance | Freeze; commit the changed balance/cadence and interval; stop feedback and settle; save and arm once. |
| Layout and motion | Stop feedback and settle without resetting clock phase. Motion sets the presenter preference before settling. |
| Settling | Existing input-generation, celebration cancellation, presentation-epoch and render boundary; stale completions cannot choose a committed outcome. |

The new focused test covers restart, First Light, balance, suspension, motion, layout and both Debug fixture loaders; each retires held tickets/old rain callbacks, stops sound once and preserves committed state/deadline on repetition. Existing clock, presentation and celebration regressions cover pending/expired work. Temporary/failed checks remain visible below.

## Verification

149 Core tests pass. The initial 81-hosted run passed the new eight-path teardown check, but the unchanged direct SpriteKit exchange test completed before the polling loop observed its intermediate sideways/falling phases. This direct-scene test does not call the changed store teardown. It started the timed exchange before the new SKView had delivered an update. Added a bounded first-update sentinel action before timing starts; it is an expectation-based test-host readiness check, not a sleep or animation suppression. All completion, intermediate-motion, exact-position, quiet-outcome and concurrent-turn assertions remain. Final 81-hosted revalidation passes, including intermediate full-motion samples. The initial readiness probe selected an async SDK overload; switched to the keyed synchronous action overload before the passing run. Final native verification passes as recorded below.

Source: main `5bec506` plus [snapshot 76caa0e5bac3](source-interruptions.json). Only FallingSkyStore.swift, TraceInputPolishTests.swift and the test-host readiness change in SkyTechniqueStoreTests.swift affect this build. No target membership change. Same Xcode/Swift/iOS and dedicated QA simulator as [availability verification](availability.md); signed Debug commands select the same five hosted suites, with `swift test` for Core. Raw logs: `/tmp/starfall-interruptions-core.log`, `hosted.log`, `hosted-frame.log` with the same prefix. Actual VoiceOver and physical-device haptic/gesture acceptance remain unverified under the development cadence.


## Final acceptance

149 Core, 81 hosted and three native checks pass, with zero final failures/skips and a passing signed Debug test build. Native selectors: `FallingSkyInteractionTests/testSystemReduceMotionKeepsManualPlayWorking`, `SkyFlowInteractionTests/testFirstLightWinReplayAndFullSky`, `SkyTechniqueInteractionTests/testSettingsAndBackgroundCancelSelection`. The flow checks two bounded rounds, win/replay/full-sky loss, persisted ending restore and fresh-entry controls. Motion preferences are restored after the native checks. [Native summary](native-interruptions.json). No game or save outcome is derived from animation completion.

Hosted suites: FallingSkyStoreTests 41, ResponsiveInputTests 10, SkyTechniqueStoreTests 10, StarlightCelebrationTests 7, TraceInputPolishTests 13. The new eight-path held-ticket test, pending presentation/celebration expiry and the first-update-corrected full/quiet exchange test all pass. Initial failures and the SDK-overload compile correction are retained above; no assertion changes or blanket retries. Raw final logs: `/tmp/starfall-interruptions-hosted-ready.log`, `/tmp/starfall-interruptions-native.log`; bundle `/tmp/starfall-interruptions-native.xcresult`.

Commands use the signed Debug invocation in [session evidence](session.md), dedicated simulator `BBB2B108-1A26-45E6-9A59-5C572306BD4B`, and selectors above. Native adds `-test-timeouts-enabled YES -maximum-test-execution-time-allowance 240 -resultBundlePath /tmp/starfall-interruptions-native.xcresult`. Configuration/OS: Debug, arm64, iPhone 17e, iOS 27.0 (24A434), Xcode 27.1 / Swift 6.4. Release is not repeated in this batch; the final feedback batch will build the combined Release source. Hygiene/diff checks pass; no new target members, artwork, layout or selected-capture changes. Rendered Markdown not inspected. Actual VoiceOver and physical device feel remain unverified.
