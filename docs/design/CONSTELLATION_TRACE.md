# Draw the stars you choose to spend

**Status:** Adopted first pass into regular Starfall · **Owner:** current implementer · **Updated:** 2026-10-17

The user accepts constellation matching as a mechanic direction, but wants its satisfaction and strategy to come from drawing the shape. This supersedes whole-component clearing in the earlier tap-only trial: release clears **only the traced stars**. Omitted stars remain, even in the same connected family. The user now requests one phone app and repeatable updates from main; integrate into the existing Starfall identity and retain its chosen round.

**Decision:** five distinct same-family stars minimum; diagonal/orthogonal neighboring steps; retracing permits branching without counting a star twice. Ordinary three-light orthogonal matches retain tap input. Glow hints at eligible groups without drawing their solution. The visible trail follows the player's walk, then pulses and bursts on successful release. Haptics rise with distinct stars; there is no idle vibration.

**User review, 2026-10-17:** The installed first pass (`dev.fecfaa150d`) is approved after iPhone play. Keep the mechanic in Starfall Lab for further polish; this approval does not adopt it into the regular game. Control has been retired.

**Next action:** continue polish in regular Starfall with the [main updater](../DEVELOPMENT_BUILDS.md#one-starfall-app-and-automatic-device-updates). The separate phone lab is removed; full actual VoiceOver acceptance remains an RC gate.

## Acceptance before implementation

- Core validates the ordered walk against committed cells, collects at least five distinct stars, scores growth normally, removes only orthogonally neighboring darkness, settles once, and preserves untraced IDs, preview and RNG. Four grown stars, mixed families, out-of-bounds and disconnected jumps fail without mutation. Walks/repeats are bounded.
- Touch recognition must cancel ordinary button activation once a drag is recognized. Partial release, leaving the board, touch cancellation/multitouch, pause/settings/background, shower, restart, motion change and geometry replacement never commit a stale trace. Commit only once on release; no animation callback owns a rule decision.
- Candidate saves keep only committed core state in its existing isolated bundle/suite. Updating the lab must not reset either its save or production Starfall. No new production route, schema or generator rule.
- Resting eligibility has a subtle glow, no solution lines. Trace visuals/particles are bounded and use the same projection as native cells. Quiet modes use static cues and equivalent outcomes. Normal play retains full effects.
- Native regression: exact five-star path, chosen five from a larger component, insufficient trace, ordinary taps, repeated/rapid input, settings/restart/background interruption, normal/reduced motion and actual VoiceOver. Accessible actions must allow selecting a particular walk and releasing/canceling it without requiring a timed swipe.
- Simulator/device installation, actual touch evidence, visuals/motion, actual VoiceOver speech/activation and subjective haptic feel are separate claims. Do not infer preference from automated checks. Record failures and remaining gates.

## Input and feedback ownership

Core validates and commits the selected set. A small main-actor trace intent owns the transient ordered walk, source snapshot and cancellation ticket. Native gesture recognition samples the finger in the shared cell projection; effects present the trace and committed clear only. Lifecycle changes invalidate the intent. Neither the path nor particles are saved. A finite pulse/burst accompanies the existing clear presentation; removing a trace or replacing a scene cancels its effects.

VoiceOver retains native star buttons and ordinary tap semantics, with explicit add/release/cancel actions for a selected constellation. Spoken progress includes distinct star count and collected value. Instructional help may explain the threshold, but active play never draws the solution for the player.

## GitHub main reconciliation — 2026-10-17

User-approved first pass remains isolated. Integration source `64c90e124642237db61816be2ad742cc791db5dc` starts from GitHub main `cbce35c74c7b46625118eced3eeb07a9a197bb15`, selecting only constellation commits and the VoiceOver cadence. No production App/Core/Config/project bytes differ from that base; Game Center and unrelated local work are excluded. This record is the only subsequent documentation change.

The export captured clean `b8410cca827e072adecf162a6788abf138aebc80` before the approval/documentation commits, with identical runtime/tooling bytes; its build ID is `dev.6502ed7875`. Clean integration checks: repository hygiene and diff checks pass; production and freshly exported candidate each pass 61 core tests. Candidate Debug native tests pass 24 hosted store tests and three constellation gesture UI tests on iPhone 17e / iOS 27.0 Simulator (`A84C81F5-AE41-496A-97AE-E17C63E18D29`), with Xcode 27.1 (27A9275). Candidate Release simulator build passes. Raw output is local `/tmp/starfall-approved-{core,lab-core,native,release}.log`; exports are `/tmp/starfall-approved-integration-labs`. These checks validate reconciliation, not a new physical-device feel or visual review. The previously installed `dev.fecfaa150d` remains the user-approved iPhone build. Actual VoiceOver is deferred to RC under the accepted cadence.
