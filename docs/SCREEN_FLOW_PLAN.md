# Deliver a continuous and trustworthy screen flow

**Status:** Accepted · **Owner:** Current implementer · **Updated:** 2026-10-17

Implement the [screen-flow design](design/SCREEN_FLOW_POLISH.md) in small verified batches. Fix launch and saved-round safety first, then transitions and result communication, then home/accessibility polish. Integrate completed batches independently of the separate gameplay experiments.

**Next action:** At RC, complete physical-device, actual VoiceOver, minimum-OS/full-tablet and first-time comprehension acceptance. Batches 1–6 have completed development implementation/checks; [executed results and capture limits](evidence/screen-flow-polish-2026-10-17/README.md) remain separate from later planned acceptance. The [review](evidence/screen-flow-review-2026-10-17/README.md) contains current evidence and its limits.

## Scope and success

Includes cold/warm launch, Welcome, staged Entry, Begin/Continue, both endings, replay/new/challenge, Home, pre-play settings/help and interrupted transitions. Keep existing visual direction, single First Light objective, shared geometry/materials, native controls and optional offline-safe rankings.

Excludes campaign/XP/unlocks, new mechanics, new art/audio production, custom services, monetization, distribution, broad architecture rewrites and core-save migration. Keep Debug classic fixtures and unrelated lab work intact.

- [ ] No captured blank/white app frame in the specified launch/transition recordings.
- [x] Back/kill at Entry preserves the prior round and ranking sidecar; Begin commits exactly once.
- [x] Continue preserves intentional in-memory pause; restored rounds safely reopen paused.
- [ ] A player can explain the objective, pause behavior, failure cause and next action.
- [ ] Screens remain continuous, readable and usable in full/quiet motion, small phone, large text and tablet layouts.
- [x] Evidence separates tests/builds, interactions, screenshots, animations, actual VoiceOver and physical devices.

**Development completion:** Integrated code `1650c50` passed 63 core checks, all 119 hosted checks and four selected native regressions across source-bound normal/quiet runs, plus signed Debug/Release builds, phone/maximum-text preferences checks and tablet landscape activation. [Final evidence](evidence/screen-flow-polish-2026-10-17/README.md#batch-6--integrated-development-candidate) preserves the initial skips and successful normal-motion rerun. The unchecked criteria retain their original broader/human/device scope; they are not established by a build or sampled video.

## Work in small batches

All batches belong to the current implementer. Start from the design's narrow boundaries; target/file names below are proposed, not created implementation files.

| Batch | Deliverable and affected owners | Done when / dependency |
| --- | --- | --- |
| 0 — Baseline | Record clean source plus dirty inputs; cold/warm launch under system Light/Dark; current Entry cancellation, pause return and both result flows. Preserve a retained save without reset. | Baseline distinguishes observed defects, code-confirmed behavior and unknowns. Recover simulator automation if it cannot deliver reliable taps; do not label tool failure an app defect. |
| 1 — Opaque launch | Named dark color, minimal launch storyboard, shared configuration, opaque `StarfallApp` root/theme fallback. Deliberate Xcode resource membership. | Effective Debug/Release plist/resources inspected; native cold/warm/relaunch recordings show no captured blank frame on tested phone configurations. Can integrate without waiting for Batch 2. |
| 2 — Safe entry and return | Focused `SkyFlowState` and tests; stage entry requests; change `FallingSkyView` integration; separate Begin/Continue; supply Entry snapshot; preserve existing store commit APIs. | Back and Entry termination retain core/ranking bytes; duplicate Begin/stale token commit once; ordinary/challenge/replay/new/initial-seed behavior and pause-return matrix pass. Update native flow tests that currently assume Entry has already replaced the round. |
| 3 — Continuous handoffs | Single owned handoff token/task; separate board visibility/input/overlay; narrow scene readiness; one suspension predicate; bounded preparation fallback only when needed. | Depends on Batch 2. Full-motion videos show uninterrupted backdrop and no duplicate interactive layer. Pause/menu/background/rotation/motion-change/stale-ready tests pass; no premature first shower. |
| 4 — Explain endings | Result snapshot from committed state, visible final board, projected blocked-column cue, correct score/18 and retry copy; adapt ceremony layout. | Depends on Batch 3. Win, ordinary overflow, challenge overflow and terminal restore use accurate data; final animation remains intact; actions are immediately usable; column cue maps to actual geometry. |
| 5 — Complete home and accessibility | Starfall identity, saved-round summary/action hierarchy, shared pre-play settings/help sections, adaptive cast layout, heading/menu focus and coordinated announcements. | Depends on Batch 2; finalize layout against Batch 4. No duplicated keys/stores, reachable controls and inspected screenshots at maximum text and supported aspect ratios; development semantic checks pass. |
| 6 — Candidate acceptance | Clean exact-source Debug/Release, affected suites, full motion/device review and RC VoiceOver at the proper stage; source-bound evidence and current docs. | All earlier batches integrated and acceptance table below complete or explicitly blocked. Visual/feel changes are adopted, revised or removed; no permanent pilot flags remain. |

Keep each batch separately reviewable. Separate navigation extraction from behavioral changes where practical. No source file currently requires a 1,200-line split to begin this work; extract cohesive state, snapshots and shared menu sections as needed rather than creating an all-purpose flow manager.

### Batch 5 subdivisions — arrival feedback follow-up

Verify 5a before 5b. **5a:** replace the clipped offscreen cast flight with a short, scaled entrance contained by one formation owner; retain full normal-motion settling and immediate quiet-mode parity. Native frame review must show complete star silhouettes throughout arrival on the compact phone; geometry checks include narrow/wide layouts and spring overshoot. Give system launch a static Starfall wordmark over the existing opaque navy, and genuine delayed in-app preparation a spinner (static in quiet modes). No fake percentage, forced delay, or asynchronous material pipeline: measured prewarm is approximately 100 ms in one simulator trace. Verify launch resources in Release and use a signed fresh-install capture.

**5b:** saved-round context/action hierarchy, shared preferences/help before play, large-text order and coordinated focus/speech. Preserve the existing preference owners and save/clock contracts. RC actual VoiceOver and physical-device acceptance remain separate.

## Focused regressions

| Mechanism | Smallest meaningful check |
| --- | --- |
| Entry cancels without replacement | Hosted flow/store test with isolated defaults: stage each request, cancel, compare complete game plus exact core-save/ranking-sidecar bytes; advance injected clock and assert no shower. |
| Death at Entry | Native process terminate/relaunch with the review suite, without reset on relaunch; inspect the prior retained round. Include no prior save and completed prior save. |
| Begin commits once | Flow event test plus store integration using manual clock/presenter; send repeated Begin, stale token completion, route replacement and background during handoff. Verify one replacement and one eligible clock. |
| Replay and new semantics | Compare seed, balance, challenge, opening marker, preview and deterministic next outcomes to existing restart behavior. Include older saves without opening/cohesive markers. |
| Pause ownership | Active → Home → Continue, paused → Home → Continue, settings dismissal, background and fresh-process restore. Assert deadline remainder/no catch-up and native visible manual controls. |
| Result cause survives restore | Ordinary/challenge overflow and win snapshots from saved core; verify blocked column and target, including exact-threshold/overshoot and existing win precedence. No animation-node-derived data. |
| Scene readiness/cancellation | Attach/resize/detach, stale generation, quiet-mode change, and bounded unready fallback; no rule mutation from readiness, no hidden input, no delayed reopening after Back. |
| Native controls/geometry | Real first-wave clear, rapid taps, projected edge taps and blocked-column alignment across changed layouts; verify settings dismissal and replay buttons by semantic IDs. |

Reuse `ManualRainClock`, the existing presenter recorder and isolated defaults in hosted tests. Add flow transition tests to the app-hosted target, not Core. Keep stable `experiment.*` accessibility IDs. Preserve existing assertions and use condition-based bounded waits; no blanket retries or motion suppression to obtain green tests.

## Verification and evidence

After each source batch run `python3 scripts/ci-hygiene.py`, `git diff --check`, `swift test`, the affected app-hosted/UI tests, and a simulator build. Batches changing launch/resources/routing also require Release and explicit target/resource membership checks. Package tests cannot prove storyboard or app-file inclusion.

Use the shared Starfall scheme and record the actual simulator UUID/toolchain. The previously successful local architecture settings are `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO`; they are command-line validation settings, not a request to rewrite project architectures. Use unique result/DerivedData paths and coordinate simulator use with other running work.

| Evidence | Required coverage / completion condition |
| --- | --- |
| Launch frames | Light/Dark system appearance; fresh install; cold/warm/force-quit; saved/corrupt/terminal states. Phone first, then supported tablet orientations and physical phone. Record frame rate, inspected interval and any missing capture coverage. |
| Full-motion transitions | Welcome → Entry → play; Continue; win/full → retry/fresh; settings/Home. Review outgoing and incoming states, first/last showers, duplicate controls and retained scenery. Still screenshots are insufficient. |
| Interruption | Background/foreground at entry, commit, handoff, final arrival/clear and result reveal; settings dismissal, rapid taps, motion changes and stale completion; no queued rain. |
| Visual/layout | Small phone, large phone, supported iPad orientations, accessibility XXXL, increased contrast and Reduce Transparency. Inspect actual screenshots, not just hittability. Geometry changes require native taps. |
| Development accessibility | Labels/traits, hidden board exclusion, focus destinations, reachability and quiet-mode state parity. Full actual VoiceOver sessions are not part of each batch. |
| RC accessibility/device | Actual spoken/focus sequence through both endings and retry, rotor/game actions, settings return, physical sound/haptics, repeated rounds and first-time comprehension. Run at RC, including first release. |
| Save/rules/rankings | Existing deterministic/old-save checks, retained installed save without reset, cancellation-byte checks, standard/challenge eligibility and terminal result delivery. Offline/slow rankings cannot block navigation or readiness. Live Game Center setup remains its separate acceptance work. |

Retain concise results under a source-bound `docs/evidence/` report; raw recordings/logs/xcresults belong under ignored artifacts or temporary storage, with locations recorded. Report the tested commit, dirty build inputs, command, configuration and OS. For published-commit acceptance use a clean export/checkout or explicitly record differences.

## Risks and decision points

- **Launch guarantee:** No software-only test proves every physical launch frame. Inspect recordings on the actual candidate, report sampling limits, and resolve any flash before accepting the zero-white requirement.
- **Readiness complexity:** The scene is already attached and prewarmed. Measure before adding work queues, image-decoding threads or another loader. Keep the fallback bounded and locally diagnosable.
- **Visual timing/comprehension:** Compare current and proposed matched native recordings, then observe phone use. The hypothesis is that short continuous handoffs and a visible final board improve orientation without delaying play. At Batch 6 adopt, tune once within scope, or remove ineffective decoration; do not leave a comparison route installed indefinitely.
- **Save/ranking safety:** Staging must not write either save key or deliver ranking effects. Do not implement cancellation by restoring old UserDefaults bytes after mutation. Preserve the existing conservative sidecar mismatch behavior; atomic-envelope redesign is outside this work.
- **Concurrent gameplay work:** These changes target presentation/store entry boundaries. Integrate independently; do not adopt tracing, shower or connector experiments as part of screen polish.

At each batch update the design's implementation status, the experiment/adoption register where presentation behavior changes, and the engineering record if a concrete gap is deferred. Update README/roadmap claims only to the level supported by the final evidence. Do not call the feature complete from a green build alone.
