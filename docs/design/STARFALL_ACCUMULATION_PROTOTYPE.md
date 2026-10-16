# Turn based starfall prototype

The playable experiment starts with an empty 7×7 board. Manage the accumulating stars and collect starlight for as long as possible. This is the accumulation direction selected on 16 October 2026, following the earlier full-board replace-or-grow proposal.

## Play

In a Debug build of the shared Starfall scheme, choose **Try turn-based starfalls** from the menu. The launch argument `--starfalls` opens it directly. The first sky uses seed 5, which demonstrates a grown jewel and a clear after three invitations; **New sky** chooses another seed, and **Replay this sky** returns to the same empty board and shower sequence.

The preview shows three stars in arrival order, with the color/shape and numbered column for each. The outlined board columns receive that shower. Tap **Let stars fall** to invite it, or tap a connected orthogonal matching group worth at least three to collect that group first. Either action advances exactly one shower. Invalid taps spend nothing and preserve the preview.

Landing columns visit all seven columns in random order before repeating. Colors remain random. This spreads the early accumulation across the field and avoids a few unlucky arrivals immediately filling one column.

Survivors settle downward, leaving empty space above them. There is no automatic refill. Each forecast star then arrives in order:

- A matching small jewel at the top of that column absorbs the star and grows to value two, occupying the same one cell.
- Otherwise, the star stacks as a small jewel worth one. Grown jewels cannot grow again.
- If a star cannot stack or grow the top jewel of its column, the round ends at that star. Earlier arrivals in the shower remain; later arrivals do not happen.

Grown jewels count as two toward the clear threshold and score. A large jewel beside one small match can clear; two small jewels or a single large jewel cannot. Growth itself awards no immediate score. A full column can still accept a star if its top jewel can grow. Clearing beneath a column before its shower can prevent overflow.

This threshold is an intentional experiment-specific change: requiring three physical jewels made absorption work against forming groups. In the initial seed-42 rule check, it produced no legal group before overflow. Counting growth toward the threshold makes absorption useful for both space and future clears.

There is no clock, move budget or win target in this experiment. The goal is to keep room and improve your collected score. A sky with no matching group can still receive a shower; overflow is the loss condition. The original 70-in-18 game retains its existing rules and free dead-board recovery.

## Controls and presentation

The main action invites one shower. Replay and New sky start fresh rounds. Close returns to the ordinary game. Settings explains growth and overflow and offers Calm effects. Every board cell is a native button with a shape/color label, value, position and connected starlight value; a Matching groups rotor lists legal clears. The incoming preview includes shape/color and column accessibility labels.

The SpriteKit presentation shows clear, downward settling and three sequential arrivals. Calm effects, system Reduce Motion and VoiceOver suppress travel. Input remains gated during a committed shower to absorb rapid taps. Backgrounding, settings, resizing and leaving the screen settle the presentation to the saved result. The experiment uses its own local save key, `starfall.accumulation.v1`, preserving the original game's saved round.

## Scope and review

Rules are deterministic in `Sources/StarfallCore/StarfallExperiment.swift`. The SwiftUI screen, state/persistence boundary and SpriteKit presenter are separate small files. Jewel rendering reuses the existing five-texture material factory. App access is Debug-only; Release keeps the existing menu. No external SDK, network feature, paid asset or monetization code was added.

Three arrivals per action, the growth cap of two and the opening seed are initial tuning choices. This build is for observing whether players read the forecast, make room deliberately and enjoy replaying a sky. Automated tests establish rules and interaction behavior, not enjoyment or long-term balance.

Native validation and its limits are recorded in [the prototype evidence](../evidence/starfalls-prototype-2026-10-16/README.md).
