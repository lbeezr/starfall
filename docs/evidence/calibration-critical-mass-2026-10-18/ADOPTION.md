# Fresh skies leave room after an implosion

**Result:** Verified for scoped development adoption · **Owner:** current implementer · **Date:** October 18, 2026

Fresh survival now uses the existing **3.0 / 2.5 / 3.5-second** cycle through one Core factory. It leaves time after full implosion animations. Saved rounds and replay keep their own cadence; First Light is unchanged. Seeded stars, aging, score and animations stay intact.

The adopted path measures 0.682/0.696 seconds before the next scheduled deadline after two sampled collapses. These are isolated native-host measurements, not guarantees for every workload or device. Existing V2 rounds retain tight timing until New sky; no save is reset or silently retimed.

**Next action:** Observe recognition, gesture comfort and repeated-round feel at this baseline. Actual VoiceOver and physical feel remain RC/player acceptance.

## Acceptance and evidence

| Requirement | Result |
| --- | --- |
| One owner for new-game defaults | Core factory is used by initial launch and New sky, including return from First Light. Explicit constructors remain available for retained versions/fixtures. No new mode, algorithm or runtime flag. |
| Save/replay compatibility | Both V1 and V2 critical-mass rounds round-trip, restore and replay their own version. New sky alone selects V1. Existing archive schema and First Light stay unchanged. |
| Seeded rule history | Eight seeds, up to forty committed showers with matched clears: complete Core states, including RNG/preview, are equal after normalizing only the saved cadence field. Balance choices are preserved. |
| Native input window | Adopted factory seed 0 through showers 9–14 retains >=0.5 s after both sampled collapses; observed 0.682/0.696 s. Retained fast-cadence control remains observational and exhibits the known tight window. |
| Package / hosted / build | 162 Core checks and 92 focused hosted checks pass. The extracted archive/phase suites also pass again after whitespace cleanup (12 checks). Debug simulator compilation and Release build pass. |
| Native interactions | Nine distinct cases pass across the main run, one corrected-copy rerun and two explicit background checks: automatic pause/replay/settings, opening clear, invalid/rapid double tap, actual system Reduce Motion, two fresh automatic samples, First Light win/replay/full-sky/restore/New sky, entry/Home/return, and settings/background/gesture recovery. The initial main run remains a recorded 6/7 pass, not an all-green run. |
| Model parity | 160 model runs, 19,187 replay-checked commits. Apart from the newly recorded `savedCadence` field, complete run objects/events match the earlier timing-only V2/V1 comparison exactly. Tool output now names the persisted cadence separately from its injected comparison lookup. |
| Actual VoiceOver / physical device | Not run in this routine development batch; RC and physical-play gates remain open. |

## Verification context

Base main: `eea67c20606729ca88e9ff91667d178fd18bbf30` (PR #102). The standalone structural extraction is local `4337779`; runtime changes and updated expectations were working-tree inputs during testing. Exact hashes, commands, artifact paths and final native observations are retained in [adoption-source.json](adoption-source.json).

Xcode 27.1 / macOS 27.0.1 arm64; Debug iPhone 16 Pro Max Simulator / iOS 27.0 (24A434), UDID `5107CBBF-108B-4B94-9125-A873F948A38C`. Dedicated DerivedData: `/tmp/starfall-calibration-derived`, Release `/tmp/starfall-calibration-release`. Binaries display `dev.local`; no phone delivery or visual redesign is claimed.

Raw artifacts: `artifacts/calibration-native/longer-cycle-hosted-final.xcresult`, `longer-cycle-native.xcresult`, `longer-cycle-release.log`; model `artifacts/calibration-longer-cycle/default-verification/`; Core output `artifacts/calibration-current/longer-cycle-core.log`. Native commands use the same project/scheme/signing/destination flags as the preceding report, selecting the named classes/methods. Release uses `-configuration Release -destination 'generic/platform=iOS Simulator'`.

## Failure handling and test ownership

The first hosted run failed because fresh-game tests still asserted the prior cadence and corresponding remaining seconds. Updated assertions name the longer fresh contract; explicit retained Dusk/V2 fixtures and their 1.7/2.5-second expectations stay intact. No assertion or timeout was relaxed.

Touching fixture expectations triggered the documented size review: `FallingSkyStoreTests.swift` drops from 1,212 to 944 lines. Archive and phase-presentation classes move unchanged to separate files; their shared feedback recorder joins the existing test support. Native target membership is explicit. An initial extraction compile caught that recorder's former file-private visibility; moving its ownership fixed it. Both extracted suites pass (12 tests); the later 92-check run includes them. Structural changes have their own commit. Trailing extraction whitespace was corrected and the affected suites are included again in the native acceptance command.

One native check initially failed before its double tap: it expected “grown stars count as 2” after an invalid tap, while the unchanged current match-help catalogue says “grown stars as 2.” The corrected condition also requires the match-help instruction prefix, so the untouched opening line cannot satisfy it. The related opening-help assertion still correctly uses its distinct wording. The affected native case is rerun explicitly; this is test/copy maintenance, not a reported gameplay correction.

The corrected invalid/rapid-tap case passes in 16.799 s; its original failure attachment confirms the current “grown stars as 2” label. The full native outcome case passes in 150.125 s. Fresh seed 180 has seven attempted contacts, one non-scoring attempt, six skipped stale selections, score 36 after 17 showers. Seed 5 has ten scoring contacts, five skipped selections, score 38 after 16 showers. These short driver-limited samples are not controlled measurements of human speed or a before/after success rate. Both end screenshots were inspected; default-text dialogue fits in the sampled bottom panel, but still images do not verify smoothness. The non-scoring attempt retains the known contact/readiness uncertainty; longer pacing is not claimed to eliminate it.

Explicit background acceptance also passes: `SkyFlowInteractionTests/testWelcomeEntryBackgroundAndAnotherSky` (58.871 s) and `SkyTechniqueInteractionTests/testSettingsAndBackgroundLeaveGesturesReadyWithoutRetoggling` (19.747 s). The former uses the fresh factory through entry, Home/activate and New sky; the latter verifies gesture ownership after settings and Home/activate on its retained technique fixture. Result: `artifacts/calibration-native/longer-cycle-background.xcresult`.
