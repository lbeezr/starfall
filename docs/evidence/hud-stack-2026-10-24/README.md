# A coherent set of native HUD instruments

**Status:** Goal 1 visually rejected by the user on October 24; correction active and goal 2 held · **Owner:** HUD coordinator, worktree dcf3 · **Started:** October 24, 2026

The user authorized [ten ordered HUD refinements](https://github.com/lbeezr/starfall/issues/381), with each goal tested and merged before the next implementation. Each pass retains the previous accepted behavior and corrects its current presentation seam in the normal app. Existing Observatory materials, native controls, rules, saves, replay, clocks and board mapping remain authoritative.

## October 24 visual rejection erratum

The user rejected goal 1's appearance after its initial merge in [PR #392](https://github.com/lbeezr/starfall/pull/392). The optional **Inspect next shower** action uses a menu component role and becomes an oversized enamel headline in active play. The tablet composition also disconnects the instruments from the scenery. These failures conflict with the [official game UI system](../../design/GAME_UI_SYSTEM.md) and [native production workflow](../../design/UI_PRODUCTION.md), even though the action's target, row placement and state preservation passed their mechanical checks.

The initial development-adoption verdict below is superseded. Its source identities, capture bytes/hashes, successful tests, earlier failures and original inspection statement remain historical evidence; they do not establish visual acceptance. [Goal 1 / #382](https://github.com/lbeezr/starfall/issues/382) is reopened for correction. [Goal 2 / #383](https://github.com/lbeezr/starfall/issues/383) is held until goal 1's corrected composition passes independent comparison with the approved reference and official component roles. Correct the oversized optional action and disconnected scenery now; later goals must not postpone a known failure.

| Order | Outcome | Issue | Integration |
| --- | --- | --- | --- |
| 1 | Expanded HUD reading order | [#382](https://github.com/lbeezr/starfall/issues/382) | Initial merge rejected visually; issue reopened, correction active |
| 2 | Coherent instrument typography | [#383](https://github.com/lbeezr/starfall/issues/383) | Held pending goal 1 correction and acceptance |
| 3 | Readability across every sky | [#384](https://github.com/lbeezr/starfall/issues/384) | After goal 2 merge |
| 4 | Shared control states and glyph craft | [#385](https://github.com/lbeezr/starfall/issues/385) | After goal 3 merge |
| 5 | One coherent forecast instrument | [#386](https://github.com/lbeezr/starfall/issues/386) | After goal 4 merge |
| 6 | Specific, calm pressure feedback | [#387](https://github.com/lbeezr/starfall/issues/387) | After goal 5 merge |
| 7 | Causal move-to-earned-light attention | [#388](https://github.com/lbeezr/starfall/issues/388) | After goal 6 merge |
| 8 | Consistent optional detail readers | [#389](https://github.com/lbeezr/starfall/issues/389) | After goal 7 merge |
| 9 | Whole-HUD adaptive layouts | [#390](https://github.com/lbeezr/starfall/issues/390) | After goal 8 merge |
| 10 | Complete native journey cohesion | [#391](https://github.com/lbeezr/starfall/issues/391) | After goal 9 merge |

## Goal 1 initial implementation: mechanical results retained

The hypothesis is that the expanded header can retain its ordered forecast and optional reading without giving each supporting item a separate row. Lantern and Ribbon now place the existing mode label beside **Inspect next shower** when their natural widths fit. Accessibility text and narrow widths retain complete stacked content. Full Board retains its standalone mode label and absence of shower controls; other locations retain their existing inspection action.

`FallingSkyView` owns composition and still captures and revalidates the exact forecast source. No Store, Core, clock, save, resource or target-membership change belongs to this pass. The forecast remains a complete separate group with native column buttons. Inspection keeps its 48-point target, busy gating and distinct live-clock behavior.

Tested working-tree base: `0d71f18cf8d41277bc3ae1a5b8c6536cde7cb9ca`; build-affecting changes: `App/FallingSkyView.swift` and `UITests/ForecastColumnInspectionInteractionTests.swift`. Computed runtime fingerprint: `dev.72a01d9bb7`; actual simulator label: `dev.local`. All 352 Core tests, 26 selected hosted checks and three final native methods pass with zero failures/skips; Debug build-for-testing, hygiene and diff checks pass. [Verification, exact source hashes and commands](verification-01.json) and [capture provenance](captures-01.json) retain their scopes.

The initial combined phone method reached inspection Return without a product assertion failure, then the command stopped at its 360.044-second boundary. Native test startup consumed about 68 seconds before the method; at the last logged action the method had run 260.19 seconds. This is incomplete acceptance, not a pass. Its unfinished result bundle has no `Info.plist`, so attachment export failed; the bounded-stage receipt, log and directly captured native stills remain available. The correction splits inspection and background/world preservation into two independent reset scenarios with the same 300-second method bounds. Frame checks reuse immutable samples instead of repeatedly querying accessibility; every target/containment/order assertion and outcome remains.

The first split run retained two failures: repeated scroll/reveal checks delayed the pinned-menu tap beyond the real first shower, violating the unchanged zero-shower setup assertion; the second method failed to launch system Settings before Starfall launched. The responsible test helper now checks the fixed menu once and taps it directly, keeping full target, viewport, Pause/Start sky and exact opening assertions. Only the dedicated phone was restarted, preserving data. Only diagnostic child 43406 of completed failed xcodebuild 41036 was stopped to finalize its result; unrelated processes were untouched. Independent final invocations pass: phone inspection 223.989 seconds, phone background/world 86.742 seconds, tablet 208.219 seconds. The outer 420-second single-method command bound accommodates measured launch/finalization overhead; each method retains its original 300-second allowance. No product clock, normal-motion mode, rule or assertion changed to obtain acceptance.

The normal phone cases verify complete targets, real column selection, inspector Return, background selection retirement and exact round/world preservation. The actual AX3XL Calm tablet case verifies full stacked support, native column taps, a real 15,000-point automatic chain, exact Full Board mode and absence of shower inspection/forecast controls. Calm is changed and restored through the existing native preference; it is not forced to hide a motion failure. Hosted checks preserve header/score/board anchors, exact forecast facts, source invalidation and score reflow. Core and hosted inputs did not change during the test-only setup correction. No resources, routes or membership changed; Release was not required for this layout/test-only slice.

| Historical, visually rejected: phone, selected column 6 | Historical, visually rejected: AX3XL actual-Calm tablet |
| --- | --- |
| ![Mode and inspection share a row above all five forecast targets](dev-72a01d9bb7-goal01-phone-selected.jpg) | ![Large text retains complete mode, inspection and ordered destinations above the scrolling board](dev-72a01d9bb7-goal01-tablet-stacked.jpg) |

**Original inspection/adoption statement — superseded by the visual rejection above:** Original-resolution exports were inspected. These frames establish the header's layout and selected-column appearance; the tablet's scrolling board extends below the captured viewport. They do not establish whole-board visibility, measured physical contrast or continuous animation quality. Retain the adaptive composition for development and revisit combined density in goals 2–9, then the final journey pass. No alternate runtime route remains.

The dedicated iPhone 17e (`89BC6263-797D-4573-838E-E238A90D0D79`) and iPad Pro 13-inch M5 (`3C3726C1-8880-48AE-AC2D-4C9376250DF7`) run iOS 27.0. Xcode 27.1 / 27A9275 builds the iOS 17+ app. No physical-device installation or reset is authorized by verification.

Human recognition, physical reading comfort, sustained performance, minimum-iOS execution and full actual VoiceOver are separate, unperformed acceptance. Existing physical contrast [#209](https://github.com/lbeezr/starfall/issues/209) remains open. Native correctness and inspected screenshots cannot establish enjoyment or learning.
