# Character motion candidate — October 17, 2026

Acceptance: distinct grown/clearing expressions; front and shallow left/right views for every character; flight turn, landing squash/rock and clearing swish; sparse ambient motion; no changes to committed rules/saves/input geometry; normal animations and reduced-motion alternatives work.

## Sheets

Each PNG is transparent 768×1024 with fixed 256×256 cells. Columns: front, left, right. Rows: idle, landing, grown, clearing. The source factory is authoritative; these native XCTest exports are review artifacts, not a separately loaded runtime atlas.

- [Spark](Spark.png)
- [Sunny](Sunny.png)
- [Pip](Pip.png)
- [Twinkle](Twinkle.png)
- [Nova](Nova.png)
- [Dusk](Dusk.png)
- [Whole-cast review](material-review.png)

## Source and checks

Clean export of `c565358`, replacing App/StarCast.swift, App/StarfallExperimentScene.swift and AppTests/StarCastTests.swift only. Unrelated local Xcode edits are excluded. Debug Starfall, arm64, iPhone 17e / iOS 27, XcodeBuildMCP.

- 60 core tests passed.
- Seven hosted cast tests passed with zero failures/skips under normal motion, including every character's twelve unique frames, geometry preservation and animated flight/landing samples. The initial run had six passes and one explicit full-animation skip because the simulator's system Reduce Motion was on; a separate normal-motion run exercised that test successfully.
- New material bound: 72 image/texture pairs; base RGBA8 source pixels total 18,874,368 bytes. Actual GPU/process memory and physical-device performance remain unmeasured.

No actual spoken VoiceOver or physical-device validation. These are authored shallow 2D turns, not evidence of 3D volume or a rigged model. Native sheet inspected for all families; final motion/visual acceptance remains open.

## Native interaction and recording

Five selected UI flows passed, zero failures/skips: automatic rain/rapid input/growth/clear/replay/settings, background/relaunch/overflow, dark-star influence/restore/adjacent clear, First Light completion/replay/survival, and actual system Reduce Motion/manual play. Final xcresult summaries are retained here. Largest-text and compact-layout tests were not rerun in this motion-only revision; their prior luminous-candidate results remain separate. Actual spoken VoiceOver remains unverified.

Release simulator build passed on the same source. Native clean-candidate run was recorded to ignored `artifacts/star-cast-motion.mp4`: seed 5, five showers, paused idle turns and two legal clears. Normal-motion recording explicitly disabled system Reduce Motion and Calm effects; the original system Reduce Motion value of 1 was restored afterward. Inspected sampled frames of [flight/landing](flight-and-landing.png), [paused board](paused-turns.png), and the authored turn sheet. Sampling frames does not constitute a frame-by-frame video quality review; final motion feel needs user/device review.
