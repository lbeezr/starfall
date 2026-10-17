# Crystal artwork source

The editable replacement family lives in [v2](v2/README.md). Keep its Blender source, settings, native scenes, rendered frames, atlases, and checksums together in this versioned directory.

V2 is a new procedural recreation authorized on 2026-10-16 because the original scene could not be recovered. It is not a recovery of the original mesh. Existing `App/Assets.xcassets` images remain the runtime baseline until a separate integration change adopts a reviewed family.

The original pixel baseline is recorded in `tools/art-quality/comparison/baseline/`. Do not overwrite either generation in place when developing another look: create a new version or render experiments outside the repository.

## Package documentation boundary

The sealed v2 handoff’s [README](v2/README.md) and manifests explain its nested assets, Blender source/scenes, frame renders/metadata and review comparisons. Those folders inherit the package documentation; do not add per-folder READMEs or change checksummed contents merely for documentation coverage. Its historical handoff status is preserved; the [current root README](../../README.md) describes later runtime adoption.
