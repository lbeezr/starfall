# Automatic starfall prototype

This Debug experiment starts with an empty 7×7 board. The sky keeps filling it while the player clears matching groups. It follows the user's 16 October 2026 decision to try continuous pressure after the initial turn-based prototype.

## Play

Choose **Try the falling sky** in the Debug menu, or launch with `--starfalls`. Tap **Start sky** once. A shower arrives every four seconds, independently of clears. Showers contain 1, 2, 3 or 5 stars, weighted 1:2:3:1. Colors are random. Columns visit all seven in a shuffled bag before repeating, spreading early pressure across the field.

The preview shows each incoming star's shape/color and numbered column, in arrival order. Outlined columns receive that shower. Most of each four-second interval remains available for clearing; a five-star animation lasts about 1.5 seconds. The forecast changes after the arriving batch settles. The countdown is isolated from the board's observation updates.

- A star matching the small jewel on top grows it to value two, occupying the same cell.
- Otherwise, the star stacks as a small jewel worth one. Grown jewels cannot grow again.
- Tap an orthogonal matching group worth at least three to collect its combined value. A large jewel beside one small match can clear. Two small jewels or a lone large jewel cannot.
- Surviving jewels settle downward. Clearing neither changes the upcoming stars nor resets their deadline. Invalid taps leave the rules and deadline unchanged.
- If an arrival cannot stack or grow its column's top jewel, the round ends at that star. Earlier arrivals remain and later ones do not happen. A full column can still absorb a matching growth.

The strategy is to make room before a forecast arrives, or preserve a matching top jewel so it absorbs an arrival. There is no win target or move budget in the experiment; collect starlight and keep the sky open. The original 70-in-18 game retains its rules.

## Pace and lifecycle

**Pause sky** is always available during play, including mid-animation. Pausing settles any already committed action and freezes the remaining interval. Settings and backgrounding also freeze it. Returning never catches up missed showers. Resume preserves the remaining interval, with at least half a second of grace. Restoring a saved game, Replay and New sky always start paused.

The scheduler has one cancellable monotonic deadline. If it expires during a clear, one due shower waits for that presentation to finish, then takes priority over another clear. There is no backlog or repeating timer. Old timer and animation callbacks cannot affect a restarted or suspended game. Every committed event is saved before its animation begins.

Seed 5 is the initial sky. Replay restores its empty board and exact future sequence. New sky chooses a different random seed. Save key `starfall.accumulation.v2` separates this experiment from the prior turn-based save and the original game's saved round.

## Presentation and access

Stars use overlapping, staggered flights with colored tapered trails, white cores and soft landing rings. Growth uses the existing jewel material at a larger size with a value label. Effects are bounded by the five-star batch. Calm effects, system Reduce Motion and VoiceOver suppress travel and landing effects.

Every cell remains a native button with its shape/color, value, position and connected starlight value. A Matching groups rotor lists legal clears. Forecast stars expose shape/color and column labels. Settings hides the underlying board from accessibility navigation. Input gates during committed animations; Pause remains available.

The rule model remains deterministic and UI-independent in `Sources/StarfallCore`. The scheduler, persistence and SpriteKit presentation have explicit boundaries. Access remains Debug-only. No external SDKs, networking, tracking or monetization were added.

## Tuning questions

Four seconds, the batch-size weights and growth cap of two are initial choices, not established balance. Playtesting should determine whether the pressure feels satisfying, whether five-star bursts are readable, whether previews influence clears, and whether players want a slower mode. Dark stars and swaps remain outside this iteration so the accumulation loop can be evaluated clearly.

Validation and limitations: [automatic prototype evidence](../evidence/automatic-starfalls-2026-10-16/README.md). Historical turn-based evidence remains in the previous evidence folder.
