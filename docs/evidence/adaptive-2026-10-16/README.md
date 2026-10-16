# Adaptive gameplay evidence — 2026-10-16

Production base b600375; adaptive implementation 0e14d35, integrated checkpoint b3e1ea3. Exact final source hashes are in source-sha256.json. Xcode 27.0, iOS 27.0 (24A434), arm64 simulators.

- Deterministic core: 27 tests passed, zero failures; /tmp/starfall-adaptive-core.log.
- iPad mini (A17 Pro): four UI cases passed, zero failures/skips. Adaptive rotation/input/navigation/restart, accessible board controls, largest-text audits, and all three terminal outcomes. Native result: /tmp/starfall-adaptive-ipad-acceptance.xcresult; summary copied here. The old stacked layout at 8f821d0 failed the intended sidebar geometry assertion in /tmp/starfall-adaptive-baseline-corrected.xcresult.
- iPhone SE (3rd generation), 375-point width: four UI cases passed, zero failures/skips. Adaptive portrait/input/navigation/restart, rapid/invalid/cancelled input, normal navigation including Settings swipe dismissal, saved-game relaunch and settled background/Calm Effects resume. Native result: /tmp/starfall-adaptive-phone-acceptance.xcresult; summary copied here.
- Release arm64 simulator build succeeded; /tmp/starfall-adaptive-release-build.log. This was a simulator build, not signed physical-device distribution.
- CI shell syntax and ten literal Python heredoc bodies parsed successfully. The existing required captures gain three adaptive names (33 total); native method-count and zero-failure/skip gates remain unchanged.

The final iPad test uses XCUIScreen.main full-screen capture. Initial and post-rotation/post-play captures show the complete 592-point board beside the HUD/status/New game column. Score/moves remain 3/17 across rotation; a real post-reflow tap reaches 7/16; restart returns 0/18. The compact phone's full 335-point board retains the stacked HUD. captures.json records the visually inspected original images and hashes; large original rasters remain alongside the local result bundles rather than being duplicated in Git.

Evidence limits: several older app.screenshot() attachments from landscape large-text and terminal tests have malformed cropped/oriented framing. They are excluded from full-layout visual acceptance; their passing native assertions/audits remain separately reported. No actual human VoiceOver speech/rotor/focus, system Reduce Motion operation, physical-device performance or frame pacing is claimed.

The temporary phone-test shell wrapper was edited while its native process ran. Its trailing shell handling returned 1 and truncated the plain text log. The completed XCTest bundle is authoritative: all four cases passed, zero failures/skips, and attachments exported successfully. No test was rerun or suppressed to conceal that wrapper issue.

Before publication, preceding cloud run 38960840647 passed at audio head 94eb306a: 27 core, 45 hosted and 11 UI tests. New adaptive source requires its own subsequent CI run.
