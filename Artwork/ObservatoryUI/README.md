# Observatory Instruments UI kit

**Status:** Source kit export-verified; native family adopted for development · **Source kit:** `cfd6ab7` · **Date:** October 19, 2026

A reusable Starfall interface family: three illustrated mode emblems, shared enamel/brass skins, and twenty dedicated utility glyphs. The source kit supports the accepted [game UI direction](../../docs/design/GAME_UI_SYSTEM.md). The [screen atlas](../../docs/design/interface/atlas-2026-10-19/README.md) remains the proposed composition reference.

The user authorized asset production and then integration into the normal native app. [StarfallTheme](../../App/StarfallTheme.swift) and [ObservatoryArtwork](../../App/ObservatoryArtwork.swift) now use this family across the scenic home, gameplay controls, reading surfaces and settings. The family is adopted for development. Exact coverage and canonical delivery status are recorded in the [native evidence](../../docs/evidence/observatory-ui-native-2026-10-19/README.md); the [capture index](../../docs/evidence/observatory-ui-native-2026-10-19/captures.json) identifies inspected appearances separately from source/export work. Rules, saves and progression retain their existing owners.

## Review the actual assets

[Open the asset specimen](review.html) to inspect the exported art with real labels, component states and stretch examples. This is a local browser specimen, not an iOS build. Its type is a specimen choice, not a newly produced display font.

![Actual exported emblems and skins, assembled at several sizes](previews/rasters.png)

*Export review sheet, not an app screenshot. The button keeps fixed ornamental ends; tall surfaces use the panel skin.*

![Dedicated SVG glyph family at small sizes on dark and light surfaces](previews/glyphs.png)

*Authored utility glyphs and export comparison. Display zoom affects apparent size; native device acceptance remains separate.*

## Contents

| Entry | Purpose |
| --- | --- |
| [Integration contract](INTEGRATION.md) | Native ownership, measured geometry, state composition, scalable labels and adoption gates |
| [Native resource catalog](../../App/Assets.xcassets/ObservatoryUI) | Twenty template vector PDFs and six illustrated image sets, preserving original point registration |
| [Generation record](PROMPTS.json) | Exact built-in ImageGen prompts, reference, original paths and source hashes |
| `masters/illustrations/` | Unchanged transparent Story lantern, Free Play comet and Tutorial constellation sources |
| `masters/skins/` | Unchanged blank action, reading-panel and utility-bezel sources |
| `masters/glyphs/` | Twenty standalone, editable 24-unit SVG masters |
| `exports/` | 60 utility PNGs, 20 vector PDFs and 18 emblem/skin PNGs at 1×/2×/3× |
| [Glyph manifest](glyph-manifest.json) / [raster manifest](raster-manifest.json) | Exact hashes, dimensions, alpha bounds, caps, content regions and checks |
| [Glyph exporter](build/README.md) / [raster exporter](build_rasters.mjs) | Deterministic offline regeneration with existing local dependencies |
| `previews/` | Review sheets; never runtime textures |

Source generation and deterministic export are separate steps. Never derive runtime assets by slicing a screenshot or the atlas boards. Keep originals unchanged and produce a new source version for an art revision.

## Use the family consistently

- **Mode emblems:** Home and major destinations, normally 40 points and at most 48. Use their simpler utility glyphs during play. Do not stretch an emblem or bake its label into it.
- **Action skin:** Fixed-height ornamental ends with a flexible middle. Primary, secondary and mode actions share one geometry. The compact role scales the entire artwork consistently before horizontal stretching; tall multiline actions use the reading-panel skin so side ornaments do not distort.
- **Reading panel:** Fixed corners, stretchable edge strips and center. Header, divider, portrait, controls and text remain independent.
- **Utility bezel:** Optional small fitting around a separate glyph. Its visible dimensions never shrink the native target; current gameplay controls retain their 45-point minimum.
- **States:** Apply registered material overlays, separate native ink and stable focus/selection marks. Do not generate a different silhouette for every button state. Disabled state must preserve labels and the selected value while preventing activation.

The native control remains the semantic and input owner. Decorative layers ignore hit testing and accessibility. Existing preferences govern sound, haptics and calm effects; system accessibility adaptations do not add new game preferences.

## Native ownership and import

`ObservatoryIcon` renders the dedicated utility family; `ObservatoryEmblem` and `ObservatoryModeLabel` compose the three home destinations with native text. `StarfallButtonStyle` retains its semantic roles and uses measured action geometry; tall labels reflow into the reading-panel skin. Compact `starfallPanel` notices remain small native surfaces, while `observatoryReadingPanel` applies the registered 32-point fittings. `StarfallGameButtonStyle` keeps 45-point targets. `ObservatoryToggleStyle` provides visible position/check cues with a native switch accessibility representation.

Display and action labels use scalable native serif roles in `StarfallTheme`; body copy uses native functional text. No new font or font registration is included. Pearl ink is separate from artwork, and exact HUD digits remain native. Crystal Comet retains its existing celebration-only renderer and fallback contract.

The app imports the twenty PDF derivatives as template images with preserved vector representation, and all eighteen illustrated PNG density files as original-color images. The SVG masters and sixty glyph PNG exports remain source-kit assets. The app catalog contains 814,454 encoded payload bytes; six 3× raster selections represent 1,944,576 decoded RGBA bytes before renderer copies or GPU storage. These are roster measurements, not a process-memory profile.

Source/export manifests describe the retained artwork and its export verification. Native `Contents.json` files describe app names, density, rendering intent and vector preservation; `ObservatorySkin` owns native point sizes and cap insets. Import metadata does not rewrite source provenance or historical export acceptance. [Hosted resource checks](../../AppTests/ObservatoryArtworkTests.swift) exercise the compiled catalog and large-text action layout; their native results belong to the integration evidence, not the export manifests.

## Provenance and boundaries

The six illustrated sources were created with built-in ImageGen for this project, using the accepted observatory concept as a material reference. The SVG family was authored for Starfall from the prior project-owned glyph study and refined for small display. No third-party asset pack, icon library, purchased artwork or runtime dependency was added. This record identifies sources; it does not make a separate legal ownership or exclusivity claim.

The optional `game-dev` CLI was unavailable. The host image generator and available local export tools produced this 2D source kit. This is not a `game-dev` canonical-package receipt. App asset-catalog membership is implemented. The [native integration record](../../docs/evidence/observatory-ui-native-2026-10-19/README.md) reports loading, interaction, inspected appearance and sampled motion independently; physical-device reading, performance and full VoiceOver retain their release-candidate acceptance boundaries.

Final measurements, reproducible export commands and verification results are recorded by the manifests and the linked integration handoff. Review sheets demonstrate the asset composition; they do not establish native game quality or performance.

## Rebuild and verification

Run from the repository root, using already installed Python/Node dependencies:

```sh
python3 Artwork/ObservatoryUI/build/glyphs.py --node /path/to/node --node-modules /path/to/node_modules
node Artwork/ObservatoryUI/build_rasters.mjs --node-modules /path/to/node_modules
```

The raster exporter accepts only the registered 1×/2×/3× set and checks all inputs before writing output. The [source-bound verification record](../../docs/evidence/observatory-ui-kit-2026-10-19/README.md) records the exact tested environment and commands, byte-identical regeneration, rejected malformed inputs, browser behavior and native acceptance limits.
