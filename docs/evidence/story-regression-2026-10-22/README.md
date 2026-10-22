# Current Story regression repair

**Result:** Development acceptance verified; actual VoiceOver remains open · **Owner:** factory coordinator · **Date:** October 22, 2026

[Issue #205](https://github.com/lbeezr/starfall/issues/205) repairs full-round test strategies that still searched for manual tap matches in current arrangement-only visits. Hosted reconstruction and native input now share deterministic revision-three exchanges/showers. Lantern reaches 154,000 against 150,000; Ribbon reaches 220,000 against 220,000. Runtime rules, saves and app behavior are unchanged.

**Next action:** [#217](https://github.com/lbeezr/starfall/issues/217) isolates the observed actual-VoiceOver navigation failure and verifies spoken custom actions. [#208](https://github.com/lbeezr/starfall/issues/208) still owns minimum-iOS evidence. Neither the passing development subset nor this repair accepts an RC.

## Acceptance and source

| Criterion | Observed result |
| --- | --- |
| Reproduce older normal full-round strategies | Two baseline failures; both reached overflow instead of the expected Lantern win. |
| Current Lantern win, committed restore, replay entry and survival entry | Passed through real native inputs. |
| Current Ribbon win, same-round replay, overflow, restored ending and survival entry | Passed through real native inputs; terminal score exactly 220,000. |
| Explicit historical Lantern completion/replay | Retained native fixture passed; its 18-light assertions remain. |
| Current visit, restore and largest-text siblings | Phone and iPad checks passed. |
| Accessible arrangement strategy | Migrated to spoken custom-action selection/activation; execution did not reach that helper. Actual acceptance remains open in #217. |

The tested base is `5554cd86d034ad3b9e5098c638f9c50dd19ce7ba`, with the nine explicit build/tooling inputs and SHA-256 values in [verification.json](verification.json). Baseline native source was clean `5166e6ec998e6c02ea540d169086c0c65c2f84c8`. Intervening discovery/playtest merges changed documentation only. The publication PR must preserve this input manifest; publication/closure is recorded on the linked issue/PR.

`StoryPatternPlan.swift` is registered in both hosted and UI test Sources phases without importing Core into UI tests. Hosted reconstruction validates every exchange/save and exact terminal totals against production Core. Native tests send gestures and explicit showers, asserting revision-specific input semantics, shower/exchange counts and terminal score; they inject no score, outcome or board state. The RC minimum-OS selector follows the renamed current Ribbon method. Existing source-counted inventory is unchanged.

## Verification

Xcode 27.1 (`27A9275`), Swift 6.4, iPhoneSimulator SDK 27.1, macOS 27.0.1. Native execution used arm64 iOS 27.0 (`24A434`): iPhone 17e `4103C352-DFC2-493E-A224-DE4CE3D50889` and iPad Pro 11-inch (M5) `027DFF2A-5E63-4A82-AACF-8360AD426F9B`. Both were initially shut down and reserved for this run. Exact native invocations, selections, receipts and input hashes are in the compact JSON; raw logs/xcresults remain disposable under `/private/tmp/starfall-factory-205/`.

| Check | Result |
| --- | --- |
| `swift test` | 225 passed, zero failures. |
| Debug `build-for-testing`, Release simulator build | Both passed; explicit arm64 architecture and test-file membership verified. |
| Selected iPhone native interaction | 5 passed, zero failures/skips; valid completed xcresult, command exit 0. |
| Selected iPad native interaction + hosted lifecycle/flow | 3 UI + 75 hosted passed, zero failures/skips; valid completed xcresult, command exit 0. |
| `python3 scripts/test_rc_platforms.py` | 12 passed. |
| `python3 scripts/test_native_test_plan.py` | 3 passed. |
| `python3 scripts/ci-hygiene.py`, `git diff --check` | Passed, including staged new-source membership. |
| Development/RC source inventory | 174/180 UI and 408 hosted registered; inventory only, not a full-matrix execution. |
| Inspected appearance | Ribbon win and overflow captures exported from the accepted phone bundle: correct 220,000 objective, complete text/actions, no observed clipping in these two stills. Temporary captures only; no artwork/UI change or replacement of historical visual evidence. |
| Animation / physical devices / minimum iOS | No new motion-quality, physical-play or iOS 17 acceptance claimed. Normal native motion settings were retained. |
| Actual VoiceOver | Attempted and failed before arrangement input; see below. Full acceptance remains due. |

## Failure history and limits

The first baseline build selected x86_64 app output against arm64 Core and failed compilation; selecting the actual simulator's arm64 architecture corrected the invocation. The corrected baseline then reproduced both stale-strategy native failures.

The first candidate's Ribbon fixture omitted the existing required `--dialogue-review` guard, so its world visit was unavailable. Supplying the required guard and retaining that defaults suite across restore corrected setup. A misspelled partial-sibling selector was corrected in the final exact-count run. That first candidate also stalled during result finalization/package-graph resolution and was stopped by the unchanged 1,200-second wrapper; its incomplete bundle is not a passing run. The final five-test phone run completed in 1,067 seconds. Avoiding redundant scroll/existence discovery for already-visible exchange targets reduced the same Lantern flow from 521.697 to 327.845 seconds while preserving hit/visibility requirements and scroll fallback; no timeout was increased.

The targeted actual-VoiceOver attempt enabled the real service, spoke/focused the Sky menu, then failed at the pre-existing World-map navigation step: “Sky menu Heading” instead of “World map” (`ObservatoryVoiceOverDriver.focus`). One test failed in 34.307 seconds with zero skips. The new custom-action helper was not reached. The process subsequently stalled finalizing its result; only its owned command group was terminated (wrapper exit 143), and the incomplete bundle is not accepted evidence. Teardown recorded speech and restored VoiceOver's prior state. Whether modal autofocus, offscreen exploration or app semantics caused the navigation failure remains unisolated. The discovery is persisted on #205 and assigned to #217; it is not relabeled as a pass or hidden behind the development deferral.

#205 explicitly permits development completion with actual-VoiceOver execution deferred to its existing RC boundary. The actual failed attempt makes that remaining work concrete. The six registered actual-VoiceOver sessions and their assertions remain in the RC selection. Full physical-iPhone VoiceOver, minimum-OS support, player comprehension and sustained device budgets remain separate open acceptance.
