# Crystal pixel review

For the falling-sky cast, `package_star_cast.py` packages approved transparent sources into centered asset-catalog cutouts. `--shards` produces seven faceless `SkyPiece` bodies from the approved October 20 plate, preserving the original `StarCast` character assets. Explicit source regions protect the broad lens from clipping. See [StarCast source/receipts](../../Artwork/StarCast/README.md). Run with Python/Pillow; this is offline slicing and coverage normalization, not runtime artwork generation. The older atlas inspectors below continue to serve the Debug jewel renderer.

Local inspection of the five default gameplay atlases. This tool reads
source PNGs and writes comparison sheets plus measurements; it never edits
the asset catalog, runtime code, source artwork, or release configuration.

The original puzzle's Debug regression renderer uses the recreated five-kind v2 family from
`Artwork/Crystals/v2/assets`. That sealed package contains newly authored Blender
source, not recovered original source or alpha-identical v1 artwork. Runtime
loading keeps all nine full canvases and the authored pivot, and falls back to
the complete procedural family if any member is missing or malformed. The
explicit Debug-only `--crystal-pilot` route still selects the original aqua v1
comparison asset, with procedural art for the other kinds. It does not select v2.

## Missing-asset preflight

Check a checkout's catalog before requesting another artwork handoff:

```sh
python3 -B tools/art-quality/validate_catalog.py
python3 -B tools/art-quality/validate_catalog.py --assets /path/to/App/Assets.xcassets --json
python3 -B tools/art-quality/test_validate_catalog.py -v
```

The read-only preflight requires the five exact-case `StarshardFamily{Kind}`
image sets plus `CrystalPilot`. It checks each `Contents.json` for one universal
entry naming its expected PNG and `info.version` 1; then checks RGBA, 2304 × 256,
nine nonempty padded frames. Referenced filenames must stay directly inside
their image set; traversal and symlinks escaping that directory are rejected.
Each of the five family PNGs must match its own v2 file SHA-256 pinned in the
utility and sealed package manifest. `CrystalPilot` must separately match the
original aqua v1 pin and frozen comparison manifest; the two aqua files are
intentionally distinct. Even lossless recompression changes approved file bytes
and is reported for explicit review. The v2 JSON report records all six pins;
`aqua_copies_identical` is informational and is false for the approved catalog.

Exit **0** means these catalog checks pass; **1** reports catalog/content
errors; **2** is invalid CLI usage. The default prints concise diagnostics;
`--json` prints details and input hashes to stdout. No output file is created.
Tests use temporary catalogs, the sealed family, and the frozen legacy reference,
preserving real assets.

This models the existing loader's file/geometry contract. Source integration,
project resource registration, compiled bundles, `UIImage` loading, appearance
and native behavior remain unchecked. The preflight does not locate or require
editable 3D render sources. It uses the existing Python/Pillow dependencies.

## Pixel review

From the repository root:

```sh
python3 tools/art-quality/inspect_crystals.py
```

Requires Python 3.10+ and Pillow with `ImageFont.load_default(size=...)`
(Pillow 10.1+). The checked-in run used Pillow 12.3.0. There are no network,
provider, Blender, or Xcode dependencies. The game-development-studio
capability/doctor checks were consulted for the initial review; its 3D asset
validation commands do not validate these PNG atlases.

The checked-in `output/` sheets and `comparison/baseline/` remain historical v1
evidence. The sealed v2 contact sheets are under
`Artwork/Crystals/v2/review/current/`. Use a separate output directory for any
new review; do not overwrite either historical record. A strict comparison of
v2 against the frozen v1 alpha baseline intentionally fails because the geometry
was recreated. It is not a substitute for the v2 structural checks or native
acceptance.

## Contract and output

Inputs are the exact five `StarshardFamily{Kind}.imageset/{kind}_tilt_atlas.png`
files in `App/Assets.xcassets`. Each must be a decoded RGBA PNG, 2304 × 256,
with nine nonempty 256 × 256 horizontal frames and at least one transparent
outer row/column on every frame. Exit **0** means those structural checks pass;
exit **1** means a missing/unreadable/malformed/empty/unpadded asset. Invalid
arguments exit **2**. An invalid family still produces `report.json`, but no
new sheets; only sheets listed in that report are evidence for that run.

The tool models the existing `StarshardArtwork` contract explicitly: neutral
frame 4, authored pivot `(128,128)`, full untrimmed canvas, and longest neutral
alpha span of 34 pt. It does not extract or verify current Swift constants.
If runtime geometry changes, update the contract here deliberately. Output
is deterministic for the same source bytes, Python/Pillow environment and
arguments. `report.json` records source/file/frame hashes, tool hash, Pillow
version, all measured frames and output-image hashes; it has no wall-clock
timestamp or machine-specific absolute paths.

| File | Use |
| --- | --- |
| `output/neutral-review.png` | Neutral on midnight, plum and light; grayscale and alpha silhouettes; 1 and 3 pixels per modeled point |
| `output/tilt-review.png` | All 45 frames at 3 pixels per modeled point, preserving each kind's neutral scale; frame labels and bright-facet fractions |
| `output/board-review.png` | Two static 7 × 7 density fixtures, color/grayscale, using radius `0.37 × pitch`; not a game screenshot or reachable-state assertion |
| `output/geometry-review.png` | Full neutral source pixels, alpha bounds and authored pivot |
| `output/report.json` | Structural verdict, hashes, alpha bounds/area/centroids, padding and highlight diagnostics |

Optional alternative destinations and spans:

```sh
python3 tools/art-quality/inspect_crystals.py --output /tmp/starfall-crystal-review
python3 tools/art-quality/inspect_crystals.py --visible-pt 40 --output /tmp/starfall-crystal-40pt
```

`--assets PATH` selects a different catalog with the same filenames/contract.
`--output PATH` must not be inside that input catalog. Named output files are
replaced on a successful rerun. `--visible-pt` accepts 16–40 only, keeping
the fixed review-sheet columns clear. At the default, 34 pt corresponds to
102 raster pixels in a 3-pixels-per-point panel. Viewer zoom and display DPI
may change apparent size; inspect native screenshots on Apple tooling to
establish actual device appearance.

## Reading the metrics

Coordinates have a top-left origin and exclusive right/bottom bounds. Bounds
include every nonzero-alpha pixel. Alpha-weighted area and centroid use pixel
centers and fractional alpha. Bounds-center motion is an observed raster
diagnostic, **not** an inferred animation pivot. In particular, the triangle's
bounds center and silhouette centroid differ by design.

Highlight fractions count only pixels with alpha ≥128. `near_white_pct` uses
minimum RGB ≥235 and RGB range ≤20; `bright_low_chroma_pct` uses minimum RGB
≥210 and range ≤45. These are reproducible encoded-RGB heuristics, not a
perceptual color score or automatic art failure. Mean encoded luma is not
linear-light luminance. Nonblack RGB under zero alpha is reported because
naive straight-alpha resampling can reveal it; its presence alone is not a
visible fringe or a SpriteKit defect.

The review composites use premultiplied-alpha Pillow bilinear resampling.
They intentionally do not smooth, recolor, recenter, trim, denoise or repaint
art. Bilinear here approximates the local inspection need; it is not a match
for SpriteKit's complete GPU, color-management or display pipeline. None of
the metrics certify native animation, filtering, accessibility, memory,
frame pacing, physical tap targets or production readiness.

See [CRYSTAL_QUALITY_REVIEW.md](../../docs/design/CRYSTAL_QUALITY_REVIEW.md)
for the observed art findings and the focused next review.

## Candidate comparison

`compare_crystals.py` reuses this inspector and keeps a frozen copy of the
five original atlases under `comparison/baseline/`. The retained
`comparison/self/` report and sheets compare those originals against
themselves; they do not represent improved artwork. No renderer or candidate
is included in this validation package.

```sh
python3 -B tools/art-quality/compare_crystals.py self-test
python3 -B tools/art-quality/compare_crystals.py compare \
  --baseline tools/art-quality/comparison/baseline \
  --candidate tools/art-quality/comparison/baseline \
  --output /tmp/starfall-crystal-self-check
```

Use the frozen baseline for future comparisons rather than replacing it with
a new candidate. All alpha samples must match for a strict pass; highlight
and texture measures are advisory. See
[CRYSTAL_REFINEMENT_ACCEPTANCE.md](../../docs/design/CRYSTAL_REFINEMENT_ACCEPTANCE.md)
for the full comparison contract, candidate command and evidence limits.

`package_star_cast.py --gravity` packages only the open attraction field and hole from `Artwork/StarCast`, preserving the field’s transparent center and hole’s opaque center and using the shared cast fitting rules. The gravity receipt records original and packaged hashes; no paid provider or runtime image generation is involved.
