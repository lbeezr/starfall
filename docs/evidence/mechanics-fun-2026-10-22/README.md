# Make setup work earn its payoff

**Result:** Research and bounded offline comparison verified; human comparison unperformed · **Owner:** Current implementer · **Date:** October 22, 2026

Prioritize reducing setup effort before a satisfying clear. **Four-star straight lines are the strongest next playtest candidate:** the simple policy needs about 40% fewer setup exchanges per scoring exchange in both locations. Five gives mixed results. Six and seven have identical recorded outcomes and metrics across 28 paired runs, without a line opportunity in their sampled decisions. These are mechanical results, not a preferred rule established with people.

The user reports that seven feels excessive and, when asked about the main frustration, selects **“Too much arranging before a satisfying clear.”** That is direct qualitative feedback and the leading design problem. Observe which part of the arrangement causes that cost rather than treating faster showers as the answer.

**Next action:** Prepare one native four-star-line comparison, holding squares/crosses, supply, cadence and score constants fixed, with a new versioned definition preserving retained rounds. Use the [current Story packet](../../design/CURRENT_STORY_PLAYTEST.md) for short natural play and preference observations. The user's feedback supports candidate development now; this packet adds no approval gate. This investigation changes no shipped rule or saved round.

## What is actually implemented

New Lantern/Ribbon visits use revision 3: automatic four-star squares, five-star crosses and full seven-star rows/columns. Four-direction adjacent exchanges arrange stars; taps/traces cannot clear. Grown stars occupy one pattern cell. Simultaneous patterns spend their union once; falling survivors can start another phase. Independent moves reset the causal multiplier. [Recipe owner](../../../Sources/StarfallCore/StarRecipe.swift), [resolution owner](../../../Sources/StarfallCore/SkyResolutionPhase.swift).

The authored openings contain 24/25 stars, supply uses five families and five arrivals per shower, and the nominal cadence is six/four seconds. Objectives remain 150,000/220,000. Supply is deterministic with fixed authored seeds 42/4202, rather than independent randomly seeded level starts. [Definitions](../../../Sources/StarfallCore/StoryChallenge.swift).

The [previous production model](../story-patterns-2026-10-20/balance.json) won Lantern with 59 setup exchanges and 27 scoring exchanges, and Ribbon with 83/35. It used no lines and mostly single-phase clears. Its search explicitly favors distance to squares; these outcomes establish reachable goals and flag setup burden, but cannot establish that humans cannot use lines. Shower/action counts are not elapsed human time.

First-phase awards for ordinary, ungrown ingredients follow the same size formula for every shape:

| Pattern | Actual occupied stars | Award |
| --- | ---: | ---: |
| Square | 4 | 5,000 |
| Cross | 5 | 7,000 |
| Proposed six-star line | 6 | 9,000 |
| Current seven-star line | 7 | 11,000 |

These are derived examples from [StoryScore](../../../Sources/StarfallCore/StoryScore.swift), excluding overlap and growth. A two-phase chain of two ungrown squares earns 5,000 + 10,000 = 15,000. A long line earns no separate shape-specific premium. This suggests examining effort, space freed and follow-ups together; adding points alone need not make a line enjoyable.

## What outside research supports

Sources checked October 22, 2026; the following adaptations are design judgments.

| Primary source | Verified finding | Question for Starfall |
| --- | --- | --- |
| [Nintendo: Pokémon Puzzle League](https://www.nintendo.com/en-gb/Games/Nintendo-64/Pokemon-Puzzle-League-269657.html) | Basic matching starts at three; larger clears earn more points, and battle combos/chains send attacks. | Can a reachable ordinary clear lead into deeper planning and a dramatic cascade? It supplies no optimal Starfall threshold. |
| [Nintendo: Panel de Pon strategy](https://www.nintendo.co.jp/wii/vc/vc_pa/vc_pa_07.html) | Players can raise panels to find work; clears briefly stop rising, with longer stops for chains/simultaneous clears. Exchanges during clearing can extend active chains. | Are there useful choices while waiting, and does a skilled clear create understandable recovery? These are related-series facts, not verified N64 timing constants. |
| [Ryan, Rigby and Przybylski, 2006](https://selfdeterminationtheory.org/SDT/documents/2006_RyanRigbyPrzybylski_MandE.pdf) | Four studies associate experienced competence/autonomy with enjoyment and preference; intuitive controls are relevant to those experiences. | Ask whether players feel effective and can choose a plan, as well as whether they win. This does not validate our questionnaire or choose a line length. |
| [Mugrai et al., 2019](https://arxiv.org/abs/1907.06570) | Automated matching-game personas model different strategies and are compared with human traces. | Use several policies to expose rule behavior; retain human observation as a separate source of evidence. |

The [existing pacing study](../../design/PUZZLE_PACING_RESEARCH.md) supplies historical context. Its implementation-pending language describes its October 20 source; revision 3 is already implemented. No commercial game was played or timed in this investigation.

## Compare one rule precisely

The six-star candidate means **a maximal horizontal or vertical run of at least six contiguous matching occupied cells**, anywhere on the existing seven-cell row/column. Seven still qualifies and clears once. Six scattered stars, diagonals and five grown stars do not qualify. Squares/crosses remain. Overlapping patterns spend and score each star once.

Keep openings, supply, palette, growth, cadence, objectives, score constants, automatic resolution and presentation fixed. Do not shrink the board or add a line bonus during this comparison. Changing match threshold inevitably changes later board states; compare matched starting histories and complete branches rather than assuming identical later opportunities.

Before a player comparison, verify both six-cell offsets, both orientations, five-cell near-misses, seven-cell maximal runs, overlap, survivor falls and interrupted/restored cascades. A shipped candidate needs a new definition revision: Continue and same-round Replay retain historical rules; explicit new visits choose the current definition. An offline patch is not that compatibility implementation.

## What the new offline comparison found

[The summary](comparison.json) records the exact source, hashes, policies, commands and aggregate counts. For each variant, 24 trajectories use two policies across six action-policy seeds and two locations; another two idle, and two replay the retained winning witnesses. These are **28 trajectories per variant**, reusing the two shipped supply streams. Policy seeds vary choices, not level supply. The ordinary policies permit four nontrivial swaps before each shower, capped at 20 showers; retained witnesses use their exact action schedule with a 40-shower cap. Neither policy plans several moves ahead.

| Observation, identical under seven and six | Meaning and limit |
| --- | --- |
| Each opening offers 31 nontrivial exchanges, including three scoring exchanges; all scoring patterns are squares. | Useful opening actions exist. This does not measure how readily people notice them. |
| The take-best-immediate-clear/otherwise-random policy has no immediate scoring option at 199/224 Lantern and 203/224 Ribbon sampled decisions. All twelve of its runs lose. | Short-sighted play soon requires setup. These roughly 89%/91% values describe this policy's visited states, not human failure rates or time spent bored. |
| Both retained winning paths reproduce their prior scores and 59/27, 83/35 setup/scoring counts. Each has one chain-producing action. | The software still reaches the objective, but mostly through isolated clears after setup. Witnesses remain square-biased. |
| Zero immediate line-producing exchanges at sampled states; no actual line clear in either variant. All paired final signatures and recorded metrics agree. | Six was not exercised naturally in this bounded sample. The result is inconclusive about its benefit to a line-building player; do not claim equivalence for all play. |
| Idle loses both locations after five showers without a recipe clear. | Waiting alone does not repair these fixed openings. This is not an argument for a faster timer. |

Nine finder/resolution fixture cases pass per variant, including both horizontal six offsets, a vertical six, maximal seven rows/columns, grown six, a gap, square and cross. Every actual committed state passes semantic validity, exact JSON round-trip and light-conservation checks: 1,153 state checks per variant. Replay returns the original opening; exchanges preserve the announced forecast and shower count. These checks validate the disposable experiment, not a production revision migration or complete candidate test suite. Vertical upper-offset six, five-cell near-miss, overlap and native interruption coverage remain for a playable candidate.

The next mechanical comparison must include an intentional line-building strategy or assessed near-line positions; increasing random-run count would not address that missing strategy. Given the user's setup complaint, also compare an opening/supply arrangement with a readable one- or two-exchange payoff. Do not change both variables in the same branch. A prototype's low setup count is useful only if players still have consequential alternatives.

## Four and five expose a more promising candidate

Because six never enters the sampled play, [two diagnostic extensions](shorter-lines.json) lower the minimum contiguous run to five and four, respectively. Each uses the same 28-run structure and maximal-run deduplication; squares/crosses and every other Core rule remain unchanged. Actual later boards and run lengths differ between variants. The following ratios pool each policy's own observed setup/scoring exchanges across six runs per location, rather than measuring the same human tasks.

| Minimum straight line | Lantern setup exchanges / scoring exchange | Ribbon setup exchanges / scoring exchange | Interpretation under the take-immediate-clear policy |
| --- | ---: | ---: | --- |
| 7, current | 7.96 | 9.67 | Baseline |
| 6 | 7.96 | 9.67 | No sampled line opportunity |
| 5 | 8.23 | 8.67 | Mixed change; few line clears |
| 4 | 4.79 | 5.88 | About 40% less setup per scoring exchange in both locations |

Four increases opening scoring choices from three to four. Across the twelve immediate-clear-policy runs it produces 53 line recipe instances alongside 56 squares and one cross. Five produces only four line instances in that policy, plus one in random play. Four therefore changes available work rather than simply raising existing awards. Even with four, 82.7%/85.5% of this policy's decision states lack an immediate scoring exchange, and all twelve adaptive runs still lose. Shorter lines alone have not established welcoming difficulty or a satisfactory complete round.

Four also produces two shower-triggered line clears across those twelve runs. Both idle runs still lose at shower five with zero points. The tradeoff is testable: look for deliberate clears and chains without returning to mostly automatic/easy play. Do not interpret the increased average score as enjoyment.

Fourteen fixture cases pass per extension, adding four/five rows and columns plus square/line overlap; 1,183 committed-state checks pass for five and 1,290 for four. The exact old Lantern winning script becomes unavailable under four after 15 showers at 105,000; it stops there and remains **unfinished**, not lost or proven unwinnable. Ribbon's old script still wins. Fixed scripts diagnose changed consequences; a candidate needs newly planned complete-round witnesses and retained-old-rule tests before native adoption.

Recommend four for the next native comparison because it is the first tested threshold to consistently reduce modeled setup burden. An intentional line-building planner could still favor five/six differently; human preference, shape competition, causal depth, recovery and natural line recognition remain open. Test opening/supply changes separately after vocabulary is selected.

## Investigate improvements in this order

| Priority / hypothesis | Smallest useful comparison | Keep it only if… |
| --- | --- | --- |
| 1. Setup work exceeds its payoff | Compare current rules with four-star straight lines; retain every other rule. Six/five remain diagnostic alternatives. | Players intentionally earn more satisfying clears while squares/crosses and setup choices remain useful. |
| 2. Setup rarely produces the desired chain | After selecting vocabulary, alter one opening or supply motif to offer an understandable one-/two-exchange payoff and possible follow-up. | People predict or learn the follow-up, and the payoff comes from their arrangement rather than rain clearing itself. |
| 3. Searching and failed intent obscure strategy | Observe current move/growth feedback first; compare one contextual example or cue only when a specific misunderstanding appears. | The next unaided decision improves without requiring constant hints. Reproduce missed legal input separately from a strategic mistake. |
| 4. Crowding removes recovery before a plan pays off | Observe a real mistake/headroom episode; if pressure is the cause, separately compare bounded earned breathing room after a causal chain. | Players understand why they recovered and have another useful decision; passive waiting does not become the best strategy. |

Use the user's earlier rejection of easy tap clears as a counterexample to “more clears is always better.” Keep automatic patterns. Assess completion length after the active loop works; no enforced minimum duration. Nearby versus/cooperative restoration remains a future direction under the [primary reference](../../design/POKEMON_PUZZLE_LEAGUE_REFERENCE.md), with current implementation offline.

## Compare the player experience, then keep, revise or remove

Use the existing packet's first pilot of up to three distinct people, with phone/tablet observations reported separately. A single returning player's session can guide the next correction; it cannot establish population preference. A convenient five-minute pilot is described in that packet. Never count a blank packet, bot trajectory or participant invitation as an observed session.

For the native current/four A/B, give each person comparable short play in both identified rules on the same device/settings; alternate order across people and record familiarity. Natural play comes before any prepared near-line demonstration. Ask which version they would choose and what moment explains that choice. Record enjoyment and control ratings separately from observed intended moves, setups, chains, recovery and voluntary continuation. A completed-round replay differs from continuing an unfinished round. Count line opportunities before calling a non-use a failure.

At that pilot checkpoint, keep the candidate if deliberate line use and stated preference improve without flattening alternatives or removing recovery. Revise/remove it if extra clears are mostly accidental, square/cross choices disappear or the experience is still tedious. If neither version offers an assessed natural line opportunity, call that comparison inconclusive and investigate arrangement/supply. No threshold is selected for production by these synthetic counts.

## Verification and limits

Source inspected: `943862da8bf89ca86b8f1369c9536cac61cd2e4f`, initially clean. Production Swift, app resources, settings, saves and build inputs are unchanged. Only documentation/evidence differs. Offline execution uses optimized host Swift 6.4 on arm64 macOS 27.0.1; no simulator or app. [Reproduction details](comparison.json) identify the disposable harness and Core hashes. Raw harness/builds/results remain disposable under `/tmp/starfall-fun-audit-2026-10-22`; their absence later requires reconstructing the documented method, rather than treating this as a maintained runner.

`python3 scripts/ci-hygiene.py` and `git diff --check` pass. A local path/whitespace/JSON check covers all changed Markdown plus the new evidence files: 764 relative file links resolve, both studies' 26 Core hashes match the checkout, diagnostic result/harness hashes match and the original-summary identity agrees. The new untracked evidence files were inspected explicitly because hygiene checks tracked paths. No rendered-document review was performed. App builds/tests are inapplicable to this documentation-only repository change; the disposable Core checks above ran separately.

No native interaction, visual, animation, actual VoiceOver, physical-device or human-comparison result is claimed by this report. The user's stated frustration is evidence; an automated score is not an enjoyment measurement.
