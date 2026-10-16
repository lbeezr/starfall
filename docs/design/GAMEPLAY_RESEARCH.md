# Starfall gameplay research

Prepared 16 October 2026. Research and experiment proposal; no gameplay change or human-play result. This is a historical preparation snapshot at the source identified below. Later executed checks are reported separately in [GAMEPLAY_STRATEGY_EVIDENCE.md](GAMEPLAY_STRATEGY_EVIDENCE.md) and [PLAYTEST_KIT.md](PLAYTEST_KIT.md); they do not supply human-play results.

## Recommendation

Keep **70 starlight in 18 valid moves** for the next observed playtest. The current rules support a clear immediate tactic and a small amount of predictable board shaping. Whether people notice, enjoy and reuse that shaping is the most useful unanswered question. Test that before adding difficulty progression or mechanics.

The smallest next experiment is the existing five-minute playtest with six first-time players, followed by a two-minute paper planning probe. It requires no new game feature, analytics or toolchain. It can distinguish rule confusion, disappointing feedback, unlearned planning and disliked outcomes. This document proposes decision thresholds below; they are product hypotheses, not research-established constants or release approval.

## Inspected baseline and evidence boundaries

Read [AGENTS.md](../../AGENTS.md), [the game bible](STARFALL_GAME_BIBLE.md), [PLAYTEST.md](../PLAYTEST.md), [the actual core](../../Sources/StarfallCore/Game.swift), its existing tests, the store's result messaging and the roadmap. No additional local `.agents` skills were present. Input HEAD was `60f44a0447f644174613370f25302cd5205a8311`. The core's Git blob is `32cc17995b4d6530f5e130e9ef74be1b8f846d86`, SHA-256 `145b02ce1be99cd3c5855615eb674c11bf08273db87b0557f29af4d186e14142`; these match the core recorded in PLAYTEST.md.

**Rule facts from source:**

- The board is 7×7, with five kinds. A tap clears its entire matching orthogonal component when its size is at least three. Players cannot choose a subset of that component; diagonals do not connect.
- Each valid clear spends one move and scores exactly its size. Invalid/out-of-bounds taps are free and do not advance randomness. There is no timer, combo multiplier, automatic cascade or reward for speed.
- Survivors compact downward within each column, preserving vertical order. New random shards fill above them. The core generates refill in ascending column order; this implementation detail is not player-visible information.
- Score at least 70 wins, including on the eighteenth valid move. Otherwise zero moves loses. Terminal taps do nothing. No early loss occurs when a target looks unlikely.
- A live board with no legal group receives a free, bounded replacement of bottom-row columns 0–2 with one generated kind. This can connect to neighboring matching cells. It neither scores those cells nor performs a full-board shuffle. Recovery is skipped after a terminal turn.
- Initialization also ensures a legal move. A legal move being available does **not** guarantee the target is attainable. There is no progression, escalating difficulty or adaptation to the player's results.

**Evidence labels used here:** rule fact = directly inspected implementation; recorded diagnostic = previously executed rules evidence; external evidence = source findings in another setting; design hypothesis = proposed interpretation or experiment. No new Swift, Apple simulator/device, visual/audio, human-play or retention validation was performed during this research preparation. Swift was unavailable in that preparation environment. No blocked signing-key download, replacement toolchain installation or network-setting change was attempted.

## Primary sources and what they support

Sources were checked on 16 October 2026. Older foundational work is identified by its original date, rather than presented as a new discovery. Developer accounts and guidelines inform hypotheses; they do not establish Starfall's outcomes.

| Source and type | Evidence reviewed | Bounded implication for Starfall |
| --- | --- | --- |
| **R1 — Ryan, Rigby & Przybylski (2006), [The Motivational Pull of Video Games](https://selfdeterminationtheory.org/SDT/documents/2006_RyanRigbyPrzybylski_MandE.pdf), especially abstract and pp. 2–4.** Primary empirical paper, four studies. | Perceived competence and autonomy were associated with enjoyment and preferences; intuitive controls were relevant to those experiences. Games and populations differ from this puzzle. | Observe whether players understand controls, can explain a consequential choice and feel able to improve. A particular bot win rate cannot substitute for those observations. This does not imply a need for social systems or external rewards. |
| **R2 — Brändle, Wu & Schulz (2025), [Leveling up fun: learning progress, expectations, and success influence enjoyment in video games](https://www.nature.com/articles/s41598-025-14628-2).** Open-access primary research; abstract, game datasets, discussion and limitations. | Three game datasets, including Robozzle, showed preferences around intermediate difficulty; expectations and success also mattered. Two controlled experiments explored those factors. Individual learning histories were unavailable in the game datasets; learning progress was modeled, not directly observed there. | Measure understanding, expectations and satisfaction alongside wins. There is no universal optimal win percentage to import into a relaxing stochastic puzzle, and this paper does not validate 70/18 or a retention claim. |
| **R3 — Kieran Hicks (2022; repository migrated 2023), [Juicy Game Design thesis](https://repository.lincoln.ac.uk/articles/thesis/Juicy_Game_Design_Exploring_the_Impact_of_Juiciness_on_the_Player_Experience/24326740).** Primary doctoral research; repository abstract reviewed, not a full-thesis replication. | Multiple studies investigated embellishments; reported effects depended on implementation and context. Coherence between mechanics, visuals and feedback was central. | Test whether a clear feels satisfying and remains understandable. More particles, louder sound or longer animation cannot be assumed to improve the experience. Effects here are a hypothesis, not an established causal benefit. |
| **D1 — Asher Vollmer & Greg Wohlwend, [The Threes Letters](https://asherv.com/threes/threemails/), especially “Asher Finds Threes,” June 2013 correspondence.** First-party design process and informal play observations. | The developers discuss simple rules, learning through replay, difficulty explaining distant consequences, and abandoning additional complexity. These are candid project-specific observations rather than a controlled retention study. | Seek a reason to try a different choice next round. Preserve a compact system while testing whether its consequences are learnable. Do not import Threes' mechanics, endless structure or success claims. |
| **D2 — Microsoft [XAG 103: additional channels](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/103).** Current primary developer guidance. | Color alone should not carry necessary information; redundant cues support access. | Preserve shape identities and descriptive narration. Essential group, progress and recovery information must remain available with sound and effects disabled. This is guidance, not a certification or an actual VoiceOver test. |
| **D3 — Microsoft [XAG 117: visual distractions and motion](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/117), updated March 2026.** Current primary developer guidance. | Unprompted motion and moving backgrounds can impair attention and reading; options to reduce or remove them help. | Keep settled boards still and Calm effects informative. Inspect real play to see whether trails or constellation travel obscure decisions. |
| **D4 — Microsoft [XAG 108: game difficulty options](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/108), updated March 2026.** Current primary developer guidance. | Experienced difficulty depends on player ability and barriers; different challenge dimensions can need separate adjustments. | Do not confuse motor speed, visual access and puzzle difficulty. The current untimed, free-invalid-tap rules reduce some barriers. This guidance does not authorize adding modes to the frozen MVP; any later assist would need separate scope and validation. |

**Synthesis — design hypothesis:** make a turn easy to read, let the player choose its pace, show its actual consequence, and offer a next attempt without punishment outside the round. A single understandable challenge is sufficient for this experiment. Neither a level map nor a currency is needed to test competence, choice or voluntary replay.

## What meaningful skill currently exists?

The visible board, score and moves are the player's information. Future refill kinds, the PRNG state and knowledge of a seed's previously replayed future are excluded from a claim of general planning skill. Replaying a memorized seed can demonstrate memory, but is not evidence of transfer to a new board.

| Decision or style | Support in current rules | Constraint and observable evidence needed |
| --- | --- | --- |
| **Opportunistic large groups** | Strong immediate support: more starlight for the same one-move cost. Comparing whole components is a real choice when multiple groups exist. | No extra multiplier rewards a large clear. A largest-group win-rate advantage is evidence of a useful tactic, not proof that greedy is optimal. Observe unaided comparisons and reasons. |
| **Visible board shaping** | Clearing a support group can bring known surviving pieces together. Their final rows can be calculated without refill. A resulting survivor group of 3+ prevents dead-board repair that turn. | Only transformations of visible survivors are guaranteed. New pieces can add opportunities. A prospective setup that needs a particular refill color is a risk, not a guaranteed plan. Observe a prediction made before the clear and its transfer to another position. |
| **Conserving moves / securing the finish** | Compare immediate value with the remaining deficit and move budget. A final move should take any visible group that reaches the target. Earlier, a setup can exchange immediate value for a known follow-up. | Waiting itself does not grow a group or save a resource: every legal clear costs one move. Repeated invalid taps are harmless exploration, not an economic tactic. Avoid teaching a blanket “always save the biggest group” rule. |
| **Preserving useful options** | Some actions leave more known legal groups or avoid disturbing a useful component. This can be a tie-breaker between otherwise similar immediate clears. | More choices need not mean a higher winning chance. A single very large group may be better than several triples. Count independent components, not the many cells that activate one group. This is a plausible heuristic, not yet a validated alternate policy. |
| **Deliberate risk / refreshing awkward columns** | A valid clear replaces known cells with unknown ones. A player can consciously accept uncertain future opportunities, particularly with several moves remaining. | No evidence says smaller clears, lower-board clears or “color balancing” reliably improve refill. Do not invent a pity system, guaranteed next color or catch-up behavior. Recognizing uncertainty is skill; predicting hidden outputs is not. |
| **Quiet, low-effort play** | No timer, free invalid taps and a simple visible large-group tactic allow a player to browse and clear at their own pace. | It is a legitimate preference even if it wins less often than deliberate planning. Enjoyment of a tactile ritual does not require an expert strategy. Check that losses do not make this style feel unwelcome. |

These are overlapping approaches, not character classes or separate modes. The current system supports at least immediate value and local shaping as distinct kinds of decisions. It does **not yet establish multiple equally successful long-run strategies**, extensive search depth or an enduring mastery curve. All styles share the same target, and a late deficit naturally narrows useful choices.

### A planning example with no future-RNG knowledge

The optional [visible-survivor study helper](../../tools/gameplay-study/visible_survivors.py) examines only geometry: enumerate current legal groups, remove each, compact survivors and leave refill slots unknown. It does not execute StarfallCore or recommend an optimal full-round policy. Run from the repository root:

```sh
python3 tools/gameplay-study/visible_survivors.py
```

Its deliberately constructed lesson board is shown top row first. `R` = rose, `A` = aqua, `T` = amber triangle, `V` = violet, `M` = mint. Coordinates below use row zero at the bottom and column zero at the left.

```text
row 6   R T M M M M M
row 5   R V R A R A R
row 4   A T A T V M R
row 3   A R R A T V M
row 2   A R M R A T V
row 1   R V V M R A T
row 0   R T T V M R A
```

| First clear, representative cell | Immediate starlight | Largest guaranteed next survivor group | Guaranteed sum if two clears are available |
| --- | ---: | ---: | ---: |
| Aqua, (2, 0) | 3 | 7 rose | At least 10 |
| Rose, (2, 1) | 3 | 4 | At least 7 |
| Mint, (6, 2) | 5 | 3 | At least 8 |

With one move and five starlight needed, mint guarantees the win. With two moves and ten needed, aqua followed by the joined rose group guarantees enough. The two examples use different score/move contexts, so choosing the smaller group is situational. Unknown refill could improve mint's follow-up too; this table does **not** prove mint loses, or shaping dominates greedy.

There is no automatic second score: the rose group requires another tap and move. Because a known legal component remains after each candidate, recovery cannot invalidate these particular survivor guarantees. The board is synthetic; its reachability from an actual generated seed has not been established. It demonstrates an available geometric mechanism, not its frequency in ordinary play.

## What the existing simulations do and do not say

[PLAYTEST.md](../PLAYTEST.md) records 4,000 completed rounds run against the real Swift core: two fixed policies on the same 2,000 starting seeds. This study reviewed the source and report; it did not rerun that driver. Its raw outputs and temporary driver are identified by hashes in that report, but are not repository deliverables.

| Recorded metric | First legal | Largest current group |
| --- | ---: | ---: |
| Wins | 904/2,000 (45.2%) | 1,266/2,000 (63.3%) |
| Mean terminal score | 68.05 | 69.47 |
| Rounds with post-turn recovery | 67.9% | 61.45% |
| Turns offering more than one legal component | 69.63% | 72.06% |

The **18.1 percentage-point** difference shows these policies produce meaningfully different outcomes in this fixed sample. First-legal is a bottom-row/location-biased policy, not a beginner model. Greedy uses visible information and no lookahead. Across paired seeds, first-legal alone won 210; greedy alone won 572; both lost 524. Thus greedy is not uniformly better. A common starting seed shares an initial board, not identical later boards: choices change survivors and how future generated kinds are assigned.

Neither policy estimates human retention, learning, round duration, relaxation, optimal play or universal solvability. Joint failures do not prove impossible seeds; a found winning path would prove only that path exists. A perfect-information solver that reads future RNG would supply a different capability from a human's visible-board policy.

Recovery frequency deserves observation: free rescue preserves continuity but changes cells the player did not select. Roughly 28–30% of recorded turns offered only one component; on those turns action selection cannot distinguish strategies. Measure whether those moments feel restful or automatic before changing generation. A repair rate alone supplies no target rate and no permission to alter the rule.

If later human evidence warrants another simulation, retain the real-core driver and raw results, hold out seeds, deduplicate components, and compare greedy with a policy that receives **only** board/score/moves. A visible-survivor heuristic can rank immediate clear plus a guaranteed next group, with a current-win override and stable tie-breaking. Label it a heuristic: this lower bound ignores possible refill benefits and is not an estimate of expected score. Report paired outcomes, repair/forced-choice rates and rare failures. Do not add a seed-aware oracle and call its advantage human skill.

## Provisional win, loss and difficulty model

**For the MVP:** keep the current binary round result, one progress count and one move budget. Win immediately at 70; lose only after 18 valid clears below 70; a last-move win wins. Keep invalid taps and bounded recovery free. Keep normal New game and saved Continue available. Do not add a loss streak, lives, waiting, rewarded extra moves, or a second score that competes with starlight. End copy should describe the outcome and progress without blame or manufactured urgency.

The target requires **70/18 ≈ 3.89 shards per valid move** across an eighteen-move win. Eighteen triples produce 54, leaving 16 additional shards to find through larger groups. During play, `(70 − score) / moves` is a diagnostic average needed, not a probability or prediction of defeat. Do not add it to the HUD before testing whether players need it. There is no speed-based difficulty and no reason to rush a final decision.

**Progression hypothesis:** start with growth in the player's understanding, rather than growing statistics. Recognize a legal group, compare immediate value, predict survivor movement, then choose between a safe clear and a setup within the remaining budget. There is no requirement that every player reach the last stage. Success on a fresh position is stronger evidence of learning than a lucky win or a repeat of one memorized board.

There is no difficulty progression to claim today. First test a flat, repeatable challenge. If observed outcomes are consistently frustrating after rules/access issues are resolved, the smallest later tuning study would change **one number**: compare 65/18 with 70/18 using the same board-generation rules and counterbalanced seed sets. If repeated evidence instead shows boredom plus a demand for harder decisions, a separately authorized 75/18 comparison could be considered. These are unvalidated research candidates, not implemented modes or a prescribed level ladder. More demanding targets may reward favorable refill rather than deeper thought; check the choice explanations as well as wins.

No secret escalation after wins, intentionally bad refill after engagement, easy boards after purchases, forced losses, ads or account-based targeting. Do not promise every random round is winnable or call every loss a player error. If that promise becomes a product requirement, it needs separate generation/verification work using the actual information available to players.

## Smallest useful experiment and measurable acceptance

**Question:** does the existing loop feel worth another round, and can players learn a useful decision beyond taking the largest group? Six first-time participants are a formative convenience sample; they cannot establish population percentages, retention, accessibility acceptance or a final difficulty curve. Recruit/share only through the coordinator's authorized process; this work contacts nobody and distributes no build.

**Procedure, at most seven minutes each:**

1. Use the unchanged five-minute protocol in [PLAYTEST.md](../PLAYTEST.md), including its uncoached first impression and voluntary-replay question. Record exact build/source/device/OS/settings, whether a round ended, invalid taps and independent legal options at observed decisions. Do not hurry the person to produce a loss. Record their reason for a choice before its result when practical. Label prompted reasons separately from spontaneous comments.
2. When recovery occurs naturally, first ask what changed and whether it spent an extra move. Record “not observed” otherwise. A prepared settled before/after image may be shown in the later probe, but label comprehension from that image separately from comprehension in live play. A status message alone is not proof that the replacement was readable.
3. After the replay question, spend at most two minutes on paper planning. Show the synthetic board above and ask for a one-move/five-needed choice, then a two-moves/ten-needed choice. Ask what they can predict and what they cannot know. No refill sequence is shown. If needed, teach one sentence: “Pieces above a cleared group fall straight down; new pieces are unknown.” Demonstrate the aqua-to-rose join once.
4. Probe limited transfer on a fresh paper version: mirror the board left/right and relabel `R→M, A→V, T→A, V→R, M→T`. The corresponding violet triple joins seven mint pieces. Ask for the same two-move deficit and explanation without another hint. This tests position/color transfer of one concept, not broad expert mastery. Record before/after prediction, hint and reason, not merely whether the chosen answer matches.
5. After open-ended comments, collect simple 1–5 ratings for clear satisfaction, perceived control and calmness (1 low, 5 high). Ask for one concrete moment behind each rating. Use the same questions for winners and losers. No validated psychological scale is claimed.

**Predeclared formative decision thresholds — design hypotheses:**

| Measure | Useful provisional signal | Action if absent |
| --- | --- | --- |
| Rule/goal comprehension | At least 5/6 explain orthogonal 3+, shard count and move limit by the end of the first minute; report unaided and aided counts separately. | Fix the specific wording/legibility issue before tuning. |
| Consequence and control | At least 4/6 explain a choice using current group size or a visible survivor consequence; median control and clear-satisfaction ratings at least 4/5. | Identify whether missing feedback or missing meaningful choice is the cause. One bounded presentation/help change is the first candidate. |
| Learnable shaping | At least 4/6 correctly predict a guaranteed joined group on the transfer probe after at most the stated demonstration, and distinguish unknown refill from known survivors. | Do not market deep planning or build progression around it. Reassess the teaching example and naturally occurring opportunities. |
| Recovery comprehension | At least 80% of those who actually see recovery correctly describe it as free; report the exact n/N. With fewer than three observers, evidence is insufficient. Any repeated “paid a move” or “board shuffled” interpretation triggers review. | Clarify the actual replacement and free status; do not infer a need for new rescue mechanics. |
| Relaxing character | Median calmness at least 4/5, with no repeated report of pressure caused by effects or presentation. | Address the repeated source of pressure before changing the challenge. |
| Short-term replay | At least 3/6 independently choose to start another round when they have time, with their stated reason recorded. “No time” remains separate. | Stop feature expansion; propose one evidence-linked improvement. This signal is not retention. |

These thresholds choose what to investigate next; passing does not constitute release acceptance. Preserve disagreement and individual observations. Missing opportunities are “not observed,” not successes. Keep wins/losses, deficits, moves, chosen styles and time-to-first-valid-clear as descriptive counts. With six people and potentially unfinished rounds, do not tune to a target win percentage. If no rounds end, terminal difficulty remains unknown and needs a separate, consented complete-round observation without time pressure.

If comprehension and access are clear but losing players repeatedly describe the target as discouraging, bring the single-number tuning proposal to the coordinator with those observations. If people enjoy immediate large-group play and decline deeper planning, that is evidence for keeping the small relaxing game. If paper planning transfers but nobody finds opportunities in ordinary rounds, investigate the frequency of visible setups before adding a tutorial or progression.

## Feedback and learning priorities

**Design hypotheses consistent with the sources and bible:** show one authoritative score/move change per valid action; keep the chosen group and survivor fall readable; let the player inspect the settled board. A small, promptly acknowledged clear can be pleasant without promising a bonus. A large group may receive a restrained stronger accent, but starlight remains exactly its size.

The game bible's touch-down group preview is a reasonable later candidate if players misread groups or commit accidental clears. It is not part of this experiment. Its count, cancellation and VoiceOver equivalent would need explicit validation; an automatic best-move highlight could erase the comparison being studied. Similarly, diagonal shooting-star refill must preserve clear straight-down survivor motion or it could obscure the very skill under investigation.

Learning should begin with the board and concise rule, followed by specific feedback for an invalid tap. Use the small gravity explanation only when needed; do not interrupt the first round with a tutorial tour. After a disappointing round, a person should be able to name a choice they might try differently, or say that they simply enjoyed clearing. Never explain a loss as proof that they failed to foresee random refill.

A later repeated-play study would use fresh board sets across sessions and record learning predictions as well as voluntary return. It would require separately authorized participants and data handling. Nothing here establishes multi-day retention, clinical relaxation or general cognitive improvement.

## What not to add

- Timers, speed bonuses, flashing low-move warnings, cascades, multipliers or power-ups to manufacture excitement.
- Level maps, unlock trees, rank/XP, streak obligations, daily chores, energy/lives, consumable retries, shops, currencies, ads, IAP or backend/account/analytics SDKs.
- Automatic catch-up/forced-loss refill, opaque adaptive difficulty, or a recommendation to change RNG merely because two bots lost.
- New shapes, blockers, color-count changes, extra goals or a mascot care economy before the existing loop earns replay on its own terms.
- Elaborate hint/solver systems, global-best-move claims, exhaustive perfect-information search presented as human strategy, or a large balance matrix without an observed question.
- Longer celebrations, one sound per shard, obscuring trails, incessant idle motion or exclusive information carried by sound/color/animation.

## Handoff and validation status

Deliverables are this document and the optional dependency-free geometry helper under `tools/gameplay-study/`. Only those owned paths are changed. The helper's demo yields the 3→7, 3→4 and 5→3 survivor results shown above; it is deliberately narrower than a game simulation. Its numeric floors assume two clears remain and the round has not already ended. It does not model random refill, initial generation, repair, persistence or terminal rules.

Local checks passed for Python syntax, all three demo actions, the position/color transfer fixture and malformed-board rejection. Enumerating all **125 assignments** to the aqua clear's three refill slots preserved a rose component of at least seven in every case. This checks the lesson's geometry across arbitrary fills; it is not a fresh execution of the Swift rules or evidence about the distribution of real generated boards.

Source preparation was completed without human experiment results or native validation; this document supplies a protocol rather than claiming either was run. Gameplay, App, existing tests, CI and project files were untouched by this research pass. No credits were purchased, account settings changed, remote refs updated, blocked publication retried or alternate toolchain installed. Integration/publication was held by a reported approval-check error during that preparation pass, and no publication attempt was made then. That historical status does not describe the current integration state.
