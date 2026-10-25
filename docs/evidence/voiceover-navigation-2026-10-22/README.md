# VoiceOver Story navigation and gesture investigation

**Result:** Unverified candidate; do not merge · **Owner:** factory coordinator · **Date:** October 22, 2026

[#217](https://github.com/lbeezr/starfall/issues/217) remains open. This branch preserves a diagnostic test/driver candidate, not accepted actual-VoiceOver gameplay. No production app, Core rule, save or phone-delivery change is included.

## Established observations

- The Free Play menu's World map row was AX-hittable at y691–747, while its owning scroll viewport ended at y717. Touching its center did not focus that row. Native VoiceOver forward traversal crossed the boundary.
- A six-second shower committed during slow spoken setup after Begin, invalidating the opening witness before its first exchange. Ordinary touch setup, committed save and paused restore preserve zero showers/zero score; actual VoiceOver menu → world map → Back retains that state. That current-Story menu row fits the viewport, so its passing round trip is distinct from the clipped Free Play observation.
- Repeated focus on the same source star passed. Public two-touch rotation produced distinct actual rotor categories and reached “Actions Activate.” The output combines category and selected action; the parser now accepts that observed form while excluding star descriptions and “Actions available” hints.
- The source-element fast swipe, even after observing Actions, spoke the source star rather than a move action. The strict speech assertion failed **before activation**. No 15,000/20,000 scoring result or post-action restore is verified.

The independent production-Core oracle starts revision-three Lantern at zero turns/score with a valid save. Exchange 8→9 legally produces 15,000; exchange 5→12 then produces 20,000, still zero showers and a valid save. Those values define the unreached native assertions, not observed VoiceOver outcomes.

## Source and results

Candidate base: `0214cf09b61fd9bf13bb6d37e9dd40aea97a6040`; [verification.json](verification.json) records the three changed input hashes and bounded native receipts. The later `bf09f946` factory-guidance merge changes Markdown/instructions only. Documentation edits from the coordinator's independent execution record are excluded from this candidate.

Environment: Xcode 27.1 (`27A9275`), Simulator SDK27.1, reserved arm64 iPhone17e / iOS27.0 (`24A434`), UDID `4103C352-DFC2-493E-A224-DE4CE3D50889`. Raw evidence stays disposable in `/private/tmp/starfall-factory-217/`.

| Check | Result |
| --- | --- |
| Latest Debug build-for-testing | Passed. |
| Latest exact one-test actual-VoiceOver selection | **0 passed / 1 failed / 0 skipped**, valid completed xcresult, exit65. Test151.331s; wrapper180.056s. |
| Registry unit checks, hygiene, diff | Three registry tests passed; hygiene/diff passed. These do not accept the failed UI test. |
| Candidate inventory | Development174UI/408hosted; RC181UI/408hosted with seven named VoiceOver deferrals. One new scoped actual session is registered; the six existing sessions are retained. |
| Full current Lantern VoiceOver round | Not run. Existing600s allowance remains; its fresh Begin→slow Pause setup still violates the proved witness precondition. |
| Physical VoiceOver / minimum OS / visual or motion quality | Not accepted by this investigation. |

The new scoped method has a240s limit after measured setup/action attempts exceeded90s before reaching restore; the existing full method and unrelated bounds are unchanged. No assertion was relaxed to turn a failed gameplay outcome green.

Earlier changed reproductions failed at different boundaries: clipped exploration35.046s; shower-contaminated first-action result94.428s; held drag exploring another row97.871s; source fast swipe without observed rotor94.780s; valid rotor output rejected by the earlier parser140.627s. Early result finalization stalled and only the completed run's owned command group was stopped; those incomplete bundles are not accepted results. The final two rotor runs finalized normally and retain valid failures.

## Next bounded investigation

Distinguish XCTest flick geometry/dispatch from VoiceOver action behavior, with the Actions category explicitly observed and exact committed-result assertions retained. The public [VoiceOver service](https://developer.apple.com/documentation/xcuiautomation/xcuivoiceoverservice) exposes navigation and speech rather than direct custom-action invocation. Apple's [custom-control guidance](https://developer.apple.com/videos/play/wwdc2026/220/) describes selecting an action with vertical swipes and activating with a double tap; it does not prove this test's synthesized gesture is equivalent. `hasFocus` describes UI focus and cannot replace spoken identity or outcomes.

Keep the draft separate from accepted main. Do not close #217, substitute coordinate gameplay drags for VoiceOver, add blanket retries or claim a full pass from partial navigation assertions. Correct the full-method setup before a full run, and choose any scoped execution budget from measured action costs. Physical-iPhone RC evidence remains separate. The candidate also has a minor comment to tighten: this machine observed “Actions Activate”; bare “Actions” is a documented category form, not an additional observed result here.
