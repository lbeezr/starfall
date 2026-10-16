# Automatic starfall prototype

This Debug experiment starts with an empty 7×7 board. The sky keeps filling it while the player clears matching groups. It follows the user's 16 October 2026 decision to try continuous pressure after the initial turn-based prototype.

## Play

Choose **Try the falling sky** in the Debug menu, or launch with `--starfalls`. Tap **Start sky** once. A shower arrives every four seconds, independently of clears. Showers contain 1, 2, 3 or 5 stars, weighted 1:2:3:1. Colors are random. Columns visit all seven in a shuffled bag before repeating, spreading early pressure across the field.

The preview shows each incoming star's shape/color, including dark stars, in arrival order. Landing columns stay hidden: there are no column headers, forecast outlines or destination labels in accessibility. Most of each four-second interval remains available for clearing; a five-star animation lasts about 1.5 seconds. The forecast changes after the arriving batch settles. The countdown is isolated from the board's observation updates.

- A star matching the small jewel on top grows it to value two, occupying the same cell.
- Otherwise, the star stacks as a small jewel worth one. Grown jewels cannot grow again.
- A dark star occupies one cell and stops the jewels directly above, below, left and right from growing. Existing grown jewels keep their size and value. Shaded jewels can still join matches.
- Tap an orthogonal matching group worth at least three to collect its combined value. A large jewel beside one small match can clear. Two small jewels or a lone large jewel cannot.
- A valid clear also dissolves every dark star touching that group. Dark stars do not join color matches, award starlight, or trigger a chain through other dark stars. Their influence follows them when gravity moves them.
- Surviving jewels settle downward. Clearing neither changes the upcoming stars nor resets their deadline. Invalid taps leave the rules and deadline unchanged.
- If an arrival cannot stack or grow its column's top jewel, the round ends at that star. Earlier arrivals remain and later ones do not happen. A full column can still absorb a matching growth unless a neighboring dark star blocks it.

The first dark star arrives in shower six, then one every four to six showers, determined by the seed. A shower contains at most one dark star; it replaces one regular arrival without increasing the batch size.

The strategy is to make room across the board, preserve opportunities for growth, and decide whether an adjacent clear is worth using now to remove a dark star. There is no win target or move budget in the experiment; collect starlight and keep the sky open. The original 70-in-18 game retains its rules.

## Pace and lifecycle

**Pause sky** is always available during play, including mid-animation. Pausing settles any already committed action and freezes the remaining interval. Settings and backgrounding also freeze it. Returning never catches up missed showers. Resume preserves the remaining interval, with at least half a second of grace. Restoring a saved game, Replay and New sky always start paused.

The scheduler has one cancellable monotonic deadline. If it expires during a clear, one due shower waits for that presentation to finish, then takes priority over another clear. There is no backlog or repeating timer. Old timer and animation callbacks cannot affect a restarted or suspended game. Every committed event is saved before its animation begins.

Seed 5 is the initial sky. Replay restores its empty board and exact future sequence. New sky chooses a different random seed. Save key `starfall.accumulation.v3` separates the dark-star rules from earlier experimental saves and the original game's saved round. Earlier experimental rounds start fresh; the original save is untouched.

## Presentation and access

Stars use overlapping, staggered flights with colored tapered trails, white cores and soft landing rings. Growth uses the existing jewel material at a larger size, with no number badge. Dark stars have a dark center and violet corona; affected jewels dim slightly and gain a thin violet ring. Effects are bounded by the five-star batch. Calm effects, system Reduce Motion and VoiceOver suppress travel and landing effects.

Every cell remains a native button with its shape/color, size, position and connected starlight value. Shaded jewels announce that a dark star blocks their growth, and the clear hint explains when a group will remove dark stars. A Matching groups rotor lists legal clears. Forecast stars expose shape/color or “Dark star,” without revealing destinations. Settings hides the underlying board from accessibility navigation. Input gates during committed animations; Pause remains available.

The rule model remains deterministic and UI-independent in `Sources/StarfallCore`. The scheduler, persistence and SpriteKit presentation have explicit boundaries. Access remains Debug-only. No external SDKs, networking, tracking or monetization were added.

## Tuning questions

Four seconds, the batch-size weights, dark-star frequency and growth cap of two are initial choices, not established balance. Playtesting should determine whether hidden destinations feel exciting or arbitrary, whether dark stars change clearing decisions enough, and whether the shaded-jewel treatment is clear. Swaps and other special tiles remain outside this iteration.

Validation and limitations: [dark-star prototype evidence](../evidence/dark-starfalls-2026-10-16/README.md). Historical [automatic prototype evidence](../evidence/automatic-starfalls-2026-10-16/README.md) and turn-based evidence remain in their original folders.
