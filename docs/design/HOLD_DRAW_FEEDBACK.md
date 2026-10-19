# A visible transition into drawing

**Status:** Accepted · **Owner:** current implementer · **Updated:** October 18, 2026

The existing contact corners and first traced star look too similar. A ready colored star should show a short, bounded hold-progress cue, then an eight-ray sparkle and distinct haptic when the unchanged 300 ms hold selects drawing. This is the fourth independent [gesture batch](../GESTURE_QUALITY.md).

**Decision:** Use twelve small segments progressing along four open cardinal rays during normal motion. Drawing replaces those marks with four bright cardinal rays around its first star, joining the existing four diagonal rays. Keep the star's face clear, the existing path/selection count, and the stronger valid-five cue. Quiet modes use the existing static contact corners followed by the static armed sparkle; outcomes and hold duration stay identical.

**Next action:** [development checks pass](../evidence/hold-feedback-2026-10-18/README.md); publish separately after the preceding batches. Phone comfort remains open.

## Acceptance before implementation

- Only a ready, eligible colored star shows hold progress. Empty, unavailable and non-drawing stars do not promise a drawing state.
- A quick swipe never waits for the cue. Canceling, swapping, resizing, backgrounding and replacing contact remove all progress nodes/actions; old timers cannot show an armed sparkle or generate feedback.
- A successful hold shows the eight-ray sparkle at the same logical transition that starts drawing, with one preference-aware arming haptic. Cue appearance does not choose a rule outcome. Traced groups, backtracking and exact selected sets remain unchanged.
- Progress is at most twelve fixed segments plus existing contact corners; no frame-time path generation, assets, timers or cache. The physical recognizer remains the sole arming timer owner.
- Native captures distinguish contact from armed drawing, including quiet and maximum-text play. Existing full-motion, quick same-color swipe, hold/draw and interruption checks pass. Actual haptic comfort and VoiceOver remain phone/RC acceptance.

Existing reference: [inspected first-star contact](../evidence/immediate-swipes-2026-10-18/README.md#inspected-native-presentation). Its subtle corners remain the contact state; the new eight-ray sparkle is the proposed distinction, not shown by that historical capture. No Core, save, geometry, timing or gameplay-rule change.

<img src="../evidence/hold-feedback-2026-10-18/dev-8d29bc1-wip-0f08b779a9__drawing-armed__iphone-16-pro-max__full.jpg" width="220" alt="Held Aqua star has eight open sparkle rays and a one-of-five drawing count below the board">

**Native implementation capture:** runtime `dev.0f08b779a9`, iPhone 16 Pro Max / iOS 27.0 Simulator, full motion. The sparkle leaves the face clear; the existing fingertip dot remains at its center. The [evidence record](../evidence/hold-feedback-2026-10-18/README.md) separates this appearance sample from timing and physical haptic acceptance.
