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

## Save/relaunch and Calm Effects acceptance — 2026-10-16

- Owner: resume reliability lane; independently reviewed source `8fa040ba6a092dfbe986522571298f61c17857a3`.
- Successful exact-head run: https://github.com/lbeezr/starfall/actions/runs/38846694217 . Xcode 26.3, iPhone SE (3rd generation), iOS 26.2 Simulator.
- 14 core tests passed; native build passed; exactly two UI tests passed, zero failures/skips. Original flow: 45.956 seconds. Persistence/resume flow: 75.828 seconds.
- Fixed initial-board loss before the first move by saving on Play. Native test proved the original seeded board survives relaunch over a different fallback seed, then verified committed-turn relaunch, settled Home/activate, persisted Calm Effects and another legal move (score 7, moves 16).
- Shared presentation settlement cancels root/child animation and renders committed rules state when inactive or motion reduction becomes enabled. This does not prove rapid interruption during the 480 ms animation or system accessibility usability.
- Four named XCTest screenshots exported and SHA-verified. Resumed and Calm-turn captures show legible score/moves and no obvious clipping/error overlay. Evidence checked 2026-10-16 03:50 UTC.
- Artifact `12023493229`: 2,543,851 bytes, one-day retention; copies retained separately. Existing spending, single-simulator and access boundaries unchanged.
- Next acceptance gaps: rapid-input/in-flight interruption, actual VoiceOver, broader device/layout coverage and signed physical-device distribution remain separate. No new game features or release-readiness claim implied.

## Terminal outcome and replay acceptance — 2026-10-16

- Owner: endgame acceptance lane; independently reviewed source `88738c204e8b33698da9de89334893480faa9a94`.
- Successful run: https://github.com/lbeezr/starfall/actions/runs/38862074669 . Xcode 26.3/17C529, iPhone SE (3rd generation), iOS 26.2 Simulator.
- 15 core tests, native build and exactly three UI flows passed, zero failures/skips. Terminal flow: 72.342 seconds; total UI execution: 197.139 seconds.
- Fixed restored terminal saves displaying generic tap instructions. Shared outcome messaging now applies both after a final move and after saved-state restoration.
- DEBUG-only fixtures replay real legal moves to the penultimate state; native input performs the final tap. Both outcomes retain score/moves/message after an extra tap and argument-free relaunch, then restart successfully. This is deterministic acceptance, not evidence of player difficulty or natural-play balance.
- Six named UI captures exported; all eight PNGs including smoke images and the ZIP were hash-verified. Human review at 06:47 UTC found clear terminal feedback and visible New game controls without obvious clipping: win 70/70 with 2 moves; loss 64/70 with 0 moves.
- Artifact `12029922915`, 3,328,976 bytes, expires 2026-10-17 06:45:13 UTC. Retained evidence copies exist separately.
- Coverage nuance: the winning post-terminal tap targets a legal four-jewel group; the losing fixture ends without legal groups, so that repeated tap verifies terminal UI stability but does not isolate the core loss guard.
- Remaining gates stay separate: actual VoiceOver, rapid/in-flight interruption, broader device/layout coverage, physical-device performance and signed distribution. No new feature or release-readiness claim.


## Accessibility and privacy checkpoint — 2026-10-16 12:27 UTC

- Runtime `2f2bb2081de01a6d31dfe62a694f6005cf7dbe56`, run https://github.com/lbeezr/starfall/actions/runs/38898933808 : failed fourth UI flow on Settings `Text clipped`, identifying Calm effects.
- 15 core tests, native build, three previous UI flows and semantic bundled privacy-manifest comparison passed. Large-text gameplay reached and passed its scoped audits. No complete accessibility or VoiceOver pass is claimed.
- All eight named UI captures were exported under `partialEvidenceOnly: true`; ZIP and all ten PNG hashes verified. Settings screenshot inspected and retained; visible wrapping alone does not overrule the native audit failure.
- Artifact `12045617965`: 3,803,271 bytes, expires 2026-10-17 12:24:38 UTC. Source-bound copies retained separately.
- Prior run 38896574407 hit its 15-minute job limit during cold simulator preparation, before any audit assertion. Current bounded setup timing succeeds: status-bar 15.725 seconds, install 33.567 seconds, first launch 17.77 seconds, second launch 1.084 seconds. Job maximum is now 25 minutes; per-test maximum remains 180 seconds; no retries or broader permissions introduced.
- Open gate: diagnose accessible text bounds/row sizing, review the minimal repair and rerun all four UI flows. Prepared interruption tests and approved icon registration are not yet integrated or natively validated.

## 2026-10-16 13:25 UTC — reliability and icon native evidence

Exact runtime `3405595abad1c66181d74ce0ed0c2304007df64c`, [run 38905933131](https://github.com/lbeezr/starfall/actions/runs/38905933131): native build, 15 core tests, four hosted tests (zero failures/skips), three prior UI flows, icon catalog packaging and privacy semantic validation passed. The fourth UI flow failed the unsuppressed Settings text-clipping audit on Calm effects. Eight UI screenshots remain partial evidence; the total build is failed.

The hosted tests cover controlled presentation completions, committed saved state and busy-input rejection. They do not establish real rapid-tap delivery or actual frame-timed interruption. Icon Assets.car and AppIcon metadata passed packaging; Home Screen appearance is not yet verified.

Artifact `12048743235` (3,803,747 bytes) expires 2026-10-17 13:24:45 UTC. Retained ZIP SHA-256 `4161c0be585e9c5b97635116c2773ab73fedb9989c428268a014b844fa4d6a33` and all ten PNG hashes verified. Native diagnostics showed Calm effects text frame `(32,355.5,153.5,125.5)` within a `(16,336.5,343,163.5)` switch row. Extra vertical padding did not fix the audit; the next candidate changes actual large-text layout rather than suppressing the issue.

## 2026-10-16 13:42 UTC — cold simulator launch timeout

Exact source `ae01b99f44d7871e7211861377932e75ed5c05e0`, [run 38908327230](https://github.com/lbeezr/starfall/actions/runs/38908327230): 15 core tests, native build, icon packaging and privacy validation passed. The first `simctl launch` exceeded its 300-second bound (300.940 seconds, exit 124); no PID was returned. Status-bar setup (6.731s) and install (18.618s) succeeded. No UI tests, hosted tests or screenshots were reached. This is an infrastructure/launch failure, not evidence that the Settings repair passed or failed its audit; the cause beyond the blocked launch remains unknown.

Compact artifact `12049866811` retained and verified, SHA-256 `e6c9b7aea9ccefa5b68c9a5200ae6791e25de899f483a8ed962d7d39601a477c`, expires 2026-10-17 13:40:05 UTC. The next reviewed source is to be tested on a fresh runner with the same time and evidence limits.
