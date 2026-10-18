# Does faster cadence create pressure when repeated clears are allowed?

**Result: Partially verified — pre-gravity model sensitivity established; current native input windows and human response remain open.** Owner: current implementer.

Hypothesis before implementation: the effect of the adopted faster V2 cadence depends on time available to recognize/execute clears, even when the modeled policy may clear repeatedly between showers. Compare V1 and V2 with unchanged current generation, Store and trace-hold ownership. This is a sensitivity model, not measured human reaction time or preference.

Scope: seeds 0–15, 120 virtual seconds, assumed reaction delays 0.25, 0.75 and 1.5 seconds; trace steps remain 0.12 seconds. Existing largest-clear, height-safety and trace-oriented policies run with both modeled full/quiet presentation durations. Each trajectory has its own outcomes; later actions/RNG relief can diverge. Keep each policy/motion/delay denominator separate. No one-clear-per-shower restriction, hidden-column strategy or new app export.

Acceptance: preserve the runner's historical default comparison; admit only named supported cadences, positive bounded delays and distinct comparison IDs; record all assumptions and input hashes; retain replay/self-checks and repeat a representative run deterministically. Use unchanged production Core/Store. No native, human, actual VoiceOver or performance claim from model output.

Decision point: after these named samples, retain current gameplay. Report whether changing the recognition delay changes observed overflow/headroom or clear throughput. Any tuning proposal needs relevant native/player evidence; do not choose a new spawn/pressure/reward rule from the simulated scores alone. Keep this reusable offline measurement option; no pilot flag or runtime selector is introduced.

## Findings and decision

Keep the adopted V2 cadence unchanged. The model is sensitive to its assumed recognition delay, so it cannot establish a player difficulty curve. Faster V2 has more overflows in these trajectories; at 1.5 seconds the model often fails to begin a clear after settlement. The next test should measure native input-ready intervals during automatic ordinary/heavy showers and observe whether players plan during falling, rather than tuning shower density from these scores.

All rows below use Opal/storm generation at main `30ce546`, before gravity integration `0cd430e`. They do not describe the current gravity-enabled game. All rows below use 16 seeds, at most 120 virtual seconds, and modeled full presentation. V1/V2 values remain separate; policies are selected behaviors, not independent participants. Median clear rates use each round's active time, so early overflow changes both numerator and denominator. None estimates human success or enjoyment.

| Assumed delay | Policy | Overflows V1 / V2 | Median clears/min V1 / V2 | Median busy time V1 / V2 |
| --- | --- | --- | --- | --- |
| 0.25s | Largest clear | 5 / 12 | 17.8 / 21.9 | 52.9% / 69.4% |
| 0.25s | Height safety | 4 / 8 | 17.9 / 22.3 | 52.9% / 70.2% |
| 0.25s | Trace oriented | 5 / 12 | 17.7 / 21.8 | 52.4% / 68.5% |
| 0.75s | Largest clear | 2 / 10 | 16.0 / 16.0 | 50.3% / 61.4% |
| 0.75s | Height safety | 5 / 6 | 15.5 / 16.0 | 50.0% / 60.6% |
| 0.75s | Trace oriented | 2 / 10 | 15.8 / 15.9 | 50.1% / 60.0% |
| 1.50s | Largest clear | 11 / 16 | 10.8 / 1.5 | 44.8% / 50.1% |
| 1.50s | Height safety | 7 / 16 | 10.6 / 1.4 | 44.8% / 50.2% |
| 1.50s | Trace oriented | 10 / 16 | 10.2 / 1.4 | 44.0% / 49.5% |

[All separate cohorts](summary.json) retain the quiet-model results too. Raw per-action timelines, summaries and provenance remain under ignored artifacts/pacing-sensitivity. [Input/run hashes](source.json) identify the exact tool and production inputs.

## Why the result needs a native check

The model waits until Store.canClear becomes true before starting its entire recognition delay. Every busy interval cancels that pending decision. A player can inspect a forecast or plan while stars are moving; this model cannot. Its full-arrival duration is an existing scene-duration substitute, not measured native animation. Current Store/trace intent and ticket ownership compile unchanged; timing lookups select the actual Core V1/V2 steps through the existing test boundary. The saved generation/cadence are not rewritten.

Choices comprise all ordinary groups and one DFS full-component trace per family, not every useful subset. Trace-oriented ranking deliberately favors traces. It models neither visual search nor finger geometry, and the DFS walk can be inefficient. Traces own the real Store hold while modeled steps proceed. Later actions can alter RNG relief and arrival histories despite equal seeds; comparisons are not identical-future streams. No-opportunity time counts only clear-enabled states with no enumerated move and must not be read as total waiting or inverse engagement. Presentation-busy time is separate. Overflow counts are censored observations, not calibrated difficulty.

## Verification

Historical default remains openingV1 versus announcedCycleV1 at 0.45-second recognition / 0.12-second trace steps. A one-seed, ten-second default smoke matched all twelve raw run objects from the unchanged parent implementation in a temporary Git archive. Five invalid option cases rejected before output creation. Runner self-checks and committed-state Core replay checks passed for every accepted sample. The representative 0.75-second run repeated byte-for-byte: SHA256 `38e787b387ac1e9c80344109088fb6a4da086175acba17b81436b33cdfec7b48`.

`swift test` passed 91 checks, zero failures, `/tmp/starfall-pacing-sensitivity-core.log`. Hygiene and whitespace checks passed. Inputs remained hash-identical across all four accepted pre-gravity runs; their historical hashes deliberately differ from the later gravity-enabled checkout. Xcode 27.1 / Swift 6.4 on macOS; Core compiled optimized, Debug Store/tool compiled with the runner's existing Onone model build. App sources/resources/project are unchanged, so this offline-tool batch does not add native/build acceptance. Existing [automatic native storm evidence](../storm-automatic-presentation-2026-10-17/README.md) does not measure usable input windows or human preference.

## Reconciliation with gravity-enabled main

Main 0cd430e adopted gravity while this study was being prepared. Preserve the preceding table as historical evidence; do not carry its overflow counts into the new generation. The first current-main runner smoke failed compilation because Core was built without DEBUG while the current Debug Store references GravityFixture. Compile the actual Core library with DEBUG and use its authoritative ConstellationFixture instead of compiling the historical tool duplicate. No app/Core files were edited.

A one-seed, sixty-second V1/V2 compatibility smoke then passed all runner/replay checks against gravity-enabled main. Two ten-second current-source runs also matched byte-for-byte: omitted options versus explicit openingV1/announcedCycleV1 and 0.45/0.12 delays. `swift test` passed all 109 current Core checks, zero failures, `/tmp/starfall-pacing-gravity-core.log`. [Current compatibility provenance](gravity-main-compatibility.json) is separate from the earlier source record.

This is compilation/action-replay compatibility, not validated gravity balance modeling: the existing policy has no explicit captive-star action and the presentation substitute does not model gravity-phase durations. A new gravity-inclusive sensitivity or native input-window study must address those gaps before drawing gameplay conclusions. Local full app/native acceptance remains with the gravity integration's source-bound evidence. Current tool/CLI changes introduce no runtime route, save change, app resource or production rule.
