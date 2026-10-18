# Directional swaps and empty-gap constellations on current main

**Result:** Partially verified · **Owner:** current implementer · **Date:** 2026-10-18

The regular app now derives horizontal swaps from a short directional stroke rather than exact destination-cell entry and release. Existing dwell previews remain available; small armed wobble is tolerated. Tracing uses projected elliptical acquisition and allows one empty midpoint between successive selected stars. [Research and acceptance](../../design/TOUCH_INTENT.md) define the rules and physical-comparison limits.

**Next action:** Merge the verified development change, then compare physical phone/iPad touch and haptics. The reported 30–40% failure rate remains unmeasured.

## What changed and why

Current main already preserved trace progress through incidental misses. The stale checkout's lab exporter is retired and was not restored. Investigation on main found swaps tied to exact cell entry, a 150 ms dwell, strict same-row residence and exact-cell release. One directional target owner now serves preview and quick release; armed target departure tolerates small drift while reversal, substantial vertical departure, another neighbor, leaving the board and lifecycle invalidation still cancel. Quick release does not override a selected trace neighbor. Vertical swaps remain unsupported by Core; vertical motion still draws/scrolls.

The existing analytic segment/circle hit test now works in normalized ellipse coordinates (52% of each projected cell dimension). Core shares one adjacent/one-empty-midpoint predicate between eligibility and selected-prefix validation; first-colored-star family anchoring, Opal, recipes, ordinary taps, Dusk, generator, preview/RNG and save schema are retained. Gaps may repeat in a walk but occupied midpoints, two-cell gaps and knight moves are rejected. New reset-only Debug fixtures are in the existing package/app; no alternate bundle, new route, dependency or asset is introduced.

## Verification

Base: `dcd89dd18ccdfd17bffa36c14d41817d7aa733b0`. Initial implementation `5c8d67778f6f668cf9a77bd3f47464db0ab1f820` matches local `4b858fe` exactly (tree `c7e36b60`). Final release-only movement classification was tested at local `c4510b7`; final runtime/test hashes in the record below identify the published PR bytes. Only documentation/capture evidence changes after that final tested source. [Source hashes](verification.json) bind the checks to those files. These results concern the current-app port, not the earlier `dev.61131c9e11` lab.

| Check | Result / limit |
| --- | --- |
| `swift test` | 152 pass, including old-save/replay and three new gap checks |
| Debug simulator | 77 hosted + seven iPhone native checks pass: quick/held swaps, empty destination settling, gap/independent off-center drawing, selected subset/restore, largest text/menu dismissal and multitouch/background/rotation recovery |
| iPad native | Three checks pass before the final platform-independent release-sample ordering correction, on task-owned iPad Air 11-inch (M3), iOS 27.0, `66475E68-E548-43B0-A265-C492ADF6234C`: one-gap, independent off-center drawing and short directional swap; `/tmp/starfall-pr-input-ipad-final.log` |
| Final release-sample correction | 25 affected hosted + three iPhone UI checks pass again; final Release rebuild passes. Final-only movement is classified before quick-swap admission to preserve selected-trace precedence. Raw `/tmp/starfall-pr-input-release-sample.log`, `/tmp/starfall-pr-input-release-sample.xcresult`, `/tmp/starfall-pr-input-release-sample-build.log` |
| Release simulator | `xcodebuild build -configuration Release`: pass |
| Hygiene/diff | `python3 scripts/ci-hygiene.py`, `git diff --check`: pass |
| Physical motion/haptics, human error rate | Not run; phone/iPad comparison is the next decision |
| Actual VoiceOver | Deferred to RC; not run on this development build |

Raw task output is local `/tmp/starfall-pr-core-r2.log`, `/tmp/starfall-pr-input-final.log`, `/tmp/starfall-pr-input-final.xcresult` and `/tmp/starfall-pr-input-release-final.log`. Native commands use Xcode 27.1 (27A9275), scheme Starfall, iOS 27.0 Simulator, `CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES ARCHS=arm64` and task-specific DerivedData. Native source/build/interaction and visual/physical acceptance are distinct claims. Source fixtures remain Debug-only; Release compilation verifies that boundary.

<img src="one-gap-clear.jpg" width="240" alt="Current iPhone simulator showing five starlight and an empty board after connecting five stars across one empty space">

**Native settled-result capture:** published implementation tree above, iPhone 16 Pro Max / iOS 27.0 Simulator (`5107CBBF-108B-4B94-9125-A873F948A38C`), `testNativeGapSwipeAndRepeatedAttempt`. Original and reduced JPEG were inspected: five stars clear, score reads five and bottom dialogue fits. This still does not prove motion or physical haptic feel. Original PNG remains in the local xcresult; this copy is resized for documentation.

## Coverage and limits

All eight gap directions, reverse links, repeated gaps, same/other/dark/Opal blockers, first-family anchoring, long/knight/out-of-board rejection and valid-save replay are covered. Hosted checks retain stale-generation, target reversal, overshoot, hold ownership, restart, motion, settings and cancellation assertions. New directional and off-center probes cover compact/large phones and tablet geometry. Ordinary tap groups and generation relief remain orthogonal; no generator/RNG/archive fields changed.

The first port build caught an accidental Debug-fixture switch insertion; it was removed before successful checks. An initial hosted run reported eight assertions in two old circle-based probes: the old radius-derived start points fell outside the intended native cells after enlargement. Probes now use the actual native cell rim and normalized ellipse grazing boundary, retaining their equality, hit and cancellation assertions; the final run passes all 77 hosted checks. An initial tablet launch stalled because its shared simulator was shut down externally; it was stopped and replaced with a task-owned iPad simulator. These earlier attempts are not counted as passing acceptance.

Normal effects remain enabled in native gesture runs. Full-motion visual review and physical touch/haptic comfort are not established. Actual VoiceOver remains deferred to RC. The [engineering follow-up](../../ENGINEERING.md#forgiving-touch-follow-up--october-18-2026) names the physical comparison and threshold-tuning trigger.

**Final focused rerun:** quick short swap, existing held swap/empty-destination settling and fast selected-five trace/restore pass on the final release-sample source. The broader 77 hosted/seven UI and tablet results above retain their preceding source; only terminal event order changed afterward. The source-bound still above comes from that preceding runtime and is used for settled appearance only. Current full end-of-round native and system Reduce Motion playthroughs were not rerun in this PR; package/hosted rules, quiet-mode and interruption coverage pass, and no outcome-screen code changed.
