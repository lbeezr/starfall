# Directional swaps and empty-gap constellations on current main

**Result:** Partially verified · **Owner:** current implementer · **Date:** 2026-10-18

The regular app now derives horizontal swaps from a short directional stroke rather than exact destination-cell entry and release. Existing dwell previews remain available; small armed wobble is tolerated. Tracing uses projected elliptical acquisition and allows one empty midpoint between successive selected stars. [Research and acceptance](../../design/TOUCH_INTENT.md) define the rules and physical-comparison limits.

**Next action:** Finish current-source checks before merging; compare physical phone/iPad touch and haptics afterward. The reported 30–40% failure rate remains unmeasured.

## What changed and why

Current main already preserved trace progress through incidental misses. The stale checkout's lab exporter is retired and was not restored. Investigation on main found swaps tied to exact cell entry, a 150 ms dwell, strict same-row residence and exact-cell release. One directional target owner now serves preview and quick release; armed target departure tolerates small drift while reversal, substantial vertical departure, another neighbor, leaving the board and lifecycle invalidation still cancel. Quick release does not override a selected trace neighbor. Vertical swaps remain unsupported by Core; vertical motion still draws/scrolls.

The existing analytic segment/circle hit test now works in normalized ellipse coordinates (52% of each projected cell dimension). Core shares one adjacent/one-empty-midpoint predicate between eligibility and selected-prefix validation; first-colored-star family anchoring, Opal, recipes, ordinary taps, Dusk, generator, preview/RNG and save schema are retained. Gaps may repeat in a walk but occupied midpoints, two-cell gaps and knight moves are rejected. New reset-only Debug fixtures are in the existing package/app; no alternate bundle, new route, dependency or asset is introduced.

## Verification

Base: `33ae6fb` (origin/main at branch creation), plus this PR's explicit App, Core, hosted/UI test and documentation paths. Runtime checks below concern this port, not the earlier `dev.61131c9e11` lab. Source hashes and final results will be recorded before merge.

| Check | Result / limit |
| --- | --- |
| `swift test` | 152 pass, including old-save/replay and three new gap checks |
| Debug simulator | In progress: relevant hosted and native checks |
| Release simulator | `xcodebuild build -configuration Release`: pass |
| Hygiene/diff | `python3 scripts/ci-hygiene.py`, `git diff --check`: pass |
| Physical motion/haptics, human error rate | Not run; phone/iPad comparison is the next decision |
| Actual VoiceOver | Deferred to RC; not run on this development build |

Raw task output is local `/tmp/starfall-pr-core-r2.log`, `/tmp/starfall-pr-input-xcode.log`, `/tmp/starfall-pr-input-tests.xcresult` and `/tmp/starfall-pr-input-release.log`. Native commands use Xcode 27.1 (27A9275), scheme Starfall, iOS 27.0 Simulator, `CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES ARCHS=arm64` and task-specific DerivedData. Native source/build/interaction and visual/physical acceptance are distinct claims. Source fixtures remain Debug-only; Release compilation verifies that boundary.
