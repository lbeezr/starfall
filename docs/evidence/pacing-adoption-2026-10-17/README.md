# Announced rhythm promoted to ordinary Starfall

**Result:** Production simulator checks passed; PR/main/device delivery pending · **Owner:** current implementer · **Date:** October 17, 2026

The user selected B without another baseline session. New brisk skies use the opening cascade followed by six 3-second, three 2.5-second and three 3.5-second intervals, with an advance cue. Core owns the versioned algorithm; the temporary exporter/selector is removed. Existing rounds retain their saved rules. [Adoption contract](../../design/PACING_ADOPTION.md).

**Next action:** Merge [PR #36](https://github.com/lbeezr/starfall/pull/36), install exact remote main in the existing phone bundle, and verify the retained save before releasing the phone.

## Source and results

Clean local source `5486492` (published tree-equivalent `6758bea04140396b35f21b0cfbf894778b78d0e5`) passed 73 Core tests (`swift test`), 103 hosted tests, Debug native tests and a Release simulator build. Native selection: five production pacing cue methods, forecast/menu/background flow, clearing before the final opening wave, and a trace held across an automatic deadline: **8 passed**, no B flag or export. Full animations were enabled except the explicit system Reduce Motion check. Normal and largest-text screenshots were inspected: cue text remains readable and controls reflow; the largest-text view scrolls the board. Screenshots alone do not prove animation smoothness.

The subsequent narrow Store fix `00954fe` (published tree-equivalent `b6a57f99cc242f8dc596238719a5c4cebcbdd856`) restores normal balance when leaving First Light. Core, UI and scene source are unchanged. On that source, **104 hosted tests** and Release build passed, including restored-won and overflowed-challenge exit coverage. The focused native First Light win/replay/full-sky/restore/new-normal-entry check also passed (1 test, 156 seconds). No dirty runtime paths affected these builds.

Commands: `xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=<id>' -parallel-testing-enabled NO … test`, ad-hoc simulator signing `CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- ARCHS=arm64 ONLY_ACTIVE_ARCH=YES`; Release used generic iOS Simulator with signing disabled. Native simulator: iPhone 17, iOS 27.0, `F4BA0D73-6491-4171-A29B-93ABC79EB4FF`; final hosted/follow-up: iPhone 17e, iOS 27.0, `1B3A9585-6D5B-4199-88E0-AF5D8982EEF8`. Raw logs/results stay under `/tmp/StarfallAdoptionNative`, `/tmp/StarfallAdoptionFollowup` and `/tmp/starfall-adopt-*.log`.

Hygiene, `git diff --check`, native matrix tooling (3 tests), device updater tooling (10 tests), and a two-seed/30-second offline model smoke passed. The model describes deterministic behavior, not enjoyment. Source/resource membership is verified by actual hosted/native app builds. Existing updater/CI source remains unchanged.

## Boundaries and limits

Phone inspection found a completed First Light save with its fixed four-second/no-dark profile. Passing that profile into a new normal sky leaked challenge configuration into survival. The Store now selects normal defaults at that boundary; normal-to-normal selected settings and same-sky challenge replay retain their existing contracts. Won/restored and overflowed exits were examined and covered by hosted tests.

Actual VoiceOver remains deferred to RC; labels/non-color cues and largest-text/native taps were checked. Physical animation feel, human preference, minimum OS/tablet coverage and accelerated-opening trace comfort remain unverified. Prior comparison evidence is historical and source-bound. No new analytics, SDKs, accounts, network game features or progression.
