# Preserve contact-time admission before tuning missed taps

**Result:** Store contract verified; recorded native miss remains partially diagnosed · **Owner:** current implementer · **Date:** October 18, 2026

Preserve contact-time input admission. These initial checks predate PR #96 critical-mass adoption; no current aging-sky balance recommendation is made. A deterministic hosted check now reproduces a ready query becoming unavailable when an automatic shower commits before contact. It covers an arriving origin and a stable origin whose ordinary match spans arriving columns. Neither stale clear spends score nor runs after settling; a new contact then clears the current group exactly once and saves that committed state. No product correction or buffering was introduced.

This establishes a supported explanation for the [current native non-scoring attempt](GAP_LINK_CALIBRATION.md#fresh-native-rounds-on-the-current-rules), not its exact cause: that attempt has a ready query and later settling feedback, without a touch-down admission receipt. Do not classify all missed taps as timing races or use this test to claim the player-reported swipe rate is resolved.

**Next action:** Continue recognition/gesture calibration; capture contact-time admission if the native miss recurs before changing buffering or timing. A player pressure preference has been requested; pending a response, retain the current cadence and the existing room-to-plan direction.

## What the boundary check proves

| Sequence | Observation |
| --- | --- |
| Query a legal ordinary match, then fire the actual Store's automatic deadline through the injected clock | Both selected origins were ready before rain; their matches are unavailable during the arrival. |
| Begin contact in an arriving column | Hold admission rejects it immediately. |
| Begin contact on a stable origin whose match crosses arriving columns | Contact can hold for a possible trace; ordinary clear admission still rejects the moving group. Contact eligibility and clear eligibility intentionally differ. |
| Deliver a stale ordinary clear, then finish the presentation | Core state is unchanged by the clear and by settling. There is no queued future action. Waiting feedback ends. The direct clear also checks the native-button/accessibility action's Store boundary; the physical surface itself suppresses release after rejected contact. |
| Start a new contact after settling | Exactly one expected Core clear commits and the decoded save equals it. |

The examined owners are `FallingSkyView.beginBoardContact`/`tapBoardCell`, `ConstellationTraceSurface` contact/release cancellation, Store hold admission and `clearAvailability`, plus existing overlap/stale-release tests. The check uses the real Store with a deterministic clock/presenter and isolated defaults; it does not manufacture UIKit touches or establish finger timing.

## Source and verification

Source: `425a9743ad4773b2c71fe15549b5426128f0fbd5`, incorporating main `f81ac90258322d9642516bde89d11269291179bf`; only `AppTests/ResponsiveInputTests.swift` changed for the test runs. Production app/Core bytes are unchanged from the preceding calibration. Xcode 27.1 / macOS 27.0.1 arm64; Debug iPhone 16 Pro Max Simulator / iOS 27.0 (24A434), UDID `5107CBBF-108B-4B94-9125-A873F948A38C`.

- `xcodebuild test -only-testing:StarfallAppTests/ResponsiveInputTests`: 13 checks pass, including the new two-origin boundary case. Result: `artifacts/calibration-native/readiness-contact.xcresult`.
- Gesture siblings: 15 hosted `TraceInputPolishTests` and four native cases pass: off-center five-star trace (8.506 s), chosen five of six plus restore (16.311 s), quick directional swap (8.247 s), settings/background then swap and tap (19.333 s). Result: `artifacts/calibration-native/contact-gesture-siblings.xcresult`. These assertions establish interaction outcomes, not physical feel.
- `swift test`: 152 tests pass. `python3 scripts/ci-hygiene.py` and `git diff --check` pass.
- Debug native compilation is included in both test commands. Release is not rerun for this hosted-test-only edit; no routing, resource or fixture change.
- No new win/loss, actual VoiceOver or physical-device acceptance is claimed. Existing source-bound outcome/accessibility evidence remains linked from the calibration index. No animation-quality conclusion is drawn from these assertions.

Commands use the same project/scheme/destination/DerivedData and local signing flags as [the gap-link native batch](GAP_LINK_CALIBRATION.md#fresh-native-rounds-on-the-current-rules). Raw output: `artifacts/calibration-native/readiness-contact.log`, `contact-gesture-siblings.log` and `artifacts/calibration-current/contact-boundary-core.log`.

A separate clean-source manual launch used ordinary seed 64 and Calm Effects off. Screenshot plus semantic observation showed three Mint stars; an explicit physical down/up cleared them for three starlight. The UI tool repeatedly failed to obtain a settled post-action snapshot, so those tool responses alone are not treated as failed gameplay input. Raw recording `artifacts/calibration-native/contact-boundary-manual.mp4` is retained but has not received a complete frame review. The first build/run attempt failed with an incompatible cached Core target module; rebuilding with the passing test batch's explicit architecture/signing settings succeeded in 6.6 s. No app source or cache deletion was needed.

## Reconciled with critical-mass main

Main advanced during this batch to `c2695e6835750ab30ec5203a755101b8e80235c9` (PR #96). Local merge `85c9b00575c1a5b3c78256d14370e483f5ca6f57` preserves that implementation and only adds this hosted test and documentation. On that merged source, 160 Core tests, 32 focused hosted tests (`ResponsiveInputTests`, `TraceInputPolishTests`, `CriticalMassProductionTests`) and two native gesture checks (quick directional swap and off-center five-star trace) pass. Debug compilation is included. The new readiness test deliberately restores the retained non-aging review fixture, so it does not by itself establish critical-mass collapse admission behavior; production critical-mass checks are separate.

A current-source pacing smoke fails compilation because the offline wrapper does not yet include `CriticalMassPresentation.warning`. Opal calibration also still explicitly constructs five-feed Dusk games. Thus the preceding timing/Opal distributions remain pre-pressure evidence. Next model work must compile the real warning dependency, label the saved aging rule explicitly, model collapse presentation durations, and repeat event/replay checks before producing current-game balance conclusions. The failed smoke is retained in `artifacts/calibration-current/critical-model-smoke.log`; no runtime stub or silent fallback was added.

Current fresh automatic samples also pass on the merged source: seed 180, four scoring attempts, eight skipped stale selections, 27 starlight / 24 showers (54.621 s test); seed 5, four attempts including one non-scoring attempt, eleven skipped selections, 14 starlight / 23 showers (53.408 s test). The latter again records ready=true before the attempt and a later “Spark. Stars settling…” hierarchy. Its exact contact-time state remains unobserved. Both end screenshots were inspected, but no new animation-quality claim is made. These short automation-limited samples are not controlled before/after comparisons of pressure, recognition or player speed. Results and diagnostics: `artifacts/calibration-native/critical-fresh-contacts.xcresult` and its exported attachments. [Source record](contact-boundary-source.json) identifies the test bytes and contexts.
