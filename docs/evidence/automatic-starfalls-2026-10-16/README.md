# Automatic starfalls validation — 16 October 2026

Device: dedicated **Starfall Accumulation Lab**, iPhone 17 Pro, iOS 27 simulator, UDID `FBB33D71-C642-4705-B63F-F71A3A7CA62C`. Xcode 27, arm64 simulator builds, shared `Starfall` scheme. No physical-device validation is claimed.

## Automated checks

- `swift test --scratch-path /private/tmp/starfall-automatic-swift`: **41 tests passed**, including 14 experiment rule tests. Clears preserve the preview and future random sequence, all four shower sizes occur, growth and gravity preserve identity/value, overflow is ordered, and saves/replay remain deterministic.
- Native app suite: **52 tests passed**, including seven experiment store tests with a controllable monotonic clock. Checks cover independent deadlines, invalid/rapid input, a due shower during a clear, pause/background without catch-up, stale timer/animation callbacks, restore/replay, Calm effects and stopping the clock at overflow.
- Native UI `testBackgroundRelaunchAndAutomaticOverflow`: **passed**. Actual four-second scheduling, background/resume, paused restoration, unattended overflow and New sky were exercised.
- Native UI `testAutomaticRainPauseGrowthClearReplayAndSettings`: **passed on focused rerun**. Actual automatic arrivals, pause across an interval, a grown-value clear with rapid input, settings accessibility isolation, Calm effects, dismissal and identical replay preview were exercised.
- Debug and Release simulator builds passed. A final Debug rebuild also passed after reserving feedback height to keep the pause button from moving between one- and two-line messages.
- `git diff --check`: passed.

The first combined UI run passed the background/overflow test but missed a double tap at the next arrival boundary. Its screenshot showed only one second remaining; accessibility queries and screenshot capture had consumed the available clear window. The test now captures while paused and resumes early in a fresh interval before double tapping. The focused rerun passed. App behavior was unchanged for this test correction. The screenshot-height adjustment was made afterward and rebuilt; the UI suite was not rerun for that layout-only adjustment.

## Native and browser inspection

The native app was played through the local `serve-sim` browser mirror, pinned to the same simulator. A grown mint beside a small mint cleared for **3 starlight** while the automatic sky ran. A five-star preview fitted in the forecast panel, paused sky stayed stationary, settings dismissed, and replay returned to an empty board.

VoiceOver was enabled on the simulator and visible focus plus the native accessibility tree were inspected. The forecast exposed shape/color and column labels; cells exposed position and connected value. This is not a full spoken-navigation or Matching groups rotor validation. Calm effects was validated in the native UI test. System Reduce Motion was then enabled on the simulator and an automatic shower was observed in the final build; see `browser-reduce-motion.png`. The browser manual-play image records the 3-starlight clear and ongoing accumulation. Baseline win/last-move precedence remains covered by the unchanged core tests; this accumulation experiment has an overflow outcome and no win target.

Screenshots exported from native XCTest attachments:

- `automatic-empty-preview.png`
- `automatic-matchable.png`
- `automatic-after-clear-paused.png`
- `automatic-calm-after-dismissal.png`
- `automatic-overflow.png`

## Reproduction artifacts

The temporary result bundles are `/private/tmp/starfall-automatic-host.xcresult`, `/private/tmp/starfall-automatic-ui.xcresult` (initial mixed result), and `/private/tmp/starfall-automatic-clear-ui.xcresult` (successful focused rerun). Build and test logs use the same `/private/tmp/starfall-automatic-` prefix. Temporary bundles are not committed.

Example native invocation:

```sh
xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug \
  -destination 'id=FBB33D71-C642-4705-B63F-F71A3A7CA62C' \
  -derivedDataPath /private/tmp/starfall-automatic-native \
  -parallel-testing-enabled NO \
  -only-testing:StarfallUITests/StarfallExperimentInteractionTests \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES test
```

These checks establish mechanics, lifecycle behavior and basic interaction. They do not establish long-session balance, performance on physical hardware, or whether four seconds is the right pace for a relaxing game.

## Handoff

The final Debug build is installed on the dedicated simulator. The local browser mirror is `http://localhost:3200/?chrome=0`, left at an empty, paused sky with Calm effects, system Reduce Motion and VoiceOver off. `browser-ready.png` shows the final live frame. `browser-manual-play.png` shows a scored group clear during accumulation, and `browser-reduce-motion.png` shows automatic arrivals under system Reduce Motion. The mirror occasionally reconnected during background browser inspection; no physical-device or frame-time performance claim is made.
