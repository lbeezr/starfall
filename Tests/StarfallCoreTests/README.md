# Core regression tests

Deterministic behavior, save validation and replay checks for StarfallCore.

## Start here

Run `swift test` from the repository root. Use focused fixtures for changed behavior and preserve old-save coverage. These results do not establish native or visual acceptance.

`FallingSkyPacingTests` compares new and historical cadence across 200 seeds, including first-wave clearing, save round trips and unchanged seeded arrivals.

`SkyCadenceTests` covers timing versions, legacy restore/replay, balance and First Light.
`TimingCycleFixture.swift` is a thin compatibility adapter to the production Core cadence.
Use the [adoption contract](../../docs/design/PACING_ADOPTION.md) for current behavior.

New skies use production Core `announcedCycleV2`; explicit V1 saves retain their timing. The historical timing fixture is now a thin adapter to Core, not a second algorithm; old timing versions and First Light remain covered.

The seeded Opal planning regression checks both ordinary two-clear orders, exact rewards, Orb consumption, unchanged preview/turn count and save round-trip.

The current gravity/Opal planning fixture checks both ordinary tap orders and the stronger traced follow-up, field closure, retained Opal, stable preview and exact save round-trip.

`GravityOpportunityTests` covers expanded calm-window supply, one committed offer per cycle, opening/First Light, save continuation/replay, and a naturally replayed two-clear example. `GravityTests` retains the original generation-2 supply assertions separately.

`DuskFeedingTests` covers feeding, starvation, zero rewards, simultaneous targets, orbit captives, loss conservation and save/replay compatibility. `DuskPlanningCompatibilityTests` records the changed reward expectations for existing Opal/magnetic choice fixtures under the adopted rule.

Gravity specials are retired from normal play. `SkyGeneration.standardSky` supplies ordinary/Opal/storm play; `FallingSky.removingGravity()` retires validated historical specials without changing survivor identities, score, RNG, cadence or outcomes. The store applies it on restore and same-sky replay, persisting only on activation/commit. Historical raw rules and reset-only Debug fixtures remain regression tooling; the normal app never routes into them. See [removal evidence](../../docs/evidence/gravity-removal-2026-10-17/README.md).
