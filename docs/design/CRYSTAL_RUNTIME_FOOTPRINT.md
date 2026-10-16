# Crystal runtime footprint — static review

Reviewed 2026-10-16 at `e84a70d57f2defa8c58ef7cd87ec128e1733fcdb`, before runtime adoption of v2. The five live `App/Assets.xcassets/StarshardFamily*.imageset` PNGs still matched the frozen originals. No unbounded texture-cache defect or registration of offline artwork files was found in this snapshot. Runtime integration is a separate workstream; recheck the references below if its loader or resource graph changes.

The v2 family saves **641,775 bytes (36.35%) of source PNG data**. Its dimensions and logical RGBA8 pixel cost are unchanged. This review did not run a build, simulator, Instruments or GPU capture: these figures are **not compiled asset size, GPU allocation, resident memory or peak memory measurements**.

## Files and pixel arithmetic

Compared the hash-verified [frozen baseline](../../tools/art-quality/comparison/baseline/manifest.json) with the sealed [v2 package](../../Artwork/Crystals/v2/manifest.json). All ten atlases are 2304 × 256 RGBA PNGs containing nine 256 × 256 frames.

| Kind | Original PNG bytes | v2 PNG bytes | Difference |
|---|---:|---:|---:|
| Rose | 402,153 | 260,429 | −141,724 |
| Aqua | 349,758 | 237,725 | −112,033 |
| Amber | 262,612 | 172,296 | −90,316 |
| Violet | 426,092 | 253,186 | −172,906 |
| Mint | 324,903 | 200,107 | −124,796 |
| **Five atlases** | **1,765,518** | **1,123,743** | **−641,775** |

The five v2 `Contents.json` files add 798 bytes, making `v2/assets/` 1,124,541 bytes. PNG compression is only the on-disk encoding; these savings do not establish a decoded-memory improvement.

| Logical RGBA8 content | Calculation | Bytes | MiB (2²⁰ bytes) |
|---|---|---:|---:|
| One frame | 256 × 256 × 4 | 262,144 | 0.25 |
| One atlas / its nine frames | 2304 × 256 × 4 | 2,359,296 | 2.25 |
| Five atlases / 45 frames | 5 × 9 × 256 × 256 × 4 | 11,796,480 | 11.25 |
| Twenty neutral fragments | 5 × 4 × 128 × 128 × 4 | 1,310,720 | 1.25 |
| **Family's 65 textures** | **45 frames + 20 fragments** | **13,107,200** | **12.5** |

The atlas row and frame row describe the same source pixel content, not proof of two simultaneous allocations. Actual UIKit/CoreGraphics/SpriteKit backing-store sharing, source-image retention, upload copies, alignment and driver storage were not measured. The family loader explicitly disables mipmaps. Its alpha-bound scan creates a 262,144-byte scratch buffer per invocation; that scratch size does not establish decode peak memory. See [`StarshardArtwork.decode` and `alphaBounds`](../../App/StarshardArtwork.swift).

## Loading and retention boundaries

[`StarshardArtwork`](../../App/StarshardArtwork.swift) maps the five cases in [`Jewel`](../../Sources/StarfallCore/Game.swift) to fixed asset names. The production call site uses its shared instance. Each kind caches either one `FrameSet` or an unavailable result, so repeated requests do not retry missing files or create additional frame sets. Each successful set contains nine independent frame textures and four fragment textures, with linear filtering and no mipmaps.

[`JewelScene`](../../App/JewelScene.swift) loads the complete family lazily after DEBUG opt-in; any missing kind leaves the scene on its existing material path. A partial failed load can retain the successfully cached subset, but still has at most five keys. Board nodes, tilt arrays and shard nodes reference these textures; board size, cell radius, taps, restarts and scene instances are not cache keys. The 48-shard limit bounds concurrently requested shard nodes, not the number of distinct fragment textures.

Two separate finite caches can also exist: the fallback factory stores at most five 256 × 256 textures (128-point renderer at scale 2; 1.25 MiB logical RGBA8), and [`CrystalPilot`](../../App/CrystalPilot.swift) stores nine aqua frames plus four fragments (2.5 MiB logical RGBA8). These static caches persist after loading. If all three paths have been used in one process, their declared texture content sums to 16.25 MiB; this is neither a measured simultaneous allocation nor an app-memory ceiling. No per-tap, per-resize or per-restart texture accumulation was shown by the reviewed code.

## Resource registration

Parsed [`project.pbxproj`](../../Starfall.xcodeproj/project.pbxproj) as a property list and followed the Starfall target's `buildPhases` → `PBXResourcesBuildPhase.files` → `PBXBuildFile.fileRef` → group-relative paths. The resource inputs are `Config/PrivacyInfo.xcprivacy`, `App/Assets.xcassets` and `App/Audio`. There are no copy-files phases, shell-script phases or synchronized-root groups in this project. [`Package.swift`](../../Package.swift) declares only Core and its tests, with no resources; [`Clean.xcconfig`](../../Config/Clean.xcconfig) adds no resource copy step.

Consequently, **this source graph does not register `Artwork/`, `docs/` or `tools/` for the app bundle**. The offline v2 directory contains 92 files / 11,286,181 bytes: five Blender scenes alone are 2,782,767 bytes, individual renders are 2,051,351 bytes, and review material is 5,227,410 bytes. Registering that entire folder as a copied resource would add much more than the intended five imagesets. No such registration is present, so no corrective project change is proposed.

The existing catalog is a resource input for both Debug and Release. `#if DEBUG` prevents the current pilot activation in Release; it does **not** establish exclusion of pilot images from asset compilation. Also, `CrystalPilot.imageset` contains a byte-identical copy of original aqua (349,758 source bytes) alongside `StarshardFamilyAqua.imageset`. Whether the compiler deduplicates or transforms it was not inspected. These are shipping considerations for runtime adoption, not evidence of an unbounded cache or accidental Blender-scene inclusion.

## Reproduce and identify the snapshot

From the repository root, using the existing Python/Pillow dependency:

```sh
python3 -B - <<'PY'
from pathlib import Path
from PIL import Image
import hashlib, json
baseline = Path('tools/art-quality/comparison/baseline')
package = Path('Artwork/Crystals/v2')
old_manifest = json.loads((baseline / 'manifest.json').read_text())
new_manifest = {f['path']: f for f in json.loads((package / 'manifest.json').read_text())['files']}
totals = [0, 0]
for kind in ['rose', 'aqua', 'amber', 'violet', 'mint']:
    relative = f'StarshardFamily{kind.title()}.imageset/{kind}_tilt_atlas.png'
    sizes = []
    for root, rel, expected in [
        (baseline, relative, old_manifest['kinds'][kind]['file_sha256']),
        (package, 'assets/' + relative, new_manifest['assets/' + relative]['sha256'])
    ]:
        path = root / rel
        assert hashlib.sha256(path.read_bytes()).hexdigest() == expected
        with Image.open(path) as image:
            assert image.mode == 'RGBA' and image.size == (2304, 256)
        sizes.append(path.stat().st_size)
    totals = [a + b for a, b in zip(totals, sizes)]
    print(kind, *sizes, sizes[1] - sizes[0])
print('total', *totals, totals[1] - totals[0], (totals[1] / totals[0] - 1) * 100)
print('family RGBA8 bytes', 5 * (9 * 256 * 256 + 4 * 128 * 128) * 4)
for name in ['assets', 'source', 'renders/scenes', 'renders/frames', 'review', '.']:
    files = [p for p in (package / name).rglob('*') if p.is_file()]
    print(name, len(files), sum(p.stat().st_size for p in files))
PY
plutil -convert json -o - Starfall.xcodeproj/project.pbxproj
```

SHA-256 pins for the reviewed integration boundaries and input manifests:

| File | SHA-256 |
|---|---|
| `App/StarshardArtwork.swift` | `bec715a1cb84987a4b03366176484b471af26438ee0a7c4ba44a81966967ceac` |
| `App/JewelScene.swift` | `ec8f551952e0b0de6b82ff54691aedc0c21aef7a96d25d6806e4ca4fbcea17eb` |
| `App/CrystalPilot.swift` | `2ea7e4da9fa4bbb8842c8746110b5b9a6459f2666e67ae5b12dbed1401735699` |
| `Starfall.xcodeproj/project.pbxproj` | `c90374e23d7e5f7ee8b952de6c154acc8bebd21825045eb56593340d6a9d4a45` |
| `tools/art-quality/comparison/baseline/manifest.json` | `325a4bfe31ca3e0918ce5e35d4ae0e5f3b223dbc02b22fce1e22948ff0038ff1` |
| `Artwork/Crystals/v2/manifest.json` | `bc4c53cf13f1e3a68fb1fc13ba55aa9908c13cae791a19c37cf47c161991864c` |

The remaining referenced source files are identified by the reviewed commit above. Manifest hashes were checked against all ten atlas files, image modes/dimensions were opened locally, and the resource graph was inspected structurally. No device performance or compiled-bundle acceptance is implied.
