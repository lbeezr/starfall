# Luminous cast revision — October 17, 2026

Acceptance target: simpler readable eyes at preview/board size; stars read as light through bright centers, pale edges and bounded halos; retain distinct silhouettes, Dusk contrast, stable expression sizing and bounded resources. Final visual approval remains with the user.

Candidate: clean export of main `d9a33d0f19d1220dbbe97958dd96f2420a7d69f0`, replacing only `App/StarCast.swift`. SHA-256: `fe0ca009c9634f44de728902e90b65a0295ceb347e5cc11d506d7770a7eab873`. Export path: `/var/folders/fs/9shw9bf142jg3280dc9n3hhc0000gn/T/starfall-luminous-7a4zcqr8`. Unrelated local Xcode project/workspace edits were excluded.

- `swift test --scratch-path /tmp/starfall-default-core`: 60 passed, zero failures.
- XcodeBuildMCP `test_sim`, Debug, Starfall, arm64, iPhone 17e / iOS 27, only StarCastTests: six passed, zero failures/skips. Includes full-animation geometry samples, stable alpha/padding, material reuse and repeated scene rendering.
- Release simulator build on the same clean candidate: passed. An initial tool invocation duplicated the configuration option and was rejected before compilation; setting the Release session configuration and rebuilding succeeded.
- [Material sheet](material-review.png) exported from the native XCTest attachment and inspected at hero and 24/36/44-point canvas sizes. No generated concept art substituted for runtime output.

Core rules, save data, gestures, clocks and layout are unchanged. Actual spoken VoiceOver and physical-device appearance/performance are unverified for this revision.

## Gameplay checks and limits

All ten `StarfallExperimentInteractionTests` passed, zero failures/skips, on the same clean Debug candidate and simulator. Coverage includes normal-motion rain/rapid input, growth/clearing, pause, settings dismissal, restart/replay, background/relaunch, overflow, challenge win/loss, dark-star restoration/clear, balance persistence, compact layout, largest text and actual system Reduce Motion. The MCP call timed out at 300 seconds; the underlying owned Xcode process continued and completed successfully at 432 seconds. Finalized xcresult summary is retained in `ui-summary.json`; no tests were weakened or retried.

Inspected [crowded board](crowded-board.png) and [largest text](largest-text.png) captures. Bright edges and separate silhouettes remain readable on the dense board; Dusk and growth-block shading remain distinct. The largest-text capture shows very large controls/instructions consuming the viewport, with the header outside the visible area. Existing layout assertions passing do not establish visual layout acceptance; this unchanged layout needs separate review. No actual spoken VoiceOver session or physical-device check was performed. No new full-play recording was made; animated sprite sizing was sampled in the hosted check, and the normal-animation native gameplay flow passed.
