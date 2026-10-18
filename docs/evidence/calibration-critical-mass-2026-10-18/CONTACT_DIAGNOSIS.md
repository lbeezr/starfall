# Two native misses arrived after the shower had committed

**Result:** Verified for the instrumented sample; earlier contacts and physical feel remain open · **Owner:** current implementer · **Date:** October 18, 2026

Keep the current input contract. In a new seed-28 automatic run, all 12 admitted native contacts commit taps. Two other contacts reach touch-down after a shower commits and reserves every column; both are denied before acquiring a hold. The actual OS touch timestamps are 113/114 ms after the respective commits. Neither is an admitted touch lost during release.

**Next action:** use physical intended-contact observations to judge whether available windows feel fair. If a future miss occurs after an admitted hold, retain its exact native timeline and investigate that distinct failure. The [earlier three uninstrumented misses](AUTOMATIC.md) are not retroactively diagnosed by this run. No input buffering, rule or timing change follows.

## What was measured

| Contact in this run | Actual native sequence | Result |
| --- | --- | --- |
| 4: row 3, column 0 | Shower 13 commits; OS touch follows 0.112993 s later, 0.304699 s after its scheduled deadline. Origin/group are settling; all seven columns reserved; hold denied; release blocked. | Score stays 15; no queued tap. |
| 7: row 0, column 5 | Shower 15 commits; OS touch follows 0.114379 s later, 0.173278 s after its scheduled deadline. Origin/group are settling; all seven columns reserved; hold denied; release blocked. | Score stays 22; no queued tap. |
| Other 12 contacts | Native touch maps to the queried cell; ready origin/group; hold granted with deadline frozen; same-cell tap on release; Store commits. | All 12 score, including one eight-light clear. No admitted cancellation/lost release in this sample. |

Rows/columns use Core's zero-based coordinates. These timings describe event ordering in a diagnostic build, not product latency or a proposed grace interval. Scheduled deadlines were already late before these two OS contacts; delivery after an OS timestamp and diagnostic logging overhead must not be interpreted as a cause-free performance measurement.

The run ends with 51 starlight after 31 showers, fourteen attempts, two non-scoring attempts, eighteen skipped stale selections and no terminal outcome. Its interaction history differs from the earlier 44-light sample because driver timing changes decisions. Scores/miss counts are not a controlled before/after comparison or a human success rate.

## Acceptance and disposition

| Criterion defined before instrumentation | Evidence |
| --- | --- |
| Capture actual native contact, mapping and generation | UIKit touch timestamp plus handler uptime, local point, mapped cell and generation recorded on all fourteen touch-downs; per-contact records in [source/analysis](contact-diagnostic-source.json). |
| Resolve admission versus committed shower order | Actual automatic commit, deadline, moving columns, origin/group availability and hold result correlate for both misses. All twelve admitted contacts produce a matching native tap and Store `tapAccepted`. |
| Inspect cancellation/release | Both denied contacts release blocked with no primary owner; all admitted contacts release normally. No admitted touch is lost in this sample. This does not exclude other failure classes. |
| Bound and remove diagnostics | 415 events in the test process, below the 1,024-event cap; stream stopped. Three source files restored byte-for-byte to main, normal app rebuilt/installed. No diagnostic route, preference, file writer, dependency or logging remains in app sources or built Debug/Release app binaries. |
| Verify restored behavior | 162 Core tests, 14 hosted input tests and the native five-second stationary-hold/drag/ordinary-tap case pass. Debug build/run and Release simulator build pass; hygiene/diff checks pass. No source/layout/rule/save change. Actual VoiceOver, physical input/haptics, human comprehension and general animation smoothness are not run or established. |

**Decision:** local investigation closed; instrumentation removed. Preserve the reproduced no-stale-clear and held-deadline invariants. The observed denial is consistent with the specified moving-column contract. Evidence does not justify bypassing it or replaying a gesture on a later occupant. Fairness of the time available to a physical player remains a calibration question.

## Source and reproduction

Base main `834b7f55e6b8ecd8393033676251bb0ade0d00d9`; local merge `99d618d` has identical tree `adab4d453fb980344c87e4ba3fcf59dd73b9bfaf`. The instrumented run changes only `App/ConstellationTraceSurface.swift`, `App/FallingSkyView.swift`, and `App/FallingSkyStore.swift`, all listed with before/after hashes in [contact-diagnostic-source.json](contact-diagnostic-source.json). No rule or schedule expression changes. The [historical instrumentation patch](contact-instrumentation.patch) captures the exact local candidate; it is evidence, not compiled app source. It adds a bounded local console logger at native down/up/cancel/outcome, view contact/tap, hold/clear admission and the existing timing observer.

Xcode 27.1 / Swift 6.4, Debug arm64, task-owned iPhone 16 Pro Max Simulator, iOS 27.0 (24A434), UUID `5107CBBF-108B-4B94-9125-A873F948A38C`. Calm explicitly off, system Reduce Motion off. The native sample selects `FreshSkyPlaytests/testRepeatedAutomaticVisibleMatchesSeed28`, 100.226 s total. It uses the [automatic sample's exact build/test flags](AUTOMATIC.md#evidence-and-limits), result `artifacts/calibration-contact-diagnostic/native.xcresult`.

The parallel diagnostic stream is `xcrun simctl spawn <owned-UUID> log stream --style json --level info --predicate 'subsystem == "com.starfall.prototype" AND category == "ContactCalibration"'`. Select process 12783; the earlier build/run process emitted eleven separate setup events and is excluded. Stream stderr reports the simulator's `getpwuid_r` lookup warning; event collection still captures the complete fourteen-contact sample. Raw stream/hash, exact contact strings and both denial contexts are retained in the source record. The raw stream, test log/attachments, analysis and original-source backup stay in ignored `artifacts/calibration-contact-diagnostic/`.

After source restoration, `removed-validation.xcresult` selects `ResponsiveInputTests` (14 pass) and `ConstellationTraceNativeTests/testStationaryTouchHoldsShowerBeforeDragAndTapStillWorks` (23.314 s, pass). Core log: `core.log`; Release log: `removed-release.log`, generic simulator with `/tmp/starfall-calibration-release` and the same scheme/arm64/signing flags. No failures or retries. Restored app bytes match the main tree; the final batch changes only this evidence and its documentation links. No native appearance claim or new screenshot is needed for this event-order diagnosis.
