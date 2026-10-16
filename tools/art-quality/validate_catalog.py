#!/usr/bin/env python3
"""Preflight Starfall crystal catalog files without building or modifying them."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path

from PIL import Image

from inspect_crystals import COUNT, KINDS, NEUTRAL, ROOT, SIDE

# The runtime family is adopted byte-for-byte from Artwork/Crystals/v2/manifest.json.
# The original aqua comparison remains separately frozen in comparison/baseline.
APPROVED_ATLAS_SHA256 = {
    "StarshardFamilyRose": "c34e81ad124efe049ade93add918701237cbed9a476ca0e72a8f87b20c0a8879",
    "StarshardFamilyAqua": "a187d78aba3d0dc2e678ab765a23d6eb424a7991eac64c91ea9b8cad6b0f8d13",
    "StarshardFamilyAmber": "aaa75c7ae2784923b5b6cffa31247e8e4f463f5005b1f9c8f5acaf809c03debf",
    "StarshardFamilyViolet": "c0c3f1cf80eeb479041362035c0b717c6a04a35f810d848bfbd17e293c95b2c9",
    "StarshardFamilyMint": "f40be6ac102cd73ffa946daaf62ab6f6e87f5e1ad942a743c5d8192568fdd984",
    "CrystalPilot": "a7e0d3c5154a3cb3c474307c876f6d87255fe9a38bc1c78f45081abb58490c2f",
}
EXPECTED = {f"StarshardFamily{kind.title()}": f"{kind}_tilt_atlas.png" for kind in KINDS}
EXPECTED["CrystalPilot"] = "aqua_tilt_atlas.png"


def checked_file(directory: Path, filename: str) -> Path:
    """Require a direct, exact-case filename, including on case-insensitive Macs."""
    if (not isinstance(filename, str) or not filename or filename in (".", "..")
            or any(character in filename for character in ("/", "\\", "\0"))
            or Path(filename).is_absolute()):
        raise ValueError("unsafe filename: expected a direct file within its imageset")
    if filename not in {path.name for path in directory.iterdir()}:
        raise ValueError(f"missing exact-case file {filename}")
    path = directory / filename
    if path.resolve().parent != directory.resolve():
        raise ValueError(f"{filename}: symlink resolves outside its imageset")
    if not path.is_file():
        raise ValueError(f"{filename}: not a readable regular file")
    return path


def inspect_set(catalog: Path, asset: str, filename: str) -> dict:
    record = {"asset": asset, "imageset": f"{asset}.imageset", "errors": []}
    directory = catalog / record["imageset"]
    try:
        if directory.name not in {path.name for path in catalog.iterdir()}:
            raise ValueError(f"missing exact-case image set {directory.name}")
        if not directory.is_dir() or directory.resolve().parent != catalog:
            raise ValueError("image set must be a directory inside the selected catalog")
        contents_path = checked_file(directory, "Contents.json")
        contents_raw = contents_path.read_bytes()
        record["contents_sha256"] = hashlib.sha256(contents_raw).hexdigest()
        contents = json.loads(contents_raw)
        if not isinstance(contents, dict):
            raise ValueError("Contents.json must contain a JSON object")
        entries = contents.get("images")
        if not isinstance(entries, list) or len(entries) != 1 or not isinstance(entries[0], dict):
            raise ValueError("Contents.json must contain exactly one image entry")
        entry = entries[0]
        reference = entry.get("filename")
        # Validate the declared reference before comparing it with the contract.
        path = checked_file(directory, reference)
        if reference != filename:
            raise ValueError(f"Contents.json references {reference!r}; expected {filename!r}")
        if entry.get("idiom") != "universal":
            raise ValueError("Contents.json image entry must have idiom 'universal'")
        info = contents.get("info")
        if not isinstance(info, dict) or type(info.get("version")) is not int or info["version"] != 1:
            raise ValueError("Contents.json info.version must be integer 1")
        raw = path.read_bytes()
        record.update(filename=reference, atlas_sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw))
        with Image.open(io.BytesIO(raw)) as image:
            if image.format != "PNG" or image.mode != "RGBA" or image.size != (SIDE * COUNT, SIDE):
                raise ValueError(f"{filename}: expected RGBA PNG, {SIDE * COUNT}x{SIDE}")
            image.load()
            bounds = []
            for index in range(COUNT):
                frame = image.crop((index * SIDE, 0, (index + 1) * SIDE, SIDE))
                box = frame.getchannel("A").getbbox()
                bounds.append(list(box) if box else None)
                if box is None:
                    record["errors"].append(f"frame {index}: empty")
                elif min(box[0], box[1], SIDE - box[2], SIDE - box[3]) < 1:
                    record["errors"].append(f"frame {index}: nontransparent outer border")
            record["frame_alpha_bounds"] = bounds
    except (OSError, ValueError, TypeError, SyntaxError, RuntimeError, Image.DecompressionBombError) as error:
        record["errors"].append(str(error))
    return record


def validate(catalog: Path) -> dict:
    catalog = catalog.resolve()
    report = {
        "schema": "starfall.crystal-catalog-preflight.v2",
        "catalog": str(catalog),
        "contract": {"family_kinds": list(KINDS), "frame_count": COUNT,
                     "frame_side_px": SIDE, "neutral_index": NEUTRAL,
                     "family_revision": "v2", "legacy_pilot_revision": "aqua-v1",
                     "approved_atlas_file_sha256": APPROVED_ATLAS_SHA256},
        "sets": {}, "errors": [],
        "limits": "Static catalog files only; no source integration, compiled bundle, UIImage loading, visual or native validation.",
    }
    if not catalog.is_dir():
        report["errors"].append("catalog directory is missing or is not a directory")
    else:
        for asset, filename in EXPECTED.items():
            record = inspect_set(catalog, asset, filename)
            report["sets"][asset] = record
            report["errors"].extend(f"{asset}: {error}" for error in record["errors"])
        for asset, approved_digest in APPROVED_ATLAS_SHA256.items():
            record = report["sets"][asset]
            digest = record.get("atlas_sha256")
            if digest is not None and digest != approved_digest:
                revision = "legacy aqua v1" if asset == "CrystalPilot" else "family v2"
                report["errors"].append(f"{asset}: PNG bytes differ from pinned approved {revision}")
        family_hash = report["sets"]["StarshardFamilyAqua"].get("atlas_sha256")
        pilot_hash = report["sets"]["CrystalPilot"].get("atlas_sha256")
        report["aqua_copies_identical"] = family_hash is not None and family_hash == pilot_hash
    report["passed"] = not report["errors"]
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--assets", type=Path, default=ROOT / "App/Assets.xcassets")
    parser.add_argument("--json", action="store_true", help="print the detailed machine-readable report")
    args = parser.parse_args()
    report = validate(args.assets)
    if args.json:
        print(json.dumps(report, indent=2))
    else:
        print(f"{'PASS' if report['passed'] else 'FAIL'}: {report['catalog']}")
        for error in report["errors"]:
            print(f"  - {error}")
        if report["passed"]:
            print("  Five v2 family image sets (45 frames) and distinct legacy aqua reference passed.")
        print(report["limits"])
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
