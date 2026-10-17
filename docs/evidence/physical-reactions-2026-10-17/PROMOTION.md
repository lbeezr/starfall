# Production promotion and merge verification

October 17, 2026, Eastern time. The motion change is commit `1d06f7c`; production naming and the experiment workflow are commit `c9cc3f02fbb2571c4afad9abffa54b280df2a954` on `codex/physical-reactions`, based on compact-HUD main commit `faf395b`. Those source commits were prepared in the isolated managed checkout `/Users/lbeezr/.codex/worktrees/physical-reactions/Starfall`; its tracked tree was clean for final post-commit native checks. This record supplements, rather than replaces, the earlier dirty-working-tree evidence.

## Adoption

Falling sky and physical reactions are adopted in the default Debug and Release game. Production model/turn, store, scene, view and test files use `FallingSky…` names. The rain clock and presenter protocols also use production names. Xcode file references point at the renamed files; the core remains a UI-free Swift package. No compatibility type aliases or permanent pilot flags were added.

Persisted keys, encoded fields, launch arguments and historical `experiment.*` accessibility IDs remain stable. A fixture encoded by the old model before renaming restores under `FallingSky`, validates its invariants, equals a replayed control and produces the same eight subsequent showers. This is a source naming promotion, not a rule or schema migration.

The authoritative [adoption register and lifecycle](../../EXPERIMENTS.md) separates adopted, isolated-trial, proposed and retained Debug tooling. AGENTS.md links that workflow. Supernova recoloring/charge and alternate showers remain outside the shipping target; neither is promoted by this merge. Human/device tuning, actual VoiceOver and broader native-UI risks remain explicitly recorded.

## Executed checks

- `swift test`: 61 core tests passed, including the frozen pre-promotion save/replay check.
- `python3 scripts/ci-hygiene.py` and `git diff --check`: passed after staging the renamed files. The hygiene guard initially reported the unstaged old path missing, correctly reflecting the old index; it passed with the actual intended file set.
- Debug native `test_sim`: `ARCHS=arm64 -parallel-testing-enabled NO -only-testing:StarfallAppTests/StarCastTests -only-testing:StarfallAppTests/FallingSkyStoreTests -only-testing:StarfallUITests/FallingSkyInteractionTests/testFirstShowerIsPlayableAndManualInputStaysPaused`; 26 passed, zero skipped. Result `test_sim_2026-10-17T13-30-28-455Z_pid43533_e684d130.xcresult`. Includes full-motion rebound/ripple/settlement, cancellation and store lifecycle checks.
- Release simulator build/install/launch passed on iPhone 17e / iOS 27.0, dedicated simulator `1199FBAF-FCA7-4F0D-BD49-8282154CC9EE`, Xcode 27.1 (27A9275), `ARCHS=arm64`. Log `build_run_sim_2026-10-17T13-31-07-968Z_pid43533_fe6c2086.log`. A final clock-protocol naming cleanup afterward is covered by the final checks below.
- `python3 tools/mechanics/run-supernova.py` and `python3 tools/mechanics/run-supernova.py --rotate`: passed after updating active tooling for production model/path names. Historical evidence patches retain their original source-bound names.

Final post-commit regression results and merge disposition follow below. Raw logs/results remain under the local XcodeBuildMCP workspace and `/tmp/starfall-promotion-*`; the integration record does not claim physical-device or actual VoiceOver validation.


### Final integration results

Post-commit `c9cc3f0` Debug command used the same arm64/serial settings and the two focused hosted suites, plus `FallingSkyInteractionTests/testAutomaticRainPauseGrowthClearReplayAndSettings` and `FallingSkyInteractionTests/testBackgroundRelaunchAndAutomaticOverflow`. **27 passed, zero failed/skipped.** Result `test_sim_2026-10-17T13-31-58-715Z_pid43533_c62f4ea7.xcresult`. Both earlier failing UI scenarios now pass on the later compact-HUD integration baseline; this does not retroactively change the historical failed runs or establish their root cause. The remaining device/actual VoiceOver acceptance limits remain open.

The final Release compile of `c9cc3f0` passed with no warnings: `build_sim_2026-10-17T13-34-12-837Z_pid43533_9deb416a.log`. The only subsequent Swift edit renamed the Debug classic menu's local `experimentPresented` state to `fallingSkyPresented` and its label to “Play falling sky”; launch arguments, state behavior and accessibility identifier are unchanged. Final compile checks cover that naming cleanup. No production owner remains named Experiment; the frozen old-save fixture and stable accessibility identifiers intentionally retain historical text.

Integration is a fast-forward into local main. Preserve unrelated shared-checkout project formatting, mechanics work and assets outside these commits. Active local lab sources need mechanical production symbol/path updates; this does not adopt their mechanics. No remote push is part of this local merge.

Final source `6c7c630` passed Debug and Release simulator compiles in the isolated checkout, respectively `build_sim_2026-10-17T13-35-41-559Z_pid43533_ce5d4df0.log` and `build_sim_2026-10-17T13-35-47-058Z_pid43533_46427da2.log`, with zero warnings/errors. Fast-forward merge into local main completed. The restored primary workspace also passed the Debug simulator build (`build_sim_2026-10-17T13-36-59-174Z_pid43533_bce531cd.log`) and hygiene/diff checks. That additional workspace build includes preserved unrelated project formatting and mechanics/documentation work; clean-tree acceptance remains tied to the isolated source above. Main's shipping app sources match the promoted commits. Shared mechanics files that explicitly export the older pinned lab retain their old snapshot naming; the active current-source sampler and supernova runner use the new domain names. No unadopted mechanics were linked into the game.
