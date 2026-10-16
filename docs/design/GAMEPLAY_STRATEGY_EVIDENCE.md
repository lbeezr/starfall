# Visible-board strategy evidence

Executed 16 October 2026. **Keep 70 cleared jewels in 18 valid moves.** This bounded diagnostic closes a gap in [GAMEPLAY_RESEARCH.md](GAMEPLAY_RESEARCH.md): survivor planning occurs on generated game boards and improves these fixed policies' results, beyond the existing synthetic lesson. It does not establish human comprehension, fun, relaxation, accessibility, replay or optimal play. No gameplay, UI, assets or tuning changed.

## What ran

[The retained Swift driver](../../tools/gameplay-study/main.swift) compiled alongside a frozen copy of the actual `Sources/StarfallCore/Game.swift`, with Apple Swift 6.4 and optimization enabled. The wrapper snapshots source before compilation and keeps its compiler/cache files in a temporary directory, separate from the app/package builds. There are no new dependencies.

The study completed **10,000 rounds**, five policies on the same 2,000 initial seeds, with **170,294 accepted-turn checks**. It checked legal-component enumeration against the core, move/score changes, valid saves, and every chosen action's known survivor positions when recovery did not occur. **145,973 chosen-action known legal survivor-group bounds** were checked against the resolved core boards; none permitted recovery or shrank below the predicted size. Those geometry checks include terminal boards and do not imply an extra move after the round ends.

Study-specific checks also passed: the synthetic lesson's 3→7, 3→4 and 5→3 survivor counts; its mirrored/recolored transfer; immediate-win and one-move guards; all 125 assignments to the lesson's three unknown refill slots; and 125 actual core executions of the lesson and winning follow-up. The original [Python geometry helper](../../tools/gameplay-study/visible_survivors.py) remains unchanged. These are rules/tool checks, not simulator, device, visual or human-play validation.

## Information and policies

Every decision function receives only **board, score and moves**. It cannot access the game, game seed, encoded save, internal generator or future refill. The visible predictor removes a candidate group and compacts known survivors downward, leaving unknown top cells empty. It credits no unknown refill or recovery. A known legal survivor group cannot disappear through refill, and prevents dead-board recovery that turn.

Each distinct orthogonal component of 3+ is one action. Stable ordering is bottom row first, then left to right; remaining ties keep the first action. `next` below is the largest **known** legal survivor component after one clear, or zero if none is known. A two-clear floor is a conservative bound, not expected score; when `next` is zero, free repair/refill may still provide a useful second action.

| Policy | Exact choice |
| --- | --- |
| Random legal A / B | Uniform random distinct legal component using rejection sampling. Two separate fixed random streams, independent of the game's seeds and RNG. No win override; these are intentionally untactical baselines, not beginner models. |
| Largest | Maximum immediate group size. |
| Largest + survivor tie | Maximum immediate size, then maximum `next` among equally large groups. It never deliberately takes a smaller group. |
| Two-clear floor | Maximum `immediate + next`, then maximum immediate size. Recomputes after each turn; it does not commit to a second tap or search unknown refill. |

Both survivor policies take the largest group whenever it wins immediately or only one move remains. The random policies are seeded once per entire 2,000-round run with `0xA24BAED4963EE407` and `0xF1357AEA2E62A9C5`, respectively; no per-game seed enters them. The shared generator type is used as a separate deterministic source of baseline choices, not as a copy of the game's hidden generator.

Policies and seed banks were fixed before accepting results; no weights or thresholds were fitted. The two cohorts are:

- **Sequential:** UInt64 seeds 0–999, matching the comparable cohort in [PLAYTEST.md](../PLAYTEST.md).
- **Dispersed holdout:** `i &* 0x9E3779B97F4A7C15 &+ 0xD1B54A32D192ED03`, with wrapping UInt64 arithmetic, for `i` in **1000–1999**. This cohort was not used to tune a policy. The older diagnostic used `i` in **0–999**, so its combined result is a different sample.

Policies share initial boards. Their subsequent choices change survivors, refill placement, random consumption through recovery and later boards. Paired outcomes do not represent identical later luck. Initial repair is not separately observable; reported repairs are after accepted turns only.

## Results

| Policy | Sequential wins / 1,000 | Holdout wins / 1,000 | Total wins / 2,000 | Mean turns used | Rounds with post-turn repair |
| --- | ---: | ---: | ---: | ---: | ---: |
| Random legal A | 396 | 510 | 906 (45.30%) | 17.59 | 995 (49.75%) |
| Random legal B | 414 | 530 | 944 (47.20%) | 17.57 | 1,045 (52.25%) |
| Largest | 616 | 708 | 1,324 (66.20%) | 17.08 | 1,192 (59.60%) |
| Largest + survivor tie | 727 | 806 | 1,533 (76.65%) | 16.73 | 977 (48.85%) |
| Two-clear floor | 807 | 862 | 1,669 (83.45%) | 16.18 | 865 (43.25%) |

Largest's **616/1,000 sequential wins reproduce the earlier diagnostic**. Its new combined 1,324 wins versus the earlier 1,266 are not evidence of a rules/balance improvement: the dispersed seed cohort changed. Winning rounds stop immediately, so mean turns and terminal scores are not fixed-18-turn totals or measurements of human duration. Full terminal score distributions and per-round counts are retained in the raw results.

| Candidate versus largest, paired initial seeds | Both win | Candidate alone wins | Largest alone wins | Both lose | Win-rate difference |
| --- | ---: | ---: | ---: | ---: | ---: |
| Random legal A | 718 | 188 | 606 | 488 | −20.90 percentage points |
| Random legal B | 749 | 195 | 575 | 481 | −19.00 points |
| Largest + survivor tie | 1,226 | 307 | 98 | 369 | +10.45 points |
| Two-clear floor | 1,249 | 420 | 75 | 256 | +17.25 points |

The survivor tie rule changes only **2,921/33,454** of its decisions from the largest policy's choice on that same observed board, yet shows a consistent advantage in both cohorts (+11.1 and +9.8 points). The two-clear rule chooses a smaller immediate group on **3,562/32,368** turns and improves on largest in both cohorts (+19.1 and +15.4 points). Neither is uniformly superior: largest wins 98 and 75 paired rounds that the respective survivor policy loses. Joint losses do not establish impossible seeds.

## How often planning is available

To avoid counting only opportunities created by the planner itself, the following signals were recorded **on largest-policy trajectories**. Planning-eligible means at least two moves remain and no immediate action wins. A strict smaller-group setup must have a greater known two-clear floor than **every** currently largest action, including their best possible survivor tie-break. This excludes a mere tie-breaking improvement.

| Signal | Sequential | Holdout | Total |
| --- | ---: | ---: | ---: |
| Planning-eligible turns | 16,242 | 15,923 | 32,165 |
| Turns with a strict smaller-group setup | 1,573 | 1,694 | 3,267 (10.16% of eligible turns) |
| Rounds containing at least one such turn | 755 | 795 | 1,550/2,000 (77.50%) |
| Such turns with a newly joined known legal component | 1,444 | 1,550 | 2,994 |
| Exactly two moves left, known two-clear win available | 160 | 168 | 328 |
| Of those, a known win requires a smaller first clear | 5 | 10 | 15 |

“Newly joined” means the known follow-up contains survivors from at least two previously separate components; it does not mean refill created the group. Counts are trajectory-dependent opportunities, not human recognition rates. Largest trajectories also contain **9,065/34,165 forced-choice turns (26.53%)**, when choosing between groups is unavailable.

The fifteen late-game cases establish a narrow practical use for taking a smaller first group: a known two-clear win exists where no largest-first action has that guarantee. They do not establish that largest-first actually loses; unknown refill could improve its follow-up.

## A reachable example for the next planning probe

The [example JSON](../../tools/gameplay-study/results-2026-10-16/reachable-examples.json) retains the first four qualifying generated positions, with their exact preceding taps, source seed and predictions. Seeds are replay provenance only and never policy input. Unlike the earlier synthetic lesson, these positions were reached by actual core play.

Example four: seed 1 after nine largest-policy moves, **score 43, nine moves left**. Rows below are top-to-bottom; R = rose, A = aqua, T = amber, V = violet, M = mint.

```text
R M M R V R M
V T A T A T M
A A M R M A R
M M M V M M A
A A V M M T A
V M A V R M T
R R R T A V R
```

- Clearing the five-mint group anchored at player row 5, column 4 scores five and leaves a known largest group of four: two-clear floor **9**.
- Clearing the bottom-left three rose scores three and joins at least nine known mint: two-clear floor **12**. It needs a second tap and move. Unknown refill can increase either result.

This is an example of a stronger guarantee, not proof of a globally best move or a forced loss for the other choice. The four retained examples were selected by encounter order and are not a representative visual sample.

## Uncertainty and next action

These deterministic convenience seed banks do not define a probability distribution of human play or production seeds, so no population confidence interval is claimed. Cohort spread matters: largest wins **61.6% versus 70.8%**, two-clear wins **80.7% versus 86.2%**, and the two random streams differ by **1.9 points overall**. The directional survivor-policy gain holds in each cohort, but its exact size is sample- and policy-specific. No policy search proves optimality, universal solvability or that a person can perform this calculation comfortably.

Keep the current rules and the [six-person playtest](FIRST_PLAYTEST_PROTOCOL.md). The next useful action is to observe whether people can explain and enjoy a survivor join in actual play, then optionally use the reachable position above as a fresh planning probe after the synthetic lesson. Record predictions before revealing a result, distinguish guarantees from hoped-for refill, and keep spontaneous play separate from prompted probe performance. Do not add an automatic best-move hint, tutorial feature, new mechanics or target change on the strength of bot results alone.

## Reproduce and inspect

From the repository root, run:

```sh
sh tools/gameplay-study/run.sh /tmp/starfall-strategy-reproduction
diff tools/gameplay-study/results-2026-10-16/summary.json /tmp/starfall-strategy-reproduction/summary.json
diff tools/gameplay-study/results-2026-10-16/rounds.csv /tmp/starfall-strategy-reproduction/rounds.csv
diff tools/gameplay-study/results-2026-10-16/reachable-examples.json /tmp/starfall-strategy-reproduction/reachable-examples.json
```

The default output directory is the retained dated result directory; specify a separate destination to preserve the recorded run. Each run verifies the study before sampling. The summary, 10,000-row CSV and four example records are deterministic for identical source/compiler behavior. Provenance includes run time and temporary paths and is expected to differ. Core/source changes should trigger a new dated report instead of silently replacing these results.

Two full executions produced **byte-identical summary JSON, round CSV and example JSON**; the repeated run is a reproducibility check, not an additional independent sample. Independent Python accounting reproduced the CSV totals/means, and the unchanged geometry helper matched every retained example's immediate value, two-clear floor and survivor grid. Shell syntax and `git diff --check` also passed. The retained outputs total 640,010 bytes.

- [Summary and paired/cohort results](../../tools/gameplay-study/results-2026-10-16/summary.json)
- [One row per policy/seed round](../../tools/gameplay-study/results-2026-10-16/rounds.csv)
- [Compiler/source/output provenance](../../tools/gameplay-study/results-2026-10-16/provenance.txt)

Input workspace HEAD: `60f44a0447f644174613370f25302cd5205a8311`, with existing uncommitted work. The exact core snapshot SHA-256 was `9ab2d57af8fe0ee804ce56e762eb5833a08ae5f39e8916ffaa0fe708d90e7086`; HEAD alone does not identify this core. The retained driver SHA-256 was `b939191cd4c2795bf3e1fa73042bccce08a63f6ff655a26dea453bf088c7e7ca`.

Only the new driver/wrapper/results under `tools/gameplay-study/` and this evidence document belong to this lane. Existing app, core, tests, roadmap, validation and research/protocol files were preserved. No participant contact, publication, account/network feature, paid asset, SDK or app build is part of this study.
