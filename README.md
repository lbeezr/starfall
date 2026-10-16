# Starfall

A small native iOS puzzle prototype. Tap a connected group of at least three matching jewels to collect starlight. Clear **70 jewels in 18 moves**. No timer. Horizontal/vertical connections only; invalid taps are free. Jewels settle downward and refill from above. If a live board has no legal move, a free cluster appears. There are no chain cascades or special pieces.

## Open and run

Requires Xcode 16+ with an iOS 17+ simulator runtime. Open `Starfall.xcodeproj`, select shared scheme **Starfall** and an installed iPhone simulator, then Run. Simulator builds do not require paid Apple enrollment or a signing team. Device distribution/signing is not configured. This is a prototype, not an App Store submission package (no production icon or distribution metadata).

```sh
swift test
xcodebuild -project Starfall.xcodeproj -scheme Starfall \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

The local Swift package has no external dependencies. Core tests also run on Linux with Swift 5.9+. Xcode's app scheme does not contain the package tests: run `swift test` separately.

Launch arguments:
- `--demo`: deterministic seed 42, opens the board, does not write game saves
- `--demo --demo-clear`: deterministic seed 42 with its first legal group cleared through the real core before board presentation
- `--reset-save`: removes the previous game save before starting normally

## Scope

- Pure deterministic puzzle core and Codable save state
- SwiftUI menu/settings and SpriteKit board
- Code-drawn translucent glass jewels with five distinct color/shape pairings
- Clear and settle animation, restrained sparkle particles
- Optional system tap sound (off by default); Calm Effects honors Reduce Motion
- VoiceOver alternative grid with row/column, jewel name and connected-group size
- On-device auto-save after each valid move; new game resets progress

The procedural sprites are implementation artwork, not a claim of matching any separate concept image. No image files or third-party art are required. No network, tracking, account, collection, lore, extra modes, ad SDK or purchase SDK.

## Editions

`Config/Clean.xcconfig` supplies `STARFALL_CLEAN`; all existing configurations are clean. Monetization code, dependencies, UI and entitlements are physically absent. See `AGENTS.md` for the boundary for any future optional edition. No speculative monetization subsystem is implemented.

## Verification

See `docs/VALIDATION.md` for exact executed checks and outstanding checks. Apple-platform compilation, simulator launch, screenshots, accessibility behavior and physical-device behavior must not be inferred from passing pure-core tests.
