# Restore compiler compatibility at the trace-start boundary

**Result: Partially verified — local checks passed; older CI compiler pending.** Owner: current implementer.

Main run 39081128237 failed on Xcode 26.3 because hypot produced Double while the nearest-start candidate tuple requires CGFloat. Local Xcode 27.1 accepted that inferred conversion. Make the geometry boundary explicit without changing hit radius, candidate ordering, Core or saves.

Acceptance: local Core, hosted coarse/grazing/curved/retraced input checks, native Opal planning/held-touch input, and Release build pass; inspect neighboring math uses for the same return-boundary mechanism. Record that the older compiler remains unverified until main CI compiles this source. Keep the original failure and subsequent run distinct; no retry or assertion weakening establishes compatibility.

## Correction and extent examined

The returned nearest-start tuple explicitly requires CGFloat. The inferred hypot result was Double under the CI compiler; converting it at the distance boundary gives the tuple the required type without changing the distance, radius or ordering on supported 64-bit platforms. Examined every hypot call in App: the two drag-slop comparisons in ConstellationTraceSurface and the remaining ripple/contact/trace-spacing uses in FallingSkyScene do not return this mismatched tuple. Also inspected the analytic segment intersection/sqrt path in ConstellationTraceHitTesting. Those paths were preserved; this does not claim every possible SDK inference issue is eliminated.

The existing three-size coarse/grazing check now also verifies exact-center admission and rejection just outside the same radius. Curved walks, retraced branches and stale-input cancellation retain their assertions. No gesture, Core rule, save, resource or layout change is intended.

## Verification

Source: main `316f8cb` plus App/ConstellationTraceHitTesting.swift and AppTests/TraceInputPolishTests.swift; documentation added afterward. Environment: Xcode 27.1 (27A9275), iPhone 17e / iOS 27.0 (24A434), private simulator 536BCC00-751C-47BA-BC2F-C1702941CFC8, Debug arm64 unsigned. Release uses the same simulator and a separate DerivedData directory.

| Check | Result |
| --- | --- |
| Core | `swift test`: 91 passed, zero failures; `/tmp/starfall-trace-compat-core.log`. |
| Hosted and native | Five passed, zero failures/skips: three TraceInputPolishTests, native Opal two-order planning, native stationary held-touch then drag/ordinary tap. `test_sim_2026-10-18T00-16-54-266Z_pid85535_b785bd5d.xcresult`. |
| Release | Build passed without warnings/errors; `build_sim_2026-10-18T00-17-59-211Z_pid85535_990873cb.log`. Debug compiled in the test run. |
| Hygiene | `python3 scripts/ci-hygiene.py` and `git diff --check` passed. |
| CI compiler | Original main run [39081128237](https://github.com/lbeezr/starfall/actions/runs/39081128237) failed at ConstellationTraceHitTesting.swift:19. Older Xcode 26.3 is unavailable locally; a source-bound main run must verify the correction. |
| Visual/motion/accessibility | No visual or motion change; existing native input outcomes rerun. No new animation, screenshot, actual VoiceOver or physical-device acceptance claimed. |

Logs and result bundles remain under the XcodeBuildMCP Starfall workspace. Input hashes are in source.json. Next action: inspect the subsequent main CI compilation and retain its actual result; do not restart a live run or label a timeout as completion.
