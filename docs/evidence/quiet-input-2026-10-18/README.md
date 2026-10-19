# Quiet play accepts the next move immediately

**Result:** Partially verified · **Owner:** current implementer · **Date:** October 18, 2026

Quiet rendering previously showed the final board while retaining input ownership for another 150 ms. Ordinary column presentation and phased gravity presentation now complete immediately after their final render. The production recognizer commits a second quiet swap without buffering; full motion retains its animation and bounded follow-up. [Acceptance](../../design/QUIET_INPUT_RESPONSE.md).

**Next action:** publish and deliver this fifth independent batch, then observe physical thumb play. Publication remains blocked by automatic review pending destination-specific authorization despite the user's approval; the canonical updater reports it is waiting for the configured iPhone.

## Root cause and scope

The scene added a 150 ms wait in both quiet branches after rendering committed state. This kept the store's presentation ticket alive even though nothing remained to animate. The new native regression fails before the correction: completion is still zero and a scene completion action remains. The correction removes the delay at the shared presenter boundary. Existing synchronous completion for a scene without a view establishes the same supported callback contract; Core commits and saves still precede presentation.

Checks cover quiet clear, swap, shower and historical phased gravity, exact visible identities, no delayed completion action, immediate production-surface retouch, full-motion buffering, independent columns, interruption cancellation, clock/save ownership and terminal states. The phased-gravity path remains historical compatibility. No normal animation timing, Core, save schema, RNG, rendered geometry, artwork or target membership changes.

## Verification

Source: `e350aba` plus [source/test hashes](source-snapshot.json), runtime `dev.8a753c144b`. Xcode 27.1 (`27A9275`), Swift 6.4; Starfall Debug; iPhone 16 Pro Max Simulator / iOS 27.0 (`24A434`), `5107CBBF-108B-4B94-9125-A873F948A38C`.

| Check | Result |
| --- | --- |
| Reproduction | `quiet-reproduced.xcresult` fails at the premature visible-ready boundary. An earlier command used a nonexistent test target and was corrected without changing tests. |
| Core | 169 pass, zero failures; `artifacts/immediate-swipes/quiet-core.log` |
| All hosted | 286 pass, zero failures/skips; `quiet-hosted.xcresult`, log `test_sim_2026-10-19T00-41-44-361Z_pid62736_731a81ed.log` |
| Native gestures / system Reduce Motion | 13 pass, zero failures/skips; `quiet-native.xcresult`, log `test_sim_2026-10-19T00-44-04-791Z_pid62736_d5d7cee5.log`. Includes rapid follow-ups, held drawing, four directions, coarse flicks, largest text, Settings and background. |
| Debug build | Compiled in hosted/native runs |
| Release | Build succeeds; log `build_sim_2026-10-19T00-47-37-416Z_pid62736_4d707c43.log` |
| Hygiene | `python3 scripts/ci-hygiene.py`, `git diff --check` pass |
| Physical / actual VoiceOver | Not run; actual VoiceOver remains RC acceptance |

Core command uses `CLANG_MODULE_CACHE_PATH=/tmp/starfall-swipe-clang SWIFTPM_MODULECACHE_OVERRIDE=/tmp/starfall-swipe-clang swift test --disable-sandbox`. Xcode checks use `-sdk iphonesimulator CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES`; tests add `-parallel-testing-enabled NO`. Hosted selection is all `StarfallAppTests`; native selection is `SkyTechniqueInteractionTests` plus `FallingSkyInteractionTests/testSystemReduceMotionKeepsManualPlayWorking`.

## Timing limits

The native production-surface/store/scene sequence observed a full-motion node displacement at **18.1 ms**, with two moves finishing in **506.6 ms** including animation. Quiet mode executed both moves synchronously during input delivery, with final node verification at **27.3 ms** total; it did not queue. Raw timing attachments remain under `artifacts/immediate-swipes/quiet-timing-export`. The quiet attachment's displacement field is sampled after both input calls and must not be read as the first frame's latency.

These are single simulator samples, using direct production-surface input and five-millisecond node polling for full motion, not hardware touch-to-photon percentiles. They do not establish physical comfort. Native full-motion tests verify actual motion; this change adds no visual state requiring a replacement screenshot. The [hold-feedback capture](../hold-feedback-2026-10-18/README.md#inspected-native-presentation) remains the selected armed-state reference. Normal First Light/replay/full-sky/restore flow retains the separately recorded [preceding acceptance](../follow-up-input-2026-10-18/README.md); this batch's hosted suite covers committed terminal/save behavior.
