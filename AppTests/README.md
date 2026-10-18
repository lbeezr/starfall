# Hosted app tests

Native tests for stores, presentation and materials that require Apple frameworks.

## Start here

Use the Starfall Xcode scheme and the relevant test identifiers. Pure package tests do not execute this suite; retain source-bound native results.

Constellation regressions cover chosen-set clearing, replay, bounded effects and stale input across interruption boundaries, with the original ordinary tap API retained.

`FallingSkyStoreTests` covers fresh opening cadence and clearing, alongside historical saved-clock, interruption and replay regressions.

Cadence scheduling tests reuse `Tests/StarfallCoreTests/TimingCycleFixture.swift` through explicit hosted-only target membership. The historical [store contract](../docs/design/PACING_STORE_CONTRACT.md) defines observation semantics; current production timing is owned by the [adoption contract](../docs/design/PACING_ADOPTION.md).

`SkyShowerPlacementTests` (in `ObservatoryGeometryTests.swift`) checks the calibrated camera profile and conservative hardware, inset, orientation and accessibility fallback. It does not prove physical cutout alignment.

**Announced cadence adoption:** New skies use production Core `announcedCycleV2` (six 2-second, three 1.7-second and three 2.5-second intervals); the previous B exporter/launch selector is removed. Core owns the sole algorithm. Older saves and same-sky replay retain their version; First Light and fixed gentle/steady settings retain timing. [Current contract](../docs/design/PACING_ADOPTION.md).

`LaunchSurfaceTests` loads the packaged launch storyboard and verifies an opaque dark named background in Light and Dark appearances. It checks resources, not visible launch frames; recordings remain separate evidence.

`SkyFlowStateTests` checks Entry cancellation, duplicate/stale Begin, retained core/ranking bytes, replay generation and pause-preserving Continue. `FallingSkyTestSupport` shares the manual clock/presenter with store tests.

`TraceInputPolishTests` covers coarse/grazing samples, small and large projected boards, spatial misses, branching and stale-generation rejection. Store checks cover the held deadline and resumed remainder.

The Opal planning deadline regression preserves the four-light follow-up across one faster shower deferred by clear presentation, and checks exact Core equality and no catch-up.
