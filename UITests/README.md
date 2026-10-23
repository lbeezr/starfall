# Native interaction tests

XCTest flows exercising the app through native controls on Apple tooling.

`WorldJourneyInteractionTests.testFourStarLineFromFreshLanternClearsAutomaticallyAndRestores` follows a natural revision-4 square chain, four-star line and square through normal-motion native input and relaunch. Complete current Lantern/Ribbon paths use the shared `StoryPatternPlan`; retained seven-star rules have separate save/Core coverage.

## Start here

Run relevant flows through the Starfall scheme. Keep bounded condition-based waits and isolated test saves. Report actual VoiceOver and full-motion observations separately from automation.

`RestorationInteractionScenarios` owns the shared native win/restore/replay, dense overflow, preview/Begin, largest-text/Reduce Motion and tablet rotation/real-clear scenarios used by Seed Moon, Silver Pools, Frostfruit Orchard and Sunwheel Mill. Their named test methods keep suite selection explicit. Shared helpers select all seven challenge identities and preserve native button/cell semantics; adding a location must not duplicate these flows.

`SilverPoolsInteractionTests` adds the fifth challenge’s phone five-state geometry check, dense rapid-clear/settings/background regression and tablet full-board completion in both orientations. Its ordinary tablet scenario captures all ten portrait/landscape states and executes real clears. [Current Silver evidence](../docs/evidence/silver-pools-2026-10-19/README.md) records 11 selected native UI checks passing at runtime `dev.98f8ba82e6`, source `aabd673` (native-equivalent `84ae918`), with all fifteen phone/tablet artwork states inspected and normal motion checked separately. Development verification is complete within that scope; [canonical installation](../docs/evidence/silver-pools-2026-10-19/delivery.json) of the same runtime from main `47ff6ba` is verified after PR #178. Main CI was pending at installation; physical play and full release-candidate accessibility remain unverified.

`FrostfruitOrchardInteractionTests` adds the sixth challenge to those shared scenarios, including phone five-state geometry, dense interruption and both tablet orientations. World-journey coverage checks its earned unlock after Silver Pools and retained lock under legacy access. The [orchard evidence](../docs/evidence/frostfruit-orchard-2026-10-20/README.md) records execution and inspected captures for native input source `6aee65e` / runtime `dev.bd94e46b80`, separately from 342 passing hosted checks on the combined source. Combined-source checks cover 342 hosted, 6 phone, 3 tablet and 2 compact-phone checks, plus Core and Release. All fifteen paintings are adopted; publication and installation are verified. The earlier 339-test hosted baseline at `bede49c` and 40 affected hosted checks at `f7b5c71`, with their failures and corrections, remain explicitly pre-integration evidence. Full release-candidate, actual VoiceOver and physical gameplay acceptance are not established by these automated checks.

`SunwheelMillInteractionTests` adds eight phone scenarios and two tablet scenarios through that shared owner. The phone preview checks retain each of the six previous locations until Begin. World-journey coverage adds a real Frostfruit winning clear, durable Sunwheel unlock and entry at zero, while Bell Choir remains unavailable. The existing all-ready swap, quiet corner and map-cancellation flows include Sunwheel. Native execution and capture review remain pending for this batch.

Restoration fixtures require Debug, `--starfalls-reset`, `--dialogue-review` and a valid score argument such as `--sunwheel-restoration-review=14`; `--restoration-dense` fills the board. They use isolated review saves. Sunwheel preview tests additionally use the gated `--world-frostfruit-complete-review` history fixture; actual unlock coverage earns that repair through a native clear. [Native test selection](../scripts/native_test_plan.py) owns phone/tablet classification, including the Silver, Frostfruit and Sunwheel tablet methods. Source-art or [design-kit](../docs/design/level-design-kit/README.md) overlays cannot replace inspecting the attached native captures.

`ConstellationTraceNativeTests` verifies selected five from six, short/outside cancellation, ordinary taps, retained relaunch and largest-text tracing/build metadata in the same Starfall target. Fixtures require Debug and explicit local reset arguments.

`ConstellationTraceNativeTests` now holds an eligible touch across a five-second automatic deadline before dragging and verifies that the chosen five clear. The same suite preserves ordinary tap, Opal and large-text checks. Hosted checks own exact deadline arithmetic.

`testOpeningCascadeAllowsNativeClearBeforeLastWave` verifies an actual clear during the intro with Calm and system Reduce Motion off, restoring the system preference afterward. Inspect recorded motion separately from the tap assertion.

`FreshSkyPlaytests` samples seeds 5 and 180 for 45 seconds and seed 28 for 90 seconds after Start sky; an in-flight native gesture may finish later. Each observation reads one accessibility snapshot containing cells, score and terminal state, then selects the largest exposed reward among enabled cells fully inside the viewport. Native contact uses that observed cell position; it does not perform delayed live-property reads on a cell that the terminal ceremony may remove. The natural-overflow regression verifies both active and terminal observations. Normal effects, automatic timing, scoring assertions and bounded miss diagnostics remain; no hidden state or forecast oracle is used. Snapshot-to-tap races and XCTest overhead remain observational limits, not human pace or balance acceptance. System Reduce Motion is inherited and must be recorded separately.

`PacingCueUITests` checks baseline isolation; Historical B flows belong to their recorded exports; current checks use the ordinary app. They cover one-wave warning, faster/breathing labels, Settings dismissal, persistent largest-text cues and system Reduce Motion with restoration.

Its active forecast/phase check verifies the final presentation integration: separate vertical space, conservative B header fallback, accessible forecast value and unchanged native cell frames.

`ShowerForecastInteractionTests` checks production camera/header placement, ordered forecast speech value, menu/background lifecycle and maximum-text fallback. Run it on a calibrated island phone and a non-island phone; inspect the attached captures separately from physical-device acceptance.

**Announced cadence adoption:** Normal fresh survival uses Core `freshSurvival` with existing `announcedCycleV1` (six 3-second, three 2.5-second and three 3.5-second intervals after the opening). Explicit constructors still default to V2 for retained-version reconstruction. Older saves and same-sky replay retain their version; First Light and fixed gentle/steady settings retain timing. [Current contract](../docs/design/PACING_ADOPTION.md).

`testOpalPlanningTwoTapOrdersKeepTheirDistinctRewards` compares Amber-first and Aqua-first through normal native taps on the seeded Debug fixture; automation establishes outcomes, not human recognition or timing.

`testTinyEdgeReleaseResumesAutomaticSkyAndOrdinaryInput` uses a native sub-slop drag from an eligible edge star and waits for a committed new-family arrival, then checks menu dismissal.

`testAutomaticStormCountsRecoverWithoutManualShowersOrClears` observes the complete three-heavy count and recovery using the actual automatic clock; it establishes sequence delivery, not a player reaction-time or preference result.

Forecast tests assert the actual 148×50 contour on calibrated simulators and the header fallback at accessibility sizes. `testInputRecoversAfterMultitouchBackgroundAndSupportedRotation` rejects a native pinch, cancels a short trace, backgrounds/restores, draws again, and restores a menu; on iPad it also rotates before the successful drag. It does not synthesize a second finger during an existing one-finger hold.

`testCurrentStormOrbitChoiceThroughTwoNativeTapOrders` uses current gravity-generation seed 180 to verify native three-plus-five versus three-plus-three tap outcomes and inspect both follow-ups. The nine-light branch needs a curved trace; Core/hosted coverage is distinct from OS-level curved-gesture acceptance.

`testCurrentOrbitFollowUpGuideReadsToEndWithoutMovingActionsOrBoard` scrolls both current field follow-ups to their timing suffix, checks the ending lies before reachable actions, verifies that an outer page scroll translates board/actions together, preserves the board and then executes the next native clear. Inspect its captures to distinguish real read-through from accessible full-text labels alone.

`GravityOpportunityNativeTests` follows the candidate's naturally reached seventh-wave pair through manual arrivals, collision and rotation, then compares eight- versus seven-light two-clear outcomes. Its second flow includes largest text, settings/background and retained restore. Debug fixtures require the explicit reset argument and use the normal app identity.

`ResponsiveInputUITests` exercises an actual 7-point ordinary drift at normal/largest text and readable incomplete-trace feedback, using existing reset-only routes and isolated dialogue-review saves.

Paused clear-feedback checks wait for the exact result text after score commitment, matching the presentation-owned dialogue boundary. Restore requires the complete restore message and Resume sky semantics; the strict approaching-cue expectation remains unchanged pending its older-runner investigation.

`DuskInteractionTests` uses reset-only fixtures in the normal app to verify five feeds, early color release, valid zero-reward clears, settings/background/restore, and readable largest-text Reduce Motion outcomes.

`SkyTechniqueInteractionTests` exercises mode-free recipe taps and relays, immediate four-direction exchanges and empty-space falls, selected tracing, and gesture readiness after settings/background interruption. Hosted recipe-path tests cover exact square/cross selection; native constellation tests cover largest-text tracing. Full animation and actual VoiceOver evidence remain separate.

The responsive-input regression uses 7-point ordinary drift at normal/largest text. Selected-five native drawing includes a hold then fast stroke beginning at the target rim; partial/outside traces must still cancel without ordinary-clear fallback.

`LandingPlaceInteractionTests` now browses the seven registered destinations without entering; it preserves its portrait/landscape centering, native opposite-edge taps, background/resume, exact large scores and largest-text scrolling. Calm checks preserve the same clear outcomes. Its explicit Observatory fixtures use isolated defaults.

`CriticalMassInteractionTests` exercises the reset-only age-eight review history: native rescue, warned collapse, settings/background/restore and largest-text calm help. It uses isolated dialogue-review defaults, not player saves.

The focused constellation gap/off-center and quick directional swap checks exercise approximate strokes without destination-cell targeting.

`FreshSkyPlaytests.testRepeatedAutomaticVisibleMatchesSeed28` extends the same visible-only driver to 90 seconds for repeated ordinary awards and contact observations. [Source-bound automatic sample](../docs/evidence/calibration-critical-mass-2026-10-18/AUTOMATIC.md) records its non-scoring attempts and limits; a passing test does not imply every attempted contact scored.

`ResponsiveInputUITests.testOutwardSwipesExplainTheEdgeAndNextTapClears` checks truthful copy on all four edges, unchanged board/score and a successful following tap with normal motion.

`PacingCueUITests` checks that normal, calm and system Reduce Motion forecasts approach before commitment and actually arrive afterward. Bounded state predicates replace guessed animation sleeps.

`SkyLessonInteractionTests` exercises real tutorial square/cross/Opal/relay moves, exact rewards, Retry, unchanged live play and maximum-text/system Reduce Motion lifecycle. `WorldJourneyInteractionTests` covers map locks versus unavailable content, cancellation, native swaps in all seven registered locations, tap/swap/held-trace practice and durable repair after relaunch. `worldVisitControl` selects through the shipping map and reveals its native sky controls before tapping the map action when chrome obscures it. This repairs the test's visibility precondition while preserving real taps and assertions. Compact result checks require immediate Replay access; the landscape result scenario also uses the Home action after a real clear. A reset-only `--world-legacy-review` flag, additionally gated by `--dialogue-review`, models an existing install for older cross-location preview tests without inventing completion.

The reward feedback acceptance repeats native recipe/relay clears, fast swaps followed by held tracing, settings/background and actual system Reduce Motion. These checks verify outcomes and lifecycle, not physical haptic or listening preference.

`NativeSkyControls` reveals fully visible targets through the non-playing screen edge. Paused preparation checks retain exact board snapshots; fixed and flowing guide layouts have distinct coordinate expectations. `SkyFlowInteractionTests.swift` owns the unchanged flow suite separately from shared native settings helpers. [Compact regression evidence](../docs/evidence/compact-native-acceptance-2026-10-19/README.md).
