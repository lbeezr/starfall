# Restore and CI startup repair — 2026-10-16

Based on `db71be94ac8ff8083ef308073c41d1523b83a247`; exact changed-source hashes and local log/capture hashes are in verification.json.

[CI run 38976368923](https://github.com/lbeezr/starfall/actions/runs/38976368923) failed the experiment background/relaunch assertion before exceeding the 25-minute job cap. At `StarfallExperimentInteractionTests.swift:97`, the restored shower count was zero instead of one. All 53 core tests and 15 other UI tests passed. Hosted tests and artifact export were not reached. The complete retrieved log is retained locally at `/private/tmp/starfall-ci-38976368923/job.log` and its hash is recorded here.

`StarfallExperimentView` can construct stores for discarded SwiftUI values. Previously each reset-enabled initializer deleted and replaced the saved game. Initialization is now read-only; the retained store persists its chosen game when activated, before starting its clock. A hosted regression proves that discarded reset stores preserve the existing bytes, restoration still works, and an intentional activated reset saves the fresh paused game. This tests the destructive mechanism found in source; the old CI log alone cannot prove the precise SwiftUI lifecycle that triggered it.

The CI script now requests boot of its selected simulator before compiling the app, overlapping those independent tasks. It retains the readiness barrier before installation, the same single simulator, cleanup, all checks and the 25-minute cap. This addresses avoidable serial startup; actual cloud timing savings and deadline completion remain pending the new run.

Local Xcode 27.0 / iOS 27.0 (24A434), arm64 iPad mini (A17 Pro):

- `swift test`: 53 passed, zero failures.
- Debug native build and test: 59 hosted tests plus the unchanged `testBackgroundRelaunchAndAutomaticOverflow` passed; 60 total, zero failures/skips/expected failures, no runtime warnings. The UI test ran through background/relaunch, overflow and New sky (114.857 seconds).
- `bash -n scripts/ci-simulator.sh` and `git diff --check` passed. Script mode remains 100755.
- An independent agent reviewed all three changed files and found no concrete blockers.

The native result is `/tmp/starfall-restore-validation.xcresult`; native-summary.json preserves the result. The invocation selected all `StarfallAppTests` and the named UI case, disabled parallel testing, retained 90-second default/240-second maximum per-test allowances and used local `-collect-test-diagnostics never` to avoid a previously observed Xcode failure-finalization stall. No UI assertion, fixture, screenshot capture or cloud diagnostic setting was changed.

This focused batch does not repeat the entire UI suite. It makes no new claim about human VoiceOver, system Reduce Motion operation, physical devices, visual review or frame pacing. The keyboard candidate remains separate and unmerged.
