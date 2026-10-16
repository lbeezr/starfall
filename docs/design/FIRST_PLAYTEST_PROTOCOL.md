# Starfall: first six-person playtest

Prepared 16 October 2026. **Preparation only: no participants recruited, sessions run or results collected.** Based on [GAMEPLAY_RESEARCH.md](GAMEPLAY_RESEARCH.md), [PLAYTEST.md](../PLAYTEST.md) and the inspected current rules/UI at source `60f44a0447f644174613370f25302cd5205a8311`. Keep **70 cleared shards in 18 valid moves** unchanged. Run only an identified, authorized build; use its actual wording rather than proposed copy from the game bible.

## Purpose and setup

Observe whether six first-time players can understand the existing loop, make a meaningful choice and want another round. Check whether an **optional short explanation** helps them predict visible survivor movement on another position. This is a small formative study, not a retention study, accessibility certification or difficulty estimate.

Reserve a flexible **10–15-minute session per person** when completed-round and replay evidence is desired. Begin with five minutes of live play/debrief and an optional two-minute planning probe; allow additional unhurried play rather than forcing an ending. A seven-minute session may establish onboarding and planning observations while leaving replay evidence insufficient. Offer breaks or more time for access needs; never make the player hurry. Record incomplete tasks as not observed. Only the coordinator recruits participants or shares an authorized build. Use anonymous IDs and handwritten/local notes; no recording, account, analytics or paid service is needed.

Before each session, record build/source, device/OS, date and starting board/seed **if already available**. Do not add a seed selector or expose hidden RNG. Ask what text size, motion, sound or input/screen-reader setup the person prefers; record preferences without asking for a diagnosis. Use their usual settings. With six people, accessibility observations are specific to the people and setups actually represented.

Moderator opening: **“We’re trying out the game, not testing you. You can pause or stop whenever you want. Please say what you are noticing when it feels comfortable; silence is fine.”**

Moderator rule reference, not an opening explanation: 7×7; five kinds; tap whole matching orthogonal groups of 3+; each clear costs one move and each shard scores one. Invalid taps are free. Survivors fall within columns, refill is unknown and new groups do not clear automatically. Win at 70, including on the last move; otherwise zero moves loses. A dead live board gets a free replacement of three bottom-row cells, not a full shuffle. Do not promise every round is winnable.

## Five-minute live session

| Phase | Neutral prompts | Observe and record |
| --- | --- | --- |
| First impression, about 30 seconds | “What do you think you can do here? What are you trying to achieve?” | Unaided interpretation of matching, orthogonal connection, 70 and 18. Can they locate Play, instructions and counters? Accept “jewels,” “shards” or “starlight” when the meaning is correct; current copy mixes these terms. |
| Uncoached play, about three minutes | “Please play in whatever way makes sense to you.” At one natural choice: “What are you considering?” | First valid clear, invalid/diagonal taps, whether a component is understood as one action, clear/settle readability, and the player's stated reason **before** seeing its result. Record whether multiple independent legal groups existed; several cells in one group are one option. Do not suggest a best move. |
| Natural recovery or ending, whenever it happens | Recovery: “What changed? What happened to your moves?” Ending: “What does this result mean? What would you do next?” | Whether replacement and its free cost are understood, or whether final score/outcome/New game are understood. Never manufacture a recovery, loss or final move. Mark events not reached as not observed. |
| Debrief and free choice, by five minutes | “What felt satisfying? What felt confusing or frustrating?” Then: “Would you prefer to continue, start another round, or stop?” Finally: “What led to that choice?” | Record the answer and actual action separately. An unfinished first round gives evidence about continuing, not actual replay after an ending. Record lack of time separately from lack of interest. Ask these questions **before** explaining planning. |

If help is requested, first ask **“What are you trying to do?”** Then provide only the necessary factual rule and write down the exact help. Separate unaided understanding from understanding after assistance. Do not treat an access barrier as a strategy mistake.

During onboarding/play, note whether all five kinds are distinguishable by shape as well as color; text/counters remain readable; intended cells can be activated; settings and return to play are understandable; and sound/effects off preserve essential information. For a person using VoiceOver, observe actual traversal, kind/position/group-size announcements, activation, feedback and focus after a clear. The UI's narrated coordinates run top-to-bottom from row 1; core row zero is the bottom. Use player-facing coordinates in discussion. Do not infer VoiceOver usability from labels existing in source or an automated audit.

After open-ended comments, ask for **clear satisfaction, perceived control and calmness**, each 1–5 (1 low, 5 high), and one moment behind each rating. These are informal questions, not validated psychological scales.

## Optional two-minute survivor-planning probe

Use a readable paper/static board, not a new app feature. Explain the letter legend and coordinates; provide a large-print, spoken or other usable representation when needed. If spatial access remains inadequate, mark the probe unavailable and report that barrier instead of scoring a failure.

Board A, shown top-to-bottom, columns left-to-right. R = rose circle; A = aqua diamond; T = amber triangle; V = violet hexagon; M = mint square. This is a **synthetic lesson board**, not a demonstrated reachable game state.

```text
          column
          1 2 3 4 5 6 7
row 1     R T M M M M M
row 2     R V R A R A R
row 3     A T A T V M R
row 4     A R R A T V M
row 5     A R M R A T V
row 6     R V V M R A T
row 7     R T T V M R A
```

1. Ask: **“Imagine one move remains and you need five more. What would you choose, and why?”** Then: **“Now imagine two moves remain and you need ten more. What could you guarantee from the pieces already here? Which parts are unknown?”** Record the chosen group and predicted survivor positions before offering help. This prompted paper task is separate from spontaneous live-play strategy.
2. Offer everyone the same choice: **“Would you like a short explanation of how pieces settle, or would you prefer to try another example on your own?”** If accepted, read only: **“Survivors fall straight down in their own columns and can join matching neighbors. New refill pieces are unknown. A new group needs another tap and another move.”** Record acceptance/decline and any extra help. Do not reveal the answer before the second probe.
3. Show Board B below. It mirrors A left/right and relabels `R→M, A→V, T→A, V→R, M→T`. Ask the same two-moves/ten-needed question without further coaching. Record the prediction and reason. The static card does not change the app.

```text
          column
          1 2 3 4 5 6 7
row 1     T T T T T A M
row 2     M V M V M R M
row 3     M T R A V A V
row 4     T R A V M M V
row 5     R A V M T M V
row 6     A V M T R R M
row 7     V M T R A A M
```

Moderator answer key: on A, top-row mint clears five immediately. Clearing the aqua triple at column 1, rows 3–5, joins **at least seven rose** for a second clear: at least ten total in two moves. On B, the violet triple at column 7 joins at least seven mint. Unknown refill may create other successes too; do not call a different choice a guaranteed loss. Planning success requires identifying the joining survivors, allowing a second move and distinguishing them from unknown refill. Merely choosing a triple is insufficient.

Report each person's baseline→transfer change, separated by explanation accepted/declined and assistance. An improvement is a useful teaching signal; self-selection, repeated questioning and the closely related boards prevent a causal claim that explanation improved skill. This tests narrow position/color transfer, not broad mastery or future-RNG prediction.

## Provisional decision thresholds

These are **design hypotheses for choosing the next investigation**, not release gates or research-established constants. Show counts and quotations, including disagreements.

| Measure | Provisional useful signal | If absent |
| --- | --- | --- |
| Comprehension | At least 5/6 explain 3+, orthogonal connection, shard-count goal and move limit after onboarding; report unaided and assisted counts separately. | Address the specific wording/access issue before tuning. Timing is descriptive, not a pass/fail condition. |
| Meaningful choice | At least 4/6 explain an observed choice using current group size or a correct visible-survivor consequence. | Separate forced-choice boards, unclear feedback and unlearned strategy. Do not assume a need for more mechanics. |
| Planning transfer | At least 4/6 pass the transfer probe with no extra coaching. A provisional teaching signal is at least two baseline-fail→transfer-pass changes among at least three initially unsuccessful people who accept the explanation; also report changes among decliners. | Do not claim a demonstrated planning-learning curve or causal teaching effect. Fewer than three eligible explanation acceptors leaves teaching evidence insufficient; unavailable probes leave the six-person threshold unevaluated. |
| Recovery comprehension | At least 80% of live observers understand that it costs no extra move; report exact n/N, with at least three observers before using this signal. | Record insufficient exposure or clarify the actual replacement. Repeated full-shuffle/extra-cost interpretations merit review. |
| Experience | Median satisfaction, control and calmness each at least 4/5; no repeated presentation-related pressure complaint. | Propose one change tied to an observed problem. These ratings do not establish clinical relaxation. |
| Replay | At least half of participants who finish a round and have time independently start another, with at least four eligible observers. Report stated interest and continuing unfinished rounds separately. | Otherwise mark replay evidence insufficient or weak, stop feature expansion and investigate the stated reasons. No retention claim follows. |

Keep 70/18 unchanged after this small study. Wins/losses and deficits are descriptive; unfinished rounds are not losses. If access and comprehension are clear but several people find endings discouraging, propose a separate complete-round observation or bounded tuning study for review. Preserve the option that enjoyable, simple large-group play is sufficient.

## Blank results sheet

All rows below are placeholders, not completed sessions. Codes: U = unaided; A = after assistance; N = not understood; NO = not observed/unavailable. Planning: pass/fail/NO using the answer key. Ratings: satisfaction/control/calmness.

Build/source: __________ Device/OS: __________ Date: __________ Moderator: __________

| ID | Access setup / help given | Rule + goal U/A/N | Choice reason / options present | Recovery understood n/a | Ending / score / moves | Replay eligible? Action + reason | Planning A→B; explanation accepted? | Ratings |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | | | | | | | | |
| P2 | | | | | | | | |
| P3 | | | | | | | | |
| P4 | | | | | | | | |
| P5 | | | | | | | | |
| P6 | | | | | | | | |

Per-person notes: first valid clear/time __________; invalid/diagonal taps __________; shapes/text/touch/narration/focus __________; exact prediction and unknown-refill explanation __________; most satisfying moment __________; confusion/frustration and exact quote __________; extra time, assistance or missing opportunities __________.

Aggregate: unaided comprehension __/6; assisted comprehension __/6; reasoned choices __/6; transfer passes __/__; initial-fail→transfer-pass __/__; explanation accepted __/__; recovery understood __/__ live observers; replay starts __/__ eligible; stated replay interest __/__ asked; median ratings __/__/__.

Repeated issue and supporting IDs/quotes: __________

One bounded next proposal, or evidence still needed: __________

**Evidence boundary:** human observations above must be collected before filling this sheet. Existing deterministic simulations, rule tests, the geometry helper and automated accessibility checks establish different facts; they do not fill any participant field or establish comprehension, satisfaction, accessibility usability or replay. Preparation makes no code change, contacts nobody and authorizes no publication, install, account operation or spending. The prior gameplay-research patch remains unchanged.
