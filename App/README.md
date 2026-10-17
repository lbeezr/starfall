# iOS application

SwiftUI screens, main-actor stores and SpriteKit presentation for the native game.

## Start here

Deterministic rules belong in [StarfallCore](../Sources/StarfallCore/README.md). Build the shared Starfall scheme and run affected hosted/UI checks after source changes. Asset catalogs are packaged data; their sets are documented by this folder, not individual READMEs.

## Observatory environment

Default Falling Sky uses the full-screen Observatory. `ObservatoryGeometry` owns artwork/prop registration and every render/touch coordinate; `ObservatoryEnvironment` owns bounded fog time and cancellable prop responses using narrow lifecycle inputs. Theme owns colors; core owns outcomes. The game view resets environment lifetime on replay/new challenge and suspends it under settings/background. Four `Observatory*.imageset` resources are generated art; exact prompts/provenance remain in [the source-art record](../docs/design/environments/landing-native-01/README.md).

`ObservatoryReviewFixture` is compiled only in Debug and requires explicit reset/review arguments. It is native verification tooling, not an alternative game/environment. See [verification commands and boundaries](../tools/environments/README.md). `skyEnvironment` is retired: any retained local value is inert and game saves are untouched.

`FallingSkyHUD` owns the selected transparent score/trail/menu row and cast guidance. `FallingSkyMenu` receives snapshots, bindings and narrow actions, with dedicated help/balance pages. The trail reads the existing deadline; it never schedules showers. See [interface contracts](../docs/design/OBSERVATORY_INTERFACE.md).

`StarCast` owns Crystal Glow materials for board, comets, HUD and previews: six packaged bodies, authored faces, shallow turns and a bounded 72-material cache. The scene owns separate contact shadows; their placement follows cached body height and grown size. See the [production contract](../docs/design/star-cast/README.md).

Constellation drawing is now part of FallingSky: transient ordered input lives beside the store, the native trace surface shares Observatory geometry with accessible buttons, and the scene presents a bounded trail/burst. Core validates the selected set; ordinary taps retain their original rules. Debug-only reset fixtures are not a second app or a menu route.

## Welcome, entry and endings

`SkyFlowCeremony` presents narrow value snapshots and actions using the shared cast and theme. `FallingSkyView` owns navigation, suspends gameplay under ceremonies and waits for the committed final turn to settle. Reveal tasks belong to screen identity and settle on interruption; they never advance gameplay. See [the flow contract](../docs/design/SKY_FLOW.md).

Ordinary Debug/Release launches open Welcome. Historical `--starfalls-reset` board fixtures still open paused play; add `--sky-flow-review` to test the production welcome flow with isolated `Starfall.SkyFlowReview` defaults. Relaunch with only `--sky-flow-review` to exercise restore. This is Debug verification setup, not a player mode.

`SkyShowerPlacement` selects the calibrated iPhone 17 portrait camera contour. All other hardware/viewports and accessible layouts use the safe-area header. Both show the same committed ordered forecast through `SkyShowerTrail`; there is no trial flag. [Adoption and device limits](../docs/evidence/shower-forecast-adoption-2026-10-17/README.md).
