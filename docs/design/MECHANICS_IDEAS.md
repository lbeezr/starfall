# Mechanics notebook

Captured October 17, 2026. These are ideas for exploration, not adopted rules or an implementation plan. The current small-prototype scope remains unchanged; a charge burst or new special star would need a separate experiment decision before implementation.

## Current dark star: Dusk

The authoritative rules live in `Sources/StarfallCore/FallingSky.swift`:

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

User idea: explore a constellation mechanism. Latest physical-device feedback (October 17): the player often sees too few valid clears and expects the five connected pink stars near the lower-right board to count through diagonal links. This is an observed frustration and a concrete future candidate, not adopted rules.

### Next candidate: diagonal constellations of five or more

Keep ordinary orthogonal matching at 3+ starlight. Separately test a same-family connected constellation of at least **five actual stars**, allowing diagonal as well as orthogonal links. A grown star remains one star toward this eligibility threshold, while retaining its existing starlight value if cleared; confirm this interpretation with the player before implementation. The photographed pink arrangement is an offset/branching cluster, not five in a single straight diagonal. Tap any member to preview/clear the eligible connected group; a tracing gesture is not presumed necessary.

The observed lower-right pattern corresponds to front-based cells `(0,4), (1,3), (2,4), (1,5), (1,6)` in the captured terrace. Its diagonal connections make a visually coherent five-star constellation despite failing today's orthogonal clear rule. Retain the board description rather than the raw phone screenshot, which contained an unrelated notification.

Hypothesis: recognize patterns players already perceive, reduce waiting for legal moves, and create satisfying larger clears without changing every diagonal pair/triple into an ordinary match. Compare current rules and this single candidate on the same saved-board fixtures and shower sequences. Measure useful choice counts, time without a clear, incidental clears, survival and player comprehension; more legal moves alone does not establish better play.

Acceptance before adoption: this five-star pink fixture clears; diagonal-only three/four-star clusters do not; ordinary 3+ starlight clears retain their outcomes; grown-star eligibility/scoring is explicit; empty cells/different families cannot bridge links; dark-star removal adjacency is decided explicitly (retain current orthogonal rule in the first bounded comparison); survivor settling, save/replay/RNG, interruption and accessible tap alternatives remain deterministic. Define precedence for groups eligible under both rules before implementing. Keep the candidate isolated, then adopt/remove it after native and observed player comparison. No current game or saved round changes in this note.

Other possible directions, retained for context:

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

## HUD: communicate decisions, reduce permanent text

User discussion, October 17: question whether announcing a shower and showing its contents adds enough to the game. Pause need not be prominent. The initial suggestion to restrict pause to a continuous-rain chaos mode was explicitly revised: keep pause available, reduce its prominence. Chaos remains an optional idea, not an adopted mode or rule change.

The first comparison is implemented as the [compact HUD trial](../evidence/compact-hud-2026-10-17/README.md). The points below retain the original hypotheses; this trial is not yet evidence of player preference:

- Keep one compact score/goal readout and a quiet menu control. Put pause/resume within the menu, with a clear resume action when the menu closes. Preserve system-interruption suspension and accessible access; hiding a large pause button must not make pausing difficult.
- Remove the permanent game title, shower counter, matching-group count and repeating instruction/status sentence from active play. Keep teaching/contextual feedback where needed; retain accessible board/group information instead of removing it with the visual labels. Round statistics can live in the result screen.
- Compare a subtle pre-arrival cue near the sky's top edge against an exact incoming-star strip. Timing may communicate fair pressure without asking players to read another row. No numerical countdown is presumed necessary. Provide equivalent non-motion information and native accessibility semantics.
- Keep exact contents only if players use them to choose which group to save or clear. Landing columns are currently hidden; the preview cannot support precise placement planning. Ask players to explain an actual forecast-driven decision rather than assuming more information creates strategy.
- Put danger on the affected column and collection feedback near the clear, using redundant shape/contrast cues. Avoid replacing the current text with many unrelated meters, badges or persistent effects.

Working hypothesis: an uncluttered board with score/goal, a quiet menu and a restrained arrival cue will be easier to read without losing meaningful choices. Compare the same seeds/timing with and without exact contents, observe useful decisions, surprise/fairness, waiting and comprehension, then adopt or remove the preview. No default mechanics, clock, pause, accessibility or settings behavior changes in this notebook update.
