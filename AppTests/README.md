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

Gravity integration uses the normal target and v5 committed archive. Core owns occupied orbit supports and saved `gravityOrbits` supply; retained generations remain unchanged. `GravityStoreTests` covers committed saves and interrupted phases; Debug reset-only histories support native verification. See [the integration plan](../docs/design/GRAVITY_MECHANICS_PLAN.md).

The Opal planning deadline regression preserves the four-light follow-up across one faster shower deferred by clear presentation, and checks exact Core equality and no catch-up.

Touch-lifecycle checks exercise edge-release classification, missing move callbacks, duplicate terminal events, hold tickets/near-deadline grace, and actual surface configuration cancellation. These do not fabricate UIKit touches or claim physical multitouch acceptance.

Camera placement tests distinguish full canvas dimensions from safe-area-reduced dimensions and reject width, height, orientation, inset and accessibility mismatches for both checked profiles. Native checks must additionally verify which route actually draws.

`NativeInputWindowTests` uses the real scheduler and SpriteKit scene in a visible isolated test window to measure Store input admission through an automatic storm. It is native presentation timing, not a finger-latency or human-preference result; full-motion checks skip under active system quiet accessibility modes.

Gravity overlap checks share the natural seed setup and verify airborne/phase concurrency, receiver response after movement, landing order, body identity, replacement/quiet parity and a bounded nominal fast-shower presentation budget; real input-window reports remain timing observations rather than reaction-time assertions.

The current Opal/orbit planning deadline test commits the field-releasing clear, delivers exactly one due recovery shower, then commits the curved six-light trace through the snapshot/generation boundary. It checks exact Core equality and does not model finger timing.

`GravityOpportunityStoreTests` verifies that retained gravity-generation saves/replay stay unchanged while New sky selects expanded opportunities, rejects gravity generations in v4 envelopes before specials arrive, and checks committed fixture saves and stale completion rejection.

`ResponsiveInputTests` covers independent presentation/save ownership, current gravity reservations, anchored drift, held contact and stale result dialogue. `StarCastTests` verifies that a real independent clear does not cancel an unrelated falling animation.

SkyDialogueTests covers the committed-score/visible-message boundary: prior help persists until presentation completion, then exact clear feedback appears, while restoring the committed round discards transient copy.

`DuskProductionTests` covers committed collapse/save before animation, stale callbacks, v5/v6 adoption into v7, zero-reward clears, gray materials, warning stages and sampled full-motion infall/arrival.

Gravity specials are retired from normal play. `SkyGeneration.standardSky` supplies ordinary/Opal/storm play; `FallingSky.removingGravity()` retires validated historical specials without changing survivor identities, score, RNG, cadence or outcomes. The store applies it on restore and same-sky replay, persisting only on activation/commit. Historical raw rules and reset-only Debug fixtures remain regression tooling; the normal app never routes into them. See [removal evidence](../docs/evidence/gravity-removal-2026-10-17/README.md).

`SkyTechniqueStoreTests` checks exact-recipe relay feedback, exchange ownership, current saves/deadlines, interrupted/stale inputs, Dusk reward columns, non-saving fixtures and sampled full/quiet exchange motion.

`TraceInputPolishTests` also separates early drawing preview from small tap drift, verifies sticky neighbor selection, and checks constellation starts across the native target rather than an inset circle.

`StarlightCelebrationTests` covers concurrent receipt replacement, current save restore, rewarding Opal/drained Dusk distinctions, zero-reward clears, validated trace/recipe/relay categories, interruption and independent expiry.
