# Engineering guide and debt register

The working contract is [AGENTS.md](../AGENTS.md). This page explains verification and tracks specific deferred work; it is not a second product roadmap. Keep the deterministic package, small app store, renderer and explicit effects/save boundaries. No mandated architecture framework, new dependency, campaign or Swift-language migration is needed for this pass.

## DRY and modularity

Use the DRY, dependency-boundary and roughly 1,200-line review rules in [AGENTS.md](../AGENTS.md) during each change. Extract around a responsibility with a clear owner and inputs, not a line-number range. A separate file alone does not decouple code: the extracted component should not reach back into unrelated mutable state. Introduce a protocol where substitution or an existing test boundary needs one; a focused value type or concrete helper is often sufficient. Shared behavior should have one owner without forcing unrelated features into a generic framework.

The current app Swift files are all below that size trigger. The duplicated board-coordinate mapping remains a concrete earlier extraction candidate because render/tap alignment must change together, regardless of file length. No broad source refactor is part of this guidance update.

## Working loop

1. Inspect `git status --short` and the change's boundary. Preserve other edits, especially Xcode project configuration. Identify whether a rule/save, lifecycle, rendering, layout, asset or build contract changes.
2. Make the smallest complete change. Keep seeded rule decisions separate from presentation timing. Add focused behavioral regression coverage for a changed contract, not tests that repeat its implementation.
3. Run `python3 scripts/ci-hygiene.py`, `git diff --check`, and `swift test`. Run affected native hosted/UI checks and a simulator build for app changes. The shared Starfall scheme includes app tests; core package tests run separately. Use an installed simulator and a temporary DerivedData directory. The cloud script is for disposable runners, not a local machine: it selects, boots and shuts down a simulator and requires runner variables.
4. For UI changes, inspect normal and accessibility-size screenshots and exercise actual touch alignment, rapid input, outcomes, restart and interruptions. Exercise full animations separately from reduced-motion alternatives. For assets, use existing validators under tools/art-quality; preserve canonical handoff files and fallback behavior.
5. Review explicit staged paths and the staged diff. A new App/AppTests/UITests file must be included in its Xcode target; a Swift package file is discovered separately. Check both Debug and Release when changing configuration or resources. Do not broaden CI triggers or dispatch paid/manual runs as incidental cleanup.
6. Integrate verified work in small batches. Verify remote head and tree after publication, including connector publication that changes commit metadata. Update the relevant evidence index and roadmap; keep previous evidence historical.

The hygiene script checks tracked generated/user files and ordinary imports of UI/platform game frameworks in StarfallCore. It examines tracked paths and current core file contents, including local edits. It does not prove deterministic behavior, parse all Swift import syntax, validate target membership, scan credentials, or establish clean-commit/native acceptance. Existing CI retains its separate builds, test-count checks, privacy/resource checks and evidence export.

## Evidence discipline

A result needs a source commit/tree, any build-affecting dirty paths, toolchain, command/configuration, simulator model/OS and pass/fail summary. Publish acceptance from a clean checkout/export, or label the result as a working-tree check and explain the difference. Compilation, native interactions, inspected screenshots, observed animations, real VoiceOver and physical-device performance answer different questions. Avoid “all validated” from a subset. Keep raw logs, movies, xcresults, traces and DerivedData out of Git. Retain selected small screenshots/JSON with a reproduction note under docs/evidence. Existing asset/source handoffs remain tracked; do not use broad binary ignore rules.

## Concrete follow-ups

These are observed risks, not completed fixes. The next change touching each boundary should resolve it or update the trigger and evidence needed; no dates or fictitious assignees.

| Risk | When to address | Smallest useful resolution and proof |
| --- | --- | --- |
| Build configuration drift: the local project file differs from published main. Parsed differences include project object version and app scene/launch-screen/orientation generation settings in Debug and Release. Recent native UI evidence used this modified working tree. | Before calling the next published candidate visually accepted. | Review the settings as their own change, preserve their owner's edits, and run clean-tree Debug/Release plus relevant phone/tablet UI checks. A clean build alone does not close visual parity. |
| Scene and native cell overlay repeat the seven-row coordinate/inset constants. They currently agree, but an independent edit can break tap alignment. | Next board geometry change. | Define one small app-local geometry mapping consumed by both; retain pure core coordinates. Test real taps at top/bottom/edge cells across affected sizes, not only a first bottom-row match. No geometry framework. |
| CI exports many named classic screenshots, but does not yet require the new falling-sky opening/First Light/compact screenshots. Falling-sky interaction tests run, so this is an evidence gap rather than absent test execution. | Next CI/evidence edit. | Require a bounded set of falling-sky attachments alongside the retained classic regressions. Keep test/export failures visible; run within the existing approved CI policy. |
| The active falling-sky classes still carry Experiment names; classic entry retains historical debug routes. More pilots could accumulate. | When gameplay boundaries settle or a route is replaced. | Rename/remove obsolete routes in a scoped refactor with all target references and tests updated. Keep the authorized classic regression path. Do not combine cosmetic renaming with rule/save changes. |
| Minimum-OS, tablet/landscape, actual VoiceOver and physical-device feel are not established by recent compact iPhone simulator checks. | Before expanding support claims or distributing a candidate. | Record device/OS and inspect layout, rotor/focus/activation, sound/haptics and repeated rounds. Profile a fixed repeated-play scenario if frame pacing, energy or memory is suspect; do not invent performance thresholds. |

## References behind the conventions

[Swift concurrency documentation](https://docs.swift.org/latest/documentation/the-swift-programming-language/concurrency/) explains actor isolation and sendable values. [MainActor](https://developer.apple.com/documentation/swift/mainactor) is the app's existing UI-state isolation boundary. [SpriteKit scene updates](https://developer.apple.com/documentation/spritekit/skscene/update(_:)) are per-frame callbacks; keeping expensive asset work and broad state invalidation out of them is this project's engineering policy. These references do not require a Swift 6 migration or moving the small deterministic rules onto background tasks.
