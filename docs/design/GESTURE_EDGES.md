# Long flicks keep their intended neighbor

**Status:** Accepted for implementation · **Owner:** current implementer · **Updated:** October 18, 2026

A fast swipe can deliver its first useful sample outside the board. Today that sample cancels before direction is considered, even when the adjacent destination is valid. The next gesture batch should interpret displacement from the touched star first, then validate the adjacent destination.

**Decision:** A finite directional stroke that crosses the existing threshold moves exactly one valid cardinal neighbor, regardless of where its last sample lands. A real outward move at a board edge still cancels. Held drawing still cancels outside the board; taps retain their existing target and drift rules.

**Next action:** reproduce with the production touch adapter, correct the decision boundary, and verify native edge strokes before individual delivery.

## Acceptance before implementation

- Final-only samples beyond all four board edges select the correct adjacent cell from a valid interior source, at compact/large phone and tablet sizes. Off-center contact and diagonal-dominant motion preserve the same direction rule.
- A long stroke never skips cells, becomes drawing or repeats on later samples/release. Actual out-of-board destinations, invalid starts and non-finite samples never commit.
- Held paths that leave the board cancel and cannot fall back to a swap/tap; ordinary short taps and stationary holds retain their current thresholds.
- Real native strokes near the board edge move once; the resulting ordinary tap remains usable. Keep full motion, same-color behavior, rapid-follow-up ownership, background/Settings and Reduce Motion checks.

No Core, geometry, save, score, animation or accessibility-action contract changes. This is a shared recognizer correction. Physical comfort and unusually curved thumb trajectories remain phone acceptance work in the [gesture plan](../GESTURE_QUALITY.md).
