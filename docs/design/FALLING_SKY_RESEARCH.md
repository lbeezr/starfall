# Falling-sky mechanics and progression research

Researched October 16, 2026, Eastern time. This is design research and a proposal, not an implemented level system. Current repository scope excludes progression. Discussing options does not remove that boundary; implementing challenge skies requires an explicit product decision.

## Findings and application

| Evidence | What it supports | Starfall design hypothesis |
| --- | --- | --- |
| Ryan, Rigby and Przybylski (2006), four studies: perceived competence and autonomy were associated with enjoyment and preference for future play. Clear controls helped support these experiences; ease of control alone was insufficient. [Primary paper](https://selfdeterminationtheory.org/SDT/documents/2006_RyanRigbyPrzybylski_MandE.pdf). | A useful account of motivation, not a formula for a specific matching game. | Offer understandable choices and visible consequences. A player should be able to explain why their clear helped. |
| The Threes developers' published correspondence describes iteration on starting conditions, previews, risk/reward and an overly dominant corner strategy. Their account also connects a slow opening with wasted actions. [First-party development record](https://asherv.com/threes/threemails/). | Small rule changes can affect depth and pacing. This is one team's retrospective, not controlled evidence of universal player preferences. | Keep the immediate opening match, compare alternative clearing policies, and test whether a useful preview supports planning while retaining surprise. Avoid solving shallow choices by simply adding obstacles. |
| King's official Candy Crush support describes levels with visible goals such as clearing specified objects or collecting orders, rather than a score label alone. [Official goal/mode explanation](https://candycrush.zendesk.com/hc/en-us/articles/360000754897-Which-game-modes-will-I-find). | A concrete example of objective-based level variation, not proof it will suit Starfall. | Use a few clear objectives based on existing jewels, growth and dark stars. A level should teach a skill or change a decision. |
| The official Tetris site presents level play alongside quick high-score rounds and infinite rounds. [Official site](https://www.tetris.com/). | Authored goals and open-ended survival are different structures; neither is mandatory for all puzzles. | A short challenge path could coexist with the existing survival round, but avoid building multiple new modes now. |
| Tyack and Mekler (2024) critically review how self-determination theory is used in games research and identify theoretical/methodological problems. [Research review](https://arxiv.org/abs/2405.12639). | Broad motivation theory should be applied cautiously rather than treated as a feature checklist. | Validate changes with observed play, alongside deterministic tests. Do not equate stronger bot performance or a progression counter with enjoyment. |

These sources do not establish an ideal session length, level count, success rate, shower speed, or reward schedule for Starfall. Numeric targets below must be tuned with actual play. They do not justify importing monetization, lives, energy, boosters, or compulsory daily play.

## Mechanics to investigate first

1. **Competing useful clears.** Compare mixed-color shower patterns with the current same-color runs. The local strategy sample found multiple groups in only about 10% of match-ready states under one-clear policies. Having two groups is still insufficient if immediately clearing both is always equally good.
2. **Board-shaping consequences.** Make it easy to see how clearing a lower group drops survivors and changes column risk. Test whether people can plan a merge or protect a crowded column.
3. **Growth versus immediate space.** Investigate situations where waiting for a matching arrival can help, but never force long idle periods. Do not add a score multiplier until a meaningful tradeoff is demonstrated.
4. **Fair pressure.** Show crowded columns and explain overflow. Speed can test execution, but cannot substitute for decisions. Preserve pause and manual advance for deliberate play.
5. **Recoverable obstacles.** Dark stars already offer a local subgoal: clear beside one to remove it. Test whether their position creates a solvable problem rather than an unavoidable loss.
6. **Clear goals and completion.** A short objective can supply direction and a satisfying stopping point. It cannot rescue an uninteresting core loop on its own.

## Current structure versus proposed progression

Implemented today: one survival round, no fixed victory target, ending on a blocked incoming star. There is no level number, unlock path, saved campaign progress, personal-best system, or difficulty escalation tied to progress. Pace and dark-star frequency are local player settings. Replay repeats a seed under current new-round rules; old saved rounds retain their generation style.

Recommendation: prototype **six authored challenge skies**, using the existing core before considering a large campaign. Each has a fixed seed, visible objective, readable difficulty, immediate retry and an actual completion state. The existing survival game remains available; a large separate mode-selection system is unnecessary for the experiment.

Illustrative sequence, not final parameters:

| Sky | Purpose | What changes |
| --- | --- | --- |
| First Light | Learn matching and finish a short starlight target | Friendly shower sequence; dark stars off; opening match retained. |
| Growing Stars | Learn how large jewels contribute to clears | A sequence/layout that makes growth useful; a modest starlight goal. |
| Clear the Shadow | Learn dark-star removal | Remove a specified dark star and collect starlight; ample time and a reachable adjacent match. |
| Make Room | Learn gravity and column management | A seeded partly occupied layout with crowded columns and a clear target. |
| Changing Sky | Choose between useful groups | Mixed-color showers and varied heights; starlight target under manageable pressure. |
| Constellation | Combine learned skills | A tested combination of growth, dark stars and column pressure; a clear final goal. |

Not all of these configuration options exist yet. Authored starting layouts, objectives, completion/win precedence, a level list and local progress persistence require implementation and focused tests. Existing save validation assumes current survival accounting, so authored layouts need explicit initial-state accounting, not forged save files.

Levels would change **objectives, initial geometry, shower patterns, dark-star placement/frequency, and occasionally pace**. Change one teaching variable at a time, then combine mastered ideas. Do not increase speed on every level or restore the slow empty-board opening. Pure 'survive N showers' goals can be trivial without clearing, so test that an intended skill is actually needed.

Progress would initially mean completing these six challenges, with local completion marks and unrestricted replay of completed challenges. No XP, upgrades, currencies, economy, power-ups, login, online leaderboard or cosmetic collection is needed. Broader unlocks, medals and personal bests are separate optional decisions, not assumed features.

For accessibility, manual/paused play should remain supported. Completion goals should assess puzzle actions rather than require reflex speed; if a future challenge explicitly evaluates real-time execution, expose that distinction rather than silently changing rules or comparing unlike scores.

## Next decision and experiment

Finish the mixed-color/decision-depth comparison first. Then, if the user chooses challenge progression, build **one objective-driven sky** and test its completion/retry flow before making the other five. Check deterministic replay, initial-board accounting, goal versus overflow precedence, terminal input, local progress migration and VoiceOver goal announcements. Observe whether the player prefers this goal-driven round to survival. No level system has been implemented or approved by this research note alone.
