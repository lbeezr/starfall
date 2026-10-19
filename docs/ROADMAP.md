# Starfall roadmap

**Stolen-light journey — design foundation approved:** The user selected Murk as illustrated and all twelve map locations, then requested the rewritten [game bible](design/STARFALL_GAME_BIBLE.md) and [world atlas](design/WORLD_ATLAS.md). Lore, shared star neighborhoods, four-act story and finale are developed proposals. [Lantern Landing’s overhead playfield](design/lantern-landing-01/README.md) is approved for the existing First Light challenge. Its [production plan](design/lantern-landing-01/PRODUCTION_PLAN.md) is implemented and development-verified at source `8fb2e78`, runtime `dev.5afe4a3c23`: all fifteen scene states, tablet clears in both orientations, compact-phone landscape, largest text and normal-motion completion have [native evidence](evidence/lantern-landing-2026-10-19/README.md). Merged in [PR #154](https://github.com/lbeezr/starfall/pull/154); the canonical updater verified installation of `dev.5afe4a3c23` from main `ab868b5` in the original `com.starfall.prototype` app on October 19 at 14:53:57 UTC. A 40-star native board and four rapid taps committing exactly one clear passed. Physical play, optional full-capacity coverage and actual VoiceOver at RC remain follow-ups. Current nightscape, gameplay and delivery work below remain authoritative for the app; no campaign or rule/save change is adopted by this design package.

The [gameplay quality workstream](GAMEPLAY_QUALITY.md) follows the gesture improvements. All six priorities are delivered: board readability, immediate consequences, truthful shower forecasts, interactive setup examples, distinct rewards and clear endings/replay. Each verified batch reached the original phone app before the next priority. The [compact native follow-up](evidence/compact-native-acceptance-2026-10-19/README.md) classifies the ten recorded CI failures and strengthens test input and failure cleanup; physical-play acceptance remains open.

The [gesture quality workstream](GESTURE_QUALITY.md) targets instant cardinal swaps, deliberate held drawing, forgiving strokes and dependable rapid follow-ups. Five separate batches cover recognition, follow-up admission, edge forgiveness, hold feedback and quiet response, with [source-bound verification](GESTURE_QUALITY.md#evidence-and-limits). All five are merged individually; [canonical delivery receipts](evidence/gesture-delivery-2026-10-18/README.md) distinguish installed identity from physical-play acceptance. Physical comfort determines final acceptance.

**October 18 decision:** [Automatic aging is disabled](evidence/aging-disabled-2026-10-18/README.md) at the user’s request: fresh and restored critical-mass skies have no purple aging or implosions. Matching growth and cadence remain. Historical critical-mass rules/fixtures remain for save compatibility and regression, with no player toggle to re-enable them.

[Directional swaps and one-gap tracing](evidence/forgiving-input-main-2026-10-18/README.md) address precision targeting in the current app. Physical phone/iPad comparison remains the next tuning decision.

**Status:** Active · **Owner:** Current implementer · **Updated:** October 19, 2026, Eastern time

Build a small, readable falling-sky puzzle worth replaying. **Skillful survival arrangements extend the current matching and tracing.** Opal and storm phases are integrated in the regular game. Preserve its versioned generator/save contracts while tuning input, layout and timing. Historical lab comparisons do not define the current delivery workflow; human preference remains unverified.

**Technical debt delivery:** The [initial](TECH_DEBT_PLAN.md), [follow-up](TECH_DEBT_FOLLOWUP.md) and [third](TECH_DEBT_THIRD_PASS.md) batches are merged. The [fourth pass](TECH_DEBT_FOURTH_PASS.md) fixes stale automatic dialogue and primary CI timeout descendants; current-main canonical phone installation is verified. [Current engineering priorities](ENGINEERING.md#active-debt-and-next-actions--october-18-2026) own the remaining risks. Tablet hit semantics/control clearance and canonical installation are verified; iOS 17, actual VoiceOver and physical-play RC acceptance remain open. Historical native intermittency remains cause-unknown despite passing reproductions.

**Centralization follow-ups:** Four scoped extractions give interaction ownership, shared input availability, interruption teardown and feedback routing explicit boundaries in the regular app. [Scope and source-bound checks](evidence/interaction-centralization-2026-10-18/README.md).

[HUD correction](evidence/dialogue-only-hud-2026-10-18/README.md): remove top Dusk/input messages and the visible swap toggle; use bottom dialogue and direct gestures. Focused gesture and hosted checks pass; the linked record retains the original full-sky native wait. [Current reproduction and diagnostics](evidence/debt-reduction-2026-10-18/README.md#task-2--native-acceptance-diagnostics) pass without establishing the historical cause.

**Current input follow-up:** [Immediate four-direction swipes and hold-to-draw](design/IMMEDIATE_SWIPES.md) replace overlapping swap/trace interpretation. Movement commits once before release, independent of neighbor color; holding still for 300 ms starts drawing. [Source-bound verification](evidence/immediate-swipes-2026-10-18/README.md) separates native/hosted checks from physical comfort and RC VoiceOver. Earlier [input refinement](evidence/input-dusk-refinement-2026-10-18/README.md) retains its historical 150 ms swap-dwell evidence.

The approved [starlight celebration storyboard](design/STARLIGHT_CELEBRATIONS.md) is integrated with current recipes, Opal, Dusk and responsive columns. A [missing-award correction](evidence/starlight-celebrations-2026-10-18/AWARD_VISIBILITY_FIX.md) preserves the nested score anchor required to draw the overlay. [Native full-game award captures](evidence/starlight-celebrations-2026-10-18/VISIBLE_AWARDS.md) now verify sampled values/titles and open sparkle selection, including a quiet-layout correction; physical preference remains open. The [harvest refinement](design/HARVEST_FEEDBACK.md) now targets family-matched light, award-scaled strength and central callouts; [Crystal Comet lettering integration](evidence/crystal-comet-integration-2026-10-18/README.md) now passes current-main native/hosted/build checks; The user-approved [opalescent material follow-up](design/celebration-lettering/crystal-comet-01/OPALESCENCE.md) addresses flat coloring against the approved reference; physical preference and dense-board readability determine further tuning.

**Next actions:** Hold mechanics steady and follow the [calibration plan](design/CALIBRATION.md). [Critical-mass pacing adoption](evidence/calibration-critical-mass-2026-10-18/ADOPTION.md) selects the longer existing rhythm for fresh survival after measured implosion input starvation, preserving saved cadence and First Light. Observe recognition, gesture comfort and repeated-round preference at this baseline. Dense/large-text celebration comfort, physical feel and actual VoiceOver at RC remain separate acceptance work. Continue the canonical single-app updater; no feature-checkout device install.

**Lettering adopted:** the user-approved [crystal-depth alphabet](../Artwork/CrystalComet/NATIVE.md) now composes score popups and celebration titles in normal Debug/Release, with finite per-letter turns and native/quiet fallbacks. [Native evidence](evidence/crystal-depth-native-2026-10-18/README.md) records checks and the remaining physical/dense-board limits; the full sprite pack remains the authoring master.


**Open limits:** No gameplay participant preference results or general physical-device acceptance. Crystal Glow art direction and character masters are user-approved; runtime verification and remaining limits are recorded in the [cast integration evidence](evidence/crystal-glow-integration-2026-10-17/README.md). Accessibility evidence remains source-bound.

**Nightscape production:** All five approved destinations now use separated scenery around centered native gameplay. [Production contract](design/environments/night-production-09/README.md) and [verification/delivery record](evidence/nightscapes-2026-10-18/README.md) supersede the platform direction. No progression, rule or save change.

Character chat and complete shower trails are integrated into the current production target, preserving Opal and constellation input. Gravity was subsequently retired through the save-normalization boundary below. [Current integration checks](evidence/character-chat-production-2026-10-17/README.md) supersede the old-base delivery limit.

[Responsive input integration](design/INTERACTION_FEEDBACK.md) replaces the global animation gate with column reservations and gives contacts/cancellations explicit feedback. Current production trace, dialogue and save behavior are retained; the later gravity retirement is recorded below. [integrated verification](evidence/responsive-input-2026-10-17/README.md) separates simulator checks from physical feel.

Grown-star readability now uses a luminous double silhouette, two glints and a gentle outer-aura pulse. [Integration evidence](evidence/grown-star-readability-2026-10-17/PULSE.md) records native checks; next confirm uncoached recognition and dense-board comfort with the reporting tester.

**Current survival:** automatic aging is disabled in fresh and restored critical-mass skies; matching growth remains and Dusk stays absent from fresh supply. Historical Dusk rounds retain their rules. [Aging retirement](evidence/aging-disabled-2026-10-18/README.md) supersedes the earlier rescue/implosion direction; those raw rules and fixtures remain compatibility coverage.

The retained [technique roster](design/STAR_TECHNIQUES.md) is reconciled with current main, including v6 saves, Dusk feeding, responsive columns and current presentation. Core, hosted, native, layout and animation checks pass. Merged and delivered through the guarded updater with unchanged saved bytes; observe human play next. [Source-bound status](evidence/technique-current-main-2026-10-18/README.md).


[Copy rewrite](evidence/copy-rewrite-2026-10-18/README.md) integrates clearer instructions, six distinct character voices and event-based celebrations/advice/teasing through the shared local catalogue. Human first-play comprehension and reaction frequency remain to be assessed.

## Adopted mechanics and historical integration — October 17, 2026

The user approved the shared white connector and storm phases for the regular app, then selected the round Opal Orb and requested soft motion. [Current contract](design/WHITE_STAR_AND_STORMS.md) and [main-based integration evidence](evidence/opal-main-integration-2026-10-17/README.md) supersede the earlier research-only adoption boundary below. Preserve the independently adopted announced timing cycle. Development acceptance passed; Opal/storm integration merged in PR #37, with compiler compatibility in #39 and direct input/cadence polish in #40. The [bounded choice study](evidence/opal-choice-study-2026-10-17/README.md) and [native two-clear comparison](evidence/opal-native-planning-2026-10-17/README.md) establish situational scoring choices; actual combined human play and replay preference remain open. Pocketed alternate silhouettes carry no new mechanic or progression commitment.

## The game we are improving

<img src="evidence/compact-hud-2026-10-17/active.png" width="240" alt="Native gameplay capture with a compact score and menu header above the star board">

**Source-bound native reference:** October 17 compact-HUD candidate, iPhone 17e / iOS 27.0 Simulator; [capture source and verification limits](evidence/compact-hud-2026-10-17/README.md). The compact layout is adopted, but this capture does not establish current-build parity or human preference. See the [icon, opening screen and cast](design/VISUAL_REFERENCE.md) for the visual context behind the workstreams below.

The [diagonal constellation investigation](evidence/constellations-2026-10-17/README.md) responds to physical-phone feedback about sparse clears. The user confirmed five actual stars, then chose swiping and clearing only the traced subset. The [historical drawing record](evidence/constellation-trace-2026-10-17/README.md) superseded the whole-component tap pair. Current drawing belongs to the regular game; [direct polish](evidence/main-polish-2026-10-17/README.md) preserves its saves and generation.

## Notifications — planned, implementation deferred

The accepted [notification plan](design/NOTIFICATIONS.md) starts with one optional weekly reminder at a player-selected day/time, off by default and scheduled locally. No notification implementation is authorized in this batch. Inactivity reminders and custom friend-rank alerts are deferred; global rank-drop alerts are excluded. Revisit implementation only when requested.

## Gravity removed from normal play

The user selected removal after the [focused exposure review](evidence/gravity-focused-playtest-2026-10-17/README.md). New, continued and replayed skies no longer contain attraction fields or orbiting holes; the [migration record](evidence/gravity-removal-2026-10-17/README.md) preserves score, remaining stars and timing. An automatic effect remains only an idea for a later request.

## What happens next

The gravity setup mechanic is retired from normal play. Keep future work focused on clear ordinary matching, tracing, growth and readable shower pressure; do not reintroduce gravity through a pilot flag.

The [screen-flow polish plan](SCREEN_FLOW_PLAN.md) adds a bounded presentation workstream: explicit dark launch, safe Entry cancellation, pause-preserving Continue, continuous handoffs and understandable endings. Its [accepted design](design/SCREEN_FLOW_POLISH.md) now has verified launch, safe Entry, continuous handoff, explanatory result, bounded arrival and home/preferences batches; [source-bound evidence and limits](evidence/screen-flow-polish-2026-10-17/README.md) remain separate from RC/device acceptance. These batches integrate independently of gameplay experiments.

| Priority | Next action | Done when |
| --- | --- | --- |
| Establish the candidate | Retain the verified Debug/Release source record and close the [current RC blockers](ENGINEERING.md#active-debt-and-next-actions--october-18-2026); historical Xcode drift is not an active failure on this source. | The exact candidate builds and its remaining visual/upgrade gaps are explicit. |
| Make choices engaging — active | Polish the adopted Opal/storm game directly, using current native fixtures and [observed play](PLAYTEST-FALLING-SKY.md). The [native input-window check](evidence/native-input-windows-2026-10-17/README.md) exposed orbit presentation blocking; the [overlap correction](evidence/gravity-flight-overlap-2026-10-17/README.md) reopens that interval. The [partial-input diagnostic](evidence/partial-input-measurement-2026-10-17/README.md) now distinguishes admitted ordinary groups from whole-board settling. Next observe planning during falling and physical comfort; simulated reaction delays are not player difficulty estimates. Historical lab comparisons are reference only. | Opening is playable within one settled shower; long dead stretches do not return in the regression sample; a player explains a useful choice and prefers a candidate or identifies the next issue. Adopt, remove, or name a bounded remaining question. |
| Polish physical feel — active | Review arrivals, growth, clears and input on an iPhone; tune optional sound/haptics and profile repeated rounds. | Effects do not block decisions or input; effects stay bounded; device observations and profiles are retained. |
| Five night journeys — integrated | Moonwake, Nebula Cradle, Shatterlight Reach, Night Garden and Ringdrift share centered geometry and independent scenery. | [Native checks and delivery](evidence/nightscapes-2026-10-18/README.md); physical comfort and RC accessibility remain separate. |
| Explain danger and outcomes | Review nearly full columns, Dusk feeding/collapse, arrival information, overflow, replay and new sky. Keep landing places hidden and controls reachable on small screens/large text. | A first-time player explains the loss and next action; affected native input, settings dismissal and layout checks pass. |
| Finish accessibility and reliability | Complete the native/device checks below. | Evidence distinguishes automation, visual review, actual VoiceOver and device observations. |
| Prepare a shareable build | Reconcile acceptance/release docs, packaging and signing with the selected mechanics. | Reproducible signed build, known issues and device checklist; distribution only when requested. |

Owners are the current implementer unless a work item names another owner. These are workstreams, not permission to expand scope or delay an independently verified batch.

## Environment art direction

The five approved nightscapes are integrated in regular Starfall, with a shared centered field and reusable layers. [Production and acceptance](design/environments/night-production-09/README.md) owns the current work. Improve these five before proposing a sixth; their order is not a campaign or unlock sequence.

The earlier Observatory/Cloudsea/platform direction is historical. Its [production strategy](design/environments/PRODUCTION.md), [five-place bible](design/environments/landing-places-01/README.md) and [physical-groove checks](evidence/environment-grooves-2026-10-18/README.md) explain the prior decisions. The existing shooting-star forecast, native menu and character dialogue continue in the nightscape layout. Sound and haptics retain saved preferences.

## Current rhythm and historical timing evidence

Fresh survival starts empty with four quick animated showers, then uses the existing V1 rhythm at brisk pace: six 3-second, three 2.5-second and three 3.5-second intervals. [Adopted calibration](evidence/calibration-critical-mass-2026-10-18/ADOPTION.md) owns that decision; saved skies and replay retain their cadence. Gentle/steady stay fixed, and First Light stays fixed without the opening. The earlier V2/B comparison is historical; its temporary selector is removed.

The [historical gravity/phase diagnostic](evidence/current-storm-choices-2026-10-17/README.md) confirms more simultaneous sampled selections during storms in two fresh seed cohorts, while immediate Opal-preservation gains remain situational. Untimed reward policies rarely encounter active orbits; use ordinary native play for recognition, execution and combined-strategy evidence before tuning supply.

The [historical native planning check](evidence/current-opal-native-2026-10-17/README.md) follows seed 180 at the storm boundary. Its stronger follow-up comes from releasing an occupied field, while Opal remains unused. Native taps and the curved nine-light OS-input path are verified on the recorded simulator; human/physical evidence remains open. This is a prepared paused comparison, not measured storm-pressure performance.

## Historical shower-comparison decision

The following comparison describes the pre-adoption research question. Opal/storm phases are now adopted and gravity is retired; [current decisions](EXPERIMENTS.md) govern new work. These records do not authorize a new lab export or install.

**Question:** Do shower changes create useful decisions and a readable rhythm, rather than more groups that feel equivalent?

| Comparison | What the evidence says | Decision / remaining question |
| --- | --- | --- |
| [Natural Shower Lab](evidence/paired-showers-2026-10-17/README.md) | Five-star 3 + 2 runs raise clear-all multiple-choice decisions from 6.7% to 11.6%; native opening/choice comparison passed. | Lead comparison; human preference remains open. Broad pairing was rejected for excessive survival extension. |
| [Pressure Lab](evidence/pressure-showers-2026-10-17/README.md) | Consequential native clear and due-rain input boundary checked; cold-opening limitation retained. Both constant candidates offer choices by shower twenty in 160/200 first-policy rounds. | Compare pressure and comprehension in observed play. |
| [Phase Lab](evidence/shower-phases-native-2026-10-17/README.md) | Native warning/count/recovery cues exist; the [largest-text correction](evidence/phase-cue-2026-10-17/README.md) is verified. The original burst changes the first forecast in only 36/200 first-clear rounds. | Retain as the cue/flow comparison; actual VoiceOver and full-motion boundaries remain open. No production phase. |
| [Surge Lab](evidence/surge-native-2026-10-17/README.md) | Five-star bursts change that forecast in 200/200 rounds, while also extending sampled survival. [Agent-simulated play](evidence/simulated-surge-playtest-2026-10-17/README.md) provisionally preferred it. | Leading phase experiment; review threshold/growth instructions, remaining acceptance cases and human comparison before adoption. |

The user selected **shower variety and choices** to lead the next playable experiment. A separate [Shower Lab](evidence/paired-showers-2026-10-17/README.md) tests natural five-star 3 + 2 runs against the unchanged game. It raises clear-all multi-group decisions from 6.7% to 11.6%, preserves existing-save generation, and has passed a native opening/choice comparison. Broader pairing is rejected for excessive survival extension. The [higher-column Pressure Lab](evidence/pressure-showers-2026-10-17/README.md) now verifies a consequential native clear and the due-rain input boundary, while retaining its cold-opening limitation. Both candidates offer choices by shower twenty in 160/200 first-policy sample rounds; observed preference remains open. The default generator is unchanged pending observed play and pressure/comprehension review.

Preserve first-shower playability, bounded dry-board assistance, dark-star settings, save compatibility and committed previews. Measure simultaneous groups, waits without a useful move, score/survival distributions and whether clearing a high column helps. Include clear-all play; one clear per shower is a diagnostic constraint. Numeric targets are hypotheses, not release gates.

Use paused/manual explanation and normal automatic play. Record comprehension, perceived waiting, useful choices and replay preference, including failures and counterexamples. Core checks and a short actual simulator playthrough precede promotion; bot scores alone cannot choose the winner. The [experiment register](EXPERIMENTS.md) owns adoption status.

## Shipping gates — all remain open

| Gate | Required evidence / next action |
| --- | --- |
| Opening is enjoyable | Observe first-time players without coaching. Record time to first clear, waits, growth/dark-star comprehension and voluntary replay. Distinguish missed moves from no available move; respond to major confusion or waiting. |
| Each feature is complete | State observable acceptance criteria and record rule/save, interruption, accessibility, visual/full-animation and test results, including omissions. Apply [AGENTS.md](../AGENTS.md) and the [writing process](WRITING.md) throughout. |
| Exact shipping candidate is verified | After project-drift review, record clean source, configuration, toolchain and device/OS. Test fresh install and a retained previous-version save without reset: board, score, preview/RNG continuation, preferences and completed challenge. Test any migration explicitly; run current falling-sky acceptance flows. Compilation alone does not establish visual or upgrade acceptance. |
| Physical-device checks are routine | Use a smaller/older supported iPhone: repeated showers, clears, replay, background/resume and audio interruption. Record responsiveness/frame pacing, heat, energy, memory trend and leftover effects. Investigate reproducible issues with Instruments before optimizing; set measured device budgets. |
| Actual accessibility is accepted | At release-candidate acceptance, following the [development/RC cadence](DEVELOPMENT_BUILDS.md#accessibility-checks-by-build-stage), play a complete round with actual VoiceOver: location/value, matching-group rotor, activation, pause/manual advance, outcome/replay and Settings focus return. Separately inspect system Reduce Motion, largest text, contrast and identification without color alone. Labels/audits do not close this gate. |
| TestFlight feedback informs the candidate | After signing prerequisites and explicit upload/tester authorization, use approved testers and the actual Release candidate. Collect confusion, crashes, replay preference and device/build context; fix significant issues and verify again. No claim of universal enjoyment or crash-free play, and no analytics SDK. |

Reliability coverage also includes minimum-supported OS, small phone, iPad portrait/landscape, rapid taps, interruptions during arrivals, save/relaunch, replay/new sky, settings dismissal and repeated-round stress. Calm effects and paused/manual play must remain usable. Existing system Reduce Motion evidence does not close every later candidate’s acceptance.

The [engineering register](ENGINEERING.md) owns technical risks; the [release checklist](RELEASE_CHECKLIST.md) owns signing/submission details. Verify clean dependencies, privacy declaration, icons, version/build metadata and Release packaging before distribution.

## Current game and scope

Falling sky is the default in Debug and Release: a 7×7 board, five colored star families plus Opal, orthogonal matches worth 3+, growth, selected-set constellations, immediate survival exchanges, automatic showers and local pause/balance controls. Fresh survival disables aging and Dusk supply; retained Dusk rounds keep their rules. Restore/replay preserves saved cadence and validated state through the explicit retirement migrations. Full falling animations and accessible quiet alternatives remain required.

The current HUD shows score/goal, a sky menu and the ordered shower trail; one bottom character chat explains committed results. Pause and local tuning live in the menu; Start/Resume and manual advance appear while paused. [Current app boundaries](../App/README.md) and [five nightscapes](design/environments/night-production-09/README.md) supersede the older cue-only HUD. Recognition and physical comfort still need observed play.

First Light is one optional fixed-seed-42, 18-starlight challenge, with steady showers and no dark stars. Entry from Settings starts a new round. Validate completion/retry and compare goal-driven play with survival before considering more skies.

No campaign, unlocks, XP, currency, power-ups, backend, accounts, analytics, ads, purchases, paid assets or external SDKs. The original 70-jewel/18-move puzzle remains Debug regression tooling; its rules do not govern falling sky.

<details>
<summary>Supporting baseline and presentation evidence</summary>

- [Strategy baseline](evidence/falling-sky-strategy-2026-10-16/README.md): across 200 seeds, about 10% of match-ready states in one-clear-per-shower policies offer multiple groups; largest-first and first-group scores are nearly identical. This motivates investigation, not a conclusion about enjoyment.
- [Expanded baseline](evidence/mechanics-baseline-2026-10-17/README.md): clear-all offers alternatives in 6.7% of decision states; 43.0% of surviving shower states are dry, with no sampled dry run beyond one shower. Preserve those denominators in comparisons.
- Implemented feedback includes faster comets, paused clears, group outlines/count, clear rings/score popups and optional local sound/haptics. That source used sound/haptics off by default. Current new preferences enable both; saved off values are preserved. Verify immediate mute, Silent Mode and interruptions against the current app.
- The star cast is integrated in Debug and Release with shared board/comet/preview materials and non-color silhouettes: [rendering contract](design/star-cast/README.md), [native evidence](evidence/star-cast-2026-10-17/README.md). The [motion revision](evidence/star-cast-motion-2026-10-17/README.md) adds twelve frames per character, partial turns and grown/clear expressions. The [luminous revision](evidence/star-cast-luminous-2026-10-17/README.md) addresses eyes and emitted light; integration did not establish final art approval.
- Adopted [physical reactions](evidence/physical-reactions-2026-10-17/README.md) add angled arrivals, weight-sensitive rebounds and distance-delayed survivor ripples. They present committed turns; no collision-driven rules or supernova recoloring are adopted.
- [Connected contact](evidence/star-contact-2026-10-17/README.md) extends that presentation with one real receiver, local character looks, surface light and a gather/release clear. No new rule, save schema or perpetual idle action. Human, VoiceOver and device feel remain open.
- At the published [pacing tree](evidence/falling-sky-pacing-2026-10-16/README.md), local checks passed: 56 core tests, 14 store tests, seven UI checks and a Release simulator build, including real system Reduce Motion and a smaller iPhone at largest text. These historical results do not establish a new cloud run or current candidate acceptance.

</details>

<details>
<summary>Parked ideas and historical context</summary>

- [Supernova rules](evidence/supernova-rules-2026-10-17/README.md) and the [native input lab](evidence/supernova-native-2026-10-17/README.md) are parked while showers lead. Hold/release/cancel, interruption and superseded-touch checks remain recorded; ordinary clear effects and the weak tap/charge tradeoff are unresolved. Neither recoloring candidate is adopted.
- The [mechanics notebook](design/MECHANICS_IDEAS.md) retains constellations, light stars and void/drain/freeze ideas. These are deferred questions, not accepted scope.
- The [next-tranche record](evidence/falling-sky-tranche-2026-10-16/README.md) compares two offline mixed-color candidates; neither replaced the default. First Light is the one playable objective comparison.
- [Progression research](design/FALLING_SKY_RESEARCH.md) and [Mahjong research](design/MAHJONG_PROGRESSION.md) distinguish difficulty from a long level counter. If future challenge sequences are considered, vary layout, goals and pressure with relief rounds rather than assuming endlessly rising difficulty. No infinite-content generator is included.
- The [original-puzzle roadmap](archive/ROADMAP-original-puzzle-2026-10-16.md) is historical. Earlier game-bible/playtest documents describe that puzzle unless explicitly updated.
- Implementation resources, not evidence: [Instruments](https://developer.apple.com/tutorials/instruments), [accessibility settings](https://developer.apple.com/documentation/accessibility/testing-system-accessibility-features-in-your-app), [TestFlight feedback](https://developer.apple.com/testflight/).

</details>

Integrate small verified batches. Keep deterministic rules in StarfallCore, presentation and feedback explicit, saves compatible and other edits intact. Update this roadmap as decisions change; preserve historical evidence with its source context.


The user also proposed events or phases within a level. [Phase Lab](evidence/shower-phases-native-2026-10-17/README.md) now provides nine preparation showers, a warned three-shower pressure burst and recovery in an isolated native export. Next: matched observed play and comprehension review against Shower Lab; retain the [verified largest-text cue correction](evidence/phase-cue-2026-10-17/README.md), then resolve actual VoiceOver and full-motion validation before adoption. No campaign or new level progression is introduced.


The [burst exposure audit](evidence/burst-exposure-2026-10-17/README.md) changes the next phase question: original first bursts change a forecast in 36/200 first-clear rounds; a five-star surge does so in 200/200, but also extends survival. The [isolated Surge Lab](evidence/surge-native-2026-10-17/README.md) now provides explicit five-star wording and separate saves; next is simulated and human observed comparison. Retain the original Phase Lab only for that cue/flow comparison, then select/remove or name a remaining question. Do not infer difficulty or enjoyment from the additional choices.


The user-requested [agent-simulated play comparison](evidence/simulated-surge-playtest-2026-10-17/README.md) provisionally preferred Surge: it reported preparing before the event and prioritizing a high dark-star-adjacent group. This is paused agent observation, not human enjoyment or a controlled score comparison. Keep Surge as the leading phase experiment. The [shared startup introduction](evidence/clearing-introduction-2026-10-17/README.md) now states the value threshold and grown-plus-small example; [Seed-five rapid-input and due-rain boundaries](evidence/burst-input-2026-10-17/README.md) are now verified; learner comprehension and other acceptance limits remain open before adoption.

The [extended survival sample](evidence/surge-survival-2026-10-17/README.md) resolves the initial 60-shower censoring for these 200 seeds: every round ended before 240 under all six policies, with Surge clear-all median 38 and maximum 126 versus natural-only median 30 and maximum 82. Idle rounds end sooner with surges while active clearing lasts longer. Keep the current cadence for comparison; do not add a tuning variant from these bot results alone.

The [expanded save check](evidence/shower-legacy-2026-10-17/README.md) verifies 160 current and 160 synthetic marker-absent save continuations plus restored/new First Light through completion under Surge. Replay/new-sky generation selection and real historical-install upgrades remain adoption work; this does not change the human comparison decision.

[Compact phase HUD fit](evidence/compact-phase-2026-10-17/README.md) is now playable as Surge Lab HUD: native clears, sticky largest-text cues, restore, full-motion samples and Release build checked. Next phase decision: observe whether preparation/recovery changes useful clears without exact preview information, then select/remove the old HUD comparison. This does not establish current Observatory/physics parity or human preference.

Main-alignment decision: the [simulated HUD follow-up](evidence/simulated-compact-playtest-2026-10-17/README.md) does not accept the newer Observatory interface. Preserve the measured rule/save results, but move further phase/feedback comparison to a source-bound Observatory snapshot using its existing guide, trail and shared geometry. No further old-HUD variants; production generation remains unchanged.

The [integrated Observatory mechanics pair](evidence/observatory-phases-2026-10-17/README.md) is the current phase-comparison route. Its isolated natural/Surge generators preserve baseline save continuation and have current native phase/focus/activation checks. Next observe ordinary-text choices, resolve maximum-text baseline play and listen to automatic announcements; then decide adoption/removal. It adds timeboxed events within the existing sky, not campaign progression.

The [completed Observatory agent comparison](evidence/observatory-phases-2026-10-17/playtest.md) makes paused outcome feedback the next refinement: explain committed growth and dark-star outcomes while preserving quiet flowing play. Keep the generator stable for that comparison; verify the feedback and an uncoached opening before interpreting familiarity-assisted success as player comprehension.

[Paused outcome feedback](evidence/paused-feedback-2026-10-17/README.md) is implemented in the isolated pair and has current native/Release checks. Keep rules stable while judging whether its growth/dark feedback improves comprehension; the maximum-text board/guide boundary remains a separate acceptance gap.

The [paused-feedback simulated follow-up](evidence/paused-feedback-2026-10-17/playtest.md) supports retaining the guide refinement in the pair. The guide is now [adopted independently on production rules](evidence/paused-guide-adoption-2026-10-17/README.md). The [maximum-text board/guide boundary](evidence/accessible-terrace-layout-2026-10-17/README.md) is now corrected on portrait 17e/SE3. [Native VoiceOver round checks](evidence/voiceover-round-2026-10-17/README.md) now pass on 17e/SE3. Return to the [different-seed storm-choice comparison](evidence/storm-choice-followup-2026-10-17/README.md), then obtain uncoached human comparison before adopting Surge. Preserve the separate rule/save decision.

[VoiceOver gameplay flows](evidence/voiceover-gameplay-2026-10-17/README.md) now cover ordinary First Light completion/restore/replay, automatic play/menu/background, and maximum-text overflow/replay on 17e. Automatic nonterminal showers stay quiet during exploration. Keep device/custom-rotor acceptance separate. The [guide-name typography polish](evidence/guide-typography-2026-10-17/README.md) now restrains Sunny while preserving readable primary text and controls.

The selected [overlapping sky flow](design/SKY_FLOW.md) adds Welcome/Resume, explicit Begin and separate win/full-sky endings. It extends the adopted drawing game; integration verification is recorded with the flow evidence.

The user selected the [curved shower forecast](evidence/shower-forecast-adoption-2026-10-17/README.md). It is default on calibrated iPhone 17 portrait; other hardware and accessible layouts retain a complete straight header forecast. Next verify physical fit/system-island expansion and forecast recognition before adding more camera profiles. The lower arc remains unused.

**Historical pacing decision (October 17; fresh V1 calibration supersedes new-sky V2):** The user selected the announced cycle for normal new skies and requested PR → main → existing-phone delivery. [Adoption and acceptance](design/PACING_ADOPTION.md) supersedes the comparative session requirement; enjoyment and device feel remain unmeasured until observed.

## Historical integration follow-ups

These dated notes retain the original sources and next actions. The current engineering index and decisions above own remaining work.

### Reliability integration

The [scoped reliability design](design/RELIABILITY_POLISH.md) closes terminal touch ownership, package build identity and local-canvas camera placement in regular Starfall. Retain physical expanded-Island, curved/multitouch, haptic/recognition and actual VoiceOver acceptance as explicit next-device/RC work; no additional lab or speculative hint/performance framework is required.

The retired gravity art remains only for historical reset-only Debug reproductions: an open attraction field and accretion-ring hole with shared cached materials. [Art acceptance](evidence/gravity-art-2026-10-17/README.md) records native checks separately from the remaining human gameplay study.

[Device delivery guards](evidence/device-delivery-guards-2026-10-18/README.md) now detect external app replacements and reject stale delivery through the canonical updater. Privileged direct installation remains an OS/account permission boundary; no gameplay change is part of this fix.

**Five-place integration, October 18:** all five locations have remembered selection and independent responsive props. Work was initially based on `f35eba8`; the user identified obsolete star circles, prompting reconciliation onto current main `ac6aeb3`. The current renderer, gestures, dialogue and v7 saves are preserved. [Current acceptance status](design/environments/production-set/README.md).

The shared responsive foundation now separates stage, interactive props and extensible scenery. Compact landscape moves communication beside the stage; short narrow/accessibility layouts scroll. Compare soft inlays, curved ledges and a carved frame as later visual treatments; the first rigid sheet is not approved. Native source, tested sizes and remaining limits stay in the integration evidence.

The user corrected the UI-fitting scope: score and communication grooves must exist in the environment artwork. Functional responsive layout is integrated, but the floating panel treatment is incomplete. Replace it with physically connected upper-ledge/lower-apron (or side-wing) recesses, keeping native content and shared hit geometry. The [board template](design/environments/BOARD_TEMPLATE.md) records the corrected contract and concept; framing shape remains flexible.

**Physical fittings follow-up:** The regular app now uses five connected illustrated control rails/floors/message aprons, with a landscape wing and extensible surrounding wallpaper. Current main `33ae6fb` supplies the preserved gesture/copy baseline. [Native verification and remaining device/RC limits](evidence/environment-grooves-2026-10-18/README.md) supersede the earlier floating-panel completion gap above; material preference remains a human review decision.

Final environment source reconciles latest origin/main `1ed6290`; 152 Core tests, 239 hosted methods and focused current native input checks pass. [Phone/tablet physical-groove gallery and acceptance limits](evidence/environment-grooves-2026-10-18/README.md#inspected-native-presentation).

The [crowded celebration check](evidence/calibration-critical-mass-2026-10-18/AWARDS.md) adds a current-rule regression sample and four native host layout/text comparisons. Keep the current presentation; next assess repeated automatic/physical recognition, including the observed temporary survivor overlap.

The [follow-up debt batches](TECH_DEBT_FOLLOWUP.md) now verify exact contact remainders, tablet Welcome native hit semantics, semantic archive admission, retained RC failure evidence and rules-aware Help. Visible save-recovery feedback is also verified; all six scoped batches are complete. Minimum-iOS, actual VoiceOver and physical-device RC evidence remain open.

The [third debt pass](TECH_DEBT_THIRD_PASS.md) closes terminal gravity-restore crashes, primary CI simulator timeout/ownership gaps, tablet ceremony control clearance and default-game screenshot gating in separate batches. Current simulator evidence remains distinct from actual VoiceOver, minimum-iOS and physical-device RC acceptance.
