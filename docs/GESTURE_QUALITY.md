# Ship gestures that keep pace with play

**Status:** Accepted · **Owner:** current implementer · **Updated:** October 18, 2026

The user wants S-tier response, consistency, forgiveness, secondary actions and fast follow-ups, delivered incrementally. Ship each coherent, verified improvement through current main and the canonical phone updater. Simulator correctness and installation receipts are evidence of implementation and delivery; physical comfort still requires observation.

**Next action:** integrate the already verified immediate-swipe foundation, preserving current main's feedback ownership fix and save contract; then ship follow-up admission separately.

## Scope and acceptance

- Response: a directional stroke commits before release, animation begins promptly, and completed motion does not leave an avoidable input lock. Measure native frames and rapid retouch; do not infer latency from a passing test.
- Consistency: one touch owns one action in all four directions, independent of neighboring family, age or growth. A held drawing cannot become a swap or tap.
- Forgiveness: small off-center, curved and final-sample strokes select the intended cardinal neighbor without requiring exact destination contact; genuine taps, edges and diagonal ties remain predictable.
- Secondary actions: a stationary hold clearly announces when drawing is ready through a visible cue and supported haptics; drawing preserves exact traced sets, backtracking and interruption cancellation.
- Fast follow-ups: admit the next intended move while its star is finishing presentation, acknowledge it immediately and execute at most once when available. Bind intent to stable identity and current adjacency; never apply a stale coordinate to a replacement star. Bound capacity/lifetime and cancel on incompatible state/lifecycle changes.

## Incremental deliveries

| Batch | Deliverable | Done when |
| --- | --- | --- |
| 1 | Immediate four-direction swipes and hold-to-draw foundation | Current-main Core/hosted/native/Debug/Release checks pass; merged runtime installed through updater with receipt. These coupled changes resolve gesture arbitration together. |
| 2 | One bounded follow-up intent | Busy-star retouch registers, fires exactly once when safe, expires/cancels safely; native rapid sequence and save/lifecycle checks pass; separate merge and receipt. |
| 3 | Forgiving direction and boundary handling | Original and representative edge/off-center/coarse-sample native checks pass; preserved tap/draw contracts; separate merge and receipt. |
| 4 | Clear secondary-action feedback | Native held-state captures distinguish pending/armed drawing, normal/quiet outcomes match, largest text remains usable; separate merge and receipt. |
| 5 | Response and complete-quality acceptance | Measure remaining avoidable admission/animation delay, ship any supported correction separately; compare real-phone repeated strokes, holds and follow-ups. Record device observations and residual gaps. |

Reuse existing gesture, contact, presenter and feedback owners. No backend, telemetry service, dependencies, separate app, progression or save-schema changes. Each batch gets focused regression checks and a compact source-bound report. Preserve existing normal-motion/Reduce Motion, Settings, background, restart, win/loss and accessibility contracts. Actual VoiceOver stays an RC gate per the development cadence.

## Evidence and limits

The [foundation report](evidence/immediate-swipes-2026-10-18/README.md) records the existing native/test evidence. The [visual reference](design/VISUAL_REFERENCE.md) owns selected captures. Stable identity, immediate acknowledgment and cancellation are required before buffering can ship; a blind queue is not an acceptable intermediate version. Phone availability may defer delivery, but must not delay independent implementation and review.
