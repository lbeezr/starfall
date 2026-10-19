# Build a place around the stars

**Status:** Accepted art direction · **Updated:** October 19, 2026

Each level should feel like a substantial, connected place: crafted terrain, useful paths, supporting structures and a clear restoration story. Lantern Landing and Ribbon Crossing set the visual standard. During Silver Pools production, the user rejected the increasingly sparse “small landmark on empty sky” approach and enthusiastically accepted the richer common garden. Preserve that richness while fitting the actual native board.

Start with the [reusable brief](BRIEF.md), the [layout overview](overview.png), [camera construction](CAMERA.md) and the references below. The templates describe particular native layouts; they do not certify every viewport, text size or painting. **Next action:** compose a rich restored master, inspect it against the appropriate geometry, then check it in the native app before deriving the remaining states.

## The visual standard

<img src="../../../App/Assets.xcassets/LanternLanding100.imageset/scene.png" width="220" alt="Lantern Landing's substantial wooden deck connects to a path at the top right, with a closer bridge across the foreground">
<img src="../../../App/Assets.xcassets/RibbonCrossing100.imageset/scene.png" width="220" alt="Ribbon Crossing spans two developed terraces, with matching close pillars and ribbon at the lower corners">

**Packaged source paintings, inspected October 19, 2026 — not native screenshots.** Lantern Landing has a deck, bench, chest, rope fittings and a route continuing beyond the frame. Ribbon Crossing connects two places and repeats its construction in the foreground. Both establish near, middle and far depth around a readable center. See the [visual reference](../VISUAL_REFERENCE.md) for source-bound native evidence and its limits.

- **Give the place a purpose.** A common garden shares water; a landing receives arrivals. Paths, ledges, mechanisms and planted beds should explain how the place works. Build supporting clusters around a few decisive subjects, with recognizable silhouettes and physical connections.
- **Make material visible in the shape.** Thick stone rims, broad timber planks, stitched cloth and glass edges should differ in construction as well as color. Supports, contact shadows, joins and useful top/side faces give objects weight. Small detail supports the large forms.
- **Frame through terrain and depth.** Continue paths beyond the crop and use nearer foreground structures to place the viewer within the world. Keep one coherent camera and continuous painting. The readable center may contain restrained texture; do not manufacture a blank rectangle, middle mask, fog divider or rigid decorative frame.
- **Protect play through composition.** Put the sharpest scenic highlights and important silhouettes where they support the setting without obscuring star faces or matching groups. Shape and shade the architecture around native UI. Preserve its detail rather than globally shrinking the garden or the stars.

## Read the geometry, then judge the art

| Guide | Use |
| --- | --- |
| [Phone](phone.svg) | Reference phone composition, board, UI and crop regions |
| [iPad portrait](ipad-portrait.svg) / [iPad landscape](ipad-landscape.svg) | Separately authored arrangements of the same place |
| [Source phone](source-phone.svg) / [source iPad portrait](source-ipad-portrait.svg) / [source iPad landscape](source-ipad-landscape.svg) | Pixel-sized guides to attach to image-generation briefs; center-cover baseline with explicit crop limits |
| [Overview](overview.png) | Compare the three reference compositions together |
| [Native layout values](native-layouts.json) | Exact dimensions and configuration behind the guides |
| [Camera reference](CAMERA.md) | Consistent overhead vantage, projection, orientation and no visible horizon |
| [Star scale reference](scale-reference.svg) | Compare architecture and restoration details with the actual star scale |

The guides are authoring overlays, never artwork to package. Their exact reference geometry comes from the native layout contract; the color regions express different design priorities:

| Mark | Meaning |
| --- | --- |
| **Teal** | Opportunity for rich scenery. It is not a mandatory box or an instruction to fill every pixel. |
| **Amber** | Soft edge bleed: up to **0.15 cell** is a preliminary design budget to test, not an automatic allowance to hide stars or their cues. |
| **Red** | Native board contrast takes priority. This area need not be blank; restrained continuous sky, water or material can remain readable behind pieces. |
| **Violet** | HUD, dialogue and controls. Architecture may continue behind these surfaces, but do not place the only story-critical change there. |
| **Hatching** | Viewport crop/inset exposure. Do not rely on detail in this region surviving every fit. |

Use the actual star width, not the full cell square, as the visual ruler. The current small body's nominal diameter is about **0.70 cell**, and a grown body's about **0.86 cell**; texture padding and the growth aura extend farther. [FallingSkyMotion](../../../App/FallingSkyMotion.swift) and [StarCast](../../../App/StarCast.swift) own that presentation. Check both ordinary and grown stars when comparing a rail, flower, stream or important finish cue with the scale reference. These proportions are source facts, not permission to change star size.

[LandingGeometry](../../../App/LandingGeometry.swift) owns the board and cell mapping. [FallingSkyView](../../../App/FallingSkyView.swift) can use expanded scrolling canvases for compact viewports and accessibility text. [RestorationEnvironment](../../../App/RestorationEnvironment.swift) fits each complete painting using its actual dimensions. Device orientation, canvas shape, safe insets and Dynamic Type can therefore change the visible crop and text arrangement. Exact values for one guide do not establish universal safe space. Bleed and prop-scale recommendations still need native visual and input checks.

## Produce one coherent restoration

1. Write the place's function, main silhouette, material language and final change in the brief. Name the few purposeful supporting clusters and how they connect.
2. Build the restored master with the visual richness of the first two locations. Compare its focal detail and supporting architecture with actual star scale. Establish a phone, tablet portrait and tablet landscape composition; preserve the place's identity across them.
3. Inspect the master under native HUD, sparse and dense stars, dialogue and result controls. Adjust terrain arrangement, perspective or local material lighting where needed. Keep the whole scene continuous and the stars' geometry unchanged.
4. Derive **0 / 25 / 50 / 75 / 100** paintings from each accepted composition. Keep camera, architecture and backdrop registered; make progress cumulative and specific. A new connection, raised step or filled basin says more than a global brightness increase. At 75%, show a clear unfinished state; at 100%, resolve it visibly. In the existing 18-light challenge, these painting thresholds occur at scores **0 / 5 / 9 / 14 / 18**.
5. Record prompts, references, attempts, selected files, dimensions and hashes. Verify every family and state in the app. Source art, native stills, motion, input, actual VoiceOver and physical play remain separate evidence.

A 0% place may be quiet, drained or dormant while retaining its crafted structure. Restoration should reveal why that place matters. Keep its changes legible under the HUD and after the result appears. Do not add a gardening rule, campaign, walking actors or a cutscene to solve a composition problem. Existing whole-image transitions and committed gameplay remain separate from any future authored travel clips.

## Review before accepting a level

- [ ] At phone size, the image reads as a connected place with substantial architecture, purposeful supporting details and near/far depth.
- [ ] Each format retains the same identity, material language and restoration story; the wide view is deliberately composed.
- [ ] Sparse and full native boards keep all star faces, growth cues and matching groups readable; representative real taps use the unchanged cell mapping.
- [ ] Default and largest supported text, compact scrolling, HUD, dialogue and result actions remain readable. No sole progress or finish cue is hidden by UI or crop.
- [ ] All five states stay registered and build cumulatively. The 75% setup and 100% resolution are distinguishable without relying only on color.
- [ ] The complete painting remains continuous. No mask, hard middle cut, flattened panel or reduced star size was introduced to make it fit.
- [ ] Native normal motion and interruptions are inspected separately from stills and Reduce Motion. Evidence names the tested source, device/configuration and remaining limits.

## Research and scope

The [Hearthstone study](../environments/hearthstone-study/README.md) supplies useful principles: stable gameplay geometry, purposeful edge clusters, convincing supports, clear materials and a camera chosen for readability. Its [catalog](../environments/hearthstone-study/CATALOG.md) distinguishes full-board references from prop icons, and its [motion notes](../environments/hearthstone-study/MOTION.md) distinguish sampled media from live behavior.

<img src="../environments/hearthstone-study/comparison.jpg" width="700" alt="Six attributed Hearthstone board references showing substantial edge scenes and different materials around stable gameplay space">

**Historical external research — Blizzard and credited artists; inspected in the October 18 study.** The copied full-board references retain their [original sources and attribution](../environments/hearthstone-study/sources.json). They are documentation references, not licensed Starfall runtime assets or a brief to copy their characters and distinctive artwork. This kit applies the composition lessons to original Starfall places; it does not rewrite that historical study or claim its proposals shipped.

**Seed Moon is a future candidate for a richer composition review.** The user's comparison motivates that follow-up; it does not authorize replacing its current shipped art during Silver Pools production. This kit also does not change rules, saves, native control roles or the [world atlas](../WORLD_ATLAS.md). The repository’s [level-design skill](../../../.agents/skills/starfall-level-design/SKILL.md) routes future location work through this kit.

## Regenerate the guides

Run `swift test` to build Core, then `python3 scripts/level-design-kit.py` from the repository root using an environment with Pillow. The generator compiles `App/LandingGeometry.swift` with the export adapter and records source hashes. `--layouts-json` accepts an explicit prior export for offline reproduction. It preserves any original `sourceSHA256` values and marks geometry ownership unverified; `generationSourceSHA256` describes only the files present while making the guides. Compile a fresh export before relying on its geometry for new art. SVG point-sized panels and `source-*.svg` artwork-pixel panels have separate coordinate systems. The latter show center-cover baseline crop exposure; final focal fitting must still be inspected in the app. Generated guide files are owned by this folder’s generator and need no individual folder front doors.

The camera plate is authored SVG construction, independent of the layout generator. Render its PNG with an SVG renderer (the retained PNG uses Sharp 0.35.5) after editing the SVG, then inspect text, supports and measurement labels. Do not change painted source assets to produce these technical guides.
