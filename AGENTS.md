# Starfall repository instructions

Keep the prototype small. Falling sky is the default game in Debug and Release: deterministic accumulating stars, automatic showers with pause, dark stars, and local balance controls. The original 7×7 orthogonal puzzle remains available for Debug testing: five jewel types, groups of 3+, 70 cleared jewels in 18 valid moves, no timer, invalid taps spend no move, win takes precedence on the last move, and dead-board recovery is free and bounded. No power-ups, progression, backend, accounts, paid assets or external SDKs.

- Keep deterministic rules in Sources/StarfallCore, with no UI imports; test with `swift test`.
- App uses SwiftUI and SpriteKit, iOS 17+. Shared scheme: Starfall.
- Every current build is clean. Ad and IAP SDKs, entitlements, tracking and monetization UI must remain absent. Any future monetized edition must be a separate opt-in target/product with dependencies conditionally linked; a runtime hide flag is insufficient.
- Do not claim simulator/device or visual validation unless actually run on Apple tooling.
- Do not change another repository or add network features, purchases or analytics without a new request.
- Run tests and a simulator build after source changes where tooling exists. Inspect normal play, rapid taps, win/loss, restart, background/resume, VoiceOver, Reduce Motion, and settings dismissal.

## Code quality
Keep rules deterministic and independent from rendering. Keep presentation, saved state and feedback behind small, explicit boundaries; add focused tests for behavioral changes. Prefer incremental reviewed changes over a growing multipurpose module, but do not introduce speculative frameworks or split files solely to meet an arbitrary size. Reuse the bounded jewel material factory rather than duplicating drawing logic.

## Incremental integration
Merge completed, verified work in small batches as it becomes ready. Do not let an unrelated blocked workstream delay integration or allow a large backlog of changes to accumulate. Keep each commit scoped to its workstream, preserve other agents' in-progress edits, and run the checks appropriate to each batch before integrating it.
