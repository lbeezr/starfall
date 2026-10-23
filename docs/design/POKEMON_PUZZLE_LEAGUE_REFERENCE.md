# Pokémon Puzzle League is the primary gameplay reference

**Status:** User-selected design reference; current first-pair trial development-verified and installed; human balance review remains open, later adaptations proposed · **Owner:** Current implementer · **Updated:** October 22, 2026

The user identifies **Pokémon Puzzle League for Nintendo 64** as Starfall's core inspiration. When mechanics, progression, difficulty, rewards or multiplayer direction are uncertain, inspect what that game does, explain why it may work, and propose a deliberate adaptation for Starfall. Treat its design as a starting point to develop further.

The desired experience includes arcade energy, impressive scores, expressive celebrations, skillful play and the social feeling of nearby handhelds or couch play. Lantern Landing should welcome new players while the wider game offers increasing mastery. [The current gameplay plan](../STORY_MODE_GAMEPLAY_PLAN.md) translates this direction into a bounded first comparison.

The [competitive pacing research](PUZZLE_PACING_RESEARCH.md) follows the user's sparse-board feedback. It separates verified mechanics and derived rates from unvalidated tuning, accounts for Starfall's single-cell pieces, and records the requested approximately half-full opening presented as a rapid cascade. Automatic patterns and causal phases are implemented for new Lantern/Ribbon visits. The [current revision-4 trial](../evidence/four-star-lines-2026-10-22/README.md) changes straight runs to four or more matching stars while retaining squares, crosses and other tuning; saved revision-3 rounds retain seven-star lines. Development verification and installation do not establish human preference. The [roadmap](../ROADMAP.md) sequences the next adaptations.

## Verified reference behavior

Primary sources inspected October 20:

- [Nintendo's original game description](https://www.nintendo.com/en-gb/Games/Nintendo-64/Pokemon-Puzzle-League-269657.html) associates larger clears with more points, combos/Skill Chains with battle attacks, and reaching the top with defeat.
- [Nintendo-authored instruction manual, archived scan](https://www.emulation64.net/pdf/N64%20-%20Pokemon%20Puzzle%20League%20%28Anglais%29.pdf): PDF pages 10–13 describe horizontal exchanges, straight matches, falling follow-up chains, manual stack raising and temporary stops earned by combos/chains.
- Manual PDF pages 19 and 22–25 distinguish trainer/difficulty progression, Marathon survival, Time Zone scoring before a deadline, Spa Service clearing above a line, and limited-move University puzzles. Spa Service advances when its objective is met.

Page numbers are one-based PDF pages. The image-only manual was rendered locally and visually inspected; no game session was played. Exact score tables, average clear times, campaign duration and detailed frame timing were not established. These sources do not establish a three-star rating system or a minimum-duration rule.

## Apply the reference through testable decisions

The following are Starfall design inferences and proposals, not claims about Nintendo's implementation.

| Question | Starfall direction to evaluate |
| --- | --- |
| Why attempt a more demanding move? | Make a better decision change the situation: a valuable follow-up, more usable space, earned progress or bounded relief. Investigate a real reward for causal relays rather than relying on their name and animation alone. |
| How should scoring feel? | Test 1,000-point base units and larger exact clear awards with pronounced audiovisual punctuation. Separately test a bounded earned bonus; adding zeros alone does not create strategic value or length. |
| What should increase difficulty? | Develop arrangements, competing choices and the need to plan ahead before relying on faster supply. Keep an understandable relation between danger, response and recovery. |
| How should levels end? | Use a clear objective and resolve a successful action promptly. A score-attack clock has a different purpose from shower timing. An enforced minimum duration would undermine the benefit of skilled play. |
| How should progression last? | Author more distinct challenges and variations. Treat twelve places as possible chapters with several rounds if the desired journey is several hours. Keep that content expansion explicit. |
| How should teaching work? | Connect practice to situations where the technique becomes useful, then test transfer to a different arrangement. Support both a welcoming first clear and deeper optional mastery. |
| What should multiplayer feel like? | Nearby players should understand their shared stakes and how their actions affect each other. Develop local versus and cooperative restoration as separate experiences. |

## Adapt deliberately to Starfall

Starfall has falling supply, four-direction exchanges and growth. Open Sky and historical challenge rules also use connected-group taps and exact traced sets; new Lantern/Ribbon visits resolve automatic patterns and survivor-created phases. Its actions are not identical to Puzzle League's. Preserve each mode's actual contract while testing the important difference.

Future changes to resolution, chain windows, attacks, board shape or competitive rules need an explicit versioned task. Identify the useful player decision, its consequences and the smallest comparison that could establish an improvement. Preserve retained definitions and same-round replay.

Current authored first-pair rounds already separate physical light from earned size/phase bonuses. Preserve that accounting in future trials. Equivalent committed results within one rule version receive identical awards through every supported input method. A bonus cannot be farmed through repeated gestures, restoration of a save or replayed animation. Check that splitting a clear does not exploit a repeatedly granted size bonus. Calibrate content targets after selecting the scoring rule.

For presentation, use Starfall's own cast, art, music and restoration identity. Build intensity through anticipation, impact, collection and resolution, retaining legible survivors and responsive input. Quiet presentation should carry the same information and earned result.

Three optional restoration stars remain a Starfall proposal, not something attributed to this reference. They should support the main pleasure of play rather than become its only reason to attempt a thoughtful move.

## Future local play

The user explicitly wants nearby iPhones/iPads on the same local network to play **against each other** or **together against a level**, evoking linked handhelds and couch multiplayer.

- **Versus:** Start design from separate boards and readable interaction between players. Investigate earned pressure and recovery without making a weak player's situation hopeless.
- **Cooperation:** Start design from shared restoration and meaningful mutual help. Compare linked personal boards with a shared board before choosing; both players need understandable contributions.

The intended connection is a local host/join session without accounts, internet matchmaking or a backend. These are future feature directions; this documentation adds no networking. Before implementation, specify session ownership, rejoin/interruptions and what completion may save on each device. Reuse deterministic rules and committed outcomes; do not build an unused networking abstraction in advance.

## Use this reference in future proposals

For an uncertain decision, record: the question; verified reference behavior and source; Starfall's relevant difference; proposed adaptation; and observable acceptance. Inspect actual footage or play when timing and feel matter, rather than inferring them from a manual.

The first follow-up is the [score, spectacle and Lantern/Ribbon implementation](../evidence/story-first-pair-2026-10-20/README.md), development-verified with human balance review open. Later versus/co-op work gets its own bounded feature plan. This reference alone does not establish implemented features, validated enjoyment or authorization to ship unfinished gameplay.
