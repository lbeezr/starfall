# Forgiving swaps and constellation drawing

**Status:** Accepted for current-app integration · **Owner:** current implementer · **Updated:** 2026-10-18

Make a directional stroke acquire matching stars without requiring exact center hits, and preserve the selected path through empty space or incidental nonmatching contact. The user reports roughly 30–40% failed swipes; that is an observation, not a measured reproduction rate. This record began with the earlier lab. Main now owns tracing and direct horizontal swaps; apply the remaining changes in those current owners, without reviving the retired exporter.

**Next action:** Verify current-main input/rule changes on simulators, then compare physical feel on phone and iPad.

## Research and decision

[Apple gestures guidance](https://developer.apple.com/design/human-interface-guidelines/gestures) calls for responsive direct manipulation, predictable feedback, learnable custom gestures and alternatives to gestures. [Apple feedback guidance](https://developer.apple.com/design/human-interface-guidelines/feedback) supports nearby, accessible status and an explanation when an action cannot occur. [Parhi, Karlson and Bederson, MobileHCI 2006](https://www.cs.umd.edu/~bederson/images/pubs_pdfs/p203-parhi.pdf) studied one-handed thumb targets and recommended approximately 9–10 mm targets for their tasks. This supports avoiding precision targeting, but does not establish a swipe threshold or modern iPad behavior.

Application to Starfall is a design inference: use the starting star and successive legal neighbors to constrain intent, use a larger elliptical acquisition region scaled to each projected cell, retain progress through incidental misses, and keep existing path/ready feedback. A direction alone must not silently choose an arbitrary chain or clear an unvisited star. Phone thumbs and tablet fingers require separate physical tuning; no published result proves the chosen 0.52-cell acquisition radius is optimal.

## What the broader research changes

| Finding | Implication for games on phones and iPads | Limit |
| --- | --- | --- |
| [Accot and Zhai, CHI 1997](https://chi1997.acm.org/proceedings/paper/ja.html): steering performance depends on permitted path width | Widen the tolerated drawing corridor; do not turn a chain into repeated center-target tasks | Model evidence, not a measured Starfall threshold |
| [Benko, Wilson and Baudisch, CHI 2006](https://www.patrickbaudisch.com/publications/2006-Benko-CHI06-PreciseSelectionTechniquesForMultitouchScreens.pdf): finger size and sensing precision complicate exact selection | Avoid pixel precision; retain visible selection feedback outside the occluded finger | Their precision techniques use two fingers and are not appropriate additions to this small game |
| [Apple touch design tips](https://developer.apple.com/design/tips/): at least 44×44-point controls | Preserve native button semantics/full targets for tap and accessibility alternatives | A minimum button target does not define a trace corridor |
| Thumb target study above | Test one-handed thumb use at board edges separately from tablet index-finger use | Old handheld study; do not equate points with millimeters or extrapolate directly to iPad |

For the current adjacent-cell swap, choose the dominant horizontal axis after a small movement threshold, latch one neighbor, and allow release before the finger reaches that neighbor's center. Distinguish a recognized-but-illegal move from an unrecognized gesture in its feedback. Current Core permits horizontal swaps only; vertical movement retains drawing/scrolling behavior. For constellation drawing, automatically inferring a whole route from one direction would erase player choice; the candidate instead accepts approximate passage through legal neighbors.

Test physical use with the same known five-star route: ten attempts per hand/device/posture at normal speed, then ten fast attempts, recording intended count, selected count, successful release, unwanted additions and visible reset. Include short strokes, curved strokes, reversing direction, edges, rapid retouch, and touch interruptions. These are local observation notes, not analytics. Compare against the preceding main build on the same setup. The player's reported rate remains unmeasured until that comparison.

## Rules and acceptance, written before implementation

- Acquire stars using an ellipse with half-axes 52% of the projected cell width/height; sampled movement remains bounded. Existing shared board projection stays authoritative.
- Empty/nonmatching/non-neighbor samples leave the existing path intact. A new valid neighbor continues it. No nearest-color jumping, automatic path search or score from finger position.
- Consecutive matching stars may be adjacent in any of eight directions, or two cells apart in those directions when the midpoint is empty. One gap per connection; multiple such connections in a path are allowed. Occupied midpoints, two empty cells, knight moves and out-of-board endpoints are rejected by Core.
- Five distinct actual stars remain required for ordinary constellations; the existing four-star square recipe is unchanged. Repeats count once; only selected stars clear. Ordinary taps, dark-star effects, score, RNG/preview and committed-save structure remain unchanged.
- Stale ticket/state/generation and lifecycle invalidation, multitouch, background/settings/restart and leaving the board still cancel. Off-path samples alone must not cancel.
- Run package, focused hosted/native checks and Debug/Release simulator builds on identified current-app source. Check subset selection, one-gap drawing, blocker rejection, wobble recovery, cancellation, rapid input, ordinary taps, restore and largest text. Record actual coverage separately from full-motion, Reduce Motion, VoiceOver and physical-device acceptance.

## Decision point

Keep one normal Starfall target and its existing saves. Compare rejected strokes and unintended additions with the player on phone and iPad; tune or remove the acquisition change if it overselects. Merge only after relevant checks; no extra permanent pilot flag. No visual assets or layout change is proposed here.

## Current-main acceptance before porting

- Preserve existing incidental-miss recovery, Opal family anchoring, recipes, generation/save contracts and interaction ticket ownership. Extend only connection geometry: one empty midpoint per straight link.
- Swap target comes from horizontal displacement (one quarter cell width, clamped to 12–24 points), not finger arrival inside the destination cell. Keep 150 ms dwell as an option; a quick directional release with no selected trace neighbor also commits.
- Latch a chosen neighbor through small drift, including drift across a cell boundary. Returning to the origin or reversing direction, leaving the board, exceeding three quarters of a row vertically or crossing a second neighbor cancels. A selected trace neighbor retains precedence on quick release; deliberate dwell retains the existing swap option.
- Verify short strokes from both cell rims and centers, vertical/diagonal rejection, armed wobble, reversal/overshoot, stale state, one-gap and repeated-gap prefix rules, Opal and blocked midpoints, native normal/fast swaps, selected-only traces, replay and interruptions. Run package, relevant hosted/UI checks and Debug/Release builds on current source.
