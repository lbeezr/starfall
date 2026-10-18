# Every touch releases its shower hold

**Result:** Verified for development integration · **Owner:** current implementer · **Date:** October 17, 2026

The normal app now classifies every final touch sample and uses store-issued hold tickets. A 7.9-point move from an eligible edge star to outside the board cancels instead of leaving showers frozen; a final sample crossing drag slop becomes a trace even without a preceding move callback. Old/duplicate releases cannot resume a newer touch. Rules, RNG, saves, art and cadence are unchanged.

**Next action:** Integrate this batch, then complete the build-identity and layout/native batches in the [accepted reliability design](../../design/RELIABILITY_POLISH.md). Physical curved/multitouch gestures and system interruptions remain next-device acceptance; full actual VoiceOver remains RC work.

## Outcomes against acceptance

| Criterion | Result |
| --- | --- |
| Edge release below 8-point slop; final movement; duplicate end/cancel; second admission | Hosted production touch-session checks pass at 320×568 and 440×956. Native edge release passes and observes a subsequent committed arrival. |
| Owner-safe clock hold | Hosted tests cover duplicate acquire/release, old ticket against a new hold, minimum near-deadline grace, and late cancelled callback. Existing single-deadline/no-catch-up tests pass. |
| Lifecycle | Hosted surface replacement checks cover unchanged redraw, size/generation/enable changes, detachment and the multitouch cancellation route. Store pause/background/restart/motion/fixture checks invalidate ownership. This is not physical second-finger injection. |
| Input / accessibility / normal motion | Native held-touch then drawing, ordinary tap/menu dismissal, and largest-text drawing pass with normal animation. Existing core and affected store tests preserve outcomes/save contracts. No full VoiceOver session performed. |

## Verification context

Source: main `f266ab9` plus this PR's explicit App, AppTests, UITests, pacing-consumer and documentation edits. Initial native pass used parent `316f8cb`; integration rechecked all seven trace-input hosted cases after the concurrent explicit CGFloat conversion, plus Release. No resource/target membership added. Xcode 27.1 (27A9275), iPhone 16 Pro Max Simulator (`5107CBBF-108B-4B94-9125-A873F948A38C`), iOS 27.0, arm64, Debug and Release; local test builds use `dev.local`.

- `swift test`: 91 passed (`artifacts/reliability/touch-core.log`).
- Debug `xcodebuild test`, Starfall scheme, explicit simulator destination above, arm64/ONLY_ACTIVE_ARCH, CODE_SIGNING_ALLOWED=NO, parallel testing disabled: 45 affected hosted tests plus final two native cases passed (`touch-final-native.log`); the initial three native cases also passed (`touch-native.log`). Final combined-main trace-input hosted checks passed (`touch-combined.log`).
- Release generic simulator `xcodebuild build`, same arm64/signing options: passed (`touch-combined-release.log`).
- `python3 tools/mechanics/compare-pacing.py --seeds 1 --seconds 10 --output artifacts/reliability/pacing-consumer-final`: passed. This bounded compatibility sample is a modeled presenter/virtual clock, not animation or human balance evidence.
- `python3 scripts/ci-hygiene.py` and `git diff --check`: passed.

Initial checks exposed an @State write during representable update; the hold ticket now lives in the existing transient input reference, with no such warning in the final run. The offline consumer initially failed because its standalone compilation omitted current save/entry/phase dependencies; it now compiles the real save archive and exact current pure declarations, with hashed inputs. Failed logs are retained under ignored `artifacts/reliability/`.

## Ownership correction

The bug was an incomplete terminal branch, not inaccurate star geometry: a touch could leave the mapped board without crossing drag slop. `ConstellationTouchSession` owns final classification; the UIKit adapter terminates the physical session before callbacks. The view coordinates selected cells and a hold ticket, while Core remains the authority for the chosen set. Surface configuration invalidation and store lifecycle invalidation both relinquish the hold; no animation completion can recreate it. Unknown physical gesture sequences remain explicitly unverified.
