# V2 recreation review — 2026-10-16

The five-color candidate family is ready for the runtime owner's integration review. This is new authored geometry, material, and lighting. Existing runtime PNGs, including the approved aqua, are byte-identical to the frozen baseline and were not replaced.

## Visual result

The narrowed, less tinted strip light and lower roughness produce a localized diagonal reflection with visible color around it. Aqua frame 1's advisory bright/low-chroma area changes from 19.9112% in the old render to 6.7651% in v2; this measurement supports the actual pixel review rather than defining artistic acceptance.

The parent and independent visual reviewer inspected the full 45-frame sheet, neutral/dark/light/grayscale/silhouette sheets, and modeled 34-point board. All five silhouettes and colors remain distinct. No blocking white-crown wash, visible interior grain, dark fringe, or overlap was found in those stills. Mint has the greatest apparent filled area and brightest body. Rose reads as a polished rounded disc. The family is stylized glazed crystal, not photoreal transparent/refractive glass.

- [All 45 tilt frames](current/tilt-review.png)
- [Neutral on dark/light and in grayscale](current/neutral-review.png)
- [Modeled board](current/board-review.png)
- [Original versus v2, all frames](comparison/all-frames-paired.png)
- [Original versus v2 board, frame 1](comparison/board-frame-1-paired.png)

## Grain control

[Sampling comparison](sampling-control/comparison.png) holds aqua geometry, lights, material, pose, and seed fixed. The deliberately noisy control uses 16 samples without denoising; the delivered frame uses 512 samples with OpenImageDenoise. The actual images show the cleaner surfaces while retaining the intended facet edges. The advisory mean neighbor-luma residual falls from 0.026213 to 0.0022584 at frame 4, and from 0.0292339 to 0.0023655 at frame 1. That proxy also responds to intentional edges and is not an independent measure of artistic quality. Sampling and denoising change together; this does not isolate their individual effects.

To reproduce the control, run the generator with `--kinds aqua --frames 4,1 --samples 16 --no-denoise` into a new temporary output directory. Source/settings hashes and measurements are in [the sampling report](sampling-control/report.json).

## Geometry and reproduction

All 45 alpha channels differ from the original. The old-alpha gate correctly reports `structural_pass: false` with 45 explicit geometry/antialiasing differences in [its report](comparison/report.json). The current-family image contract passes separately in [the inspection report](current/report.json). No crop, frame rescale, or alpha-box recentering was applied to the shipped pixels.

| Kind | Old neutral alpha bounds | V2 neutral alpha bounds |
| --- | --- | --- |
| Rose | 37,37–220,219 | 36,36–220,220 |
| Aqua | 34,34–222,222 | 34,34–222,222 |
| Amber | 47,37–209,180 | 46,37–210,180 |
| Violet | 40,30–216,226 | 41,30–215,226 |
| Mint | 56,56–200,200 | 56,56–200,200 |

The largest component of any old-to-new alpha-centroid shift is 0.42 source pixels (amber); every authored pivot remains 128,128. Bounds use top-left coordinates with right/bottom exclusive.

[Native scene reproduction](native-reproduction.json) records all five editable scenes reopening in Blender 5.2.2 LTS, all nine keyed poses, no linked libraries/unpacked image dependencies, unchanged source scene files, and exact neutral pixel reproduction. Independent Pillow decoding confirms exact RGBA8 samples for all five. File-byte hashes differ because Blender embeds timestamps and render timing; these differences remain in the report. Blender float hashes are same-host evidence, not portable image checksums.

[Portable source reproduction](portable-source-reproduction.json) records a clean directory containing only `generate_crystals.py` and `scene_settings.json` rebuilding aqua frame 4 exactly. No existing scene or image was an input.

## Remaining native acceptance

These are offline renders and presentation sheets. They do not establish SpriteKit sampling, motion smoothness, physical device size, GPU/memory use, accessibility behavior, or native gameplay acceptance. The runtime owner should adopt all five imagesets together in a separately verified change. This package leaves that active workstream untouched.
