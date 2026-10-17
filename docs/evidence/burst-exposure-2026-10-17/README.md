# Does an announced burst change arrivals? — 2026-10-17

Decision: extend the phase experiment with one offline five-star **surge** candidate. The original higher-column burst remains a native cue/flow reference, but its sampled exposure is too weak to assume the countdown demonstrates a distinct gameplay phase. Do not promote either rule. Next: one isolated surge play comparison, retaining the original for that named comparison only, then select/remove or name a concrete remaining question.

## Finding and bounded refinement

The original burst only changes natural five-star showers with an existing legal group and eligible columns. Under the canonical first-clear policy, all 200 sampled rounds reached the first burst, but only 36/200 had any changed forecast there. Seed five—the native flow fixture—had no pressure-specific forecast change in showers 10, 11 or 12. This is evidence about that policy, not every possible player path. A player preserving groups can create different eligibility.

The density candidate keeps nine preparation showers and three surge showers, but offers five stars in every surge shower. It retains higher-column primary targeting when eligible, keeps dry-board relief, excludes First Light and old baseline saves, and does not rewrite announced previews. It consumes the normal size draw before overriding its value, but extra arrivals and board-dependent branches can change later RNG consumption. It is a different candidate generation contract with no native route or compatible cross-lab save import.

| First-clear policy, seeds 0–199 | Original burst | Five-star surge |
| --- | ---: | ---: |
| Rounds reaching first burst | 200 | 200 |
| First bursts with any changed forecast | 36/200 | 200/200 |
| Changed delivered first-burst forecasts | 42/600 (7.0%) | 530/600 (88.3%) |
| First-burst forecasts with changed star count | 0 | 464 |
| Extra offered stars vs same-state preparation | 0 | 1222 |
| Changed forecasts across all delivered burst showers | 119/1396 (8.5%) | 1468/1677 (87.5%) |

All delivered surge forecasts contain five stars. Offered stars can grow existing stars instead of occupying extra cells. Changed forecasts do not prove consequential choices, player understanding or enjoyment.

## Balance implication

The surge creates more matching opportunities and extends automated survival. Present it neutrally as a surge rather than promise a harder pressure phase. These truncated means include capped survivors.

| Clear-all policy, cap 60 showers | Original burst | Five-star surge |
| --- | ---: | ---: |
| Multiple-choice decisions | 11.5% | 20.7% |
| First choice by shower twenty | 155/200 | 198/200 |
| Mean showers including capped survivors | 32.115 | 37.395 |
| Rounds ended by cap | 199/200 | 179/200 |

First-clear choices rise from 19.6% to 43.8%, with 178/200 rounds ending by the cap instead of 196/200. Choices do not uniformly become more consequential: clear-all next-preview outcome differences fall from seven to four, while first-clear differences rise from twelve to forty. The sampler sees exact landing columns for counterfactual analysis; players do not. This supports comparing how players exploit an event, not claiming strategic depth or higher difficulty. Survival extension is smaller than rejected broad pairing (80/200 clear-all rounds ended), but remains an explicit balance risk.

## Verification and reproduction

Commands: `python3 tools/mechanics/measure-burst-exposure.py`, the same command with `--dense-burst`, and `python3 tools/mechanics/compare-showers.py --dense-burst`. Each archives immutable core `30af812aa3bf3105a55d8b960288e1d2ac672c2c`. Input/core hashes are in the [original summary](burst-summary.json), [surge summary](dense-burst-summary.json) and [six-policy comparison](dense-comparison.json).

The observer clones the exact state immediately before forecast generation, including RNG, and disables pressure/count overrides on the clone only. It does not compare already-diverged rounds. Reference and observed executions hash every initial, post-shower and post-clear committed state in canonical JSON order. All 200 per-round SHA256 traces match in both candidates. Both exposure samples' score/shower/end totals and core hashes also match their separate six-policy comparisons. Generated previews are counted separately from consumed showers; none were unconsumed pressure previews in these samples. Raw per-round/event reports remain at `/tmp/starfall-burst-exposure-final.json` and `/tmp/starfall-dense-burst-exposure-final.json`; summaries retain their hashes.

Surge checks passed: 161 baseline saves × 12 identical continuations, 200 candidate opening/round-trip/preview samples, 120 schedule positions and 1138 phase transitions. A temporary baseline package export with the surge rule applied passed `swift test`: 60 tests, zero failures (`/tmp/starfall-dense-burst-core.log`), core SHA256 `91d5c3968bc4154863339b4535441a8f0956eb4f2795f49c58aab3fa31a28f80`. Export `/var/folders/fs/9shw9bf142jg3280dc9n3hhc0000gn/T/starfall-native-baseline-n8r62k_k` was not installed or treated as a native surge app. Python compilation, hygiene and diff checks passed.

Only offline tools and documentation changed. No simulator build or native interaction/visual/accessibility acceptance exists for the surge rule. Phase Lab still runs the original rule with source-bound limits. A native surge export needs a separate save suite/bundle, clear five-star event wording, interruption/animation checks, actual VoiceOver review and observed matched play before adoption. Baseline-save continuation coverage does not prove legacy new-round migration.

Later follow-ups: [Surge Lab](../surge-native-2026-10-17/README.md) supplies separate source-bound native acceptance, and the [240-shower survival sample](../surge-survival-2026-10-17/README.md) resolves the initial cap's censored rounds in these seeds/policies. The values above remain the original 60-cap results.
