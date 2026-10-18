# Native interaction tests

XCTest flows exercising the app through native controls on Apple tooling.

## Start here

Run relevant flows through the Starfall scheme. Keep bounded condition-based waits and isolated test saves. Report actual VoiceOver and full-motion observations separately from automation.

`ConstellationTraceNativeTests` verifies selected five from six, short/outside cancellation, ordinary taps, retained relaunch and largest-text tracing/build metadata in the same Starfall target. Fixtures require Debug and explicit local reset arguments.

`ConstellationTraceNativeTests` now holds an eligible touch across a five-second automatic deadline before dragging and verifies that the chosen five clear. The same suite preserves ordinary tap, Opal and large-text checks. Hosted checks own exact deadline arithmetic.

`testOpeningCascadeAllowsNativeClearBeforeLastWave` verifies an actual clear during the intro with Calm and system Reduce Motion off, restoring the system preference afterward. Inspect recorded motion separately from the tap assertion.

`PacingCueUITests` checks baseline isolation; Historical B flows belong to their recorded exports; current checks use the ordinary app. They cover one-wave warning, faster/breathing labels, Settings dismissal, persistent largest-text cues and system Reduce Motion with restoration.

Its active forecast/phase check verifies the final presentation integration: separate vertical space, conservative B header fallback, accessible forecast value and unchanged native cell frames.

`ShowerForecastInteractionTests` checks production camera/header placement, ordered forecast speech value, menu/background lifecycle and maximum-text fallback. Run it on a calibrated island phone and a non-island phone; inspect the attached captures separately from physical-device acceptance.

**Announced cadence adoption:** New skies use production Core `announcedCycleV2` (six 2-second, three 1.7-second and three 2.5-second intervals); the previous B exporter/launch selector is removed. Core owns the sole algorithm. Older saves and same-sky replay retain their version; First Light and fixed gentle/steady settings retain timing. [Current contract](../docs/design/PACING_ADOPTION.md).

`testOpalPlanningTwoTapOrdersKeepTheirDistinctRewards` compares Amber-first and Aqua-first through normal native taps on the seeded Debug fixture; automation establishes outcomes, not human recognition or timing.

`testTinyEdgeReleaseResumesAutomaticSkyAndOrdinaryInput` uses a native sub-slop drag from an eligible edge star and waits for a committed new-family arrival, then checks menu dismissal.

`testAutomaticStormCountsRecoverWithoutManualShowersOrClears` observes the complete three-heavy count and recovery using the actual automatic clock; it establishes sequence delivery, not a player reaction-time or preference result.
