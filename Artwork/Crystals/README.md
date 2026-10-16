# Crystal artwork source

The editable replacement family lives in [v2](v2/README.md). Keep its Blender source, settings, native scenes, rendered frames, atlases, and checksums together in this versioned directory.

V2 is a new procedural recreation authorized on 2026-10-16 because the original scene could not be recovered. It is not a recovery of the original mesh. Existing `App/Assets.xcassets` images remain the runtime baseline until a separate integration change adopts a reviewed family.

The original pixel baseline is recorded in `tools/art-quality/comparison/baseline/`. Do not overwrite either generation in place when developing another look: create a new version or render experiments outside the repository.
