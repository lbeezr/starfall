# Screen polish needs continuity, safe cancellation and clearer outcomes

**Result:** Partially verified · **Owner:** Current implementer · **Date:** 2026-10-17

The screens share a coherent visual palette, but the flow is not yet polished enough to call release-ready. Prioritize the launch surface, destructive pre-Begin save replacement, and handoffs between menus, gameplay and results. More particles will not resolve those gaps. Keep the existing survival game and single First Light challenge; this review does not recommend campaign, progression or extra loading delays.

**Next action:** Implement findings 1–3 as a bounded reliability batch, then improve entry/result communication and transitions. Accept each batch against its checks below. This is a review, not implementation acceptance.

## Evidence and limits

Reviewed clean source `f35eba87311f5e9e56740b9677bceb699154e8ae`. No app, rule, resource or save changes were made. Inspected routing, ceremonies, save mutation, pause/clock boundaries, menu, scenery, scene completion, feedback and the four native flow tests.

The three principal runtime files (`FallingSkyView`, `FallingSkyStore`, `SkyFlowCeremony`) match the SHA-256 values in the [earlier native evidence](../sky-flow-2026-10-17/source-sha256.txt). I inspected its Welcome, Entry, win and full-sky images. They are retained native captures, not newly captured screens or proof of current device performance. The earlier record reports passing native tests; those results were not rerun successfully in this review.

A new XcodeBuildMCP Debug build/run succeeded on the booted Starfall Compact HUD QA simulator (iPhone 17e class, iOS 27.0), with `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO`, DerivedData `/tmp/starfall-adversarial-review-build`, and isolated `--starfalls-reset --sky-flow-review` launch arguments. Its generated plist contains an empty `UILaunchScreen` dictionary. Fresh Welcome screenshot and native hierarchy inspection succeeded after an initial remote-automation timeout. A tap command reported delivery but did not change screens; Entry/Back interaction therefore was not accepted or treated as a reproduced app defect. Fresh launch video, end-to-end interaction, Release, physical-device and actual VoiceOver acceptance remain **unverified**. No claim is made that a white frame was observed. Core tests are not evidence for these presentation issues; they were not rerun for this documentation-only review. `python3 scripts/ci-hygiene.py` and `git diff --check` passed.

<img src="welcome-current.jpg" width="220" alt="Fresh current-source Welcome capture showing the Observatory heading, four cast stars and two start actions">

**Current native capture:** source above, Debug, Starfall Compact HUD QA / iOS 27.0; screenshot reduced to JPEG for this report. The settled Welcome matches the retained composition. This is not a launch-screen or animation capture. Raw original `/tmp/starfall-adversarial-entry.png` was named before confirming that the attempted tap left Welcome unchanged.

## Prioritized findings

### 1. P1 — The launch configuration does not cover the zero-white-frame requirement

**Source-confirmed gap; visible flash not reproduced.** [Clean.xcconfig](../../../Config/Clean.xcconfig#L8) requests generated launch content without a background/image. The generated app plist has `UILaunchScreen = {}`. The dark preference in [FallingSkyView](../../../App/FallingSkyView.swift#L61) applies to app content, after the system launch surface. There is also no opaque root fallback independent of the scenery assets.

Give the system launch screen an explicit dark asset color and a matching opaque app root. Preserve that base through first-frame scene preparation. Prewarm only if measurement demonstrates a need; a synthetic progress bar or mandatory splash delay would add friction without proving readiness.

**Accept when:** cold launch, warm launch, force-quit relaunch and resume have no white or transparent gap in frame-by-frame recordings, under system Light and Dark appearance. Include first install, small phone, iPad orientations and a physical phone. Record capture frame rate; one screenshot cannot establish a zero-frame guarantee.

### 2. P1 — Entry is already destructive before Begin

**Source-confirmed behavior.** With an unfinished saved round, select Start a sky or Try First Light, then Back to Observatory. [prepareSky / handleFlowAction](../../../App/FallingSkyView.swift#L235) calls `restart` or `startFirstLight`; both [save immediately](../../../App/FallingSkyStore.swift#L212). Back only changes navigation. The previous round has already been replaced, even though the player never pressed Begin. The menu's Replay/New/First Light actions share this mechanism.

Own a pending entry choice separately and commit replacement at Begin. Back should discard that pending choice. If deliberate immediate replacement is retained, make the consequence explicit at that boundary; staging is preferable because it gives the existing Back action ordinary cancellation semantics.

**Accept when:** an existing ordinary/challenge round survives every entry-and-Back path, process termination while at Entry, and rapid repeated selection. Begin replaces it exactly once. Check same-seed replay, fresh-seed sky and First Light independently, including ranking-session ownership.

### 3. P2 — Resume changes the player's pause choice

**Source-confirmed behavior; product decision needed.** [Begin and Resume share a branch](../../../App/FallingSkyView.swift#L252) that unpauses any live sky. Pause manually, go Home, then Resume: automatic showers restart. Relaunch also restores into paused state and Resume starts the clock. This is understandable for returning to active play, but surprising for someone deliberately using the supported paused/manual-shower mode.

Separate Begin from return-to-round behavior. Define whether Resume means resume the clock or reopen the retained board, and make the label/preview explicit. Preserve intentional pause state where supported rather than treating all returns as Begin.

**Accept when:** active and deliberately paused rounds have documented return behavior through Home, background, settings and relaunch; no accumulated showers occur. Verify native timing as well as store state.

### 4. P2 — Entry promises calm without teaching the automatic opening

**Observed copy/layout in retained captures; behavior confirmed in source.** Ordinary Entry says “No need to hurry” and “Clear matching stars,” then Begin enables the automatic opening cascade. It does not explain the three-starlight threshold, connected matching groups, or where to pause. Help and preferences are accessible only after entering play.

Keep the short entry but make its promise accurate: showers arrive automatically; the player can pause. Use a compact cast example for a legal match and make Help/Calm preferences available before play. Avoid adding a long mandatory tutorial.

**Accept when:** a new player can identify a legal clear and pause before pressure starts. Check comprehension with a person; script success alone does not demonstrate understanding. Ensure larger text can reach the primary action without scrolling past a fixed 220-point decorative cast region.

### 5. P2 — Failure hides its cause and underexplains challenge failure

**Source-confirmed information loss, visible in retained full-sky capture.** Once the final turn settles, [showingCeremony](../../../App/FallingSkyView.swift#L27) hides every board star. The result says “This sky is full” over an empty terrace. The store knows a column blocked the next star, but the [ceremony message](../../../App/SkyFlowCeremony.swift#L113) discards that reason. First Light failure also omits the visible 18 target; only its accessibility label includes it.

Keep a readable settled-board moment, gently identify the blocked column, then present the result with an accurate short explanation. For First Light show collected/18 and “Try First Light again.” Preserve the gentle tone without obscuring the outcome or suggesting the entire board must fill.

**Accept when:** ordinary overflow and challenge overflow explain the committed cause, retain the final score, and offer the correct retry. Verify final-arrival animation, final-clear win precedence, interruptions at that boundary, and quiet-motion equivalents. Keep immediate usable actions; do not add an unskippable result delay.

### 6. P2 — Screen entrances animate, but the journeys between screens do not

**Source-confirmed handoff gap; perceived severity needs fresh motion review.** [Flow actions](../../../App/FallingSkyView.swift#L243) switch identity and board opacity directly; no outgoing/board handoff transition is authored. The [ceremony reveal](../../../App/SkyFlowCeremony.swift#L199) animates stars and controls inside each new screen, which does not establish visual continuity into gameplay. Replay/new also replaces the environment identity.

Define one short cancellable handoff contract for Welcome → Entry → play and play → result. Keep an opaque environment continuously present, gate input once, and release gameplay only at the chosen explicit boundary. A local game does not need a separate fake “loading level” screen. If real preparation becomes measurable, retain scenery and show truthful readiness feedback.

**Accept when:** frame-reviewed recordings show coherent outgoing and incoming states, with no blank frame, duplicate chrome or active hidden buttons. Interrupt every handoff with Home/background, rapid taps and motion-setting changes. Animations must never determine rules, saves or shower schedules.

### 7. P2 — The home screen lacks identity, preferences and save context

**Observed in retained Welcome capture and confirmed in the action list.** It displays “The Observatory” and “A sky of your own,” but no Starfall title. No settings/help control is present. Resume has no mode, score or pause context; “View last sky” receives primary emphasis even when the saved game has already ended.

Add restrained Starfall branding, pre-play preferences/help, and a compact saved-round summary. For a completed sky, consider making a fresh start primary while keeping the result accessible. Retain the existing strong action hierarchy and generous touch targets.

**Accept when:** fresh install, unfinished survival, unfinished First Light, completed sky and rejected-save states each show a clear primary choice. Someone can silence sound or choose Calm effects before Begin. Review screenshots with all supported text sizes; do not solve crowding by shrinking text.

### 8. P3 — Results and home reuse too much composition to communicate distinct states

**Visual judgment from inspected captures.** Welcome, Entry and both endings use the same terrace and central cast arrangement. Success gains happy expressions and a finite burst; failure largely restores idle faces. The ordinary Entry repeats much of Welcome, creating a second gate without much additional information. [Scenery activity](../../../App/FallingSkyView.swift#L163) is also disabled for every ceremony, freezing environmental motion even while active.

Differentiate states through restrained composition, typography and a relevant board-to-cast gesture before adding assets or effects. Give Entry useful information that earns the second tap. Consider a separate presentation activity value for ambient home motion while retaining gameplay suspension, and honor Calm/Reduce Motion. A still home is a design choice, not a correctness bug.

**Accept when:** people can identify Welcome, ready-to-play, success and failure from brief viewings. Compare real full-motion recordings and quiet equivalents. No campaign map, unlocks, permanent pilot flag or additional service is needed.

### 9. P2 — New-screen accessibility focus is not explicitly owned

**Source risk, not a reproduced VoiceOver failure.** The only explicit accessibility focus in [FallingSkyView](../../../App/FallingSkyView.swift#L12) returns to the game menu after sheet dismissal. Ceremonies replace their view identity and remove the focused gameplay cell, but do not explicitly target the new heading. Outcome announcements exist, yet an announcement and a reliable navigation destination are separate contracts.

Own heading/primary-action focus for screen changes, coordinate it with the existing terminal announcement, and preserve scrolling access to actions at large text. Avoid duplicate speech or overriding ongoing user exploration.

**Accept when:** lightweight hierarchy/reachability checks cover development, and actual VoiceOver at RC verifies Welcome → Entry → play → both endings → retry, plus background and menu return. Earlier VoiceOver evidence does not accept these new screens.

## What already has a sound foundation

Core outcomes are committed before animation; endings wait for the final presentation; ceremonies suspend the gameplay clock; result actions are not blocked behind their decorative burst. Native buttons, non-color character cues, quiet-motion alternatives and bounded particles are already present. Preserve these contracts while improving the flow. The observed shortcomings do not justify rewriting the game or adding progression.

## Visual evidence inspected

| Welcome | Entry | Challenge win | Full-sky result |
| --- | --- | --- | --- |
| <img src="../sky-flow-2026-10-17/welcome.jpg" width="180" alt="Retained Welcome capture with Observatory heading, central cast and Start and First Light actions"> | <img src="../sky-flow-2026-10-17/entry.jpg" width="180" alt="Retained Entry capture with No need to hurry copy and Begin card"> | <img src="../sky-flow-2026-10-17/flow-win.jpg" width="180" alt="Retained First Light win with happy cast and 20 starlight but no visible 18 target"> | <img src="../sky-flow-2026-10-17/flow-full.jpg" width="180" alt="Retained full-sky result showing an empty terrace, idle cast and retry actions"> |

**Retained native evidence:** Welcome/Entry: iPhone 17e; endings: iPhone SE3; iOS 27.0 Simulator, Debug, normal motion. [Original provenance and limits](../sky-flow-2026-10-17/README.md). These images show composition, copy and hierarchy. They cannot prove launch continuity, frame pacing, audio, tactile quality or accessibility focus.

## Completion matrix for the next implementation

| Boundary | Required adversarial cases |
| --- | --- |
| System launch → first content | Fresh install; retained/corrupt/terminal save; Light/Dark system appearance; cold/warm launch; no white frame; no forced delay |
| Welcome → Entry → Begin | Saved round cancellation; rapid taps; Back; kill/relaunch at Entry; ordinary/First Light/replay; preferences before play |
| Entry → first usable board | Actual ready first frame; visible objective; first/last opening wave input; no hidden playable board; full/reduced motion |
| Play → result | Win, ordinary overflow, challenge overflow, final-turn precedence; clear/arrival in flight; retained score/cause; background at commit/settle |
| Result → next sky | Replay seed/challenge retained; new sky correct mode; no accidental double action; Begin remains explicit; terminal restore |
| Any screen → interruption → return | Settings dismissal; notification/Control Center interruption; background/foreground; cancellation and stale work; paused mode preserved as designed |
| Presentation coverage | Small phone; current large phone; iPad portrait/landscape; maximum text; contrast/transparency; long/localized copy when supported; screenshot and full-motion review |
| Services and feedback | Offline launch; slow/unavailable rankings do not block play; sound preferences respected; no speech overlap; native audio/haptic review on device |

The matrix is a proposed acceptance checklist, not an executed test result. No new implementation, native interaction, animation, actual VoiceOver or physical-device acceptance is claimed by this report.
