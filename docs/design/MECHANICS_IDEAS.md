# Mechanics notebook

Captured October 17, 2026. These are ideas for exploration, not adopted rules or an implementation plan. The current small-prototype scope remains unchanged; a charge burst or new special star would need a separate experiment decision before implementation.

## Current dark star: Dusk

The authoritative rules live in `Sources/StarfallCore/StarfallExperiment.swift`:

- A dark star occupies space and suppresses growth in its four orthogonally adjacent cells. Diagonals are unaffected.
- It does not drain color, shrink an already grown star, stop matching, or freeze movement. A matching arrival that cannot grow stacks instead.
- Tapping Dusk cannot clear it. Clearing a neighboring legal same-kind group worth at least three removes every dark star touching that group orthogonally.
- Dark stars award no extra starlight. Survivors settle after the clear.
- Default dark-star frequency is a gap of four to six showers; local balance controls can disable or change it. First Light has no dark stars.

## Press and hold: charge clear or burst

User idea: retain tap-to-clear and explore a deliberate press-and-hold interaction, potentially charging a clear or burst.

First hypothesis: holding could reveal the affected group and build anticipation before release. A larger effect could create a decision about waiting under falling-star pressure, but it could also make every ordinary tap feel inferior or slow the game further. A preview-only hold and a rules-changing burst are separate experiments.

Questions to resolve before a prototype:

- Does release commit? How does sliding away cancel, and what happens when a shower changes the group under the finger?
- What does charging change: reach, strength, growth, or interaction with a special star? No radius, cost, threshold or charge duration is chosen.
- Why choose an immediate tap instead? Avoid making repeated long holds the compulsory optimal move.
- Can the same action be invoked accessibly without a timed hold? Preserve pause/manual play and clear feedback with Reduce Motion.
- How are charge intent and committed outcomes represented deterministically in core, independently of animation completion and gesture wall time?

## Light / white star

User idea: introduce a light or white star alongside dark stars.

Possible role: restorative counterplay that returns drained stars to their original identity or releases a frozen state. This is a proposal, not a chosen wildcard, bomb or scoring rule. Decide whether it falls naturally, is activated by a neighboring clear, or has another interaction only after choosing the problem it solves.

Its silhouette, face and state markers must distinguish it without color alone. Keep its character warm and readable against the existing board and Dusk.

## Void / hole: color drain and freezing

User idea: something drains a star's color and freezes it; a void or hole is a possible identity.

Possible role: a reversible threat that preserves the original star identity for restoration by light. “Frozen” needs a precise definition: blocked growth, matching, movement, or some combination. None is selected yet. Avoid an irreversible dead board, restoration loops, or additional waiting without useful choices.

Visually explore washed-out, sleepy characters rather than implying they have been injured or destroyed. Communicate the state with more than desaturation.

## Keep the roles distinct

Dusk currently suppresses local growth; a proposed void could drain/freeze; a proposed light star could restore; a charged interaction could offer deliberate counterplay. These roles should not automatically become four simultaneous additions. First consider whether evolving Dusk would provide the same depth with fewer rules.

Before adopting anything, choose one hypothesis and a bounded comparison against the current game. Check time to a useful move, meaningful alternatives, comprehension, recovery from blocked states, replay preference, input accessibility, and save/replay determinism. Human play observations decide whether the added rule earns its complexity; bot scores alone do not.
