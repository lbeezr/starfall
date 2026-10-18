# StarfallCore

Deterministic rules, seeded randomness and committed save/outcome values, without UI imports.

## Start here

Run `swift test` from the repository root. Preserve replay and old-save invariants when rules, RNG or schema change; see [repository boundaries](../../AGENTS.md).

Constellation walks add explicit five-distinct-star validation and selected-set clearing; ordinary `group`, `legalGroups`, `clear`, save fields and generator relief remain compatible. `ConstellationFixture` compiles only in Debug for deterministic native/core tests.

`FallingSky.automaticShowerDelay` derives the opening cadence from committed shower count. A saved optional cadence marker preserves historical clocks and First Light; the seeded wave generator is unchanged.

`SkyCadenceID.step(committedShowers:pace:)` is the versioned pure timing lookup.
`FallingSky.cadenceStep` describes the interval after `turns`, toward shower `turns + 1`;
`replay()` resets play while preserving cadence, balance and historical generation markers.
Missing cadence markers use the saved opening contract. See the [consumer contract](../../docs/design/PACING_CORE_CONTRACT.md).

New skies use production Core `announcedCycleV2` (six 2-second, three 1.7-second and three 2.5-second intervals). The historical timing fixture is now a thin adapter to Core, not a second algorithm; old timing versions and First Light remain covered.

Gravity integration uses the normal target and v5 committed archive. Core owns occupied orbit supports and saved `gravityOrbits` supply; retained generations remain unchanged. `GravityStoreTests` covers committed saves and interrupted phases; Debug reset-only histories support native verification. See [the integration plan](../../docs/design/GRAVITY_MECHANICS_PLAN.md).

Debug-only `opalPlanning` replays seed 10 through shower 12 to expose a two-tap allocation choice without injected board or save fields.

Debug-only `opalStormPlanning` replays current gravity-generation seed 180 through shower 12. It contrasts spending Opal with releasing an occupied field: two ordinary taps total six versus eight light, while a curved five-star trace raises the released branch to nine. It preserves the earlier `opalPlanning` historical-generation regression.
