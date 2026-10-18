# Starlight celebrations development build

**Result:** Partially verified · **Owner:** current implementer · **Date:** October 18, 2026

Implemented the user-approved charge → impact → collection storyboard. Production ordinary/large clears use the shared receipt/overlay; the existing isolated constellation lab supplies the validated drawn path for its larger payoff. Core scoring, generator, save schema and production constellation routing are unchanged. Native graphics capture is currently blocked; physical sound/haptic preference is unverified. Do not treat compilation or the approved mock as proof that the running animation matches it.

**Next action:** finish native gesture/layout and normal-motion visual review on a responsive graphics simulator, then compare timing and tactile/audio weight on iPhone. Retain/tune a named weak beat; no new progression or recipe rules are part of this build.

## What changed

- A store-owned, generation-identified receipt lasts at most 1.15 seconds. It records the exact award and total; dark-star removals do not pull the collection origin away from scoring stars. The existing 0.56-second clear input gate remains independent.
- A small SwiftUI timeline draws a local ring/glints, the actual constellation outline, up to six light packets toward the real score anchor, readable award/title and counter bloom. The numeric pop uses that same receipt's lifetime, including interruption cancellation. Board and header anchors share one coordinate space. Geometry changes settle decoration and stop sound.
- Ordinary clears keep the selected four tucks. Large and traced clears use original deterministic local WAV resolutions and a stronger native success haptic. The existing single-voice audio owner still handles replacement, mute, background, route changes and interruption. No external audio generation, samples, SDKs or new dependency.
- Quiet modes preserve a static exact award/callout; decorative text is hidden from accessibility exploration. The committed spoken result includes category and total. Full actual VoiceOver remains an RC gate.
- Removed the duplicate constellation-lab release burst. Trace preview reports actual unbanked value when ready and distinct count before readiness.

[Approved concept and acceptance criteria](../../design/STARLIGHT_CELEBRATIONS.md) remain the design authority. The concept image is explicitly separate from runtime evidence. No runtime capture is embedded here because screenshot/video attempts did not produce a usable image.

<img src="../../design/interface/starlight-celebration-concept.png" width="640" alt="Approved concept storyboard showing charge, constellation impact and light collecting into the total">

**Generated concept — not runtime evidence.** User-approved October 18, built-in ImageGen from the existing native Observatory/cast references. [Brief and source](../../design/STARLIGHT_CELEBRATIONS.md). This shows the intended feel; it does not close the blocked animation/layout checks.

## Verification context

Base: `f35eba8`, plus the source/test changes identified by [SHA-256 manifest](source.json). These are working-tree/export checks, not acceptance of an unchanged published commit. The lab snapshot/export isolates candidate bundle `com.starfall.constellations.candidate` and defaults suite `starfall.constellations.candidate`. No original phone app, saved round or device installation was touched.

Environment: Xcode 27.1 (27A9275), Apple Swift 6.4, arm64, iOS 27.0 Simulator. Final hosted checks used small-phone QA; initial production hosted checks used Compact HUD QA (`6E9BC34B-C5C6-48ED-9593-D16AC994BCC8`); initial candidate hosted checks used small-phone QA (`E90550D2-AE94-4695-8E6F-707BD527C12F`). Shared iPhone 17e (`4103C352-DFC2-493E-A224-DE4CE3D50889`) had overlapping installs from other worktrees and was abandoned without modifying those processes. Simulator create/capture requests also stalled; no new simulator was successfully created.

| Area | Result | Evidence and limits |
| --- | --- | --- |
| Core | Pass: production 63, exported candidate 63 | `core.log`, `lab-core.log`; no production core source change. |
| Hosted behavior/audio | Pass: production 38, candidate 44 | `hosted-final.log`, `lab-native.log`; committed award, grown value, dark exclusion, restore, duplicate input, independent expiry, interruptions, distinct sounds/resources, old take rotation and existing trace contracts. Final-tree production 38 and candidate 44 also pass (`hosted-acceptance.log`, `lab-hosted-acceptance.log`), including geometry/audio cancellation and the receipt-gated counter pop. Lab identity is `dev.84f75738d0`. |
| Build/resource membership | Pass: Debug/Release production and candidate | `debug-final.log`, `release-acceptance.log`, `lab-release.log`; native compiler includes the new Swift file and bundled WAV folder resources. Debug final candidate built during `constellation-final.log`. |
| Initial native interaction | Two passed; two helper failures | Background/restore/automatic overflow and menu suspension passed. Both First Light methods stopped before gameplay at the offscreen challenge button. The existing bounded reveal helper now scrolls before checking/tapping it; assertions remain intact. The lab-only duplicate helper patch was removed from the exporter. The corrected run (`firstlight-corrected.log`) failed during XCTest initialization: `Timed out waiting for AX loaded notification`; neither corrected method executed. |
| Current native gesture/layout | Not yet accepted | Initial candidate UI execution stalled after hosted success; later candidate execution also stalled before test cases started and was terminated. Unfinished native cases are not passes. |
| Visual/full motion | Unverified — capture blocked | `simctl io screenshot`, `recordVideo`, IO enumeration and display-power request stalled without producing a usable capture. No motion claim is made from stills or suppressed effects. |
| Accessibility | Partial source/hosted checks | Static quiet mode, labels and exact totals preserved; native Reduce Motion/largest-text acceptance remains open unless final results below close it. Actual VoiceOver: deferred to RC; not run on this development build. |
| Physical device/audio/haptics/preference | Not run | Resource decode is not listening or haptic evidence. User approval applies to the concept. |

Raw logs, intermediate exports and result bundles remain in ignored `artifacts/celebrations/`. The first default-architecture build failed to resolve the arm64 package for an x86_64 app build; explicit `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES` succeeded. A keyframe closure initially captured actor-isolated view state; replacing that capture with a value snapshot compiled. Neither diagnostic was suppressed.

Reproduction uses the shared scheme:

```sh
swift test
python3 scripts/ci-hygiene.py
git diff --check
python3 tools/mechanics/prepare-constellation-labs.py --output <new-export-folder>
xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug \
  -destination 'platform=iOS Simulator,id=<available-qa-udid>' \
  -derivedDataPath <isolated-derived-data> ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO \
  -only-testing:StarfallAppTests/FallingSkyStoreTests \
  -only-testing:StarfallAppTests/QuietTuckPlayerTests test
```

Repeat in the candidate export and include `-only-testing:StarfallUITests/ConstellationTraceNativeTests` for gesture checks. Production interaction selection and results are in `native.log` and the final logs below. Release builds use `-configuration Release -destination 'generic/platform=iOS Simulator'` with the same arm64/resource boundary.

## Final source checks

The final Debug production build (`debug-final.log`), final Release production build (`release-acceptance.log`) and Release lab build (`lab-release.log`) pass. The ready/final-source lab runtime fingerprints both equal `dev.84f75738d0`; later differences are test-helper/documentation changes. Final hosted checks pass 38 production and 44 candidate tests. Hygiene, both staged/unstaged diff checks and local documentation/image links pass. Embedded concept inspected; Markdown rendering not checked.

The initial broad native session was terminated after two passes and two pre-gameplay helper failures; manual/large-text/Reduce Motion cases did not complete. Subsequent candidate UI startup on two QA devices stalled before trace cases ran. Own stalled capture/test requests were stopped; shared simulator services and other worktrees were left alone. Full native acceptance is open, not waived.

The final corrected First Light UI launch failed before either method started with `XCTDaemonErrorDomain Code=18: Timed out waiting for AX loaded notification`. This confirms a simulator accessibility-startup blocker for that attempt, not a gameplay failure or a passed helper correction. Earlier canceled candidate UI/capture attempts do not establish a separate root cause. No shared service reset was attempted.

## Remaining acceptance

The highest uncertainty is visual timing and readability: verify the charge/release, actual header destination, overlap at maximum text, clear-to-shower replacement and a second clear during a tail. Then inspect system Reduce Motion, settings Done/swipe, restart and both endings. On a physical iPhone, compare ordinary versus constellation weight with sound/haptics on and off, including repeated play and interruptions. See the [engineering follow-up](../../ENGINEERING.md#starlight-celebration-acceptance).
