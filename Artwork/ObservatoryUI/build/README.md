# Utility artwork exporters

`rendered_utilities.py` owns the current full-color utility family. The original `glyphs.py` retains the historical vector family and does not change app resource membership. [Rendered utility provenance and review](../RENDERED_UTILITIES.md) records the new family’s sources, registration and acceptance limits.

## Rendered utility family

Run with Python 3 and an existing Node/Sharp installation:

```sh
python3 Artwork/ObservatoryUI/build/rendered_utilities.py --node /path/to/node --node-modules /path/to/node_modules --check-only
python3 Artwork/ObservatoryUI/build/rendered_utilities.py --node /path/to/node --node-modules /path/to/node_modules --catalog-root App/Assets.xcassets/ObservatoryUI
python3 Artwork/ObservatoryUI/build/test_rendered_utilities.py --node /path/to/node --node-modules /path/to/node_modules
```

The exact twenty PNG masters live in `../masters/utilities-v2/`, named for `ObservatoryGlyph` raw values. Their `PROMPTS.json` supplies one `key`, `master` filename, original `source`, `sourceSHA256`, and exact `prompt` per entry, with `version: 1` and `generator: "Built-in ImageGen"`. Hashes must match unchanged source bytes. Partial or unexpected rosters, absent alpha, visible edge clipping, oversized files and linked output paths are rejected.

Visible-subject bounds use alpha ≥16 plus four source pixels of bleed. The crop retains its colors and alpha, then receives ordinary proportional Lanczos resampling into a 20-point content region on a transparent 24-point canvas. The manifest records alpha ≥1/16/128 bounds, the crop, padding, and count/maximum/sum of discarded low-alpha pixels. It does not claim those faint pixels were fully transparent. Original masters remain unchanged.

The exporter writes `../exports/utilities-v2/` at 1×/2×/3×, `../rendered-utility-manifest.json`, and separate small-size/source-canvas PNG specimens under `../previews/`. All assets validate in temporary storage before publication. `--check-only` publishes nothing; omitting `--catalog-root` changes only the source kit. Explicit catalog replacement retains the twenty `ObservatoryGlyph…` names, registers original-color density PNGs and removes only their old `glyph.pdf` payloads. Historical SVG/PDF masters and exports are retained. Runtime byte budgets exclude the review specimens, which never enter the app catalog.

Eight behavioral checks exercise real temporary PNG exports, byte-identical repetition, small-size/source preview identity, no-write validation, original-source hashes, visible versus faint-alpha clipping, complete provenance, and rejection of unowned catalog entries or symlink redirection. They do not run Apple tools or certify native rendering.

## Historical vector family

`glyphs.py` regenerates only the historical utility glyph exports, `glyph-manifest.json` and `previews/glyphs.png`. The 20 SVGs in `../masters/glyphs/` remain the source of truth for that family.

Run with a Python that already has Pillow, ReportLab and pypdfium2, and a Node runtime that already has Sharp. No dependency installation is part of this exporter:

```sh
python3 Artwork/ObservatoryUI/build/glyphs.py --node /path/to/node --node-modules /path/to/node_modules
```

The optional `--font` and `--bold-font` arguments select local fonts used only for preview captions. They default to the macOS Arial fonts; these fonts are neither copied nor included in the asset kit.

The SVG vocabulary is intentionally limited to explicit absolute `M`, `L`, `H`, `V`, `C`, `Z` paths, circles and rounded rectangles. The exporter rejects unsupported constructs. ReportLab translates this vocabulary directly to stroked vector PDF paths; Sharp renders transparent PNG templates. Each SVG uses a 24-unit viewBox, a 1.5-unit `currentColor` stroke, round caps and joins, and no fill.

Each run validates XML, dimensions, transparent outer frames, black template ink, and PDF page bounds with no raster images. PDFium independently renders every PDF at 12x, and the weighted alpha intersection-over-union against the SVG rendition must be at least 0.95, allowing ordinary edge antialiasing differences. The manifest records this comparison, source/export hashes and measured alpha bounds. The preview renders actual 20, 24 and 32 pixel samples on dark and light fields, plus enlarged SVG/PDF pairs for comet, settings and calm. Captions are review furniture, not proposed game typography. These checks do not establish native optical alignment, device contrast, accessibility, touch-target size or app integration.
