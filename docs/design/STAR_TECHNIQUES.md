# Arrange stars and build deliberate relays

**Status:** Accepted; gesture-only development checks recorded, full-sky check unresolved · **Owner:** current implementer · **Updated:** October 18, 2026

Give single-cell stars a controllable setup move and exact recipes while preserving falling stars. In survival, swipe horizontally toward a neighbor, then lift to exchange the stars. A brief hold also shows a preview. Empty destinations are allowed: unsupported stars fall after the slide. A matching four-star square or five-star cross can be cleared without spending surrounding stars. The next clear remains a player decision.

**Decision:** Keep these as ordinary board actions, with no charge, bonus multiplier, progression or automatic cascade. First Light retains its existing rules. [Original integration evidence](../evidence/technique-current-main-2026-10-18/README.md) retains its source; [gesture-only correction](../evidence/dialogue-only-hud-2026-10-18/README.md) tracks removal of Arrange.

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

The [touch-intent contract](TOUCH_INTENT.md) infers one neighbor from a short horizontal stroke; quick release can commit without reaching its cell. A 150 ms dwell still arms a preview. Armed drift may cross a cell border; returning toward the source, substantial vertical departure, a second neighbor or leaving the board cancels. Quick swipes that selected a trace neighbor retain tracing precedence. Multi-touch, changed input generation, settings, backgrounding and scene replacement cancel pending input. The recognizer delivers contact immediately, before scroll views can defer UIView touches; one contact owns the held shower deadline through release/cancel/reset. Unavailable incidental samples preserve a trace; stale snapshots still cancel.

Board actions are direct gestures. Swipe sideways for an exchange; tap ordinary matches or trace exact squares/crosses. There is no Arrange mode, menu entry, toggle, neighbor-tap exchange or recipe picker. A completed/cancelled gesture returns directly to ordinary input. Native constellation accessibility actions retain exact trace selection without a mode. At accessibility text sizes character chat scrolls below the canvas. Opal can join a colored family; all-Opal recipes and Dusk ingredients are invalid.


## State and presentation

Core validates actual star IDs and current board state. The store rejects stale snapshots/generations and reserves only affected columns, including Dusk reward changes. It commits and saves before presentation. Scene animation first slides exchanged identities horizontally, then falls to the committed resting cells. Quiet motion preserves the outcome.

Exchanges spend no starlight and do not advance showers, RNG or forecast. Shared clear rules retain growth, Opal and current Dusk feeding/collapse rewards. These actions introduce no save fields; the current v7 archive versions the separate five-feed Dusk rule. Selection and relay feedback are transient. A relay label increments only if a clear spends a recipe newly created by the preceding clear, comparing actual ingredient identities; it awards no extra points.

## Acceptance and remaining questions

Verify exact ingredients, Opal/Dusk interactions, deterministic continuation, stale callbacks, independent columns, interruption, native direct gestures, full/quiet motion, largest text, normal flow/outcomes and Debug/Release target membership. Record each evidence level separately in the linked report. Actual VoiceOver acceptance belongs to the release candidate cadence. Human comprehension, timing comfort, free-exchange balance and enjoyment require observed play after delivery; seeded examples cannot establish them.
