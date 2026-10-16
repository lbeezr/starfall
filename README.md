# Starfall

A small native iOS puzzle prototype. Tap a connected group of at least three matching jewels to collect starlight. Clear **70 jewels in 18 moves**. No timer. Horizontal/vertical connections only; invalid taps are free. Jewels settle downward and refill from above. If a live board has no legal move, a free cluster appears. There are no chain cascades or special pieces.

## Open and run

Requires Xcode 16+ with an iOS 17+ simulator runtime. Open `Starfall.xcodeproj`, select shared scheme **Starfall** and an installed iPhone simulator, then Run. Simulator builds do not require paid Apple enrollment or a signing team. Device distribution/signing is not configured. This remains a prototype; App Store distribution and submission metadata require their own release work.

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
- `--crystal-pilot`: Debug-only comparison with the original aqua pilot and procedural artwork for the other four kinds; Release ignores this argument

The current five-kind crystal family is enabled by default in Debug and Release. It needs no launch argument.

## Scope

- Pure deterministic puzzle core and Codable save state
- SwiftUI menu/settings and SpriteKit board
- Offline-rendered crystals with five distinct color/shape pairings and a complete procedural fallback
- Bounded clear fragments, downward settling and diagonal refill presentation
- Optional local quiet-tuck sound (off by default); Calm effects honors Reduce Motion
- VoiceOver alternative grid with row/column, jewel name and connected-group size
- On-device auto-save after each valid move; new game resets progress

The default artwork comes from the [sealed v2 crystal handoff](Artwork/Crystals/v2/README.md) and its [manifest](Artwork/Crystals/v2/manifest.json). It is newly authored Blender geometry, material and lighting based on visual references, not recovered original source or an alpha-identical replacement. The app uses the five packaged atlases together; if any member is missing or malformed, every kind uses the existing procedural material factory. Rendering remains SpriteKit 2D with no runtime 3D or external asset service. The original aqua pilot remains a separate explicit comparison.

The package records its pre-adoption handoff state and is preserved unchanged. Runtime adoption does not establish native visual, accessibility, performance or physical-device acceptance; see [the validation record](docs/VALIDATION.md). The [audio integration record](docs/design/audio/INTEGRATION.md) separately documents the local quiet-tuck starter. No network, tracking, account, collection, lore, extra modes, ad SDK or purchase SDK.

## Editions

`Config/Clean.xcconfig` supplies `STARFALL_CLEAN`; all existing configurations are clean. Monetization code, dependencies, UI and entitlements are physically absent. See `AGENTS.md` for the boundary for any future optional edition. No speculative monetization subsystem is implemented.

## Verification

See `docs/VALIDATION.md` for exact executed checks and outstanding checks. Apple-platform compilation, simulator launch, screenshots, accessibility behavior and physical-device behavior must not be inferred from passing pure-core tests.
