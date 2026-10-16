# Starfall crystal family v2

New editable Blender geometry, materials, lighting, and animation for the five Starfall jewels. This family recreates the visual direction from references; it does not reproduce the missing original source or promise identical silhouettes. No external model, texture, paid generation, or network dependency is used.

## Files

- `source/generate_crystals.py` and `source/scene_settings.json`: the complete procedural source.
- `renders/scenes/*.blend`: one self-contained editable scene per jewel, saved at neutral frame 4.
- `renders/frames/<kind>/frame_00.png` through `frame_08.png`: original Blender RGBA outputs.
- `renders/metadata/*.json`: source, settings, scene, and output hashes plus rendering configuration.
- `assets/*.imageset`: five packed runtime-compatible atlases with Xcode metadata.
- `manifest.json`: SHA-256 and byte counts for every package file except the manifest itself.
- `package.py`, `validate_package.py`, and `test_validate_package.py`: lossless packing, sealing, and structural checks.

## Frame contract

Each atlas is 2304 × 256 pixels: nine 256 × 256 transparent frames, left to right, neutral at index 4. The authored pivot is fixed at (128, 128). Frames retain their full canvas; neither packing nor review should recenter cropped alpha bounds. The five silhouettes are rose circle, aqua diamond, amber upward triangle, violet point-up hexagon, and mint square.

## Reproduce

Use Blender 5.2.2 LTS with Cycles CPU and Python 3 with Pillow for packing. Run from the repository root. The generator defaults to a two-frame aqua pilot; request the whole family explicitly:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --threads 4 --python-exit-code 1 \
  --python Artwork/Crystals/v2/source/generate_crystals.py -- \
  --kinds all --frames 0,1,2,3,4,5,6,7,8 --samples 512 \
  --output-dir /tmp/starfall-crystal-reproduction/renders
```

For a new complete package, copy this directory to a versioned destination, remove that copy's generated `renders/`, `assets/`, and manifest, and point `--output-dir` at its `renders/`. Then run:

```sh
python3 -B Artwork/Crystals/v2/package.py pack --root /path/to/new-package
python3 -B Artwork/Crystals/v2/package.py seal --root /path/to/new-package
python3 -B Artwork/Crystals/v2/validate_package.py /path/to/new-package
python3 -B -m unittest discover -s Artwork/Crystals/v2 -p 'test_*.py'
```

The generator refuses existing output files unless `--overwrite` is supplied. Keep originals and approved versions intact. Render settings use a fixed seed, 512 samples, OpenImageDenoise, and transparent film. Hardware or Blender version changes can affect pixels; render receipts record the actual build and hashes.

## Adoption boundary

This directory is an artwork handoff. It does not replace `App/Assets.xcassets` or enable any runtime feature. Native game acceptance, including actual phone sizing, motion, accessibility, and runtime loading, belongs to the separate integration workstream. The old alpha-equality comparator intentionally rejects new geometry; use its reported deltas for review rather than claiming a drop-in geometric match.

## Verification

The source pipeline has rendered the aqua pilot at neutral frame 4 and tilt frames 1 and 8 in Blender 5.2.2 LTS, Cycles CPU, at 128 samples with denoising. Nine focused synthetic validator tests pass, including resealed stale-receipt failures. Rendered deliverables and final reproduction evidence follow in a separate verified batch. Synthetic tests alone do not establish editable Blender scenes, visual quality, or native game acceptance.
