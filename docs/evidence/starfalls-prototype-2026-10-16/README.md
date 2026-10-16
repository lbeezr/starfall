# Turn-based accumulation prototype — 16 October 2026

This evidence covers the native Debug experiment described in [the prototype rules](../../design/STARFALL_ACCUMULATION_PROTOTYPE.md). The original 70-in-18 game remains separate.

## Environment and reproducibility

- Xcode 27.0, Apple Swift 6.4, arm64 simulator builds.
- Dedicated iPhone 17 Pro simulator, iOS 27.0, named **Starfall Accumulation Lab** (`FBB33D71-C642-4705-B63F-F71A3A7CA62C`). No physical-device validation.
- Shared scheme: `Starfall`; bundle: `com.starfall.prototype`.
- Launch with `--starfalls --starfalls-reset --starfalls-seed=5` for the empty demonstration sky. After three invitations it contains a grown jewel and a legal clear. New sky selects a fresh seed; replay repeats the selected sky.

Core command:

```sh
swift test --scratch-path /private/tmp/starfall-accumulation-swift
```

Native Debug command:

```sh
xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug \
  -destination 'platform=iOS Simulator,id=FBB33D71-C642-4705-B63F-F71A3A7CA62C' \
  -derivedDataPath /private/tmp/starfall-accumulation-final \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build-for-testing
```

Release uses `-configuration Release -destination 'generic/platform=iOS Simulator'` and its own derived-data directory. The experiment's app screen, menu entry and presentation classes are wrapped in `#if DEBUG`.

## Verified rules

`swift test`: **39 passed, zero failures**, including 12 accumulation tests. These cover empty starts, free invalid taps, weighted clear thresholds, one-time growth, stacking, stable survivor identity under gravity, ordered partial arrival on overflow, a matching full-column growth exception, clearing to prevent overflow, the seven-column arrival bag, and deterministic save/replay across 50 skies. Existing game and refill-presentation tests also pass.

The initial three-physical-jewel rule produced no legal clear in seed 42 before overflow. The final experiment counts a grown jewel as two toward a clear and spreads landing columns across a shuffled seven-column bag. These are tuning decisions for this prototype, not evidence of long-term balance or human enjoyment.

## Native checks and visual inspection

- Final Debug build-for-testing and Release simulator build: succeeded.
- Final app-hosted run: **48 passed, zero failures**, including the three new experiment store tests. See [Xcode summary](app-tests-summary.json).
- Final `testPreviewGrowthClearReplayAndSettings`: **passed**, covering an empty start, all three preview labels, a free invalid tap, a normal-mode double tap counted once, visible growth, a real group clear, settings accessibility isolation, a Calm effects double tap counted once, dismissal and exact replay. See [Xcode summary](interaction-summary.json).
- `testBackgroundRelaunchAndOverflow`: **passed** in the initial native run, covering background/resume, process relaunch, overflow, locked terminal input and New sky.
- Original `testRealBoardTapAndNavigation` and `testTerminalOutcomesPersistAndRestart`: **both passed** in that run, including win, loss and last-move win. Results are preserved in [the initial run's test output](initial-native-test-results.txt).

The initial forecast test failed because SwiftUI did not expose the three preview cards separately. Adding an explicit accessibility container fixed it; the final interaction test above passed. The initial mixed run later stalled during Xcode result packaging after its tests finished and was stopped. The final interaction and app-hosted runs each completed successfully with separate result bundles.

The final screenshots below were exported from the successful native interaction test and visually inspected. They show the empty forecast, a grown aqua jewel beside its small match after three showers, the collected score and new arrivals after clearing, and the calm presentation after settings dismissal. The board, forecast and main action are visible; the explanatory footer can scroll.

- [Empty sky and forecast](starfalls-empty-preview.png)
- [Growth and a possible clear](starfalls-grown-and-matchable.png)
- [After clearing](starfalls-after-clear.png)
- [Calm effects after settings dismissal](starfalls-calm-after-dismissal.png)

[Attachment provenance](attachment-manifest.json) and [tested source hashes](source-sha256.txt) are included. Native result bundles remain locally at `/private/tmp/starfall-accumulation-final-ui.xcresult` and `/private/tmp/starfall-accumulation-final-host.xcresult`.

## Accessibility and limits

Every cell uses a native button labeled with jewel type, value and position. Its connected starlight value and clear hint are exposed, and a Matching groups rotor lists legal clears. The three incoming stars each expose type and column. Settings hides the underlying board from accessibility navigation. Calm effects, system Reduce Motion and VoiceOver route to the non-travel presentation.

Native UI tests inspect and operate accessibility elements; they do not enable VoiceOver or validate spoken output, rotor focus, or a person's screen-reader experience. System Reduce Motion wiring is present, but the tested reduced-animation setting is the app's Calm effects toggle. Human playtesting and physical-device accessibility validation remain follow-up work.
