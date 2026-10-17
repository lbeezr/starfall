# Observatory production integration

**Integrated; acceptance limits recorded · October 17, 2026.** Integrate the approved Moonlit Observatory into default Falling Sky in Debug and Release. Cloudsea stays deferred until this location is finished. The user explicitly requested adoption and remaining polish/checks.

## Acceptance recorded before integration

- Default survival and First Light use full-screen Observatory art, the real cast, projected landing surface, contact shadows, responsive telescope/lantern and gently moving fog. No alternate environment picker or lab route.
- Empty/sparse/dense, grown and dark stars stay readable. Geometry, render centers, native touch polygons and prop targets have one owner, including iPad portrait/landscape. Full targets, no prop/board overlap, normal animations retained.
- Repeated prop input stays bounded; restart, settings, background and scene replacement cancel responses and freeze ambient time without catch-up. Decorative interactions never change committed outcomes.
- Native normal play, rapid input, win/loss, replay/new sky, background/resume, settings dismissal, maximum text and quiet modes pass. Inspect actual VoiceOver if tooling permits; distinguish unavailable checks from passes.
- Core rules, RNG, save schema and retained previews remain unchanged. Old palette preferences are deliberately retired without changing game data. Debug review fixtures remain separate from Release routing.
- Core/affected hosted/UI tests, Debug/Release simulator builds, source/resource membership, hygiene and diff checks pass. Inspect temporal native captures and source-bound screenshots. Check connected physical-device availability and profile a reproducible scenario where tooling permits; record residual gaps explicitly.

Production owners, source identity, results and remaining risks are recorded below. Raw artifacts belong under ignored `artifacts/observatory-integration-2026-10-17/`.

## Selected implementation and source

The user approved location adoption and later selected HUD **A**, explicitly preferring the comet/star-trail progress indicator. One transparent score/trail/menu row replaces the padded score/menu blocks and ambiguous arrival flash. The system status bar is hidden during play, actual controls respect the camera safe area, and the trail uses the store's existing deadline. It schedules no gameplay. Paused/outcome guidance uses Sunny from the actual cast; active routine arrivals do not open a dialogue card. The menu has separate How to Play and Balance pages with a common Done action at each destination. New sound/haptic preferences default on; saved off remains authoritative and initialization remains read-only.

The normal app bundle is `com.starfall.prototype`; default Debug and Release route to Observatory. Four catalog imagesets own background/fog/telescope/lantern. `ObservatoryGeometry` owns image registration, projected cells and prop targets. Tall phones fill vertically without stretching; wide tablet views blend into a distant background. `ObservatoryEnvironment` owns finite cancellable prop responses and pausable ambient phase. The scene retains the concurrently adopted contact renderer. No core, RNG, save schema, generation, progression or network change.

[Runtime/test SHA-256 manifest](source.json) identifies export `starfall-observatory-review-odaihv9w` from the dirty working tree. Expanded local Xcode settings and Personal Team are not accepted as feature changes. A second export `starfall-observatory-review-u386g6td` uses identical runtime source plus the HEAD project with only explicit source/test membership added. Both Debug and Release simulator builds succeeded for this minimal project. Personal development signing remains local.

## Checks and limitations

Toolchain: Xcode 27.1, iOS Simulator 27.0, Apple silicon. Main phone simulator: iPhone 17e (`Starfall Cosmic Art Lab`). Matrix: iPhone SE (3rd generation) and iPad mini (A17 Pro), both owned disposable QA simulators. Normal motion remains enabled for full-animation review; separate quiet-mode checks exercise Calm and system Reduce Motion.

- Package `swift test`: **61 passed**, zero failures (`hud-core.log`). Core source was unchanged by this presentation/feedback pass.
- `python3 scripts/ci-hygiene.py`, `git diff --check` and project `plutil -lint`: passed. New source/test/resource membership is explicit; app resources decoded in hosted tests.
- Selected single-row matrix: **six native runs passed**, three methods on each SE/iPad: real prop responses/menu cancellation, maximum-text prop/footer reachability, actual portrait/supported-landscape viewport and native projected-cell taps. `hud-quiet-matrix.xcresult` is finalized. Landscape captures now use the actual screen after orientation/center assertions; older cropped app-screenshot captures are not accepted evidence.
- Broader single-row native/hosted run: results recorded below after completion. Earlier candidates exposed missing Done navigation ownership and large-text label/switch conflicts. Final menu has one reusable dismissal toolbar applied to each page; maximum text uses a full-row native toggle. Assertions were retained and immediate state expectations added. These were real candidate failures, not silently retried passes.
- Actual VoiceOver service was exercised separately (`hud-voiceover.xcresult`). **Failed:** touch exploration at a cell spoke the containing terrace group before the expected cell. This does not establish a usable complete VoiceOver round, rotor behavior or focus return. Do not treat native accessibility labels as actual speech/focus acceptance; retain this explicit release follow-up.
- Physical iPhone 16 Pro Max, iOS 26.6.2: signed, installed and launched the selected A build with no reset/fixture arguments. Saved round and score **13** were retained. [Actual device capture](iphone-selected-A.jpg) shows terminal saved state, smaller controls, guide/lantern separation and no top/bottom letterbox strips. The trail is intentionally absent in terminal/paused state. Active physical trail timing still needs player observation after Replay/New sky. The user's earlier “Feels good so far” and sound confirmation refer to the preceding Observatory build, not blanket acceptance of this new HUD.
- A prior 45-second physical SwiftUI trace was captured, but its analysis/export contained no samples. It is **not performance acceptance** and does not establish zero hitches. Device screen recording was unsupported on that OS. No frame-rate, memory or energy threshold is claimed.

Raw commands, logs, xcresults, screenshots and trace remain under ignored `artifacts/observatory-integration-2026-10-17/`. [Tablet landscape capture](ipad-landscape-selected-A.jpg) demonstrates the current composition, not human preference acceptance. Minimum supported iOS 17 runtime and a complete physical VoiceOver session remain unverified.

## Adoption decision

Observatory and selected HUD A are integrated production presentation, with no environment/variant pilot flags. B/C are closed design comparisons. Keep [the interface direction](../../design/OBSERVATORY_INTERFACE.md), shared tokens, cast materials and geometry as the repeatable boundary; Cloudsea remains deferred pending the remaining environment acceptance. Physical profiling, actual VoiceOver and user evaluation of active trail timing remain explicitly open rather than being implied by successful builds.

### Feedback boundary regression

The responsible default-reading boundary previously interpreted an absent boolean as false. It now distinguishes absent keys from explicit false without writing defaults during view/store initialization. Hosted regression covers fresh-on values, no initialization writes, explicit saved-off values and reload. Existing committed-clear/mute/suspension feedback tests remain. Sound still respects the phone's Silent Mode; the user confirmed the earlier silence was due to mute, not a playback failure.

### Final verification and integrating source

- Full `hud-quiet.xcresult`: **34 hosted passed**, zero skips, plus **20 of 21 selected UI/setup checks passed**. All eleven existing gameplay checks passed, including win/loss, automatic/manual showers, rapid input, saved state, background/resume, balance, feedback persistence, menu dismissal and system Reduce Motion. Eight of nine Observatory methods passed, plus normal-motion setup. The one failure required the menu's location identity, which the redesign had omitted.
- Restored the concise “Moonlit Observatory” context heading; `hud-menu-final.xcresult` passed **both** the exact retired-preference/location check and the complete help/balance/Done navigation check. This preserves the original assertion, rather than removing it to obtain a pass.
- Final crop review found that a tall accessibility canvas could crop edge columns. Capped crop to 4% while keeping the painted-background edge feathered. Added 375×1000 geometry coverage and an actual largest-text edge-cell tap/score check. `hud-edge-regression.xcresult`: **six hosted geometry checks and two native SE checks passed**, zero failures/skips. The unchanged normal phone/tablet mapping retains the earlier matrix evidence.
- Minimal-project clean export `hud-clean-hosted.xcresult`: **34 hosted + normal-motion setup passed**, zero failures/skips, including full animated landings/contact transfer. The final crop delta's affected geometry checks passed separately as above.
- Final selected export (path retained in raw `/tmp/starfall-hud-selected-export`) passed Debug native test compilation, Release simulator build (`hud-selected-release.log`) and signed physical Debug build (`hud-selected-device.log`). The installed final source hashes and minimal project hash are in `source.json`. No rule/save/RNG source changed. Post-test edits are documentation only.
- [Native active-trail capture](active-comet-trail-native.jpg) was inspected: one quiet row, fading tail/star head, no status text/panels over the cosmos. This is a simulator still during an approaching shower, not a physical motion/performance claim. [Physical capture](iphone-selected-A.jpg) verifies retained terminal round, smaller controls, full-bleed art and guide/lantern separation; final follow-up changed only the accessibility crop cap/edge feather and restored menu context heading.

Final selected build is installed on the connected iPhone without reset arguments. Final launch was denied because the device was locked; the earlier selected-A build was launched and captured. Unlock and open Starfall to run the final two polish changes. User evaluation of the active trail, actual VoiceOver and usable physical profiling remain open. The integration commit contains a minimal membership-only project delta; local Xcode formatting, repeated settings, workspace state and personal team are excluded.
