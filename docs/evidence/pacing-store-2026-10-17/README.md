# Cadence store boundary verified locally

**Result:** Partially verified · **Owner:** task 3 · **Date:** October 17, 2026

The store consumes Core cadence, preserves one deadline and same-sky replay, and exposes immutable next-shower cues plus Debug-only measurement. All 72 Core and 33 focused hosted tests pass; Debug test build, Release build and hygiene pass. This establishes scheduling and committed-state behavior, not native gesture, animation, accessibility or player preference acceptance.

**Next action:** Tasks 4/5 consume the [store contract](../../design/PACING_STORE_CONTRACT.md) and canonical test fixture. Task 6 owns native acceptance. Remote publication remains pending; shared main, the phone installation and updater were untouched.

## Outcomes against acceptance

| Criterion | Result | Scope |
| --- | --- | --- |
| Next interval/phase before scheduling | Pass | Manual and automatic opening/two phase boundaries; canonical B lookup is test-only. |
| No catch-up; scheduled vs delivered time | Pass | Late callback, busy deferred rain, original deadline retained through delivery, fresh interval at commitment. |
| Input and interruptions | Pass | Existing rapid/repeated clear, invalid taps, manual busy input, settings/balance, pause, background/resume, restart, terminal and stale callback tests retained. Candidate checks additionally cross warning/phase boundaries with settings, pause and motion settlement. |
| Trace across deadline | Pass at hosted boundary | Corrected baseline uses a valid five-star trace during opening. New observer check classifies automatic invalidation without finger-down deferral. No actual native gesture claim. |
| Saves, replay, historical contracts | Pass | Core 72 tests; hosted restore/save-before-animation, historical/First Light override rejection and Core-owned same-sky replay. No candidate policy persisted. |
| Shared B fixture membership | Pass | SwiftPM test discovery; explicit StarfallAppTests source reference; normal app sources exclude fixture. Standalone compilation succeeds without XCTest. |
| Native play, visual/full-motion, Reduce Motion experience, accessibility, actual VoiceOver, physical device | Not run | Task 6 retains native acceptance. Hosted presenter settlement tests do not verify animation or VoiceOver. |

## Verification context

**Tested source:** clean `3c09532d78400f877b4961073de05de3afa33828` on `codex/pacing-store-contract`, in `/Users/lbeezr/.codex/worktrees/pacing-store/Starfall`. No dirty build-affecting paths. This includes Core handoff `15c10288dc21832742005d0406b11b017b5b4e16`, corrected baseline fixture `21aae67` cherry-picked as `d0593de`, and baseline evidence `8210cf6` as `b032534`. This report is the only subsequent source difference, with its evidence index link.

**Environment:** Xcode 27.1 (`27A9275`), arm64; focused hosted tests on iPhone 17e, iOS 27.0, simulator `4103C352-DFC2-493E-A224-DE4CE3D50889`, after task 1 released it. Separate DerivedData; no global accessibility setting changes. An earlier private-simulator build was interrupted when incorporating the corrected baseline; final committed-source results below supersede preliminary runs.

| Check | Command | Result |
| --- | --- | --- |
| Core | `swift test` | 72 passed, zero failures. |
| Debug hosted/build | Command below | 33 FallingSkyStoreTests passed, zero failures. |
| Release simulator | Command below | Build succeeded. |
| Hygiene | `python3 scripts/ci-hygiene.py` and `git diff --check` | Passed. |
| Offline fixture reuse | `swiftc -O Sources/StarfallCore/*.swift Tests/StarfallCoreTests/TimingCycleFixture.swift /tmp/starfall-pacing-fixture-check/main.swift -o /tmp/starfall-pacing-fixture-check/check` | Passed; driver asserts count-9 warning/count-10 delay and prints `announcedCycleV1`. |

```sh
xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,arch=arm64,id=4103C352-DFC2-493E-A224-DE4CE3D50889' \
  -derivedDataPath /tmp/starfall-pacing-store-final \
  -only-testing:StarfallAppTests/FallingSkyStoreTests -parallel-testing-enabled NO \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 60 \
  -maximum-test-execution-time-allowance 90 \
  -resultBundlePath /tmp/starfall-pacing-store-committed.xcresult \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES \
  DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual test

xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Release \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/starfall-pacing-store-release \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

Raw logs and compact hosted summary are local ignored outputs at `artifacts/pacing-store-2026-10-17/`; the full result bundle remains at the command's temporary path. These are machine-local, not published evidence artifacts.

Store SHA-256: `4b1831c68870403ef2841597e0a6ff4d1bc7f8d729a6cd7eff931abf2e154777`.
Fixture SHA-256: `873a78ded0501fcc4bb14123a92b93d634a10015aa16a97083eaa07b7d0e51e0`.

## Limits for downstream measurement

Observation has no production buffer/logging and does not choose scheduling. Gate windows use the final `state` event at each monotonic timestamp; intermediate schedule/commit events are not input windows. The original due deadline and delivery time remain separate. Generation invalidation is observable; actual trace starts, completed paths and gesture cancellations still belong to the test/native input harness. Candidate B remains unadopted, with no permanent production flag or save identity.
