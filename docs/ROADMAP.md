# Starfall roadmap

Updated October 17, 2026, Eastern time. This is the current roadmap for **falling sky**, the default game in Debug and Release. The [original-puzzle roadmap](archive/ROADMAP-original-puzzle-2026-10-16.md) is historical. Earlier game-bible and playtest documents describe the original puzzle unless explicitly updated for falling sky.

## Product direction

See [the adoption register and experiment workflow](EXPERIMENTS.md) for the authoritative adopted/trial/proposed status. Falling sky and its physical reactions are shipping behavior, not permanent experiments.

A small, readable, satisfying falling-sky puzzle worth replaying. Keep the 7×7 board, five jewel kinds, orthogonal matching worth 3+, growth, dark stars, automatic showers, pause, manual next shower, and local balance controls. Preserve full falling animations, with accessible reduced-motion alternatives.

No progression, power-ups, backend, accounts, analytics, ads, purchases, paid assets, or external SDKs. The original 70-jewel/18-move puzzle stays available for Debug regression testing; its rules do not govern falling sky.

## Current baseline

- The [compact HUD](evidence/compact-hud-2026-10-17/README.md) replaces the exact forecast/countdown/status rows with score/goal, a quiet menu and a subtle arrival cue. Pause moves into the menu; Start/Resume and manual advance appear while paused. User play still needs to establish whether losing the exact forecast helps readability without losing useful decisions.

- Falling sky is the default. New skies offer a first-shower match; matching runs help dry boards when a low column has room. Existing saves retain their previous sky-generation rules.
- Faster comets, manual next shower, paused clears, matching-group outlines/count, clear rings/score popups, and optional local sound/haptics are implemented.
- One optional First Light challenge is implemented: fixed seed 42, 18 starlight, steady showers and no dark stars; entry starts a new round from Settings. This is a single objective prototype, not a campaign or unlock system.
- The original star-character cast is integrated for falling sky in Debug and Release, with shared board/comet/preview materials and color-independent silhouettes. See the [production rendering contract](design/star-cast/README.md) and [native evidence](evidence/star-cast-2026-10-17/README.md). General physical-device and actual VoiceOver acceptance remain open.
- Local evidence at the published pacing tree: 56 core tests, 14 falling-sky store tests, seven UI checks and a Release simulator build passed. Checks include real system Reduce Motion gameplay and a smaller iPhone at the largest text size. These are local results, not a claim about a new cloud CI run.
- [Pacing evidence](evidence/falling-sky-pacing-2026-10-16/README.md) records exact scope and limitations. VoiceOver speech/focus and physical-device feel remain open.

## 1. Make choices engaging — active

The [mechanics notebook](design/MECHANICS_IDEAS.md) preserves the hold-to-supernova clear with possible nearby color changes, constellations, light-star, and void/drain/freeze ideas. These are deferred design questions, not additions to the accepted prototype scope.

**Question:** Is the player making useful decisions, or simply clearing the only available group?

The [strategy baseline](evidence/falling-sky-strategy-2026-10-16/README.md) is complete. Across 200 seeds, only about 10% of match-ready states in one-clear-per-shower policies offer multiple groups. Largest-first and first-group policies score almost identically. This is a reason to investigate decision depth, not proof that the game is unenjoyable.

The [expanded mechanics baseline](evidence/mechanics-baseline-2026-10-17/README.md) adds dry-shower and high-column-choice diagnostics without changing gameplay. Clear-all still offers alternatives in only 6.7% of decision states; 43.0% of its surviving shower states are dry, with no sampled dry run beyond one shower. Use these denominators when comparing the next bounded mechanic; human play remains necessary.

The user selected **shower variety and choices** to lead the next playable experiment. A separate [Shower Lab](evidence/paired-showers-2026-10-17/README.md) tests natural five-star 3 + 2 runs against the unchanged game. It raises clear-all multi-group decisions from 6.7% to 11.6%, preserves existing-save generation, and has passed a native opening/choice comparison. Broader pairing is rejected for excessive survival extension; a higher-column refinement remains offline. The default generator is unchanged pending observed play and pressure/comprehension review.

The [supernova rule comparison](evidence/supernova-rules-2026-10-17/README.md) and its [isolated native input lab](evidence/supernova-native-2026-10-17/README.md) are parked while showers lead. Hold/release/cancel, interruption and superseded-touch checks are retained; ordinary clear effects and the weak tap/charge tradeoff remain unresolved. Neither recoloring candidate is adopted.

The [next-tranche record](evidence/falling-sky-tranche-2026-10-16/README.md) compares two offline mixed-color candidates. Neither replaced the default. One optional objective-driven First Light round is the playable comparison in this tranche.

Ongoing experiment sequence:

1. Compare the current same-color showers with a two-color shower distribution in an offline candidate. Preserve the first-shower match, bounded dry-board assistance, dark-star settings, save compatibility, and unchanged announced previews.
2. Measure simultaneous groups, waits without a useful move, score/survival distributions, and whether clearing a high column actually helps. Include a clear-all policy; one clear per shower is only a diagnostic constraint.
3. Promote a candidate only after core checks and an actual short simulator playthrough. Preserve the current version for comparison. Do not pick a winner solely from bot scores.
4. Use the [falling-sky playtest](PLAYTEST-FALLING-SKY.md) to compare comprehension, perceived waiting, choices, and replay preference. Record only observed play; there are no participant results yet.

**Exit:** Opening remains playable within one settled shower; long dead stretches do not return in the regression sample; a player can describe a useful choice and prefers the candidate or clearly identifies the next issue. Numeric sample targets are design hypotheses, not release gates.

## Progression direction — one challenge prototype, campaign deferred

[Mechanics/progression research](design/FALLING_SKY_RESEARCH.md) and [Mahjong-solitaire research](design/MAHJONG_PROGRESSION.md) distinguish puzzle difficulty from a long level counter. The user's next-tranche request advances the plan to one optional First Light challenge. Validate completion/retry and compare goal-driven play with survival before authoring more skies. No campaign, unlock system, XP, currency or infinite-content generator is included. Future challenge sequences should vary layout, goals and pressure, with readable changes and easier relief rounds rather than an assumed endlessly rising difficulty curve.

## 2. Polish physical feel — active

Visual acceptance of the cast remains open. A [motion-set revision](evidence/star-cast-motion-2026-10-17/README.md) adds twelve frames per character, partial turns and distinct grown/clearing expressions; its sheets and recording are available for review. The [luminous revision](evidence/star-cast-luminous-2026-10-17/README.md) responds to feedback on eyes and emitted-light appearance; the first integration did not establish final art approval.

A bounded [physical-reaction pass](evidence/physical-reactions-2026-10-17/README.md) adds angled arrivals, lighter/heavier rebounds and distance-delayed survivor ripples. These present existing committed turns; they do not adopt supernova recoloring or add collision-driven rules. Human preference and device pacing remain open.

- Review comet speed, landing/growth emphasis, clear readability and input response on a real iPhone.
- Tune optional sound/haptics for comfort, silent mode and interruptions; keep defaults off and mute immediate.
- Profile repeated rounds for frame pacing, memory growth and leftover effect nodes before optimizing.

**Exit:** No distracting effect blocks the next decision; no input lock or accumulating effects; device observations and profiles are retained.

## 3. Make danger and outcomes readable

- Communicate nearly full columns and growth-blocked jewels without relying on color or motion alone.
- Keep the preview legible while preserving the current hidden landing places.
- Make overflow cause, final score, replay and new sky easy to understand and reach.
- Keep pause and manual shower controls reachable on smaller screens and with large text.

**Exit:** A first-time player can explain the loss and their next action; native input, settings dismissal and layout checks pass on affected screens.

## 4. Finish accessibility and reliability

- Actual VoiceOver speech, focus, matching-group rotor, activation and focus return from Settings.
- Actual system Reduce Motion while playing; paused/manual play and Calm effects remain usable.
- Minimum-supported OS, small phone, iPad portrait/landscape, large text and contrast review.
- Rapid taps, moving-arrival interruptions, save/relaunch, replay/new sky, audio interruption and repeated-round stress.

**Exit:** Retained source-bound results distinguish simulator automation from device/human observations. No blanket accessibility claim from structural checks.

## 5. Prepare a shareable build

- Reconcile current falling-sky acceptance/release documents with the selected mechanics.
- Verify clean dependencies, privacy declaration, icons, version/build metadata and Release packaging.
- Configure signing and run on a device before preparing TestFlight distribution.

**Exit:** Reproducible signed build, clean-edition checks, known-issues list and completed device checklist. Upload/distribution remains a concrete final action when requested.

## Shipping quality gates

These six priorities turn the shipping recommendations into explicit work. They remain open: adding a checklist is not evidence of completion. Start by resolving the clean Release baseline, then observe first-time players; use the existing gameplay workstreams above to address what those checks reveal. The [engineering register](ENGINEERING.md) tracks technical risks and the [release checklist](RELEASE_CHECKLIST.md) owns signing/submission details.

- [ ] **Prove the opening is fun.** Observe a small set of first-time players without coaching, using the [falling-sky protocol](PLAYTEST-FALLING-SKY.md). Record measured time to first clear, waits between useful moves, understanding of growth/dark stars, and whether they voluntarily replay. Distinguish missed moves from a board without a move. Exit with actual observations and a bounded response to major confusion/waiting; bot scores and a first-shower match alone do not close this gate.
- [ ] **Use a feature definition of done.** Each change states observable acceptance criteria and records relevant rules, save compatibility, interruptions, accessibility, visual polish/full animations and tests, with explicit omissions. A reviewer should be able to reproduce the intended behavior. Apply the regression and experiment-lifecycle rules in [AGENTS.md](../AGENTS.md); this is an ongoing gate for every feature, not a one-time document task.
- [ ] **Validate the exact shipping candidate.** Resolve the local Xcode project drift as its own reviewed change. Build a clean Release candidate and record commit/tree, configuration, toolchain and device/OS. Test fresh installation and upgrading from a retained previous-version save without resetting it: board, score, preview/RNG continuation, preferences and completed challenge remain valid or follow an explicitly tested migration. Existing clean-baseline compilation does not establish visual or upgrade acceptance. Run the current falling-sky acceptance flows on that candidate.
- [ ] **Make physical-device checks routine.** Use a smaller/older supported iPhone and a repeatable sequence of showers, clears, replay and background/resume. Record responsiveness/frame pacing, heat, energy behavior, memory trend and leftover effects across repeated rounds, plus audio interruption/resume. Investigate reproducible issues with Instruments before optimizing. Set measured budgets appropriate to the chosen devices; do not invent thresholds or claim device performance from simulator results.
- [ ] **Complete actual accessibility acceptance.** Play a complete round with VoiceOver: spoken location/value, rotor, activation, pause/manual advance, outcome/replay and focus return from Settings. Separately play with system Reduce Motion and inspect largest text, contrast and jewel identification without color alone. Record actual behavior and remaining barriers. Structural labels, audits and sighted native grid tests do not close this gate.
- [ ] **Run a small TestFlight feedback loop.** After signing/distribution prerequisites and explicit upload/tester authorization, test the actual Release candidate with approved testers before expanding scope. Collect confusion, crashes, replay preference and device/build details using TestFlight feedback; fix significant issues and verify the candidate again. Keep feedback separate from a claim of crash-free play or universal enjoyment. This adds no analytics SDK, account system or network feature to the game.

Useful Apple guidance: [Instruments](https://developer.apple.com/tutorials/instruments), [testing accessibility settings](https://developer.apple.com/documentation/accessibility/testing-system-accessibility-features-in-your-app), and [TestFlight feedback/crash reporting](https://developer.apple.com/testflight/). These are implementation resources, not completed acceptance evidence.

## Delivery discipline

Work in small verified batches. Keep rules in StarfallCore, presentation/feedback explicit, saves compatible and other local edits intact. Update this roadmap with the outcome of each experiment; historical evidence remains append-only. No feature is marked accepted just because it compiles or a bot performs better.
