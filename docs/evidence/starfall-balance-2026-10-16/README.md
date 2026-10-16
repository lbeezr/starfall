# Balance controls validation — 16 October 2026

Device: dedicated **Starfall Accumulation Lab**, iPhone 17 Pro, iOS 27 simulator, UDID `FBB33D71-C642-4705-B63F-F71A3A7CA62C`. Xcode 27, arm64, shared `Starfall` scheme. No physical-device validation is claimed.

## Automated coverage

- `swift test --scratch-path /private/tmp/starfall-balance-swift`: **53 tests passed**, including 26 experiment rule tests.
- Initial native run: **56 app tests and all four experiment UI scenarios passed**. This includes the three new store tests for changing pace during presentation, changes while settings/background suspend the clock, and retaining/resetting balance through replay, New sky and relaunch.
- Native interaction covered Gentle + Frequent, the first dark star in shower three, preserving the existing board, restoring both controls after relaunch, resetting defaults and switching to Brisk + None. Existing native scenarios also passed normal play, rapid taps, Calm effects, settings dismissal, background/resume, overflow and dark-star removal.
- After visual inspection, explicit Shower pace / Dark stars labels and the app's cyan tint were added to the menu rows. The final Debug build and **both settings-related UI scenarios passed again**, including the stricter check that Gentle waits beyond the former four-second deadline. The three `balance-*.png` files are exported from that final run.
- New core coverage checks every frequency's first arrival and later gaps, turning dark stars off while preserving the current preview, pace changes leaving the random sequence intact, replay/restore for all twelve combinations, and loading pre-tuning v3 saves without losing their board or future stars.
- The default rules remain Steady (four seconds) and Regular (first dark star in shower six, then every four to six showers).

## Semantics checked

Pace adjusts shower spacing rather than flight animation duration. A changed balance gives a fresh interval after settings dismissal or resume. It does not clear the board, remove existing dark stars or reroll the preview. None stops dark stars after the announced preview. Replay and New sky retain both choices; Reset balance restores Steady + Regular. Settings changes invalidate stale timer/animation callbacks and cannot cause catch-up bursts.

## Reproduction artifacts

The final settings sheet was inspected in the live native browser mirror. Visible row labels, selected values, explanatory ranges and Reset balance were checked. VoiceOver was enabled on the simulator and visible native focus was inspected on the settings sheet (`native-voiceover-settings.png`). The automated tests interact with the same native picker controls and inspect their selected values. This is not a full spoken-navigation or rotor validation. Calm effects was exercised in both native runs; system Reduce Motion rendering was inspected in the preceding dark-star iteration and that rendering code is unchanged here.

Native test command selects `StarfallAppTests` and `StarfallUITests/StarfallExperimentInteractionTests`, with parallel testing disabled. The native run builds the Debug simulator app before testing. Baseline win/loss rules remain covered by the core suite; the unchanged baseline UI suite was validated in the preceding [dark-star iteration](../dark-starfalls-2026-10-16/README.md).

Logs: `/private/tmp/starfall-balance-core.log`, `/private/tmp/starfall-balance-tests.log`, `/private/tmp/starfall-balance-final-ui.log`. Result bundles: `/private/tmp/starfall-balance-tests.xcresult` and `/private/tmp/starfall-balance-final-ui.xcresult`. Temporary logs and result bundles are not committed.

These controls are tuning inputs, not validated difficulty modes. This work does not establish long-session balance or physical-device performance.

## Handoff

The final Debug build is installed on the dedicated simulator. The live mirror is `http://localhost:3200/?chrome=0`, left in Sky settings with Steady + Regular restored, the current board retained and the sky paused. Calm effects, system Reduce Motion and VoiceOver are off. `browser-ready.png` shows the final settings panel.
