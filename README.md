# Starfall

A small native iOS falling-sky puzzle. Start the sky, then clear connected matching jewels worth at least 3 starlight while new stars arrive. Large jewels count as 2. Dark stars block nearby growth; clear beside one to dissolve it. New skies offer a match in the first shower. Matching colors travel together, and dry boards receive a matching run in a later preview when a low column has room. Call the next shower yourself, or clear while paused. Tune shower pace and dark-star frequency in Settings, and replay or start a new sky when the board fills. Falling sky is the default in Debug and Release; progress stays on this device.

The current [roadmap](docs/ROADMAP.md) and [falling-sky playtest](docs/PLAYTEST-FALLING-SKY.md) track the next gameplay and device-validation work.

Try the first goal-driven sky from **Settings → Start First Light**. This starts a new round: collect **18 starlight** with steady showers and no dark stars. Replay repeats the challenge; New sky returns to survival. There is one challenge prototype, with no campaign or unlock progression.

## Open and run

Requires Xcode 16+ with an iOS 17+ simulator runtime. Open `Starfall.xcodeproj`, select shared scheme **Starfall** and an installed iPhone simulator, then Run. Simulator builds do not require paid Apple enrollment or a signing team. Device distribution/signing is not configured. This remains a prototype; App Store distribution and submission metadata require their own release work.

```sh
python3 scripts/ci-hygiene.py
swift test
xcodebuild -project Starfall.xcodeproj -scheme Starfall \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
```

The local Swift package has no external dependencies. Core tests also run on Linux with Swift 5.9+. Xcode's app scheme does not contain the package tests: run `swift test` separately.

Launch arguments (original puzzle testing):
- `--classic`: Debug-only original 70-jewel / 18-move puzzle
- `--demo`: deterministic seed 42, opens the board, does not write game saves
- `--demo --demo-clear`: deterministic seed 42 with its first legal group cleared through the real core before board presentation
- `--reset-save`: removes the previous game save before starting normally
- `--crystal-pilot`: Debug-only comparison with the original aqua pilot and procedural artwork for the other four kinds; Release ignores this argument

The character star cast is enabled by default in Debug and Release. The original crystal family remains in the Debug classic puzzle. Neither needs a new pilot flag.

## Scope

- Pure deterministic puzzle core and Codable save state
- SwiftUI falling-sky screen/settings and SpriteKit board
- Five original star-character families plus Dusk, with distinct silhouettes and landing/grown/clear expressions
- Original Debug puzzle retains offline-rendered crystals and a complete procedural fallback
- Bounded clear fragments, downward settling and diagonal refill presentation
- Optional local quiet-tuck sound and soft haptics (off by default); Calm effects honors Reduce Motion
- Match outlines and a ready-group count; bounded clear rings and a collected-score popup
- VoiceOver alternative grid with row/column, jewel name and connected-group size
- On-device falling-sky save after committed events; replay or new sky resets the round

Falling-sky artwork comes from the shared, bounded [star-cast material factory](docs/design/star-cast/README.md), used by the board, comets and preview. It is authored drawing code with a fixed cache, not a cropped concept sheet or an external dependency.

The Debug classic puzzle artwork comes from the [sealed v2 crystal handoff](Artwork/Crystals/v2/README.md) and its [manifest](Artwork/Crystals/v2/manifest.json). It is newly authored Blender geometry, material and lighting based on visual references, not recovered original source or an alpha-identical replacement. The app uses the five packaged atlases together; if any member is missing or malformed, every kind uses the existing procedural material factory. Rendering remains SpriteKit 2D with no runtime 3D or external asset service. The original aqua pilot remains a separate explicit comparison.

The package records its pre-adoption handoff state and is preserved unchanged. Runtime adoption does not establish native visual, accessibility, performance or physical-device acceptance; see [the validation record](docs/VALIDATION.md). The [audio integration record](docs/design/audio/INTEGRATION.md) separately documents the local quiet-tuck starter. No network, tracking, account, collection, lore, ad SDK or purchase SDK.

## Editions

`Config/Clean.xcconfig` supplies `STARFALL_CLEAN`; all existing configurations are clean. Monetization code, dependencies, UI and entitlements are physically absent. See `AGENTS.md` for the boundary for any future optional edition. No speculative monetization subsystem is implemented.

## Verification

See the [engineering guide and concrete debt register](docs/ENGINEERING.md) for the change/validation loop and [AGENTS.md](AGENTS.md) for repository rules. Raw CI/local output goes under ignored `artifacts/`; selected durable evidence belongs in `docs/evidence/`.

See `docs/VALIDATION.md` for exact executed checks and outstanding checks. Apple-platform compilation, simulator launch, screenshots, accessibility behavior and physical-device behavior must not be inferred from passing pure-core tests.
