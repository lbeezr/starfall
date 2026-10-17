# Learning from Mahjong solitaire

Research checked October 16, 2026, Eastern time. The comparison here concerns single-player tile-removal Mahjong solitaire, not four-player Mahjong. Sources describe particular products; they do not establish a universal generation algorithm or difficulty curve.

## What the official sources establish

- [MobilityWare: What are Levels? What is XP?](https://mobilityware.helpshift.com/hc/en/37-mahjong/faq/3037-what-are-levels-what-is-xp/?s=gameplay-settings) explicitly says winning games earns XP/levels and that those levels do not affect game difficulty. Thus an increasing player level need not represent harder boards.
- [MobilityWare: How do I earn new boards?](https://mobilityware.helpshift.com/hc/en/37-mahjong/faq/2429-how-do-i-earn-new-boards/?s=gameplay-settings) says wins level the player and certain level intervals add layouts to the available board pool. This is content availability rather than evidence of a monotonic difficulty ramp.
- [MobilityWare: How do I play Mahjong?](https://mobilityware.helpshift.com/hc/en/37-mahjong/faq/2428-how-do-i-play-mahjong/?s=gameplay-settings) describes matching exposed pairs to uncover other tiles. Removing a pair changes which future actions are available. That spatial dependency is relevant to Starfall's gravity/column management.
- [Mahjong Club's official site](https://www.mahjongclubgame.com/) advertises a large mobile level collection, varied board layouts, ratings and weekly puzzles. This demonstrates a continuing supply of compact puzzles, not mathematical infinity or proof that every next puzzle is harder. The source does not establish how its boards are generated or validated.

## What to borrow

Keep a familiar interaction while changing the puzzle's configuration. Supply a clear finish and a straightforward next challenge. Let a player understand how a move opens possibilities or prevents a blockage. An easy round after a demanding one is a design option worth testing; it is not a measured difficulty pattern established for these products by the sources above.

Separate three concepts in Starfall:

1. **Challenge identity:** a fixed seed, goal and configuration the player can learn and replay.
2. **Actual challenge:** the availability of useful moves, dangerous columns, dark-star dependencies, shower composition and pace. Measure and observe these rather than infer them from an index.
3. **Progress presentation:** completed challenges and the next available challenge, if a campaign is later approved. A level number alone does not change the rules.

Do not copy XP/title ladders, shuffles, streaks, monetization or weekly-content services as part of this tranche. They are unnecessary to test the core experience and are outside current scope.

## Current tranche and later extension

First Light is a single optional challenge: 18 starlight, seed 42, steady showers, no dark stars, with pause/manual advance preserved. Its target is provisional and meant to produce an observable completion/retry flow. The core tests verify that a deterministic clearing policy can complete this specific challenge, not that every possible decision wins or that players will enjoy it.

If this feels better than survival, author a handful of distinct skies. After those work, a future local generator could combine curated templates and deterministic seeds into more challenges. Require a known solution path or bounded solver evidence for authored goal configurations, range-check pressure and waiting, detect duplicates, and use human sampling. Seeds alone do not prove solvability, fun, uniqueness or rising difficulty. Do not label this hypothetical generator implemented or promise infinite handcrafted levels.
