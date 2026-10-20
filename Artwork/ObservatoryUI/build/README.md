# Utility glyph exporter

`glyphs.py` regenerates only the utility glyph exports, `glyph-manifest.json` and `previews/glyphs.png`. The 20 SVGs in `../masters/glyphs/` are the source of truth. No app resource membership is changed.

Run with a Python that already has Pillow, ReportLab and pypdfium2, and a Node runtime that already has Sharp. No dependency installation is part of this exporter:

```sh
python3 Artwork/ObservatoryUI/build/glyphs.py --node /path/to/node --node-modules /path/to/node_modules
```

The optional `--font` and `--bold-font` arguments select local fonts used only for preview captions. They default to the macOS Arial fonts; these fonts are neither copied nor included in the asset kit.

The SVG vocabulary is intentionally limited to explicit absolute `M`, `L`, `H`, `V`, `C`, `Z` paths, circles and rounded rectangles. The exporter rejects unsupported constructs. ReportLab translates this vocabulary directly to stroked vector PDF paths; Sharp renders transparent PNG templates. Each SVG uses a 24-unit viewBox, a 1.5-unit `currentColor` stroke, round caps and joins, and no fill.

Each run validates XML, dimensions, transparent outer frames, black template ink, and PDF page bounds with no raster images. PDFium independently renders every PDF at 12x, and the weighted alpha intersection-over-union against the SVG rendition must be at least 0.95, allowing ordinary edge antialiasing differences. The manifest records this comparison, source/export hashes and measured alpha bounds. The preview renders actual 20, 24 and 32 pixel samples on dark and light fields, plus enlarged SVG/PDF pairs for comet, settings and calm. Captions are review furniture, not proposed game typography. These checks do not establish native optical alignment, device contrast, accessibility, touch-target size or app integration.
