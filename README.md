# Starfall

<img src="App/Assets.xcassets/AppIcon.appiconset/Starfall-1024.png" width="96" alt="Starfall icon: Spark tumbling above lavender clouds">

A small native iOS falling-sky puzzle. Clear matching stars as showers fill the board. Play at your own pace, or try **First Light**, one 18-starlight challenge. Progress stays on this device.

[Roadmap](docs/ROADMAP.md) · [Visual reference and cast](docs/design/VISUAL_REFERENCE.md) · [Playtest](docs/PLAYTEST-FALLING-SKY.md) · [Documentation map](docs/README.md)

## How to play

- **Clear a match:** Connected matching jewels must total at least 3 starlight. Normal jewels count as 1; large jewels count as 2. Clear beside a dark star to dissolve it and unblock nearby growth.
- **Control the showers:** Call the next shower yourself or clear while paused. Use the sky menu to pause or tune shower pace and dark-star frequency; Start/Resume and manual advance appear while paused.
- **Try a goal:** Choose **Sky menu → Start First Light** to start a new round with steady showers, no dark stars and an 18-starlight target. Replay repeats it; New sky returns to survival. When a survival board fills, replay or start a new sky.

New skies offer a match in the first shower. Matching colors travel together; dry boards receive a matching run in a later preview when a low column has room. The [compact HUD](docs/evidence/compact-hud-2026-10-17/README.md) keeps score/goal and the sky menu above the board, with an arrival cue instead of the exact forecast strip.

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

<details>
<summary>Debug puzzle and deterministic launch arguments</summary>

Launch arguments (original puzzle testing):
- `--classic`: Debug-only original 70-jewel / 18-move puzzle
- `--demo`: deterministic seed 42, opens the board, does not write game saves
- `--demo --demo-clear`: deterministic seed 42 with its first legal group cleared through the real core before board presentation
- `--reset-save`: removes the previous game save before starting normally
- `--crystal-pilot`: Debug-only comparison with the original aqua pilot and procedural artwork for the other four kinds; Release ignores this argument

The character star cast is enabled by default in Debug and Release. The original crystal family remains in the Debug classic puzzle. Neither needs a new pilot flag.

</details>

## Scope

[The adoption register](docs/EXPERIMENTS.md) distinguishes shipping gameplay from isolated trials. Falling sky and its physical reactions are adopted in both Debug and Release; supernova recoloring and alternate shower candidates remain outside the game.

- **Rules and saves:** Pure deterministic core, Codable state and on-device saving after committed events. Replay or New sky resets the round.
- **Native presentation:** SwiftUI screens/settings and a SpriteKit board; five expressive star families plus Dusk. The original Debug puzzle keeps its crystal artwork and procedural fallback.
- **Bounded motion:** Clear fragments, downward settling, diagonal refill, angled arrivals, weighted rebounds and survivor ripples (stronger at 5+ starlight). These present committed outcomes.
- **Feedback and accessibility:** Group outlines/count, clear rings and score popup; optional local sound/haptics off by default; Calm effects honors Reduce Motion. The VoiceOver alternative grid exposes row/column, jewel name and connected-group size.

Falling-sky artwork comes from the shared, bounded [star-cast material factory](docs/design/star-cast/README.md), used by the board and comets. It is authored drawing code with a fixed cache, not a cropped concept sheet or an external dependency.

<details>
<summary>Classic crystal artwork and audio provenance</summary>

The Debug classic puzzle artwork comes from the [sealed v2 crystal handoff](Artwork/Crystals/v2/README.md) and its [manifest](Artwork/Crystals/v2/manifest.json). It is newly authored Blender geometry, material and lighting based on visual references, not recovered original source or an alpha-identical replacement. The app uses the five packaged atlases together; if any member is missing or malformed, every kind uses the existing procedural material factory. Rendering remains SpriteKit 2D with no runtime 3D or external asset service. The original aqua pilot remains a separate explicit comparison.

The package records its pre-adoption handoff state and is preserved unchanged. Runtime adoption does not establish native visual, accessibility, performance or physical-device acceptance; see [the validation record](docs/VALIDATION.md). The [audio integration record](docs/design/audio/INTEGRATION.md) separately documents the local quiet-tuck starter. No network, tracking, account, collection, lore, ad SDK or purchase SDK.

</details>

## Product boundaries

Falling sky is the default in Debug and Release. There is one optional challenge, with no campaign or unlock progression. No power-ups, backend, accounts, analytics, ads, purchases, paid assets or external SDKs.

`Config/Clean.xcconfig` supplies `STARFALL_CLEAN`; all existing configurations are clean. Monetization code, dependencies, UI and entitlements are physically absent. See `AGENTS.md` for the boundary for any future optional edition. No speculative monetization subsystem is implemented.

## Verification

Use the [writing process and templates](docs/WRITING.md) for plans, designs, evidence reports, pull requests, and GitHub issues.

See the [engineering guide and concrete debt register](docs/ENGINEERING.md) for the change/validation loop and [AGENTS.md](AGENTS.md) for repository rules. Raw CI/local output goes under ignored `artifacts/`; selected durable evidence belongs in `docs/evidence/`.

See `docs/VALIDATION.md` for exact executed checks and outstanding checks. Apple-platform compilation, simulator launch, screenshots, accessibility behavior and physical-device behavior must not be inferred from passing pure-core tests.

The isolated [Phase Lab](docs/evidence/shower-phases-native-2026-10-17/README.md) explores preparation, a three-shower pressure burst and recovery. It does not change the default game; observed preference, phase accessibility and full-motion acceptance remain open.

A subsequent [burst exposure audit](docs/evidence/burst-exposure-2026-10-17/README.md) found the original phase often leaves arrivals unchanged under a first-clear policy. The separate [Surge Lab](docs/evidence/surge-native-2026-10-17/README.md) now makes the five-star event playable for comparison; additional choices and longer sampled survival are not adoption or enjoyment evidence.
