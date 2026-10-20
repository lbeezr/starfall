# Give the player something worth doing between arrivals

**Status:** Research complete; automatic recipe resolution selected as the design direction, implementation pending · **Owner:** Current implementer · **Updated:** October 20, 2026

The user reports that the delivered Lantern/Ribbon stages can be kept nearly empty with occasional taps. Competitive research supports changing available work and supply composition before selecting another fixed shower interval. The earlier suggestions of roughly two-second showers and particular opening counts were tuning guesses, not findings from comparable games.

**Direction:** Keep single-cell stars. The user selects automatic recipe popping and resulting cascades as the desired payoff for arranging the board, identifying this as a central pleasure of Pokémon Puzzle League. They accept an opening around half full, presented as a rapid cascade of stars rather than pieces already sitting in place. Familiar matching conventions are welcome; develop Starfall's identity through its decisions, world and presentation.

**Next action:** Define and compare automatic recipe resolution first, then calibrate the fuller opening, supply and cadence for that loop. Exact matching patterns and combo awards remain to be tested. No replacement interval or minimum stage duration is established by this research.

## What the references actually establish

Sources were inspected October 20, 2026. Edition and mode matter; the following facts do not imply identical timing across a franchise.

| Reference | Documented behavior | Starfall inference |
| --- | --- | --- |
| **Pokémon Puzzle League, N64** | Individual panels are exchanged to form straight matches. Rows rise automatically and accelerate; L/R raises them manually. Combos/chains earn temporary stops. The Marathon illustration at 0:00 already has several mixed rows. [Nintendo-authored manual, archived scan](https://www.emulation64.net/pdf/N64%20-%20Pokemon%20Puzzle%20League%20%28Anglais%29.pdf), PDF pp. 10–13, 22. | This is the closest structural reference. Available arrangements, manual acceleration and earned relief work together. The illustration supports a populated opening, not a universal exact starting count. |
| **Panel de Pon, Nintendo's VC guide and GBA mode guide** | Nintendo recommends manually raising when useful matches are unavailable. Clears stop rising briefly; combinations/chains stop it longer. GBA Stage Clear increases both initial panel count and rise speed between stages. [VC strategy](https://www.nintendo.co.jp/wii/vc/vc_pa/vc_pa_07.html), [GBA modes](https://www.nintendo.co.jp/n08/bzpj/panel_mode/index.html). | Starting workload, replenishment and recovery are separate controls. A gentle stage can provide substantial material with ample thinking time. |
| **Dr. Mario, NES** | Virus Level sets initial virus count; Low/Med/Hi separately sets capsule speed. The player can accelerate a capsule. Clearing all viruses completes the stage. [Nintendo manual](https://www.nintendo.co.jp/clv/manuals/en/pdf/CLV-P-NAAXE_en.pdf), PDF pp. 2–3, 6. | Density need not imply urgency. However, viruses require capsule placement; adding immediately tappable stars would not reproduce that workload. |
| **Puyo Puyo 2, 3DS** | Players move, rotate and accelerate falling pairs. Four matching cells clear. Difficulty, attack offsetting and the delay before garbage quantities increase are separate settings. [SEGA instructions](https://games.sega.com/3dclassics/puyo2.html). | Time between placements contains decisions. Starfall's predetermined arrival columns cannot borrow that interval without accounting for the work available on its board. |
| **Puyo Puyo Champions, 2020 update** | Speed options are ×1.0, ×0.7 and ×0.5. The adjustment excludes start/end presentation, garbage falling and Quick Drop. [SEGA update](https://www.sega.jp/topics/detail/200824_1/). | Decision pace and presentation timing need not be the same control. These multipliers reveal no absolute seconds-per-piece value. |

For mode structure, Tetris Effect's **publisher-hosted, community-authored** guide describes 150-line Marathon with increasing speed, 40-line Sprint, three-minute Ultra and a Chill Marathon without fatal top-outs. This is useful supplementary evidence, not a developer timing specification. Our inference is to choose a stage objective separately from urgency; a countdown belongs to an explicitly timed challenge. [Guide](https://www.tetriseffect.game/beginners-community-guide/).

## Single-cell stars change the comparison

Pokémon Puzzle League also uses one-cell panels. Tetris's four-cell tetromino and Puyo's pair arrive as controllable units: four cells do not mean four independent decisions. Piece count alone is therefore a poor pacing measure.

Starfall's important combination is single-cell arrivals **with predetermined columns**, connected-group clearing, growth, and many same-color showers already arranged for an ordinary tap. Growth can store two light units in one occupied cell. Thus incoming light, occupied cells, score and player work can diverge sharply. Puzzle League instead asks the player to arrange straight matches through horizontal exchanges; its timing cannot be copied without considering Starfall's different freedoms and input method.

Compare supply in cells/light units, occupied board fraction, work required to create a clear, useful alternative actions, and time without anything worthwhile to do. More taps alone would not demonstrate more interesting choices.

## Other successful single-cell games clarify the input choice

| Reference | Verified behavior | What to learn |
| --- | --- | --- |
| **Bejeweled 3** | Swap gems into matches of three or more. Its manual describes cascades, untimed Classic, endless Zen, timed Lightning and objective-based Quest. [PopCap-authored Xbox manual, archived scan](https://www.videogamemanual.com/xbox360/Bejeweled%203.pdf), printed pp. 5–8. | Familiar matching can support different kinds of pressure and objectives. Presentation and challenge structure can develop around a readable core action. |
| **Candy Crush Saga** | A swap forming a horizontal/vertical line of three or more makes those candies disappear; replacement candies fall into the spaces. Ordinary matches need no confirmation tap. Levels have a move budget. [King's controls guide](https://candycrush.zendesk.com/hc/en-us/articles/360000750278-Controls-how-to-switch-and-match-candies). | Arranging the match is the decision; the game supplies its immediate consequence. Its refill model differs from Starfall's accumulating sky and should not be imported accidentally. |
| **Toon Blast / Toy Blast** | Players tap groups of two or more same-color cubes within a move budget. Larger groups create special items; Toon Blast previews the earned item before the group is consumed. [Toon rules](https://peakgames.helpshift.com/hc/en/4-toon-blast/faq/5-how-to-play/), [reward preview](https://peakgames.helpshift.com/hc/en/4-toon-blast/faq/7-what-are-the-special-items/), [Toy rules](https://peakgames.helpshift.com/hc/en/5-toy-blast/faq/98-how-to-play/). | Manual activation has successful precedents. It earns its place when choosing which group to spend, and when, changes the outcome. It does not establish that Starfall's extra clear action is useful. |

These are established examples, not evidence that one input convention causes success. EA reported over **50 million Bejeweled franchise units sold in 2011**; King reported over **five billion Candy Crush franchise downloads in 2023**; Zynga reported over **12 million combined average daily active users for Toon Blast and Toy Blast in 2020**. These are dated publisher-reported franchise/game metrics, not current figures or unique-person counts across games. [EA](https://news.ea.com/press-releases/press-releases-details/2011/EA-to-Acquire-PopCap-Games/default.aspx), [King](https://www.king.com/corporate-and-media/posts/press-releases/celebrating-20-years-of-gaming-excellence-kings-milestone-journey/), [Zynga](https://www.zynga.com/blog/Zynga-Enters-Into-Agreement-to-Acquire-Istanbul-based-Peak-Creator-of-Top-Charting-Mobile-Franchises-Toon-Blast-and-Toy-Blast).

Our design judgment: use the familiar arrange-and-resolve loop because it supports the user's desired payoff. Distinctiveness should come from consequential arrangements, the accumulating sky, restoration progression and audiovisual character. Preserve growth and selective tracing where they offer understandable choices; do not retain an extra confirmation solely to look different.

## Automatic recipes and causal combos are the selected direction

The user explicitly favors **arrange → recipe pops → survivors fall → another recipe pops**, with the resulting cascade building points and spectacle. The missing feature is automatic follow-through. A tap or trace can also initiate a genuine cascade if its resulting fall creates another recipe; separate taps made quickly are not evidence of such a chain.

The smallest candidate uses the existing exact four-star square and five-star cross. Detect complete recipes after a committed swap, arrival batch, or clear-and-settle; resolve them and repeat on the resulting board. This candidate's pattern set is a recommendation, not yet the final adopted matching vocabulary. Test whether it is readable and frequent enough before deciding whether a standard three-in-line pattern belongs.

Do **not** equate this with automatically executing every existing tap. Today's tap rule clears a whole connected group worth three light, including a grown star plus one small star. Automatic consumption of all such groups would erase many growth and five-star trace setups. Recipe-only resolution preserves more of those choices, though it removes the ability to bank a completed square/cross and requires a clear explanation of which other selections remain manual.

Combo depth should represent successive clear phases caused by settling. Simultaneous recipes belong to one phase; overlapping ingredients score once. The exact bonus curve remains unvalidated. A new unrelated move or shower must not inherit an old combo merely because it occurs quickly. Pausing or quiet animation must not change the committed award.

This changes existing decisions: Lantern currently starts with a square inside its five-aqua group. Auto-popping that square spends four stars and changes its intended banking tradeoff. Author an opening that settles into useful incomplete arrangements instead of immediately dismantling itself. Resolve growth, overlapping recipes, overflow/win ordering and interrupted presentation explicitly before implementation.

Core must own deterministic cascade outcomes and individual award phases, with versioned save/replay behavior. Animations present those results. This research does not replace current rules, change a saved round, or implement a scoring multiplier.

## A numerical reference, with its limits

**Panel Attack is an independent open-source homage, not Nintendo's engine.** Its source makes a defensible numerical example possible. At pinned commit `7462970780ce79506c8a7214fcd8abdc6ce7a2b5`, the rise table and six-column stack imply:

| Speed-table index | Nominal seconds per full row | Nominal incoming panels/minute |
| ---: | ---: | ---: |
| 1 | 15.70 | 22.93 |
| 10 | 8.58 | 41.94 |
| 20 | 4.27 | 84.38 |

Derivation: raw table values 942/515/256 are divided by 16 for each one-pixel rise; sixteen pixels produce a row; simulation frames last 1/60 second. Therefore seconds/row = raw value/60, and panels/minute = 6 × 60 ÷ seconds/row. Fractional timer remainder is preserved. [Constants](https://github.com/panel-attack/panel-game/blob/7462970780ce79506c8a7214fcd8abdc6ce7a2b5/common/engine/consts.lua), [stack implementation](https://github.com/panel-attack/panel-game/blob/7462970780ce79506c8a7214fcd8abdc6ce7a2b5/common/engine/Stack.lua).

These are derived rates at fixed indices with uninterrupted passive rise. They exclude earned stops, rise locks, countdown, manual raising, speed changes and top-out. They are neither measured session rates nor Nintendo constants. Index 1 is not the slowest entry; index 2 is slightly slower.

The generator also rejects immediate vertical repetition and horizontal triples. Its input composition matters alongside its timer. [Generator](https://github.com/panel-attack/panel-game/blob/7462970780ce79506c8a7214fcd8abdc6ce7a2b5/common/engine/PanelGenerator.lua).

The practical finding is that a low passive rate can coexist with arrangements to work on. This does not establish that Starfall's current rate is sufficient.

## What our baseline shows

Source inspected: `53d816e996cd3ed9926bfcbb401d29712d6aa1d9`, clean before this documentation batch. In [revision 1](../../Sources/StarfallCore/StoryChallenge.swift), Lantern supplies 30 light units per 12 six-second showers: **25/minute**. Ribbon supplies 46 per 18 four-second showers: **38.33/minute**. Both repeat their structural motif after 72 nominal seconds, with later color rotation and mirroring. Each shower contains one color and one to three arrivals.

On an empty board, eight of Lantern's twelve showers immediately make a legal group; the remaining four form two self-completing pairs of showers. Ribbon similarly has ten immediate groups and four paired setups. Actual surviving stars can alter those results.

The [existing deterministic model](../evidence/story-first-pair-2026-10-20/README.md#deterministic-calibration) is a warning about depth: first, last, largest and smallest legal tap policies all finish Lantern with identical totals and maximum column height two; the same four policies finish Ribbon with identical totals and maximum height three. These are model outcomes, not human clear times or proof that every strategy is equivalent.

Our supply rate is already near some Panel Attack entries, but units, board sizes, growth and required actions differ. The more specific failure hypothesis is **too much supplied material is already solved, leaving too little persistent work**. Faster delivery may help, but could merely repeat the same shallow action more often.

## The revised opening and comparison

The user's accepted direction is approximately half-full on entry: roughly 24–25 occupied cells on our 49-cell board is a useful candidate, **not a competitor-derived optimum**. Show that authored arrangement arriving through a rapid, overlapping cascade. It should feel like an opening shower, without waiting through ordinary shower intervals for each small batch.

Lantern should reveal obvious early clears, straightforward growth opportunities and room to experiment. Ribbon can use a similar density while making exchanges, selective clears and preserving a follow-up materially useful. Mixed colors alone do not guarantee those choices; demonstrate the consequences of alternative actions on the resulting board.

The cascade is presentation of an authored initial state. It must not award score or advance shower count. Begin normal scheduled pressure after the entrance, use the existing lifecycle/input boundaries, and give reduced-motion players the same arrangement promptly. Resume must retain the saved board; replay must not duplicate opening stars. This is proposed implementation behavior, not verified code.

Run a bounded comparison in order:

0. **Resolution:** Compare current explicit activation with automatic recipes on authored positions, keeping supply and score rules fixed. Verify that intentional setup creates predictable follow-ups and that tracing/growth retain a readable role. Select the matching vocabulary before calibrating its cadence.
1. **Opening:** Compare the current opening with the fuller authored one, keeping recurring supply, cadence and scores fixed.
2. **Supply:** Keep the selected opening and change composition at the same incoming-light budget and cadence. Introduce useful incomplete arrangements alongside readable clears; inspect how choices survive successive showers.
3. **Cadence:** Once there is useful work, vary the interval using measured recognition, arrangement and recovery times. Existing manual advancement should serve intentional acceleration; repeated use just to escape emptiness is a warning.
4. **Length:** Revisit score targets after the active loop works. Keep theatrical awards. Derive stage length from meaningful play rather than enforcing a minimum duration.

Record occupancy and tallest column over time, immediately clearable supply, useful setups, actions and their consequences, unwanted waiting, recovery after a mistake, manual advancement, and completion duration. Distinguish thinking from inactivity, and presentation/input holds from insufficient supply.

Adopt a candidate only if human comparison shows less unwanted waiting, understandable choices with different consequences, and recoverable mistakes in Lantern. Automated policies should expose meaningful differences, not choose enjoyment for us. Record failing cases and revise or remove the candidate before extending it to later locations. Any rule/generation revision must retain the existing save/replay contract.

## Evidence boundary

This is web/manual research, source inspection and arithmetic. No commercial game was timed or played for this study, and no new Starfall balance variant was implemented or tested. Exact Nintendo frame tables, a validated Starfall cadence, human stage-duration targets, automatic-resolution balance, physical cascade comfort and accessibility acceptance remain unestablished. The next comparison belongs to the [gameplay plan](../STORY_MODE_GAMEPLAY_PLAN.md) and [experiment register](../EXPERIMENTS.md).
