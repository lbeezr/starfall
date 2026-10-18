# Non-scoring native attempts follow changing readiness

**Result:** Verified bounded diagnostic · **Owner:** current implementer · **Date:** October 18, 2026

Retain the game’s input rules. The examined non-scoring taps reflect stale readiness and an arrival boundary; no unexplained lost touch was reproduced. Correct the native driver to re-read group value and readiness just before contact, skip stale selections and retain bounded diagnostics. This changes test behavior, not the app, clock, queue or balance.

**Next action:** Play deliberate setups under automatic rain. If a player reports a missed tap, retain the physical reproduction and contact/admission state; these clear-only samples do not establish that every input issue is eliminated.

## What the samples explain

The initial seed-180 diagnostic made ten attempts. All four non-scoring attempts had **`targetReady=false` immediately before contact**. Three post-tap hierarchies contained **“Stars settling…”**; the fourth target was ready by the later hierarchy capture. A different disabled-before-contact attempt did score, showing readiness can also recover before the actual event. The inspected first screenshot shows the settling cue with incoming stars; raw screenshots remain in artifacts.

The driver had selected a legal, enabled target during a scan of all 49 cells, then synthesized a touch after that information became stale. Legal group value is not a promise of current input admission. The app’s readiness snapshots and moving-column feedback consistently describe the examined rejections.

After adding the late check:

| Sample | Taps / score-changing taps | Stale selections skipped | Non-scoring feedback |
| --- | --- | --- | --- |
| Seed 180 | 14 / 13 | 3 | One later “Stars settling…” boundary after readiness sampled true |
| Seed 5 | 10 / 10 | 5 | None |

After consolidating the exposed-reward parser, both original seeds pass again: **13/13 taps change score**, with 23 stale selections skipped. That final run is a regression check, not a claim that the guard improves gameplay, guarantees admission, or increases a human score. Native scheduling differs between runs. Do not compare the sample scores or rejection counts as a controlled difficulty result.

The driver now resolves stable identifiers, captures immediate value/frame, reads readiness last and starts no touch when the value is no longer legal or the button is disabled. It rescans in its next bounded selection cycle; it does not enqueue a coordinate or retry a pending action. The same parser owns candidate reward and late validation. Legal zero-reward Dusk groups remain permitted; non-scoring positive-reward attempts receive diagnostics (at most four hierarchies and two screenshots). Existing score-gain assertions and full effects remain unchanged.

## Boundary examined and limits

Reviewed the shared `SkyInputPolicy`, `clearAvailability`/`canClear`, native button disabling, `beginBoardContact`, the physical recognizer’s begin/end path and `tapBoardCell` → `store.clear`. The store still owns admission; the physical session freezes rain only after an admitted contact. Readiness can change between an AX property read and touch-down. A failed contact reports settling/arriving and is not replayed later. No rule, coordinate mapping, production feedback or lifecycle correction was justified by this reproduction.

This is evidence for the named stale-selection mechanism. It is not a contact-level trace of every rejection, a general latency benchmark, a rapid/curved trace or swap test, or human/physical-device acceptance. Extra queries and captures change the driver’s timing. The selection-cycle budget stays 45 seconds; an in-flight native cycle may finish afterward.

## Subsequent presentation integration

Before publishing, fetched and merged main **`a928693`**, visible awards/open selection sparkles. That change affects presentation and view initialization, not store admission or rules. Seed 180 passes again on the combined source; no production fix is added by this batch. The diagnostic tables above retain their original main `6f8155f` source.

The integration command began after main's runtime files had been checked out while one documentation merge conflict remained. Only that documentation changed before the merge was finalized as `adea3ed`; runtime inputs stayed unchanged throughout compilation/execution and match `a928693` exactly. The [manifest](contact-source.json) records the staged runtime paths and hashes. This is explicit dirty-input provenance, not a clean-at-command-start claim.

## Source and checks

Fetched `origin/main` before each batch; main remained **`6f8155f`**. Local base **`8ec63f4`** has identical runtime inputs, fingerprint **`dev.d77248d12e`**. Only `UITests/FallingSkyInteractionTests.swift` differs in the native build. [Source hashes, event observations and feedback](contact-source.json) distinguish the diagnostic, late-check and final parser runs.

- **Native:** initial diagnostic, two late-check cases and two final cases pass; normal effects, automatic rain, no weakened assertions.
- **Core/build:** 149 Core pass; Debug simulator test build/execution passes. Hosted/Release not repeated: no app, rule, resource, configuration or target-membership change.
- **Hygiene:** `python3 scripts/ci-hygiene.py` and `git diff --check` pass.
- **Other acceptance:** no actual VoiceOver, physical-device, audio/haptic or smoothness claim. Existing current-main evidence retains its original source.

Xcode 27.1 / Swift 6.4; iPhone 16 Pro Max, iOS 27.0 (24A434), QA `5107CBBF-108B-4B94-9125-A873F948A38C`; Debug arm64. Calm effects and system Reduce Motion off. Simulator binaries display `dev.local`; no phone installation.

Raw logs/bundles: `artifacts/calibration-native/contact-{diagnostics,ready-check,ready-final}.{log,xcresult}`, corresponding attachment folders, preserved pre-extraction `contact-ready-driver.swift`, and `artifacts/calibration-current/contact-core.log`. Native commands use scheme Starfall, explicit QA destination, no parallel testing, bounded 180/240-second allowances and ad-hoc simulator signing. Methods remain `FallingSkyInteractionTests/testFreshAutomaticVisibleMatchesSeed180` and `testFreshAutomaticVisibleMatchesSeed5`.
