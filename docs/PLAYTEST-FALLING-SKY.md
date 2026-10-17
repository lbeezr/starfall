# Falling-sky comparison playtest

Use this for the current default game. The older PLAYTEST and first-playtest kit concern the original 70/18 puzzle.

Run two short rounds with the same balance and motion settings: current version, then one bounded candidate. Alternate version order across people where practical. Record version, seed when known, pace, dark frequency, automatic/manual play, device and accessibility settings. Do not add analytics or record identifying details.

Before coaching, ask the player to start and explain what they think makes a clear. Observe their first legal clear, pauses, manual showers, invalid taps, and periods in which they say they are waiting. Record times only if actually measured. Do not treat a missed group as proof the board had no move.

After each round ask:

- When did you first feel you could do something useful?
- Was there a point where you chose between two clears? What mattered?
- Did you deliberately wait, or did the game make you wait?
- What did the dark star change? If the round ended, why?
- Would you replay this version? Which version would you choose, and why?

For VoiceOver, separately inspect spoken piece value/location, matching-group rotor, activation, pause/manual shower, and focus after Settings. A sighted accessibility-grid test is not this check.

Record short quotations, observed examples and missing observations. Keep simulator performance, bot policy scores and participant preferences separate. One preferred version is an initial signal, not a general balance conclusion. End with one bounded change or the specific evidence still needed.

No participant observations have been collected for this protocol yet.

## Shower-variety comparison

Use the matched **Sky Baseline**, **Shower Lab** (natural-only pairing), and **Pressure Lab** exports described in [the pressure evidence](evidence/pressure-showers-2026-10-17/README.md). All share the same frozen HUD/renderer. Comparing a frozen lab against newer production presentation would confound preference. Match pace, Dusk frequency, motion, sound/haptics, text size, device and automatic/manual mode. Keep normal saves separate.

Start with uncoached fresh rounds; record the actual seed and rotate version order where practical. Record time to first clear only when measured, first simultaneous groups, whether they noticed both, which clear they chose and their reason. A player who clears every ready group may experience little pressure tradeoff; record that rather than imposing a one-clear limit. Pressure seed 5 has no choice within twenty showers even though the 200-seed opportunity rate matches natural-only; do not use a single seed as the preference conclusion.

After fresh-round preference is recorded, optionally use `--shower-decision-fixture`. Ask what they would clear and why before explaining the two outcomes. Distinguish choosing the larger group from recognizing the threatened column. Paused play allows both clears; the consequence of a single clear matters when automatic rain is already due. This coached demonstration is separate from unprompted strategy discovery. End with a concrete preference/reason, confusion to fix, or an explicit lack of preference. No such human observations have been collected yet.

## Phase choices and HUD comprehension

Keep two questions separate. To compare **rules**, use Shower Lab and Surge Lab with the same frozen HUD/renderer. To compare **presentation**, use Surge Lab and Surge Lab HUD with identical Surge rules. Comparing Shower Lab's old HUD against compact Surge changes both rules and information; it cannot identify the reason for a preference. Record the export manifest and installed build, not just the app name. [Compact trial setup and limits](evidence/compact-phase-2026-10-17/README.md).

For a bounded HUD comparison, launch both Surge apps with `--starfalls-reset --shower-phase-fixture`. Both begin at seed five after eight showers, following the fixture's canonical clears. Keep balance, motion, device and text size matched, and alternate app order across people. This is a prepared state, not an uncoached opening or independent replay of the earlier simulated round. Keep saves separate.

Before advancing or explaining the cue, ask what the player expects next, whether they would clear or wait, and why. Record that answer before the action, then what actually happened. Continue through shower thirteen or loss. Record unavailable clears as such; never impose a one-clear-per-shower policy. Note whether the reason concerns column height, growth, a dark star, joining survivors, or a revealed forecast. Distinguish visible information from accessibility values, hints or coaching used during exploration.

Ask whether the warning, event count and recovery changed a useful choice; retain an explicit “no” or lack of preference. Do not infer strategy from a higher score after decisions diverge. Then use fresh rounds and normal automatic play to assess the wider experience: a paused fixture cannot establish urgency, initial comprehension or enjoyment. Record automatic and paused observations separately. Actual VoiceOver listening/focus is a separate session; reading the accessibility tree is not its substitute.

At the decision point, select one lab presentation, remove the redundant comparison, or name one bounded remaining question. Human preference and agent simulation stay separate; repeated sessions by the same agent retain familiarity and order effects. No production generation or save migration follows solely from HUD preference.

## Current playable comparison: survival versus First Light

The next tranche adds First Light under Sky settings. It starts a new round with a fixed seed, an 18-starlight goal and no dark stars; replay repeats it, while New sky returns to survival. Compare these as whole experiences first. A preference cannot be attributed to the goal alone because seed/configuration also differ from a default survival round.

Observe whether the player notices the goal before acting, recognizes the completed state, understands that showers stop, and chooses replay or New sky. Ask whether this feels like a satisfying short puzzle or merely the same survival round cut short. Do not claim a level system or persistent campaign progress from this single challenge. No observations have been collected yet.
