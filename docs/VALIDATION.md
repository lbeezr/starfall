# Validation record

2026-10-16 UTC, Linux cloud workspace.

## Executed successfully

- Official Swift 6.0.3 release toolchain downloaded from download.swift.org into temporary workspace (no system install)
- Pure package debug build and **12 XCTest tests passed, 0 failures**, 0.434 seconds test time
- Includes 200 deterministic initial boards and complete plays over 100 seeds
- Swift frontend syntax parsing of both App source files passed; **this is not Apple SDK type-checking or an iOS build**
- Shared Xcode scheme XML parsed successfully
- Shell syntax check of CI script passed
- Independent source review; VoiceOver animation-lock issue and gravity test fixture repaired, regression coverage expanded

Exact core command (temporary tooling/cache paths are environment-specific):

```sh
CLANG_MODULE_CACHE_PATH=/tmp/starfall-swift/clang-cache \
 /tmp/starfall-swift/swift-6.0.3-RELEASE-ubuntu22.04/usr/bin/swift test \
 --cache-path /tmp/starfall-swift/cache \
 --config-path /tmp/starfall-swift/config \
 --security-path /tmp/starfall-swift/security
```

The initial unconfigured invocation failed before compilation because its default home-directory compiler cache was read-only. The successful command explicitly used writable temporary build/cache locations and did not change permissions or write the home cache.

## Not run / blocked

- iOS app build and link: Xcode and Apple SDKs are unavailable in this Linux environment
- Simulator/device launch, screenshots, animation inspection and accessibility testing
- GitHub workflow execution: manual workflow is prepared, not dispatched
- App Store/device distribution signing

No visual or device quality claim follows from these core test results. See `ACCEPTANCE.md` for remaining runtime checks. The manual cloud workflow describes a future Apple-tooling validation route, not evidence of a completed run.

## Independent exact-head rerun

2026-10-16 01:57:53 UTC: core tests independently rerun at
`b884b452ff9c2832f19fea0fc85fe4cea662f674` with the same explicit writable-cache
command above. All 12 XCTest cases passed, zero failures, 0.53 seconds test time.
No Apple SDK, simulator or physical-device validation was performed.

## First native cloud evidence

Run https://github.com/lbeezr/starfall/actions/runs/38840259665 succeeded at
source `15d068b6231d7fbb8f5c05867361419c549c5bb6` on Xcode 26.3 / Swift 6.2.4 /
ARM64 with iPhone SE (3rd generation), iOS 26.2 Simulator. All 12 core tests
passed and the native app built. Initial and post-clear settled launches stayed
alive and produced inspected screenshots. Initial HUD: 0/70, 18 moves; settled:
3/70, 17 moves. These were separately launched deterministic states, not evidence
of a performed touch gesture or observed animation. Physical-device behavior and
accessibility are still unverified. Later source changes need their own run.

## Native interaction and glass-material acceptance — 2026-10-16

- Owner: native interaction/CI lane; independently reviewed incremental source.
- Accepted source: `26d76f6473268d2d62fcc3e45079e1d10d7e783e`.
- Evidence: https://github.com/lbeezr/starfall/actions/runs/38843933811 — successful; Xcode 26.3, iPhone SE (3rd generation), iOS 26.2 Simulator.
- Core: 12 tests passed. Native build passed. One XCUI flow passed with zero failures (49.653 seconds).
- Actual coordinate tap cleared three jewels, changed score from 0 to 3 and moves from 18 to 17. Menu/Continue retained the game. Sound on/off and reopened muted state passed. Restart restored 0 score and 18 moves.
- Named native screenshots: `real-touch-post-clear` captured 2026-10-16 03:16:57.570 UTC; `real-touch-restarted` captured 03:17:25.464 UTC. Both exported and SHA-256 verified; human inspection found legible HUD, distinct glass silhouettes and no obvious clipping/error overlay.
- Artifact: `12023145003`, 1,747,618 bytes, one-day GitHub retention. Screenshot copies are retained separately; CI links may outlive artifacts.
- Earlier failures were kept visible: run 38841903130 failed pre-tap score-label assertion; run 38843063380 passed the tap/Continue but failed sound-toggle assertion. Explicit accessible score labeling and switch-control targeting were reviewed and verified by the accepted run.
- Scope: simulator interaction and settled rendered states. This does not establish physical-device performance, real VoiceOver usability, rapid-input exclusion, animation aesthetic quality, signed distribution or release readiness.
- Next permitted transition: bounded remaining MVP acceptance, keeping deterministic core separate from presentation. Physical-device/TestFlight delivery depends on separately established Apple signing/account access; no new access or purchases inferred.

## Save/relaunch and Calm Effects acceptance — 2026-10-16

- Owner: resume reliability lane; independently reviewed source `8fa040ba6a092dfbe986522571298f61c17857a3`.
- Successful exact-head run: https://github.com/lbeezr/starfall/actions/runs/38846694217 . Xcode 26.3, iPhone SE (3rd generation), iOS 26.2 Simulator.
- 14 core tests passed; native build passed; exactly two UI tests passed, zero failures/skips. Original flow: 45.956 seconds. Persistence/resume flow: 75.828 seconds.
- Fixed initial-board loss before the first move by saving on Play. Native test proved the original seeded board survives relaunch over a different fallback seed, then verified committed-turn relaunch, settled Home/activate, persisted Calm Effects and another legal move (score 7, moves 16).
- Shared presentation settlement cancels root/child animation and renders committed rules state when inactive or motion reduction becomes enabled. This does not prove rapid interruption during the 480 ms animation or system accessibility usability.
- Four named XCTest screenshots exported and SHA-verified. Resumed and Calm-turn captures show legible score/moves and no obvious clipping/error overlay. Evidence checked 2026-10-16 03:50 UTC.
- Artifact `12023493229`: 2,543,851 bytes, one-day retention; copies retained separately. Existing spending, single-simulator and access boundaries unchanged.
- Next acceptance gaps: rapid-input/in-flight interruption, actual VoiceOver, broader device/layout coverage and signed physical-device distribution remain separate. No new game features or release-readiness claim implied.

## Terminal outcome and replay acceptance — 2026-10-16

- Owner: endgame acceptance lane; independently reviewed source `88738c204e8b33698da9de89334893480faa9a94`.
- Successful run: https://github.com/lbeezr/starfall/actions/runs/38862074669 . Xcode 26.3/17C529, iPhone SE (3rd generation), iOS 26.2 Simulator.
- 15 core tests, native build and exactly three UI flows passed, zero failures/skips. Terminal flow: 72.342 seconds; total UI execution: 197.139 seconds.
- Fixed restored terminal saves displaying generic tap instructions. Shared outcome messaging now applies both after a final move and after saved-state restoration.
- DEBUG-only fixtures replay real legal moves to the penultimate state; native input performs the final tap. Both outcomes retain score/moves/message after an extra tap and argument-free relaunch, then restart successfully. This is deterministic acceptance, not evidence of player difficulty or natural-play balance.
- Six named UI captures exported; all eight PNGs including smoke images and the ZIP were hash-verified. Human review at 06:47 UTC found clear terminal feedback and visible New game controls without obvious clipping: win 70/70 with 2 moves; loss 64/70 with 0 moves.
- Artifact `12029922915`, 3,328,976 bytes, expires 2026-10-17 06:45:13 UTC. Retained evidence copies exist separately.
- Coverage nuance: the winning post-terminal tap targets a legal four-jewel group; the losing fixture ends without legal groups, so that repeated tap verifies terminal UI stability but does not isolate the core loss guard.
- Remaining gates stay separate: actual VoiceOver, rapid/in-flight interruption, broader device/layout coverage, physical-device performance and signed distribution. No new feature or release-readiness claim.


## Accessibility and privacy checkpoint — 2026-10-16 12:27 UTC

- Runtime `2f2bb2081de01a6d31dfe62a694f6005cf7dbe56`, run https://github.com/lbeezr/starfall/actions/runs/38898933808 : failed fourth UI flow on Settings `Text clipped`, identifying Calm effects.
- 15 core tests, native build, three previous UI flows and semantic bundled privacy-manifest comparison passed. Large-text gameplay reached and passed its scoped audits. No complete accessibility or VoiceOver pass is claimed.
- All eight named UI captures were exported under `partialEvidenceOnly: true`; ZIP and all ten PNG hashes verified. Settings screenshot inspected and retained; visible wrapping alone does not overrule the native audit failure.
- Artifact `12045617965`: 3,803,271 bytes, expires 2026-10-17 12:24:38 UTC. Source-bound copies retained separately.
- Prior run 38896574407 hit its 15-minute job limit during cold simulator preparation, before any audit assertion. Current bounded setup timing succeeds: status-bar 15.725 seconds, install 33.567 seconds, first launch 17.77 seconds, second launch 1.084 seconds. Job maximum is now 25 minutes; per-test maximum remains 180 seconds; no retries or broader permissions introduced.
- Open gate: diagnose accessible text bounds/row sizing, review the minimal repair and rerun all four UI flows. Prepared interruption tests and approved icon registration are not yet integrated or natively validated.

## 2026-10-16 13:25 UTC — reliability and icon native evidence

Exact runtime `3405595abad1c66181d74ce0ed0c2304007df64c`, [run 38905933131](https://github.com/lbeezr/starfall/actions/runs/38905933131): native build, 15 core tests, four hosted tests (zero failures/skips), three prior UI flows, icon catalog packaging and privacy semantic validation passed. The fourth UI flow failed the unsuppressed Settings text-clipping audit on Calm effects. Eight UI screenshots remain partial evidence; the total build is failed.

The hosted tests cover controlled presentation completions, committed saved state and busy-input rejection. They do not establish real rapid-tap delivery or actual frame-timed interruption. Icon Assets.car and AppIcon metadata passed packaging; Home Screen appearance is not yet verified.

Artifact `12048743235` (3,803,747 bytes) expires 2026-10-17 13:24:45 UTC. Retained ZIP SHA-256 `4161c0be585e9c5b97635116c2773ab73fedb9989c428268a014b844fa4d6a33` and all ten PNG hashes verified. Native diagnostics showed Calm effects text frame `(32,355.5,153.5,125.5)` within a `(16,336.5,343,163.5)` switch row. Extra vertical padding did not fix the audit; the next candidate changes actual large-text layout rather than suppressing the issue.

## 2026-10-16 13:42 UTC — cold simulator launch timeout

Exact source `ae01b99f44d7871e7211861377932e75ed5c05e0`, [run 38908327230](https://github.com/lbeezr/starfall/actions/runs/38908327230): 15 core tests, native build, icon packaging and privacy validation passed. The first `simctl launch` exceeded its 300-second bound (300.940 seconds, exit 124); no PID was returned. Status-bar setup (6.731s) and install (18.618s) succeeded. No UI tests, hosted tests or screenshots were reached. This is an infrastructure/launch failure, not evidence that the Settings repair passed or failed its audit; the cause beyond the blocked launch remains unknown.

Compact artifact `12049866811` retained and verified, SHA-256 `e6c9b7aea9ccefa5b68c9a5200ae6791e25de899f483a8ed962d7d39601a477c`, expires 2026-10-17 13:40:05 UTC. The next reviewed source is to be tested on a fresh runner with the same time and evidence limits.

## 2026-10-16 14:01 UTC — native crystal pilot and remaining Settings audit

Runtime `d856a08a0792fc745e0c871dc4c90599f78f7505`, [run 38911131017](https://github.com/lbeezr/starfall/actions/runs/38911131017): 15 core tests, nine hosted tests, native build, privacy and icon packaging passed. Four of five UI flows passed, including real aqua pilot input (26.011 seconds), normal gameplay/navigation, persistence and terminal outcomes. The largest-text Settings audit still failed; no global pass is claimed.

Inspected `crystal-pilot-before-tap.png` and `crystal-pilot-after-tap.png` show the faceted aqua artwork, a physical input changing score 0 to 3 and moves 18 to 17, and the resulting board. These settled stills do not prove tilt/fracture playback or frame pacing. The five renderer tests cover asset availability, immediate settlement, action cleanup and the 48-fragment cap using controlled scene conditions; elapsed GPU animation remains unverified.

Artifact `12050821982` is 4,570,581 bytes, expires 2026-10-17 14:00:27 UTC. Retained ZIP and all twelve PNG hashes were verified. Full-width Settings toggles are visible, but the current error has no element-specific detail. The informational text extends beyond the viewport; that alone is not evidence of defective clipping in a scrollable Form. A logging-only audit handler is the next diagnostic, with all issue failures preserved.

## 2026-10-16 19:06 UTC — local design-system and gameplay integration

- Three disjoint priority/Fast agent lanes delivered deterministic matching groups/save validation, bounded renderer/arrival improvements, and shared presentation tokens/primitives across menu, HUD, results and Settings. The root integrated store feedback and native interaction coverage. Runtime source is now checkpointed locally at `3424b09`; CI coverage gates at `8d2d101`. Earlier foundation/core checkpoints are listed in `docs/evidence/swarm-2026-10-16/source-and-product.json`.
- Xcode 27.0, iOS 27.0, arm64 iPhone 17 Pro Simulator: 27 core tests passed. One full native run passed all 34 hosted tests and 10 UI tests, zero failures/skips. Release simulator build passed. Bundled privacy declaration matches source, AppIcon metadata is present, and no ad/IAP/tracking framework or remote Swift package was introduced.
- Real UI input covered normal play, free invalid taps, cancelled drag, rapid double tap, menu/continue, restart, relaunch, settled background/resume, Calm Effects, the five DEBUG artwork families and terminal restoration. A real final tap wins at 73/70 with zero moves; the raw score remains truthful and the progress rail caps at its goal. Hosted tests cover cancellation and stale-callback boundaries separately from physical input timing.
- Shared component ownership and accessibility/motion contracts are recorded in `docs/design/DESIGN_SYSTEM.md`. The native accessible-board fixture exercises actual cell controls but does not enable VoiceOver. Settings excludes/restores underlying gameplay in the accessibility hierarchy across presentation/dismissal.
- The three unsuppressed audit types pass the tested largest-text menu/game positions, expanded normal-size Settings, and maximum-size Settings after revealing the final footer. The initial medium-height sheet's earlier `textClipped` finding remains unresolved, despite visibly readable text. Its native diagnostic and screenshot are retained. A passing expanded-sheet audit does not close this separate finding or prove its cause.
- All 30 required named screenshot contracts were checked. Eight passing images and the medium-sheet failure image are retained with hashes. After the full suite, one screenshot was moved before the audit because the audit can change scrolling; a focused native test passed again, and the corrected capture visibly includes the entire footer. No production code or assertions changed. Both test-source hashes and the supplemental result are recorded.
- Incremental integration was checked from committed snapshots: the design-system foundation (`1c34a6a`) builds independently; the renderer checkpoint (`1823e5b`) builds and passes all 34 hosted tests without the subsequent screen changes. CI shell syntax and all 11 embedded Python blocks passed validation; source gates count 10 UI and 34 hosted methods.
- Evidence: `docs/evidence/swarm-2026-10-16/README.md`, native summary, source/product hashes and screenshot manifest. Temporary full result: `/tmp/starfall-swarm-accepted.xcresult`. No cloud CI run or remote branch update was made by this wave; the local Git push was denied for its configured account.
- Remaining acceptance: actual VoiceOver speech/rotor/focus, actual system Reduce Motion operation, minimum-size/iPad layouts, keyboard focus, Increase Contrast, animation/frame pacing, audible/haptic feel, physical devices and human play balance. No complete accessibility, distribution or release-readiness claim is made.

## 2026-10-16 19:21 UTC — publication through the connected GitHub plugin

- The earlier local Git HTTP 403 was an identity mismatch: command-line Git used `lbliii`, while the connected GitHub plugin has write access as `lbeezr`. The plugin published all seven verified checkpoints plus the incremental-workflow instruction commit. No credential or permission changes were needed.
- Published code/evidence head: `6c163c58b8949e2741efba0186f9adc42ca4aed0`. Tree `173a32a477f3d01eb923c7ca70f4c428afaf4e3d` exactly matches local checkpoint `8877b06e2d31ab5cbf84b4421e2a6728dcd4d10c`. Each blob and each intermediate checkpoint tree was SHA-verified before the non-force, expected-head update of main. See `docs/evidence/swarm-2026-10-16/publication-map.json`.
- This follow-up changes publication records only. Production/test sources still match the retained validation hashes; no additional application tests are necessary for these documentation edits. Remote push-triggered CI is a separate result. The previously documented Settings and manual accessibility limits remain open.

## 2026-10-16 19:49 UTC — CI success and incremental follow-up fixes

- Cloud run [38954256452](https://github.com/lbeezr/starfall/actions/runs/38954256452) passed at `6c163c58`: 27 core, 34 hosted and 10 UI tests, zero native failures/skips, all 30 named screenshot contracts and two smoke captures. All 32 artifact PNG hashes matched. Xcode 26.3/iOS 26.2 on iPhone SE (3rd generation) adds a 375-point phone to automated coverage. The 21m23s job duration came from cold setup and sequential UI execution; no defect or diagnostic stall was found.
- Merged [PR #5](https://github.com/lbeezr/starfall/pull/5): restore neutral scale/texture when a valid turn interrupts an invalid-tap nudge, with an actual-animation regression in both rendering modes. Keep already-settled refill sprites instead of rebuilding them again; no measured performance claim.
- Merged [PR #7](https://github.com/lbeezr/starfall/pull/7): Settings opens directly in a large native sheet at every text size. The normal presentation is audited directly; the retired medium-sheet finding remains unresolved historical evidence. The shared design-system owner reviewed the new normal and maximum-text captures.
- On the combined source `0d4ebe6b`, local Xcode 27/iOS 27 iPhone 17 Pro checks passed: 27 core tests, all 35 hosted tests, all 10 UI tests, Release simulator build, and the actual CI attachment gate with all 30 named captures. Native passes have zero failures/skips. The 37-test focused run preceded the full 10-UI rerun; counts are not added as distinct tests. Source hashes and compact summaries are retained in `docs/evidence/ci-followup-2026-10-16/`.
- New cloud run [38957215784](https://github.com/lbeezr/starfall/actions/runs/38957215784) is in progress at this recording. A 15-minute coordinator heartbeat watches CI, repairs evidenced failures, and continues disjoint Fast-mode work with small verified merges. Actual VoiceOver speech/focus, physical-device feel and frame pacing remain separate acceptance work.

## 2026-10-16 20:33 UTC — adaptive tablet layout and compact-phone acceptance

- Shared layout tokens now select a board/sidebar arrangement in spacious landscape windows, retaining the stacked layout on phones, portrait and accessibility text sizes. One SpriteKit scene survives reflow; real taps verify state and mapping after rotation.
- Local Xcode 27/iOS 27: 27 core tests, four iPad mini UI cases and four iPhone SE (3rd generation) UI cases passed; native summaries report zero failures/skips. Release simulator build passed. iPad cases include largest-text audits and win/loss/final-move-win restoration; phone cases include rapid/cancelled taps, Settings swipe dismissal, saved-game and settled Calm resume.
- Full-screen iPad initial/post-play and compact-phone initial captures were visually inspected. Malformed older landscape app.screenshot attachments are excluded from visual acceptance. Native audits do not establish actual VoiceOver usability. A temporary phone shell-wrapper/log issue is documented separately from its complete passing XCTest bundle.
- Evidence and exact source hashes: `docs/evidence/adaptive-2026-10-16/`. Preceding cloud audio run [38960840647](https://github.com/lbeezr/starfall/actions/runs/38960840647) passed 27 core, 45 hosted and 11 UI tests. The adaptive change will have its own subsequent CI result.


## 2026-10-16 21:09 UTC — default five-crystal artwork adoption

- The sealed v2 family now supplies all five normal Debug/Release jewel types without an artwork flag. The existing bounded loader caches complete-family success/failure; a missing or malformed member selects the complete procedural fallback. Original Debug Aqua comparison remains separate. No game rules, shared design tokens, project dependencies or network/monetization features changed.
- Production source `127c057` passed 27 core and 11 catalog tests, all 47 Debug hosted cases and 11 of 12 UI cases in a full run. That run remains failed: a terminal relaunch query disagreed with the visible menu. A narrow test-only fresh-query repair at `41f6461` preserved every timeout/assertion and separately passed all three terminal outcomes/restarts. Do not describe this as a single 59-test passing run.
- Eight focused Release hosted cases passed with test-only ENABLE_TESTABILITY enabled and Release optimization retained. The ordinary non-testable Release simulator build also passed and launched on the compact phone without arguments. Its menu capture was inspected. Extra manual Release phone/iPad taps could not be performed while the Mac was locked; no such pass is claimed.
- A separate iPad mini native adaptive case passed with the new artwork: real taps, rotation/reflow, Settings dismissal, menu/continue and restart. Full-screen initial and post-play captures were inspected alongside compact-phone and terminal captures; all five shapes, board spacing and shared sidebar remain clear. Native summaries have zero failures/skips for these focused runs. Still images do not establish animation pacing.
- Preceding adaptive cloud run [38963283093](https://github.com/lbeezr/starfall/actions/runs/38963283093) passed 84 tests (27 core, 45 hosted, 12 UI), with 35 screenshot hashes verified. The crystal revision requires its own later cloud result. Evidence, exact source/resource hashes, original failure and focused results are retained in `docs/evidence/crystal-adoption-2026-10-16/`.
- Actual VoiceOver speech/focus, system Reduce Motion, physical-device behavior and human play balance remain outside these results. A captured maximum-text scroll/status-bar overlap is being handled as a separate shared-viewport polish batch.


## 2026-10-16 21:38 UTC — safe-area scroll clipping

- Source `3f4f4cf` adds two foreground viewport boundaries so maximum-text content stops below the system status bar when scrolled. Shared tokens/components, the full-bleed backdrop, game rules and content sizing are unchanged.
- Local Xcode 27/iOS 27: 27 core tests, two compact iPhone SE UI cases and two iPad mini UI cases passed; native results report zero failures/skips. Ordinary Release simulator build passed. Checks cover unsuppressed largest-text menu/game/Settings audits, real clears, restart, Settings dismissal and tablet rotation/reflow with continued input.
- The coordinator and design-system owner inspected before/after phone restart-ready captures: the previously overlapping moves label now clips at the safe-area edge; the complete board and New game retain their positions. Tablet landscape and maximum-text portrait captures retain clear, complete controls. Exact source hashes, summaries and 15 exported capture hashes plus the preceding-source baseline are in `docs/evidence/safe-area-2026-10-16/`.
- Preceding crystal cloud run [38967493117](https://github.com/lbeezr/starfall/actions/runs/38967493117) passed 86 tests (27 core, 47 hosted, 12 UI) and 35 screenshot hashes. The new viewport change requires its own subsequent CI result. Human VoiceOver, system Reduce Motion, physical devices and frame pacing remain separate acceptance work.

### Falling sky default — 2026-10-16

- Promoted the falling-sky screen, store and renderer to Debug and Release; ordinary launches open falling sky directly. Removed the modal Close button and experiment label. Debug `--classic` and `--demo` retain the original puzzle for regression coverage.
- `swift test --scratch-path /tmp/starfall-default-core`: 53 tests passed.
- Release generic iOS Simulator build passed using Xcode and `/tmp/starfall-default-build`.
- On the iPhone 18 Pro / iOS 27.0 simulator, the falling-sky UI tests passed for background/resume, saved-state restoration, automatic overflow/new sky, balance controls, and dark-star restore/clear. The rapid-tap/growth/replay/settings test initially lost its matching-group query after waiting for another shower. It passed on a focused rerun after removing that extra shower wait. Launch helper now omits `--starfalls`, covering default entry.
- Calm effects and native accessible cell controls were exercised by the suite. Actual VoiceOver speech/focus, the system Reduce Motion toggle, and physical-device behavior were not validated in this run. Falling sky ends on overflow; classic win/loss rules were unchanged and covered by core tests.
- Existing local Xcode project/workspace edits were preserved.

### Falling-sky pacing, feedback and accessible controls — 2026-10-16

- New skies have a first-shower match, coherent shower colors, and bounded matching runs in later forecasts when the board is dry and a low column has room. Existing saves keep their old generation rules. Comets fall faster; paused clears and Call next shower remove forced waiting. Added static match outlines/count, clear rings/score popup and optional local sound/haptics.
- Passed: 56 core tests; Release simulator build; 14 hosted store tests; five gameplay UI tests on iPhone 18 Pro; largest-text/settings/persistence check on iPhone 17e; actual system Reduce Motion gameplay check with the switch restored. Initial Settings switch targeting failed; explicit thumb targeting and value wait passed.
- Reproducible pacing sample, retained small-screen captures, source hashes, method and limitations: `docs/evidence/falling-sky-pacing-2026-10-16/README.md`. VoiceOver spoken/focus behavior and physical sound/haptic feel remain unvalidated. Existing unrelated Xcode project/workspace edits were preserved.

### Falling-sky roadmap and strategy baseline — 2026-10-16

- Replaced the outdated canonical roadmap with falling-sky priorities; preserved the original plan in `docs/archive/`. Added an observed-play comparison protocol and historical notices on original-puzzle playtest/acceptance material.
- Added `tools/sample-falling-sky-balance.swift`, an offline deterministic strategy sampler. Six policies over 200 seeds show that multi-group choices remain uncommon; these results motivate an offline mixed-color candidate and human comparison, not immediate changes to the shipped mechanics. Results and limits are in `docs/evidence/falling-sky-strategy-2026-10-16/`.
- The sampler compiled and produced byte-identical JSON on a second execution. All 56 core tests and a Release simulator build passed. No game source or UI behavior changed, and no new simulator interaction, human playtest or device acceptance is claimed.

## 2026-10-17 — engineering guidance and repository hygiene

- Runtime baseline: published `61ea5046e3d595858aba4da741fc301249b10ef1`. This pass changes guidance, ignore rules and a Python hygiene gate called by the existing CI script; no gameplay, app source, assets or Xcode settings changed.
- Local toolchain: Xcode 27.1 (27A9275), Apple Swift 6.4, ARM64 macOS. `swift test --scratch-path /tmp/starfall-hygiene-core` passed all 60 tests, zero failures. `python3 scripts/ci-hygiene.py`, `bash -n scripts/ci-simulator.sh` and `git diff --check` passed. Disposable-index artifact injection and an in-memory core SpriteKit-import injection both failed as intended without modifying the real index or source.
- A clean `git archive` export of the baseline built successfully with `xcodebuild -project <export>/Starfall.xcodeproj -scheme Starfall -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/starfall-hygiene-clean-build ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build`. This confirms clean-baseline simulator compilation, not launch, layout or visual parity.
- Existing local project/workspace edits remain untouched and excluded. The parsed project differences include scene/launch-screen/orientation generation settings and object version; recent native UI checks used that modified project. Resolving clean-published versus working-tree visual acceptance is tracked in `ENGINEERING.md`.
- No new simulator interaction, VoiceOver, physical-device, profiling or GitHub Actions run is claimed for this guidance pass. Existing native evidence remains source-bound under `docs/evidence/`.

## 2026-10-17 — original star-character cast

- Runtime integration `063d67b` replaces falling-sky jewels with the original Spark/Sunny/Pip/Twinkle/Nova/Dusk cast in Debug and Release. Board, comets and preview share one bounded material factory; existing core IDs/rules/saves and Debug classic crystal rendering remain unchanged.
- Clean exported source: 60 core tests passed; 69 hosted app tests passed with normal motion and zero failures/skips; all ten falling-sky UI cases passed in a separate Reduce Motion matrix; smaller-phone compact/large-text cases and a final normal-motion automatic/rapid-input UI case passed. Clean Release simulator build passed. The failed hosted portion of the mixed-motion run and its diagnostic-collection stall are explicitly retained in the evidence scope, not called an overall pass.
- Inspected native material sheet, full-animation recording and sequential frames caught and verified a fix for transient landing texture-size jumps. Geometry-preserving expression swaps cover both landing and clear; the new animated hosted test samples bounds over time.
- [Detailed scope, source hashes, summaries and selected captures](evidence/star-cast-2026-10-17/README.md). No actual spoken VoiceOver, physical-device, minimum-iOS or tablet/landscape acceptance is implied. Local unrelated Xcode edits were preserved; tests/builds used clean staged exports.
