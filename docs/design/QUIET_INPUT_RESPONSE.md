# Release input when quiet presentation is complete

**Status:** Accepted · **Owner:** current implementer · **Updated:** October 18, 2026

Quiet modes render the committed board immediately but currently delay completion by 150 ms. Remove that artificial delay from both ordinary column presentation and phased gravity presentation. Keep all normal animation timings and Core/save behavior unchanged.

**Next action:** [the reproduced failure and development checks pass](../evidence/quiet-input-2026-10-18/README.md); publish this fifth batch independently, then assess physical play.

## Acceptance before implementation

- A quiet clear, shower, swap or phased gravity turn completes exactly once in the presentation call, with final nodes already in place and no delayed completion action.
- The normal production recognizer can commit two quiet swaps in succession without queueing. Full motion still buffers the second until its owning presentation finishes.
- Settings/background/restart cancel normal in-flight work; no quiet callback survives to overwrite a later state. Existing committed save and clock ownership remain unchanged.
- Core, hosted/native and system Reduce Motion checks pass. Record native sampled callback-to-node timings separately from unknown physical touch-to-photon latency. Actual VoiceOver and physical comfort remain RC/phone acceptance.
