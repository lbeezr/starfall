# Starfall cast and gameplay pieces

**Living starlight — adopted and development-verified, October 20:** The user selected [one responsive inner light within each stable gameplay silhouette](living-starlight-2026-10-20/README.md), including white Opal, for the normal game and original phone. All seven shell materials and finite light responses are implemented. The two artwork roles below remain; [native checks and sampled visual/motion evidence](../../evidence/living-starlight-2026-10-20/README.md) pass on snapshot `756c0353`, runtime `dev.e2b265734e`. Publication and canonical delivery remain pending.

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

[SkyPiece.swift](../../../App/SkyPiece.swift) owns the faceless materials shared by forecast, airborne arrival and settled board. In the approved living-light integration, seven `SkyPiece` image sets supply translucent shells. [LivingLight.swift](../../../App/LivingLight.swift) prewarms an interior mask, resting composite and shared shader per family, then renders one bounded inner light on native gameplay nodes. Per-node attributes hold light response, drain and pressure independently; family uniforms remain immutable. Forecast images use the cached resting composite. Field and Hole keep their original shared faceless textures. State changes preserve the body pivot, and accessibility names retain the silhouette and familiar family name.

[StarCast.swift](../../../App/StarCast.swift) retains the original Crystal Glow characters for story, ceremony and world-map use. Dialogue portraits retain their existing dedicated assets. The seven characters keep four expression slots and three shallow facings; Field and Hole share one material per object. Character expressions are not added to the gameplay pieces. The original [character masters](crystal-glow/characters/README.md) and [integration evidence](../../evidence/crystal-glow-integration-2026-10-17/README.md) remain source-bound references.

Offline packaging isolates each connected shell and fits its proportions into a 256×256 canvas, with a centered 128/128 pivot and maximum 208-pixel body span. No face, label, loose sparkle, ground shadow or aura is packaged in a gameplay body. The translucent center is completed by the cached rest material or native inner light. Each crop must preserve the complete authored contour; equal grid slicing can clip a wide tip. These are cutouts, not expression atlases.

## Motion, material and growth

The approved material combines a colored translucent boundary with one broad light inside it. Finite shader responses let the light lag in flight, gather after impact and attend briefly to touch. Shallow renderer meshes still create yaw/pitch; finite rotation and local rebound create body contact response. These are 2D presentation turns, not full 3D backs. Opal keeps its soft teardrop/squash meshes. The [body-motion table](characters-and-shards-2026-10-20/MOTION.md#motion-direction) and [inner-light acceptance](living-starlight-2026-10-20/README.md#native-acceptance) distinguish their responsibilities. Bodies and inner light return to a stable rest; quiet modes keep the light steady.

`FallingSkyCharacter` presents one body with a separate cached radial light field when grown. The previous offset body copies and paired diamond glints are removed. Growth scales the nominal radius from 0.35 to 0.46 cell spacing: approximately 1.31× linear size, with visible maximum extent around 0.90 spacing after texture padding. This deliberately keeps ordinary pieces readable and adjacent grown pieces separable; it is not literal double width. Aura strength may breathe in normal motion and stays static in quiet modes. Floating pieces have no floor shadows.

Stores still own committed outcomes, deadlines and persistence. Scene movement follows those outcomes. Only local child artwork and shader values respond to contact; neither can select a cell, score or shower. Replacement and quiet-mode transitions must cancel local actions and restore neutral transforms and light values; scene teardown removes owned flight and growth effects. The linked evidence records passing native reset/lifecycle checks on the tested source.

## Bounded resources

The living-light gameplay cache keeps nine material references and seven shared family shaders. Each of seven families retains three 256-pixel rasters—shell, interior mask and rest composite—plus two shared historical gravity materials: **6,029,312 nominal RGBA8 bytes**. One existing 128-pixel radial grown aura adds 65,536 bytes separately. The story material cache retains its existing upper bound of 86 UIImage/SKTexture pairs and nine original body sources. These are raster bounds, not measured total GPU/process memory. Decoding, image drawing, mask scanning, shader creation and mesh construction happen during prewarming. Finite SpriteKit actions change per-node `a_light`, `a_drain` and `a_pressure` attributes and reuse cached textures, shaders and meshes. No new game clock, observer or service is introduced.

## Verification and history

Use the repository [verification matrix](../../ENGINEERING.md#verification-by-change). The [living-light record](../../evidence/living-starlight-2026-10-20/README.md) binds passing checks to snapshot `756c0353`: both artwork roles, shell/mask/rest caches, finite response/reset, native fall/contact/touch, a 49-piece board and Debug/Release membership. Publication and canonical delivery are pending. The [earlier shard record](../../evidence/gameplay-shards-2026-10-20/README.md) remains evidence for its own static materials and body motion, not the new light shader. Inspected captures and sampled normal animation remain distinct from actual VoiceOver and physical feel.

The [October 20 expression review](refinement-2026-10-20/README.md), [three design directions](directions-2026-10-20/README.md) and [rejected whole-star study](whole-star-study-2026-10-20/README.md) retain the decision history. The original [paper-like concept](approved-concept.png), [first integration](../../evidence/star-cast-2026-10-17/README.md), [luminous revision](../../evidence/star-cast-luminous-2026-10-17/README.md) and [motion revision](../../evidence/star-cast-motion-2026-10-17/README.md) describe earlier sources. Earlier grown-cue screenshots and pulse evidence are historical for artwork after this pass.
