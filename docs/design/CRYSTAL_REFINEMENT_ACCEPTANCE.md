# Crystal refinement acceptance

16 October 2026. This lane compares the original five-by-nine crystal atlases with a separate source-rendered candidate. It owns only the comparator, frozen comparison inputs/outputs, and this handoff. It does not change the asset catalog, original inspector/output, source renderer, runtime, tests or Xcode project.

**Current result:** the original-against-itself control passes all 45 strict frame checks with zero changed pixels. A refinement candidate has not yet been evaluated. This establishes the comparison control, not an improvement or native acceptance.

## Frozen input and commands

The original PNG files are preserved byte-for-byte under [`tools/art-quality/comparison/baseline`](../../tools/art-quality/comparison/baseline/manifest.json), using the existing `StarshardFamily{Kind}.imageset/{kind}_tilt_atlas.png` layout. The frozen manifest records each file SHA-256 and geometry contract. `freeze` refuses an existing destination; comparison verifies those frozen hashes before accepting any result. Do not refresh this baseline to make a changed candidate pass.

The comparator reuses the unchanged inspector's pixel metrics and premultiplied-alpha composition helpers. Requirements are the existing Python 3.10+ and Pillow 10.1+ environment; no new dependency, network, provider, Blender or native build is involved. This run used Python 3.14.0 and Pillow 12.3.0.

```sh
# Already completed: immutable copy of the original input files.
python3 -B tools/art-quality/compare_crystals.py freeze \
  --baseline tools/art-quality/comparison/baseline

# Focused malformed-input and measurement checks.
python3 -B tools/art-quality/compare_crystals.py self-test

# Already completed: original against the same original.
python3 -B tools/art-quality/compare_crystals.py compare \
  --baseline tools/art-quality/comparison/baseline \
  --candidate tools/art-quality/comparison/baseline \
  --output tools/art-quality/comparison/self

# Run when a separately supplied source-rendered candidate is available.
python3 -B tools/art-quality/compare_crystals.py compare \
  --baseline tools/art-quality/comparison/baseline \
  --candidate /path/to/candidate-imagesets \
  --output tools/art-quality/comparison/candidate5x9
```

Both input roots must contain the five canonical imageset paths. The output must be outside both inputs. `--visible-pt` defaults to 34 and accepts finite values from 16 through 40; it controls inspection scale only. It never changes source pixels. Use a new versioned output directory for subsequent candidate versions if retaining their evidence.

The completed validation package contains no renderer or refinement candidate.
The placeholder candidate path above is supplied only when new source-rendered
art is ready; its absence does not block running the inspector, self-test or
original/self comparison.

## Strict structural gate

Exit **0** means the frozen original is intact and these structural checks pass. Exit **1** means an input/structural failure recorded in `report.json`. Exit **2** means invalid CLI configuration or an I/O failure prevented normal execution. A passing structure never grants art acceptance.

| Contract | Check |
| --- | --- |
| Family and framing | All five expected files are decoded RGBA PNG, exactly 2304×256; nine full 256×256 horizontal frames, no trimming |
| Nonempty padded frame | Every frame has nonzero alpha and at least one transparent outer pixel row/column |
| Alpha/support | Candidate alpha bytes and nonzero support mask match the same original frame exactly; every changed sample and maximum alpha delta is reported |
| Bounds and center | Nonzero-alpha bounds, area, box center and alpha-weighted pixel-center centroid are reported for both inputs; centroid delta and bounds equality are explicit |
| Index continuity | Each candidate frame's alpha fingerprint is compared to every original frame; cross-index matches expose a possible reorder. All nine original alpha fingerprints are distinct for each current kind. |
| Pivot and scale | Expected authored pivot is `(128,128)`, neutral index is 4. Every sheet uses that full-canvas pivot and the original kind's neutral scale for both versions, without trimming/recentering or candidate normalization. |

**Any alpha change fails by default, including antialiasing-only changes with identical support and bounds.** A new native source renderer may legitimately change edge samples; this remains an explicit failed strict comparison to review. There is no tolerance flag, automatic waiver, copied-original-alpha workaround or raster repair. If a broader geometry change is accepted later, preserve this report and establish a deliberately versioned contract through the coordinator.

PNG pixels cannot prove the original 3D camera, semantic tilt angles or authored object origin. The pivot entry is the required canvas contract; centroid stability is an observable diagnostic, not proof of an inferred optical/3D pivot. Source-renderer provenance and the intended angle sequence still need review. A shuffled RGB treatment with untouched alpha would require visual/source inspection even if the alpha gate passed.

Valid-dimension frames still receive comparison sheets when alpha differs, so a strict failure remains inspectable. Missing/corrupt/wrong-sized/mode/empty/border-invalid families receive a failed report with no new listed sheets. Only files named and hashed in that run's manifest/report are evidence; older sheets left in a reused output directory do not belong to a failed run.

## Advisory measurements

Each frame reports both file/frame hashes, changed RGBA pixels, changed pixels on the union of visible support, and RGB-only changes under zero alpha. Compression-only file differences can therefore be separated from decoded-pixel changes.

Highlight fractions reuse the original inspector: pixels with alpha ≥128 form the denominator; near-white requires minimum RGB ≥235 and RGB range ≤20; bright-low-chroma requires minimum RGB ≥210 and range ≤45. Signed candidate-minus-original differences are reported alongside mean encoded luma and HSV saturation. These are thresholds on encoded RGB, not linear-light or perceptual scores.

The optional grain diagnostic is the mean and 90th-percentile absolute encoded-luma residual between an interior pixel and the average of its four immediate neighbors, using only samples whose five alphas are all ≥250. It responds to intended facet boundaries, small highlights and texture as well as sampling noise. **A lower residual is not proof of less grain or better crystal quality.** It must not motivate blurring/repainting the finished atlas or sacrificing crisp facets.

## Inspection outputs and decision

The [self-control manifest](../../tools/art-quality/comparison/self/manifest.json) binds the machine report and four sheets:

- [Neutral pairs](../../tools/art-quality/comparison/self/neutral-paired.png): original left/candidate right within each kind, at 1 pixel per modeled point and 3 pixels per point on midnight, plum, light gray and grayscale.
- [All frames paired](../../tools/art-quality/comparison/self/all-frames-paired.png): original row above candidate row for every kind, same indexed layout and 3-pixels-per-point scale.
- [Neutral board](../../tools/art-quality/comparison/self/board-frame-4-paired.png) and [bright tap-frame board](../../tools/art-quality/comparison/self/board-frame-1-paired.png): identical synthetic 7×7 arrangements, original left/candidate right, current 0.37×pitch radius convention. They are neither reachable-state assertions nor game screenshots.

The baseline control neutral, all-frame and frame-1 board sheets were opened and inspected locally for paired layout, labels and spacing. Their copies visibly match. This is inspection of generated comparison sheets, not Apple rendering or physical phone size; viewer zoom and display DPI remain uncontrolled.

For an actual candidate, inspect neutral and the used `4,3,2,1,2,3,4` response first. Retain color identity through the bright face, believable facet changes, clear shape spacing, original pivots and settled appearance. Check the lower/right bevel grain on aqua/violet, rose's segmented reflection and mint corners without accepting a softer silhouette. Inspect dark/light alpha edges and the unused positive tilt half separately. Record concrete wins/regressions, structural failures and the source renderer identity; do not reduce the decision to a metric.

Native comparison, fractional positioning/filtering, movement, accessibility, memory and frame pacing remain with the active runtime/native owner after a candidate is selected. No simulator jobs were started by this lane.

## Checks actually performed

- Frozen five original PNGs and verified their manifest hashes against current input bytes.
- Ran all 45 original/self comparisons: strict pass, nine distinct alpha fingerprints per kind, zero changed RGBA/visible/alpha pixels.
- Ran synthetic self and single-color-change cases; checked a one-pixel translation produces centroid delta `(1,0)`, and an alpha-only change fails strict comparison despite equal bounds/support.
- Checked mismatched frame order, wrong PNG mode/dimensions, empty frame, nontransparent border, corrupt/missing file, frozen-hash tampering, malformed baseline manifest, input-directory protection, and a failed report that lists no artifacts.
- Recorded comparator/inspector hashes, Python/Pillow versions, exact source/file/frame/alpha hashes, output image hashes and a manifest binding `report.json` to its images.

Original asset/catalog and existing inspector/output bytes were not changed. Candidate evaluation remains pending its source-rendered output.

## Standalone merge verification

The completed validation package was checked against committed asset revision
`80d6975d2b7092cee7b89a870a83d041d6b98041`. A fresh temporary checkout was
assembled with `git archive` from that revision and only this package's 22
proposed files; no other untracked handoffs or reconstruction files were used.

In that checkout, the comparator self-test passed, the inspector audited all
45 committed frames, and a strict comparison of the frozen baseline against
the committed catalog passed. Both generated reports, the comparison manifest
and all eight review sheets were byte-identical to the retained evidence.
Every Markdown link in the package resolved using only those files and the
committed repository. The stored tool, source, frame, sheet and report hashes
were independently checked. No cache, temporary-render or candidate file is
part of the package. This verifies standalone local reproducibility with
Python 3.14.0 / Pillow 12.3.0, not native game rendering.
