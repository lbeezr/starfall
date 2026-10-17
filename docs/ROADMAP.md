# Starfall roadmap

**Status:** Active · **Owner:** Current implementer · **Updated:** October 17, 2026, Eastern time

Build a small, readable falling-sky puzzle worth replaying. **Shower variety leads the next gameplay comparison.** Keep the default generator unchanged until observed play supports adoption. Phase and Surge native trials now exist; the agent-simulated comparison provisionally favors Surge, but human preference remains unverified.

**Next actions:** Review the clean Release baseline as its own change, then review the existing warning/burst/recovery trials and observe matched play. Physical feel can be reviewed independently in small batches.

**Open limits:** No participant preference results, final cast approval, general physical-device acceptance, or actual VoiceOver acceptance. These remain open even where simulator checks passed.

## The game we are improving

<img src="evidence/compact-hud-2026-10-17/active.png" width="240" alt="Native gameplay capture with a compact score and menu header above the star board">

**Source-bound native reference:** October 17 compact-HUD candidate, iPhone 17e / iOS 27.0 Simulator; [capture source and verification limits](evidence/compact-hud-2026-10-17/README.md). The compact layout is adopted, but this capture does not establish current-build parity or human preference. See the [icon, opening screen and cast](design/VISUAL_REFERENCE.md) for the visual context behind the workstreams below.

## What happens next

| Priority | Next action | Done when |
| --- | --- | --- |
| Establish the candidate | Resolve the [Xcode project drift](ENGINEERING.md) in a separate reviewed change; retain a clean Release source/build record. | The exact candidate builds and its remaining visual/upgrade gaps are explicit. |
| Make choices engaging — active | Compare natural Shower Lab, Pressure Lab, and one [announced phase trial](design/SHOWER_PHASES.md), using matched seeds and [observed play](PLAYTEST-FALLING-SKY.md). | Opening is playable within one settled shower; long dead stretches do not return in the regression sample; a player explains a useful choice and prefers a candidate or identifies the next issue. Adopt, remove, or name a bounded remaining question. |
| Polish physical feel — active | Review arrivals, growth, clears and input on an iPhone; tune optional sound/haptics and profile repeated rounds. | Effects do not block decisions or input; effects stay bounded; device observations and profiles are retained. |
| Explain danger and outcomes | Review nearly full columns, blocked growth, arrival information, overflow, replay and new sky. Keep landing places hidden and controls reachable on small screens/large text. | A first-time player explains the loss and next action; affected native input, settings dismissal and layout checks pass. |
| Finish accessibility and reliability | Complete the native/device checks below. | Evidence distinguishes automation, visual review, actual VoiceOver and device observations. |
| Prepare a shareable build | Reconcile acceptance/release docs, packaging and signing with the selected mechanics. | Reproducible signed build, known issues and device checklist; distribution only when requested. |

Owners are the current implementer unless a work item names another owner. These are workstreams, not permission to expand scope or delay an independently verified batch.

## The next gameplay decision

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
| Actual accessibility is accepted | Play a complete round with VoiceOver: location/value, matching-group rotor, activation, pause/manual advance, outcome/replay and Settings focus return. Separately inspect system Reduce Motion, largest text, contrast and identification without color alone. Labels/audits do not close this gate. |
| TestFlight feedback informs the candidate | After signing prerequisites and explicit upload/tester authorization, use approved testers and the actual Release candidate. Collect confusion, crashes, replay preference and device/build context; fix significant issues and verify again. No claim of universal enjoyment or crash-free play, and no analytics SDK. |

Reliability coverage also includes minimum-supported OS, small phone, iPad portrait/landscape, rapid taps, interruptions during arrivals, save/relaunch, replay/new sky, settings dismissal and repeated-round stress. Calm effects and paused/manual play must remain usable. Existing system Reduce Motion evidence does not close every later candidate’s acceptance.

The [engineering register](ENGINEERING.md) owns technical risks; the [release checklist](RELEASE_CHECKLIST.md) owns signing/submission details. Verify clean dependencies, privacy declaration, icons, version/build metadata and Release packaging before distribution.

## Current game and scope

Falling sky is the default in Debug and Release: a 7×7 board, five jewel kinds, orthogonal matches worth 3+, growth, dark stars, automatic showers, pause, manual next shower and local balance controls. Full falling animations and accessible reduced-motion alternatives remain required. Existing saves retain their generation behavior.

The [compact HUD](evidence/compact-hud-2026-10-17/README.md) uses score/goal, a quiet menu and an arrival cue instead of exact forecast/countdown/status rows. Pause is in the menu; Start/Resume and manual advance appear while paused. **Whether that simplification preserves useful decisions still needs observed play.** Any phase cue must work within that constraint.

First Light is one optional fixed-seed-42, 18-starlight challenge, with steady showers and no dark stars. Entry from Settings starts a new round. Validate completion/retry and compare goal-driven play with survival before considering more skies.

No campaign, unlocks, XP, currency, power-ups, backend, accounts, analytics, ads, purchases, paid assets or external SDKs. The original 70-jewel/18-move puzzle remains Debug regression tooling; its rules do not govern falling sky.

<details>
<summary>Supporting baseline and presentation evidence</summary>

- [Strategy baseline](evidence/falling-sky-strategy-2026-10-16/README.md): across 200 seeds, about 10% of match-ready states in one-clear-per-shower policies offer multiple groups; largest-first and first-group scores are nearly identical. This motivates investigation, not a conclusion about enjoyment.
- [Expanded baseline](evidence/mechanics-baseline-2026-10-17/README.md): clear-all offers alternatives in 6.7% of decision states; 43.0% of surviving shower states are dry, with no sampled dry run beyond one shower. Preserve those denominators in comparisons.
- Implemented feedback includes faster comets, paused clears, group outlines/count, clear rings/score popups and optional local sound/haptics. Keep sound/haptics off by default, mute immediate, and check silent mode and interruptions.
- The star cast is integrated in Debug and Release with shared board/comet/preview materials and non-color silhouettes: [rendering contract](design/star-cast/README.md), [native evidence](evidence/star-cast-2026-10-17/README.md). The [motion revision](evidence/star-cast-motion-2026-10-17/README.md) adds twelve frames per character, partial turns and grown/clear expressions. The [luminous revision](evidence/star-cast-luminous-2026-10-17/README.md) addresses eyes and emitted light; integration did not establish final art approval.
- Adopted [physical reactions](evidence/physical-reactions-2026-10-17/README.md) add angled arrivals, weight-sensitive rebounds and distance-delayed survivor ripples. They present committed turns; no collision-driven rules or supernova recoloring are adopted.
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

The user-requested [agent-simulated play comparison](evidence/simulated-surge-playtest-2026-10-17/README.md) provisionally preferred Surge: it reported preparing before the event and prioritizing a high dark-star-adjacent group. This is paused agent observation, not human enjoyment or a controlled score comparison. Keep Surge as the leading phase experiment. The [shared startup introduction](evidence/clearing-introduction-2026-10-17/README.md) now states the value threshold and grown-plus-small example; learner comprehension and remaining acceptance limits are still open before adoption.
