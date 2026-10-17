# Crystal Glow body sources

`crystal-glow-bodies.png` is a transparent, faceless production plate generated with the built-in OpenAI image tool from the [approved cast study](../../docs/design/star-cast/crystal-glow/refinement.png). The [exact prompt](prompt.txt) removes faces intentionally: `StarCast` owns expressions and shallow yaw, so every expression retains one body silhouette and pivot. The six packaged 256-pixel bodies live in `App/Assets.xcassets/StarCast*.imageset`; sheets remain design references, not runtime atlases.

Run `tools/art-quality/package_star_cast.py` with Python/Pillow to repeat grid slicing, alpha-range normalization and centered aspect-preserving fitting. `packaging.json` records source and packaged hashes. This is offline asset packaging, never runtime artwork generation. No SDK, service or dependency is added to the app. Ground shadows stay in the scene, separate from the cutouts.
