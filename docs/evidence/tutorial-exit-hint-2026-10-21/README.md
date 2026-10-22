# Tutorial exit hint matches its action

**Result:** Partially verified · **Date:** October 21, 2026

The practice HUD close button now announces “Return to the tutorial chapter list” as its accessibility hint. Previously it reused “Pause, settings and how to play” from the regular game menu, despite immediately closing practice. The regular game retains its menu hint. Actual VoiceOver listening remains unverified.

Acceptance: select the hint from the same `tutorialExit` capability that selects the button action, icon and label; keep the shared control identity and saved round unchanged. The new text lives in the bundled typed copy catalogue. No rule, save, routing or layout change.

## Source and checks

Source: `7a6dee86be1eacbec3b029a233df1684980119ce` plus only these build-affecting edits: `App/FallingSkyView.swift`, `App/SkyCopy.swift`, `App/DialogueScripts/observatory-dialogue.json`. Earlier README/ENGINEERING edits are documentation only. Xcode 27.1 (`27A9275`); selected native tests use Debug on Starfall UI Parity `A0300936-14CC-4B3A-9B09-55B88D1D7624`, iOS 27.0, normal motion and default text.

- `swift test`: 225 tests passed, zero failures.
- `python3 scripts/ci-hygiene.py` and `git diff --check`: passed.
- Debug simulator build and selected tests: 16 hosted dialogue tests and one native tutorial interaction test passed, zero failures or skips. The native flow covers real tap/swap/trace practice, retry, exit to the chapter list and unchanged retained score/board.
- Release simulator build: passed.

Commands:

```sh
xcodebuild -project Starfall.xcodeproj -scheme Starfall \
  -destination 'platform=iOS Simulator,id=A0300936-14CC-4B3A-9B09-55B88D1D7624' \
  -derivedDataPath /private/tmp/starfall-low-fruit-dd \
  -resultBundlePath /private/tmp/starfall-low-fruit-arm64-tests.xcresult \
  -parallel-testing-enabled NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  -only-testing:StarfallAppTests/SkyDialogueTests \
  -only-testing:StarfallUITests/WorldJourneyInteractionTests/testTutorialRealTapSwapTraceRetryAndExitPreserveRound test
xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Release \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/starfall-low-fruit-release-dd \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

The initial native command omitted architecture overrides and failed resolving an arm64 Core module for an x86_64 app compile. The corrected command selects this Mac’s arm64 architecture; no product build settings changed. Raw logs and xcresults are disposable under `/private/tmp/starfall-low-fruit-*`. Release emits the tooling warning that App Intents metadata extraction is skipped because the app has no AppIntents dependency.

## Limits and follow-up

The defect is established by inspecting the shared button action and unconditional old hint. The chapter-list return path and ordinary game-menu sibling were examined. Catalogue tests validate packaging and the complete typed key inventory. Native exit checks establish interaction and save preservation, not spoken hint delivery. No visual, animation, actual VoiceOver or physical-device acceptance is claimed. At the next actual VoiceOver session, focus the close button in practice and the menu in regular play and confirm each speaks the corresponding action.
