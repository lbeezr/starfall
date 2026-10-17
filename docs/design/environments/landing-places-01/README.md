# Five landing places — art direction, 2026-10-17

## Intent and decision

Build five recognizable places rather than a large sky-palette catalog. Each gets its own materials, prop vocabulary, silhouette, lighting, depth and emotional tone. All remain cosmetic environments for the same Falling Sky rules; no campaign, unlocks or location-specific mechanics. This is an art-direction proposal, not five completed production environments.

The user positively responded to the moonstone landing-terrace illustration. Use its shallow oblique camera as the common comparison baseline. Retain the stronger perspective illustration as a camera study only; it must not become a sixth location. The cosmic paintings from cosmic-01 remain a historical spatial/mood study, not a second active location catalog.

## Research and interpretation

- Regular Hearthstone: Blizzard's [Secrets of Stranglethorn Vale](https://hearthstone.blizzard.com/en-us/news/9773962) describes environmental ambiance, gentle animation and peripheral interactions. The official screenshot was inspected. Quiet central surface, dimensional corner scenery, deliberate materials and environmental storytelling are the relevant visual lessons.
- Battlegrounds: Blizzard's [22.0 notes](https://hearthstone.blizzard.com/en-us/news/23751629) introduce Arena of Champions' armor/purple/gold identity and explicitly simplify its bottom-right region on mobile. This is a useful example of tailoring set dressing around play/controls.
- Primary artist/studio records: [Tiffany Chiu's Tinker Tavern](https://tiffachiu.artstation.com/projects/8wAA0O), [Mooncolony's Murloc Hideaway](https://mooncolony.artstation.com/projects/2qmmmJ), and [Sandy Shores](https://mooncolony.artstation.com/projects/NGkDXN) establish distinct tavern/shore settings and production credits. Their retrieved pages exposed descriptions rather than full-resolution art; do not claim image inspection of those exact boards.

Design inference: borrow environmental framing, a tactile landing surface, grounded contact shadows and small clusters of characterful props. Do not copy Hearthstone's layout, franchise props or interactions. “Isometric” is a useful visual cue here; the preferred portrait study uses a shallow oblique view rather than a strict equal-axis isometric camera. Keep Paper Mario's constructed softness and Fountain of Dreams' dreamlike lighting as the broader art-direction markers.

## The five places

| Place | Tone / light | Surface and materials | Signature props | Scenery and spatial identity |
| --- | --- | --- | --- | --- |
| **Moonlit Observatory** | Tender curiosity; cool midnight, warm pinpoints | Worn lavender moonstone, aged brass, soft crystal petals | Star-catching telescope, single lantern, crystal flowers | Planet rim, deep galaxy, distant floating observatories, foreground cloud curls. A place where someone watches for falling stars. |
| **Cloudsea Conservatory** | Welcoming, breezy; peach dawn | Dusty rose matte ceramic, ivory stone, sage enamel, weathered rosewood | Wind harp, paper pinwheel, little dew catcher | Broad cream cloud ocean, hanging planters, distant glasshouses, trailing vines. A place that nurtures what arrives. |
| **Comet Hearth** | Cozy, industrious; amber dusk against blue night | Quiet charcoal basalt, copper bands, terracotta | Rounded kiln, bellows, star molds, kettle | Curved comet cliffs, distant golden dust tail, restrained smoke layers. A place where starlight is carefully tended. |
| **Prism Tide Grotto** | Hushed, refreshing; cool petrol and pearl | Frosted matte sea glass, rounded shellstone, pale coral | Spiral-shell water thread, tide basin, pearl | Near cavern silhouette, lagoon light, distant sea arch and thin planet ring. A sheltered place where cosmic tides arrive. |
| **Eventide Archive** | Reverent, curious; wine-black and aged gold | Matte dark slate, ebony, antique ivory | Small orrery, suspended sandglass, closed books, floating bookmark | Quiet abyss, paper-like cloud veils, remote luminous event horizon. A place that seems to remember the stars. |

These voice lines guide set dressing, sound and motion; they are not lore quests or new systems. Mood cannot depend solely on hue: each location must remain identifiable in grayscale and as a silhouette thumbnail.

## Shared production grammar

- Same board footprint, star cast and family silhouettes, native semantics and clear seven-column topology. Illustrated stars in these concepts are composition placeholders; their identical five-point shapes are not an approved replacement for production non-color cues.
- Landing surface is part of the place: broad quiet material, edge thickness, peripheral wear, no visible square cell backgrounds. Reserve clear HUD/control zones early.
- Prefer upright star sprites over the ground plane, contact shadow under each committed landing, short arrival arc/drop and restrained material-specific impact. Never flatten or stretch the star art with the floor.
- Six spatial planes: far sky/void; distant landmark; atmospheric midground; rear props; landing plane and gameplay; foreground rim/props. Effects stay behind character faces and out of touch targets.
- Only one or two ambient motifs per place: observatory lantern/cloud drift; conservatory chime/vine sway; hearth kiln pulse/smoke; grotto water glint; archive orrery/bookmark. These are proposed, not implemented. No cosmetic RNG use may alter game RNG.
- The same committed star state and clearing rules must work everywhere. Do not infer a changed score, shower pace, dark-star behavior or interaction from a prop or material.

## Camera and gameplay question

A receding floor makes stars feel grounded, but the current core uses seven columns accumulating along seven rows. We must establish whether rows read as height in a pile or depth across a floor before adopting the camera. This is an open presentation/affordance question, not permission to change rules or silently invent 3D stacking.

Do not rotate/skew only SpriteView: native button cells and SpriteKit currently calculate matching rectangular positions separately. A native perspective experiment must first give rendered positions, projected cell polygons, hit testing and accessibility frames a single mapping owner. Preserve upright star aspect and stable identities. The far row must remain tappable at a full usable target size; reduce tilt or framing if it cannot. Real native tap checks are required on all corners, adjacency boundaries and resized boards. Until that exists, these are explicitly generated illustrations, not playable/native screenshots.

## Acceptance and bounded next pass

1. **Art identity:** five places recognizable by silhouette/material/prop arrangement, including grayscale; at most two primary prop clusters, restrained tertiary detail. Distinct warm/cool and open/enclosed moods.
2. **Composition:** compare the same sparse, half-full and nearly-full board with the real cast, dark stars, HUD and large text. No prop/foreground occlusion; no decorative star confusion; no bright floor marks that look interactive.
3. **Motion:** coherent arrival-to-contact, shadows and bounded impacts; ambient planes separate from gameplay and disabled/reduced appropriately. No camera rocking or required parallax to understand a move.
4. **Rules/save/input:** original deterministic replay and save fixtures unchanged; native geometry/touch/accessibility checks pass if projection changes; settings and background/restart reject stale effects.
5. **Accessibility:** actual VoiceOver, Reduce Motion/Calm effects, Increased Contrast, Reduce Transparency and Dynamic Type checked separately. Lighting changes cannot remove family/non-color cues.
6. **Production:** final background-only separated layers contain no baked-in gameplay pieces, UI or shadows for old states; bounded textures/caches; memory/frame pacing measured in a reproducible native scenario.

Decision point: five-place concept review, then one Moonlit Observatory graybox/native projection proof before any perspective adoption. Reuse that validated camera and layout for the remaining four. If the camera harms seven-row readability or touch size, retain a shallower view and get depth from rims, shadows and scenery. No production route or flag added for these concept assets.

## Assets and provenance

Original generated concepts, built-in image generator. Exact prompt sets saved beside this file. No third-party board textures or models imported into the game. The illustrations include temporary star placeholders and must not ship as game backdrops. No simulator/device validation claimed for them; no source implementation changed in this design pass. Native geometry, motion, performance and human preference remain unverified.
