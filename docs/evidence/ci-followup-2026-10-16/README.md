# CI follow-up and incremental fixes — 16 October 2026

The renderer restores neutral scale and texture when a valid turn interrupts an invalid-tap nudge. A hosted regression samples the actual intermediate animation, pauses it, and verifies immediate restoration in ordinary and five-kind pilot rendering. Refill completion now retains its already-settled sprites instead of rebuilding the board again; this is an avoided allocation path, not a measured frame-rate improvement.

Settings opens directly in a large native sheet at every text size. Its normal-size test audits that initial presentation without an expansion gesture. The maximum-text audit covers the reading position where the final information paragraph is fully visible. All three audit types remain enabled and every reported issue fails the test. The retired medium-sheet report remains unresolved historical evidence in the preceding swarm evidence folder.

Validation on the combined integration source recorded in `source-and-evidence.json`:

- 37/37 focused native tests: all 35 hosted app tests plus normal and maximum-text Settings flows; zero failures or skips. See `focused-native-summary.json`.
- 27/27 deterministic core tests.
- The subsequent full UI run passed all 10 tests, zero failures/skips, covering rapid input, persistence, background/resume, Calm effects, all five pilot kinds and win/loss/restart. These are 45 distinct native tests across the hosted and full UI runs; the two earlier focused UI tests are repeated coverage, not additional distinct cases.
- The actual CI attachment gate passed with all 30 named captures, including the new `settings-default-initial` contract. See `full-ui-summary.json`, `ui-evidence-status.json` and `ui-attachment-manifest.json`.
- Release simulator build passed, Xcode 27, arm64 iOS 27 simulator.
- Both retained Settings captures were visually inspected. Normal text and controls are clear; at maximum text the footer is fully visible and earlier content scrolls above it.

The screenshots and local results come from a 402×874-point iPhone 17 Pro simulator. These checks do not establish actual VoiceOver speech/focus, physical-device feel, audio/haptics, frame pacing or every scroll position. Earlier full-suite results remain in `../swarm-2026-10-16/`.

The renderer and Settings changes were merged separately through pull requests [#5](https://github.com/lbeezr/starfall/pull/5) and [#7](https://github.com/lbeezr/starfall/pull/7). The resulting production source is `0d4ebe6b49034bb43553691b3a9e9830959f410b`; its source/configuration files match the tested integration checkout. Other chats' local audio work was preserved and excluded from these publications.

The preceding [cloud run 38954256452](https://github.com/lbeezr/starfall/actions/runs/38954256452) passed at source `6c163c58`: 27 core, 34 hosted and 10 UI tests, zero native failures/skips, 30 named XCTest screenshots and two smoke captures. All 32 downloaded PNG hashes matched the artifact manifest. Compact source-bound receipts are retained in `cloud-baseline/`. That run used Xcode 26.3 and an iPhone SE (3rd generation), iOS 26.2 simulator, adding a 375-point phone environment to the earlier local evidence.

The cloud job took 21m23s. Cold setup/smoke occupied the first seven minutes; sequential UI cases took 10m57s, with additional test preparation time. No failed command, timeout or diagnostic stall was found, so no speculative CI repair was made. The raw log and complete artifact remain at `/private/tmp/starfall-ci-38954256452/`; GitHub artifact 12071180641 expires on 17 October 2026.

The [new combined cloud run 38957215784](https://github.com/lbeezr/starfall/actions/runs/38957215784) was in progress when this record was written. Its renderer-only predecessor was superseded by the configured workflow concurrency rule. CI monitoring continues in the coordinator every 15 minutes; the baseline cloud pass does not establish a pass for later source.
