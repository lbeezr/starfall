"""Structural validator tests, using only synthetic temporary packages.

The fake .blend header payloads are deliberately not editable Blender scenes.
These tests never render, install assets, or claim visual/native acceptance.
"""
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

from PIL import Image, ImageDraw

SPEC = importlib.util.spec_from_file_location("crystal_package_validator", Path(__file__).with_name("validate_package.py"))
validator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validator)


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value))


def seal(root):
    manifest = json.loads((root / "manifest.json").read_text()) if (root / "manifest.json").exists() else {
        "schema": "starfall.crystal-package.v1", "provenance": {"kind": "new-native-recreation"},
        "kind_names": list(validator.KINDS), "frame_count": 9, "frame_side": 256, "neutral_index": 4,
    }
    manifest["files"] = [
        {"path": path.relative_to(root).as_posix(), "bytes": len(path.read_bytes()),
         "sha256": hashlib.sha256(path.read_bytes()).hexdigest()}
        for path in sorted(root.rglob("*")) if path.is_file() and path.name != "manifest.json"
    ]
    write_json(root / "manifest.json", manifest)


class PackageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.base_directory = tempfile.TemporaryDirectory(prefix="starfall-synthetic-crystal-base-")
        cls.base = Path(cls.base_directory.name)
        (cls.base / "source").mkdir()
        (cls.base / "source/generate_crystals.py").write_text("# Synthetic fixture; not a render generator.\n")
        settings = {"schema": "starfall.crystal-v2-scene.v1", "synthetic_fixture": True}
        write_json(cls.base / "source/scene_settings.json", settings)
        for kind in validator.KINDS:
            frames = cls.base / f"renders/frames/{kind}"
            frames.mkdir(parents=True)
            atlas = Image.new("RGBA", (2304, 256))
            for index in range(9):
                frame = Image.new("RGBA", (256, 256))
                ImageDraw.Draw(frame).rectangle((40 + index, 40, 200, 200), fill=(index * 20, 100, 150, 255))
                frame.save(frames / f"frame_{index:02d}.png")
                atlas.paste(frame, (index * 256, 0))
            asset = cls.base / f"assets/StarshardFamily{kind.title()}.imageset"
            asset.mkdir(parents=True)
            filename = f"{kind}_tilt_atlas.png"
            atlas.save(asset / filename)
            write_json(asset / "Contents.json", {"images": [{"filename": filename, "idiom": "universal"}], "info": {"version": 1}})
            scene = cls.base / f"renders/scenes/{kind}.blend"
            scene.parent.mkdir(parents=True, exist_ok=True)
            scene.write_bytes(b"BLENDER-v500SYNTHETIC TEST FIXTURE ONLY")
            cls.receipt(cls.base, kind, settings)
        seal(cls.base)

    @staticmethod
    def receipt(root, kind, settings=None):
        if settings is None:
            settings = json.loads((root / "source/scene_settings.json").read_text())
        digest = lambda path: hashlib.sha256((root / path).read_bytes()).hexdigest()
        write_json(root / f"renders/metadata/{kind}.json", {
            "schema": "starfall.crystal-v2-render.v1", "kind": kind, "complete": True,
            "requested_frames": list(range(9)), "settings": settings,
            "generator_sha256": digest("source/generate_crystals.py"),
            "settings_sha256": digest("source/scene_settings.json"),
            "blend": {"path": f"scenes/{kind}.blend", "sha256": digest(f"renders/scenes/{kind}.blend")},
            "frames": [{"index": index, "path": f"frames/{kind}/frame_{index:02d}.png",
                        "sha256": digest(f"renders/frames/{kind}/frame_{index:02d}.png")} for index in range(9)],
        })

    @classmethod
    def tearDownClass(cls):
        cls.base_directory.cleanup()

    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="starfall-synthetic-crystal-case-")
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name) / "package"
        shutil.copytree(self.base, self.root)

    def report(self):
        return validator.validate(self.root)

    def fails(self, message):
        report = self.report()
        self.assertFalse(report["passed"], report)
        self.assertIn(message, " ".join(report["errors"]))

    def edit_manifest(self, mutate):
        path = self.root / "manifest.json"
        value = json.loads(path.read_text())
        mutate(value)
        write_json(path, value)

    def change_frame_and_atlas(self, frame):
        frame.save(self.root / "renders/frames/rose/frame_00.png")
        path = self.root / "assets/StarshardFamilyRose.imageset/rose_tilt_atlas.png"
        with Image.open(path) as opened:
            atlas = opened.copy()
        atlas.paste(frame, (0, 0))
        atlas.save(path)
        self.receipt(self.root, "rose")
        seal(self.root)

    def test_complete_structure_and_fresh_repeatable_output(self):
        first = self.report()
        self.assertTrue(first["passed"], first["errors"])
        self.assertEqual(first["atlases_verified"], 5)
        self.assertEqual(first["frames_verified"], 45)
        self.assertEqual(first["native_scene_headers_verified"], 5)
        self.assertEqual(first, self.report())
        self.assertEqual(first["kinds"]["rose"]["minimum_padding_px"], 40)
        self.assertIn("do not prove Blender editability", first["limits"])

    def test_hash_tamper_and_unlisted_file(self):
        path = self.root / "source/generate_crystals.py"
        original = path.read_bytes()
        path.write_bytes(original.replace(b"Synthetic", b"synthetic"))
        self.fails("SHA-256 differs")
        path.write_bytes(original)
        (self.root / "unexpected.txt").write_text("unlisted")
        self.fails("manifest inventory differs")

    def test_observed_blender_522_headers_are_accepted(self):
        for kind in validator.KINDS:
            scene = self.root / f"renders/scenes/{kind}.blend"
            scene.write_bytes(validator.BLENDER_522_HEADER + b"REND SYNTHETIC TEST FIXTURE ONLY")
            self.receipt(self.root, kind)
        seal(self.root)
        report = self.report()
        self.assertTrue(report["passed"], report["errors"])
        self.assertEqual(report["native_scene_headers_verified"], 5)

    def test_malformed_and_truncated_native_headers_are_rejected(self):
        header = validator.BLENDER_522_HEADER
        variants = [header[:length] for length in range(1, len(header) + 1)]
        variants += [b"BLENDER-v500", b"BLENDER-v50", b"BLENDER-vXYZpayload",
                     b"BLENDER17-01v0503REND", b"BLENDER17-02v0502REND",
                     b"BLENDER17-01V0502REND", b"BLENDER16-01v0502REND"]
        for data in variants:
            with self.subTest(header=data):
                (self.root / "renders/scenes/rose.blend").write_bytes(data)
                self.receipt(self.root, "rose")
                seal(self.root)
                self.fails("native Blender header")

    def test_manifest_traversal_absolute_and_duplicate_paths(self):
        original = (self.root / "manifest.json").read_bytes()
        for invalid in ("../outside.png", "/tmp/outside.png", "source/../outside.png", "source\\outside.png", "C:/outside.png"):
            with self.subTest(path=invalid):
                self.edit_manifest(lambda value: value["files"][0].update(path=invalid))
                self.assertFalse(self.report()["passed"])
                (self.root / "manifest.json").write_bytes(original)
        self.edit_manifest(lambda value: value["files"].append(value["files"][0]))
        self.fails("duplicate manifest path")

    def test_symlink_and_exact_case_rejected(self):
        path = self.root / "source/generate_crystals.py"
        original = path.read_bytes()
        path.unlink()
        path.symlink_to(self.base / "source/generate_crystals.py")
        self.fails("symlink")
        path.unlink()
        path.write_bytes(original)
        path.rename(path.with_name("Generate_crystals.py"))
        self.fails("missing exact-case path")

    def test_frame_pixels_are_compared_after_hashes_are_resealed(self):
        path = self.root / "renders/frames/rose/frame_00.png"
        with Image.open(path) as opened:
            frame = opened.copy()
        frame.putpixel((100, 100), (255, 0, 255, 255))
        frame.save(path)
        self.receipt(self.root, "rose")
        seal(self.root)
        self.fails("RGBA bytes differ")

    def test_empty_and_edge_alpha_rejected(self):
        self.change_frame_and_atlas(Image.new("RGBA", (256, 256)))
        self.fails("empty alpha")
        frame = Image.new("RGBA", (256, 256))
        frame.putpixel((0, 128), (100, 150, 200, 1))
        self.change_frame_and_atlas(frame)
        self.fails("nontransparent frame edge")

    def test_wrong_png_shape_mode_and_contents_reference(self):
        path = self.root / "renders/frames/rose/frame_00.png"
        for frame in (Image.new("RGBA", (255, 256)), Image.new("RGB", (256, 256))):
            frame.save(path)
            self.receipt(self.root, "rose")
            seal(self.root)
            self.fails("expected RGBA PNG 256x256")
        shutil.copyfile(self.base / "renders/frames/rose/frame_00.png", path)
        self.receipt(self.root, "rose")
        contents = self.root / "assets/StarshardFamilyRose.imageset/Contents.json"
        value = json.loads(contents.read_text())
        value["images"][0]["filename"] = "../../outside.png"
        write_json(contents, value)
        seal(self.root)
        self.fails("expected universal image named rose_tilt_atlas.png")

    def test_missing_source_scene_extra_frame_and_provenance(self):
        source = self.root / "source/generate_crystals.py"
        source.unlink()
        seal(self.root)
        self.fails("required package file missing: source/generate_crystals.py")
        shutil.copyfile(self.base / "source/generate_crystals.py", source)
        scene = self.root / "renders/scenes/rose.blend"
        scene.write_bytes(b"This is not a Blender header")
        seal(self.root)
        self.fails("native Blender header")
        shutil.copyfile(self.base / "renders/scenes/rose.blend", scene)
        extra = self.root / "renders/frames/rose/frame_09.png"
        shutil.copyfile(self.root / "renders/frames/rose/frame_00.png", extra)
        seal(self.root)
        self.fails("exactly the 45 expected")
        extra.unlink()
        seal(self.root)
        self.edit_manifest(lambda value: value["provenance"].update(kind="recovered-original"))
        self.fails("new-native-recreation")

    def test_resealed_stale_or_incomplete_receipt_is_rejected(self):
        path = self.root / "renders/metadata/rose.json"
        original = path.read_bytes()
        cases = [
            (lambda value: value.update(schema="other"), "schema/kind"),
            (lambda value: value.update(kind="aqua"), "schema/kind"),
            (lambda value: value.update(complete=False), "incomplete"),
            (lambda value: value.update(requested_frames=[4, 1]), "all nine unique frames"),
            (lambda value: value.update(generator_sha256="0" * 64), "generator_sha256"),
            (lambda value: value.update(settings_sha256="0" * 64), "settings_sha256"),
            (lambda value: value["settings"].update(changed=True), "recorded settings differ"),
            (lambda value: value["blend"].update(sha256="0" * 64), "scene path/hash"),
            (lambda value: value["blend"].update(path="../outside.blend"), "scene path/hash"),
            (lambda value: value["frames"][0].update(sha256="0" * 64), "frame 0 path/hash"),
            (lambda value: value["frames"][0].update(path="../outside.png"), "frame 0 path/hash"),
            (lambda value: value["frames"][0].update(index=1), "each index exactly once"),
        ]
        for mutate, message in cases:
            with self.subTest(message=message):
                value = json.loads(original)
                mutate(value)
                write_json(path, value)
                seal(self.root)
                self.fails(message)
        path.write_bytes(original)
        seal(self.root)
        self.assertTrue(self.report()["passed"])


if __name__ == "__main__":
    unittest.main()
