# Simulated phase HUD comparison and wording follow-up — 2026-10-17

The same agent followed up on the user's requested simulated playtest. Compact Surge Lab HUD first, original Surge Lab second, each launched with --starfalls-reset --shower-phase-fixture: seed five, eight showers, score 19. Both remained paused and stopped at thirteen showers without loss. This is a prepared-state HUD comparison, not a fresh opening or a new independent participant.

Parent checks matched both installed executable and Debug-dylib hashes to verified build products; all core files match, and stores match after save-suite normalization. Exact sources in observed-builds.json: frozen core/renderer 30af812, compact view/theme be4d869. The compact build also has the newer announcement-selection policy, which this session did not assess audibly. Parent performed only read-only build inspection during the agent's exclusive simulator session.

| Settled shower | Decision stated before acting, in both HUDs | Reported result |
| --- | --- | --- |
| 8 | Surge approaching; no legal group, wait. | Shower 9 made rose clearable; score 19. |
| 9 | Three heavy showers ahead; clear rose to open left-side space. | +4, score 23. |
| 10 | Two remain; aqua high in the centre is worth only 2. Low mint would not lower that centre, so wait. | Shower 11 produced amber/rose opportunities. |
| 11 | One remains; clear amber beside the upper dark star, joining aqua. Clear the joined aqua to lower the centre and remove the second blocker. | Two clears, +3 then +3; score 29, both dark stars gone. |
| 12 | Recovery means calmer arrivals; retain low groups for growth. | Shower 13, score 29. |
| 13 | Another calmer preparation interval; would keep waiting. | Stopped. |

Original visible ready counts at these initial states: 0, 1, 1, 3, 3, 3. Compact hid those counts. The agent used accessibility cell labels/values for exact connected values and blocked-growth relationships, and screenshots for height, layout, rings and visible phase text. It did not use the original forecast strip to derive hidden arrivals. Parent inspected the matched shower-eleven captures: [compact](compact-shower-11.jpg), [original](original-shower-11.jpg), both score 23 before the two-clear sequence.

The agent found phase intensity legible in both and reported a useful shift from waiting to removing blockers, then waiting for growth during recovery. It preferred the **original HUD, moderately**, for its rule reminder, ready count and growth/dark-star outcome confirmations. Compact remained visually quieter and preserved phase comprehension once the rules were known, but offered less explanation of why a change happened. This distinguishes a phase cue from teaching the best clear; it does not prove an exclusive resource tradeoff, since paused play permits multiple clears.

Two wording observations prompted bounded edits in the existing isolated labs: “Five-star surge follows” did not specify when; recovery switched to “Prepare · 8 calmer showers” immediately after its first step ([observed capture](compact-old-recovery.jpg)). The warning now says “Five-star surge after this shower.” Recovery retains its name for the remaining calmer interval until the next warning, while the opening still says Prepare. Shared phase/forecast ownership, cadence, rules, save schema and announcement-selection policy are unchanged. Both HUD regression scenarios now advance through shower thirteen and check eight-shower recovery after settings, background and relaunch. [Corrected recovery](corrected-recovery.jpg) and [largest-text warning](corrected-warning-largest.jpg) are separate parent native checks after the edit; their canonical test trajectory reaches score 33, not the agent's 29.

## Verification of the wording edits

Exact sources in wording-builds.json. Xcode 27.1 (27A9275), iPhone 17e / iOS 27.0 (24A434), simulator A84C81F5-AE41-496A-97AE-E17C63E18D29. XcodeBuildMCP test_sim, Debug, CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES, parallel-testing-enabled NO:

- Compact: 23 passed, zero failures/skips (19 store, 2 policy, 2 native UI). Result test_sim_2026-10-17T16-02-56-306Z_pid40582_2d013349.xcresult. Export .../starfall-native-showers-bekvpmz_, derived data /tmp/starfall-phase-wording.
- Original: 5 passed, zero failures/skips (3 native UI, 2 policy). Result test_sim_2026-10-17T16-04-13-209Z_pid40582_9000dbf6.xcresult. Export .../starfall-native-showers-9eijdxkr, derived data /tmp/starfall-original-wording.
- Compact Release simulator build passed: build_sim_2026-10-17T16-04-06-196Z_pid40582_d5f776bb.log.
- Current core swift test: 61 passed, /tmp/starfall-phase-wording-core.log. Hygiene/diff checks passed. Candidate core hash unchanged. Raw Apple artifacts: ~/Library/Developer/XcodeBuildMCP/workspaces/Starfall-27844ad883f3/.

Largest-text initial warning wraps into three readable lines; controls require scrolling, and native tests verify that the sticky cue remains visible while advancing. Parent inspected the corrected normal recovery and largest-text warning screenshots. No system preferences were changed. No new full-motion, actual VoiceOver speech or physical-device acceptance is claimed; earlier motion evidence retains its own source. Native tests establish layout/input/persistence, not improved human comprehension of the new wording.

## Decision and main reconciliation

Retain the two wording corrections as isolated-lab refinements. Do not select a production HUD or restore the forecast strip from this one simulated comparison. Prior familiarity, fixed compact-first order, accessibility metadata and paused tool deliberation limit the inference. Identical actions/scores do not establish equal enjoyment or automatic-play difficulty, and the revised copy has not had an uncoached participant test.

The user's main review interrupted further legacy-HUD work. At review, committed main was 9bb008d; the working tree also contained a newer Observatory projection, HUD/menu family, comet trail and Sunny guide. None of those later working-tree interface changes was in these labs. Core findings survive; these HUD observations do not accept the current Observatory. Next mechanics work should use an exact source-bound Observatory snapshot and its existing components. The bounded remaining feedback question is whether that interface provides enough confirmation for growth and dark-star clears, with quiet active play and hidden forecasts. Preserve this report as historical evidence rather than adding another old-HUD variant. Rules versus HUD comparisons are now distinguished in PLAYTEST-FALLING-SKY.md. Production phase adoption, actual VoiceOver and human/device acceptance remain open.
