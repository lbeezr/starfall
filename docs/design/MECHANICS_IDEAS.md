# Mechanics notebook

Captured October 17, 2026. These are ideas for exploration, not adopted rules or an implementation plan. The current small-prototype scope remains unchanged; a charge burst or new special star would need a separate experiment decision before implementation.

## Current dark star: Dusk

The authoritative rules live in `Sources/StarfallCore/StarfallExperiment.swift`:

- A dark star occupies space and suppresses growth in its four orthogonally adjacent cells. Diagonals are unaffected.
- It does not drain color, shrink an already grown star, stop matching, or freeze movement. A matching arrival that cannot grow stacks instead.
- Tapping Dusk cannot clear it. Clearing a neighboring legal same-kind group worth at least three removes every dark star touching that group orthogonally.
- Dark stars award no extra starlight. Survivors settle after the clear.
- Default dark-star frequency is a gap of four to six showers; local balance controls can disable or change it. First Light has no dark stars.

## Press and hold: supernova clear and nearby color changes

User direction: retain tap-to-clear; holding should produce a more violent, forceful clear—a supernova—that could also change the colors of nearby stars. Color change is a possible gameplay effect, not merely a temporary visual tint. This supersedes preview-only holding as the main concept; a preview can still communicate the charged effect.

Design hypothesis: an ordinary tap collects an existing opportunity; a supernova reshapes nearby opportunities by recoloring surviving stars. This could let players set up their next clear. The specific recoloring rule remains open: adopting the charging star's color would be predictable, while rotating colors would produce a different planning puzzle. Neither rule is selected. The forceful feeling should come from readable anticipation, impact and recovery, with comfortable reduced-motion feedback.

Questions to resolve before a prototype:

- Does release commit? How does sliding away cancel, and what happens when a shower changes the group under the finger?
- Which stars clear and which survive to change color? Is the neighborhood orthogonal or radial, and are dark/light/void stars affected? No radius, cost, threshold or charge duration is chosen.
- Does recoloring preserve character identity, or transform one cast member into another? Keep color, silhouette and matching identity consistent; a visual tint must not disagree with the rules.
- Does a recolored group wait for the next deliberate clear or trigger a cascade? Decide the resolution order, growth behavior and settling explicitly.
- Why choose an immediate tap instead? Avoid making repeated long holds the compulsory optimal move.
- Can the same action be invoked accessibly without a timed hold? Preserve pause/manual play and clear feedback with Reduce Motion.
- How are charge intent and committed outcomes represented deterministically in core, independently of animation completion and gesture wall time?

## Constellations

User idea: explore a constellation mechanism. No connection, scoring or activation rule has been chosen.

Possible directions to compare, not simultaneous requirements:

- **Recognize a pattern:** stars forming a small readable arrangement connect into a constellation. This could reward placement/planning, but must remain achievable on an accumulating board.
- **Build a connection:** successive deliberate clears light up a short constellation. This could create a round-local goal without requiring a campaign, XP or unlocks.
- **Choose a connection:** the player links stars into a constellation as an alternate interaction. This needs clear eligibility, cancellation and an accessible alternative to tracing a path.

One promising relationship to investigate is using a supernova's color changes to prepare a constellation. Test each mechanic alone first so their value and complexity can be assessed independently. A constellation could simply be a satisfying recognition/reward moment; it does not inherently need another special ability.

Open questions: Are constellations on the board or represented elsewhere? Must stars share a color? Are diagonals legal? Do links survive falling/settling? What completes or breaks the pattern, and what does completion do? Keep connections visually light so they do not obscure faces, legal groups or the board. Avoid restoring square cell backgrounds or adding a large progress panel.

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
