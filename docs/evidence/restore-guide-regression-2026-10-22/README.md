# Reopen the intentionally collapsed restore guide

**Result:** Selected development regression repaired · **Owner:** Factory coordinator · **Date:** October 22, 2026

[#226](https://github.com/lbeezr/starfall/issues/226) is a stale native-test expectation. A restored paused round selects the correct Twinkle restore message but intentionally starts its prose collapsed. The regression pressed Continue, then demanded the expanded text without opening the portrait. The app already behaves consistently with its ordinary paused-guide sibling.

## Ownership and correction

`FallingSkyStore` selects `guide.restore` with the existing default `visible: false`. Its `pausedGuideLine` retains that message. `SkyDialogueOverlay` starts `pausedMessageVisible` false and expands it when the player taps `sky.dialogue.reopen`. `SkyDialogueInteractionTests/testPausedGuideStartsCollapsedAndReopensWithoutHidingManualControls` explicitly covers that contract.

Only `UITests/FallingSkyInteractionTests.swift` changes: record the committed board, assert the expected collapsed state after restore, reveal/tap the actual portrait and retain the exact Twinkle text, Resume sky, score and absence of transient `+` assertions. The board must remain identical through restore and reopening. No app behavior, dialogue content, rule/save, clock or animation change is supported or made.

The earlier failure on a clean `bf09f946` export remains in [the growth-guidance failure record](../factory-gameplay-2026-10-22/README.md#failed-checks-retained). The current passing test itself observes the intentional collapsed state that violated its old expectation; this is a test-navigation repair, not evidence of a repaired product defect.

## Source and verification

Base main `db713bc0c242de5e2244495c41f05961c939b4ee`; working-tree snapshot `dc997f39cf31`. [Exact test input hash](source-inputs.json) identifies the only changed build input. Existing file membership is unchanged. App/Core/resource inputs match accepted main; its Release result from the preceding Tutorial slice carries forward without an unrelated Release rerun.

Xcode 27.1 (`27A9275`), arm64, iPhone 17e Simulator `4103C352-DFC2-493E-A224-DE4CE3D50889`, iOS 27.0, normal motion. Raw data lives under `/private/tmp/starfall-factory-next-20261022/`; the complete result is `restore-guide.xcresult` and the bounded command is recorded in `stages.jsonl` / `restore-guide.log`.

| Check | Result |
| --- | --- |
| Core | 225 passed, zero failures/skips; unchanged production Core. |
| Hosted dialogue | 19 passed, zero failures/skips. |
| Native normal input | Two passed, zero failures/skips: complete growth/Dusk/restore regression and ordinary collapsed-guide/reopen sibling. Exact restore/pause/score/board assertions remain. |
| Debug | Normal app and test targets built successfully. |
| Hygiene / diff / local links | Passed at acceptance. |

The targeted test retains its original growth and historical Dusk inputs, score accumulation, menu/background behavior and restoration assertions. The sibling separately verifies ordinary portrait reopening/closing and manual controls. No VoiceOver test is selected or enabled. This subset does not certify the full native matrix, physical input, minimum-iOS, spoken accessibility or human enjoyment.

Reproduce with `scripts/simulator-command.py`, scheme `Starfall`, Debug, the simulator above, temporary DerivedData, `ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO -parallel-testing-enabled NO`, and these selectors:

```text
StarfallAppTests/SkyDialogueTests
StarfallUITests/FallingSkyInteractionTests/testPausedGuideReportsGrowthDarkOutcomesAndRestore
StarfallUITests/SkyDialogueInteractionTests/testPausedGuideStartsCollapsedAndReopensWithoutHidingManualControls
```

Core uses `swift test --scratch-path /private/tmp/starfall-factory-next-20261022/CoreBuild`. No player data is reset outside the isolated simulator fixtures; no physical installation occurs.

## Continuing factory state

The prior two player-facing slices merged independently: #228 through #230, and #229 through #231. Their issues closed automatically; #228's issue-side Project Done was observed, while #229 required a specific manual Done reconciliation after a hydrated read showed In Progress. The corrected receipt and #220 retain that limitation; manual reconciliation is not an automation pass.

Independent bounded refill review examined entry cancellation, map/back/resume, pause-menu recovery, restart/restore, input admission, retained-round snapshots and journey persistence. It found no additional concrete gameplay correction in those paths. VoiceOver #217 stays deferred. #206/#207/#209 need actual player/device observations, #208 needs an available minimum-OS environment, and #210 remains conditional on the player study. These are real evidence dependencies, not approval gates or a reason to manufacture features. The known forecast/tutorial wording concern remains a separate, unimplemented discovery in #223's review; no HUD redesign follows from it.
