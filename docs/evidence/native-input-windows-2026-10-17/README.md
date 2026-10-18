# Native input-ready intervals across the first storm

**Result: Partially verified — native Store-admission timing measured; an orbit presentation issue remains open.** Owner: current implementer.

Question before implementation: how long does the actual Store admit a clear after real SpriteKit presentation and before the next automatic shower? The offline sensitivity model starts recognition only after settlement; native intervals must be measured separately from human planning or reaction time.

Acceptance: use unchanged production Store, scheduler and scene in a visible native test window, normal motion, no injected presentation duration/clock. Seed 17 current generation is prepared through eight committed showers with bounded ordinary clears, then observed passively through shower fourteen. Record complete source-bound timing events, exact committed-state parity, five closed input windows (showers 9–13), real settlement and both scheduled-deadline/actual-due endpoints. Exclude the initially restored window and the final censored window. Verify a paused clear afterward through the real Store/scene. Use isolated defaults and explicitly detach/cancel on exit. No runtime route, gameplay rule or save change.

Report any interval with no observed ready event as such rather than assuming a positive window. Do not impose a minimum human reaction threshold or change pacing to pass. Skip normal-motion measurement when system Reduce Motion/VoiceOver is active, and report skips honestly. Retain a small JSON summary; no per-frame production IO or analytics. Core, native build, Release membership and hygiene remain separate checks. Human recognition, physical gestures, actual VoiceOver and smoothness remain unmeasured.

## Finding and scope

**The orbit/fast-heavy combination can leave effectively no input-ready interval.** In the prepared natural seed-68 orbit, shower 10 used 1.696–1.701 seconds of presentation against a 1.7-second deadline. The two samples left 0–3.5 milliseconds before the scheduled deadline, and 4.8–5.7 milliseconds before the actual due callback. This is native Store admission, not measured physical tap latency or player reaction time. Treat it as a presentation problem before judging difficulty or enjoyment.

The ordinary seed-17 sample exposes about 0.50–0.52 seconds before the fast-heavy deadline and about 1.50 seconds during breathing. No claimed enjoyment or preference follows from these intervals. Current rules/cadence remain unchanged in this batch.

| Prepared case / shower | Presentation | Ready to scheduled deadline | Ready to actual due |
| --- | ---: | ---: | ---: |
| Seed 17, heavy 10 | 1.184s | 0.516s | 0.522s |
| Seed 17, heavy 11 | 1.194s | 0.506s | 0.507s |
| Seed 17, heavy 12 | 1.193s | 0.507s | 0.515s |
| Seed 17, lighter/breathing 13 | 1.002s | 1.498s | 1.507s |
| Seed 68, orbit + heavy 10 | 1.701s | 0.000s | 0.005s |
| Seed 68, release + heavy 11 | 1.595s | 0.105s | 0.111s |

[Standard summary](standard.json), [orbit summary](orbit.json), [same-source orbit repeat](orbit-repeat.json). Timings are wall-clock native measurements and are not expected to be byte-identical. No minimum reaction threshold was used to make the measurement pass. A ready event after its scheduled deadline may reflect callback dispatch latency; the actual-due interval does not establish a reliably usable opportunity.

## Why the cases were selected

The standard case replays seed 17 through eight ordinary-clear showers, then passively observes six actual automatic showers. Every committed game equals the independently replayed Core result. To extend coverage after seeing the first non-orbit sample, the second test scans seeds 0–79 through shower eight, preferring legal magnetic collisions, and selects the first occupied orbit: seed 68. It then observes four passive showers. This deliberate coverage search is not a natural orbit frequency estimate or an uncoached round. No board, counters, RNG or incoming preview is invented.

The initial restored input interval is excluded. The final committed arrival closes the last measured interval; its own presentation is censored when the test pauses, and excluded. Both cases then commit a paused clear through the real Store and wait for its real SpriteKit completion. This does not exercise a physical finger or SwiftUI hit testing. The observer is the pre-existing Debug timing boundary and records only values; raw events include full committed games and admission flags. A visible SKView hosts the actual scene, not a model presenter, and the default Store clock owns the scheduler. Test defaults are isolated and removed; detachment cancels the clock/actions and restores the previous window.

## Cause and next bounded correction

FallingSkyScene.animateGravity serializes all committed gravity presentation before starting the airborne arrivals, then waits for landing. A 0.5-second rotation plus a five-arrival approach/stagger/landing sequence nearly consumes the 1.7-second cadence. Release/settling plus arrivals is a sibling path and also leaves a short interval. Core commits, versioned cadence and the Store's single-deadline ownership are behaving as specified; the extra presentation serialization owns the demonstrated failure.

Next hypothesis: overlap the airborne approach with the preceding gravity presentation while keeping gravity phase order, full motion durations and first landing strictly after those phases. Scope is scene/motion timing plus focused native/ordering/quiet/interruption checks; no rule, RNG, save or cadence change. Compare this baseline with a bounded candidate. Adopt only if ordering and identity remain correct, clear/quiet outcomes match, repeated native orbit windows materially reopen, and full motion/interruptions are inspected. Otherwise remove the candidate and record the unresolved presentation constraint. Do not derive a new shower schedule from animation callbacks.

## Verification and limits

Source: main f359f94 plus the new AppTests file, its explicit hosted-target membership and documentation. Xcode 27.1 (27A9275), iPhone 17e / iOS 27.0 (24A434), private simulator 536BCC00-751C-47BA-BC2F-C1702941CFC8, Debug arm64 unsigned. Native measurement skipped neither case; system Reduce Motion/VoiceOver were off and scene.reduceMotion was false.

| Check | Result |
| --- | --- |
| Hosted real-renderer measurement | Two passed, zero failures/skips; test_sim_2026-10-18T00-49-57-605Z_pid85535_c0322cd4.xcresult. Exact Core parity for all six/four automatic commits and paused clear. |
| Orbit observation repeat | One passed, zero failures/skips; test_sim_2026-10-18T00-52-15-141Z_pid85535_12b91373.xcresult. Same prepared orbit and near-zero window, without changing source or motion. This repeat measures timing variability, not a retry of a failed test. |
| Initial setup | First build misplaced the test file's group reference under UITests; corrected to AppTests with hosted source membership. The initial standard-only native check passed before the reusable host/orbit extension. Both are superseded by the combined run above. |
| Core | swift test: 109 passed, zero failures; /tmp/starfall-native-window-core.log. No Core changes. |
| Builds | Debug built in the hosted runs. Release simulator build passed without warnings/errors, build_sim_2026-10-18T00-52-30-126Z_pid85535_2f8c87f0.log. New test belongs only to StarfallAppTests; app membership/resources are unchanged. |
| Hygiene | python3 scripts/ci-hygiene.py and git diff --check passed. |
| Separate acceptance | No new scene artwork, frame-by-frame visual review, smoothness/performance profile, actual VoiceOver, physical-device gesture or human preference result. Store admission timing cannot establish those. |

Raw event JSON remains under ignored artifacts/native-input-windows; native bundles/logs are in the XcodeBuildMCP Starfall workspace. [Source and artifact hashes](source.json) identify the tested inputs. The narrow sample establishes a reproducible timing issue, not population-wide difficulty or an acceptable minimum reaction time.
