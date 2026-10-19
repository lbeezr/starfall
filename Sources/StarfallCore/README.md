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

Fresh survival uses Core `freshSurvival` and the existing `announcedCycleV1` rhythm (six 3-second, three 2.5-second and three 3.5-second intervals), adopted after [native implosion-window checks](../../docs/evidence/calibration-critical-mass-2026-10-18/ADOPTION.md). The historical timing fixture is now a thin adapter to Core, not a second algorithm; old timing versions and First Light remain covered.

Gravity integration uses the normal target and v5 committed archive. Core owns occupied orbit supports and saved `gravityOrbits` supply; retained generations remain unchanged. `GravityStoreTests` covers committed saves and interrupted phases; Debug reset-only histories support native verification. See [the integration plan](../../docs/design/GRAVITY_MECHANICS_PLAN.md).

Debug-only `opalPlanning` replays seed 10 through shower 12 to expose a two-tap allocation choice without injected board or save fields.

Debug-only `opalStormPlanning` replays current gravity-generation seed 180 through shower 12. It contrasts spending Opal with releasing an occupied field: two ordinary taps total six versus eight light, while a curved five-star trace raises the released branch to nine. It preserves the earlier `opalPlanning` historical-generation regression.

`SkyGeneration.gravityOpportunities` extends pair eligibility to calm waves seven or eight. Generation 2 retains its eighth-wave supply. The committed pair blocks the following offer, so there is at most one per cycle; all existing geometry/special/relief skip conditions remain. `GravityOpportunityFixture` replays the natural candidate history only in Debug, without authored state injection.

Gravity specials are retired from normal play. `SkyGeneration.standardSky` supplies ordinary/Opal/storm play; `FallingSky.removingGravity()` retires validated historical specials without changing survivor identities, score, RNG, cadence or outcomes. The store applies it on restore and same-sky replay, persisting only on activation/commit. Historical raw rules and reset-only Debug fixtures remain regression tooling; the normal app never routes into them. See [removal evidence](../../docs/evidence/gravity-removal-2026-10-17/README.md).

`StarRecipe.swift` adds bounded exact square/cross discovery and four-direction landed-star exchanges, including same-family identities. It reuses current Opal family matching, selected-walk validation and committed clear/settle rules. New actions do not draw RNG or change the save schema; First Light keeps its existing trace rules without recipes or exchanges. `SkyTechniqueExample.swift` contains authored Debug-only, non-saving review positions.

`DuskRule` preserves historical three-feed replay and marks current five-feed skies explicitly. `adoptingFeedingDusk()` retains committed stars, feed counts, reward loss, forecast and seeded state; Core never advances feeding from elapsed animation time.

`canStartConstellation(at:)` is the shared eligibility query for native target admission and transient intent. It preserves colored-first, five-star and exact-square rules without changing selected-set validation or saves.

`CriticalMassRule` retains historical aging as version 1; version 2 disables aging, clears saved visual ages and preserves the no-Dusk generator and lost-light accounting. `freshSurvival` selects version 2; the app migrates restored version 1 rounds before presenting them. `FallingSky` owns ages, stage-three targets, simultaneous stage-four collapse, lost-light conservation and before-arrival settling. `CriticalMassFixture` is reset-only Debug review tooling; retained rounds and First Light do not adopt aging.

`canLinkConstellation` owns adjacent/one-empty-midpoint geometry for eligibility and selected prefixes; family anchoring and ordinary tap groups remain separate.


`HistoricalGravityState` contains historical collision, orbit rotation/release and validation using only board/orbit/identity-accounting values. `FallingSky` keeps every encoded field and applies the returned state at the existing committed boundary. Current and retained games share `SkyBoardSettling` for stable compaction, including occupied anchors. `SkyPresentationPhase` names committed collapse/orbit snapshots; `GravityPhase` and `FallingSkyTurn.gravityPhases` remain compatibility aliases for retained tools. No archive layout or RNG change accompanies this extraction.

Terminal overflow is committed history. Gravity retirement may compact a losing column; existing retired-mass accounting preserves that outcome without reopening play. Ordinary unretired saves still validate full-column overflow. See [terminal migration coverage](../../docs/evidence/debt-third-pass-2026-10-18/README.md#1-terminal-gravity-retirement).

`SkyLesson` supplies four fixed Help examples and their explicit moves in Debug and Release. Every move calls existing swap, tap or constellation rules; examples own no save, clock, progression or random generation.
