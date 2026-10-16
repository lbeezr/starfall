# Local playtest observations

Prepared 16 October 2026. **No sessions have been run and no human results are supplied.** The [blank CSV](../../tools/playtest-results/blank-observations.csv) has six anonymous ID slots and empty observation cells. This small local tool transcribes the structured parts of [FIRST_PLAYTEST_PROTOCOL.md](FIRST_PLAYTEST_PROTOCOL.md) and the supplementary reachable R1 probe in [PLAYTEST_KIT.md](PLAYTEST_KIT.md). It does not recruit, record, send data, run the game or decide a design change.

## Use

Python 3.9+ and its standard library are sufficient; there are no packages to install. From the repository root:

```sh
cp tools/playtest-results/blank-observations.csv /tmp/starfall-observations.csv
# Edit the copied CSV locally after an authorized session.
python3 -B tools/playtest-results/summarize.py /tmp/starfall-observations.csv --validate-only
python3 -B tools/playtest-results/summarize.py /tmp/starfall-observations.csv > /tmp/starfall-summary.json
```

Use a durable local location outside the repository for real notes; `/tmp` above is only a disposable working example. Keep the blank source template blank. Each input row represents one anonymous participant's session, with a unique `P1`–`P999` ID. Mark `session_state=observed` and `evidence_kind=human` only for an actual observed human session. A planned row has only its ID and optionally `session_state=not_started`. Use `synthetic` for fictional exercises; the output places those in `synthetic_not_human_results`, never human results. Author-supplied labels cannot authenticate evidence.

The command reads the input without modifying it and prints JSON to standard output. Validation errors exit with status 2 and no summary; do not use a redirected output after a failed command. A valid blank template reports six blank slots, zero human observations, zero synthetic records, and no assessed outcomes. Validation proves record consistency, not that a session occurred or that a recorded board was reachable.

The exact 33-column schema is [schema.json](../../tools/playtest-results/schema.json). Keep every column exactly once; header order may change. Extra columns, duplicate IDs, malformed CSV, unknown enum values, noninteger/out-of-range ratings, malformed dates/source hashes and contradictory records are rejected. Leading/trailing cell whitespace is ignored. No personal names, contact details or free-text fields are accepted. Keep anonymous qualitative notes, exact help, predictions, reasons/quotes, access preferences, device/OS, and build context on the protocol or kit's existing local observation sheet, using the same ID; do not discard them because they are absent from this numerical summary.

## Record the observed state

Every measurement can be blank: blank means missing, never failure. `not_observed` means explicitly not observed. `unavailable` on a planning probe means the representation was not accessible enough to assess, as described in the protocol; preserve the barrier in the anonymous notes. `not_asked` is available for stated replay interest. These states remain distinguishable in the summary. Do not translate unavailable or unfinished tasks into failed tasks.

| Columns | Meaning and allowed values |
| --- | --- |
| `participant_id`, `evidence_kind`, `session_state` | Anonymous ID; `human`/`synthetic`; `not_started`/`observed`. An observed session must declare evidence kind. |
| `first_time`, `session_date`, `build_source_sha` | `yes`/`no`/`not_observed`; optional `YYYY-MM-DD`; optional full lowercase Git source SHA. Use the actual authorized build's source, not a proposed build. |
| Four `comprehension_*` fields | `3plus`, `orthogonal`, `goal`, `moves` each use `unaided`, `assisted`, `not_understood` or `not_observed`. Record understanding after onboarding, preserving which rules needed factual assistance. |
| `choice_options`, `choice_reason` | At one naturally observed choice: `multiple` independent legal groups, `forced` or `not_observed`; stated reason before its result is `current_size`, `correct_survivors`, `other` or `not_observed`. A guessed future refill is not a correct visible-survivor reason. |
| `recovery_seen`, `recovery_understanding` | `yes`/`no`/`not_observed`; `understood`/`not_understood`/`not_observed`. Understanding concerns the actual free replacement observed live; it cannot be assessed here without `recovery_seen=yes`. |
| `round_status`, `score_at_stop`, `moves_at_stop` | State of the index live round before the free-choice action: `unfinished`/`won`/`lost`/`not_observed`; score 0–118 and moves remaining 0–18, or `not_observed`. Leave unavailable measurements absent. |
| `replay_time`, `replay_action` | Time for a new round after an ending: `available`/`unavailable`/`not_observed`; actual action `new_round`/`continue`/`stop`/`not_observed`. An unfinished round can be continued or restarted, but neither counts as post-ending replay. |
| `replay_start_independent` | `yes`/`no`/`not_observed`, only for an actual `new_round` start. A free choice after the protocol's neutral prompt may be independent; a moderator-directed start is `no`. If independence was not observed, leave it unassessed. |
| `stated_replay_interest` | `yes`/`no`/`unsure`/`not_asked`. Record what was said independently of what was done; apparent disagreement is not a validation error. |
| `planning_a`, `planning_b` | `pass`/`fail`/`not_observed`/`unavailable` for the protocol's synthetic A then B boards. Apply its survivor/second-move/unknown-refill answer criteria; selecting a triple alone is not a pass. |
| `a_extra_help`, `b_extra_help` | `yes`/`no`/`not_observed` for assistance beyond the standard probe prompt; classify `yes`/`no` only when that probe was assessed. A blank or unknown help classification does not establish unaided performance. |
| `gravity_explanation` | The prescribed explanation offered between A and B: `accepted`/`declined`/`not_offered`/`not_observed`. Record extra coaching separately; acceptance does not imply a successful transfer. |
| `r1_recognition` | `observed`/`not_yet`/`not_observed`/`unavailable`, using the reachable card's moderator rubric. This is a separate supplementary position, never another A→B trial. |
| `r1_prior_ab`, `r1_prior_explanation`, `r1_extra_prompt` | Each `yes`/`no`/`not_observed`; record prior A/B exposure, prior gravity explanation and extra prompting for R1. Classify the extra prompt only when R1 was assessed. |
| `satisfaction`, `control`, `calmness` | Each integer 1–5 or `not_observed`; blank is missing. Preserve the moment behind the rating in the notes. These are informal ratings, not clinical measures. |

Record `first_time=yes` only when known. The protocol concerns first-time players: returning and unclassified sessions are counted as excluded, and their original CSV records remain intact. Their observations are not silently pooled into the protocol rates.

Round consistency checks use the unchanged 7×7 / 3+ / 70 in 18 rules. A known score must be zero or at least three, even when moves or outcome were not observed. A win needs at least two moves and at least 70 cleared pieces; a loss has zero moves and at least 54 cleared pieces. The largest possible final score is 69 + 49 = 118. An unfinished round must have moves left and score below 70. When both score and moves are present, cleared pieces must lie within three to 49 per valid move. A last-move win is accepted. These necessary checks do not certify that a particular trajectory exists, infer missing measurements, or require manufacturing an ending.

## Read denominators with coverage

All rates are descriptive. Each rate contains its numerator and **actually assessed denominator**, with `percent=null` at zero denominator. Missing opportunities and incomplete assessments are reported separately. No threshold, release, tuning, recruitment or retention decision is generated. The protocol's six-person hypotheses remain unevaluated when the required observations are missing; a high percentage from a smaller assessed subset is not a six-person result.

- **Comprehension:** the denominator includes only sessions with all four rules assessed. Fully unaided understanding, understanding with some assistance, and explicit incomplete understanding are separate; incomplete assessment is another count. Individual rule frequencies retain partial observations.
- **Meaningful choice:** the rate includes only observed multiple-option decisions with an assessed reason. Forced choices and unassessed reasons are shown separately, so neither becomes a strategy failure.
- **Recovery:** exposure and assessment are separate. The numerator is understood, the denominator is live observers whose understanding was assessed, and unassessed live observers are counted. Three assessed observers are the minimum context flag.
- **Replay:** eligibility requires a completed round and time available. The rate uses eligible participants whose actual stop or new-round start and independence were assessed. Directed starts are separate from independent starts; unknown independence remains unassessed. Continuing or restarting an unfinished round, absent time, unknown time and stated interest each have separate counts. Four assessed eligible participants are the minimum context flag.
- **A→B:** B passes without extra help use assessed B results explicitly marked `b_extra_help=no`. Paired transitions additionally require assessed A and `a_extra_help=no`; help or unknown help on either probe excludes the pair. Accepted, declined, not offered, not observed and missing explanation groups remain separate. Each group reports initial failures, missing/helped follow-ups, all paired transitions and initial-fail→B-pass n/N. Three assessed initial-failure pairs are the minimum context flag for that last descriptive rate. Self-selection and closely related boards prevent a causal teaching claim.
- **R1:** raw recognition/history/prompt counts stand alone. R1 does not enter A/B denominators, replace unavailable transfer data or demonstrate general planning mastery.
- **Ratings:** each rating has its own assessed denominator, median and value frequencies, including missing and explicitly not observed. Missing ratings never become zeros.

`minimum_assessed_for_protocol_context` is a coverage label, not a success criterion: six for comprehension, multiple-option choices and B, three for recovery and each initial-failure transition group, four for replay. Stated-interest percentages have no protocol sample threshold and need at least one assessed response simply to describe a proportion. `insufficient_evidence` flags fewer than the listed assessed count; `descriptive_only` does not establish the protocol hypothesis, human fun, accessibility usability, retention or a teaching effect. Inspect raw counts, exclusions and the anonymous notes together.

## Verification and scope

```sh
python3 -B -m unittest discover -s tools/playtest-results -p 'test_*.py' -v
python3 -B tools/playtest-results/summarize.py tools/playtest-results/blank-observations.csv --validate-only
```

Executed locally: **15 tests passed**. They cover empty observations, human/synthetic partitioning, first-time eligibility, complete/partial/assisted comprehension, forced choices, recovery exposure, replay action/time/independence, unavailable probes, A/B help and explanation grouping, separate R1, missing ratings, invalid input, contradictions including impossible scores with missing moves, a last-move win and repeatable JSON output. Populated fixtures exist only in temporary test directories and are fictional, including the explicitly labeled tests of the `human` branch. No filled result sheet is shipped. No simulator/device, game UI or human validation was run for this tool.

This batch consists only of [schema.json](../../tools/playtest-results/schema.json), [blank-observations.csv](../../tools/playtest-results/blank-observations.csv), [summarize.py](../../tools/playtest-results/summarize.py), [test_summarize.py](../../tools/playtest-results/test_summarize.py), and this document. The next evidence step is an authorized human session using the existing protocol and accessible materials, followed by transcription of only the events actually observed. Bots and deterministic studies cannot fill any human observation field.
