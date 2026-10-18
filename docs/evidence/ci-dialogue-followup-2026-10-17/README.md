# Verify clear feedback after its presentation boundary

**Result: Verified locally for paused-feedback synchronization; remote approaching-label failure remains open · Owner: current implementer.** Cancelled remote run 39088189209 on source 49dcd0e compiled the app and passed 110 Core tests before two native failures. The current source 71ec3ec locally reproduces the paused-feedback failure. Its diagnostic still reads dark-star help immediately after tapping a legal remote group: the Store publishes visible result dialogue in the presentation completion callback, while the test assumes synchronous copy replacement.

Acceptance before correction: preserve the exact collected score, attributed clear text, unrelated-dark-star survival, adjacent dissolution, paused menu/background message retention and committed restore checks. Wait on the actual expected result text after the committed score, with a bounded timeout; no extra tap, assertion removal, blanket retry or reduced motion. Examine the adjacent-clear sibling and other immediate dialogue assertions. Retain the separate approaching-shower label failure as unresolved on its older runner until it is reproduced or independently verified; it passed the local current-source reproduction run.

Use a separate simulator from the user's live preview. This is test synchronization work, not a rule/save/cadence change or permission to update the active playtest.

## Correction and root causes

The remote native failure at line 532 reproduced unchanged on current main 71ec3ec. A diagnostic-only run printed the actual value: “Sunny. Clear a matching group beside the dark star to dissolve it.” The score had a legal group available, but the test inspected the prior help message before presentation completion published the new result. The UI test now checks committed score first and waits up to five seconds for the **same exact attributed result prefix**. It sends no extra tap and retains all dark-survival/dissolution and restore assertions. The adjacent result uses the same completion-aware expectation.

That correction reached a second stale assertion at restore. The bundled restore script says “Your sky is paused. Resume when you're ready.” The previous test looked for the distinct explicit-pause wording “Sky paused.” It now requires the complete current restore line **and** a Resume sky button, while still rejecting persisted transient plus-score copy and preserving the exact total score.

A focused SkyDialogueTests regression commits six real seeded showers, displays invalid dark-star help, commits the valid remote clear, verifies score commitment while the old message remains, finishes presentation, then verifies the exact resulting dialogue and paused restoration without transient copy. It uses the existing shared presenter/clock test support and isolated defaults. No product code, save, cadence, rule, schema, resource or membership changed.

## Source-bound verification

| Check | Result / limit |
| --- | --- |
| Older remote compiler | Cancelled run [39088189209](https://github.com/lbeezr/starfall/actions/runs/39088189209), source 49dcd0e: Xcode 26.3 (17C529), Swift 6.2.4, iPhone SE (3rd generation). Logs prove 110 Core passes and Debug BUILD SUCCEEDED. Two UI failures occurred before a later source push cancelled the run. This is compiler/Core evidence, **not a green suite** |
| Initial local reproduction | One native pass / one failure, zero skips: test_sim_2026-10-18T02-26-18-070Z_pid85535_f3c8ce03.xcresult. The cue test passed; paused feedback failed at the same line as cloud |
| Diagnostic reproduction | Exact prior-help message confirmed; test_sim_2026-10-18T02-29-07-568Z_pid85535_a1a39550.xcresult |
| Follow-through after completion wait | The first result, adjacent dissolution and background/menu checks passed, exposing the stale restore wording; test_sim_2026-10-18T02-30-45-866Z_pid85535_f6130eec.xcresult. One native pass / one failure, zero skips |
| Accepted hosted/native batch | **10 passed, zero failures/skips**: all seven SkyDialogueTests including the new lifecycle regression; paused feedback/restore; compact HUD/menu; current native Opal/orbit tap orders. test_sim_2026-10-18T02-33-25-383Z_pid85535_da768d0e.xcresult |
| Build / hygiene | Debug test compilation passed. python3 scripts/ci-hygiene.py and git diff --check passed. No Release rerun: App/Core/resources/project are unchanged by this test-only correction |
| Interaction and accessibility scope | Native score/message, pause, menu/background and restore assertions passed. No new screenshot-based visual claim, animation-frame review, actual VoiceOver, physical device or human preference evidence. The user's separate live-preview simulator was untouched |

Local base main **71ec3ec**, with only the two test files in [source.json](source.json) affecting compilation. Xcode 27.1 / Swift 6.4, iPhone 17e / iOS 27.0 (24A434), Debug arm64 unsigned, scheme Starfall. Reproductions and accepted tests used simulator 536BCC00-751C-47BA-BC2F-C1702941CFC8 and /tmp/starfall-ci-dialogue-build. Raw logs/attachments remain in the cited XcodeBuildMCP result bundles and /tmp/starfall-ci-dialogue-repro.

## Extent and remaining risk

Examined result publication in FallingSkyStore.present, explicit help/pause handling, restored initialization, SkyDialogueSession, and immediate guide assertions in FallingSkyInteractionTests, ObservatoryInteractionTests and ConstellationTraceNativeTests. Manual-shower and adjacent-clear paths already wait for input readiness; invalid taps publish help synchronously. The new focused case guards the actual commit-versus-presentation boundary. This does not prove every unrelated UI test is synchronized.

The strict **Shower approaching** expectation failed on the older remote runner but passed all three local paired runs. Its exact label and eight-second timeout remain unchanged. A transient-label sampling race is a hypothesis, not an established cause or fixed product bug. Trigger: the next completed older-runner result reproduces it. Preserve the actual cue hierarchy/frame and clock state, then distinguish label publication from snapshot sampling before changing the assertion or timer. Track that follow-up in ENGINEERING.md. New main 71ec3ec changes ready-column input, so the separate source-49 user preview is not current-input acceptance.

Core regression: swift test passed 110 tests, zero failures; /tmp/starfall-ci-dialogue-core.log. No Core source changed.

## Integration with gravity opportunities

Merged main ce2a45a into local cff461e before final checks. This includes responsive column input and generation-3 gravity opportunities; no App/Core changes were introduced by this correction. Core: **115 passed**, zero failures (`/tmp/starfall-ci-dialogue-integrated-core.log`). The first integrated native/hosted batch passed 11 cases, including both gravity opportunity cases, but the compact-menu case crashed in the shared shower-count reader's force unwrap (`test_sim_2026-10-18T02-38-00-724Z_pid85535_9c73968a.xcresult`). The recording attachment was an error placeholder, so it provides no crash-screen evidence.

The reader now handles a missing or malformed accessibility value explicitly: readiness predicates continue their bounded wait; required reads fail with a screenshot and hierarchy instead of crashing the runner. This is a diagnostic mitigation, not proof of the cause of board disappearance. The exact approaching-label expectation remains unchanged. If the board becomes unreadable again, inspect the retained hierarchy, screenshot and app lifecycle before changing product behavior.

One attempted verification could not start because the machine refused new processes. Obsolete logging and simulator helpers owned by this chat were stopped; the user's separate preview was preserved. After cleanup, the compact-menu case passed (`test_sim_2026-10-18T02-46-48-077Z_pid85535_1128b3fc.xcresult`). The final batch passed **9 tests, zero failures/skips**: seven SkyDialogueTests, paused guide/restore, and opening-cascade native input (`test_sim_2026-10-18T02-48-28-017Z_pid85535_b3a9efc0.xcresult`). This final batch compiled cff461e plus the reader change; environment and simulator match the earlier local checks. No new actual VoiceOver, physical-device, visual-animation or human-enjoyment evidence is claimed. Release was not rerun for these test-only changes.
