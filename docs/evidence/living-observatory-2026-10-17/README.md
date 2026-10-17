# Living Observatory native proof

**Partially verified · October 17, 2026.** Full-screen scenery, the real cast, projected native taps and responsive props work in the isolated Observatory lab. The user endorsed the experience after tapping both props. Production adoption still needs actual VoiceOver, supported-layout review and device profiling. Follow the [production strategy](../../design/environments/PRODUCTION.md).

| Sparse | Dense |
| --- | --- |
| <img src="sparse.jpg" width="240" alt="Real star cast on the Observatory terrace, framed by telescope, lantern and cosmic scenery"> | <img src="dense.jpg" width="240" alt="Fully populated Observatory terrace with all star families and Dusk visible"> |

Native XCTest captures, downsized without changing proportions. Inspect character contrast and near/far placement. Stills do not prove fog movement or falling animation.

## Source and environment

Xcode 27.1 (27A9275), iPhone 17e / iOS 27.0 Simulator, UDID `CDF20AC9-729B-4AB2-9B00-2F50E1A3766B`. Scheme Starfall; isolated bundle `com.starfall.landinglab`. Production routing and saves are unchanged.

Exports contain tracked working-tree bytes plus [explicit lab overrides](../../../tools/environments/README.md); these are not clean published-commit acceptance. Final export: `/var/folders/fs/9shw9bf142jg3280dc9n3hhc0000gn/T/starfall-landing-lab-yosone_v`. Integrated test export: sibling `starfall-landing-lab-j5zjcyg7`. Their App and Sources trees were byte-identical; the final export adds the normal-motion test setup. [Runtime hashes](runtime-sha256.json) pin those trees. Each export also records original HEAD/dirty paths in `ENVIRONMENT-LAB-SOURCE.json` and override hashes in `LANDING-LAB-OVERRIDES.json`.

## Results and limits

| Check | Result |
| --- | --- |
| Core `swift test` | 61 passed; no core changes in this work. Log `/tmp/starfall-landing-core.log`. |
| Integrated Debug hosted tests | 30 selected, zero failures, one full-motion test skipped because system Reduce Motion was enabled. Geometry, inverse mapping, clock, fixture/save continuation, bundled alpha assets and store/cast checks passed. |
| Integrated native UI | Five passed: real-cast corner taps, settings/background preservation, prop responses/modal cancellation, Calm behavior and existing automatic shower/pause/growth/clear/replay path. |
| Separate normal-motion run | Explicitly switched system Reduce Motion off on the disposable simulator. Existing animated landing bounds test passed with no skip, including fall/rebound/expression/settling and survivor ripple. Runtime App/Sources identical to integrated run. |
| Release simulator build | Passed on final export. |
| Earlier acceptance run | First Light win, overflow/loss, rapid double tap, largest Dynamic Type and actual system Reduce Motion checks passed on earlier export `w5ma7650`. This is prior-source evidence, not a complete final-source matrix. |
| Visual review | Sparse/dense native captures inspected for real silhouettes, aspect, readable faces and full-screen framing. User personally reported successful telescope/lantern reactions; exact user-tapped build unknown. |
| Motion evidence | Normal-motion simulator video retained under ignored artifacts. Recording alone is not a completed human temporal review. Hosted full-animation assertions passed separately. |
| Unverified | Actual VoiceOver, physical device, minimum-supported OS/phone, iPad/landscape, frame pacing/memory profile and long-play enjoyment. Markdown rendering not independently reviewed. |

Integrated command: `xcodebuild -project <export>/Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=CDF20AC9-729B-4AB2-9B00-2F50E1A3766B' -derivedDataPath /tmp/StarfallLandingBuild ARCHS=arm64 ONLY_ACTIVE_ARCH=YES -only-testing:StarfallAppTests/LandingGeometryTests -only-testing:StarfallAppTests/FallingSkyStoreTests -only-testing:StarfallAppTests/StarCastTests -only-testing:StarfallUITests/NativeLandingUITests -only-testing:StarfallUITests/FallingSkyInteractionTests/testAutomaticRainPauseGrowthClearReplayAndSettings test`.

Raw integrated log `/tmp/starfall-landing-integrated-native.log`; full-motion log `/tmp/starfall-landing-fullmotion.log`; Release log `/tmp/starfall-landing-integrated-release.log`. XCTest bundles: `/tmp/StarfallLandingBuild/Logs/Test/Test-Starfall-2026.10.17_11-11-10--0400.xcresult` and `Test-Starfall-2026.10.17_11-16-25--0400.xcresult`. Raw attachments `/tmp/starfall-landing-final-captures`; recording `artifacts/living-observatory-2026-10-17/native-normal-motion.mp4`. Temporary outputs may expire; this report and runtime hashes are the durable summary.

## Corrections found during acceptance

On iOS 27, hiding the native cell overlay from accessibility alone did not reliably remove underlying cells while settings was open. The lab now structurally removes gameplay and prop buttons for the modal lifetime, restoring them on dismissal. The existing automatic-play/settings test and dedicated prop/modal test passed after this correction. Related gameplay-cell and environmental-prop paths were examined; this does not establish actual VoiceOver focus behavior.

SpriteKit centers use floating-point storage; geometry checks compare at subpixel tolerance while separately checking inverse coordinates, touch targets and shared edges. The initial exact string comparison was corrected. No rule, save, animation-bound assertion or outcome was changed to pass these checks.

**Decision:** Keep this one bounded native lab, finish the missing acceptance, then adopt its verified pieces into production. Cloudsea is the next reuse test; do not accumulate five separate runtime implementations.
