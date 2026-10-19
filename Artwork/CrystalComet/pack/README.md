# Crystal Comet sprite pack 1.0.0

106 characters, 45 views per visible glyph, 4,725 sprites. Open `preview.html` locally to type a sample and play or inspect the exported angle frames. No server, network call, font installation or runtime library is needed by the viewer.

## Included

- `font.json`: character coverage, stable layout metrics, pivots and the 45-view index.
- `atlases/`: full-size transparent, straight-alpha sRGB PNGs; each view has its own independently loadable atlas, at most 1536 × 1536 pixels.
- `frames/`: exact pixel rectangles, baseline-origin offsets and pivots for each glyph at each view.
- `previews/`: character/angle contact sheets, an animated WebP, and smaller compressed views used only by the offline viewer.
- `provenance.json`, `validation.json`, `browser-validation.json`, `manifest.json`: generation prompts/source hashes, asset/browser checks and a closed file/hash roster.

## Character coverage and angles

All 95 printable ASCII characters: A–Z, a–z, 0–9, all 32 keyboard punctuation symbols and space. Eleven additional symbols: `– — ‘ ’ “ ” … × ÷ − •`. Space has a 64-unit advance and no image. This is not an installable font or universal Unicode coverage; accented letters are not included.

Yaw: −35° to +35°, every 5° (15 views). Pitch: −12°, 0°, +12°. Positive yaw reveals the left edge in this camera convention. Positive pitch reveals lower-facing surfaces. Ordinary in-plane rotation can be applied to a sprite without extra images.

Every angle uses the same front artwork and contour-derived shallow geometry. Front facets are painted; sides have directional lighting. This is the selected shallow-depth treatment, not a physically refractive model or independently generated angle pictures.

## Draw a string

Coordinates use source pixels with y increasing downward. At scale `s = desiredCapHeight / 160`:

1. Resolve a character to its Unicode key, for example `R` → `u0052`. Select a view from `font.json`, then its matching frame JSON and atlas.
2. Read the glyph's frame `rect`. Draw that source rectangle at `(penX + originOffset.x × s, baselineY + originOffset.y × s)`, sized `(rect.w × s, rect.h × s)`.
3. Advance `penX` by the glyph's `advance × s`. For optional tabular numerals, center the proportional glyph within its `tabularAdvance` and advance by that value instead. Missing characters should use a native text fallback.
4. Keep `advance` and the baseline fixed when changing views. The sprite pivot within the frame is `(pivot.x, pivot.y)`; the equivalent text-space pivot is in the glyph metrics. These offsets already account for angle-dependent trimming.

Cap height is 160 pixels, x-height 118, descenders 40 and suggested line height 230. Layout uses optical source ratios and proportional advances, with no comprehensive kerning table. Small text and connected-word rhythm require product-specific review.

## Import boundary

Use linear filtering without mipmaps; every frame has two transparent pixels around its artwork and two pixels of separation from neighboring frames. Do not derive spacing from changing frame rectangles. Load the needed angle views with a bounded cache instead of eagerly decoding all 45 full atlases. The offline preview uses smaller WebP copies, not app resources.

The package is validated as an asset deliverable. No SpriteKit/SwiftUI integration, native GPU/performance test, full VoiceOver session or physical-device acceptance is claimed. The original Starfall app is unchanged.

## Provenance

Front artwork was generated with the built-in ImageGen tool for Starfall. The approved ten-glyph specimen is retained exactly as the source for `Relay!+128`; new sheets extend that family. The question mark, division sign and capital Z were repaired after inspection. Exact prompts, source identities and fingerprints are in `provenance.json`. No third-party font or purchased artwork is included; provenance does not assert exclusive copyright in generated imagery or assign a third-party license.
