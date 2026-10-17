# Shower-phase offline comparison — 2026-10-17

Decision: extend to one announced native phase trial. No production or native-lab routing changed. The user proposed events/phases within a level; [the bounded design and acceptance criteria](../../design/SHOWER_PHASES.md) define the next playable experiment.

Implementation: `python3 tools/mechanics/compare-showers.py --burst` derives nine natural-only showers then three higher-column pressure showers from the canonical candidate patch. `turns + 1` selects the phase for the next generated forecast. The schedule adds no RNG draws or mutable timer. Its generation marker is candidate-only and does not support importing saves from another candidate lab. Baseline pin and complete input/core hashes are in [comparison.json](comparison.json).

All policies use seeds 0–199 with a 60-shower cap. These are automated choices, not player reactions. Compare with the source-bound natural and pressure reports in the preceding evidence directories.

| Clear-all policy | Natural-only | Constant pressure | Nine + three burst |
| --- | ---: | ---: | ---: |
| Multiple-choice decisions | 503/4337 (11.6%) | 507/4210 (12.0%) | 494/4294 (11.5%) |
| Choices involving tall columns | 168 | 262 | 187 |
| Mean showers, including capped survivors | 32.27 | 31.35 | 32.115 |
| Rounds ended by cap | 197/200 | 200/200 | 199/200 |
| First choice by shower twenty | 156/200 | 158/200 | 155/200 |

First-group policy: burst offered a choice by twenty in 159/200 rounds, compared with 160/200 for both constant candidates. This gives no evidence of a substantial early-choice improvement. The proposed benefit is the readable change of rhythm, which this sampler cannot measure. The burst does not inherit the overly generous survival extension that rejected broad pairing.

Verification: optimized Swift compilation and execution of baseline and candidate sampler; 161 baseline saves × 12 unchanged continuations; 200 candidate opening/round-trip/preview samples. Candidate-specific checks cover 120 schedule positions and 200 seeded clear/forecast/save continuations, observing 940 phase transitions. These checks establish schedule and replay behavior, not visual warning correctness or human understanding. The first run stopped at a strict patch-anchor check because the selection expression occurred twice; the replacement was narrowed to the primary-column expression before rerunning successfully.

Current working-tree `swift test`: 61 tests passed, zero failures. `python3 scripts/ci-hygiene.py`, Python compilation and `git diff --check` passed. Raw output: `/tmp/starfall-burst-comparison.json` and `/tmp/starfall-burst-current-core.log`. Current production tree includes unrelated environment/view/project edits; those are not part of this experiment. The comparison itself exports the immutable baseline and hashes all rule/tool inputs.

No application-target sources or resources changed in this batch. Simulator build, native interaction, automatic-deadline phase transitions, interruption behavior, visual/full-motion behavior, Dynamic Type, actual VoiceOver and physical-device validation of phases are **unverified**. There is no phase HUD or native burst app yet. First Light remains excluded by the candidate's existing guard and baseline continuation checks; no new challenge or progression is introduced. Old-save coverage proves continuation, not a migrated cross-candidate replay/new-round contract.
