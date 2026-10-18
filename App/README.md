# iOS application

SwiftUI screens, main-actor stores and SpriteKit presentation for the native game.

## Start here

Deterministic rules belong in [StarfallCore](../Sources/StarfallCore/README.md). Build the shared Starfall scheme and run affected hosted/UI checks after source changes. Asset catalogs are packaged data; their sets are documented by this folder, not individual READMEs.

Player copy for regular Falling Sky lives in the [local dialogue/interface catalogue](DialogueScripts/README.md), including character voices, menu/help/results and accessibility text. `SkyCopy` exposes typed keys; the shared template validator rejects missing/extra values. Keep wording there and committed facts in the app/Core owners. Debug tooling and the original orthogonal puzzle retain their separate developer text.

## Observatory environment

Default Falling Sky uses the full-screen Observatory. `ObservatoryGeometry` owns artwork/prop registration and every render/touch coordinate; `ObservatoryEnvironment` owns bounded fog time and cancellable prop responses using narrow lifecycle inputs. Theme owns colors; core owns outcomes. The game view resets environment lifetime on replay/new challenge and suspends it under settings/background. Four `Observatory*.imageset` resources are generated art; exact prompts/provenance remain in [the source-art record](../docs/design/environments/landing-native-01/README.md).

`ObservatoryReviewFixture` is compiled only in Debug and requires explicit reset/review arguments. It is native verification tooling, not an alternative game/environment. See [verification commands and boundaries](../tools/environments/README.md). `skyEnvironment` is retired: any retained local value is inert and game saves are untouched.

`FallingSkyHUD` owns the selected transparent score/trail/menu row. [Character dialogue authoring](DialogueScripts/README.md) owns reusable scripts, speaker IDs and the Debug studio; `SkyDialogueBubble` renders one shared native chat surface for gameplay and ceremonies. `SkyTrailMotion` owns the straight/island forecast finish mapping. `FallingSkyMenu` receives snapshots, bindings and narrow actions, with dedicated help/balance pages. The trail reads the existing deadline; it never schedules showers. See [interface contracts](../docs/design/OBSERVATORY_INTERFACE.md).

`StarCast` owns Crystal Glow materials for board, comets, HUD and previews: six packaged bodies, authored faces, shallow turns and a bounded 72-material cache. The scene owns separate contact shadows; their placement follows cached body height and grown size. See the [production contract](../docs/design/star-cast/README.md).

Constellation drawing is now part of FallingSky: transient ordered input lives in `SkyInteractionSession` beside technique selection, the native trace surface shares Observatory geometry with accessible buttons, and the scene presents a bounded trail/burst. Core validates the selected set; ordinary taps retain their original rules. Debug-only reset fixtures are not a second app or a menu route.

The store schedules the core’s persisted opening cadence: four quick waves, then the chosen regular pace. Input opens between settled batches; [opening acceptance](../docs/evidence/opening-cascade-2026-10-17/README.md) records checks and limits.

## Welcome, entry and endings

`LaunchScreen.storyboard` and the opaque `StarfallApp` root share the named `LaunchBackground` color. The static Starfall wordmark uses named `CeremonyGold`; launch has no timed delay or gameplay state. Validate system launch snapshots with an ad-hoc signed simulator product so SplashBoard can validate its resources. Shared build configuration selects the storyboard in Debug and Release; `LaunchSurfaceTests` checks the packaged color and launch declaration.

`SkyFlowState` stages round choices until Begin and rejects duplicate/stale Entry actions. Back discards only that pending choice; Continue preserves the in-memory pause choice, while restored rounds stay paused. `SkyResultSnapshot` explains committed endings after restore; `SkyWelcomeSnapshot` describes the retained round. `SkyPreferences` shares pre-play and game-menu toggles/help without another store or preference key. `SkyFlowCeremony` presents narrow value snapshots and actions over the final board using the shared cast and theme. `FallingSkyView` owns navigation, suspends gameplay under ceremonies and waits for the committed final turn to settle. `SkyCastFormation` owns contained decorative arrival poses. Heading focus and terminal speech have one presentation owner. Reveal tasks belong to screen identity and settle on interruption; they never advance gameplay. See [the flow contract](../docs/design/SKY_FLOW.md).

Ordinary Debug/Release launches open Welcome. Historical `--starfalls-reset` board fixtures still open paused play; add `--sky-flow-review` to test the production welcome flow with isolated `Starfall.SkyFlowReview` defaults. Relaunch with only `--sky-flow-review` to exercise restore. This is Debug verification setup, not a player mode.

The optional `SkyCadenceCue` reads `nextShowerCadence` only. Baseline supplies no cue; candidate copy and a persistent large-text placement do not own scheduling.

`SkyShowerPlacement` selects the calibrated iPhone 17 and iPhone 16 Pro Max portrait camera contours. All other hardware/viewports and accessible layouts use the safe-area header. Both show the same committed ordered forecast through `SkyShowerTrail`; there is no trial flag. [Adoption and device limits](../docs/evidence/shower-forecast-adoption-2026-10-17/README.md).

**Announced cadence adoption:** Fresh survival uses Core `freshSurvival` and the existing `announcedCycleV1` rhythm (six 3-second, three 2.5-second and three 3.5-second intervals), adopted after [native implosion-window checks](../docs/evidence/calibration-critical-mass-2026-10-18/ADOPTION.md); the previous B exporter/launch selector is removed. Core owns the sole algorithm. Older saves and same-sky replay retain their version; First Light and fixed gentle/steady settings retain timing. [Current contract](../docs/design/PACING_ADOPTION.md).

`FallingSkyScene` reports attached, sized presentation readiness. Scene detachment synchronously suspends the store. `SkyFlowState` gates a cancellable 240 ms handoff; scene readiness alone never starts a round.

`ConstellationTraceSurface` owns touch lifetime and coalesced samples; `ConstellationTraceHitTesting` maps continuous segments through the shared projection. The store holds its single shower deadline from eligible touch-down to release/cancel. Spatial misses keep the chosen path; stale state still cancels. The HUD reserves phase-copy space inside the full-window canvas, so it cannot crop scenery or hide the camera inset. Resting star rings are removed; the traced thread and finite sparks indicate selection.

Gravity integration uses the normal target and v5 committed archive. Core owns occupied orbit supports and saved `gravityOrbits` supply; retained generations remain unchanged. `GravityStoreTests` covers committed saves and interrupted phases; Debug reset-only histories support native verification. See [the integration plan](../docs/design/GRAVITY_MECHANICS_PLAN.md).

`ConstellationTouchSession` classifies every final sample, including sub-slop off-board releases and a first drag sample delivered on release. The surface cancels on changed configuration/detachment/multitouch; store-issued hold tickets reject releases from older gestures.

Camera-layout selection reads the full local playfield canvas, beside the consuming overlay. Profiles require complete checked portrait dimensions and inset; resized/unknown/accessible viewports use the header. This is layout approval, not a claim that unknown hardware lacks a camera island.

Attraction fields and gravity holes use `StarCastField`/`StarCastHole` packaged artwork through the shared cast cache, including forecasts and arrivals. Theme supplies their blue-gold light colors; `GravityMotion` supplies finite child-art cues. [Art source and exact prompts](../Artwork/StarCast/README.md#magnetic-crystal-and-gravity-hole); [native visual evidence](../docs/evidence/gravity-art-2026-10-17/README.md).

The magnetic saved role now presents as an **attraction field** using `StarCastField`: an open aura with transparent center, no ground shadow, physical bounce or contact response. The shared material owns board/forecast/flight appearance; existing occupied-cell/collision rules remain unchanged. The original magnetic crystal is retained only as historical source art.

Gravity arrivals share the ordinary flight constructor. StarfallMotion.GravityTimeline owns phase durations and approach overlap; receiver responses and landings follow completed gravity motion. The scene presents committed outcomes and never schedules Core showers.


Gravity supply is versioned by Core. New skies select the current generation; retained skies and replay keep their saved rules. The archive rejects every gravity-capable generation in the older v4 envelope, including the expanded-opportunity generation before any special arrives.

`FallingSkyPresentation` derives the columns reserved by committed turns, using a whole-board reservation for orbit phases. Store and scene allow independent ready actions and reconcile against the newest game. The existing trace surface owns anchored contacts and eligible drag classification; [responsive input](../docs/design/INTERACTION_FEEDBACK.md) defines feedback, lifecycle and verification boundaries.

Grown colored stars carry a luminous double silhouette and paired glints in `FallingSkyCharacter`. Only the outer aura breathes over 2.8 seconds; the rim/body stay steady. The scene and store cancel this decoration for quiet motion, suspension and replacement. [Current pulse verification](../docs/evidence/grown-star-readability-2026-10-17/PULSE.md) distinguishes native checks from human preference.

Gravity specials are retired from normal play. `SkyGeneration.standardSky` supplies ordinary/Opal/storm play; `FallingSky.removingGravity()` retires validated historical specials without changing survivor identities, score, RNG, cadence or outcomes. The store applies it on restore and same-sky replay, persisting only on activation/commit. Historical raw rules and reset-only Debug fixtures remain regression tooling; the normal app never routes into them. See [removal evidence](../docs/evidence/gravity-removal-2026-10-17/README.md).

`SkyTechniqueIntent` owns the transient direct-swap snapshot. There is no Arrange mode, toggle or tap-arrangement panel; recipes use the existing trace input. The existing trace surface owns swipe-and-hold dwell and cancellation, while Core validates and the current store commits/saves/reserves columns. See [technique contract](../docs/design/STAR_TECHNIQUES.md).

`ConstellationTraceSurface.CaptureRecognizer` owns raw physical contact delivery before scroll arbitration, including terminal/reset cancellation. The store owns its ticketed shower hold. `SkySaveArchive` writes v7 and reads retained v3–v6 archives without overwriting their bytes. Current Dusk warnings and marks derive the limit from the saved Core rule.

Drawing starts on the full native star target and follows six-point movement. The touch session separates early preview from sticky drawing intent, preserving small same-cell tap drift without turning partial selections into ordinary clears.

## Starlight celebrations

`StarlightCelebration` presents an already committed award, with immutable pre-clear family/reward contributors and a validated trace/recipe outline. Collection trails inherit the contributing material color and scale with actual awarded points; special callouts enter near the central terrace, while exceptional awards add one translucent aurora. Quiet modes keep a static exact award. See [harvest acceptance](../docs/design/HARVEST_FEEDBACK.md). The store owns its bounded replacement/expiry/cancellation; its overlay uses real board/header/score anchors through a shared registration that preserves nested preferences. Selection and release share recipe drawing order. Ready-column input, current saves, Dusk rewards and dialogue remain independent. Selection uses open sparkle rays; clear bursts use scattered glints without enclosing rings. The quiet overlay owns the same full canvas as normal motion. See [native visibility checks](../docs/evidence/starlight-celebrations-2026-10-18/VISIBLE_AWARDS.md).

`SkyInteractionSession` owns logical trace/swap selection and the held store ticket. Its terminal transition clears local state before releasing exactly once; stale terminal tickets cannot end a replacement contact. The recognizer retains physical-contact ownership, and the store retains clock/generation ownership.

`SkyInputPolicy` gives contact, clear, trace and technique admission the same explicit global/column reasons. Core still decides action legality. Automatic pause permits explicit play; suspension and an already-due shower do not.

Store interruption cleanup has two small boundaries: `interruptPlay` freezes the deadline, then stops feedback and settles; `settleInterruptedPresentation` preserves the deadline for layout/motion changes. Balance freezes before changing cadence and settles afterward. Existing input generations, celebration cancellation and presentation epochs remain authoritative.

`GameFeedback` owns trace selection haptics and all explicit accessibility announcements. The view passes count/value/readiness plus generation and hold values through the store; cancelled/replaced ownership cannot emit stale speech. Store preferences and device Reduce Motion/VoiceOver policy gate selection haptics, using the existing bounded generators.

Fresh survival skies use universal critical mass. `CriticalMassPresentation` renders committed age as advancing violet facets, inward chevrons and exact threatened cells; `StarCollapsePresentation` shares the bounded inward swallow with historical Dusk. `SkySaveArchive` writes v8, reads retained v3–v7 and preserves prior bytes. Retained replay keeps its mechanics; New sky selects aging. See [critical mass](../docs/design/CRITICAL_MASS.md).

[Touch intent](../docs/design/TOUCH_INTENT.md) defines direction-based horizontal swaps and projected elliptical trace acquisition; Core owns gap legality.

`CrystalCelebrationArtwork` loads the five neutral title materials and twelve companion glyphs once, including failure. `CrystalCelebrationLabel` composes exact awards/relay depth and colors the faceted material from the receipt. `ArtworkRaster` owns alpha-bound measurement shared with packaged jewel loading. Accessibility-size, changed/localized-copy and missing-family fallbacks remain native text; no art loading or raster scans occur per timeline tick. [Production provenance](../Artwork/Celebrations/README.md) and [integration acceptance](../docs/design/celebration-lettering/crystal-comet-01/INTEGRATION.md) describe the boundary.

`CrystalCelebrationMaterial` shares one static luminance-masked refraction treatment across title and numeral art. Theme owns the spectral light colors; the receipt still supplies the harvested-family tint. Original PNG registration, bounded artwork loading, exact live values and accessible native fallbacks remain in `CrystalCelebrationArtwork`. [Material direction](../docs/design/celebration-lettering/crystal-comet-01/OPALESCENCE.md).

`SkySaveArchive.inspect` distinguishes missing, loaded and rejected archives. Before a successful replacement, one `starfall.accumulation.rejected` recovery slot preserves the rejected property-list value and source key; it never automatically restores an older round. Initialization stays read-only. Store encoding failures are observable through `saveFailed` and local OSLog, while prior bytes remain unchanged.
