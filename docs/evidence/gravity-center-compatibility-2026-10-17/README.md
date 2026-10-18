# Keep magnetic forecast selection compatible with the CI compiler

**Result: Partially verified — local behavior/build checks passed; older CI compiler pending.** Owner: current implementer.

Main [run 39083169793](https://github.com/lbeezr/starfall/actions/runs/39083169793), source 0cd430e, failed in Core's magneticForecast center filter: the compiler could not type-check the chained expression in reasonable time. Split the predicate into named integer heights and a guard, keeping candidate order, all conditions and the final colored-middle check unchanged. This does not change generation, RNG, preview, rules or saves.

Acceptance: unchanged encoded Core histories across legacy, Opal and gravity generations; current Core tests plus affected hosted/native checks; Debug/Release builds and hygiene. Source inspection verifies the same conjunction and min/tie order. Older Xcode 26.3 is unavailable locally; main CI must verify compilation before compatibility is claimed.

## Behavior and compiler boundary

The filter still scans centers 1 through 5 in order. Endpoint heights must match, be at most four, and sit below the middle, whose selected cell must be colored. Only the constraint expression is decomposed; the min selection and output forecast map remain unchanged. Inspected the neighboring guard, min comparator, family lookup and enumerated forecast map for the same nested-inference mechanism; no further edits were justified. This does not establish that every older-SDK compiler issue is eliminated.

## Verification

Source: main 9fc0c57 plus Sources/StarfallCore/FallingSky.swift; documentation added afterward. Xcode 27.1 (27A9275), Swift 6.4, arm64 unsigned iPhone 17e / iOS 27.0 (24A434), private simulator 536BCC00-751C-47BA-BC2F-C1702941CFC8, Starfall scheme. No new source/resource membership.

| Check | Result |
| --- | --- |
| Before/after generation bytes | Exact equality across 9,905 emitted states: three generations, forty seeds each, two ordinary-clear policies, maximum twenty-four showers. Includes 250 states with magnets and seven with occupied fields. [Parity summary](parity.json). Baseline 0cd430e has the identical rule source before this correction; temporary replay extends the existing GravityOrdinaryReplay to include gravityOrbits. |
| Core | `swift test`: 109 passed, zero failures; `/tmp/starfall-gravity-center-core.log`. Existing natural supply regression covers eighty seeds / 2,518 showers, 34 pairs and eight clears ending with a field. |
| Hosted | Six GravityStoreTests passed, zero failures/skips: saved collision/restore, due rain without catch-up, stale phases across fixture/restart/background/motion, invalid/rapid input and saved historical bytes. `test_sim_2026-10-18T00-40-22-216Z_pid85535_141ecf4b.xcresult`. |
| Native | One GravityUITests/testFloorCollisionOrbitClearAndRestore passed, zero failures/skips; `test_sim_2026-10-18T00-41-11-169Z_pid85535_6ae126c7.xcresult`. The initial command used a nonexistent GravityInteractionTests selector and ran zero tests; that result is not counted as acceptance. |
| Build | Debug compiled in the native/hosted runs. Release simulator build passed, no warnings/errors; `build_sim_2026-10-18T00-42-00-927Z_pid85535_173a82f6.log`. |
| Hygiene | `python3 scripts/ci-hygiene.py` and `git diff --check` passed. |
| Missing/separate | No new visual, smooth-animation, actual VoiceOver, physical-device or human-preference result. The predicate refactor changes no presentation; broader acceptance remains source-bound to the gravity integration. Older CI compilation remains pending. |

Raw replay/compile output is under ignored artifacts/gravity-center-compatibility. Native results/logs remain in the XcodeBuildMCP Starfall workspace. Source hashes are in source.json. Next action: inspect a main CI run containing this correction; keep cancellations and failures distinct from a passing compiler check.
