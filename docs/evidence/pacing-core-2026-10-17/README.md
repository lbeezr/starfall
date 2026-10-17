# Versioned cadence and test-only timing cycle

**Result:** Partially verified · **Owner:** task 2 · **Date:** October 17, 2026

Core now exposes the [cadence consumer contract](../../design/PACING_CORE_CONTRACT.md): versioned pure interval lookup and policy-preserving replay. Production timing remains unchanged; B exists only in test support. All 72 Core tests pass. Native integration acceptance remains outstanding.

**Next action:** Coordinator integrates the focused commit; tasks 3–5 consume the public values and run native scheduling/cue/comparison checks after task 1 releases its simulator. No phone installation or push was performed.

## Outcomes against acceptance

| Criterion | Result |
| --- | --- |
| Exact opening and cycle/warning boundaries | Pass: all slots over two complete cycles; warning at count 9, faster interval at 10 |
| Existing saves and First Light | Pass: missing markers preserve timing; historical fixture continuation remains green; challenge balance/replay fixed |
| Replay and local balance | Pass: same-sky replay retains generation markers, cadence and selected balance; non-brisk B lookup suppresses cycling |
| Generator parity | Pass: matched accepted clear/shower actions over 50 seeds and existing 200-seed opening coverage; no generator changes |
| Terminal freezing / invalid versions | Pass: rejected terminal inputs preserve cadence; unknown versions reject decoding and contradictory markers fail validation |
| Native scheduling, input and interruptions | Not run in this task; simulator reserved for task 1; no Store changes |
| Visual/animation, Reduce Motion, accessibility and device | Not run; Core tests/builds do not establish these results |

## Verification context

Source base: `571ccd1f3ca2f7ba135c35281ee3820781a5440f`; branch `codex/pacing-core-contract`, separate managed worktree `pacing-core/Starfall`. Tested working-tree changes are confined to `Sources/StarfallCore/{FallingSky,SkyCadence}.swift`, `Tests/StarfallCoreTests/{FallingSkyTests,SkyCadenceTests}.swift` and accompanying documentation. No app, project, resource or phone changes. New Core source is included automatically through the app's local `StarfallCore` Swift package dependency.

Toolchain: Xcode 27.1 (27A9275), iPhoneSimulator27.1 SDK; builds target generic iOS Simulator, not a launched device. `swift test` ran on the host, arm64e macOS test runner.

| Check | Command | Result |
| --- | --- | --- |
| Core | `swift test` | 72 tests, zero failures; `/tmp/starfall-pacing-core-tests.log` |
| Hygiene | `python3 scripts/ci-hygiene.py` | Pass |
| Whitespace | `git diff --check` | Pass |
| Debug simulator-target build | `xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/starfall-pacing-core-derived CODE_SIGNING_ALLOWED=NO build` | Pass |
| Release simulator-target build | Same command with `-configuration Release -derivedDataPath /tmp/starfall-pacing-core-release` | Pass |

Raw build output: `/tmp/starfall-pacing-core-debug.log` and `/tmp/starfall-pacing-core-release.log`. SwiftPM reports existing unhandled README warnings; no warning suppression was added.

## Findings and remaining limits

The first run exposed representation compatibility: explicitly marking old no-opening initializers changed equality with frozen saves. They retain the missing marker and resolve to `originalV1`; the original equality/continuation assertions remain intact. Synthetic pre-tuning fixtures now remove the new field as well as fields absent in their historical schema. A malformed hybrid test fixture initially retained today's generated preview after deleting the generation marker; it was corrected to the seed-5 independent-color initial forecast/RNG. Final checks include replay from overflow while retaining the original generation contract.

B's identity is fixture metadata, not a production save value. Native comparison must keep its metadata isolated; adoption needs an explicit production identity/persistence decision. No enjoyment, human rhythm preference, native deadline correctness or trace timing claim follows from these checks.
