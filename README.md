# Starfall

<img src="App/Assets.xcassets/AppIcon.appiconset/Starfall-1024.png" width="96" alt="Starfall icon: Spark tumbling above lavender clouds">

A small native iOS falling-sky puzzle. Clear matching stars as showers fill the board. Open sky remains the default; optional 18-starlight challenges restore individual places. **First Light / Lantern Landing** and **Ribbon Crossing** are implemented, development-verified and delivered to the existing app. [Kite Harbor](docs/design/kite-harbor-03/README.md) is implemented and [development-verified](docs/evidence/kite-harbor-2026-10-19/README.md) as the third optional challenge; merge and canonical delivery are pending. Progress stays on this device.

[Roadmap](docs/ROADMAP.md) · [Visual reference and cast](docs/design/VISUAL_REFERENCE.md) · [Playtest](docs/PLAYTEST-FALLING-SKY.md) · [Documentation map](docs/README.md)

**Future story direction:** The user approved Murk, the Hungry Moon, and all twelve illustrated locations. The rewritten [game bible](docs/design/STARFALL_GAME_BIBLE.md) and [world atlas](docs/design/WORLD_ATLAS.md) develop their lore, cast and restoration journey; the [concept explorer](docs/design/world-01/index.html) holds the written state sequences. Lantern Landing and [Ribbon Crossing](docs/design/ribbon-crossing-02/README.md) are directly selectable challenges using the same seed-42 opening and 18-light rules. Kite Harbor implements the third challenge within that same boundary; the other nine locations and map traversal remain concepts, with no campaign or unlocks.

**Ribbon development verification:** All fifteen scene states have been inspected; phone win/restore/replay, cancellation, largest-text/system Reduce Motion, compact-phone play and tablet rotation/real clears pass. Runtime `dev.453e081fb5` passes 49 focused hosted checks, the compact Ribbon win/replay check and a zero-warning Release build. Its recorded normal-motion finish uses light transfer, the full-image seam join and the normal result, with no characters crossing the bridge. Merged in [PR #167](https://github.com/lbeezr/starfall/pull/167); the canonical updater verified installation of `dev.453e081fb5` from main `c40aad5` in the original app on October 19 at 16:25:49 UTC. [Source-bound evidence and installation receipt](docs/evidence/ribbon-crossing-2026-10-19/README.md) retain the separate limits for actual VoiceOver, physical play and dense-board input. Future generated travel clips are not implemented.

Help now includes optional interactive examples of squares, crosses, Opal and relays. Each button shows a real rule outcome while your sky stays paused.

[Gameplay quality](docs/GAMEPLAY_QUALITY.md) improvements are delivered across readability, consequences, pacing, discovery, reward rhythm and replay. Each verified batch was merged and delivered before the next priority; physical-play acceptance remains open.

[Gesture improvements](docs/GESTURE_QUALITY.md) are merged in five individual batches, with [canonical phone delivery evidence](docs/evidence/gesture-delivery-2026-10-18/README.md). Physical-play acceptance and [mechanics calibration](docs/design/CALIBRATION.md) continue.

Score popups and celebration titles use the [crystal-depth alphabet](Artwork/CrystalComet/NATIVE.md), with brief letter turns, static quiet modes and native accessible text.

**Lantern Landing is implemented, merged and delivered:** First Light restores the approved dock through five states as you collect its existing 18-starlight goal. Bespoke phone and tablet scenes preserve continuous artwork; collected light reaches the lantern before the ending, saved progress restores directly, and replay begins dark. [Native evidence](docs/evidence/lantern-landing-2026-10-19/README.md) covers source `8fb2e78`, runtime `dev.5afe4a3c23`. Merged in [PR #154](https://github.com/lbeezr/starfall/pull/154); the canonical updater verified installation of `dev.5afe4a3c23` from main `ab868b5` in the original `com.starfall.prototype` app on October 19 at 14:53:57 UTC. Physical play and actual VoiceOver at RC remain separate acceptance. [Production scope and remaining checks](docs/design/lantern-landing-01/PRODUCTION_PLAN.md).

**Five layered nightscapes are integrated:** Moonwake, Nebula Cradle, Shatterlight Reach, Night Garden and Ringdrift. Gameplay stays centered while independent scenery fills the margins. Choose **Menu → Location** without changing the round. [Production art and contract](docs/design/environments/night-production-09/README.md) · [Native verification and delivery](docs/evidence/nightscapes-2026-10-18/README.md).

Player wording and character voices are authored in the [local copy catalogue](App/DialogueScripts/README.md), with typed interface keys, validated templates and an in-app dialogue preview.

## How to play

- **Clear a match:** Horizontally or vertically connected matching jewels must total at least 3 starlight. Normal jewels count as 1; large jewels with a luminous double silhouette and paired glints count as 2. Their soft aura gently pulses in normal motion. In retained Dusk rounds, clear beside Dusk to dissolve it early; gray neighbors still match and grow, but score zero until released.
- **Keep playing:** Ready groups stay interactive while other columns settle. One recent tap or swap can wait briefly for its stars, with a visible outline/arrow acknowledgment. A new touch replaces that intention; changed boards and interruptions cancel it. Short ordinary finger drift stays a tap.
- **Draw a constellation:** Hold a star until it glows, then draw through five or more matching stars, beside one another or across one empty space in a straight line, including diagonals, then lift. Only the stars you traced clear; retrace to branch. Drawing holds the next shower until release or cancellation.
- **Arrange a setup:** In survival, swipe left, right, up or down to exchange neighbors immediately. Each touch moves one space regardless of color. Stars exchanged into space fall normally. Hold then trace exact four-star squares or five-star crosses; surrounding stars stay. Build the next recipe, then clear again for a deliberate relay. [Techniques](docs/design/STAR_TECHNIQUES.md).
- **Understand the sky:** Characters explain play, storm counts and timing warnings in one bottom chat. Tap the retained portrait to reread a message. Six conversation portraits and bundled scripts share one reusable presentation; [edit or preview dialogue](App/DialogueScripts/README.md).
- **Control the showers:** Call the next shower yourself or clear while paused. Use the sky menu to pause or tune shower pace (retained Dusk rounds also keep dark-star frequency); Start/Resume and manual advance appear while paused.
- **Try a goal:** Choose **Try First Light** to revive Lantern Landing, **Try Ribbon Crossing** to reconnect its stitched path, or **Try Kite Harbor** to raise its sails. All three use the same opening, steady showers, no dark stars and an 18-starlight target; replay keeps the selected challenge, while New sky returns to survival. When an arrival column has no room, replay or start a new sky.

[Starlight celebrations](docs/design/STARLIGHT_CELEBRATIONS.md) connect committed clear awards to the total with harvested-family light, award-scaled strength and [Crystal Comet lettering](docs/evidence/crystal-comet-integration-2026-10-18/README.md) for major clears, recipes, constellations and causal relays. The user-approved [opalescent material refinement](docs/design/celebration-lettering/crystal-comet-01/OPALESCENCE.md) restores warm/cool facet light from the approved swatches. [Protected award placement](docs/evidence/board-clarity-2026-10-18/README.md) keeps lettering above playable rows, with readable compact/native fallbacks. Scoring and ready-column input stay unchanged; [native award captures](docs/evidence/starlight-celebrations-2026-10-18/VISIBLE_AWARDS.md) verify sampled visibility and record acceptance limits.

New skies start empty, then open with four closely spaced animated showers. Clear between waves as they settle; the fresh-survival rhythm then repeats six showers at three seconds, three at 2.5 seconds, and three at 3.5 seconds to leave room for input. The faster passage is announced in advance. Saved skies and same-sky replay keep their original cadence; First Light keeps its fixed cadence. [Pacing calibration](docs/evidence/calibration-critical-mass-2026-10-18/ADOPTION.md) records the decision and its limits. At the gentle/steady settings, showers retain the selected fixed interval. New skies offer a match in the first shower. Matching colors travel together; dry boards receive a matching run in a later preview when a low column has room. The [compact HUD](docs/evidence/compact-hud-2026-10-17/README.md) keeps score/goal and the sky menu above the board, with an arrival cue instead of the exact forecast strip.

New survival skies also use the approved [Opal and storm rules](docs/design/WHITE_STAR_AND_STORMS.md): a white Opal Orb can join the colored family you start on, and nine lighter showers alternate with three heavy showers. Clearing spends any included Opal; she is worth one light and never grows. Density and timing cues describe separate parts of the forecast. Older saved skies and replays keep their generation; First Light excludes both mechanics. [Integration evidence](docs/evidence/opal-main-integration-2026-10-17/README.md) distinguishes tested behavior from human enjoyment, which remains unmeasured.

Automatic star aging, purple pressure warnings and implosions are disabled in fresh survival and restored critical-mass rounds. Matching growth still counts as two starlight; score, committed preview and saved cadence are preserved. Dusk remains pocketed in these skies. Historical Dusk rounds retain their rules. [Change and verification](docs/evidence/aging-disabled-2026-10-18/README.md).


Attraction fields and orbiting holes are removed from normal play. Saved rounds keep their score and remaining stars; held stars settle and upcoming fields become ordinary stars. Replay also stays free of gravity specials. [Removal and save compatibility](docs/evidence/gravity-removal-2026-10-17/README.md).

The [sky flow](docs/design/SKY_FLOW.md) opens with Welcome/Continue, stages choices until Begin at Entry, and gives First Light wins and full skies their own endings. Cast stars settle while actions emerge; Calm effects and Reduce Motion show the settled screen. Back at Entry retains the previous saved sky. Continue preserves an intentional pause; restored rounds reopen paused. Another sky always waits for your choice. Settings/help describe the selected round before play; results retain the final stars and explain the blocked column. Replay entry explains the starting sky and keeps the saved round until Begin. Save problems show a native notice while preserving the previous save or rejected recovery copy. [Verified presentation batches and remaining device/RC checks](docs/evidence/screen-flow-polish-2026-10-17/README.md).


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

New installations start in **Moonwake**. Existing location preferences map to the five nightscapes; the score, stars and saved round are preserved. The scenery has no gameplay touch targets. Compact screens and accessibility text use a scrolling layout with the same seven-column coordinate mapping.

Requested improvements go directly into regular Starfall. Build the shared scheme and update the existing installation; create no separate lab unless explicitly requested. Historical trials remain in the [adoption register](docs/EXPERIMENTS.md). [Current drawing, full-window and cadence fixes](docs/evidence/main-polish-2026-10-17/README.md) record tests and remaining physical/RC checks.

The selected [nightscape art direction](docs/design/environments/night-production-09/README.md) supplies five destinations in the regular app. No unlock progression or alternate player route is added.

The [shower forecast](docs/evidence/shower-forecast-adoption-2026-10-17/README.md) follows the upper camera contour on the calibrated iPhone 17 and iPhone 16 Pro Max portrait layouts. Other iPhones, tablets and accessible layouts show the same ordered incoming stars along a straight header trail. Physical camera fit remains unverified.

Dusk now feeds toward a zero-point neighborhood collapse; Opal still joins a color. The former gravity setup is retired; historical generation readers and reset-only Debug histories remain for save compatibility and regression testing.

[Input centralization](docs/evidence/interaction-centralization-2026-10-18/README.md) gives logical contacts, availability, interruption teardown and device feedback small shared owners.

[Scoped reliability hardening](docs/design/RELIABILITY_POLISH.md) gives drawing explicit hold ownership, fingerprints package build inputs, and verifies camera layout against the full local canvas. Remaining physical/RC checks stay separate from development integration.

Phone delivery now verifies the actual installation and rejects stale main history. [Delivery guards and their limits](docs/evidence/device-delivery-guards-2026-10-18/README.md) record the active service and checks.

The score/menu and dialogue now occupy [physical recesses in each environment](docs/design/environments/BOARD_TEMPLATE.md). Portrait uses a front apron; landscape uses a connected wing. Separate scenery fills extra space, while larger text scrolls with full-size controls. [Current implementation evidence](docs/evidence/environment-grooves-2026-10-18/README.md) separates native checks from remaining device/RC acceptance.
[Active technical debt and RC blockers](docs/ENGINEERING.md#active-debt-and-next-actions--october-18-2026) distinguish current risks from the historical record; [seven independent shipping tasks](docs/TECH_DEBT_PLAN.md) link their verification.
