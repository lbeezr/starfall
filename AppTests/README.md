# Hosted app tests

Native tests for stores, presentation and materials that require Apple frameworks.

## Start here

Use the Starfall Xcode scheme and the relevant test identifiers. Pure package tests do not execute this suite; retain source-bound native results.

Constellation regressions cover chosen-set clearing, replay, bounded effects and stale input across interruption boundaries, with the original ordinary tap API retained.

`FallingSkyStoreTests` covers fresh opening cadence and clearing, alongside historical saved-clock, interruption and replay regressions.

Cadence scheduling tests reuse `Tests/StarfallCoreTests/TimingCycleFixture.swift` through explicit hosted-only target membership. The [store contract](../docs/design/PACING_STORE_CONTRACT.md) defines cue and test observation semantics; B is absent from normal app targets.

`SkyShowerPlacementTests` (in `ObservatoryGeometryTests.swift`) checks the calibrated camera profile and conservative hardware, inset, orientation and accessibility fallback. It does not prove physical cutout alignment.
