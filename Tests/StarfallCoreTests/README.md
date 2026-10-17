# Core regression tests

Deterministic behavior, save validation and replay checks for StarfallCore.

## Start here

Run `swift test` from the repository root. Use focused fixtures for changed behavior and preserve old-save coverage. These results do not establish native or visual acceptance.

`FallingSkyPacingTests` compares new and historical cadence across 200 seeds, including first-wave clearing, save round trips and unchanged seeded arrivals.

`SkyCadenceTests` covers timing versions, legacy restore/replay, balance and First Light.
`TimingCycleFixture.swift` owns candidate B (`announcedCycleV1`) solely in test support;
its identity belongs in comparison metadata, never normal saved skies. See the
[consumer contract](../../docs/design/PACING_CORE_CONTRACT.md) for indexing and adoption limits.
