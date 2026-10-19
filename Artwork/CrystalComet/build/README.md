# Build the sprite pack

Offline registration, depth projection, atlas export and validation tooling for the [Crystal Comet package](../README.md). These scripts are not app code or runtime dependencies. Preserve source images and regenerate the package rather than editing exported sprites.

Run from the repository root with Node and the workspace's bundled `sharp`, `@napi-rs/canvas` and `playwright` on `NODE_PATH`:

```sh
node Artwork/CrystalComet/build/register.cjs
node Artwork/CrystalComet/build/export.cjs
node Artwork/CrystalComet/build/make-preview.cjs
node Artwork/CrystalComet/build/check-preview.cjs
node Artwork/CrystalComet/build/validate.cjs
```

`register.cjs` owns component selection, contours and glyph metrics. `render.cjs` owns the geometric depth and lighting. `export.cjs` creates PNG atlases, frame maps and contact sheets. `make-preview.cjs` produces the self-contained viewer and animated WebP; repeated identical WebP frames may be coalesced while preserving duration.

The browser check uses installed Chrome (optional executable path as its first argument) and a temporary loopback server for canvas pixel assertions. The shipped viewer opens directly from disk. Run validation last: it checks every sprite, source hashes and detached punctuation, then seals the exact package file roster in `manifest.json`. These scripts overwrite generated outputs, so preserve a released package before changing sources.

`node Artwork/CrystalComet/build/native.cjs` derives the [native profile](../NATIVE.md) from the sealed pack, verifies its hashes, and writes the fifteen `CrystalDepth*.imageset` resources plus `CrystalDepthMetrics.dataset` into the existing asset catalog. `native-profile.json` records output hashes and raster budgets. This leaves the full-resolution pack unchanged.
