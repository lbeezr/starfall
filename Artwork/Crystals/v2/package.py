#!/usr/bin/env python3
"""Pack untouched Blender frames into sprite atlases and seal this source package."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
KINDS = ("rose", "aqua", "amber", "violet", "mint")


def pack(root: Path) -> None:
    for kind in KINDS:
        atlas = Image.new("RGBA", (2304, 256))
        for index in range(9):
            path = root / "renders" / "frames" / kind / f"frame_{index:02d}.png"
            with Image.open(path) as frame:
                if frame.mode != "RGBA" or frame.size != (256, 256):
                    raise ValueError(f"Invalid frame: {path}")
                # Paste all channels verbatim; no resampling or alpha compositing.
                atlas.paste(frame, (index * 256, 0))
        target = root / "assets" / f"StarshardFamily{kind.title()}.imageset"
        target.mkdir(parents=True, exist_ok=True)
        filename = f"{kind}_tilt_atlas.png"
        atlas.save(target / filename, compress_level=9)
        metadata = {"images": [{"filename": filename, "idiom": "universal"}],
                    "info": {"author": "xcode", "version": 1}}
        (target / "Contents.json").write_text(json.dumps(metadata, indent=2) + "\n")


def seal(root: Path) -> None:
    entries = []
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"Package symlink is not allowed: {path}")
        if not path.is_file() or path == root / "manifest.json":
            continue
        if "__pycache__" in path.parts or path.name == ".DS_Store":
            raise ValueError(f"Remove incidental cache before sealing: {path}")
        data = path.read_bytes()
        entries.append({"path": path.relative_to(root).as_posix(), "bytes": len(data),
                        "sha256": hashlib.sha256(data).hexdigest()})
    manifest = {
        "schema": "starfall.crystal-package.v1",
        "name": "Starfall crystal family", "version": 2,
        "provenance": {
            "kind": "new-native-recreation",
            "authorization": "User authorized recreating the missing-source assets on 2026-10-16.",
            "authorship": "New procedural Blender geometry, materials and lighting authored for Starfall; no third-party models, textures or paid generation.",
            "original_source_recovered": False,
            "runtime_adopted": False,
        },
        "kind_names": list(KINDS), "frame_count": 9,
        "frame_side": 256, "neutral_index": 4,
        "files": entries,
    }
    (root / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Sealed {len(entries)} files; {sum(entry['bytes'] for entry in entries)} bytes")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("pack", "seal"))
    parser.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    root = args.root.resolve()
    (pack if args.action == "pack" else seal)(root)


if __name__ == "__main__":
    main()
