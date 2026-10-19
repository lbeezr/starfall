# Recover full development CI

**Result:** Partially verified · **Owner:** current implementer · **Date:** October 19, 2026

Repair simulator discovery, remaining UI regressions and the partial screenshot captures in separate verified batches. Acceptance requires a complete development run: tooling checks, core tests, Debug/Release builds, source-counted UI/hosted matrices with zero failures/skips, and valid compact evidence. Native screenshots require direct inspection; a passing assertion alone does not accept rendering. Physical delivery and full RC VoiceOver are outside this development task.

**Next action:** Complete the full development matrix on the merged fixes, inspect its exported evidence and record the passing source/run before closing remote acceptance.

## Batch 1: simulator host

[Run 39274515592](https://github.com/lbeezr/starfall/actions/runs/39274515592), attempt 1, source `73ad2beddb4c247fe9190f356c518f433731ef31`, job `118136124483`, passed all five Python suites and 177 core tests, then `simctl list devices available --json` timed out after 30.021 seconds. The runner was ARM64 macOS 15 with Xcode 26.3. No native build/test ran.

[Apple's Xcode 26.4 notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-26_4-release-notes) identify a repaired `simdiskimaged` loop that could hang simulator commands (172343027), and require macOS 26.2+. [GitHub's macOS 26 image](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md) includes Xcode 26.6. Change the existing job to standard `macos-26`; retain the 30-second discovery bound, one runner, matrix, public-main triggers and cost guard. [Standard runners remain free for public repositories](https://docs.github.com/en/actions/reference/runners/github-hosted-runners#standard-github-hosted-runners-for-public-repositories).

This is an evidence-backed environment correction, not proof that Apple's reported mechanism caused this timeout: no service crash sample was captured. The remote discovery receipt and full run must verify the outcome. Local static/tooling checks cannot emulate GitHub's VM.

**Remote result:** [Run 39276071444](https://github.com/lbeezr/starfall/actions/runs/39276071444), source `451219d`, completed inventory in 7.132 seconds and boot in 4.994 seconds on macOS 26.6.2 / Xcode 26.6, then passed the Debug build. [Compact receipt](discovery.json). The next verified integration cancelled that run during Release compilation; this proves successful discovery/build on the new environment, not full CI acceptance or a universal cure for simulator service failures.

## Batch 2: room for the complete serial matrix

[Run 39201250877](https://github.com/lbeezr/starfall/actions/runs/39201250877), source `515f7f8`, job `117894490089`, reached only 35 UI cases before cancellation at 05:23 UTC. Native UI began at 04:58:38; the completed cases consumed 1,445.977 seconds. Its 29 passing cases alone consumed 1,231.546 seconds (42.47 seconds/case); six cases failed. This is observed partial-run throughput, not a successful-suite median, and does not prove which cancellation mechanism fired.

The current source-counted plan selects 120 UI and 316 hosted cases. Extrapolating only those passing UI durations gives about 85 minutes of UI work, before setup, Debug/Release builds, hosted tests and export. A 35-minute whole-job cap is incompatible with that workload. Raise the single-job bound to 150 minutes to accommodate the existing coverage and variation; keep the 90/240-second UI test bounds, hosted/operation bounds, serial execution, zero-retry policy and all count/skip gates. Revisit the estimate using the first complete passing run, not failed-test elapsed time. No new runner or parallel job is added.

Verification: all five existing Python suites pass (55 checks); the workflow parses with Ruby's YAML parser, hygiene and diff checks pass. These checks use main `451219d` plus the workflow/script README/evidence changes. No runtime input changes. Complete remote timing remains pending.

## UI and capture investigation

The compact SE simulator used by the maintenance reproduction was in landscape at the fresh launch, while earlier XCTest attachments had portrait dimensions and cropped content. The fresh simulator screenshot renders its visible landscape viewport. Investigate orientation/setup and scrolling at the native test boundary before changing game rendering. Preserve existing outcome assertions, historical Dusk fixtures, normal-motion checks and all selected tests.

## Batch 3: native input readiness and portrait captures

**Verified subset:** five UI cases pass, zero failures/skips, on Xcode 27.1 / iOS 27.0 / iPhone SE (3rd generation), Debug. Source `451219d` plus only `UITests/FallingSkyInteractionTests.swift` as a native build input; [hashes and capture provenance](readiness.json) identify that snapshot. Subsequent workflow/docs commits do not change those runtime/test inputs. `swift test` passes all 177 cases; the native test action builds the app and test targets. Hygiene/diff checks pass. Release is inapplicable to this test-only correction.

The class now explicitly starts in portrait and reuses the existing non-playing-edge scroll helper for sky controls; menu navigation shares one local helper. The Calm Effects row is reached through the existing lazy-menu helper. Compact scrolling keeps both paused actions physically reachable; the original board-size, hittability, exact score, menu suspension, forecast-label, restoration and early-cascade assertions remain. No timeout, motion, rule or save changes were made.

Exact selected methods: `testCompactHUDMenuSuspendsWithoutChangingPauseChoice`, `testCompactPlayfieldKeepsControlsVisible`, `testDarkStarInfluenceRestoreAndAdjacentClear`, `testFirstLightGoalCompletionRestoreReplayAndSurvival`, and `testOpeningCascadeAllowsNativeClearBeforeLastWave` in `FallingSkyInteractionTests`, serial, via XcodeBuildMCP `test_sim`. The initial orientation/menu-only probe passed three and exposed the remaining compact offscreen-action assumption; the final helper correction passes all five in 197.817 seconds.

| Retained Dusk before clear | Fresh cascade after early native clear |
| --- | --- |
| <img src="dev-451219d-wip-38b36fae__dusk-before__iphone-se3__portrait.jpg" width="225" alt="Portrait Moonwake with the score and menu above the visible Dusk and shaded stars"> | <img src="dev-451219d-wip-38b36fae__cascade-clear__iphone-se3__portrait.jpg" width="225" alt="Portrait Moonwake showing three starlight and the surviving stars after an early cascade clear"> |

**Native source `451219d` + test snapshot `38b36fae`, SE3 / iOS 27.0, default text.** These size-reduced JPEG previews preserve the original PNG hashes in the manifest. Both original attachments and the compact paused-actions capture were inspected: the prior black crop is absent, stars/score/menu render, and the scrollable controls are readable. This closes the demonstrated portrait capture failure, not all landscape or device rendering. The normal-motion cascade test clears before its fourth wave with Calm Effects and system Reduce Motion off; stills alone do not establish animation quality. First Light win/restore/replay and menu interruption pass; actual VoiceOver, physical play and full remote CI remain separate acceptance.

## Batch 4: fresh and retained balance contracts

**Verified subset:** the repaired balance case and all six `CriticalMassProductionTests` pass (7/7), then the largest-text settings/restore case passes (1/1), with zero skips. Debug / Xcode 27.1 / iPhone 17e / iOS 27.0; [source hashes, commands' result paths and case durations](balance-readiness.json) distinguish the two test snapshots. Native actions build the test targets. Core: 177 pass; hygiene/diff pass. No app/core/save/resource changes; Release is inapplicable to these test-only changes.

The balance case now explicitly verifies fresh survival has a pace control and no Dusk-frequency control, then exercises the retained `unfed` Dusk fixture in the existing isolated review defaults. It uses current pace labels, preserves an occupied cell and committed board through changes, verifies saved Gentle/Frequent settings after relaunch, resets defaults and verifies Frequent versus None at exact shower counts. Native manual showers finish the sequence because retained skies deliberately have no fresh opening cascade; automatic timing remains covered by the unchanged opening/menu/background cases. A shower committed during Begin/menu admission counts toward that exact total.

The first probe's new zero-before-pause assumption failed after a legitimate Brisk arrival; the corrected test passes in 108.578 seconds. Its explicit 180-second outer allowance contains fresh/retained setup, restore and two replays; individual 5-second waits, assertions and normal motion remain. The native invocation enables the same 90-second default/240-second maximum policy as CI. This is a measured case allowance, not a blanket retry or assertion relaxation.

The broader SE3 probe also exposed two largest-text switch callers using the board helper for lazy menu rows. Those callers now use the existing menu helper; the final native case passes in 40.454 seconds and restores feedback preferences. The balance and largest-text fixes were tested separately; this is not a full-class pass. The earlier broad probe exceeded the MCP transport's 300-second response window, continued in Xcode and was explicitly stopped before its class-wide selection could reach an RC-only VoiceOver method. Its completed failures remain recorded above. The complete local/remote development runs use the planner's existing exclusions and exact-count gates.

## Batch 5: layout-specific controls and retained guide history

The complete local development probe of `6c47961` exposed two further assumptions. `testCompactHUDMenuSuspendsWithoutChangingPauseChoice` expected a running sky's actions to disappear on every phone, although the fixed landing canvas deliberately keeps them outside the guide. It now checks the actual two layout contracts: absent during play in the scrolling guide, or visible and correctly labelled on the fixed canvas. Both branches keep the menu-freeze, automatic resume, explicit pause and hidden legacy-HUD assertions.

The compact reproduction also missed the 1.25-second approaching cue. Its failed element-predicate checks captured accessibility hierarchies, leaving a measured 3.9-second gap between reads. A direct label predicate avoids that diagnostic work during polling; the exact `Shower approaching` assertion and eight-second bound remain unchanged. The initial tall-phone check passed, the initial compact check failed at this cue, and the corrected compact check passed.

`testPausedGuideReportsGrowthDarkOutcomesAndRestore` assumed fresh survival would generate Dusk on shower six. It now retains the fresh-growth assertions and explicitly checks no Dusk arrived, then uses the existing isolated `imminent` retained fixture. A remote Violet clear must preserve Dusk, an adjacent drained Amber clear must remove it with the exact reward, and menu/background/relaunch must preserve the committed result while dropping transient dialogue. Restore keeps the same isolated defaults domain. No fixture, game rule or app source changes.

**Verified subset:** both selected cases pass on iPhone SE (3rd generation) and iPhone 17e / iOS 27.0 / Xcode 27.1, Debug: four executions, zero failures/skips. [Source-bound results](layout-and-guide.json) record the exact test snapshot, native result paths and durations. The original complete probe continues independently to expose other failures; it is not a passing acceptance run. Core inputs are unchanged (177 tests pass); native test actions build the app/test targets. Hygiene/diff checks pass. Inspected tall and compact captures render complete portrait viewports without the earlier black crop; the compact guide is below the visible board and those stills do not prove its text appearance. Full remote development acceptance remains open.

## Batch 6: remove cosmetic simulator setup from the critical path

[Run 39279682027](https://github.com/lbeezr/starfall/actions/runs/39279682027), attempt 1, source `6c47961`, job `118152932449`, passed tooling checks, 177 core tests and both Debug/Release builds. Inventory took 4.630 seconds; boot readiness completed after a long Core Location migration. The subsequent `simctl status_bar override` timed out at 63.698 seconds against its 60-second limit. Cleanup succeeded; installation, captures and native tests were not reached. [Artifact provenance and stage receipts](status-bar-timeout.json) identify iPhone Air / iOS 26.5 / Xcode 26.6. This is a distinct simulator-service stall after successful discovery, not another inventory failure.

Remove the artificial 9:41/full-battery override. Screenshot cosmetics are not an app-readiness contract and should not gate the functional matrix. Captures now retain actual simulator status values. Boot readiness, installation, live-process checks, screenshot creation, complete UI/hosted counts, zero-skip gates and bounded cleanup remain mandatory; no failure is swallowed and no timeout or retry is added. This removes the demonstrated nonessential failure point without claiming other simulator commands cannot stall.

Verification on main `1b9790e` plus this script/docs batch: all ten simulator-lifecycle checks pass, including real descendant cancellation and primary-failure preservation; shell syntax, hygiene and diff checks pass. No app/test source changes. The next full remote run must verify installation through export with this correction.
