# Starfall cast — production rendering contract

The approved [concept sheet](approved-concept.png) is reference artwork, generated with the built-in OpenAI image tool in this chat and approved by the user. It is not a sprite atlas. Runtime artwork is newly authored in [StarCast.swift](../../../App/StarCast.swift): editable star contours, color/shading, eyes, mouths and expressions. No downloaded character art, font artwork, paid asset, external SDK, or runtime image-generation service is used. The direction draws on the user's preference for readable, expressive paper-like stars; these are original designs rather than reproductions of another game's characters.

| Saved kind | Character | Recognition and temperament |
| --- | --- | --- |
| aqua | Spark | Tall four-point silhouette; curious open eyes |
| amber | Sunny | Balanced five-point star; open, friendly face |
| mint | Pip | Compact six-point star; raised eyebrow and open eyes |
| rose | Twinkle | Eight alternating rays; quiet, shorter oval eyes |
| violet | Nova | Wide four-point silhouette; sleepy face |
| nil/dark | Dusk | Concave five-point star, light lilac keyline and dark interior; gently mischievous |

Names and varied point counts are presentation only. Jewel raw values, deterministic shower/clear rules, scores, challenges and saves are unchanged. Point count does not indicate value: normal stars are worth 1 and grown stars 2; dark stars remain worth 0. VoiceOver labels include color, silhouette and name, plus existing position/value/growth-block information. Color alone is unnecessary for distinguishing normal families; the two four-point families have different proportions.

## Materials and animation

- All poses use the same centered 256×256 transparent canvas with a 128/128 pivot. Rounded contour corners retain the authored points. Rendering has transparent padding, and expressions never change the alpha silhouette.
- Four expression slots: idle (family personality), landing (surprised), grown and clearing (happy). Grown and clearing intentionally share the same happy drawing. Grown stars also remain visibly larger; expression alone does not carry value.
- Existing comet timing, gravity, landing bounce, growth ring and clear effects remain. Comets now carry the actual star face/shape. There are no independent infinite idle actions or new rules driven by animation.
- A single main-actor material owner rasterizes each family/expression once and caches successes. Six families × four slots = at most 24 UIImage/SKTexture pairs. Each base RGBA8 raster is 256×256: 6,291,456 bytes across all 24 source images. This is not a total-process/GPU-memory claim; texture copies, image backing and framework overhead are separate.
- Prewarming happens on scene construction before the first shower. No file IO, texture regeneration or artwork drawing occurs per frame. Board, comets and native preview consume this same factory. Classic Debug puzzle rendering keeps its existing crystal artwork and fallback; the falling-sky renderer no longer requests those jewel materials.
- Expression changes go through `StarCast.setExpression`, which preserves size and pivot. Native recording found a brief intrinsic-size jump when using a SpriteKit texture action; both landing and clear now use the shared geometry-preserving boundary. An animated hosted test samples sprite bounds throughout flight, face swap and settlement, alongside every-family/pose geometry checks.
- Calm effects, system Reduce Motion and VoiceOver settle directly to idle/grown frames through the existing store/scene contract. The cast changes neither input gating nor the clock.

## Reproduction and acceptance

Build shared scheme Starfall normally in Debug or Release. Default entry uses the cast; no permanent pilot flag is needed. Run `swift test` separately, then hosted `StarCastTests`, affected app/store tests and `StarfallExperimentInteractionTests`. `testCastReviewSheetAtBoardAndHeroSizes` attaches a contact sheet generated from the actual runtime renderer, including 24/36/44-point canvases. No separate source PNG atlas needs manual synchronization. The source itself is the canonical editable asset; exported PNGs/contact sheets are review artifacts.

[Native evidence](../../evidence/star-cast-2026-10-17/README.md) separates clean-candidate tests, inspected imagery and full-animation recording from remaining device/VoiceOver acceptance. This handoff is for the production game renderer, not an assertion that the entire app is App Store ready.

## Luminous revision — October 17

User feedback reopened visual acceptance: the first runtime eyes and solid-token treatment did not meet the desired quality. The revised candidate uses single dark oval eyes with one catchlight, shorter relaxed eyes for quieter characters, a broad inner light, pale contour and a soft baked halo. Dusk retains a dark body and restrained rim. No new particles, texture slots or animation work are introduced. The halo is clipped inside the existing transparent padding; silhouette geometry, board sizing and expression pivots remain unchanged. See the [revision evidence](../../evidence/star-cast-luminous-2026-10-17/README.md). This is a reviewable visual iteration, not a claim of final art approval.
