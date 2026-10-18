# Falling-sky comparison playtest

Use this for the current default game. The older PLAYTEST and first-playtest kit concern the original 70/18 puzzle.

## Current session: Opal planning under storm pressure

**Status: Ready to run; no participant results.** Use the single regular Starfall app, with current Opal/storm generation and the faster V2 cadence. Start a fresh survival sky; a retained sky or same-sky replay preserves its older generation/cadence, and First Light excludes these mechanics. Record the installed source/build and available seed, balance, motion, sound, text size and device. Do not replace the player's retained round without their choice of New sky.

**Question:** Do storms change which clear a player chooses, or mainly how quickly they clear? Does Opal offer a recognizable reason to choose one clear before another? The [bounded study](evidence/opal-choice-study-2026-10-17/README.md) and [native two-clear check](evidence/opal-native-planning-2026-10-17/README.md) establish possible rewards, not human interest.

1. Let the player start ordinary automatic play without explaining a preferred strategy. Observe the first storm warning, three heavy showers and recovery, or record loss/stop before those points. Do not require one clear per shower or discourage the player's use of pause.
2. Before explaining an observed choice, ask what they plan to clear or preserve and why. Record the answer and actual action separately. If questioning interrupts play, pause and label that observation as prompted/paused; do not count it as automatic-play performance.
3. Note whether the reason concerns column height, available space, Dusk, grown value, Opal's family allocation, or the color forecast. Distinguish a changed group/order from faster tapping, and keep an explicit “no change.” Record long holds on eligible stars as well as pauses: touch-down holds the single shower deadline, so time held is not uninterrupted pressure exposure.
4. After the round, ask what the warning/recovery meant, whether a deliberate smaller/equal clear paid off, and whether they want another sky. Keep exact short quotations and counterexamples. A player who never finds an Opal choice may be reporting frequency or legibility, not misunderstanding the rule.
5. Only afterward, optionally demonstrate the existing Debug `opalPlanning` fixture using `--starfalls-reset --constellation-fixture=opalPlanning` on an isolated simulator. Ask for the first choice and predicted follow-up before explaining the seven-versus-six outcome. This prepared board is not an ordinary-round preference result; no new lab app, selector or phone-save reset is required.

For a current-gravity prepared comparison, the reset-only `opalStormPlanning` fixture replays seed 180 / shower 12. Record whether the player notices field release separately from Opal preservation: the stronger follow-up leaves Opal untouched. Two ordinary taps yield eight versus six; the nine-light branch requires tracing five released Aqua stars. [Verification and remaining input limits](evidence/current-opal-native-2026-10-17/README.md). Use only after the uncoached ordinary-play observation.

| Record per session | Observation |
| --- | --- |
| Source/build, new or retained sky, settings/device | Not collected |
| First storm warning/event/recovery reached | Not collected |
| Clear choice and reason before the event | Not collected |
| Changed group/order versus changed speed | Not collected |
| Opal preserved/spent deliberately; predicted versus actual benefit | Not collected |
| Pause, touch holds, coaching or intervening showers | Not collected |
| Replay preference and exact reason | Not collected |

**Decision point:** After an observed session, choose one bounded follow-up: clarify an identified cue, investigate choice scarcity, compare pressure pacing, or keep the rules. A single preference is an initial signal. Keep source, observations, interpretation and missing evidence separate; no automatic frequency/power/progression change follows. Human comprehension, actual VoiceOver and physical feel are separate checks. The earlier lab protocols below remain historical reference, not delivery instructions.

## Separate pressure, understanding and replay

**Status: Ready to use; no participant results.** Keep the current game and pending first-round question unchanged. This extends interpretation after that answer, not the number of questions asked during falling play.

An [online experiment by Klimmt, Hartmann and Frey (2007)](https://journals.sagepub.com/doi/10.1089/cpb.2007.9942) manipulated perceived influence and control in a game (500 participants). Its abstract reports a role for perceived influence in enjoyment, with a more complex control relationship. Only the public abstract was reviewed here; this does not validate Starfall's pressure, cadence or reward. Our design inference is to distinguish feeling busy from recognizing a consequence caused by one's choice. The [Tyack/Mekler review](https://arxiv.org/abs/2405.12639) also cautions against shallow applications of motivation theory; neither source is a feature checklist.

| Observation | What it can support | Next bounded response |
| --- | --- | --- |
| Player clears faster but names no changed choice | Pressure was noticed; strategic engagement is still unknown | Ask which moment felt deliberate after the round; do not automatically increase speed |
| Player predicts a specific rearrangement, then the committed result agrees | A consequential choice was understood on that board | Record the prediction before the action and the actual result separately; avoid attributing an orbit benefit to Opal merely because it survives |
| Player predicts correctly but cannot carry out the action | Understanding and execution differ | Investigate that input/window/readability reproduction before adding another mechanic |
| Player executes a prepared example after explanation | The demonstrated sequence was reproducible | Label coaching and familiarity; this alone establishes neither discovery nor transfer |

If the player voluntarily chooses another round after the first-round answer or prepared example, offer **New sky** as the optional transfer check. Record the new source/seed/settings and whether a similar principle is recognized on a different arrangement, without recommending a first clear or revealing arrivals. Keep pauses/holds explicit. If no comparable opportunity occurs, record **not observed**, not failed learning. If the player prefers same-sky replay, preserve that choice and record rehearsal rather than fresh-board transfer. Stop when they choose to stop; the protocol does not require another round.

Record voluntary replay/decline and the player's reason separately from score and demonstrated skill. Enjoying simple clears is a valid preference. One explained fresh-board choice and a voluntary replay are initial signals, not proof of long-term replayability or retention. Do not add tracking, progression or reward schedules to fill that evidence gap. At the decision point, choose one observed cue/input/frequency issue or retain the current rules; wait for an actual observation before selecting a candidate.

Use the matched-version protocol below only once an observed issue justifies a bounded candidate. Run two short rounds with the same balance and motion settings: current version, then one bounded candidate. Alternate version order across people where practical. Record version, seed when known, pace, dark frequency, automatic/manual play, device and accessibility settings. Do not add analytics or record identifying details.

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

## Historical shower-variety comparison

Use the matched **Sky Baseline**, **Shower Lab** (natural-only pairing), and **Pressure Lab** exports described in [the pressure evidence](evidence/pressure-showers-2026-10-17/README.md). All share the same frozen HUD/renderer. Comparing a frozen lab against newer production presentation would confound preference. Match pace, Dusk frequency, motion, sound/haptics, text size, device and automatic/manual mode. Keep normal saves separate.

Start with uncoached fresh rounds; record the actual seed and rotate version order where practical. Record time to first clear only when measured, first simultaneous groups, whether they noticed both, which clear they chose and their reason. A player who clears every ready group may experience little pressure tradeoff; record that rather than imposing a one-clear limit. Pressure seed 5 has no choice within twenty showers even though the 200-seed opportunity rate matches natural-only; do not use a single seed as the preference conclusion.

After fresh-round preference is recorded, optionally use `--shower-decision-fixture`. Ask what they would clear and why before explaining the two outcomes. Distinguish choosing the larger group from recognizing the threatened column. Paused play allows both clears; the consequence of a single clear matters when automatic rain is already due. This coached demonstration is separate from unprompted strategy discovery. End with a concrete preference/reason, confusion to fix, or an explicit lack of preference. No such human observations have been collected yet.

## Historical phase choices and HUD comprehension

Keep two questions separate. To compare **rules**, use Shower Lab and Surge Lab with the same frozen HUD/renderer. To compare **presentation**, use Surge Lab and Surge Lab HUD with identical Surge rules. Comparing Shower Lab's old HUD against compact Surge changes both rules and information; it cannot identify the reason for a preference. Record the export manifest and installed build, not just the app name. [Compact trial setup and limits](evidence/compact-phase-2026-10-17/README.md).

For a bounded HUD comparison, launch both Surge apps with `--starfalls-reset --shower-phase-fixture`. Both begin at seed five after eight showers, following the fixture's canonical clears. Keep balance, motion, device and text size matched, and alternate app order across people. This is a prepared state, not an uncoached opening or independent replay of the earlier simulated round. Keep saves separate.

Before advancing or explaining the cue, ask what the player expects next, whether they would clear or wait, and why. Record that answer before the action, then what actually happened. Continue through shower thirteen or loss. Record unavailable clears as such; never impose a one-clear-per-shower policy. Note whether the reason concerns column height, growth, a dark star, joining survivors, or a revealed forecast. Distinguish visible information from accessibility values, hints or coaching used during exploration.

Ask whether the warning, event count and recovery changed a useful choice; retain an explicit “no” or lack of preference. Do not infer strategy from a higher score after decisions diverge. Then use fresh rounds and normal automatic play to assess the wider experience: a paused fixture cannot establish urgency, initial comprehension or enjoyment. Record automatic and paused observations separately. Actual VoiceOver listening/focus is a separate session; reading the accessibility tree is not its substitute.

At the decision point, select one lab presentation, remove the redundant comparison, or name one bounded remaining question. Human preference and agent simulation stay separate; repeated sessions by the same agent retain familiarity and order effects. No production generation or save migration follows solely from HUD preference.

## Survival versus First Light comparison

First Light is available in the regular app. It starts a new round with a fixed seed, an 18-starlight goal and no dark stars; replay repeats it, while New sky returns to survival. Compare these as whole experiences first. A preference cannot be attributed to the goal alone because seed/configuration also differ from a default survival round.

Observe whether the player notices the goal before acting, recognizes the completed state, understands that showers stop, and chooses replay or New sky. Ask whether this feels like a satisfying short puzzle or merely the same survival round cut short. Do not claim a level system or persistent campaign progress from this single challenge. No observations have been collected yet.
