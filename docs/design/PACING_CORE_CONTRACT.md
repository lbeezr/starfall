# Cadence consumer contract

**Adoption update:** The user selected B for production. [Current contract](PACING_ADOPTION.md) supersedes the test-only policy boundary below; historical timing/indexing and observation details remain context.

**Status:** Accepted contract; Core and build checks passed · **Owner:** task 2 · **Updated:** October 17, 2026

Core exposes versioned timing without changing generation or player settings. Policy B remains a test-only fixture; the production game retains its existing opening and cadence. This implements the Core boundary of the [shared pacing design](PACING_NEXT.md) (original commit `590be47`), not adoption of its comparison.

**Next action:** Tasks 3–5 consume this indexing after the verified Core handoff. Native deadline and cue acceptance remain their responsibility.

## Values and indexing

`SkyCadenceID` has `originalV1` and `openingV1`. Its pure `step(committedShowers:pace:)` returns `SkyCadenceStep` (`delay`, `phase`, `warnsFasterNext`). The count must be nonnegative. `FallingSky.cadenceID` and `cadenceStep` expose the saved game's effective contract; `automaticShowerDelay` delegates to that step.

Every step is the interval **after count n commits, leading to shower n + 1**. `turns` is that count. Manual and automatic showers advance it equally. Clears, wall time, pauses and animation completions do not. Terminal rule calls cannot advance the count. Store remains responsible for freezing scheduling and cancelling deadlines.

| Count n | Next shower | Opening A | Test-only B at brisk |
| --- | --- | --- | --- |
| 0 | 1 | 0.25 s, opening | Same |
| 1–3 | 2–4 | 1.8 s, opening | Same |
| 4–9 | 5–10 | Selected pace, steady | 3 s, steady |
| 10–12 | 11–13 | Selected pace, steady | 2.5 s, faster |
| 13–15 | 14–16 | Selected pace, steady | 3.5 s, breathing |
| 16 onward | 17 onward | Selected pace, steady | Repeat twelve intervals |

B's slot is `(n - 4) % 12` after opening. Only slot 5 warns: first at count 9, before steady shower 10; committing shower 10 starts the faster interval toward shower 11. No warning during opening or non-brisk play. Each full cycle totals 36 seconds. These are interval phases, not generation or wave-composition phases.

## Save, replay and comparison boundaries

New opening skies encode `savedCadence: openingV1` alongside the existing opening marker. Missing cadence markers derive timing from the saved opening marker and saved balance; missing balance retains the historical four-second default. Unknown versions fail decoding; contradictory opening/version markers fail save validation. No legacy save is rewritten merely by reading its timing.

`FallingSky.replay()` resets committed play while preserving seed, challenge, balance, cadence and historical generation markers. Consumers should use this method for same-sky replay instead of reconstructing from today's initializer defaults. No Store changes are included here. First Light continues without opening at its fixed four-second balance.

`TimingCycleFixture` in `Tests/StarfallCoreTests/SkyCadenceTests.swift` owns B's `announcedCycleV1` identity and pure lookup. It delegates the shared opening to Core. B is absent from production policy identities, initializers, persistence and routes. Comparison runners keep B identity in isolated run metadata and apply its lookup to an otherwise unchanged Core game; round trips preserve that game's production state. Adoption would require an explicit production identity/save decision and removal or promotion of this fixture.

Comparison eligibility requires brisk pace. Gentle and steady preserve the selected six/four-second intervals after opening and suppress B phase cues. Switching back to brisk resumes the committed-count slot; no hidden counter or phase reset. Dark-star frequency is independent and never overridden. The opening retains its approved timing at every pace.

## Acceptance and limits

Focused tests cover opening and two full cycles, exact warnings, non-default pace, matched-action generation parity, round trips, both historical timing contracts, historical generation replay, First Light, terminal freezing and invalid versions. Core tests cannot verify native deadlines, gestures, motion, accessibility or enjoyment. No RNG, generator, wave-size or dark-frequency rule changes are included.

[Verification summary](../evidence/pacing-core-2026-10-17/README.md) records source, commands and native acceptance limits.
