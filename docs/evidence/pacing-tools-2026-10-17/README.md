# Measure pacing with explicit action time

**Result:** Partially verified · **Owner:** task 5 · **Date:** October 17, 2026

The bounded offline runner exercises the unchanged Debug Store and real trace intent, while presentation and reaction durations remain explicit models. This evidence cannot establish native animation quality or human enjoyment. Candidate B is test-only; no production routing, rules, app identity or save contracts changed.

**Next action:** Use the comparison and counterexamples to select native play scenarios; retain A pending the separate native and human comparison.

## Scope and reproducibility

Run `python3 tools/mechanics/compare-pacing.py --seeds 16 --seconds 120` from repository root on macOS with Xcode tools. [Tool documentation](../../../tools/mechanics/README.md#pacing-comparison) defines policy visibility, durations, metrics and output schemas. The shared candidate fixture is compiled directly. No native exporter or app selector is added.

**Source:** `3c09532d78400f877b4961073de05de3afa33828`, plus only `tools/mechanics/Pacing*.swift`, `compare-pacing.py` and tool/evidence documentation. Raw `artifacts/pacing/source.json` records exact SHA-256 inputs and toolchain; raw outputs remain ignored. No App/Core/project edits are included.

## Verification and limits

- Core: `swift test` passed 72 tests with zero failures.
- App compile: Debug generic iOS Simulator build passed with isolated `artifacts/pacing-build` DerivedData and signing disabled. Simulator SDK 27.1; no simulator was booted or app installed by this task.
- Harness: 192 runs (seeds 0–15 × A/B × three personas × two presentation models), capped at 120 active seconds or terminal state. All 8,765 commits passed same-action A/B generation replay and save-invariant checks. Controlled Store checks cover one overdue deferral/delivery without catch-up, suspension, paused manual shower, invalid empty-board tap, pause/stale deadline, and valid versus stale-generation trace release. A second complete run produced byte-identical `runs.json` and `summary.json`.
- Native interaction/visual/animation, settings dismissal, Dynamic Type, actual VoiceOver, physical device and human preference: not run. Release: not run; no production membership/routing/resources changed.
- Rule/save changes: inapplicable; runner validates every replayed committed save and does not touch normal saves. Paused/manual/menu/background sessions are excluded from persona comparison; their behavior is not inferred from automatic rates.

Initial harness failures were compilation assumptions (the older shared fixture needs a temporary module import; runner visibility needed adjustment), a trace-test integer type annotation, followed by a terminal-state check attempting to clear after overflow. These were tool failures, corrected without changing runtime assertions or Core behavior.

## What the model found

First accepted clear was **1.70 s** in every full-motion run and **0.85 s** in every quiet run, for both A and B. The shared opening explains the identical policy result. Longest input-enabled no-opportunity gap in the first 30 seconds had median **2.18 s** full-motion and **2.85 s** quiet, again unchanged between A/B. Presentation occupied roughly **47–48%** of full-motion active time versus **8.6%** quiet. Removing presentation gates exposes more input-enabled empty-opportunity time; the quiet model's higher no-opportunity fraction is not evidence of worse play.

Each table value is a per-round median, except cancellations, which pool actual started gestures across the 16 seeds. Rates use each round's active time, including presentation. A → B compares cadence policies within the same presentation model.

| Model / persona | Accepted clears/min, A → B | Accepted traces/min, A → B | Deadline-cancelled / started traces, A → B |
| --- | --- | --- | --- |
| Full / largest-clear | 12.32 → 12.35 | 1.02 → 1.18 | 46/66 → 40/69 |
| Full / height-safety | 12.32 → 12.37 | 1.02 → 1.00 | 47/70 → 33/60 |
| Full / trace-oriented | 12.30 → 12.24 | 1.18 → 1.58 | 53/78 → 44/80 |
| Quiet / largest-clear | 13.50 → 13.50 | 1.56 → 1.57 | 0/36 → 1/37 |
| Quiet / height-safety | 13.50 → 13.50 | 1.56 → 1.57 | 0/36 → 1/37 |
| Quiet / trace-oriented | 13.50 → 13.50 | 1.64 → 1.64 | 0/41 → 1/43 |

The full-motion model delivered some showers up to **0.55 s** after their original deadlines because of busy presentation. These are real Store deferrals under modeled presenter completion. Raw events retain original deadline, callback time, delivery, phase, gates and invalidation separately. The synthetic held-presenter check also exercises a much longer deferral without queued catch-up; it is outside the persona statistics.

**Counterexample:** full-motion height-safety, seed 11: B delivered 19 accepted clears versus A's 20, with no deadline-cancelled traces in either. B spent 39.34/93.78 active seconds without a legal opportunity (41.9%), versus A's 34.23/88.09 (38.9%). Both overflowed. B produced 24 growth events versus A's 20; both reached height seven and zero incoming-column headroom. Thus changing only cadence can change actions, relief, later arrivals and pressure; matching seeds does not imply matched streams.

Seed 0 gives a different tradeoff: full-motion height-safety B lasted 118.52 s versus 63.07 s and accepted 21 clears versus four, yet its no-opportunity fraction increased from 10.4% to 31.6%. Neither survival nor total idle seconds alone gives an interpretable adoption decision. Raw summary includes active-time differences and rates beside paired counterexamples.

These policies use deterministic full-component walks, not optimal five-star subsets, so cancellation counts should select native trace scenarios rather than be treated as human failure rates. They do not read the cue or model intentional use of a breathing passage. Native comparison should include seeds 0 and 11, full-motion near-deadline traces, and an explanation of a deliberate clear in the breathing window. This tooling supplies no reason to adopt B without that separate acceptance.

Documentation links were inspected as text; rendered Markdown was not reviewed. No screenshots are relevant to this text-only tooling record.

## Retained output fingerprints

Two final runs used the same source bytes and passed all focused checks. SHA-256 fingerprints (raw files remain ignored):

- `runs.json`: `d6ee48dd1d735d6d7f5e60c30e877b398317343c0163fb44c13a73a83fc5ed9d`
- `summary.json`: `654f991d844298e75e48c5ab04bada46719d9fc591fdb19c114cef8114c22a01`

Repeat command: `python3 tools/mechanics/compare-pacing.py --seeds 16 --seconds 120 --output artifacts/pacing-repeat`. Compare with `cmp artifacts/pacing/runs.json artifacts/pacing-repeat/runs.json` and the corresponding summary files. Source metadata differs only in invocation/output context; measurement files are deterministic. Environment: macOS 27.0.1 (26A434), Apple Swift 6.4, Debug Store with an unoptimized instrument harness and optimized unchanged Core; no simulator OS run.
