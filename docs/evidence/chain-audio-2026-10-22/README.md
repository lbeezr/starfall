# A rising phrase for committed Story chains

**Result:** Verified for selected development acceptance · **Owner:** Factory coordinator · **Date:** October 22, 2026

[Leaf #236](https://github.com/lbeezr/starfall/issues/236) gives successive committed Story phases a short rising musical contour. Previously every cascade reused the historical relay sound. The existing recipe opens E5 → G5; phase two answers A5 → C6 and phase three or deeper D6 → E6. Two original generated WAVs add 74,176 bytes. No new audio subsystem, timer or remembered streak is introduced.

The player promise is that a survivor-created follow-up sounds like a growing achievement. [The accepted spectacle goal](../../STORY_MODE_GAMEPLAY_PLAN.md#give-skill-and-spectacle-room-to-grow) supplies the direction; the pitches are an authored adaptation, not a reproduction of reference-game audio. A useful counterexample is the next independent line clear: it must return to the recipe opening even after a deeper chain. Physical listening, intelligibility and preference remain unmeasured.

## Ownership and acceptance

`QuietTuckPlayer` chooses a take from the existing committed receipt. Historical relays keep their original take; ordinary rotation and all eight original files stay byte-identical. Phase three caps variation independently of the existing score multiplier. Gain, duration and voice count do not grow with further depth. One worker still owns replacement, mute, interruption, background and route-change cancellation. Playback never controls scoring, saves, clocks or input.

Quiet presentation retains its existing single aggregate receipt instead of requesting the omitted phase sounds. The hosted Store regression covers both current openings × normal/quiet × sound enabled/muted, exact committed board/save and 15,000/30,000 awards. Duplicate completions cannot replay cues. A real subsequent Lantern line yields 5,000, total 20,000, and restarts the opening accent. Separate queued-work tests exercise supersession and mute before playback starts.

## Source and environment

Initial working-tree checks use base `45ee2c2dc8d2f071721c4e57b4feb0bf67191230`, computed identity `dev.3abf04f9e5`. Main then merged #261's short-swipe correction. Final integration fast-forwards to `086df43899a8940d28358710d98e4a190b6dba4d`, identity `dev.9dd978825b`, with all six audio hashes unchanged. [source-inputs.json](source-inputs.json) records both sources and their exact dirty inputs. Core/package inputs are identical between the bases. The local simulator displays `dev.local`, version 0.1.0 (1). Documentation edits do not change runtime inputs. Publication preserves these hashes and compares the complete Git tree; these are working-tree checks, not a claim that the simulator displayed a published commit.

Environment: macOS 27.0.1 arm64, Xcode 27.1 (`27A9275`), iOS 27.0 (`24A434`), factory-owned iPhone 17e `64231AFE-4CDB-4B5A-B6D5-70CD7CEED324`. Only that owned simulator is booted for this slice; the factory iPad stays shut down and other devices are untouched. Raw logs, results and DerivedData are disposable under `/private/tmp/starfall-chain-audio-20261023/` and the adjacent `starfall-chain-audio-*-20261023.log` files.

## Verification

| Check | Observed result |
| --- | --- |
| Core | 236 passed, zero failures/skips. |
| Hosted audio / committed phases / native scene | All 17 pass on both sources: 15 audio plus two scene methods, zero failures/skips. All ten bundled takes successfully start through the native player. |
| Initial real-input iPhone journeys | Two pass on `45ee2c2d`, zero failures/skips: Lantern exact score/restore (46.173 seconds) and Ribbon win/replay/overflow/restore (443.609 seconds). |
| Final integrated iPhone controls | Two pass on `086df438`, zero failures/skips: Lantern exact chain/score/restore (46.878 seconds), and #261's short-swipe correction followed by a successful full move (30.552 seconds). |
| Debug / Release | Both arm64 builds pass on each source. Final bundles each contain all ten audio files with exact source hashes through the existing folder resource reference. |
| Resource cleanup | The factory-owned phone was shut down successfully after testing. No other simulator was changed. |
| Hygiene / diff / local links | Pass after explicit staging; 505 local targets checked across seven Markdown files. Rendered Markdown was not inspected. |

[verification.json](verification.json) retains exact selected methods, zero-skip summaries, bounded command receipts and bundled hashes. Initial/final complete native commands pass in 506.477/106.178 seconds respectively. [signal-analysis.json](signal-analysis.json) retains the independent reproducibility and PCM measurements.

Initial native selection: all 15 `QuietTuckPlayerTests`; `NativeInputWindowTests/testRecipeCascadeShowsPopThenFallThenNextPop` and `testRecipeCascadeReplacementAndQuietModeDiscardRemainingCallbacks`; `WorldJourneyInteractionTests/testRevisedLanternEarnsThousandsAndRetainsScoreAcrossRelaunch`; and `SkyFlowInteractionTests/testCurrentRibbonWinReplayAndFullSky`. Final integration repeats the same 17 hosted methods and Lantern case, replacing the expensive Ribbon journey with `SkyFlowInteractionTests/testShortStorySwipeExplainsHowToCompleteTheMove`, which exercises the newly changed boundary and next-action recovery. The valid swap/phase path remains unchanged by #261; the complete Ribbon result remains explicitly bound to the earlier source.

The two scene tests drive committed turns into a real `SKView` and inspect normal phase/cancellation behavior; they do not synthesize touch or audio. UI tests use actual production controls and preserve opening, exact awards, restore/replay and terminal assertions. This is a selected subset, not the full development or RC matrix.

Commands use `python3 scripts/simulator-command.py --receipt <temp>/stages.jsonl <stage> <seconds> <command>`. Core uses `swift test --scratch-path <temp>/swift-build`. Debug uses `xcodebuild build-for-testing -project Starfall.xcodeproj -scheme Starfall -configuration Debug -destination id=<owned-phone> -derivedDataPath <temp>/dd -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 -jobs 2 ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO`. Execution uses `test-without-building`, the same products/destination, the selectors above, a unique result bundle and `-collect-test-diagnostics never`. Release uses the generic iOS Simulator destination and separate `release-dd` with the same explicit architecture/signing settings. No assertion, skip gate, motion requirement or test timeout is weakened.

### Failed preparation retained

- The first Debug invocation selected x86_64 for the app against an arm64 package module and exited 65. Explicitly selecting the actual host/simulator architecture passes; no project source or dependency was changed to conceal the error.
- The first sandboxed native invocation exited 74 before executing tests: CoreSimulator access and package/module caches were denied. The authorized invocation uses the same selection and assertions with standard simulator/cache access.
- The first result-summary export lacked Xcode TestReport cache access. The authorized export succeeds and verifies all 19 methods with zero failures/skips; no test rerun was needed.

## Signal analysis and remaining evidence

Two isolated standard-library generator runs reproduce all six WAVs exactly. All eight original assets equal their main-base blobs. Each new cue is 0.42 seconds, mono 16-bit PCM at 44,100 Hz; source/spectral checks agree with the rising lead notes, endpoints are zero and no sample clips. Recipe/depth-two/depth-three peak levels are −9.039/−5.981/−6.722 dBFS; RMS is −23.189/−23.186/−23.154 dBFS. Higher transient peaks remain bounded, but similar RMS does not establish equal perceived loudness. [Runtime audio](../../../App/Audio/README.md) owns regeneration and the file budget.

No visual layout or animation code changes; this audio slice does not refresh unrelated screenshots. Native playback-start callbacks establish successful bundled starts, not audible speaker output or perceptual synchronization. Physical listening, physical performance and player enjoyment remain separate; actual VoiceOver stays deferred. Revisit contour recognition and comfort at the next ordinary player session, revising or removing these two accents if they obscure feedback. The broader sensory-language outcome #249 remains open.
