# Starfall repository instructions

Keep the prototype small: a 7×7 orthogonal tap-to-clear puzzle, five jewel types, groups of 3+, 70 cleared jewels in 18 valid moves. No timer, power-ups, progression, backend, accounts, paid assets or external SDKs. Invalid taps spend no move. Win takes precedence on the last move. Dead-board recovery is free and bounded.

- Keep deterministic rules in Sources/StarfallCore, with no UI imports; test with `swift test`.
- App uses SwiftUI and SpriteKit, iOS 17+. Shared scheme: Starfall.
- Every current build is clean. Ad and IAP SDKs, entitlements, tracking and monetization UI must remain absent. Any future monetized edition must be a separate opt-in target/product with dependencies conditionally linked; a runtime hide flag is insufficient.
- Do not claim simulator/device or visual validation unless actually run on Apple tooling.
- Do not change another repository or add network features, purchases or analytics without a new request.
- Run tests and a simulator build after source changes where tooling exists. Inspect normal play, rapid taps, win/loss, restart, background/resume, VoiceOver, Reduce Motion, and settings dismissal.
