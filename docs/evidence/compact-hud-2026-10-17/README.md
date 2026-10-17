# Compact HUD candidate — October 17, 2026

## Intended behavior and comparison

User-authorized trial: compact score/goal and menu header; replace exact incoming-star strip and numeric countdown with a subtle top-edge arrival cue; move active-play pause into the menu. Remove permanent title, shower count, matching-group count and repeated status sentence during play. Keep start/resume and manual advance when paused, results/restart at round end, teaching/settings in the menu, matching-group rotor and accessible cell information.

The cue brightens for the last 1.25 seconds before an automatic shower and during arrival. Calm effects, VoiceOver and Reduce Motion use state changes without the glow transition. The cue has native state labels, no continuously announced numerical countdown, and does not reveal contents/columns. This is a comparison candidate, not proof that removing the forecast improves decisions or enjoyment. After user play, adopt the compact layout or revise/remove the cue based on comprehension, perceived fairness and board readability; no permanent pilot route is added.

Menu opening remains temporary suspension. Done/dismissal restores the existing player pause choice. Pause/Resume selected in the menu changes that choice and returns to the board. Clock event ownership, rules, core forecast/save data and renderer geometry are unchanged. The menu operation releases suspension and toggles pause synchronously on the main actor before dismissal, so no rain callback interleaves those operations.

## Source isolation

Clean export of `b9eea1a` plus only the three files hashed in source.json. All other exported tracked files were verified against that base. Unrelated current Xcode/project, star-motion/artwork, branding and mechanics work was excluded. Later documentation-only commits in the shared checkout do not affect this candidate.

Acceptance requires a dominant board, real native clears after layout resize, quiet active HUD, accessible menu/pause/manual play, menu dismissal preserving the pause choice, challenge completion/overflow/restart, interruptions, largest text and Reduce Motion. Actual VoiceOver speech/focus and physical-device acceptance remain separate and unverified.

## Checks

- `swift test --scratch-path /tmp/starfall-default-core`: 60 core tests passed.
- Debug simulator build and native launch succeeded. Shared scheme Starfall, arm64, iPhone 17e, iOS 27.0; ARCHS=arm64, ONLY_ACTIVE_ARCH=YES, CODE_SIGNING_ALLOWED=NO.
- First shared-simulator run: compact/menu and board/tap checks passed; largest-text test was killed at launch while another independently owned Xcode run used that simulator. This failed batch is not claimed green. Validation moved to task-owned simulator `6E9BC34B-C5C6-48ED-9593-D16AC994BCC8` (Starfall Compact HUD QA), isolating subsequent runs.

No claim of human preference, actual VoiceOver speech/focus, physical-device performance or App Store readiness.

## Isolated layout/accessibility batch

Six native UI tests passed, zero failures/skips: compact active/menu behavior, compact board/clear, First Light completion/restore/replay/survival, first-shower manual play, largest-text settings/feedback/dismissal, and actual system Reduce Motion. See ui-layout-summary.json. Screenshots [opening](opening.png), [paused board](paused.png) and [largest text](largest-text.png) were retained; the largest-text game/menu images were inspected. Unlike the prior luminous-cast viewport, the header and paused actions now fit with the board. This does not establish actual VoiceOver speech/focus or every device/OS layout.

Release simulator build passed on the same clean candidate. Those results describe the initial source in initial-source.json; the foreground-readiness correction below is recorded separately.

## Gameplay/menu batch

Three additional native UI flows passed, zero failures/skips: automatic rain/pause/growth/rapid clear/replay/settings dismissal, balance persistence/pace/frequency, and dark-star restore/adjacent clear. See ui-gameplay-summary.json. These flows now reach Pause through the menu while the sky is running; they continue to reach Start/Resume and Next shower directly while paused. Renderer and native cells use the same actual board frame after each resize; the tests activated actual board buttons and verified score/outcomes. This is not a complete top/edge-cell geometry matrix.

## Foreground menu readiness correction

The first interruption/overflow batch passed First Light overflow but failed the background/resume flow: immediately after foreground activation, a menu tap did not produce a sheet. Its hierarchy remained on the running board. The active HUD previously always exposed an enabled menu button through scene suspension/activation. Final source disables the menu during suspension/inactive phases and makes the paused Start/Resume control reflect suspension too. The test helper waits for an enabled, hittable menu before tapping; it does not retry taps or weaken the subsequent sheet/pause assertions.

This examines the shared readiness boundary for the header menu and paused action, alongside existing clock suspension and menu dismissal behavior. It does not claim every OS presentation race is eliminated. The failed batch is retained in ui-overflow-before-readiness-summary.json. Final hashes are in source.json; the six layout and three gameplay passes above precede these two small UI readiness guards and the helper wait.

Final readiness verification: background/resume/save/relaunch/automatic overflow/restart and menu suspension/dismissal/player-pause checks both passed, zero failures/skips. See ui-readiness-summary.json. Final Release simulator rebuild passed after the readiness guards. The final menu test additionally checks the cue reaches its native “Shower approaching” state and retains an active-HUD capture; it adds no runtime changes.

The final menu/cue test passed (zero failures/skips), including a condition-based wait for the native arrival cue's “Shower approaching” label. See ui-final-cue-summary.json and the inspected [active HUD](active.png) capture. It confirms the board is dominant while active and contains no pause/manual-advance/status/forecast rows. No ad-hoc tool tap was counted as gameplay acceptance; native XCTest controls produced these captures.
