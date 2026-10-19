# iOS application

[Native implementation and test instructions](AGENTS.md) give the local working contract.

SwiftUI screens, main-actor stores and SpriteKit presentation for the native game.

## Start here

Deterministic rules belong in [StarfallCore](../Sources/StarfallCore/README.md). Build the shared Starfall scheme and run affected hosted/UI checks after source changes. Asset catalogs are packaged data; their sets are documented by this folder, not individual READMEs.

## Player copy

Player copy for regular Falling Sky lives in the [local dialogue/interface catalogue](DialogueScripts/README.md), including character voices, menu/help/results and accessibility text. `SkyCopy` exposes typed keys; the shared template validator rejects missing/extra values. Keep wording there and committed facts in the app/Core owners. Debug tooling and the original orthogonal puzzle retain their separate developer text.

## Official locations and practice

Welcome and the game menu expose one World Map and Learn to Play. `WorldMapView` provides a painted selector and equivalent native list. `WorldMapPainting` combines registered damaged/repaired artwork using saved completion, with obscured unreached landmarks and no number badges. `WorldJourneyStore` persists a separate v1 completion envelope after committed round saves; `WorldJourney` derives access and preserves prior-install access without inventing wins. Seven mapped destinations remain unbuilt. See the [integration contract](../docs/OFFICIAL_LOCATIONS_AND_TUTORIAL_PLAN.md).

`SkyTutorialView` uses 21 `SkyTutorial` scenarios through the real `FallingSkyStore` and gesture surface. Its store has no save writes, and Retry/Next cancel old input, clock and presentation tickets. The original Help diagrams are removed; their Core board definitions are reused by practice.

The old five-nightscape selector, `LandingPlace`, `LandingEnvironment` and sixteen exclusive image sets are removed. Open Sky uses completed Lantern Landing scenery independently of rules and progress; old scenery preferences are inert. `LandingGeometry`, the shared ambient clock and restoration art remain authoritative. `SkyBackdrop` fills the margins.

Five production locations restore Lantern Landing, Ribbon Crossing, Kite Harbor, Seed Moon and Silver Pools. They keep stable challenge IDs, seed 42, 18-light goals and historical supply. A versioned action capability enables current swaps and recipes on new, restored and replayed challenges; v9 saves retain all v3–v8 readers. Entry is still read-only until Begin. [Development checks](../docs/evidence/official-world-2026-10-19/README.md) are separate from historical phone deliveries.

`RestorationEnvironment` receives that value and lifecycle flags, with no store capability. `RestorationArtwork` and `RestorationLayout` own family selection, exact per-state source dimensions and registration for phone portrait, iPad portrait and iPad landscape. Each state is one continuous painting; no center replacement, feather mask or split source regions. The [level-design kit](../docs/design/level-design-kit/README.md) supplies shared composition, camera, native-layout/bleed and star-scale guidance. It preserves rich connected terrain while leaving native gameplay geometry authoritative.

Actual Crystal Glow pieces remain in SpriteKit and share `LandingGeometry` with native hit cells. `StarlightCelebrationOverlay` transfers committed clear receipts to the registered scene destination; the full-image transition and ordinary ceremony present completion. Quiet, restored and interrupted presentations settle to committed state. There is no extra score rule, timer, walking cast or world-travel subsystem. [The adoption register](../docs/EXPERIMENTS.md) and linked [Lantern](../docs/evidence/lantern-landing-2026-10-19/README.md), [Ribbon](../docs/evidence/ribbon-crossing-2026-10-19/README.md), [Kite](../docs/evidence/kite-harbor-2026-10-19/README.md) and [Seed](../docs/evidence/seed-moon-2026-10-19/README.md) reports retain delivered-source evidence. Browser reviewers and source paintings do not establish native, physical or actual VoiceOver acceptance.

`SkyDefaults` owns storage selection for both `FallingSkyStore.forSkyFlowApp` and the app root’s SwiftUI preference environment. Observatory reset/review runs use `Starfall.ObservatoryReview`; existing technique, dialogue and Sky Flow review suite names are preserved. Ordinary Debug/Release continues using standard defaults. The selector never clears a domain or writes during initialization.

`ObservatoryReviewFixture` is compiled only in Debug and requires explicit reset/review arguments. Shared challenge review selection requires `--starfalls-reset`, `--dialogue-review` and a valid location score argument such as `--silver-restoration-review=14`; `--restoration-dense` requests the full-board fixture. It is native verification tooling, not an alternative game/environment. See [verification commands and boundaries](../tools/environments/README.md). `skyEnvironment` is retired: any retained local value is inert and game saves are untouched.

`FallingSkyHUD` owns the selected transparent score/trail/menu row. [Character dialogue authoring](DialogueScripts/README.md) owns reusable scripts, speaker IDs and the Debug studio; `SkyDialogueBubble` renders one shared native chat surface for gameplay and ceremonies. `SkyTrailMotion` owns the straight/island forecast finish mapping. `FallingSkyMenu` receives snapshots, bindings and narrow actions, with dedicated help/balance pages. The trail reads the existing deadline; it never schedules showers. See [interface contracts](../docs/design/OBSERVATORY_INTERFACE.md).

`StarCast` owns Crystal Glow materials for board, comets, HUD and previews: six packaged bodies, authored faces, shallow turns and a bounded 72-material cache. The floating cast has no ground shadows; clear light is radial and stays at its source. See the [production contract](../docs/design/star-cast/README.md).

Constellation drawing is now part of FallingSky: transient ordered input lives in `SkyInteractionSession` with one held-contact ticket, the native trace surface shares `LandingGeometry` with accessible buttons, and the scene presents a bounded trail/burst. Core validates the selected set; ordinary taps retain their original rules. Debug-only reset fixtures are not a second app or a menu route.

The store schedules the core’s persisted opening cadence: four quick waves, then the chosen regular pace. Input opens between settled batches; [opening acceptance](../docs/evidence/opening-cascade-2026-10-17/README.md) records checks and limits.

## Welcome, entry and endings

`LaunchScreen.storyboard` and the opaque `StarfallApp` root share the named `LaunchBackground` color. The static Starfall wordmark uses named `CeremonyGold`; launch has no timed delay or gameplay state. Validate system launch snapshots with an ad-hoc signed simulator product so SplashBoard can validate its resources. Shared build configuration selects the storyboard in Debug and Release; `LaunchSurfaceTests` checks the packaged color and launch declaration.

`SkyFlowState` stages round choices until Begin and rejects duplicate/stale Entry actions. Back discards only that pending choice; Continue preserves the in-memory pause choice, while restored rounds stay paused. `SkyResultSnapshot` explains committed endings after restore; `SkyWelcomeSnapshot` describes the retained round. `SkyPreferences` shares pre-play and game-menu toggles/help without another store or preference key. `SkyHelpContext` supplies the current or staged Core rules, including First Light before Begin; Entry can open the same settings/help sheet. `SkyFlowCeremony` presents narrow value snapshots and actions over the final board using the shared cast and theme. `FallingSkyView` owns navigation, suspends gameplay under ceremonies and waits for the committed final turn to settle. `SkyCastFormation` owns contained decorative arrival poses. Heading focus and terminal speech have one presentation owner. Reveal tasks belong to screen identity and settle on interruption; they never advance gameplay. See [the flow contract](../docs/design/SKY_FLOW.md).

Ordinary Debug/Release launches open Welcome. Historical `--starfalls-reset` board fixtures still open paused play; add `--sky-flow-review` to test the production welcome flow with isolated `Starfall.SkyFlowReview` defaults. Relaunch with only `--sky-flow-review` to exercise restore. This is Debug verification setup, not a player mode.

`SkyCadenceCue` presents the committed cadence forecast; copy and placement never own scheduling. The former B comparison is historical, with no runtime selector.

`SkyShowerPlacement` selects the calibrated iPhone 17 and iPhone 16 Pro Max portrait camera contours. All other hardware/viewports and accessible layouts use the safe-area header. Both show the same committed ordered forecast through `SkyShowerTrail`; there is no trial flag. [Adoption and device limits](../docs/evidence/shower-forecast-adoption-2026-10-17/README.md).

**Announced cadence adoption:** Fresh survival uses Core `freshSurvival` and the existing `announcedCycleV1` rhythm (six 3-second, three 2.5-second and three 3.5-second intervals), adopted after [native implosion-window checks](../docs/evidence/calibration-critical-mass-2026-10-18/ADOPTION.md); the previous B exporter/launch selector is removed. Core owns the sole algorithm. Older saves and same-sky replay retain their version; First Light and fixed gentle/steady settings retain timing. [Current contract](../docs/design/PACING_ADOPTION.md).

`FallingSkyScene` reports attached, sized presentation readiness. Scene detachment synchronously suspends the store. `SkyFlowState` gates a cancellable 240 ms handoff; scene readiness alone never starts a round.

`ConstellationTraceSurface` owns touch lifetime and coalesced samples; `ConstellationTraceHitTesting` maps continuous segments through the shared projection. The store holds its single shower deadline from eligible touch-down until exchange commitment or drawing release/cancel. Spatial misses keep the chosen path; stale state still cancels. The HUD reserves phase-copy space inside the full-window canvas, so it cannot crop scenery or hide the camera inset. Resting star rings are removed; the traced thread and finite sparks indicate selection.

Historical gravity integration used the v5 archive. Retained Core readers, `GravityStoreTests` and reset-only Debug histories preserve compatibility and regression coverage. Normal new, restored and replayed games apply gravity retirement; see [removal evidence](../docs/evidence/gravity-removal-2026-10-17/README.md).

`ConstellationTouchSession` classifies every final sample, including sub-slop off-board releases and a first drag sample delivered on release. The surface cancels on changed configuration/detachment/multitouch; store-issued hold tickets reject releases from older gestures.

Camera-layout selection reads the full local playfield canvas, beside the consuming overlay. Profiles require complete checked portrait dimensions and inset; resized/unknown/accessible viewports use the header. This is layout approval, not a claim that unknown hardware lacks a camera island.

Historical gravity fixtures use `StarCastField`/`StarCastHole` through the shared cast cache and finite `GravityMotion` cues. These are retained presentation/compatibility paths, not ordinary fresh-survival mechanics. [Art provenance](../Artwork/StarCast/README.md#magnetic-crystal-and-gravity-hole).

The historical magnetic saved role presents as an attraction field with a transparent center and no ground shadow; ordinary new/restore/replay paths retire the special before play.

Gravity arrivals share the ordinary flight constructor. StarfallMotion.PhaseTimeline owns phase durations and approach overlap; receiver responses and landings follow completed gravity motion. The scene presents committed outcomes and never schedules Core showers.


Core versions historical gravity supply. The archive rejects gravity-capable generations in a v4 envelope, including expanded-opportunity generations before any special arrives. Preserve those readers and checks when editing compatibility.

`FallingSkyPresentation` derives the columns reserved by committed turns, using a whole-board reservation for orbit phases. Store and scene allow independent ready actions and reconcile against the newest game. The existing trace surface owns anchored contacts and eligible drag classification; [responsive input](../docs/design/INTERACTION_FEEDBACK.md) defines feedback, lifecycle and verification boundaries.

Grown colored stars carry a luminous double silhouette and paired glints in `FallingSkyCharacter`. Only the outer aura breathes over 2.8 seconds; the rim/body stay steady. The scene and store cancel this decoration for quiet motion, suspension and replacement. [Current pulse verification](../docs/evidence/grown-star-readability-2026-10-17/PULSE.md) distinguishes native checks from human preference.

Gravity specials are retired from normal play. `SkyGeneration.standardSky` supplies ordinary/Opal/storm play; `FallingSky.removingGravity()` retires validated historical specials without changing survivor identities, score, RNG, cadence or outcomes. The store applies it on restore and same-sky replay, persisting only on activation/commit. Historical raw rules and reset-only Debug fixtures remain regression tooling; the normal app never routes into them. See [removal evidence](../docs/evidence/gravity-removal-2026-10-17/README.md).

`ConstellationTouchSession` gives movement priority: one four-direction exchange on displacement, or a stationary 300 ms hold followed by drawing. `ConstellationTraceSurface` owns the timer, physical contact and cancellation; `SkyInteractionSession` owns trace state and the rain ticket. There is no swap preview state or Arrange mode. Core validates and the store commits/saves/reserves columns. See [technique contract](../docs/design/STAR_TECHNIQUES.md).

`ConstellationTraceSurface.CaptureRecognizer` owns raw physical contact delivery before scroll arbitration, including terminal/reset cancellation. The store owns its ticketed shower hold. `SkySaveArchive` writes v9 and reads validated retained v3–v8 archives without overwriting their original keys. A present invalid current archive never falls back to an older round. Current Dusk warnings and marks derive the limit from the saved Core rule.

Drawing starts on the full native star target and follows six-point movement. The touch session separates early preview from sticky drawing intent, preserving small same-cell tap drift without turning partial selections into ordinary clears.

## Starlight celebrations

`StarlightCelebration` presents an already committed award, with immutable pre-clear family/reward contributors and a validated trace/recipe outline. Collection trails inherit the contributing material color and scale with actual awarded points; special callouts enter near the central terrace, while exceptional awards add one translucent aurora. Quiet modes keep a static exact award. See [harvest acceptance](../docs/design/HARVEST_FEEDBACK.md). The store owns its bounded replacement/expiry/cancellation; its overlay uses real board/header/score anchors through a shared registration that preserves nested preferences. Selection and release share recipe drawing order. Ready-column input, current saves, Dusk rewards and dialogue remain independent. Selection uses open sparkle rays; clear bursts use scattered glints without enclosing rings. The quiet overlay owns the same full canvas as normal motion. See [native visibility checks](../docs/evidence/starlight-celebrations-2026-10-18/VISIBLE_AWARDS.md).

`SkyInteractionSession` owns logical trace selection and the held store ticket. Its terminal transition clears local state before releasing exactly once; stale terminal tickets cannot end a replacement contact. The recognizer retains physical-contact ownership, and the store retains clock/generation ownership.

`SkyInputPolicy` gives contact, clear, trace and technique admission the same explicit global/column reasons. Core still decides action legality. Automatic pause permits explicit play; suspension and an already-due shower do not.

Store interruption cleanup has two small boundaries: `interruptPlay` freezes the deadline, then stops feedback and settles; `settleInterruptedPresentation` preserves the deadline for layout/motion changes. Balance freezes before changing cadence and settles afterward. Existing input generations, celebration cancellation and presentation epochs remain authoritative.

`GameFeedback` owns trace selection haptics and all explicit accessibility announcements. The view passes count/value/readiness plus generation and hold values through the store; cancelled/replaced ownership cannot emit stale speech. Store preferences and device Reduce Motion/VoiceOver policy gate selection haptics, using the existing bounded generators.

`LandingBackdrop` fills extra screen space from separate scenery plates. `LandingGeometry` owns the central stage, compact landscape companion column, prop registration and all 49 cell polygons; portrait artwork and compact terrace materials share that measured boundary. Short narrow and accessibility layouts scroll instead of shrinking targets.

Compact-height and accessibility layouts use a scrolling canvas plus a growing dialogue/footer. Other sizes keep the centered board with score/forecast above and 128-point dialogue plus native actions below. Large scores use grouped exact digits; they never become abbreviated values. [Native layout evidence](../docs/evidence/nightscapes-2026-10-18/README.md) separates simulator checks from physical comfort and RC VoiceOver.

Fresh and restored critical-mass skies disable automatic aging and purple warnings through the Core migration before scene presentation. Historical reset fixtures still exercise `CriticalMassPresentation`; `StarCollapsePresentation` also supports retained Dusk. Matching growth, committed preview, score and saved cadence are preserved. [Current aging decision](../docs/evidence/aging-disabled-2026-10-18/README.md).

[Touch intent](../docs/design/TOUCH_INTENT.md) defines direction-based horizontal swaps and projected elliptical trace acquisition; Core owns gap legality.

`CrystalCelebrationArtwork` prewarms the complete 106-character Crystal Comet family in fifteen horizontal views once, including failure. `CrystalGlyphLine` uses exported baselines and advances; `CrystalLetterMotion` samples a bounded turn/settle from receipt age. The existing overlay owns timing, placement, family-colored glow and cancellation. Quiet modes use the front view, and accessibility sizes, unsupported characters, long values or malformed art retain exact native text. No decoding, cropping or pixel scans occur during animation ticks. [Native profile and acceptance](../Artwork/CrystalComet/NATIVE.md) owns the current production boundary; [original static material](../Artwork/Celebrations/README.md) is retained as provenance.

`SkySaveArchive.inspect` distinguishes missing, loaded and rejected archives. Before a successful replacement, one `starfall.accumulation.rejected` recovery slot preserves the rejected property-list value and source key; it never automatically restores an older round. Initialization stays read-only. Store encoding failures are observable through `saveFailed` and local OSLog, while prior bytes remain unchanged.

`SkyPresentationLedger` owns outstanding turn tickets, column reservations, pending forecast selection and epoch invalidation. It owns no clock, scene or save. `SkyDialogueLibrary.result` selects turn wording from immutable committed values; the store retains session delivery, speech policy and save-before-animation ordering. Player-action results publish at commit; deferred shower/outcome feedback must still own both the presentation ticket and dialogue revision.

Idle input admission skips copied-game simulations when no presentation reserves columns. Busy-board admission still simulates the exact Core action; the real commit remains authoritative in every case.

Current collapse rendering consumes `presentationPhases` / `SkyPresentationPhase` through `PhaseTimeline`. Historical orbit events retain their existing rendering and timings; old timing-test names remain compatibility aliases.

Contact clock holds preserve the exact remaining shower time; only pause/background interruptions apply resume grace, including interruptions during a hold. Ticket/generation invalidation and no-catch-up delivery remain store-owned.

`SkyPersistenceNotice` exposes rejected-save and encoding/validation failure acknowledgements through the native app alert. It shares existing interruption/handoff ownership; acknowledgement does not write or restore data. The archive writer remains the production save boundary, with an injected write capability and reset-only review fixtures for failure tests. See [source-bound notice checks](../docs/evidence/debt-followup-2026-10-18/README.md#6-visible-save-recovery-and-failure-notices).

Ceremonies reserve bottom scroll space using theme spacing. Welcome, Entry and result actions can be brought fully above the system Home area at large text and landscape sizes; native tests check complete frames as well as activation. This does not change the board projection.

Historical Dusk rounds retain their saved feeding rules. Fresh survival has no Dusk arrivals or aging toggle; First Light keeps its fixed objective and cadence. Help and controls describe the selected Core rules.

Outward cardinal swipes preserve a blocked-swap result through the touch adapter, so the guide explains the edge instead of giving tap instructions.

The shower trail reads a narrow monotonic countdown snapshot, including held remainder and due state. Frozen states render once; normal and quiet periodic updates cannot schedule or commit rain. `FallingSkyView` separates scene composition, lifecycle observation and modal/award expressions while retaining the same state owners.

Trace readiness feedback validates the actual path, snapshot, generation and held contact at the Store boundary. It signals the first legal release once (including four-star squares), deduplicates retracing and coalesces coarse pointer samples. Recipe and relay audio have distinct short cues through the existing one-voice owner.

Replay entry receives only its pending choice; the result headline describes a blocked arrival while the committed snapshot owns the exact column and score. [Acceptance](../docs/evidence/ending-replay-2026-10-19/README.md).
