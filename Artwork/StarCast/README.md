# Crystal Glow body sources

`crystal-glow-bodies.png` is a transparent, faceless production plate generated with the built-in OpenAI image tool from the [approved cast study](../../docs/design/star-cast/crystal-glow/refinement.png). The [exact prompt](prompt.txt) removes faces intentionally: `StarCast` owns expressions and shallow yaw, so every expression retains one body silhouette and pivot. The six packaged 256-pixel bodies live in `App/Assets.xcassets/StarCast*.imageset`; sheets remain design references, not runtime atlases.

Run `tools/art-quality/package_star_cast.py` with Python/Pillow to repeat grid slicing, alpha-range normalization and centered aspect-preserving fitting. `packaging.json` records source and packaged hashes. This is offline asset packaging, never runtime artwork generation. No SDK, service or dependency is added to the app. Ground shadows stay in the scene, separate from the cutouts.

## Magnetic crystal and gravity hole

`magnet-body-v1.png` and `hole-body-v1.png` are original cutouts generated with the built-in OpenAI image tool for the production gravity mechanic. [Exact prompts](gravity-prompts-v1.json) and [source/package hashes](gravity-packaging.json) record provenance. These are faceless objects: the magnetic crystal has opposed gold tips and a teal waist; the hole has an opaque dark center and a blue-gold accretion ribbon.

Run `python3 tools/art-quality/package_star_cast.py --gravity` in a Python environment with Pillow to reproduce the two 256×256 catalog assets. This reuses the cast's alpha-island/padding/aspect normalization. No new image synthesis occurs in packaging; no creative edits were made after generation. The assets are `StarCastMagnet` and `StarCastHole`; one cached material per object serves board, flight and forecast. Source images remain unmodified. Art review is distinct from native visual/motion acceptance.
