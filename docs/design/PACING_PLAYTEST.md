# Compare pacing with the user first

**Status:** Ready for user session; actual observations pending · **Owner:** pacing comparison owner · **Updated:** October 17, 2026

Run an initial comparison with the user alone. Test whether announced timing contrast gives the user a usable breathing window while preserving intentional input. This session can support a provisional policy selection; it cannot establish broad preference or unfamiliar-player comprehension. No human observations have been collected.

**Next action:** The user completes the four rounds below against the simulator-verified candidate. A second participant is not required to start or report this session.

## Scope and success

This protocol follows the [shared pacing proposal](PACING_NEXT.md), originally committed as `590be47` on October 17. Its historical source hashes are not candidate acceptance. Original protocol baseline: `571ccd1`. This session handoff is prepared against clean combined source `b42eba357515793c834fec7d9125907ca106a22f` on `codex/pacing-baseline`. The [combined acceptance report](../evidence/pacing-acceptance-2026-10-17/README.md) verifies that export’s presentation separately from the unchanged earlier rules/store checks. Record any changed source and its verification separately.

A uses three-second post-opening intervals. B repeats six waves at three seconds, three at 2.5 seconds and three at 3.5 seconds, with the faster passage announced one wave ahead. Both use the same four-wave opening and generation rules. Confirm these policies against the handoff; record discrepancies before comparing. Mechanics changes are outside this session.

- [x] Record source-bound candidate identity and technical acceptance from tasks 5 and 6; retain their explicit limits.
- [ ] Complete or explicitly mark incomplete both matched seed pairs.
- [ ] Capture cue explanation, a deliberate breathing-window action or its absence, cancellation/idle examples and preference in the user's own words.
- [ ] Choose provisional B, retain A/remove B, or one named bounded follow-up; list cleanup and remaining verification.

## Run four rounds with reversed order

Prespecify seeds **0 and 11**, recommended by task 5’s tooling as contrasting counterexamples, before collecting any human results. This is purposeful coverage, not a representative random sample or selection from human outcomes. Give a brief controls introduction and one unscored practice using a different seed. Do not explain the expected benefit of B or coach during scored rounds.

| Pair | First round | Second round |
| --- | --- | --- |
| Seed 0 | A | B |
| Seed 11 | B | A |

Start each round from its fresh matched initial state. Play for up to three active minutes or until the sky ends. Record early endings without replaying for a better result. Use the same device, controls, motion/accessibility settings and balance values throughout; preserve the user's required accessibility settings. Take a brief break between pairs and record interruptions. Do not require think-aloud during timed play. Separate pause/manual-shower episodes from automatic active play.

Order reversal limits a simple order bias but does not remove learning, fatigue or seed effects in one participant. Matching initial seeds does not guarantee identical later incoming waves: different actions can trigger board-dependent relief.

Immediately after each round ask:

- What did the cues tell you would happen next?
- Was there a calmer passage? Describe a deliberate action you took, or why you could not use it.
- Did a shower interrupt something you intended? What happened?
- When did you wait by choice, and when because there was nothing useful to do?

After each pair ask which felt better and why; accept no preference. After all rounds ask whether that preference changed. Preserve direct statements separately from observer interpretations.

## Launch the handed-off session

Task 6 supplied the [final verification result](../evidence/pacing-acceptance-2026-10-17/README.md), export `/tmp/starfall-pacing-final-acceptance-export` (manifest pins `b42eba3`) and owned iPhone 17 simulator `F4BA0D73-6491-4171-A29B-93ABC79EB4FF`. It is shut down after preference restoration; the session operator may resume that existing candidate when the user is ready. The [cue handoff](PACING_CUE_HANDOFF.md) describes export mechanics; its older task-4 source/checks do not validate this combined source. Do not start another export, native selector, build or installation for this session. Use the same simulator identity `com.starfall.prototype` for all four rounds, with the isolated `starfall.pacing.candidate` save prefix confirmed by the manifest. Preserve normal saves and the single installed phone identity; no phone app, updater or publication action is needed.

The session operator substitutes task 6’s simulator UUID below. Terminate the previous candidate round before each launch using the handed-off simulator controls; launch arguments apply to a fresh process. Run these one at a time, completing and reporting each round before the next:

```sh
# Round 1: seed 0, A
xcrun simctl launch <PRIVATE-SIMULATOR-UUID> com.starfall.prototype --starfalls-reset --starfalls-seed=0 --pacing-policy=A
# Round 2: seed 0, B
xcrun simctl launch <PRIVATE-SIMULATOR-UUID> com.starfall.prototype --starfalls-reset --starfalls-seed=0 --pacing-policy=B
# Round 3: seed 11, B
xcrun simctl launch <PRIVATE-SIMULATOR-UUID> com.starfall.prototype --starfalls-reset --starfalls-seed=11 --pacing-policy=B
# Round 4: seed 11, A
xcrun simctl launch <PRIVATE-SIMULATOR-UUID> com.starfall.prototype --starfalls-reset --starfalls-seed=11 --pacing-policy=A
```

These are instructions only; no launch has been performed by this documentation task. B is Debug-simulator reset-only: it is not a persisted/restored policy, and every B round needs explicit reset and selection. Release retains A. Do not use a resumed save to compare policies.

After each round, the user can report this short form in chat:

> Round / seed / policy; approximate active duration and ending; what the cue meant; one deliberate action during a calmer passage (or none and why); any interrupted gesture or frustrating idle stretch; anything else confusing.

After rounds 2 and 4, add **A, B or no preference**, with a reason. Approximate recollections are valid qualitative observations; label them as such rather than converting them to measured timings. The operator records source/settings and available harness evidence separately. Stop for a technical failure and record the incomplete round instead of treating it as gameplay preference.

## Record evidence without filling gaps

Before play record candidate commit/export identity, working-tree differences, policy version, seed/reset instructions, device/OS, configuration, settings, round order and task 5/6 evidence links. Use existing candidate access only; this protocol authorizes no installation or deployment and must preserve the single installed phone identity.

For each round record duration/ending, cue explanation, breathing-window action, frustrating cancellations or idle stretches, and preference with reasons. Keep human statements, observer notes, local harness measurements and bot results in separate fields. Mark missing measurements unavailable; do not infer intended actions from bot behavior.

Where the handed-off local evidence supports them, report first accepted clear, time with neither legal tap nor legal trace and longest gap, accepted taps/traces per active minute, completed/deadline-cancelled traces, presentation-gated time, delivered versus scheduled intervals and pressure outcomes. Distinguish an opportunity drought from deliberate waiting. Keep counterexamples visible; score and survival alone do not demonstrate agency or enjoyment. No new telemetry implementation is part of this task.

## Decide and retire the comparison

**Provisional B selection:** The user can explain the faster cue, describes a usable intentional action in a breathing window, and prefers the rhythm for concrete reasons supported by the observations. Input/interruption and other technical gates must pass before adoption. Report this as one user's preference; unfamiliar-player comprehension and broader preference remain unverified.

**Retain A/remove B:** B fails to create a usable breathing window or adds consequential confusion, cancellation or idle time, or the user prefers A. Record the tradeoff and remove candidate-only routes/assets/code in a separately verified cleanup patch.

**One bounded follow-up:** If evidence is mixed or incomplete, name one unresolved question, the scenario/rounds needed and the next decision point. Do not accumulate permanent pilot flags. Recommend gesture grace only when observed deadline cancellations demonstrate a problem; recommend a wave-size bag only when opportunity droughts persist. Questions about meaningful mechanics belong to the separate mechanics workstream.

If B is selected, define a narrow integration/retirement patch: make the selected policy authoritative for its intended new-sky route, preserve legacy saves/First Light/replay contracts, remove comparison-only routing and unused assets, and update experiment/design/roadmap facts through their coordinator. Require hygiene, core and affected hosted/UI checks, Debug/Release simulator builds, and source-bound native input/interruption, full-motion and lightweight accessibility evidence. Actual VoiceOver remains the release-candidate gate under the repository cadence. No merge or publish is authorized here.

## Current verification limits

Technical simulator acceptance is recorded in the linked report; actual user observations remain pending. No human gameplay result is implied by this protocol. A remains the retained policy with no B adoption claim. Human interaction, animation, accessibility and device evidence must retain their separately reported limits. No source/resource/build-setting changes are required for preparation. A second participant is optional later and is not a blocker for this initial session. Retain unfamiliar-player comprehension as explicitly unverified even if the user selects B.

On the calibrated iPhone 17, A uses the camera contour and B’s fixed cue slot selects the safe header forecast. This comparison therefore includes that presentation difference alongside timing/cues; record whether it affects the user’s judgment. Native seed 0/11 comfort, accelerated-opening intentional traces, continuous smoothness, actual VoiceOver and physical-device behavior remain unverified.
