# Opal mesh compiler compatibility

The main push at `f6f1cd8` failed before native tests on [CI run 39079370673](https://github.com/lbeezr/starfall/actions/runs/39079370673/job/117533003741). Xcode 26.3 / iOS 26.2 SDK reported `FallingSkyMotion.swift:124:60: cannot convert value of type [Int] to expected argument type [Float]`. The local Xcode 27.1 / Swift 6.4 build had accepted the same contextual literal expression. The previous local green results do not establish older-compiler compatibility.

The round warp's two fractional rows now use explicit Float numerators before division. This fixes the type boundary without casting already-truncated integer results. Acceptance is an identity mesh at all twelve vertices, successful build on both toolchains, preserved full falling/contact/round-reset behavior, and unchanged Core/save outcomes. The regression checks every source and destination vertex against its expected normalized coordinate. Review covered the other four mesh initializers, source-grid row conversion, and related ratios in FallingSkyMotion/StarCast; the observed ambiguous integer-fraction literal occurred in the round initializer. This does not claim a repository-wide compiler audit.

## Local verification

Source: `f6f1cd8` plus only App/FallingSkyMotion.swift and AppTests/StarCastTests.swift. The three untracked Opal study files are outside the app target and excluded from this fix. Simulator: private iPhone 17e, iOS 27.0, arm64 unsigned, Debug, scheme Starfall; DerivedData `/tmp/starfall-trace-integration-build`.

- Core: `swift test`, **89 passed**, zero failures; `/tmp/starfall-opal-mesh-core.log`.
- Hosted: **14 StarCastTests passed**, zero failures/skips, including identity, real motion/handoff, cancellation, round restore and quiet equivalence. Result `test_sim_2026-10-17T23-40-44-101Z_pid85535_dd282c57.xcresult` under `~/Library/Developer/XcodeBuildMCP/workspaces/Starfall-27844ad883f3/result-bundles/`.
- Release simulator build passed without warnings/errors: `build_sim_2026-10-17T23-42-11-233Z_pid85535_80ce9e40.log` in the same workspace's logs directory; DerivedData `/tmp/starfall-flow-trace-release`.
- Hygiene and diff checks passed. Normal motion [falling](falling.png) and [round rest](round-rest.png) captures inspected; stage timing is not a deterministic pixel comparison.

No rules, RNG, save format, geometry mapping, touch targets, settings or spoken behavior changed. Their unchanged [development acceptance](../opal-main-integration-2026-10-17/README.md) remains source-bound. Full actual VoiceOver is not rerun for this presentation arithmetic fix under the accepted development/RC cadence. Only Swift 6.4 is installed locally; the decisive older-compiler verification is the next automatic main CI run, still pending publication of this fix. No assertions or CI gates were weakened.
