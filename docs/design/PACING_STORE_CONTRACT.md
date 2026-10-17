# Store cadence and comparison boundary

**Adoption update:** The user selected B for production. [Current contract](PACING_ADOPTION.md) supersedes the test-only policy boundary below; historical timing/indexing and observation details remain context.

**Status:** Ready for review · **Owner:** task 3 · **Updated:** October 17, 2026

The store consumes Core cadence without adopting candidate B. Production retains its current opening, selected balance, historical restores and First Light. Same-sky restart uses Core's `replay()` so saved cadence and generation markers survive.

**Next action:** Cue and measurement work consume the interfaces below; native acceptance and human comparison remain separate gates. See [Core indexing](PACING_CORE_CONTRACT.md).

## Cue interface

`nextShowerCadence: SkyCadenceStep` is the immutable interval/phase/warning value leading to the next shower. `showerInterval` delegates to its delay. It refreshes after a committed shower, balance change or new/replayed sky, before arming the deadline. Clears, presentation completions and pauses do not advance it. During overdue deferral it still describes the due shower, until that shower commits. `nextShowerDate` remains the existing wall-date display adapter; measurement uses the injected monotonic clock instead.

One cancellable deadline remains authoritative. A late callback delivers at most one shower. Busy presentation retains one due flag and its original deadline, then delivers once when ready. The next interval starts at commitment, never at animation completion. Pause/background/settings cancel both scheduled and due work, retaining the existing remaining-time floor. No trace grace or finger-down pause is added.

## One test-only entry

Debug-only `configureTimingTest(lookup:observe:)` installs an optional pure lookup and synchronous observer before activation, while suspended and paused. An alternate lookup additionally requires zero committed showers. It applies only to opening-version nonchallenge skies; historical cadence and First Light cannot be overridden. Selection is neither saved nor available through launch arguments, settings or production routes. Release excludes this entry and observation types. Restored games can attach observation alone.

Candidate B has one implementation: `Tests/StarfallCoreTests/TimingCycleFixture.swift`, identity `announcedCycleV1`. SwiftPM discovers it in the Core test target; the Xcode project explicitly compiles the same source in **StarfallAppTests only**. Neither production target links it. Hosted consumers use:

```swift
store.configureTimingTest(lookup: {
    TimingCycleFixture.step(committedShowers: $0.turns, pace: $0.balance.pace)
}, observe: { event in /* test-owned recording */ })
```

Offline tools compile that exact source alongside their runner and link/import `StarfallCore`; no XCTest dependency is required. For existing single-module tools, the conditional import also permits `swiftc -O Sources/StarfallCore/*.swift Tests/StarfallCoreTests/TimingCycleFixture.swift /tmp/main.swift -o /tmp/pacing-runner`, with their own runner at `/tmp/main.swift`. An isolated native candidate export may explicitly add the same file to its exported app target and call this Debug entry before activation. Record identity and source hash in export/run metadata. Do not add fixture membership to the normal app or copy its algorithm. A Release candidate export needs its own explicit export-only adaptation; normal Release has no override.

## Observation semantics

`TimingEvent` contains a kind, immutable `TimingSnapshot`, and `showerDeadline`. There is no production logging, store-owned event buffer or second scheduler. Callbacks must not mutate/reenter the store. Task 5 owns bounded recording and opportunity calculations using Core legal actions.

- `scheduled`, `due`, `deferred`, `cancelled` describe scheduling transitions. `due` is callback time, which can exceed the deadline. `deferred` means a busy presenter blocked delivery.
- `automaticShower` and `manualShower` mark committed showers. Automatic events retain the **original** `showerDeadline`, even though their snapshot already contains the next interval/deadline. Manual events have no source deadline. Count and board are committed; persistence/presentation follow synchronously.
- `tapAccepted` and `traceAccepted` mark successful rule commits. Invalid or blocked inputs produce neither.
- `invalidated(reason)` marks generation invalidation (`clear`, `automaticShower`, `manualShower`, `pause`, `suspension`, `restart`, `balance`, `motion`, `fixture`, `challenge`, or `presentation`). Multiple invalidations can share a timestamp. This establishes ticket invalidation, not proof of a real finger gesture or a completed trace. Settings/background share suspension because their distinction belongs to the caller.
- `state` records stable input gates after presentation entry/completion, pause, suspension, balance, restart or settlement; tracing changes also emit it. Nested synchronous transitions may share timestamps. For elapsed input availability, use the last state at a timestamp, not intermediate scheduling/invalidation snapshots. Do not treat a pre-presentation commit event as an input window.

Snapshots include monotonic `time`, Core `game`, next `cadence`, `scheduledDeadline`, `rainDue`, `busy`, `paused`, `suspended`, `inputGeneration` and exact gates. `canClear` includes paused manual play; `canTap` additionally excludes tracing. `canCallShower` requires idle, nonsuspended, nonterminal state. Task 5 must exclude paused/suspended intervals from automatic-play rates and track actual traces in its input harness.

## Acceptance

Focused hosted checks must establish exact candidate slots/warning, manual phase advancement, correct cue before scheduling, due-versus-delivered timing, busy deferral without catch-up, trace invalidation, historical/First Light isolation and same-sky replay. Existing interruption checks cover settings, pause, restart, terminal freeze and stale completions. Core tests and Debug/Release builds must pass after fixture extraction. Native touch, full-motion visuals, accessibility and human preference remain task 6 acceptance; no new visual behavior is claimed here.
