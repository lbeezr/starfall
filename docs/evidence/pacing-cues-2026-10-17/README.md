# Cadence cue native comparison

**Result:** Partially verified · **Owner:** task 4 · **Date:** October 17, 2026

The presentation reads the committed Store cadence and displays the exact user-selected warning, “Faster after next shower,” followed by “Faster showers” and “Breathing window.” Baseline A supplies no cue. Candidate B remains an isolated Debug simulator export; it is not adopted. [Handoff and commands](../../design/PACING_CUE_HANDOFF.md) define task 6's combined acceptance.

**Next action:** Task 1 integrates the narrow changes with current main; task 6 uses a healthy private simulator to finish reduced-mode Settings, inspect final screenshots/motion and validate combined acceptance. Human comprehension, automatic-play rhythm, actual VoiceOver and physical-device acceptance remain open.

## Source and ownership

App/test source: `c9cde8a25af07a34bdbed7039168a0982ee2445f`, based on Store `3c09532d78400f877b4961073de05de3afa33828`. Later report/register edits do not affect the build. Worktree: `codex/pacing-cues`; no shared checkout edits, merge, push or phone install. Remote main was read-only checked at `ec4a4d179942d73bab84931f8dd3d15fe4fa3a6f`; this does not claim integration with that source.

Export `/tmp/starfall-pacing-cues-candidate-final` records four adaptations: fixture app membership, simulator-only Debug initializer using isolated defaults, the candidate UI-test marker, and a fixed B cue slot. Store, `FallingSky.swift` and canonical fixture are byte-identical to source. Fixture SHA-256: `873a78ded0501fcc4bb14123a92b93d634a10015aa16a97083eaa07b7d0e51e0`. B never enters production policy/save identities or normal launch routes. Release B is unsupported.

## Executed checks

Xcode 27.1 (27A9275), arm64 host, iPhone 17e type / iOS 27.0 (24A434), private simulator “Starfall Pacing Cue QA” `45D19CC2-B110-43E7-8C5E-1D7579EC737F`. Private DerivedData and `/tmp` logs keep this run separate. Completed flows restored the original Reduce Motion preference. The interrupted reduced flow left the private simulator enabled; cleanup shut it down, restored `ReduceMotionEnabled = 0` in that device's preferences and read the value back. Post-cleanup UI verification was not run. No host-wide preference, other simulator or phone identity changed.

| Check | Result and evidence |
| --- | --- |
| Core | `swift test`: 72 tests passed; `/tmp/starfall-pacing-cues-core-c9cde8a.log`. |
| Normal app Release | Generic arm64 simulator build passed at final app source; `/tmp/starfall-pacing-cues-release-final2.log`. |
| Normal app Debug | Final app source generic arm64 simulator build passed; `/tmp/starfall-pacing-cues-debug-final2.log`. Candidate Debug build also compiled its explicit fixture adaptation; native acceptance remains separate. |
| Final largest-text B | Passed at `c9cde8a`: one cue, exact warning/faster/breathing labels, lower controls, Settings removal/dismissal and return to steady. `/tmp/starfall-pacing-cues-final.log`, 101.061 seconds. Screenshot attachments were captured but not extracted/visually inspected before interruption. |
| Final normal-motion B | Passed at `c9cde8a`, 165.982 seconds: same boundaries, unchanged native cell frames, actual matching-group clear with score increase, Settings and cue restoration. Full-motion system setting and Calm off were asserted. This establishes execution and input, not final motion/art approval. |
| Final system Reduce Motion B | Partial: actual system toggle enabled, warning/unique cue/stable frame/native clear passed. Opening Settings then stalled: no event-loop idle notification, Done not found; screenshot capture also stopped responding. Interrupted under the coordinator's recovery limit. No full reduced-mode pass is claimed. |
| Hosted cue copy | Two tests passed at `f1db9ee`: baseline/opening suppression and exact canonical B boundaries, including gentle-pace exclusion. `/tmp/starfall-pacing-cues-native-v4.xcresult`. Copy is unchanged in final source. |
| Export anchor failure | Preparing Store-only `3c09532` correctly exits 1 at the missing `cadenceCueCopy` anchor; `/tmp/starfall-pacing-cues-anchor-negative.log`. No partial output was built. |
| Hygiene | `python3 scripts/ci-hygiene.py`, Python compilation and `git diff --check` passed. |
| Rule/save changes | Not applicable: no Core, Store, RNG, fixture algorithm or schema changes. Combined replay/interruption acceptance belongs to task 6. |
| Actual VoiceOver / device / human preference | Not run; RC VoiceOver and combined acceptance remain open. |

## Failures investigated

- Export preparation initially failed on system Python because its `tarfile.extractall` lacks the newer filter keyword. The script now validates archive entry type/path and works with the installed Python. It refuses an existing output directory; no partial export is silently reused.
- Initial tests queried the grouped SwiftUI Label as `StaticText`. Runtime observation found the warning; a type-independent query, already used for the arrival cue, retains exact wording, visibility and bounds checks. The native element is `Other`.
- The initial Settings assertion sampled before presentation settled. A bounded wait then demonstrated that the grouped cue remained discoverable even after the sheet settled. Final source removes the cue from the view tree while Settings is open. The original hide assertion remains, with no action retry.
- At `b99113c`, largest-text cue existence/wording passed but visibility failed while reaching lower controls. The safe-area inset did not contain scrolling content that ignored that inset. The correction reserves real sibling space and allows the board/scroll view to ignore only horizontal/bottom safe areas while a cue exists. Opening/steady A retain their edge-to-edge path. Normal B also receives a native-clear regression to check coordinate mapping. Scene inspection found that resizing settles presentation; the final exporter therefore reserves a fixed B slot from round start. Native tests assert one accessible cue and unchanged cell frames across warning/breathing boundaries. This prevents the cue from truncating a boundary shower through a resize; animation acceptance still requires native observation.
- A subsequent run compiled but stalled before runner startup at debugger attachment; even screenshot capture stopped responding. The run was interrupted and only the private simulator was restarted. This is a tooling failure, not a passing interaction check. Logs: `/tmp/starfall-pacing-cues-native-v7.log`. Superseded runs are retained under `/tmp/starfall-pacing-cues-native-v3*`, `v4*`, `v5*`; v3/v5 were interrupted after relevant failure/teardown and may lack finalized result bundles.

The final targeted command used exported `c9cde8a`, scheme Starfall, Debug, arm64, private DerivedData `/tmp/starfall-pacing-cues-native-final`, signing disabled, serial execution, `-only-testing` for the three B UI methods and `StarfallAppTests/SkyCadenceCueTests`. Raw log: `/tmp/starfall-pacing-cues-final.log`; interrupted result `/tmp/starfall-pacing-cues-final.xcresult` may be incomplete. The final hosted rerun did not execute. Baseline A passed at app source `e38a27e` after sibling extraction (70.960 seconds), before Settings-only removal and export-only B slot changes; no final A visual parity is inferred.

The one private-simulator reboot restored runner progress. When the same simulator later stopped responding during reduced-mode Settings, testing stopped without a second recovery. This remains a native validation gap; it does not prove the app is free of a reduced-mode Settings defect. Task 6 must reproduce/check on a healthy simulator rather than dismiss it as tooling solely from this run.

Exact final targeted invocation, after the documented export:

```sh
xcodebuild -project /tmp/starfall-pacing-cues-candidate-final/Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=45D19CC2-B110-43E7-8C5E-1D7579EC737F' -derivedDataPath /tmp/starfall-pacing-cues-native-final CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES -parallel-testing-enabled NO -only-testing:StarfallUITests/PacingCueUITests/testLargestTextKeepsCueVisibleWithControls -only-testing:StarfallUITests/PacingCueUITests/testNormalMotionWarningFasterBreathing -only-testing:StarfallUITests/PacingCueUITests/testSystemReduceMotionKeepsLabels -only-testing:StarfallAppTests/SkyCadenceCueTests -resultBundlePath /tmp/starfall-pacing-cues-final.xcresult test
```

Final largest-text/normal-motion attachments were captured by XCTest, but the interrupted result bundle could not be exported for visual inspection. There is no inspected final-source screenshot or final animation review to embed. Task 6 must capture these after integration; an earlier warning capture at `f1db9ee` was inspected for wording only and is not final layout evidence.

## Remaining acceptance

The focused flows exercise manual committed boundaries, Settings hide/dismiss, persistent largest text, system Reduce Motion, and native clears during the warning. They do not establish timed human reaction windows, automatic speech/focus acceptance, dense-board comprehension or enjoyment. Task 6 owns normal automatic play, rapid taps/traces, restart, terminal states, background/resume and combined source acceptance. Players still need to explain that the next shower precedes the faster passage, and that breathing room does not imply a safe board.
