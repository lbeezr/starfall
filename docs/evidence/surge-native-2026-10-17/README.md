# Surge Lab native comparison — 2026-10-17

Decision: retain an isolated playable surge trial for observed comparison; do not adopt it into production. The [offline exposure audit](../burst-exposure-2026-10-17/README.md) explains why five-star surges replace the weak original pressure rule as the next phase question. Automated survival increased as well as matching choices; the event is not presented as a promise of greater difficulty.

## Play and scope

Run `python3 tools/mechanics/prepare-native-lab.py --surge-showers`, then build the printed `Starfall.xcodeproj` with scheme Starfall. Display name **Surge Lab**, bundle `com.starfall.surgeshowerslab`, defaults suite `starfall.surge-showers.lab`. Original Phase Lab remains separate. No production route, SDK, progression, dependency or project membership changes were added. Candidate saves cannot cross labs.

For a fresh round, launch `--starfalls-reset --starfalls-seed=5`. For the short event walkthrough, launch `--starfalls-reset --shower-phase-fixture`: eight ordinary committed showers with canonical first clears have already occurred. The next forecast has the warning “Five-star surge follows.” After that shower, the next three forecasts each contain five stars and count down as “Surge · 3/2/1 five-star showers.” Preparation resumes after shower twelve with “Recovery · 9 calmer showers.” Use manual Next shower to inspect the rule, or Resume sky for automatic play. Matching arrivals can grow stars rather than occupy more cells.

The shared phase view follows the store's visible forecast: while an arrival is presenting, it retains that arriving shower's count; after presentation, it describes the next preview. At accessibility text sizes the cue stays above the scrollable board/controls. Labels and shared tests are configured by the exporter rather than copied into a second app implementation. The original Phase Lab's App, Sources and Config files were verified byte-identical before and after this exporter refactor.

## Tested source and results

Frozen baseline `30af812aa3bf3105a55d8b960288e1d2ac672c2c`, [tested source manifest](source-manifest.json), exported project `/var/folders/fs/9shw9bf142jg3280dc9n3hhc0000gn/T/starfall-native-showers-qbrig6rl`. Core SHA256 `91d5c3968bc4154863339b4535441a8f0956eb4f2795f49c58aab3fa31a28f80` exactly matches the measured offline candidate. The export excludes unrelated repository environment/view/project changes. All injected code appends to existing app/core/test target members.

Xcode 27.1 (27A9275), iPhone 17e “Starfall Mechanics Lab,” iOS 27.0 (24A434), simulator `A84C81F5-AE41-496A-97AE-E17C63E18D29`, scheme Starfall. Debug build/run and 21 selected tests passed, zero failures/skips: 17 hosted shower store tests and four native UI tests. Added surge assertions verify five incoming stars for all three surge forecasts and five-star committed forecasts for the automatic/manual comparison. Other checks cover recovery, restart, pause/suspension without catch-up, restored paused state, settings dismissal, largest-text cue visibility and actual system Reduce Motion/manual play. Native tests use bounded predicates, no blanket retries. The inherited system Reduce Motion setting was enabled during the automated run; those passes are not full-motion visual evidence.

Exported `swift test`: 60 passed (`/tmp/starfall-surge-native-core.log`). Generic arm64 simulator Release build passed (`/tmp/starfall-surge-release.log`, DerivedData `/tmp/starfall-surge-release`). All builds/tests used `CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES`; native tests used `-parallel-testing-enabled NO`, Debug DerivedData `/tmp/starfall-surge-native`. Python compilation, hygiene and diff checks passed.

Native result: `/Users/lbeezr/Library/Developer/XcodeBuildMCP/workspaces/Starfall-27844ad883f3/result-bundles/test_sim_2026-10-17T14-46-02-077Z_pid40582_7066501e.xcresult`. [Default-size preview](surge-preview.png) and [largest-text cue/controls](largest-text.png) were inspected, as was the recovery capture. At largest text the cue spans three lines and the board/controls scroll; this is sampled readability, not all-device layout acceptance.

## Motion observation

The first simulator recordings followed the inherited enabled Reduce Motion setting and correctly showed the reduced path. For a separate full-motion observation, that simulator preference was temporarily set false and the app relaunched, then restored to its original true value after capture. Settings navigation via the runtime tap tool did not consistently activate rows; the temporary change used `simctl spawn ... defaults write com.apple.Accessibility ReduceMotionEnabled -bool false/true`, with readback 0 and restored 1. No game source or test assertion was changed to force motion.

`simctl io ... recordVideo --codec=h264` successfully captured `/tmp/starfall-surge-full-motion.mov`. [Source/hash and sampled times](motion-source.json). Frames extracted locally with AVFoundation show the board before input at 2.6 s, a star entering at 2.8 s, multiple falling stars/trails at 3.0 s, and the settled next forecast at 4.0 s. The [in-flight frame](surge-in-flight.png) retains “Surge · 3 five-star showers” and the arriving colors; after settlement the cue becomes two and the next colors appear together. This verifies falling and forecast/cue synchronization in this one manual shower-ten example, not every animation, recovery boundary or device performance scenario.

## Remaining decision

Compare whether a player prepares differently, preserves groups for a surge or mainly receives easy matches. Agent-simulated observations must be labelled separately from human acceptance. Paused manual play cannot establish normal-speed urgency. Actual VoiceOver listening, dense-board comprehension, rapid phase-boundary input, physical devices and a production-HUD port remain unverified. The earlier baseline-reproduced crystal renderer failures are not resolved or rerun by this selected check set. Legacy-save continuation checks from the offline trial do not establish a future production migration/new-round contract. Retain, remove or extend only for a named remaining question after the comparison.

The requested [agent-simulated comparison](../simulated-surge-playtest-2026-10-17/README.md) is now recorded separately. It provisionally favors Surge and reports preparation and spatial-planning choices, with low comparative-gameplay confidence. It does not close the human enjoyment or remaining acceptance questions.
