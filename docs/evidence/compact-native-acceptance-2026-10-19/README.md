# Compact native checks follow the scrollable playfield

**Result:** Verified locally; full remote matrix pending · **Owner:** current implementer · **Date:** 2026-10-19

All ten recorded native failures are classified and corrected. Nine used obsolete viewport assumptions; one missed a short storm phase during repeated hierarchy diagnostics. Tests now follow the actual scrolling playfield, and failed system-motion tests restore their setting through XCTest teardown. Game rules, saves, geometry and animation are unchanged.

**Delivery:** [PR #151](https://github.com/lbeezr/starfall/pull/151) merged to `515f7f8`; the canonical updater verified **dev.84fd0fa338** on the original phone. Core tests and signature passed; main CI was pending at installation. [Receipt](delivery.json). No player-data reset or automatic launch.

**Next action:** Use the installed app for physical-play acceptance; observe the next complete remote matrix separately.

## Acceptance

- Expose gesture endpoints together before drawing, and expose controls before waiting for physical hit readiness. Scrolling must not commit a gameplay action.
- Verify guide text remains below the board and readable to its end. Fixed-layout inner scroll keeps controls fixed; flowing outer scroll may translate them while preserving their relative order and committed board.
- Keep all exact move/score, restore, interruption and system Reduce Motion checks. Do not turn missing/disabled controls into passes or suppress normal animation.
- Extract the independent sky-flow suite from its near-1,200-line file, preserve test identities/counts, and verify target membership.
- Record remote-only failures separately if they do not reproduce; no claim that a passing local sample establishes green remote CI.

## Baseline

Clean main `0bcc8529a2f303a93c501fbabc6e5d27793b593f`, dev.07b4062290; Xcode 27.1, iOS 27.0, iPhone SE3 `Starfall Landing Compact Acceptance`. Ten exact methods from the earlier Xcode 26.3 CI log run unchanged. Only delivery/evidence documentation differs after the test build began. Raw result: `artifacts/compact-native-acceptance/baseline.xcresult`.

## Reproduction and correction

The unchanged compact baseline produced one pass and nine failures. Four constellation checks either began a drag outside the viewport or treated the flowing page as a fixed overlay. Three critical-mass and two Dusk checks waited for offscreen controls to become hittable without scrolling. [Baseline](baseline.json). The shared native helper now reveals complete targets through the non-playing edge, requires them to remain hittable, and fails if they cannot fit. Paused trace/guide preparation requires a real committed-board snapshot and verifies it remains unchanged. Guide read-through checks retain text-before-actions order and exact board/action relative positions: an outer page translates both, while an inner guide translates neither. Exact scores, survivor identities, restore and interruption assertions remain.

The corrected `188db84` run passed all nine original visibility cases plus six siblings (**15 passed**), but reproduced the previously intermittent storm-count failure. The tool transport timed out at 300 seconds; the existing Xcode process continued. Its finalized result bundle was recovered without rerunning: 16 tests, 15 passed, one failed, no skips. Build inputs were committed before execution. The later storm-only test edit was not part of this compiled run.

The storm log sampled at t=13.57 and t=16.59 while the fixture's original V2 count can last 1.7 seconds. Repeated hierarchy diagnostics on each failed element predicate could span the complete state. `af34db2` keeps all four exact counts in order and each original eight-second bound, using a direct static-text label in a condition predicate. Three fixed iterations passed (17.840, 18.124 and 17.608 seconds); these were not retry-until-success runs. No clock, animation or fixture cadence was changed.

The independent 386-line `SkyFlowInteractionTests` body moved byte-for-byte in `f43fa87`; the parent file is now 800 lines. Explicit target membership and the source-counted native plan retain 116 development UI methods and 303 hosted methods. The two ending/replay native checks pass after extraction.

## Failed-test cleanup

A later broad integration run correctly rejected full-motion preconditions: 277 passed, five failed and 23 skipped while system Reduce Motion remained enabled. The baseline log shows the original critical-mass case toggled Reduce Motion on, then stopped at its failed assertion without reaching its Swift `defer`. This contaminated later tests, not saved gameplay. Both that case and the analogous Dusk case now register restoration with XCTest before changing the setting; the other motion-setting owners examined already use registered teardown.

Native Settings calibration confirmed the enabled state and restored it off. A temporary failure probe then inserted one deliberate failed assertion after enabling Reduce Motion with `continueAfterFailure = false`. The registered teardown restored the original off state; a separate native check passed without changing the setting. The probe's expected result is one intentional failure and one verification pass. Both temporary test edits were removed byte-for-byte afterward. No new permanent fixture, skipped assertion or runtime motion override was added.

## Final verification

Committed source `c1bee15`, runtime **dev.84fd0fa338**, with only the listed evidence/readme documents dirty. [Commands, source, counts and artifact paths](verification.json). The project fingerprint changes because the two test files are explicit target members; App and Core runtime sources are unchanged.

- Core: **172 passed**. Native-plan Python checks: **3 passed**, unchanged 116 development UI / 303 hosted methods.
- Compact final integration: **303 hosted + 2 actual system Reduce Motion flows passed**, zero failures/skips. Normal system motion was independently verified before this run.
- Original compact visibility failures and six siblings: **15 passed**; the separately corrected storm method passed **three fixed iterations**. Compact gap and Opal checks also passed.
- Larger phone: **6 native checks passed**, covering maximum-text drawing, both guide variants, interruption/rotation, gap swipes and chosen Opal identity.
- Debug test build and Release Simulator build: passed on Xcode 27.1, iOS 27.0. Hygiene and diff checks passed.

No new player UI or assets require refreshed screenshots. This maintenance batch preserves the existing inspected gameplay captures; native physical input verifies target geometry. Full remote CI, actual VoiceOver at RC, minimum-iOS runtime, physical comfort and enjoyment remain separate acceptance. Earlier failed runs and the deliberate failure probe are retained above rather than counted as passing integration.
