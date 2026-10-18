# Snappy drawing without losing taps

**Result:** Verified development checks · **Owner:** current implementer · **Date:** October 18, 2026

Constellation starts now use the full native star target, and drawing follows six-point movement rather than twelve. Small unselected drift remains a tap. Choosing another star or making a larger excursion permanently claims drawing, so a partial constellation cannot fall back to clearing a whole group. Swaps keep the 150 ms hold and contact-ticket protection from the preceding batch. 149 Core, 27 hosted and eight native checks pass, along with Debug/Release simulator builds. Physical contact-to-display latency and phone feel remain unmeasured.

**Next action:** Observe physical rim starts, finger wobble, fast repeated taps and curved/retraced swipes. No phone installation is included.

## Acceptance and source findings

Acceptance was recorded before implementation: preview after six points; within-18-point contact ending on the original cell remains a tap unless a neighbor was selected; larger excursions/selected neighbors stay drawing even on return. Incomplete/outside drawing must never trigger ordinary-clear fallback. Preserve swap timing/tickets, independent-column input, interruptions, scrolling, normal animations, rules and saves. Expanded start admission was added after finding a second source boundary: the native button target admitted taps while an inset start circle rejected drawing at the same location.

The physical session previously used one `dragging` flag both to start preview and to choose the terminal action. Survival also treats occupied stars as potential swaps, so an ordinary 12–18-point wiggle could become an incomplete swipe and disappear. Preview now starts earlier while maximum excursion and sticky selected-neighbor intent classify release independently. Non-drawing starts retain the tap tolerance before vertical scrolling claims the contact. Large excursions still stay drawing after a return to the source.

Start admission now uses `ObservatoryGeometry.cell(at:)`, matching taps. Core's shared `canStartConstellation(at:)` predicate owns colored-first, five-star and exact-square start eligibility for both hit testing and transient intent. Analytic segment/circle testing along the path is unchanged. This also removes the start-time all-cell candidate search; no cache, new scheduler or rendering change was introduced. No measured CPU/latency improvement is claimed.

## Verification

| Criterion | Result / limit |
| --- | --- |
| Deterministic rules/save compatibility | 149 Core tests pass. New start-query regression covers five stars, exact squares, insufficient groups, empty cells and Opal-first rejection. Clear rules, save schema, RNG, Dusk timing and shower cadence are unchanged. |
| Shared touch classifier / sibling actions | 27 hosted tests pass: TraceInputPolishTests, ResponsiveInputTests and SkyTechniqueStoreTests. Covers 6/12/16/18-point preview/tap boundaries, selected-neighbor and larger-excursion intent, full native target starts, edge/duplicate release, stale contacts/hold tickets, independent ready columns during animations, interruption, quick action ownership and sampled full/quiet exchange motion. |
| Native fast rim start and selected set | Pass: fast swipe starts at 4% of the native target width, clears chosen five, leaves the sixth and restores correctly. Drawing/menu dismissal at Accessibility XXXL also passes. |
| Native cancelled drawing recovery | Pass: partial and outside traces cancel, explain the result and leave ordinary taps usable. No whole-group fallback. |
| Native tap drift | Pass: real 16-point ordinary drifts clear exactly once at normal text and Accessibility XXXL. |
| Native swaps, scrolling and ending/restart controls | Pass: quick-flick rejection, 200 ms held exchanges, empty-destination falling, subsequent ordinary clear, quiet largest-text scrolling with recipe controls, and full-sky result/replay entry controls. All eight native methods passed with no skips. |
| Build / membership / hygiene | Debug simulator test build and Release arm64 simulator build pass; all changes use existing target members. `python3 scripts/ci-hygiene.py`, changed-document file links and `git diff --check` pass. |
| Other acceptance | Actual VoiceOver and physical device not run under the development cadence. Win rules have Core coverage and the prior batch's native First Light win/full-sky acceptance; the full win round is not repeated for this classifier-only follow-up. No claim of physical latency, enjoyment or elimination of every possible blocked action. |

**Source:** base `a18cd5f` plus snapshot `e5d4e9f72caf`; [changed runtime/test input hashes](source.json). The earlier hosted/Core checkpoint preceded the shared start-target query; the final 27/149 counts above rerun that source. Documentation changes do not affect the app build.

**Environment:** Xcode 27.1 (27A9275), Swift 6.4, iPhone 17e / Physics Review simulator `1199FBAF-FCA7-4F0D-BD49-8282154CC9EE`, iOS 27.0 (24A434), arm64, Debug. Responsive and technique fixtures explicitly set Calm effects off; constellation helpers retain its existing preference. System motion was not changed for this run. Release uses generic arm64 iOS Simulator. No simulator was created, erased or shut down.

Commands: `swift test`; `xcodebuild -project Starfall.xcodeproj -scheme Starfall -configuration Debug -destination 'platform=iOS Simulator,id=1199FBAF-FCA7-4F0D-BD49-8282154CC9EE' -derivedDataPath /tmp/starfall-input-derived -parallel-testing-enabled NO -collect-test-diagnostics never ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGN_IDENTITY=- CODE_SIGNING_ALLOWED=YES DEVELOPMENT_TEAM= CODE_SIGN_STYLE=Manual test`, with `-only-testing:StarfallAppTests/<suite>` or the native methods above. Native cases use bounded 90/180-second allowances without retries. Release uses `/tmp/starfall-input-release`, `-configuration Release -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`.

Raw output: `/tmp/starfall-snappy-core.log`, `hosted.log`, `release.log`, `native.log` and `native.xcresult` under the same `/tmp/starfall-snappy-` prefix. Rendered Markdown was not inspected. No visual artwork/layout changes; selected [visual references](../../design/VISUAL_REFERENCE.md) remain source-bound and cannot prove gesture latency.

## Remaining scope

Related paths examined: ordinary physical taps, constellation admission/continuous hits/partial selection, swap admission/dwell/release, scroll capture, accessibility selection, contact generation/cancellation and store column reservations. Ready groups still work during unrelated movement. Actions against changing columns or an already-due shower still respect committed-state ownership; there is no coordinate queue or replay against a later occupant. Physical automatic-shower play is the next acceptance step, especially accidental-clear rate at cell boundaries and perceived snappiness. See [engineering follow-up](../../ENGINEERING.md#tap-and-trace-classification--october-18-2026).

Inspected the exported `trace-five-from-six` and `technique-largest-text-selected-controls` native attachments: the expected survivor/score are visible, and the wrapping recipe description plus Clear square/Cancel remain visible after scrolling. These stills do not prove motion or latency. No replacement artwork/layout capture is needed; raw images remain under `/tmp/starfall-snappy-attachments`.
