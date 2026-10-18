# Starfall

<img src="App/Assets.xcassets/AppIcon.appiconset/Starfall-1024.png" width="96" alt="Starfall icon: Spark tumbling above lavender clouds">

A small native iOS falling-sky puzzle. Clear matching stars as showers fill the board. Play at your own pace, or try **First Light**, one 18-starlight challenge. Progress stays on this device.

[Roadmap](docs/ROADMAP.md) · [Visual reference and cast](docs/design/VISUAL_REFERENCE.md) · [Playtest](docs/PLAYTEST-FALLING-SKY.md) · [Documentation map](docs/README.md)

## How to play

- **Clear a match:** Horizontally or vertically connected matching jewels must total at least 3 starlight. Normal jewels count as 1; large jewels count as 2. Clear beside a dark star to dissolve it and unblock nearby growth.
- **Keep playing:** Ready groups stay interactive while other columns settle. A contact outline acknowledges touch; changing columns briefly wait, and short ordinary finger drift stays a tap.
- **Draw a constellation:** Swipe through five or more neighboring matching stars, including diagonals, then lift. Only the stars you traced clear; retrace to branch. Drawing holds the next shower until release or cancellation.
- **Understand the sky:** Characters explain play, storm counts and timing warnings in one bottom chat. Tap the retained portrait to reread a message. Six conversation portraits and bundled scripts share one reusable presentation; [edit or preview dialogue](App/DialogueScripts/README.md).
- **Control the showers:** Call the next shower yourself or clear while paused. Use the sky menu to pause or tune shower pace and dark-star frequency; Start/Resume and manual advance appear while paused.
- **Try a goal:** Choose **Sky menu → Start First Light** to start a new round with steady showers, no dark stars and an 18-starlight target. Replay repeats it; New sky returns to survival. When a survival board fills, replay or start a new sky.

New skies start empty, then open with four closely spaced animated showers. Clear between waves as they settle; the default rhythm then repeats six showers at two seconds, three at 1.7 seconds, and three at 2.5 seconds. The faster passage is announced in advance. Saved older skies and First Light keep their original cadence. At the gentle/steady settings, showers retain the selected fixed interval. New skies offer a match in the first shower. Matching colors travel together; dry boards receive a matching run in a later preview when a low column has room. The [compact HUD](docs/evidence/compact-hud-2026-10-17/README.md) keeps score/goal and the sky menu above the board, with an arrival cue instead of the exact forecast strip.

New survival skies also use the approved [Opal and storm rules](docs/design/WHITE_STAR_AND_STORMS.md): a white Opal Orb can join the colored family you start on, and nine lighter showers alternate with three heavy showers. Clearing spends any included Opal; she is worth one light and never grows. Density and timing cues describe separate parts of the forecast. Older saved skies and replays keep their generation; First Light excludes both mechanics. [Integration evidence](docs/evidence/opal-main-integration-2026-10-17/README.md) distinguishes tested behavior from human enjoyment, which remains unmeasured.

The [sky flow](docs/design/SKY_FLOW.md) opens with Welcome/Continue, stages choices until Begin at Entry, and gives First Light wins and full skies their own endings. Cast stars settle while actions emerge; Calm effects and Reduce Motion show the settled screen. Back at Entry retains the previous saved sky. Continue preserves an intentional pause; restored rounds reopen paused. Another sky always waits for your choice. Settings/help are available before play; results retain the final stars and explain the blocked column. [Verified presentation batches and remaining device/RC checks](docs/evidence/screen-flow-polish-2026-10-17/README.md).


[Automatic connected-iPhone updates](scripts/README.md#one-app-iphone-updates) keep one regular Starfall installation and its saved round.

## Open and run

Requires Xcode 16+ with an iOS 17+ simulator runtime. Open `Starfall.xcodeproj`, select shared scheme **Starfall** and an installed iPhone simulator, then Run. Simulator builds do not require paid Apple enrollment or a signing team. Local development signing has been exercised on a connected iPhone; choose your own Personal Team in Xcode. Distribution signing is not configured. This remains a prototype; App Store distribution and submission metadata require their own release work.

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
- **Bounded motion:** Clear fragments, downward settling, diagonal refill, angled arrivals, weighted rebounds and survivor ripples (stronger at 5+ starlight). These present committed outcomes. [Connected contact](docs/evidence/star-contact-2026-10-17/README.md) adds local weight transfer, brief neighbor looks, surface light and a quiet resting sky.
- **Feedback and accessibility:** A luminous drawn thread, brief star sparks and score popup; local sound/haptics on for new preferences (saved off is preserved; sound respects Silent Mode); Calm effects honors Reduce Motion. The VoiceOver alternative grid exposes row/column, jewel name and connected-group size.

Falling-sky artwork comes from the shared, bounded [star-cast material factory](docs/design/star-cast/README.md), used by the board, comets and HUD. It combines packaged Crystal Glow cutouts with authored expressive faces in a fixed cache; no external runtime dependency is needed.

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

Default play takes place in **Moonlit Observatory**: full-screen cosmic scenery, an angled terrace, gently drifting fog and a telescope/lantern that respond to taps. The earlier palette picker is retired; saved rounds and shower rules stay the same. [Integration evidence and remaining device/accessibility limits](docs/evidence/observatory-adoption-2026-10-17/README.md).

Requested improvements go directly into regular Starfall. Build the shared scheme and update the existing installation; create no separate lab unless explicitly requested. Historical trials remain in the [adoption register](docs/EXPERIMENTS.md). [Current drawing, full-window and cadence fixes](docs/evidence/main-polish-2026-10-17/README.md) record tests and remaining physical/RC checks.

The selected [environment art direction](docs/design/environments/PRODUCTION.md) develops five living landing places. Finish Moonlit Observatory before Cloudsea; there is no parallel player route.

The [shower forecast](docs/evidence/shower-forecast-adoption-2026-10-17/README.md) follows the upper camera contour on the calibrated iPhone 17 and iPhone 16 Pro Max portrait layouts. Other iPhones, tablets and accessible layouts show the same ordered incoming stars along a straight header trail. Physical camera fit remains unverified.

New skies include paired attraction fields that can converge into temporary orbiting holes. Clear their middle to collide, use the rotating colored captives in matches, and clear a captive to release the field. Dusk still blocks growth; Opal still joins a color. Existing saved skies and their replays retain their original rules. See [the gravity design](docs/design/GRAVITY_MECHANICS.md) and [integration evidence](docs/evidence/gravity-integration-2026-10-17/README.md).

[Scoped reliability hardening](docs/design/RELIABILITY_POLISH.md) gives drawing explicit hold ownership, fingerprints package build inputs, and verifies camera layout against the full local canvas. Remaining physical/RC checks stay separate from development integration.
