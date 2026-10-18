# Starfall cast — production rendering contract

**Direction approved:** Crystal Glow, October 17, 2026. The user approved the [six character masters](crystal-glow/characters/README.md) and requested integration. Native acceptance is recorded separately in the [integration evidence](../../evidence/crystal-glow-integration-2026-10-17/README.md).

The production renderer combines nine packaged transparent celestial cutouts with authored expressive faces. [StarCast.swift](../../../App/StarCast.swift) remains the shared owner for board, falling stars, HUD and previews. The [body production plate, exact prompt and packaging receipts](../../../Artwork/StarCast/README.md) make the raster inputs reproducible. Model/expression sheets are design masters, not loaded sprite atlases. No paid asset, external SDK or runtime image generation is used.

| Saved kind | Character | Recognition and temperament |
| --- | --- | --- |
| aqua | Spark | Tall four-point aqua crystal; curious open eyes |
| amber | Sunny | Balanced five-point amber crystal; friendly face |
| mint | Pip | Compact six-point mint crystal; raised eyebrow |
| rose | Twinkle | Eight alternating rose rays; gentle brow |
| violet | Nova | Wide four-point violet crystal; sleepy eyelids |
| nil/dark | Dusk | Concave five-point dark crystal, lilac rim; mischievous brow |

Names and point counts are presentation cues. Normal stars remain worth 1, grown stars 2 and dark stars 0. Core rules, RNG, saves and body sizes are unchanged. Grown board stars now carry a warm luminous double silhouette and two fixed diamond glints; [readability evidence](../../evidence/grown-star-readability-2026-10-17/README.md) records checks and limits. Existing VoiceOver descriptions retain color, shape, name, position and value. Dusk's grown expression is a reusable material slot, not a new rule.

**Dusk update:** Matching weight remains 1/2, but touching stars/Opals become gray and score zero. A thin original-color edge and native shape/name preserve family recognition; grown glints remain. Three feeding marks, inward strokes and a growing halo/core communicate the bounded collapse. [Current Dusk contract](../DUSK_FEEDING.md).

## Body, face and shadow ownership

The offline packaging tool splits the transparent plate, keeps each body's largest connected alpha island, normalizes coverage and fits its existing proportions into a centered 256×256 canvas. Body extent is at most 208 pixels, inside the existing 212-pixel display-size contract. It removes stray disconnected glints rather than carrying neighboring cutout fragments into the game. No labels or ground shadows are packaged.

The seven faced star identities have four expression slots (idle, landing, grown, clearing) and three facings (front, left, right). Large navy eyes have blue lower gradients, pupils and catchlights. Nova and Dusk retain distinct idle eyelids; eyebrows distinguish Pip and Twinkle. Landing is surprised, grown is open-eyed happy, clearing uses closed happy eyes. Source-atop composition changes color without changing body alpha, including translucent edge coverage.

Partial turns remain shallow 2D presentation: horizontal compression and face offset around a stable 128/128 pivot. They are not a full 3D mesh, profile or rear rotation. Construction views and motion poses in the approved masters guide production; unsupported views are not added speculatively. Existing flight, squash/stretch, rebound, neighbor reactions, growth and clearing timing remain owned by the scene.

Ground shadows are separate scene nodes, with a dark compact contact core and softer wider pool. Existing clear/gravity/rebuild actions own their lifetime. Shadows do not determine rules or legal destinations. The shared Observatory projection continues to own scene, native hit and accessibility coordinates; no depth-based character scaling or board geometry change is introduced by this cast integration.

The grown cue belongs to `FallingSkyCharacter`, attached beneath its sprite so local reactions and landing transforms carry the entire cue. Two tinted echoes reuse the cached idle texture's exact body alpha; two small diamond glints sit above the body. Four cue children are allocated once per character and hidden for ordinary/dark stars. Expression changes preserve the active pulse; render, clear and restart dispose of the cue with the character. Only the outer echo opacity breathes over 2.8 seconds (0.14–0.34), with a stable per-ID presentation phase across scene rebuilds. The rim, glints and body stay steady. One keyed SpriteKit action per grown star is canceled for Calm effects, Reduce Motion, VoiceOver, suspension, scene detachment and replacement; quiet mode restores alpha 0.24. No new texture cache, particles, timers or tasks are introduced. [Current-main pulse evidence](../../evidence/grown-star-readability-2026-10-17/PULSE.md).

## Bounded resources and lifecycle

A main-actor material cache prewarms before the first shower: at most 86 UIImage/SKTexture pairs, each 256×256. Their base RGBA8 rasters total 22,544,384 bytes; nine cached source bodies add 2,359,296 nominal RGBA8 bytes. These are source-raster bounds, not total process/GPU memory measurements. Asset-catalog decoding and material drawing occur on cache creation, never per frame. No new particles, observers, tasks, frame callbacks or clocks are introduced.

`StarCast.setExpression` preserves sprite size and anchor. Stores still coordinate committed outcomes, persistence and interruption. Scene replacement, restart, backgrounding, menu dismissal, calm effects, system Reduce Motion and VoiceOver keep the existing presenter/generation contracts. Classic Debug jewel rendering keeps its existing crystal factory.

## Verification and historical references

Run `swift test`, hosted `StarCastTests`, `FallingSkyStoreTests`, `ObservatoryGeometryTests`, affected `FallingSkyInteractionTests` and `ObservatoryInteractionTests`, plus Debug/Release simulator builds. Hosted exports include the actual runtime cast at 24/36/44-point sizes and twelve-frame sheets. Inspect native gameplay captures and full motion separately; a contact sheet cannot prove animation.

The earlier [paper-like concept](approved-concept.png), [first integration](../../evidence/star-cast-2026-10-17/README.md), [luminous revision](../../evidence/star-cast-luminous-2026-10-17/README.md) and [motion revision](../../evidence/star-cast-motion-2026-10-17/README.md) remain historical evidence for their recorded source. Crystal Glow supersedes their body rendering, retaining the shared material, shape identity and animation contracts.

## Production gravity objects

Attraction Field and Hole use packaged generated cutouts through the same material loader. Their fixed faceless materials deliberately share one cache entry per object across all expression/facing requests; no arrow glyph or alternate renderer remains. The open field has translucent wisps and no solid center, star points, contact shadow or physical bounce. Its blue-gold light connects it visually with the hole’s accretion ribbon. Theme owns matching light colors; finite scene/child-art actions present convergence, formation and rotation without changing Core, saves or hit coordinates. [Sources/prompts/packaging](../../../Artwork/StarCast/README.md#magnetic-crystal-and-gravity-hole) and [native acceptance](../../evidence/gravity-art-2026-10-17/README.md) record the asset and runtime boundaries.
