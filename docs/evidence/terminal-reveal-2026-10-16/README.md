# Settled terminal result reveal — 2026-10-16

Based on `80c5a4983067b07e6a7b47c31d28d03802c6a33f`. Exact source hashes, the unchanged core tree, retained log hashes and every exported PNG hash are in verification.json.

Compact-phone evidence for the preceding layout placed terminal New game entirely below the viewport. The existing ScrollView now reveals the result/action region once after the turn settles, including entry into a restored terminal game. It defers while inactive or covered, preserves the same scene and geometry, and never forces accessibility focus. The passive scroll destination includes the shared 20-point bottom inset without adding layout height. Oversized content starts with the outcome; a fitting tablet sidebar stays in place. Restart returns to the initial reading position. Scroll transactions explicitly disable animation.

Validation used local Xcode 27.0 and iOS 27.0 (24A434), arm64:

- `swift test`: 53 passed, zero failures; core sources are unchanged by this batch.
- Ordinary Release simulator build passed, without testability overrides or fixture launch arguments. This is build evidence, not a Release play check.
- Compact iPhone SE (3rd generation): 2 UI cases passed. The terminal case checks win, loss and last-move win; result/action frames must be within the viewport before any helper scrolling or tapping. It checks saved-terminal entry, unchanged terminal rules and restart position. The maximum-text case checks outcome visibility, unsuppressed `textClipped`, `sufficientElementDescription` and `hitRegion` audits, real restart and initial navigation.
- iPad mini (A17 Pro): 2 UI cases passed. All three terminal fixtures and restored states pass in landscape; board Y position remains fixed. Ordinary adaptive play, portrait/landscape reflow, actual clears, Settings, menu/Continue and restart pass.
- The same built iPad candidate passed 3 further UI cases: production accessible-cell invalid/valid input, Calm terminal win/loss with background/resume/restart, and rapid taps/invalid taps/cancelled drag.
- All seven accepted native case executions report zero failures, skips, expected failures or runtime warnings. `git diff --check` passes. Source and test review found no concrete blockers.

The first candidate passed the maximum-text audit but failed normal terminal visibility because New game touched the viewport edge. Its result bundle and log remain at `/tmp/starfall-terminal-phone.xcresult` and `/tmp/starfall-terminal-phone.log`; verification.json records their summary/log hashes and the failure. The correction extends only the invisible scroll destination into the existing shared inset. The original visibility assertion is unchanged.

Accepted bundles are `/tmp/starfall-terminal-phone-inset.xcresult`, `/tmp/starfall-terminal-ipad.xcresult` and `/tmp/starfall-terminal-input.xcresult`. Summaries are retained here. Native invocations disable parallel testing, retain 90-second default/240-second maximum allowances (terminal case180), and use local `-collect-test-diagnostics never` to avoid prior Xcode failure-finalization stalls. Assertions, captures and audits remain enabled. Tablet terminal captures use full-screen screenshots, avoiding the earlier app-only landscape crop.

The coordinator and dedicated design-system owner inspected the corrected compact-phone win/maximum-text captures and tablet win/restored-loss captures. The design owner also inspected phone restored-loss/restart and tablet active-play reflow. Result text and New game are complete with the expected bottom inset; the tablet board and sidebar remain legible and stable. Compact-phone HUD text may be scrolled partly above the viewport, while the result retains complete outcome and score. Maximum text retains ordinary scrolling. These are inspected native images, not evidence about every possible scroll position.

This batch does not claim human VoiceOver speech/focus, system Reduce Motion operation, physical-device interaction, frame pacing or ordinary Release play. Calm effects and the production accessible control structure were exercised, but neither substitutes for those human/system checks. The separate keyboard candidate remains unmerged. The preceding full CI run is allowed to finish before integration; the new merge receives its own full CI run.
