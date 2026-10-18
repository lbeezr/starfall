# Fourth debt pass

**Status:** Partially verified · **Updated:** 2026-10-18

Two independent regressions reproduce from clean main `99803b38abf044bb2d0247acf79de70ac2410b7e`; [rank and acceptance](../../TECH_DEBT_FOURTH_PASS.md). The feedback fix is merged in [PR #129](https://github.com/lbeezr/starfall/pull/129); primary CI process cancellation passes execution verification. RC minimum-iOS, actual VoiceOver and physical play remain unverified.

## Stale automatic dialogue

Core-generated retained seed 0, generation current, 23 showers with one legal clear after each: the next automatic shower permits a clear in another column. Completing that clear before the shower restores an obsolete Nova cadence warning over Pip’s +3 result and repeats the warning in speech. Baseline hosted reproduction failed both assertions in `test_sim_2026-10-18T23-09-13-888Z_pid37945_a4c2b528.xcresult` under the XcodeBuildMCP result-bundles directory. An earlier Dusk fixture had no admitted clear and was rejected as a reproduction; fresh critical-mass samples likewise did not provide this overlap.

The fix requires the latest presentation ticket for automatic as well as explicit results. The completion still releases its column reservation and delivers due rain; only stale feedback is suppressed. Examined explicit clears, manual/automatic showers, terminal speech ownership, invalidated/duplicate callbacks and the presentation ledger. Rules, RNG, schema, layout and animation timing are unchanged.

## Timed-out descendants

A real Python parent spawned a child that wrote `late-output` after 0.7 seconds. The stage timed out at 0.25 seconds with status 124, but the child wrote after return. Baseline execution suite: 8 passed, 1 failed (`/tmp/starfall-fourth-tool-baseline.log`). No external simulator or user process was killed in the reproduction.

## Source and checks

Runtime checks use Xcode 27.1, iPhone 17e / iOS 27.0 (`1E9DCEF5-BF64-4052-AF8D-A6A205F711EE`), Debug, shared Starfall scheme, `/tmp/starfall-debt-derived`, with manual ad-hoc simulator signing. Base `99803b3` plus exactly these build-affecting edits:

| Path | SHA-256 |
| --- | --- |
| `App/FallingSkyStore.swift` | `342bd8d6df9008cbb61c2a0705a54480673b09aa62b32b8c26db67b8f4dc42da` |
| `AppTests/ResponsiveInputTests.swift` | `f287ad41df58a2c7a45aaa8eebd67071bf06a794b64854eecfc0fff02e0bd313` |

Concurrent script/document edits do not affect the native app. Raw output remains disposable in `/tmp/starfall-fourth-*` and `~/Library/Developer/XcodeBuildMCP/workspaces/Starfall-614375984f0e/{logs,result-bundles}`.

| Check | Result |
| --- | --- |
| `swift test` | 165 passed; `/tmp/starfall-fourth-core.log`. Core/rules/RNG unchanged. |
| Hosted `ResponsiveInputTests`, `SkyDialogueTests`, `FallingSkyStoreTests` | 68 passed, zero skips; `test_sim_2026-10-18T23-09-40-841Z_pid37945_037d9aa7.xcresult`. Includes automatic/manual feedback, duplicate/interrupted callbacks, terminal speech, clock, restart and save boundaries. |
| Native First Light goal/restore/replay, overflow, largest-text settings/dismissal | 3 passed, zero skips, 157 seconds; `test_sim_2026-10-18T23-09-58-107Z_pid37945_a8dcb968.xcresult`. |

Inspected disposable First Light complete and largest-text game screenshots from that native bundle. The result shows 20/18 and all three result actions. The largest-text game is scrolled to guidance/actions, with the header offscreen; it does not establish simultaneous viewport fit. No layout/artwork changes or retained captures were introduced. Still images do not verify falling motion. The production callback test establishes obsolete text/speech suppression; actual spoken VoiceOver is not run for this routine iteration.

| Additional check | Result |
| --- | --- |
| Native opening clear before last wave, automatic rain/settings/replay, system Reduce Motion, Welcome background/new sky, classic rapid/invalid/cancelled input | 5 passed, zero skips, 192 seconds; `test_sim_2026-10-18T23-12-42-656Z_pid37945_1806d544.xcresult`. Opening check explicitly selects normal system motion; reduced-motion check toggles/restores the actual setting. Native assertions do not establish human feel or an inspected animation recording. |
| Standalone Debug / Release simulator builds | Passed with `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES`; `build_sim_2026-10-18T23-16-11-058Z_pid37945_8b432c06.log` and `build_sim_2026-10-18T23-16-12-332Z_pid37945_58248dce.log`. |
| Hygiene / whitespace | `python3 scripts/ci-hygiene.py` and `git diff --check` passed. |

Initial standalone Debug build tried x86_64 against the ARM package cache and failed module compatibility; the initial Release invocation supplied configuration twice and was rejected. Corrected the invocation to the actual ARM simulator and set Release through session defaults, without source changes, cache deletion or warning suppression. Both corrected builds pass. Full native CI and minimum-iOS/actual VoiceOver/physical play were not run here.

## Primary CI cancellation verification

`simulator-command.py` starts each command in a new session. Timeout kills that command's inherited process group and reaps the direct child before returning status 124 and its timing receipt. It does not signal the caller's group or an unrelated child. Normal stdout, missing-command status 127, signal status 143, primary failure versus receipt failure, and simulator ownership cleanup retain their existing contracts.

The final regression requires the child to create a readiness sentinel before timeout, ignores SIGTERM, then attempts a delayed write. The identical final test fails against `99803b3`'s executor and passes the candidate. A sibling test verifies an unrelated process finishes and writes normally. Entire tooling suite: **55 passed**, zero failures, `python3 -m unittest discover -s scripts -p 'test_*.py'`, `/tmp/starfall-fourth-all-tools.log`; lifecycle subset now has ten checks. The timeout wait in this sentinel test is the failure mechanism under test, not a blanket readiness retry.

This fix applies to the primary simulator command wrapper only. Code inspection found direct-child timeout wrappers in `rc-platforms.py` (boot/tests/summary/shutdown) and `device-update.py` (build/archive/output commands). They have not received this change and were not exercised with a real timeout. Follow-up: before the next RC runner or deployment-tooling edit, give those boundaries group ownership with their existing status/evidence/install-lock contracts; verify real descendant cancellation plus mocked failure/cleanup and canonical service packaging. Ordinary descendants can still escape by deliberately starting a different session; the runner is not a process sandbox. CoreSimulator's separately managed service/app processes are not inherited children of this wrapper.

Tool checks used integrated main `f62eb7c` plus the two script edits, with no native-source changes from the verified feedback snapshot. Full primary native CI was not rerun locally. Tool-only changes do not change rule/save, UI/accessibility, artwork, animation or app-target membership. No simulator/device operation is needed to establish the process regression; real Python processes supply its evidence.

Tested script SHA-256: {"scripts/simulator-command.py": "f003d06343f1391664f3fa3e16846338098dc5910198239a9af60fda3d01c0d0", "scripts/test_simulator_lifecycle.py": "f79941990d7f6aa4706179df2f4f28f56185f411d508b5a000c59e907fcbbfdd"}
