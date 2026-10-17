# Core regression tests

Deterministic behavior, save validation and replay checks for StarfallCore.

## Start here

Run `swift test` from the repository root. Use focused fixtures for changed behavior and preserve old-save coverage. These results do not establish native or visual acceptance.

`FallingSkyPacingTests` compares new and historical cadence across 200 seeds, including first-wave clearing, save round trips and unchanged seeded arrivals.

`SkyCadenceTests` covers timing versions, legacy restore/replay, balance and First Light.
`TimingCycleFixture.swift` is a thin compatibility adapter to the production Core cadence.
Use the [adoption contract](../../docs/design/PACING_ADOPTION.md) for current behavior.

New skies use production Core `announcedCycleV1`. The historical timing fixture is now a thin adapter to Core, not a second algorithm; old timing versions and First Light remain covered.
