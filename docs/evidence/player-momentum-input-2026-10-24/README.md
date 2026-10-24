# Accept the next move while the cascade continues

**Status:** Verified nonvisual correction, PR #398 · **Date:** October 24, 2026

The existing 650 ms single-request buffer could expire a valid swipe during a real five-phase Ribbon cascade. A later contact also replaced an earlier accepted request. This slice keeps up to four independent plans in FIFO order through physical presentation; combo and collection announcements continue. Only actual commits award points or save.

## Ownership and scope

Core previews each request in sequence. Admission names visible stationary identities and validates both exchange endpoints through every presentation waypoint, including an exchange that eventually settles back to its origin. Moving, replaced, dependent or conflicting endpoints reject. A held tap submits before releasing its ticket, so an older queued head cannot retarget that tap. Existing disjoint direct actions remain available.

The queue has no wall-clock expiry and admits at most four requests per continuous burst, including already-dispatched requests. It cannot replenish indefinitely and starve rain. Existing lifecycle/layout/motion/round boundaries cancel pending plans; the exact frozen shower remainder resumes after the final dispatch or cancellation, with already-due rain retaining priority. Projected terminal outcomes reject followers. Only executed Core state is persisted.

This is a source-exact extraction from the already tested first-loop candidate in [draft #395](https://github.com/lbeezr/starfall/pull/395). Home, first-play eligibility/cues, layout, component roles, marker artwork, visible status and board accessibility summaries retain main `22ab5c2d` bytes. The existing arrow presents the current queue head; a multi-plan count/marker treatment remains visually held in #395 with active HUD correction #382. No new appearance is adopted by isolating this behavioral fix.

## Verification boundary

[Source snapshot](source.json) records every build-affecting dirty input at Debug build and test dispatch. Subsequent changes to this branch are evidence/docs only; final committed source must match those hashes. The unchanged Core suite passes 352 tests. Debug build-for-testing passes. Release, all 88 selected hosted checks and the native five-phase journey pass with zero failures/skips. [Verification summary](verification.json) records exact source, commands, environment and result. Hygiene and whitespace pass. These establish execution, not physical feel or new visual adoption.

The hosted selection covers36 SkyTechniqueStore,17 ResponsiveInput,29 SkyDialogue and6 SkyPhasePresentation checks. Queue regressions verify FIFO, four-admission bound, held-tap order, stationary/settle-back identity, moving manual-group member rejection, terminal/lifecycle cancellation, committed-only saves and exact clock remainder. The native method uses the real Ribbon revision 7 opening and 11 production exchanges, then submits three rapid inputs through the actual five-phase action with no settling/readiness wait. Acceptance requires exactly 15 committed exchanges,179,000 points and49 actual stars. It does not depend on a proposed visual queue counter.

Environment: Xcode 27.1 (27A9275), arm64, SDK 27.1, iOS Simulator 27.0 (24A434), dedicated iPad mini (A17 Pro) `9ADC6510-1A37-4046-9FCA-FC6B498444FA`. Normal system motion and app Calm off are asserted. The broader same-input implementation separately passed the equivalent normal iPhone 17e journey; that is supporting evidence at its recorded source, not this branch's own native result.

Disposable commands/logs are under `/private/tmp/starfall-momentum-input-{build,core,tablet,release}.log`, with tablet `.xcresult`. Builds use the shared Starfall scheme, Debug build-for-testing and Release arm64 with signing disabled. Native/hosted tests run without building, parallel testing disabled, no diagnostics collection and the exact selected methods. No test assertions, production cadence, motion or input history were weakened to pass.

## Limits and next action

No human latency/recognition, physical thumb comfort, actual VoiceOver, minimum-iOS runtime, sustained performance or later-day return was measured. These belong to identified observation, not seeded correctness. Existing #206 remains open. First-play and feedback visual work remains independently held; this correction grants no visual adoption or phone-delivery authority.

The Store remains over 1,200 lines because commit, save, clock and cancellation ordering are verified together here. The concrete follow-up in ENGINEERING extracts pure queue admission into the existing input owner after responsiveness acceptance; do not move mutation into a renderer or split by line count.
