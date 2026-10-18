# Arrange stars and build deliberate relays

**Status:** Accepted; development checks verified · **Owner:** current implementer · **Updated:** October 18, 2026

Give single-cell stars a controllable setup move and exact recipes while preserving falling stars. In survival, swipe one horizontal cell, hold briefly, then lift to exchange the stars. Empty destinations are allowed: unsupported stars fall after the slide. A matching four-star square or five-star cross can be cleared without spending surrounding stars. The next clear remains a player decision.

**Decision:** Keep these as ordinary board actions, with no charge, bonus multiplier, progression or automatic cascade. First Light retains its existing rules. [Integration evidence](../evidence/technique-current-main-2026-10-18/README.md) owns verification and delivery status.

## What the player can learn

| Technique | Deliberate action and consequence |
| --- | --- |
| Trim | Spend an exact square or cross, preserving matching stars around it. |
| Drop-in | Remove a support so survivors fall into a useful arrangement. |
| Bank | Keep a ready group while spending another selection. |
| Fork | Choose between overlapping recipes with different survivors. |
| Relay | Clear, inspect the new recipe created by falling survivors, then clear it. |
| Double setup | Choose a clear that makes more than one useful follow-up. |
| Rescue | Open headroom or clear beside Dusk before the next shower. |
| Nudge | Exchange horizontal neighbors, including an empty space, to construct a match. |
| Trace | Select five or more actual neighboring stars, including diagonals, rather than the whole component. |

These are player strategies, not separate saved abilities. Debug reset-only examples exercise the decisions without saving or running automatic showers; normal play has no example selector.

## Touch and accessibility

A 150 ms dwell in the neighboring cell arms an exchange and displays its two-star preview. Lift on that same cell to commit. Returning to the source cancels the armed move; leaving the original row or crossing two columns disqualifies that contact. Quick swipes retain selected tracing behavior. Multi-touch, changed input generation, settings, backgrounding and scene replacement cancel pending input. The recognizer delivers contact immediately, before scroll views can defer UIView touches; one contact owns the held shower deadline through release/cancel/reset. Unavailable incidental samples preserve a trace; stale snapshots still cancel.

Arrange offers tap controls for selecting a star, moving left/right, choosing an overlapping recipe, clearing it, or cancelling. Native accessibility actions open the same selection. At accessibility text sizes these controls reflow below the canvas and scroll. Ordinary taps still clear normal connected groups; the selected recipe spends only its exact ingredients. Opal can join a colored family; all-Opal recipes and Dusk ingredients are invalid.

Arrange is unavailable while the sky is empty. If a committed clear removes the final stars, the intent exits Arrange and restores the ordinary paused-play controls, retaining relay feedback. A populated sky keeps the mode while discarding its stale selection. [Native correction and timing follow-up](../evidence/calibration-timing-and-arrange-2026-10-18/README.md).

## State and presentation

Core validates actual star IDs and current board state. The store rejects stale snapshots/generations and reserves only affected columns, including Dusk reward changes. It commits and saves before presentation. Scene animation first slides exchanged identities horizontally, then falls to the committed resting cells. Quiet motion preserves the outcome.

Exchanges spend no starlight and do not advance showers, RNG or forecast. Shared clear rules retain growth, Opal and current Dusk feeding/collapse rewards. These actions introduce no save fields; the current v7 archive versions the separate five-feed Dusk rule. Selection and relay feedback are transient. A relay label increments only if a clear spends a recipe newly created by the preceding clear, comparing actual ingredient identities; it awards no extra points.

## Acceptance and remaining questions

Verify exact ingredients, Opal/Dusk interactions, deterministic continuation, stale callbacks, independent columns, interruption, native gestures and tap equivalents, full/quiet motion, largest text, normal flow/outcomes and Debug/Release target membership. Record each evidence level separately in the linked report. Actual VoiceOver acceptance belongs to the release candidate cadence. Human comprehension, timing comfort, free-exchange balance and enjoyment require observed play after delivery; seeded examples cannot establish them.
