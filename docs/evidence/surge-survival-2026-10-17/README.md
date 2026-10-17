# Surge survival beyond the initial cap — 2026-10-17

Decision: keep the current nine-preparation / three-surge rule as the leading isolated phase experiment. The longer sample does not justify shortening the event or adding another variant. It resolves censoring in these selected seeds/policies, not human enjoyment, every seed or a mathematical survival bound.

The original 60-shower sample left 21/200 clear-all Surge rounds unfinished. The comparison tool now accepts bounded sample caps of 60, 120 or 240 and records per-seed observed lengths and capped seeds. This changes analysis only: every game rule, RNG choice, native route and save contract is unchanged. Unsupported caps are rejected. Both 60 and 240 were executed in this batch.

At cap 240, **all 200 seeds ended under each of the six policies** for baseline, natural-only paired showers and Surge. The largest observed Surge round was 126 showers. No 240-shower survivors remain censored in this sample.

| Metric, showers | Baseline | Natural-only | Surge |
| --- | ---: | ---: | ---: |
| Idle mean | 19.675 | 20.155 | 16.675 |
| Clear-all mean | 26.450 | 32.480 | 39.385 |
| Canonical-first mean | 26.215 | 33.195 | 39.075 |
| Clear-all median | 26 | 30 | 38 |
| Clear-all 95th percentile | 38 | 49 | 74 |
| Clear-all maximum | 49 | 82 | 126 |

Surges end idle rounds sooner but extend active-clearing rounds. This is consistent with extra arrivals creating both crowding and useful matches. It supports presenting the event as an opportunity to exploit rather than a promise of higher difficulty. The longer active tail remains a balance consideration; these bots do not model reaction time, animation gates or human strategy. The preview-aware policy additionally sees landing columns unavailable to the player. Do not convert shower counts into observed human play times.

## Verification and reproduction

Commands: `python3 tools/mechanics/compare-showers.py --dense-burst`, the same command with `--shower-cap 240`, and `python3 tools/mechanics/compare-showers.py --natural-only --shower-cap 240`. All use immutable source `30af812aa3bf3105a55d8b960288e1d2ac672c2c`, seeds 0–199 and the same six policies. The tool checks every committed state with `isValidSave`, verifies distribution sums against aggregate counts, and checks that capped seeds really reached the requested cap.

The default-60 run reproduced every existing baseline/candidate metric in the preceding Surge report exactly. Across 60/240, rounds already ended at 60 retained exactly the same per-seed lengths; censored lengths could only extend. Independently repeated baseline samples from the two 240-cap commands were identical. Candidate core hashes are unchanged. Save/preview compatibility checks passed as before; Surge phase checks observed 1138 transitions in their separate fixed-bound replay sample.

Durable summaries retain all aggregate metrics, length summaries, longest/capped seeds, input/core hashes and hashes/paths of full raw reports: [Surge 60](surge-60-summary.json), [Surge 240](surge-240-summary.json), [natural-only 240](natural-240-summary.json). Raw per-seed lengths remain in `/tmp/starfall-surge-cap60.json`, `/tmp/starfall-surge-cap240.json` and `/tmp/starfall-natural-cap240.json`. The 60-cap summaries remain censored where indicated; their maximum observed lengths are not completed-round maxima.

Optimized Swift compilation/execution, Python compilation, repository hygiene and diff checks passed. The current repository's `swift test` also passed; that package check is separate from the frozen candidate simulations. No application-target source changed, so there is no new simulator/visual/accessibility claim. Existing [native acceptance](../surge-native-2026-10-17/README.md), [input checks](../burst-input-2026-10-17/README.md) and [agent-simulated observations](../simulated-surge-playtest-2026-10-17/README.md) retain their source bounds and limitations. Actual VoiceOver, learner comprehension, devices and production migration remain open before adoption.
