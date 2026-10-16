# Validation record

2026-10-16 UTC, Linux cloud workspace.

## Executed successfully

- Official Swift 6.0.3 release toolchain downloaded from download.swift.org into temporary workspace (no system install)
- Pure package debug build and **12 XCTest tests passed, 0 failures**, 0.434 seconds test time
- Includes 200 deterministic initial boards and complete plays over 100 seeds
- Swift frontend syntax parsing of both App source files passed; **this is not Apple SDK type-checking or an iOS build**
- Shared Xcode scheme XML parsed successfully
- Shell syntax check of CI script passed
- Independent source review; VoiceOver animation-lock issue and gravity test fixture repaired, regression coverage expanded

Exact core command (temporary tooling/cache paths are environment-specific):

```sh
CLANG_MODULE_CACHE_PATH=/tmp/starfall-swift/clang-cache \
 /tmp/starfall-swift/swift-6.0.3-RELEASE-ubuntu22.04/usr/bin/swift test \
 --cache-path /tmp/starfall-swift/cache \
 --config-path /tmp/starfall-swift/config \
 --security-path /tmp/starfall-swift/security
```

The initial unconfigured invocation failed before compilation because its default home-directory compiler cache was read-only. The successful command explicitly used writable temporary build/cache locations and did not change permissions or write the home cache.

## Not run / blocked

- iOS app build and link: Xcode and Apple SDKs are unavailable in this Linux environment
- Simulator/device launch, screenshots, animation inspection and accessibility testing
- GitHub workflow execution: manual workflow is prepared, not dispatched
- App Store/device distribution signing

No visual or device quality claim follows from these core test results. See `ACCEPTANCE.md` for remaining runtime checks. The manual cloud workflow describes a future Apple-tooling validation route, not evidence of a completed run.

## Independent exact-head rerun

2026-10-16 01:57:53 UTC: core tests independently rerun at
`b884b452ff9c2832f19fea0fc85fe4cea662f674` with the same explicit writable-cache
command above. All 12 XCTest cases passed, zero failures, 0.53 seconds test time.
No Apple SDK, simulator or physical-device validation was performed.

## First native cloud evidence

Run https://github.com/lbeezr/starfall/actions/runs/38840259665 succeeded at
source `15d068b6231d7fbb8f5c05867361419c549c5bb6` on Xcode 26.3 / Swift 6.2.4 /
ARM64 with iPhone SE (3rd generation), iOS 26.2 Simulator. All 12 core tests
passed and the native app built. Initial and post-clear settled launches stayed
alive and produced inspected screenshots. Initial HUD: 0/70, 18 moves; settled:
3/70, 17 moves. These were separately launched deterministic states, not evidence
of a performed touch gesture or observed animation. Physical-device behavior and
accessibility are still unverified. Later source changes need their own run.

## Native interaction and glass-material acceptance — 2026-10-16

- Owner: native interaction/CI lane; independently reviewed incremental source.
- Accepted source: `26d76f6473268d2d62fcc3e45079e1d10d7e783e`.
- Evidence: https://github.com/lbeezr/starfall/actions/runs/38843933811 — successful; Xcode 26.3, iPhone SE (3rd generation), iOS 26.2 Simulator.
- Core: 12 tests passed. Native build passed. One XCUI flow passed with zero failures (49.653 seconds).
- Actual coordinate tap cleared three jewels, changed score from 0 to 3 and moves from 18 to 17. Menu/Continue retained the game. Sound on/off and reopened muted state passed. Restart restored 0 score and 18 moves.
- Named native screenshots: `real-touch-post-clear` captured 2026-10-16 03:16:57.570 UTC; `real-touch-restarted` captured 03:17:25.464 UTC. Both exported and SHA-256 verified; human inspection found legible HUD, distinct glass silhouettes and no obvious clipping/error overlay.
- Artifact: `12023145003`, 1,747,618 bytes, one-day GitHub retention. Screenshot copies are retained separately; CI links may outlive artifacts.
- Earlier failures were kept visible: run 38841903130 failed pre-tap score-label assertion; run 38843063380 passed the tap/Continue but failed sound-toggle assertion. Explicit accessible score labeling and switch-control targeting were reviewed and verified by the accepted run.
- Scope: simulator interaction and settled rendered states. This does not establish physical-device performance, real VoiceOver usability, rapid-input exclusion, animation aesthetic quality, signed distribution or release readiness.
- Next permitted transition: bounded remaining MVP acceptance, keeping deterministic core separate from presentation. Physical-device/TestFlight delivery depends on separately established Apple signing/account access; no new access or purchases inferred.
