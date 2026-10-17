# Environment variety — 2026-10-17

## Design and bounded comparison

Hypothesis: distinct, quiet sky palettes and distant silhouettes can make repeat rounds feel fresher without competing with the star characters. Baseline: Midnight's violet gradient, twelve fixed stars and opaque board. Candidates: Aurora (jade ribbons), Ember Dusk (rose ridges), Moonlit Mist (blue haze). These are cosmetic environments for the existing survival/First Light modes, not campaign levels. No assets, dependencies, network calls, rule changes or RNG consumption.

References: [NASA night lights](https://science.nasa.gov/solar-system/skywatching/night-sky-network/nsn-night-lights/) for aurora/cloud forms; [Apple accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) for contrast and restrained peripheral motion. Original vector interpretation, no downloaded imagery.

Acceptance criteria: four selectable named skies; choice changes neither board nor shower state; default/unknown preference resolves to Midnight; preference survives app restarts; scenery cannot intercept input or add accessibility stops; no ambient motion or per-frame work; full star animations retained; Increased Contrast suppresses silhouettes. Inspect all four on native screenshots, then compare dense-board readability and observed human preference before promoting candidates as default.

Implementation: palette contracts in StarfallTheme, bounded passive rendering in NightSkyBackdrop, local AppStorage preference and native menu picker in FallingSkyView. No store/core/scene/coordinate changes. Existing files already belong to app target. Midnight remains default. Candidates remain directly selectable for comparison; decision point is one observed dense-board play comparison across all four, then retain preferred options or remove weak ones. No automatic rotation, progression or extra pilot route.

## Source and checks

Base HEAD `d2dadfa644adb2fe0a51012aa1077266d4d33b78`, working tree validation, Xcode 27.1 (27A9275). This is not clean published-commit acceptance. Pre-existing dirty paths: project.pbxproj, FallingSkyTests.swift, compare-showers.py, prepare-native-lab.py; untracked workspace, branding, pressure evidence and mechanics fixtures. These were not modified by this work. Feature paths: App/{StarfallTheme,NightSkyBackdrop,FallingSkyView}.swift and UITests/FallingSkyInteractionTests.swift plus documentation.

- `swift test`: 61 tests passed, including existing dirty core tests.
- `python3 scripts/ci-hygiene.py`, `git diff --check`: pass.
- Debug simulator generic build: pass (`/tmp/StarfallEnvironmentsBuild`).
- Initial UI invocation reusing the generic multi-architecture derived data failed linking StarfallCore symbols in x86_64; a fresh derived-data invocation follows. This failure is not a passing interaction check.
- Release build and native interaction results recorded below after completion.

Actual VoiceOver, physical device, human enjoyment, preference persistence across relaunch, rapid taps, win/loss, background/resume and all motion/accessibility combinations remain unverified for this source. Static scenery does not prove falling animations. Geometry was not changed.

- Release generic simulator build: pass (`/tmp/StarfallEnvironmentsRelease`).
- Fresh automatic-architecture UI build also failed resolving StarfallCore for x86_64. Explicit `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES` resolved this build issue; selected environment UI test passed on iPhone 17e / iOS 27.0, UDID `4103C352-DFC2-493E-A224-DE4CE3D50889` (43.57s test). All four picker selections, menu dismissal and unchanged paused board summary checked; screenshots attached to xcresult under `/tmp/StarfallEnvironmentNative/Logs/Test`. This first test used an empty reset board and cannot establish character contrast. Populated comparison follows.
- Aurora native screenshot inspected: peripheral ribbons and bottom silhouette stay behind the opaque board, native HUD remains legible. Blank launch screenshot was discarded as timing noise, not visual evidence.

## Final bounded result

Populated native UI test passed (58.564s) after six paused showers; all four choices and menu dismissals preserved the board's shower/group summary. Command: `xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=4103C352-DFC2-493E-A224-DE4CE3D50889' -derivedDataPath /tmp/StarfallEnvironmentNative ARCHS=arm64 ONLY_ACTIVE_ARCH=YES -only-testing:StarfallUITests/FallingSkyInteractionTests/testEnvironmentSelectionPreservesPausedBoard -only-testing:StarfallAppTests test`. Raw output `/tmp/starfall-environments-final-native.log`.

Hosted result: 72 tests, 4 skipped, 35 assertion failures; all 16 FallingSkyStore tests passed. Failures occur in CrystalPilotTests (4) and StarshardFamilyPilotTests (31). Simulator `com.apple.Accessibility ReduceMotionEnabled` reads `1`; ENGINEERING already records legacy animation-test motion assumptions. No same-source baseline was run to attribute every failure; full suite is **not green**. The xcresult finalizer remained pending after suite completion, so captures were also taken directly with simctl. Earlier populated run was invalidated by overlapping hosted execution on the same simulator and is not acceptance evidence. No blanket retry or weakened assertion was used: the final run removed that execution overlap.

Native Ember, Mist and Aurora populated screenshots inspected directly: character shapes/faces, dark-star rings and controls remain visible; silhouettes stay outside the opaque playfield. Captures in ignored `artifacts/environments-2026-10-17/`. This is a sparse six-shower board, not dense-board acceptance. Reduce Motion was on, so full falling animation remains unverified. Explicit launch preference overrides used for direct captures do not prove persistent user preference restoration.

Decision: extend the optional presentation comparison. Keep Midnight default. Next decision remains observed dense-board comparison with actual accessibility checks and human preference. This pass establishes implementation, builds and native selection behavior, not satisfaction or final visual adoption. Changes remain uncommitted alongside concurrent repository work; no clean integration acceptance claimed.
