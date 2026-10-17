# Opal and storms: main-based development acceptance

**Verified within the scope below.** Product source is `5b326dccd52d828f8573fd5ac943f024243e9a23`, based on main `b3bde49`. [Source hashes](source.json) match a clean Git export byte-for-byte, including app, Core, tests, assets, project and changed tooling. Documentation was finalized afterward. The earlier branch at `1a3ddc5` was preserved; unpublished rankings work was excluded.

This adopts the user-approved round, soft Opal connector and nine-lighter/three-heavy shower cycle in regular new survival skies. Historical saves/replays and First Light retain their generation. Main's adopted timing remains independent; “Lighter showers” does not promise slower arrivals. User approval establishes implementation direction, not observed enjoyment.

## Checks and source limits

All native runs use the private iPhone 17e simulator `536BCC00-751C-47BA-BC2F-C1702941CFC8`, iOS 27.0 build 24A434, Debug arm64 unsigned, scheme Starfall, DerivedData `/tmp/starfall-trace-integration-build`, unless stated otherwise. Result filenames below live under `~/Library/Developer/XcodeBuildMCP/workspaces/Starfall-27844ad883f3/result-bundles/`.

| Check | Result and scope |
| --- | --- |
| Core | `swift test`: **89 passed**, zero failures. Repeated from the clean export of `5b326dc`; `/tmp/starfall-opal-clean-core.log`. Covers connector allocation/trace legality, generation/replay/save invariants and realized follow-up reward. |
| Full hosted app suite | **115 passed**, zero failures/skips. `test_sim` with `-only-testing:StarfallAppTests`; `test_sim_2026-10-17T23-17-14-992Z_pid85535_4230fe89.xcresult`. Includes retained Debug material/puzzle paths, clock/cancellation, v3/v4 migration and malformed downgrade rejection, geometry, bounded caches, real SpriteKit motion, and equivalent quiet outcomes. |
| Opal/storm native interactions | Four passed, zero skips: white-first free/colored clear spends shared Orbs and restores; selective trace; warning/count/recovery with menu/background; largest-text density reflow. `test_sim_2026-10-17T22-56-05-145Z_pid85535_e37d8862.xcresult`. |
| Layout regressions | Three passed, zero skips: normal long guide below all seven front-row targets, selective trace, and largest-text native clear after scrolling from controls. `test_sim_2026-10-17T23-07-02-727Z_pid85535_e8035798.xcresult`. |
| Final lifecycle/read-through | Four passed, zero skips: introduction scrolls to its end with pinned reachable actions; automatic showers, double-tap clear, settings/Calm/replay; First Light overflow; First Light win/restore/replay/new survival sky. `test_sim_2026-10-17T23-13-43-432Z_pid85535_d98d6402.xcresult`. |
| Normal motion and actual VoiceOver after guide correction | Both passed, alongside 58 focused hosted checks, zero failures/skips: `test_sim_2026-10-17T23-09-19-474Z_pid85535_b1447f15.xcresult`. Normal pacing preserves native cell frames while cues change. Actual VoiceOver reads Opal identity/value, activates the chosen colored match, handles menu dismissal, and reads warning/storm cues. [Speech sample](voiceover-speech.txt). This is targeted acceptance, not a full physical-device round. |
| Other timing cases | Forecast/cadence separation, largest-text sticky cue, system Reduce Motion labels passed in the earlier combined run. That run ended five passed/one failed; the failed clear-navigation case was corrected and rerun above. Source predates only the guide footprint correction, later formatting, and test additions. `test_sim_2026-10-17T22-58-06-477Z_pid85535_b3b751a8.xcresult`. |
| Debug build | `build_sim` passed, no warnings/errors; `build_sim_2026-10-17T23-19-30-667Z_pid85535_8b074a62.log` in the workspace logs directory. |
| Release build | `build_sim` passed, no warnings/errors (`build_sim_2026-10-17T23-13-13-370Z_pid85535_4186f68c.log`). Also passed from the clean committed export; [exact commands/results](clean-export.json), `/tmp/starfall-opal-clean-release.log`, DerivedData `/tmp/starfall-opal-clean-release-build`. |
| Packaging and hygiene | All seven body PNGs and both receipts reproduce byte-for-byte in a temporary directory with bundled Python/Pillow. No checkout assets changed. `python3 scripts/ci-hygiene.py`, `git diff --check` and three native-plan tests passed. The new actual VoiceOver session belongs to RC in routine CI, preserving the accepted development/RC policy; it was explicitly run for this work. |

## Visual and animation inspection

Durable screenshot PNGs are scaled proportionally to 390 pixels wide (the motion strip to 1000) using CoreGraphics high-quality downsampling. Full-resolution originals remain in the listed xcresults and ignored temporary captures. No content, geometry or game artwork was edited in these QA derivatives.

Inspected native [Opal before trace](opal-before-trace.png), [selected trace result](opal-selected-trace.png), [storm/timing labels](storm-three-showers.png), [largest-text density reflow](largest-text-reflow.png), and [largest-text native clear](largest-native-clear.png). The round pearly silhouette is distinct from Dusk and the faceted cast; only the selected Orb is consumed by the trace. Normal density copy sits above the terrace, separate from the reserved timing strip. Largest text reflows below the canvas and requires scrolling.

An initial after-trace screenshot exposed long normal corrective copy covering the front row. The final guide fits its introduction or scrolls it within a footer budget derived from the shared projection; actions remain outside that scroll region. Inspected [Opal message read to end](guide-opal-read-to-end.png) and [ordinary message read to end](guide-ordinary-read-to-end.png): complete text is reachable and the scrollbar is visible after the reading gesture, with front stars clear and actions pinned. The older after-trace image is retained as the source-bound reproduction; it is superseded for guide layout.

The hosted native motion checks run real SpriteKit playback: Opal in flight, soft landing, no simultaneous flight/landed body, face changes preserving deformation, reset/restore round, and quiet-motion equivalence. A still screenshot alone does not establish those behaviors. The [pose strip](motion-poses.png) is historical native capture at `1a3ddc5`, not a frame-by-frame animation atlas. The scene, motion and StarCast source files match the committed implementation byte-for-byte; the current hosted tests independently exercise their playback.

## Failures resolved and remaining questions

The largest-text test originally searched for a visible match while scrolled down to the guide controls. Core probing confirmed legal front-row groups still existed. It now scrolls back to native stars while preserving every sticky-cue, visible-target, and successful-clear assertion. No blanket retry, assertion reduction or forced reduced motion was introduced.

The 22:58 MCP observation call expired after 300 seconds. Its original `xcodebuild` PID 24563 was confirmed live and monitored through the original log until terminal; no duplicate run was started. An earlier invocation with the wrong target name ran no tests; successful invocations use `StarfallAppTests`.

The [simulated review and deterministic follow-up](simulated-review.md) distinguish mechanical opportunity from enjoyment. In a real seeded fixture, equal five-light first clears leave a four-versus-three follow-up ordinary match, with or without the committed shower. Human recognition, the frequency of useful holding choices, combined-cue comprehension and replay preference remain unmeasured. The next bounded human comparison is recorded there.

Physical device, smaller-phone/resized-window coverage and full release-candidate VoiceOver round are **not verified by this record**. [Engineering follow-up](../../ENGINEERING.md#paused-guide-footprint--opalstorm-integration-october-17) names layout triggers. No campaign, progression, backend, ads, IAP or new SDK was added. Remote publication/CI status is recorded separately when available.
