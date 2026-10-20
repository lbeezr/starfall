# Crystal Glow body sources

## Faceless gameplay pieces

`shards-bodies-v1.png` is the seven-piece transparent production source generated with the built-in OpenAI image tool from the [approved character/piece board](../../docs/design/star-cast/characters-and-shards-2026-10-20/pairing-v2-opal.png). Its [exact prompt](shards-prompt-v1.txt) preserves the selected silhouettes and colors while removing all faces, labels and surrounding light. Original generated file: `exec-2ff72747-057f-4380-b27c-60ab2cf300f0.png`; the source is copied byte-for-byte.

Run `python3 tools/art-quality/package_star_cast.py --shards` with Pillow to reproduce the seven `SkyPiece{Name}` image sets. The [packaging receipt](shards-packaging.json) records source/prompt/output hashes, explicit crop regions, 256-pixel canvas, centered pivot and 208-pixel maximum body span. Fixed equal grid slicing would clip Nova's right tip, so extraction regions follow the actual source spacing. The shared packager isolates the connected body and fits it without repainting. All seven assets are faceless; Opal is a round pearl. Material shading is baked into the bodies; fall/contact transforms and the grown aura belong to the renderer. See the [motion contract](../../docs/design/star-cast/characters-and-shards-2026-10-20/MOTION.md).

The original `StarCast` assets below remain the face-bearing character sources for story and ceremony. Gameplay has a separate material role; historical gravity objects retain their existing cutouts.

## Original character bodies

`crystal-glow-bodies.png` is a transparent, faceless production plate generated with the built-in OpenAI image tool from the [approved cast study](../../docs/design/star-cast/crystal-glow/refinement.png). The [exact prompt](prompt.txt) removes faces intentionally: `StarCast` owns expressions and shallow yaw, so every expression retains one body silhouette and pivot. The six packaged 256-pixel bodies live in `App/Assets.xcassets/StarCast*.imageset`; sheets remain design references, not runtime atlases.

Run `tools/art-quality/package_star_cast.py` with Python/Pillow to repeat grid slicing, alpha-range normalization and centered aspect-preserving fitting. `packaging.json` records source and packaged hashes. This is offline asset packaging, never runtime artwork generation. No SDK, service or dependency is added to the app. Floating cast and pieces have no ground shadows; light effects remain separate from the cutouts.

## Magnetic crystal and gravity hole

**Historical magnetic-crystal direction:** superseded by the open attraction field below. The hole remains current.

`magnet-body-v1.png` and `hole-body-v1.png` are original cutouts generated with the built-in OpenAI image tool for the production gravity mechanic. [Exact prompts](gravity-prompts-v1.json) and [source/package hashes](gravity-packaging.json) record provenance. These are faceless objects: the magnetic crystal has opposed gold tips and a teal waist; the hole has an opaque dark center and a blue-gold accretion ribbon.

Run `python3 tools/art-quality/package_star_cast.py --gravity` in a Python environment with Pillow to reproduce the two 256×256 catalog assets. This reuses the cast's alpha-island/padding/aspect normalization. No new image synthesis occurs in packaging; no creative edits were made after generation. The assets are `StarCastMagnet` and `StarCastHole`; one cached material per object serves board, flight and forecast. Source images remain unmodified. Art review is distinct from native visual/motion acceptance.

## Attraction field revision

The user rejected the solid magnetic star silhouette. Current `StarCastField` replaces `StarCastMagnet` with an open aura: [generated source](field-body-v1.png), [exact built-in imagegen prompt](attraction-field-prompt-v1.txt), and the current [gravity packaging receipt](gravity-packaging.json). `package_star_cast.py --gravity` now packages Field and Hole. Field preserves both wisps and disconnected motes without largest-island pruning, fits alpha ≥16 to the same padded 256-pixel canvas, and requires a transparent center; Hole retains its opaque-center and island rules. The original magnetic crystal source and prompt remain historical provenance, but its runtime image set is removed.
