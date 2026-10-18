# Empty-board controls verified with five-feed Dusk and faster input

**Result:** Verified development checks · **Owner:** current implementer · **Date:** October 18, 2026

The Arrange correction is reconciled with main `70cd96b`, including the 150 ms swap dwell, forgiving taps and five-feed Dusk. Only two app files differ from that main runtime: the intent’s mode eligibility/reconciliation and the view’s use of that boundary. The correction adds no rule, save, RNG, cadence, geometry or animation change.

**Next action:** Integrate this verified batch, then continue natural automatic-play calibration on the combined source. Retain the current mechanics. Human feel, observed motion and RC VoiceOver remain separate acceptance work.

## Combined checks

[Source and affected-test hashes](integration-source.json) identify runtime fingerprint **`dev.79c0d8c7f9`**, tested local merge `85f5a2a`. Only offline tools and documentation changed afterward. Simulator binaries display `dev.local`; the fingerprint is a source identity, not a stamped phone installation. Environment remains Xcode 27.1 / Swift 6.4, iPhone 16 Pro Max / iOS 27.0 Simulator `5107CBBF-108B-4B94-9125-A873F948A38C`.

| Check | Actual result |
| --- | --- |
| Core | **149 pass**, zero failures: `swift test`, `artifacts/calibration-current/integrated-core.log`. The extra tests come from integrated main; no Core files changed in this correction. |
| Hosted | **10 pass**, zero failures/skips: `SkyTechniqueStoreTests`, including the new empty/populated/First Light reconciliation check, saves, stale input, Dusk reward columns and full/quiet exchange outcomes. |
| Native | **Four distinct methods pass**: empty opening → real shower → Arrange enables; final recipe → empty board → feedback/controls return; largest-text recipe controls/scroll; quick-flick rejection and 200 ms held swaps/empty-destination fall followed by ordinary clear. |
| Builds | Debug simulator test/build and Release generic iOS Simulator build pass on the combined tree. |
| Visuals | Combined relay/empty-board and largest-text attachments inspected. Footer/control state matches the selected [after capture](README.md#the-observed-problem-and-correction); no duplicate retained image is needed. Raw combined capture: `integrated-attachments/DB3F2647-C166-42F2-9131-650754635FEC.png`. The updated intent/view source is identical for this footer; main’s Dusk/input changes are preserved. |
| Tool version | Calibration output now records explicit Dusk enum value and feed count. Default is `patientFeeding` (five); `--dusk-rule feeding` reproduces the retained historical three-feed policy rows in a 2-seed/6-shower regression. Historical study mode is unchanged. |
| Hygiene | `python3 scripts/ci-hygiene.py` and `git diff --check` pass. Existing source/test target membership is retained. |

**Failed run and recovery:** the initial combined native session passed its first three methods, then the swap method exceeded its 120-second allowance during setup/app launch, before any gesture. Its result bundle is retained as a failure, not counted green. The task stopped its own stalled run, restarted only this QA simulator’s `com.apple.testmanagerd`, then ran the unexecuted swap and hosted suite with ad-hoc simulator signing. Those **11 checks pass**, with unchanged assertions and timeout. This is a targeted recovery, not a claim that the underlying Simulator failure class is fixed.

Raw results: `artifacts/calibration-native/integrated-empty-arrange.{log,xcresult}`, `integrated-recovered.{log,xcresult}`, `integrated-release.log`; exported attachments under `integrated-attachments/`. Commands select the four named `SkyTechniqueInteractionTests` methods and `StarfallAppTests/SkyTechniqueStoreTests`, use scheme Starfall, arm64, no test parallelism and the destination above. Recovery adds `CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual`; the earlier run and Release use `CODE_SIGNING_ALLOWED=NO`. No project signing settings or phone installation changed.

## Current five-feed measurements

The earlier [four-scenario timing table](README.md#what-timing-changes-in-the-balance-conclusion) is deliberately retained as three-feed source-bound evidence. [Five-feed source and results](five-feed-study.json) record the combined source and exact commands; no older result is relabeled as current.

- Untimed, 128 seeds capped at 240 showers: clear-one ends **111/128**, setup-one **14/128**. Most setup samples remain censored; this is not an endless-play finding.
- Timed, 16 seeds capped at 180 seconds, normal-motion model: at 0.45 s decision / 0.5 s swap contact, clear-first ends **8/16**, setup-first **0/16**. With 1 s decision / 1 s contact, clear-first ends **10/16**, setup-first **16/16**. The quiet model retains different results: setup-first ends **1/16** under each timing assumption.
- The same limitations remain: assumed search/contact durations, sequential policy waiting for all presentation, no exact-recipe trimming/optimal subset search, board-dependent relief, and no human evidence. The real app permits independent-column input during other animations. These data justify retaining rules while observing execution; they do not justify a new exchange cost or difficulty claim.

Normal/quiet hosted outcomes and inspected stills are not motion-video acceptance. The recorder saved no usable file; physical haptics, human preference and actual VoiceOver remain unverified. Actual VoiceOver is deferred to RC, not a routine development gate. This batch completes a specific usability correction; the broader calibration goal remains active.
