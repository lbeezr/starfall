# Reliable drawing, layout and development delivery

**Status:** Development implementation verified · **Owner:** current implementer · **Updated:** October 17, 2026

Implement the review findings directly in regular Starfall, in independently verified PRs. Preserve rules, cadence versions, saved rounds and full animations. No additional app, backend, mechanic or package dependency.

**Decision:** Every touch terminates through one explicit state machine, with the store granting a generation-safe hold ticket. Build identity covers runtime/build inputs and excludes documentation. Camera placement uses explicit validated geometry profiles with a complete header fallback. Broader native checks protect the actual integration boundaries rather than adding device guesses.

**Next action:** Integrate the final canvas/native batch; retain the physical and RC checks below for the next appropriate session. Touch ownership is merged in PR #46; build identity/delivery is merged in PR #48.

| Batch | Acceptance |
| --- | --- |
| Touch ownership | Eligible edge touch moving 7.9 points outside the board always cancels; final movement is classified even without a move callback. Tap, trace, cancel, duplicate terminal events, multitouch admission, size/generation/enable changes and detach all release their session. An old hold ticket cannot release a newer hold. No queued showers; committed outcomes/save/RNG unchanged. |
| Build identity | Package manifest/resolution, runtime Swift/resources/config/project changes alter identity; READMEs/docs/tests/user workspace state do not. Missing optional resolution is deterministic. Failed local validation or installation never advances the installed receipt. Existing development CI policy remains explicit. |
| Layout and native boundaries | Checked portrait profiles require full expected geometry; unknown, resized, rotated and accessible layouts use the same complete header forecast. Native edge release, normal drawing/tap, menu/background, largest text and representative resized iPad checks preserve usable controls and committed state. |

The touch surface owns physical input classification; the view owns transient selected cells; the store owns hold tickets/deadlines; Core owns legal selected sets. Every terminal path relinquishes ownership. Timing and storm density stay separate committed values. Existing luminous thread/sparks and non-color character shapes remain the interaction cues; no speculative hints or new decorative effects are introduced.

Use focused hosted regression tests plus native normal-motion drawing, relevant interruption/layout checks, `swift test`, Debug/Release simulator builds, hygiene and explicit target membership. Source-bound reports record results and failures. Pure geometry/hosted events are not physical gesture acceptance. Full actual VoiceOver remains an RC gate; physical expanded-Island activities, curved/multitouch feel, haptics, match discovery and enjoyment require the next observed phone session. Performance work starts only if measurement exposes a problem on the bounded 7×7 board.
