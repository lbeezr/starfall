# Coarse flicks retain their intended direction

**Result:** Partially verified · **Owner:** current implementer · **Date:** October 18, 2026

The shared recognizer now decides the adjacent destination from displacement before testing that destination's bounds. A final sample beyond the board can therefore commit one valid neighboring move. Held drawings, actual outward destinations and non-finite samples still cancel. [Acceptance](../../design/GESTURE_EDGES.md).

**Next action:** publish/deliver this as the third individual gesture batch after the preceding two. Automatic publication review remains blocked despite the user's approval; a destination-specific response is pending.

## Root cause and scope

The production adapter regression failed in all four directions at three board sizes before the correction: it sent a single release sample outside the board, and the recognizer returned cancellation before considering the valid neighbor. The fix changes that common decision boundary, so coalesced motion and final-only release samples share the correction. Direction still follows the dominant axis and commits once; no additional distance, dwell or color arbitration is introduced.

Sibling checks exercise actual outward directions on all four edges, near-edge short taps, held-path exits, invalid numeric coordinates, short/off-center strokes, later samples, stale hold timers and interruption cancellation. Core and coordinate mapping are unchanged. Native UI checks use actual fast strokes ending beyond the playfield; UIKit may provide intermediate samples, so the hosted final-only reproduction is separately necessary.

## Verification

Source: `e46358f` plus [explicit source/test hashes](source-snapshot.json), runtime `dev.5e10acea62`. Xcode 27.1 (`27A9275`), Swift 6.4; Starfall Debug; iPhone 16 Pro Max Simulator / iOS 27.0 (`24A434`), `5107CBBF-108B-4B94-9125-A873F948A38C`. No source/resource membership, save, RNG, rule, rendered geometry or artwork change.

| Check | Result |
| --- | --- |
| Reproduction | New final-only test fails on unchanged pre-fix recognizer; `artifacts/immediate-swipes/edges-reproduction.xcresult` |
| Core | 169 pass; `edges-core.log` |
| Hosted / native | 43 hosted and 12 native UI checks pass, zero failures/skips; `edges-validation.xcresult`, log `test_sim_2026-10-19T00-28-47-464Z_pid62736_6598ac08.log` |
| Debug build | Compiled in the native test run |
| Hygiene | `python3 scripts/ci-hygiene.py`, `git diff --check` pass |
| Physical / actual VoiceOver | Not run; actual VoiceOver remains RC acceptance |

Core uses `CLANG_MODULE_CACHE_PATH=/tmp/starfall-swipe-clang SWIFTPM_MODULECACHE_OVERRIDE=/tmp/starfall-swipe-clang swift test --disable-sandbox`. Native command uses `-sdk iphonesimulator CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES -parallel-testing-enabled NO` and all `TraceInputPolishTests`, `SkyTechniqueStoreTests`, and `SkyTechniqueInteractionTests`. Full/quiet animation, same-color exchanges, held drawing, maximum text, rapid follow-ups, Settings and background are covered by those suites. First Light, restart, full-sky and system Reduce Motion remain source-bound to the immediately preceding [follow-up batch](../follow-up-input-2026-10-18/README.md); this changes only pending-stroke bounds ordering. No artwork/layout change needs a new screenshot.
