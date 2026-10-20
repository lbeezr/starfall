# Observatory UI production handoff

**Status:** Native import and shared components adopted for development · **Source kit:** `cfd6ab7` · **Owner:** Current implementer · **Updated:** October 19, 2026

The native app uses three mode emblems, one shared action skin, one reading-panel skin and one compact utility bezel. Labels, interaction states and accessibility remain native. Primary, secondary and mode actions share the same button geometry and source bitmap. The [game UI system](../../docs/design/GAME_UI_SYSTEM.md) owns art direction and screen migration. The [atlas](../../docs/design/interface/atlas-2026-10-19/README.md) is a concept reference, not a source of sliced runtime artwork.

The [raster manifest](raster-manifest.json) records actual source/export bounds, registration, hashes and slice regions. The [glyph manifest](glyph-manifest.json) records vector and template exports. These retain source/export status at production time; native import does not rewrite them. The registered action skin uses a wide source with fixed-height end fittings, so it stretches horizontally only. Native integration adds no font registration, preference keys or runtime dependency.

## Keep the existing native owners

| Concern | Existing owner | Handoff boundary |
| --- | --- | --- |
| Color, material, type, spacing and control roles | [StarfallTheme](../../App/StarfallTheme.swift) | Native serif display/action roles, pearl ink and enamel/brass colors; avoid screen-local style copies. |
| Primary, secondary, quiet and ceremony actions | `StarfallButtonStyle` in `StarfallTheme`; `ObservatoryActionLayout` | Native `Button`, measured wrapping labels, enabled/focus semantics and full hit shape. One measured skin plus native material state changes. |
| Glyphs, mode emblems and artwork registration | [ObservatoryArtwork](../../App/ObservatoryArtwork.swift) | `ObservatoryIcon`, `ObservatoryEmblem`, `ObservatoryModeLabel`, `ObservatorySkin` and passive `ObservatorySurface`; no game state or runtime SVG parsing. |
| Small gameplay actions | `StarfallGameButtonStyle` in `StarfallTheme` | Preserve the existing 45-point minimum target. A 20–24-point glyph or 32-point bezel does not shrink it. |
| Passive reading surface | `StarfallPanelStyle` / `starfallPanel`; `observatoryReadingPanel` | Small native notices retain compact insets; full reading surfaces use the registered 32-point fittings. Neither owns input, accessibility grouping or clipping of content. |
| Sound, Haptics and Calm effects | [SkyPreferences](../../App/SkyPreferences.swift), `SkyPreferenceToggle`, `SkyFeelSection`; `ObservatoryToggleStyle` | Existing bindings, native switch accessibility representation, thumb position/check cues and large-text reflow; no preference keys added. |
| Score, next shower and pause | [FallingSkyHUD](../../App/FallingSkyHUD.swift), `SkyShowerTrail` | Keep exact values, existing countdown and forecast ownership. Skins never schedule or commit gameplay. |
| Message content and lifetime | `SkyDialogueOverlay`, `SkyDialogueBubble`, dialogue catalog | Keep dismissal, focus and cancellation ownership. A panel is only its visual surface. |

Chrome anchors to the root viewport's safe edges. `LandingGeometry` continues to own the shared board, hit-cell and accessibility-cell projection. Asset proportions never determine gameplay geometry. Any projection change belongs to a separate native verification step.

## Native catalog contract

`App/Assets.xcassets/ObservatoryUI` contains 26 image sets: twenty `ObservatoryGlyph…` PDF templates with `preserves-vector-representation`, and six original-color `ObservatoryEmblem…` / `ObservatoryButtonAction` / `ObservatoryPanelReading` / `ObservatoryUtilityBezel` sets with explicit 1×, 2× and 3× PNG entries. Each imported payload is byte-identical to its kit export. SVG masters and glyph PNG alternatives are not copied into the app.

Catalog `Contents.json` owns native names, density, template intent and vector preservation. `ObservatorySkin` owns point sizes and cap insets. Kit manifests own source/export identity and measurements; they do not describe compiled asset-catalog output or establish native acceptance. Artwork changes require new exports and registration checks before catalog replacement. Metadata-only app changes do not alter the original manifests or historical export evidence.

The imported payload is 814,454 encoded bytes: 31,579 bytes of vector PDFs and 782,875 bytes of raster PNGs. Catalog JSON brings the source catalog to 822,467 bytes. Compiled catalog size, process memory and GPU storage require native measurement.

## Asset roster and point-space registration

Use stable semantic IDs below, with separate source and export records. Original source bytes and provenance are retained. Exported PNGs use RGBA, sRGB, transparent outer edges and no matte. Each role has 1×, 2× and 3× exports; the table gives 3×. Native catalog registration preserves those scales. Do not treat the pixel width as the point width.

| ID | Purpose and composition | Registered 3× canvas | Intended native presentation |
| --- | --- | --- | --- |
| `emblem-story` | Lantern with restrained warm crystal light; no label or surrounding medallion | 144 × 144 px / 48 × 48 pt | Home at 40 pt; 48 pt maximum. Aspect fit, never nine-slice. |
| `emblem-freeplay` | Comet with a clear head and restrained trail; no label or surrounding medallion | 144 × 144 px / 48 × 48 pt | Same box and optical weight as Story; preserve the directional silhouette. |
| `emblem-tutorial` | Connected constellation with a recognizable learning/discovery silhouette; no label or surrounding medallion | 144 × 144 px / 48 × 48 pt | Same box and optical weight as Story. Avoid tiny details needed to identify the action. |
| `button-action` | Midnight enamel, fine brass, fixed corner/end fittings, uninterrupted label area | 960 × 192 px / 320 × 64 pt | Shared primary, secondary and mode skin; horizontal stretch at fixed height. |
| `panel-reading` | Quiet enamel field, thin edge, corner-only fittings; no header, divider, portrait or close button baked in | 480 × 480 px / 160 × 160 pt | Pause, settings and reading surfaces; nine-slice in both axes. |
| `utility-bezel` | Small simple rim with quiet center; no action glyph baked in | 96 × 96 px / 32 × 32 pt | Optional 32-point fitting around a 20-point glyph inside a full target; aspect fit, never nine-slice. Unframed utilities can use 24-point glyphs. |

The three emblem labels remain `Story Mode`, `Free Play` and `Tutorial` in native text. Their utility equivalents come from the dedicated SVG family. Use emblems for major destinations and simple glyphs during play. Keep existing world art, wordmark, cast and Crystal Comet under their current owners; this package does not replace them.

The six 3× raster exports total 1,944,576 decoded RGBA bytes (about 1.85 MiB). All eighteen density exports total 3,024,896 decoded bytes (about 2.88 MiB), before renderer copies or GPU storage. The manifests record encoded sizes. These are calculable pixel-roster costs, not measured process memory.

## Nine-slice and content boundaries

Coordinates use a top-left origin with exclusive right/bottom bounds. Insets apply to the complete transparent canvas, including outer padding. Sources are fitted proportionally before measuring; no generated source is stretched anisotropically to force these numbers.

| Skin | Fixed caps, top / leading / bottom / trailing | Stretch region in 3× export pixels | Content clearance |
| --- | --- | --- | --- |
| Button | 0 / 48 / 0 / 48 pt; 0 / 144 / 0 / 144 px | `[144, 0, 816, 192)`; horizontal only | Labels inset 52 pt horizontally and 16 pt vertically; an emblem has its own reserved column and gap. |
| Panel | 32 pt each side; 96 px each side | `[96, 96, 384, 384)` | 32 pt around reading content, adjusted only after inspecting actual fitting clearance. |

The registered caps preserve the generated fittings. Stretch specimens exercise them separately from text layout. Re-measure after any source revision; do not silently retain old insets. A center with a distinctive highlight, star, seam or focal texture is unsuitable for stretching.

The reading panel uses nine-slice: corners stay fixed, top/bottom strips stretch horizontally, side strips stretch vertically, and the plain center stretches in both axes. The action skin uses full-height fixed ends and a horizontally stretched middle. Its side diamonds must never stretch vertically. Content bounds are independent of alpha bounds, and touch bounds are independent of both.

The action's two fixed ends occupy 96 pt; the registered geometric floor is 120 × 64 pt before labels are considered. A compact action scales the entire 64-point artwork uniformly to 52 points, then stretches horizontally, preserving the scaled endcaps. Use at least 98 × 52 pt for that compact geometry, and more whenever text requires it. A tall or multiline action uses the reading-panel skin and grows with its content. The panel's registered geometric floor is 80 × 80 pt, while usable reading layouts require measured text plus the 32-point content insets. Do not shrink text to make a skin fit.

`ObservatoryActionLayout` measures the native label and selects a 52- or 64-point action height; labels exceeding that envelope are remeasured with the reading panel's 32-point insets on every side. Mode emblems and titles stack vertically at accessibility text sizes. Geometry does not change between rest, press and disabled states.

Every export has transparent outer padding; actual nonzero-alpha and alpha≥128 body boxes are recorded separately. The source crop uses alpha≥2 plus two source pixels. Only detached alpha=1 noise outside that crop is omitted; counts are recorded and source masters remain unchanged. Review over midnight, bright clouds and checkerboard, including the actual-size brass edge. The intended brass face is approximately 1 pt with localized highlights; source glow is not a rim measurement.

## State production: fixed art, native response

Keep one rest master per visual object. Independently generated pressed, selected or disabled images often alter corners, lighting, alignment or crop. Those differences would make controls move when their state changes. State treatment therefore uses native color/material overlays and stable geometry; a derived mask, if required, must share the exact canvas, crop, scale and registration of its source.

| State or role | Native treatment | Required invariant |
| --- | --- | --- |
| Primary / mode rest | Shared enamel/brass master with crisp pearl label; richer emblem only on mode actions | Fixed canvas, content alignment and target. No continuous shine. |
| Secondary rest | Same registered master with a modest native brightness reduction behind the separate pearl label | No different silhouette or independent source generation. Label contrast is not reduced with the artwork. |
| Quiet / gameplay utility | Native glyph; minimal backing only where needed for contrast, optionally the utility bezel | Do not wrap every HUD action in the home button skin. Full target stays intact. |
| Pressed | Immediate face darkening or subtle inset highlight; optional bounded light response | No target movement, label re-layout or geometry swap. Navigation is never delayed for decoration. |
| Selected, where meaningful | Stable selection mark plus stronger edge/ink emphasis | Selection remains distinguishable in grayscale and without glow; a press is not selection. |
| Disabled | Subdued native ink/rim and no activation response; retain the meaningful label and selected value if present | Native disabled semantics prevent activation. Do not dim the entire component until its label disappears. |
| Focused | Native focus behavior plus a clear exterior focus stroke if needed | Focus does not change content bounds and is not clipped by the skin. Preserve accessibility focus. |
| Toggle on / off | Native value/semantics with a distinct position or check/shape cue and readable label | No color-only state. Preserve whole-row large-text fallback and existing bindings. |
| Increased contrast / reduced transparency | Opaque native backing and stronger readable ink/edge | Same meaning, hit target and hierarchy; no new user preference. |
| Calm effects / Reduce Motion | Settled material and immediate state changes; omit decorative movement | Honor existing settings/system state; preserve committed outcomes and inputs. |

Compose states predictably: disabled suppresses press/activation; selected meaning remains visible; focus adds a non-layout-changing indicator. Review selected+pressed, selected+disabled and focused+selected as well as isolated states. Utility labels and toggle state descriptions remain native. Decorative raster layers are hidden from accessibility and ignore hit testing.

Any temporary visual face displacement must remain within a fixed target and content allocation. Start with material-only pressing in the specimen; add motion only if actual native review demonstrates an improvement. Existing sound/haptic owners remain authoritative and must not emit twice for a single action. Do not introduce a shader, audio engine, runtime SVG parser or texture generator for this handoff.

## Scalable labels and glyphs

All readable button, panel and preference labels stay separate from painted skins. `StarfallTheme.Typography` uses native scalable serif display, heading and action roles, with functional body text and exact native digits. No custom font is registered. A new display face remains a separate font-production decision; a generated letter sheet is not a usable font. Preserve semantic scaling, wrapping, punctuation and supported-character fallback. Never outline whole labels into SVG merely to reproduce a mock.

The dedicated glyph masters use a consistent 24-unit viewbox. Native utility display is 20–24 pt, with at least a 44 × 44 pt target; current gameplay controls retain 45 × 45 pt. Prefer an Xcode-supported, verified vector rendition without adding a runtime parser. Keep the source glyph and all derived exports registered to the same optical center. Symbols alone do not carry accessibility names: the native control supplies a meaningful action label and value when relevant.

Pearl display text must remain legible with its halo removed. HUD numbers use exact native values and stable digit widths. Body/explanation text uses the clear functional face. Crystal Comet remains the finite celebration voice with its [existing fallback contract](../CrystalComet/NATIVE.md); its raster alphabet is not a menu-font substitute. Proposed ordinary essential-text contrast is at least 4.5:1 against the worst actual backdrop behind the glyphs, including translucent surfaces composited over bright scenery.

## Manifest and review deliverables

For every retained master/export, record: semantic ID; purpose; source path and SHA-256; prompt/provenance; export path and SHA-256; pixel dimensions; scale; color mode/profile; encoded bytes; decoded RGBA roster bytes; nonzero-alpha/body bounds; optical anchor; intended point range; fixed caps and stretch rect if applicable; content insets; and validation status. Mark unavailable measurements as pending. Do not silently substitute proposed values for observed measurements.

Keep a source-to-export recipe so resizing, padding and metadata can be reproduced. Preserve source aspect ratio and alpha; do not hand-crop individual states. Derived masks or density exports require their own hashes and registration. The parent package README owns the roster and links this handoff. Production acceptance requires these records, not just attractive standalone PNGs.

The existing [art-quality tools](../../tools/art-quality/README.md) validate specific crystal catalogs/atlases. They do **not** validate arbitrary Observatory UI PNGs, nine-slice caps or SVGs. Their passing results cannot certify this package. Use bounded offline inspection for the new roster and retain small reports; no new dependency is necessary. Native `UIImage`/asset-catalog loading is checked independently by the [hosted resource tests](../../AppTests/ObservatoryArtworkTests.swift), with results recorded in the [native evidence](../../docs/evidence/observatory-ui-native-2026-10-19/README.md).

## Acceptance and regression criteria

| Check | Required result and evidence |
| --- | --- |
| Roster/provenance | Exactly the declared six raster roles plus the separately declared glyph family; all files decode; source/export hashes match; no baked labels, screenshots or unexplained state variants. |
| Registration | Manifest pixel dimensions and 3× point interpretation match each export; alpha padding and optical anchors are recorded; all masks/derived variants share registration. |
| Stretch | Render compact button at 120 × 52 pt, fixed-height action at 160 × 64, 240 × 64 and 320 × 64 pt; tall action uses panel-reading at 320 × 100 pt. Render panel at 160 × 160, 320 × 240 and 480 × 400 pt. Corners keep their shape/scale, fittings are never sliced, and edges show no gaps, seams or focal texture stretching. |
| Content | `Story Mode`, `Free Play`, `Tutorial`, `Settings`, `Resume`, a two-line long label, and exact `18 / 18` and `1,024` samples fit without touching fittings. Larger text grows/reflows controls; no clipping or forced shrinking. |
| Silhouette/scale | Emblems remain distinguishable at 40 and 48 pt; utility glyphs at 20 and 24 pt; bezel at 32 pt. Inspect dark sky, bright clouds, grayscale and glow-off specimens. |
| State consistency | Required combinations preserve identical component bounds and optical alignment; every enabled press responds; disabled controls cannot activate; selection and toggle values are understandable without hue alone. |
| Readability | Measure essential text at ≥4.5:1 against its composited worst background; record colors and sampled region. No required stroke/counter depends on glow. Native Dynamic Type and actual VoiceOver remain separate checks. |
| Resource cost | Record encoded bytes and decoded pixel roster; identify every density/mask variant. No per-frame image decoding, generation or unbounded cache is introduced. Native frame pacing and process/GPU memory require later measurements. |
| Native regression | Verify target membership and Debug/Release resource loading, real touch alignment, default/maximum text, compact phone and iPad layouts, bright/dense boards, rapid input/cancellation, background/resume and normal/reduced motion under the [verification matrix](../../docs/ENGINEERING.md#verification-by-change). |

The asset package's structural and visual specimen review cannot establish native interactions, animation quality, performance, actual VoiceOver or physical-device acceptance. The normal target now extends its existing controls with the imported family. No rule, save, world progression or tutorial-write behavior changes belong to the artwork components.

## Native adoption and evidence

The source kit was reviewed against the accepted design at `cfd6ab7`. Native integration includes `ObservatoryArtwork`, shared theme/style changes, the 26 catalog sets and `ObservatoryArtworkTests`. The [native record](../../docs/evidence/observatory-ui-native-2026-10-19/README.md) and [capture index](../../docs/evidence/observatory-ui-native-2026-10-19/captures.json) identify exact native coverage and inspected appearances. The shared family is adopted for development; canonical delivery status is recorded in the native evidence. Debug/Release builds, hosted and interaction checks, inspected layouts, motion, actual VoiceOver and canonical device delivery remain distinct evidence categories.

The completed source/export and browser checks remain in their original [source-bound evidence](../../docs/evidence/observatory-ui-kit-2026-10-19/README.md); they are not rewritten as native acceptance.
