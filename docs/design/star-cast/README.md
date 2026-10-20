# Starfall cast and gameplay pieces

**October 20 production pass — adopted for development.** The user approved [traditional characters paired with seven varied faceless pieces](characters-and-shards-2026-10-20/README.md). Gameplay uses the shard silhouettes; story, ceremony and the map keep their original face-bearing characters. The [motion contract](characters-and-shards-2026-10-20/MOTION.md) defines observable acceptance.

![Approved characters and faceless pieces, including round white Opal](characters-and-shards-2026-10-20/pairing-v2-opal.png)

Concept reference. The [transparent production source and packaging receipts](../../../Artwork/StarCast/README.md) identify the actual runtime inputs; the reference board is not a gameplay capture.

| Saved identity | Character | Faceless gameplay silhouette |
| --- | --- | --- |
| aqua | Spark, curious four-point star | Swept comet with two fused trailing tapers |
| amber | Sunny, friendly five-point star | Blunt irregular solar chunk |
| mint | Pip, inquisitive six-point star | Asymmetric meteor wedge |
| rose | Twinkle, gentle eight-ray star | Tall pinched diamond |
| violet | Nova, relaxed wide four-point star | Broad low lens |
| dark | Dusk, playful concave five-point star | Dark folded shard with opposing notches |
| light | Opal, pearly round character | Smooth white opalescent orb |

Normal colored pieces remain worth 1, grown colored pieces 2, Dusk 0 and Opal 1. Core rules, RNG, saved identities, matching and hit cells are unchanged. Current skies do not age automatically; retained Dusk/gravity rounds keep their existing behavior. Drained pieces retain their original-family edge and native family description while their center becomes gray.

## Two artwork roles

[SkyPiece.swift](../../../App/SkyPiece.swift) owns the faceless materials shared by forecast, airborne arrival and settled board. Seven `SkyPiece` image sets are cached once, with the existing Field and Hole sharing their original faceless textures. State changes reuse the same body image and preserve its pivot. Accessibility names describe the new silhouette and familiar family name.

[StarCast.swift](../../../App/StarCast.swift) retains the original Crystal Glow characters for story, ceremony and world-map use. Dialogue portraits retain their existing dedicated assets. The seven characters keep four expression slots and three shallow facings; Field and Hole share one material per object. Character expressions are not added to the gameplay pieces. The original [character masters](crystal-glow/characters/README.md) and [integration evidence](../../evidence/crystal-glow-integration-2026-10-17/README.md) remain source-bound references.

Offline packaging isolates each connected body, normalizes existing alpha coverage and fits its proportions into a 256×256 canvas, with a centered 128/128 pivot and maximum 208-pixel body span. No face, label, loose sparkle, ground shadow or aura is packaged in a gameplay body. Source-region extraction preserves Nova's wide tip; equal grid slicing would clip it. These are cutouts, not expression atlases.

## Motion, material and growth

The material has luminous facets, a bright upper bevel and a deeper colored lower edge. Shallow renderer meshes create yaw/pitch; finite rotation and local rebound create contact response. These are 2D presentation turns, not full 3D backs or moving-light simulation. Opal keeps its soft teardrop/squash meshes. The [family motion table](characters-and-shards-2026-10-20/MOTION.md#motion-direction) records the intended distinctions. Pieces return to a stable rest rather than continuously wobbling.

`FallingSkyCharacter` presents one body with a separate cached radial light field when grown. The previous offset body copies and paired diamond glints are removed. Growth scales the nominal radius from 0.35 to 0.46 cell spacing: approximately 1.31× linear size, with visible maximum extent around 0.90 spacing after texture padding. This deliberately keeps ordinary pieces readable and adjacent grown pieces separable; it is not literal double width. Aura strength may breathe in normal motion and stays static in quiet modes. Floating pieces have no floor shadows.

Stores still own committed outcomes, deadlines and persistence. Scene movement follows those outcomes. Only local child artwork responds to contact; its transform cannot select a cell, score or shower. Replacement and quiet-mode transitions cancel local actions and restore neutral transforms; scene teardown removes flight and growth effects.

## Bounded resources

The gameplay cache contains nine material references: seven new 256-pixel images plus two shared historical gravity materials. Seven new base RGBA8 images add 1,835,008 nominal bytes, plus one 128-pixel radial aura (65,536 bytes). The story material cache retains its existing upper bound of 86 UIImage/SKTexture pairs and nine original body sources. These are raster bounds, not measured total GPU/process memory. Decoding, image drawing and mesh construction happen outside per-frame paths. Finite SpriteKit actions reuse cached textures and meshes; no new game clock, observer or service is introduced.

## Verification and history

Use the repository [verification matrix](../../ENGINEERING.md#verification-by-change). Hosted checks cover both artwork roles, actual packaged bodies, motion reset/cancellation and landing handoff. UI checks exercise the normal scene and shared native hit mapping; Debug/Release builds check target membership and resources. Inspected native captures and sampled normal animation remain distinct from actual VoiceOver and physical feel.

The [October 20 expression review](refinement-2026-10-20/README.md), [three design directions](directions-2026-10-20/README.md) and [rejected whole-star study](whole-star-study-2026-10-20/README.md) retain the decision history. The original [paper-like concept](approved-concept.png), [first integration](../../evidence/star-cast-2026-10-17/README.md), [luminous revision](../../evidence/star-cast-luminous-2026-10-17/README.md) and [motion revision](../../evidence/star-cast-motion-2026-10-17/README.md) describe earlier sources. Earlier grown-cue screenshots and pulse evidence are historical for artwork after this pass.
