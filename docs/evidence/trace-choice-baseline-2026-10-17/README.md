# Existing tracing creates occasional choices; holding is not yet compelling

**Result:** Partially verified · **Owner:** current implementer · **Date:** 2026-10-17

Keep selected tracing as the baseline. No new star or pressure rule adopted. Smaller selections sometimes preserve a stronger follow-up, but most sampled actions remained ordinary taps. A familiar simulated tester chose the full six-star chain in the native safety example and predicted its seven-light gain correctly. This supports understandable immediate clearing, not a rewarding reason to hold or human replayability.

**Next action:** Compare a visible smaller-first follow-up with its larger-clear alternative, then revisit storm timing against the same tracing rules. Add a white-star experiment only if it supplies a missing, understandable tradeoff. [Acceptance and bounds](../../design/TRACE_CHOICE_BASELINE.md).

## Outcomes against acceptance

| Criterion | Result | Evidence / limitation |
| --- | --- | --- |
| Deterministic natural states and exact existing Core | Pass | Committed source 9ec96f8; canonical transformations; Core hash matches native dev.fecfaa150d. Full provenance and three replay fixtures in results.json. |
| Distinct choices and bounded enumeration | Pass | Five helper checks; no capped states. Exactly-five sets, whole components and ordinary taps; intermediate subsets excluded. |
| Same-value safety/follow-up differences | Observed | Largest policy: 13 states with same-value alternatives, six follow-up differences and one safety difference among 226 decision states. Five-at-a-time: 13, seven, zero among 224. |
| Partial clear beats whole on two-clear diagnostic | Observed, uncommon | Two states in each policy. Hidden-next lookahead is diagnostic, not knowledge supplied to a player. |
| Native prediction and committed outcome | Pass within scope | Tester chose six aqua, predicted 65→72; hosted real-store commit and native saved restore each passed one test. No actual swipe executed. |
| Holding is understandable/rewarding | Not established | Tester saw no concrete benefit to spending fewer or waiting. Full six also frees the tall column; the five-versus-five safety fixture alone overstates that decision. |

## Verification context

**Source:** Clean archived 9ec96f8650224cfab79944391075b18dc61a3dc6 plus canonical selected-trace transformation. Analysis and test overlays were uncommitted tools at execution; hashes recorded. Native export runtime unchanged, older presentation than current main and excludes rankings. Test overlays append only existing test-target files. No production save/rule/runtime change or phone install.

**Environment:** Debug, arm64, iPhone 17e / iOS 27.0 private Simulator 536BCC00-751C-47BA-BC2F-C1702941CFC8. Shared scheme Starfall; code signing disabled.

| Check | Procedure | Result |
| --- | --- | --- |
| Core | `python3 tools/mechanics/compare-trace-choices.py --ref 9ec96f8` | 61 package tests; helper checks and fixture save/replays passed. |
| Reproducibility | Rerun emitted executable | Exact policies, rounds and fixtures equal. |
| Native initial stage/capture | Hosted TraceChoiceStoreBridge and UI TraceChoiceCaptureTests | One pass each; initial score65. |
| Native selected action/capture | Same tests with STARFALL_CHOICE_WALK=0:1,0:2,1:3,2:4,1:5,2:6 then STARFALL_CHOICE_SCORE=72 | One pass each; final guarded overlay, saved score72. |
| Visual | Inspected before and after native screenshots | Selected aqua gone; right column reduced. Still captures only. |
| Gesture, motion, interruption, actual VoiceOver, device | Not exercised by this observation | No runtime changes; do not inherit acceptance from a store test. Simulator-only bridges skip physical devices. |

Raw results: XcodeBuildMCP Starfall-27844ad883f3 result bundles at 20-20-31, 20-21-00, 20-25-14 and 20-25-34 UTC on 2026-10-17. Captures under /tmp/starfall-trace-choice-observation and /tmp/starfall-trace-choice-outcome. Source manifests retained beside this report; raw media/logs remain temporary.

## Findings and limits

Across 16 rounds per policy through shower24, largest-whole-or-tap scored911 total versus880 for five-at-a-time; each overflowed in five rounds. Approximately91% of actions were ordinary taps. These are future-blind immediate-clearing policies with different visited states, not an optimal-play or enjoyment comparison. No policy tests deliberate waiting. The safety fixture at shower24 probes already committed shower25, beyond the policy round cap.

The partial-versus-whole fixture gives seven light now plus six on the best post-shower follow-up, versus ten now and no follow-up. That is a candidate for the next comprehension comparison, not proof that a person could foresee the hidden arrival or prefer the smaller trace. There are three retained categories but only two underlying source states.

The before-input prediction is preserved in prediction.md; its outcome assessment is appended separately. This is one familiar agent on one paused board. Storm urgency, cold human learning, repeated-round preference and replayability remain open. Retain these offline tools and fixtures for the next bounded baseline comparison; no additional runtime pilot flag or phone variant was introduced.

Main advanced to 9c20c7e during this comparison, adding an opening cascade and three-second default showers. This evidence remains pinned to the earlier round/cadence. Rebase the next timed comparison on that opening/cadence before making a pressure recommendation; do not treat this immediate-clear sample as current-main timing acceptance.

Integration: clean merge ba8a4a7 includes main 9c20c7e. `swift test`, hygiene and diff checks passed; Debug arm64 Simulator build passed (XcodeBuildMCP log build_sim_2026-10-17T20-27-18-800Z_pid85535_1cc3701f.log). No app/runtime differences versus that main; this batch adds only offline analysis, simulator-only test overlays and documentation. Original experiment results remain pinned, not rerun under the new cadence.
