# Give implosions room for the next decision

**Result:** Model corrected; a native timing problem and bounded candidate identified · **Owner:** current implementer · **Date:** October 18, 2026

Use the existing longer announced cycle as the next candidate for fresh critical-mass skies. Current heavy implosions can consume essentially the entire faster interval: the real renderer showed no ready window after shower 10 and almost none after shower 11. On the same seeded history, the existing `announcedCycleV1` gave 0.768 and 0.653 seconds before the scheduled deadlines, while preserving full motion. No runtime default changes in this batch.

The corrected model compiles production warning/timeline code, includes the swallow lead, asserts critical-mass version 1, and adds a zero-action idle policy. Active play survives and scores better than waiting in these samples. Do not add hazards to punish idling on this evidence.

**Adoption update:** [Fresh-survival integration](ADOPTION.md) records the factory, saved-cadence/replay checks and acceptance results.

**Next action at this measurement source:** Adopt the existing longer cycle for fresh survival only; the latest-artwork native recheck confirms the sampled decision windows. Preserve saved rounds' cadence and verify replay/First Light before shipping. Human feel and the pending player pressure preference remain separate.

## Current-rule balance

Each eight-seed cohort runs five policies × two timing lookups × full/quiet models: 160 runs. Below uses the current `announcedCycleV2` and normal-motion model. Most active runs are censored at their horizon. All five cohorts total 800 model runs and 138,009 replay-checked commits; [summary.json](summary.json) retains commands, distributions, hashes and native records.

| Cohort / horizon | Largest-clear ended / 8; median score | Setup-first ended / 8; median score | Idle ended / 8; median score |
| --- | --- | --- | --- |
| Seeds 0–7 / 180 s | 0; 247.5 | 0; 234.5 | 2; 0 |
| Seeds 64–71 / 180 s | 0; 256 | 0; 242.5 | 3; 0 |
| Seeds 0–7 / 180 s, reaction 1.0 s | 0; 230.5 | 0; 210.5 | 2; 0 |
| Seeds 0–7 / 600 s | 0; 853.5 | 0; 789 | 5; 0 |

Default assumptions are 0.45 s reaction, 0.12 s per visited/retraced cell and 0.5 s exchange contact. Idle never touches, traces, swaps or holds rain. Its surviving rounds are not proof of indefinite survival; it scores zero and loses substantial starlight to collapses. Active policies reduce overflow in these samples and retain value. Setup first minimizes some swallowed value but holds the clock and delivers fewer showers. These are canonical full-component policies, not optimal selection or measured player speed.

A same-seed 180 s timing comparison uses existing `announcedCycleV1` (3.0 / 2.5 / 3.5 s, opening unchanged). Largest clear has no overflows, median score 201 and 59 showers, versus 247.5 and 81 under V2. Idle still ends in 2/8. Lower score per wall-clock horizon accompanies fewer arrivals; it does not establish worse play or isolate human benefit. The comparison changes only the injected timing lookup, not production rules, saved state, or app routing.

## Native decision windows

The integrated-artwork SpriteKit/Store comparison uses ordinary critical-mass seed 0 advanced without clears through shower 8. The renderer and actual cancellable scheduler then deliver showers 9–14. Core states match deterministic replay; the last arrival is censored. Calm/Reduce Motion/VoiceOver are not used to suppress normal animation.

| After shower | Collapse sources | Current V2: ready → scheduled deadline | Existing longer V1 |
| --- | --- | --- | --- |
| 9 | 0 | 0.692 s | 1.724 s |
| 10 | 3 | No ready state observed | 0.768 s |
| 11 | 2 | 0.045 s | 0.653 s |
| 12 | 0 | 0.434 s | 1.249 s |
| 13 | 0 | 1.333 s | 2.432 s |

An earlier V2 repetition likewise had no ready state after 10 and only 0.028 s before the scheduled deadline after 11. Times vary by frame scheduling/load; these are one simulator/history, not guarantees for every board or device. Recorded events also retain actual due times and per-action admitted groups. The candidate requires at least 0.5 s after both sampled collapses; it passes. This is a measured opportunity to start input, not a claim that a full human decision fits in half a second.

The responsible contract schedules the next interval at shower commitment. A heavy collapse's full sequence is about 1.70 s: swallow, gravity phases, overlapping approach/stagger and landing. The current faster interval is also 1.70 s. If rain is due when presentation completes, Store delivers the one pending shower immediately. A callback-based schedule extension would violate the established ownership boundary. Reusing a longer saved cadence is the narrower candidate; it preserves full animation and the single-deadline model.

## Verification and source

Initial tested HEAD: `edc893c6abf7f9b939fefc5f6909447c7e3b3974`, main `dc0b3f2` (PR #99). Changed inputs are the four `Pacing*`/wrapper files and the focused native test; documentation is separate. Exact model hashes are in the summary. Xcode 27.1 / Swift driver 1.168.6, macOS 27.0.1 arm64; Debug iPhone 16 Pro Max Simulator, iOS 27.0 (24A434), UDID `5107CBBF-108B-4B94-9125-A873F948A38C`.

- Original missing `CriticalMassPresentation.warning` compilation failure is reproduced in the preceding [contact report](../calibration-timing-and-arrange-2026-10-18/CONTACT_BOUNDARY.md). The wrapper now extracts that exact pure method and the exact production `GravityTimeline`, without stubbing their behavior. Source boundaries fail if missing/ambiguous.
- Fixture checks verify four overlapping sources counted once per consumed cell; 1.34 s normal / 0.15 s quiet completion for the fixed one-arrival collapse; ordinary clear and no-arrival gravity completion; and single owned completion. Replay/save invariants execute for every accepted modeled action. A repeated 40-run sample has identical complete run objects and event sequences.
- Native baseline/candidate checks pass in 12.796 / 18.195 s; prior current/retained-rule comparison passes in 12.823 / 12.521 s. `swift test`: 160 pass. Debug compilation, hygiene and diff checks pass. No Release build is needed for this offline/hosted-test-only batch.
- No production rule/save or interruption behavior changes. Existing interruption checks remain source-bound. Actual VoiceOver and physical-device/haptic/frame-quality acceptance are not run here.

Commands and raw runs are under ignored `artifacts/calibration-critical-mass/`; native results are `artifacts/calibration-native/critical-input-windows.xcresult` and `critical-cycle-comparison.xcresult`. Native commands select the named methods in `NativeInputWindowTests` using the preceding contact batch's Debug destination/DerivedData/signing flags. All new tests reuse existing target membership. No artwork is generated or promoted by this measurement report.

## Integrated artwork recheck

Main advanced to `b24fde8e1084aaabdea8882cb1a299b5b799f450` (PRs #100/#101: evolving facets and Crystal Comet). Local merge `e40fabe76b259279b76e671622b5ac11020d0512` preserves that work. Core, Store, scene scheduling and motion constants are unchanged across this integration; the wrapper recompiles current value declarations and hashes the changed presentation sources. Its complete 40-run repeat matches the earlier result exactly. The native table above uses the current integrated renderer: V2 passes its observational check in 12.841 s, V1 passes the >=0.5 s candidate requirement in 18.111 s. Both retain all committed-state, final-clear and cleanup assertions. The prior comparison's V2 shower-11 deadline was already overdue; those earlier values remain in the summary instead of being relabeled.

`swift test` and hygiene/diff checks pass on the integrated source. Exact integrated hashes and both native records are under `integrated` in the summary. Raw current artifacts: `artifacts/calibration-critical-mass/integrated-repeat/` and `artifacts/calibration-native/critical-integrated-windows.xcresult`. This batch changes only measurement tooling, hosted tests and documentation; no production default, saved rule, asset or routing change is introduced by this work.

## Crowded celebration follow-up

[Current-source award review](AWARDS.md) adds a reproducible 26-star current-rule sample, native compact/large host captures and maximum-text fallback checks. It retains the existing art; repeated automatic and physical recognition remain open. Earlier timing measurements above keep their original source.

[Repeated automatic sample](AUTOMATIC.md) records 31 showers, 44 starlight and three queried-ready non-scoring attempts. One occurs before any award; current-rule deadline-order checks pass, while exact native contact admission remains uninstrumented.
