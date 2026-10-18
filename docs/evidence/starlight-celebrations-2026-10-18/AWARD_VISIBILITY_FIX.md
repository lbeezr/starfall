# Restore visible clear awards

**Result:** Partially verified · **Owner:** current implementer · **Date:** October 18, 2026

The player clarified that the running total was visible, but no points appeared when stars popped. The celebration overlay required board, header and score anchors. The header's `anchorPreference` replaced its descendant score preference, so the overlay's three-anchor condition failed. The shared registration now transforms the existing dictionary, preserving descendant and sibling roles.

**Next action:** integrate the bounded fix, then inspect the +N and collection animation on normal phone play. Actual effect appearance/timing and physical preference remain unverified until captured or tried; the earlier successful store tests did not establish that the overlay rendered.

## Reproduction and correction

A native macOS SwiftUI/AppKit probe used the production anchor types/modifier and the same nested score-inside-header plus sibling-board arrangement. Before correction its observed roles were `board,header`; afterward they were `board,header,score`. This verifies the preference-loss mechanism on Apple's SwiftUI framework; it is not an iOS app screenshot or animation acceptance.

All three `FallingSkyView` registrations now use one `starlightAnchor` modifier with `transformAnchorPreference`. The board registration and nested score/header path were examined; the overlay still resolves these real anchors in its existing coordinate space. No frame, gesture, score, recipe, reward, receipt lifetime or save rule changed. Ordinary clears, constellations, recipes and relays share this corrected overlay admission path; their individual visual quality is not established by the probe.

A hosted regression creates a real `UIHostingController` window and requires all three roles to reach the parent overlay. It exercises nested and sibling registration, with a bounded expectation, rather than checking only the store receipt. Existing receipt tests remain unchanged.

## Source and verification

Base main `e4c8f2b`; the checkout also retains an earlier documentation-only retry report. Dirty runtime/test inputs are `App/FallingSkyView.swift`, `App/StarlightCelebration.swift` and `AppTests/StarlightCelebrationTests.swift`; their hashes are recorded in `award-fix-source.json`. Xcode 27.1 (27A9275), Swift 6.4, arm64. No target/resource membership changed.

| Check | Result / boundary |
| --- | --- |
| Native framework reproduction | Before: missing score; after: all three roles. macOS 27.0.1 AppKit/SwiftUI, not iOS gameplay. |
| Core | 149 pass, `swift test --jobs 1`; no core changes. |
| Debug | Simulator build-for-testing passes, including compilation of the new hosted regression. |
| Release | Simulator build passes. |
| Hosted/native interactions | Final selected run attempted on Forecast QA (`1E9DCEF5-BF64-4052-AF8D-A6A205F711EE`), iPhone 17e / iOS 27.0. Both app and UI test runners exited with a signal kill before establishing their test connections; no selected assertions executed. The runtime run failed, not passed. Earlier reproduction attempt could not locate the destination; sampled xcodebuild waited for CoreSimulator notification registration. |
| Visual/animation | No new iOS capture or animation acceptance. Selected active-play index remains Needs refresh. |
| Interruption/accessibility/save | Existing guards and saves unchanged. Runtime settings/background/largest-text selectors attempted above; actual VoiceOver deferred to RC. No phone install bypass. |
| Hygiene | `python3 scripts/ci-hygiene.py` and `git diff --check` pass. |

Raw probe source, before/after output, compiler/test logs and process sample are under ignored `artifacts/celebration-anchor-fix/`. The probe was compiled with `swiftc -parse-as-library` and executed against the native framework. Debug uses generic arm64 iOS Simulator, ad-hoc signing and build-for-testing; Release uses a separate DerivedData directory and no signing. The final runtime attempt uses the built `.xctestrun`, four technique interaction selectors and `StarlightCelebrationTests`, with a 15-second destination timeout. No assertions were weakened and no quiet-motion setting was forced to obtain a pass.

## Remaining risk

The missing-anchor mechanism is corrected; the effect's timing, density and legibility still need normal-motion iOS inspection. Trigger: the next responsive simulator or physical play session. Check ordinary +N, five-star trace, square/cross and relay feedback, rapid independent clears, zero-reward Dusk, danger chrome, largest text and interruption cancellation. Keep the total visible and the clear's committed reward exact. See the existing [acceptance follow-up](../../ENGINEERING.md#starlight-collection-acceptance--october-18-2026).
