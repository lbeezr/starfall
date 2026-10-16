#!/usr/bin/env python3
"""Check a standalone recreated crystal package, offline, without modifying it.

Requires Python 3.9+ and Pillow. Every invocation reads current file bytes;
there is no cached-result mode and no dependency on the old app assets.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re

from PIL import Image

KINDS = ("rose", "aqua", "amber", "violet", "mint")
COUNT, SIDE, NEUTRAL = 9, 256, 4


def require(condition, message):
    if not condition:
        raise ValueError(message)


def checked_file(root, relative):
    """Require a portable exact-case regular file, with no symlink components."""
    require(isinstance(relative, str) and relative and
            not any(c in relative for c in ("\\", "\0", ":")), "invalid package path")
    parts = relative.split("/")
    require(all(part not in {"", ".", ".."} for part in parts), f"unsafe package path: {relative!r}")
    current = root
    for part in parts:
        require(current.is_dir() and part in {child.name for child in current.iterdir()},
                f"missing exact-case path: {relative}")
        current = current / part
        require(not current.is_symlink(), f"symlink is not a self-contained package file: {relative}")
    require(current.is_file(), f"not a regular file: {relative}")
    require(root in current.resolve().parents, f"path escapes package: {relative}")
    return current


def json_object(raw, label):
    value = json.loads(raw)
    require(isinstance(value, dict), f"{label}: expected a JSON object")
    return value


def rgba_png(raw, label, size):
    with Image.open(io.BytesIO(raw)) as opened:
        require(opened.format == "PNG" and opened.mode == "RGBA" and opened.size == size,
                f"{label}: expected RGBA PNG {size[0]}x{size[1]}")
        opened.load()
        return opened.copy()


def validate(root):
    root = Path(root).resolve()
    report = {
        "schema": "starfall.crystal-package-validation.v1",
        "package": str(root), "passed": False, "errors": [],
        "files_verified": 0, "atlases_verified": 0, "frames_verified": 0,
        "native_scene_headers_verified": 0, "kinds": {},
        "limits": "Current package bytes and structural checks only. Native .blend headers do not prove Blender editability, a full render reproduction, visual quality or native game acceptance. No equality to the old mesh/alpha is required.",
    }
    try:
        manifest_raw = checked_file(root, "manifest.json").read_bytes()
        manifest = json_object(manifest_raw, "manifest.json")
        report["manifest_sha256"] = hashlib.sha256(manifest_raw).hexdigest()
        require(manifest.get("schema") == "starfall.crystal-package.v1", "unsupported package manifest schema")
        provenance = manifest.get("provenance")
        require(isinstance(provenance, dict) and provenance.get("kind") == "new-native-recreation",
                "provenance.kind must state new-native-recreation")
        report["provenance_kind"] = provenance["kind"]
        names = manifest.get("kind_names")
        require(isinstance(names, list) and len(names) == len(KINDS) and set(names) == set(KINDS),
                "kind_names must contain each of the five expected kinds exactly once")
        for key, expected in (("frame_count", COUNT), ("frame_side", SIDE), ("neutral_index", NEUTRAL)):
            require(type(manifest.get(key)) is int and manifest[key] == expected,
                    f"manifest {key} must be integer {expected}")

        entries = manifest.get("files")
        require(isinstance(entries, list) and entries, "manifest files must be a nonempty list")
        verified = {}
        for entry in entries:
            require(isinstance(entry, dict), "manifest file entries must be objects")
            relative = entry.get("path")
            path = checked_file(root, relative)
            require(relative != "manifest.json", "manifest must not enumerate its own hash")
            require(relative not in verified, f"duplicate manifest path: {relative}")
            size, digest = entry.get("bytes"), entry.get("sha256")
            require(type(size) is int and size >= 0, f"{relative}: bytes must be a nonnegative integer")
            require(isinstance(digest, str) and re.fullmatch(r"[0-9a-f]{64}", digest),
                    f"{relative}: sha256 must be 64 lowercase hexadecimal characters")
            raw = path.read_bytes()
            require(len(raw) == size, f"{relative}: byte count differs from manifest")
            require(hashlib.sha256(raw).hexdigest() == digest, f"{relative}: SHA-256 differs from manifest")
            verified[relative] = raw
            report["files_verified"] += 1
        actual = set()
        for path in root.rglob("*"):
            relative = path.relative_to(root).as_posix()
            require(not path.is_symlink(), f"symlink is not allowed in package: {relative}")
            if path.is_file() and relative != "manifest.json":
                actual.add(relative)
        require(actual == set(verified),
                f"manifest inventory differs; unlisted={sorted(actual - set(verified))}, absent={sorted(set(verified) - actual)}")

        def file(relative):
            require(relative in verified, f"required package file missing: {relative}")
            raw = verified[relative]
            require(bool(raw), f"required package file is empty: {relative}")
            return raw

        file("source/generate_crystals.py")
        settings_path = "source/scene_settings.json"
        settings = json_object(file(settings_path), settings_path)
        require(settings.get("schema") == "starfall.crystal-v2-scene.v1", "unsupported source scene settings schema")
        report["source_settings"] = settings_path
        expected_frames = {f"renders/frames/{kind}/frame_{index:02d}.png" for kind in KINDS for index in range(COUNT)}
        require({path for path in verified if path.startswith("renders/frames/")} == expected_frames,
                "renders/frames must contain exactly the 45 expected individual PNGs")
        expected_assets = {f"assets/StarshardFamily{kind.title()}.imageset/{filename}"
                           for kind in KINDS for filename in (f"{kind}_tilt_atlas.png", "Contents.json")}
        require({path for path in verified if path.startswith("assets/")} == expected_assets,
                "assets must contain exactly the five expected atlas PNGs and Contents.json files")
        for kind in KINDS:
            scene_path = f"renders/scenes/{kind}.blend"
            scene = file(scene_path)
            require(len(scene) > 12 and re.fullmatch(rb"BLENDER[_-][vV][0-9]{3}", scene[:12]),
                    f"{scene_path}: expected an uncompressed native Blender header")
            report["native_scene_headers_verified"] += 1
            metadata_path = f"renders/metadata/{kind}.json"
            receipt = json_object(file(metadata_path), metadata_path)
            require(receipt.get("schema") == "starfall.crystal-v2-render.v1" and receipt.get("kind") == kind,
                    f"{metadata_path}: wrong receipt schema/kind")
            require(receipt.get("complete") is True, f"{metadata_path}: render receipt is incomplete")
            requested = receipt.get("requested_frames")
            require(isinstance(requested, list) and all(type(index) is int for index in requested) and
                    len(requested) == COUNT and set(requested) == set(range(COUNT)),
                    f"{metadata_path}: receipt must request all nine unique frames")
            for key, path in (("generator_sha256", "source/generate_crystals.py"), ("settings_sha256", settings_path)):
                require(receipt.get(key) == hashlib.sha256(file(path)).hexdigest(),
                        f"{metadata_path}: {key} differs from the included source")
            require(receipt.get("settings") == settings, f"{metadata_path}: recorded settings differ from included source")
            blend = receipt.get("blend")
            require(isinstance(blend, dict) and blend.get("path") == f"scenes/{kind}.blend" and
                    blend.get("sha256") == hashlib.sha256(scene).hexdigest(),
                    f"{metadata_path}: scene path/hash differs from the included scene")
            records = receipt.get("frames")
            require(isinstance(records, list) and len(records) == COUNT and all(isinstance(item, dict) for item in records),
                    f"{metadata_path}: receipt must enumerate nine frame records")
            indices = [item.get("index") for item in records]
            require(all(type(index) is int for index in indices) and set(indices) == set(range(COUNT)),
                    f"{metadata_path}: frame records must use each index exactly once")
            for item in records:
                path = f"frames/{kind}/frame_{item['index']:02d}.png"
                require(item.get("path") == path and item.get("sha256") == hashlib.sha256(file(f"renders/{path}")).hexdigest(),
                        f"{metadata_path}: frame {item['index']} path/hash differs from the included frame")
            directory = f"assets/StarshardFamily{kind.title()}.imageset"
            filename = f"{kind}_tilt_atlas.png"
            contents_path = f"{directory}/Contents.json"
            contents = json_object(file(contents_path), contents_path)
            images = contents.get("images")
            require(isinstance(images, list) and len(images) == 1 and isinstance(images[0], dict),
                    f"{contents_path}: expected exactly one image entry")
            require(images[0].get("filename") == filename and images[0].get("idiom") == "universal",
                    f"{contents_path}: expected universal image named {filename}")
            info = contents.get("info")
            require(isinstance(info, dict) and type(info.get("version")) is int and info["version"] == 1,
                    f"{contents_path}: info.version must be integer 1")
            atlas_path = f"{directory}/{filename}"
            atlas = rgba_png(file(atlas_path), atlas_path, (COUNT * SIDE, SIDE))
            measurements = []
            for index in range(COUNT):
                frame_path = f"renders/frames/{kind}/frame_{index:02d}.png"
                frame = rgba_png(file(frame_path), frame_path, (SIDE, SIDE))
                packed = atlas.crop((index * SIDE, 0, (index + 1) * SIDE, SIDE))
                require(frame.tobytes() == packed.tobytes(), f"{frame_path}: RGBA bytes differ from atlas slice {index}")
                box = frame.getchannel("A").getbbox()
                require(box is not None, f"{frame_path}: empty alpha")
                padding = min(box[0], box[1], SIDE - box[2], SIDE - box[3])
                require(padding >= 1, f"{frame_path}: nontransparent frame edge risks interframe bleed")
                measurements.append({"index": index, "alpha_bounds": list(box), "minimum_padding_px": padding})
                report["frames_verified"] += 1
            report["atlases_verified"] += 1
            report["kinds"][kind] = {"frames": measurements, "minimum_padding_px": min(item["minimum_padding_px"] for item in measurements)}
        report["passed"] = True
    except (OSError, UnicodeError, ValueError, TypeError, SyntaxError, RuntimeError, Image.DecompressionBombError) as error:
        report["errors"].append(str(error))
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("package", nargs="?", type=Path, default=Path(__file__).resolve().parent)
    args = parser.parse_args()
    report = validate(args.package)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
