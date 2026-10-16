# Dark-star prototype validation — 16 October 2026

Dedicated device: **Starfall Accumulation Lab**, iPhone 17 Pro, iOS 27 simulator, UDID `FBB33D71-C642-4705-B63F-F71A3A7CA62C`. Xcode 27, arm64, shared `Starfall` scheme. No physical-device validation is claimed.

## Rules and build

- `swift test --scratch-path /private/tmp/starfall-dark-swift`: **48 tests passed**, including 21 experiment tests.
- Debug simulator build: **passed**.
- Full native run: **53 app tests and 14 UI tests passed**. The eight experiment store tests include saved dark-star influence, invalid dark-star taps, removal feedback and persistence of the updated accounting. The broader UI suite also passed baseline normal play, rapid/invalid taps, large-text accessibility audits, win/loss/restart, artwork variants and saved-round restoration.
- Seven new core scenarios cover orthogonal growth blocking, preserved existing growth, dark stars stacking without matching, influence on later arrivals in the same shower, adjacent removal without chains or extra score, a shaded full column overflowing, and seeded first-arrival/frequency bounds.
- Existing save/replay and long seeded-run tests now exercise dark-star conservation and future sequence as well. Baseline win/last-move precedence remains covered by the unchanged core suite.

## Native interaction checks

All three `StarfallExperimentInteractionTests` passed in the combined simulator run:

- Actual automatic arrivals, pause across an interval, rapid-tap clear, Calm effects, settings accessibility isolation/dismissal and identical replay preview.
- Background/resume without catch-up, paused restoration, unattended overflow and New sky.
- First dark star and shaded-neighbor labels, a large jewel with no numeral, destination-free preview labels, restored dark-star influence and a neighboring clear that removes the dark star for exactly three starlight.

The browser mirror was also visually inspected during live accumulation: violet dark-star coronas and shaded-neighbor rings are visible, grown jewels use size alone, and no landing-column highlights or headers remain. VoiceOver was enabled on the dedicated simulator and its visible native focus was inspected on the dark-star board (`native-voiceover.png`; the browser setting is recorded separately). Native accessibility assertions cover the dark-star and shaded-jewel labels. This is not a full spoken-navigation or rotor validation.

The seven native screenshots in this folder were exported from the successful XCTest run. `dark-star-and-shaded-neighbors.png` and `dark-star-dissolved-by-adjacent-clear.png` show the before/after state of the new interaction. The other five record empty preview, available match, scored clear, Calm effects and overflow.

System Reduce Motion was enabled during automatic arrivals on the dark-star board; `browser-reduce-motion.png` records the settled result. Calm effects was checked separately by the native UI suite. Neither screenshot is a frame-time measurement.

## Reproduction

Launch with `--starfalls --starfalls-reset --starfalls-seed=5`, then start the sky. With no clears, shower six contains the first dark star. It lands above the bottom mint jewel in the second column. The bottom mint group is worth three; clearing it dissolves the adjacent dark star and awards three starlight. The large jewel in that group has no numeral. Landing columns are not shown in the forecast or outlined on the board.

Core and build logs: `/private/tmp/starfall-dark-core.log`, `/private/tmp/starfall-dark-build.log`. Native test log and result bundle: `/private/tmp/starfall-dark-tests.log`, `/private/tmp/starfall-dark-tests.xcresult`. Temporary logs and result bundles are not committed.

Dark-star frequency, pressure and readability are prototype tuning choices. These checks do not establish long-session balance or physical-device performance.

## Handoff

The final Debug build is installed on the dedicated simulator. The local browser mirror is `http://localhost:3200/?chrome=0`. It is left paused with a dark star present and the adjacent bottom mint group available to clear after resuming. Calm effects, system Reduce Motion and VoiceOver are off for the handoff. `browser-ready.png` records the final live preview.
