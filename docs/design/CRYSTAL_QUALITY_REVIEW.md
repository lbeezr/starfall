# Existing crystal family: pixel quality review

16 October 2026. Scope: the five actual local DEBUG family PNG strips, checked
against [the game bible](STARFALL_GAME_BIBLE.md) and
[the artwork loader's geometry contract](../../App/StarshardArtwork.swift).
This review changes no artwork,
runtime code, default renderer, Release activation or game rules.

**Result:** all 45 source frames pass the geometry/alpha contract, and all
five silhouettes remain distinct in the composed neutral color, grayscale
and silhouette comparisons. The next art pass should address pale highlight
coverage in the currently used tilt and residual grain in broad bevels.
Amber's authored pivot should remain centered. This is local pixel evidence,
not an Apple simulator/device rendering or performance acceptance.

## Reproducible evidence

Run `python3 tools/art-quality/inspect_crystals.py` from the repository root.
The [tool contract](../../tools/art-quality/README.md) documents thresholds,
coordinates, dependencies, failure modes and evidence limits. The
[machine report](../../tools/art-quality/output/report.json) binds exact
source/file/frame hashes, the inspector and output images.

- [Neutral comparison](../../tools/art-quality/output/neutral-review.png):
  34 pt longest neutral span, 1 and 3 pixels per point; dark/plum/light,
  grayscale and alpha silhouettes.
- [All-frame comparison](../../tools/art-quality/output/tilt-review.png):
  every source frame at that same per-kind scale, with no per-frame alignment.
- [Board density](../../tools/art-quality/output/board-review.png):
  repeated groups in a static 7 × 7 fixture at the renderer's 0.37 × pitch
  radius; neutral color and grayscale.
- [Source geometry](../../tools/art-quality/output/geometry-review.png):
  untrimmed neutral frames, bounds, and `(128,128)` authored pivot.

All four images were opened and inspected locally. The panels preserve the
actual transparent PNGs; composition, grayscale and silhouette views are
diagnostics, not proposed replacement assets. Viewing zoom does not establish
physical phone size. The fixture is deliberately a readability comparison,
not a game-state, interaction or color-vision accessibility test.

Executed locally with Python 3.14.0 / Pillow 12.3.0: the real 45-frame audit;
a known centered synthetic rectangle; rejection of wrong mode/dimensions,
empty frames, nontransparent borders and missing files; failing CLI/report
status; rejection of a span outside the supported range; two byte-identical
full report/sheet runs; and before/after source-PNG hashes proving no asset
bytes changed. The revised tilt sheet was reopened to check label spacing.

## Measurements that affect art decisions

Every atlas is RGBA, 2304 × 256, containing nine unique RGBA frames. All frame
borders are transparent; the smallest nonzero-alpha margin is 30 source
pixels. Each frame remains within its original 256 × 256 canvas.

| Kind | Neutral span at 34 pt | Max motion span | Neutral alpha area | Alpha-box center offset from pivot |
| --- | --- | --- | --- | --- |
| Rose circle | 34.000 × 33.814 pt | 34.186 × 34.186 pt | 879.6 pt² | +0.093, 0 pt |
| Aqua diamond | 34.000 × 34.000 pt | 34.000 × 34.000 pt | 651.9 pt² | 0, 0 pt |
| Amber triangle | 34.000 × 30.012 pt | 34.210 × 30.012 pt | 566.9 pt² | 0, −4.093 pt |
| Violet hexagon | 30.531 × 34.000 pt | 30.878 × 34.000 pt | 783.5 pt² | 0, 0 pt |
| Mint square | 34.000 × 34.000 pt | 34.944 × 34.472 pt | 1111.1 pt² | 0, 0 pt |

The **alpha-weighted silhouette centroid is centered within 0.0004 pt for
every neutral piece**, including amber. A triangle's bounding box is not its
area center. Amber looks higher by its box, but moving it down by 4.093 pt
would move its silhouette mass below the authored pivot. Keep the existing
full-canvas centered anchor and assess optical balance in native play before
considering an art-camera change; do not recenter by the alpha box.

The largest frame-to-neutral alpha-box center displacement is only 0.297 pt
(amber); others are at most 0.208 pt. These numbers measure raster bounds,
not motion trajectories. Mint's widest motion span is 0.944 pt beyond its
neutral width. No overlap appears in the composed density fixture.

## Actionable art findings

1. **Retain more color in the bright tap frame.** Neutral surfaces share a
   coherent diagonal central reflection, but frame 1 turns a large central
   face pale. In the current tap sequence `[4,3,2,1,2,3,4]`, bright low-chroma
   coverage grows from 6.9–10.5% at neutral to 19.5–21.7% at frame 1 across
   the five kinds. Frame 0 reaches 22.7–25.9%, but is not currently used by
   tap or clear. In a future offline material/light pass, reduce the broad
   pale face while retaining a smaller strong highlight and changing facets.
   Compare frames 4/3/2/1 first; do not eliminate the approved tilt character.

2. **Clean broad bevel grain at source.** Speckled patches are visible in the
   lower/right aqua and violet bevels, rose's lower segmented reflection,
   and mint's lower and corner facets, especially in the 3-pixels-per-point
   and source-scale sheets. Inspect the actual original render sampling and
   denoise choices before a new export. Do not blur finished silhouettes or
   repaint the atlases as a shortcut. The 1-pixel-per-point row reduces this
   appearance, so decide severity at native phone scale before spending on
   a full family rerender.

3. **Keep fullness an explicit review choice.** Mint has about 1.96× amber's
   alpha-weighted area under the intentional equal-longest-span rule. Rose
   and mint consequently look fuller; amber and aqua look lighter. The
   shapes remain identifiable in grayscale. This is not a scaling defect,
   and it does not justify a runtime optical multiplier without a focused
   native side-by-side decision. Preserve the current dimensions meanwhile.

4. **Review the unused tilt half before future expansion.** Frames 6–8 have
   zero bright-low-chroma coverage by the stated threshold and appear much
   flatter than neutral/negative-side frames in the contact sheet. They are
   not part of the current tap or clear sequence. If future motion uses
   those frames, adjust the original lighting/material response so the
   alternate side keeps readable volume; this is not a blocker for the
   currently selected short response.

## Alpha, filtering and runtime boundaries

No obvious dark/light halo appears in the inspected premultiplied composites
on midnight, plum or light gray. Many fully transparent pixels retain nonzero
RGB; this alone is harmless with correct premultiplied-alpha sampling and
is not an asset failure. A future exporter must preserve the intended alpha
semantics. Do not infer native texture behavior from Pillow alone.

The inspected source loader creates separate full-frame crops, uses linear
filtering without mipmaps, retains transparent padding, and caches successes
and failures. That design prevents sampling the neighboring atlas frame.
The scene reuses its material boundary; there is no need for a second drawing
or decoding path. The family remains bounded at 45 frames plus 20 quadrant
textures: 12.5 MiB of RGBA8 base pixels, **not measured resident memory**.

The next native art acceptance can be short and specific: inspect neutral,
frame 1, and return-to-neutral on the narrow phone layout; compare amber's
optical alignment, mint/rose fullness, grain and bright-face color retention;
look for light/dark edge fringes during fractional positioning and animation;
check full 49-cell density and Calm/Reduce Motion settled states. Confirm
memory/frame pacing separately on supported hardware. This review does not
claim simulator/device, VoiceOver, interaction, animation timing, memory,
GPU filtering, or performance validation.
