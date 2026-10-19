# Swipe to exchange; hold to draw

**Status:** Accepted · **Owner:** current implementer · **Updated:** October 18, 2026

Directional swipes must exchange adjacent stars immediately, before release, in all four directions. Hold a star briefly before drawing a constellation. Neighbor color never decides which gesture is recognized. This replaces the release/dwell swap arbitration described in [touch intent](TOUCH_INTENT.md).

**Decision:** One touch owns one action. A short dominant-axis stroke commits one exchange; a stationary 300 ms hold reserves drawing. Exact same-color stars can exchange identities too; age and growth remain attached to each star. Survival retains falling/settling and manual clearing after an exchange. First Light retains its no-exchange rules.

**Next action:** Observe thumb comfort after canonical delivery; [development verification](../evidence/immediate-swipes-2026-10-18/README.md) records automated/native results and remaining limits.

## Acceptance written before implementation

- Swiping left, right, up or down commits during movement, once per contact, with matching, different-family, Opal and empty neighbors. No release delay, color-based trace fallback, or second swap from continued motion/release.
- Holding within a small stationary tolerance for 300 ms visibly starts drawing. Subsequent movement only traces; release clears the exact valid set, while incomplete paths cancel without tapping or swapping. A quick stationary tap still clears an ordinary group. Any colored star can anchor a held drawing; completeness is checked at release. Holding Opal/Dusk consumes the gesture and explains the colored-start rule without swapping.
- Boundaries reject out-of-board destinations, stale generations and unavailable columns without queuing a move. Settings, background, restart, resize, detachment and multitouch cancel pending holds. Old timers cannot arm a new contact. Already committed swaps are never undone by finger-up/cancellation.
- Core owns orthogonal exchange and normal settlement. Star identity/age, score, RNG, forecasts and existing save formats remain valid. Exercise deterministic replay and archive restore.
- Native and assistive input share all four exchange destinations. Update help and tests; verify actual movement before lift, short/fast gestures, hold drawing, rapid retouch, interruption, outcomes/restart, full motion, Reduce Motion and largest text. Run core/hosted/UI checks and Debug/Release simulator builds.

## Limits

Immediate exchange still needs a small displacement to distinguish it from a tap; animation starts at recognition. A vertical move into unsupported space can fall back under the existing gravity rule. Physical contact-to-display latency and thumb comfort require phone observation. Actual VoiceOver acceptance is deferred to RC. No new save schema, mode switch, automatic clear, progression or separate app is introduced.
