# Run the next falling-sky session

**Ready for an observed session; no human results collected.** Use the regular Starfall app and the [current protocol](../../docs/PLAYTEST-FALLING-SKY.md). Keep this moderator sheet out of the player’s view. Aim for two short fresh skies, stopping whenever the player wants. One prepared example comes only after natural play, if useful.

## Prepare one record per round

```sh
mkdir -p artifacts/playtests
python3 tools/playtest-results/falling_sky.py form artifacts/playtests/moderator.html
python3 tools/playtest-results/falling_sky.py new artifacts/playtests/S1.json
```

Open `moderator.html` locally in a browser to fill and download a draft, or edit `S1.json` directly. Both start completely unobserved. The form does not upload or persist automatically. `falling-sky-session.html` is the source template; generate the form before opening it. A second run refuses to overwrite an existing file.

Use anonymous `P1`…`P999` for people and unique `S1`…`S99999` for rounds. Reuse the same participant ID across rounds. Mark `human` only for actual people; agent observations and invented checks are `synthetic`. A person has at most one `first_time` round in the input set. No names, contact details, or personal device names.

Record the **installed** build ID from the Sky menu and its corresponding source receipt from [device delivery](../../docs/DEVELOPMENT_BUILDS.md). Mark `verified_install=yes` only when those match. Repository HEAD alone is insufficient. Leave unknown generation/cadence blank; a retained round and its replay can retain older rules despite a new app. Current new skies use `gravityOrbits`; record the actual cadence separately. Keep device/OS, text size, pace, Dusk frequency, motion, sound and haptics explicit; mark changes during play. A new install/build/settings cohort remains separate in the summary.

Let the player choose New sky; do not reset their retained round. Record `new_sky`, `retained_sky`, `same_sky_replay`, `first_light` or `prepared` accurately. Prepared boards and paused play answer narrower questions than an ordinary fresh automatic round.

## Watch before teaching

1. Ask them to start. Observe their first useful clear, pauses, long touch holds, invalid actions and waiting. Do not label an unseen group as absent or impose one clear per shower.
2. Watch the first storm. Does the player change **which group/order** they choose, only their speed, or neither? A round ending before a storm is `not_reached`; seeing a storm without assessing its effect is `not_assessed`.
3. For Opal, distinguish **encountered**, **a usable choice existed**, and **the player deliberately spent/preserved it**. Spending can be sensible. A choice that was never offered cannot be a comprehension failure.
4. If needed, ask once: “What do you expect that clear to change?” Record the answer before input. A neutral question is `neutral_prompt`; suggesting a strategy is `strategy_hint`. If asking interrupts automatic play, pause and mark `mixed` or `paused`. Touch-down holds the deadline; held wall time is not continuous pressure exposure.
5. After the action, record the actual result and whether it matched that prediction. Do not classify hindsight as a before-action prediction. Capture a short deidentified quote and the visible action in a local `S1-notes.txt`; note missed taps/trace cancellations separately.
6. After the round: “What made you choose that?” and “What would you like to do now?” Observe an actual independent new-round start when time is available. Asked-for interest, prompted starts and no available time stay separate.

For a mechanism example, use an existing reset-only Debug fixture only on a disposable simulator, after fresh-play observations. The current native-planning record owns its exact source and outcomes; it is not a cold learning or enjoyment result. Full actual VoiceOver acceptance follows the RC cadence, separately from this pilot. Do not infer speech/focus usability from labels.

## Validate, summarize, then choose one change

```sh
python3 tools/playtest-results/falling_sky.py summarize artifacts/playtests/S*.json
```

Keep downloaded records and raw notes locally under ignored `artifacts/playtests/`. The summary reports sessions and distinct people separately, keeps human/synthetic evidence and exact contexts apart, and excludes missing assessments from assessed denominators. It does not authenticate the labels or select a tuning change.

After the first **three uncoached people** on a comparable build, review the observations with their actual denominators. Three is a pilot decision point, not statistical preference evidence. If a build changes, preserve separate cohorts and state what remains incomparable. Returning players are useful but remain familiar sessions.

| Observation | Bounded next investigation |
| --- | --- |
| Input failures prevent intended actions | Reproduce and fix input readiness/geometry before drawing strategy conclusions. |
| Opal rarely offers a usable choice | Measure opportunity frequency in those seeds/settings; do not coach a missing opportunity into existence. |
| A choice exists but is missed | Test one clearer cue or explanation; keep outcomes/rules fixed for comparison. |
| Player acts deliberately but predicts the wrong outcome | Inspect committed-outcome feedback and the specific misunderstood rule. |
| Choices are understood but feel repetitive or unrewarding | Test one change to the competing payoffs against the same baseline. More legal selections alone is insufficient. |
| Player independently replays and explains a satisfying choice | Retain that behavior, check a second situation and avoid changing it from a bot score alone. |

Write the next action, the observation supporting it, the expected visible improvement and a stop/adopt/revise point. Preserve counterexamples and an explicit “not enough evidence.” No automatic mechanic, progression, save or frequency change follows from the report.
