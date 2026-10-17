# Renderer motion preconditions — 2026-10-17

Acceptance: retain every renderer assertion, execute all 22 checks with system motion enabled, and keep reduced-motion checks runnable when system motion is suppressed. No app/core/save behavior changes.

The six historical failures reproduced in the unchanged frozen baseline because Reduce Motion was enabled. JewelScene intentionally suppresses actions/fragments for system Reduce Motion, VoiceOver, calm effects and unattached views. Reviewed both JewelScene suppression and StarfallArrivalEffects, and all nine full-motion methods in CrystalPilotTests/StarshardFamilyPilotTests. Consolidated their precondition without altering assertions or the shared reduced-motion fixture. Frozen lab exports copy these authoritative hosted test files and record their hashes.

Native Debug build and two affected suites: iPhone 17e, iOS 27.0 (24A434), Xcode 27.1 (27A9275), simulator A84C81F5-AE41-496A-97AE-E17C63E18D29. Frozen app source 30af812, current two renderer tests plus exporter as hashed in source.json; concurrent production app/project/UI changes excluded. Commands: XcodeBuildMCP test_sim, CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES, only-testing StarfallAppTests/CrystalPilotTests and StarfallAppTests/StarshardFamilyPilotTests, parallel-testing-enabled NO.

- Reduce Motion on: 13 passed, 0 failed, 9 explicitly skipped. Raw result test_sim_2026-10-17T15-27-18-076Z_pid40582_10348e08.xcresult.
- Reduce Motion off: 22 passed, 0 failed, 0 skipped. Raw result test_sim_2026-10-17T15-28-12-047Z_pid40582_97a73605.xcresult.
- Raw bundles: ~/Library/Developer/XcodeBuildMCP/workspaces/Starfall-27844ad883f3/result-bundles/. Original Reduce Motion on restored in finally.
- Current core swift test passed (61 tests); log /tmp/starfall-renderer-core.log. Hygiene passed. Own staged diff check passed; working-tree diff check reports unrelated concurrent whitespace in App/FallingSkyView.swift.

This resolves the six-test motion-precondition diagnosis, not unrelated native interaction failures or human gameplay acceptance. Historical runs remain failed. No new Release run: app/core/build configuration unchanged from the frozen baseline. No new visual, VoiceOver listening, physical-device, interruption/settings or gameplay-quality acceptance claimed; these test-only changes do not modify those paths. Actual VoiceOver remains unverified. The full 22-test run is the animation assertion evidence; nine skips alone are not.
