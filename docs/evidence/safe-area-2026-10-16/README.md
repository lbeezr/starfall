# Safe-area scroll evidence — 2026-10-16

Source commit `3f4f4cf5c216dac86b12da40797d956b01563262`, based on merged crystal revision `ff9f736c18d8323f6d49fb8082b0f00d5261c366`. Exact source hashes are recorded in source-sha256.json. The production change adds clipping at the two existing menu/game foreground viewports. Shared tokens, content sizing, scroll behavior and the full-bleed backdrop remain intact.

Xcode 27.0, iOS 27.0 (24A434), arm64 simulators:

- Deterministic core: 27 tests passed; `/tmp/starfall-safearea-core.log`.
- Ordinary Release simulator build passed; `/tmp/starfall-safearea-release-build.log`.
- iPhone SE (3rd generation): two native UI cases passed, zero failures/skips/expected failures. `testLargestTextLayoutAndAccessibilityAudit` exercises maximum-text menu/game/Settings, three unsuppressed audit types, a real clear, restart and Calm effects/Done. `testRealBoardTapAndNavigation` covers normal gameplay, Settings controls and swipe dismissal, and restart. Result: `/tmp/starfall-safearea-phone.xcresult`; 137.608 seconds of test execution.
- iPad mini (A17 Pro): two native UI cases passed, zero failures/skips/expected failures. `testAdaptiveLayoutKeepsBoardAndControlsReachable` exercises portrait/landscape reflow, real taps (0/18 → 3/17 → 7/16), Settings isolation/Done, menu/Continue and restart. `testLargestTextLayoutAndAccessibilityAudit` also passes on the tablet. Result: `/tmp/starfall-safearea-ipad.xcresult`; 109.522 seconds of test execution.

The coordinator and dedicated design-system owner inspected the phone restart-ready comparison against the preceding-source capture. Scrolled “17 moves” now stops at the safe-area boundary below the system status bar; previously its top stroke drew behind Wi-Fi. The complete 49-cell board, +3 feedback and New game button retain their positions and size. Initial phone menu/game screenshots retain readable text and expected scrolling for content below the viewport.

The same reviewers inspected the iPad initial/reflowed landscape and maximum-text portrait restart-ready captures. The complete board, navigation, status and New game controls remain clear without observed overlap or unsafe clipping. These are inspected native screenshots, not a claim about every scroll position. captures.json records all 15 exported PNGs plus the baseline with SHA-256 hashes; full images and result bundles remain at the listed local paths. phone-summary.json and ipad-summary.json preserve the native results; log-sha256.json binds the retained logs.

The preceding crystal cloud run [38967493117](https://github.com/lbeezr/starfall/actions/runs/38967493117) passed on `ff9f736`: 86 tests (27 core, 47 hosted, 12 UI), with 35 screenshot hashes verified. It does not validate this new viewport revision; that merge receives its own CI run.

No UI tests, assertions or audit suppressions changed. These focused checks do not repeat the entire preceding suite. Actual human VoiceOver speech/focus, system Reduce Motion operation, physical-device behavior and frame pacing remain unverified by this batch.
