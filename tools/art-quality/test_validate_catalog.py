#!/usr/bin/env python3
"""Focused temporary-catalog fixtures; never edit the real asset catalog."""
import json
import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

from PIL import Image

import validate_catalog as validator


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="starfall-catalog-test-")
        self.addCleanup(self.temporary.cleanup)
        self.catalog = Path(self.temporary.name) / "Assets.xcassets"
        self.catalog.mkdir()
        # Reuse the sealed v2 family and distinct immutable v1 pilot in temporary
        # fixtures. Real assets and the package are never modified by these tests.
        aqua = Path(__file__).parent / "comparison/baseline/StarshardFamilyAqua.imageset/aqua_tilt_atlas.png"
        family = Path(__file__).resolve().parents[2] / "Artwork/Crystals/v2/assets"
        for asset, filename in validator.EXPECTED.items():
            directory = self.catalog / f"{asset}.imageset"
            directory.mkdir()
            source = aqua if asset == "CrystalPilot" else family / f"{asset}.imageset" / filename
            shutil.copyfile(source, directory / filename)
            self.write_contents(asset, {"images": [{"filename": filename, "idiom": "universal"}],
                                        "info": {"author": "xcode", "version": 1}})
        self.rose = self.catalog / "StarshardFamilyRose.imageset"

    def write_contents(self, asset, value):
        (self.catalog / f"{asset}.imageset/Contents.json").write_text(json.dumps(value))

    def errors(self):
        report = validator.validate(self.catalog)
        self.assertFalse(report["passed"])
        return "\n".join(report["errors"])

    def test_complete_catalog_and_approved_pin(self):
        report = validator.validate(self.catalog)
        self.assertTrue(report["passed"], report["errors"])
        self.assertFalse(report["aqua_copies_identical"])
        self.assertEqual(len(report["sets"]), 6)
        for asset, digest in validator.APPROVED_ATLAS_SHA256.items():
            self.assertEqual(report["sets"][asset]["atlas_sha256"], digest)

    def test_absent_catalog_set_contents_and_atlas(self):
        self.assertFalse(validator.validate(self.catalog / "missing")["passed"])
        for target in (self.rose / "rose_tilt_atlas.png", self.rose / "Contents.json", self.rose):
            if target.is_dir():
                target.rmdir()
            else:
                target.unlink()
            self.assertIn("missing", self.errors())

    def test_exact_case_image_set_and_filename(self):
        renamed = self.rose.with_name("starshardfamilyrose.imageset")
        self.rose.rename(renamed)
        self.assertIn("missing exact-case image set", self.errors())
        renamed.rename(self.rose)
        original = self.rose / "rose_tilt_atlas.png"
        original.rename(self.rose / "Rose_tilt_atlas.png")
        self.assertIn("missing exact-case file", self.errors())

    def test_contents_schema_and_reference(self):
        contents = self.rose / "Contents.json"
        cases = [[], {}, {"images": []}, {"images": [None]}, {"images": [{"filename": None}]},
                 {"images": [{"filename": "rose_tilt_atlas.png", "idiom": "iphone"}]},
                 {"images": [{"filename": "rose_tilt_atlas.png", "idiom": "universal"}], "info": {"version": True}}]
        for value in cases:
            with self.subTest(value=value):
                contents.write_text(json.dumps(value))
                self.errors()
        contents.write_text("{bad json")
        self.assertIn("StarshardFamilyRose", self.errors())
        shutil.copyfile(self.rose / "rose_tilt_atlas.png", self.rose / "wrong.png")
        self.write_contents("StarshardFamilyRose", {"images": [{"filename": "wrong.png", "idiom": "universal"}]})
        self.assertIn("expected 'rose_tilt_atlas.png'", self.errors())

    def test_traversal_and_symlink_escapes(self):
        for reference in ("../secret.png", "/tmp/secret.png", "sub/file.png", "..\\secret.png", "bad\0name"):
            with self.subTest(reference=reference):
                self.write_contents("StarshardFamilyRose", {"images": [{"filename": reference}]})
                self.assertIn("unsafe filename", self.errors())
        self.write_contents("StarshardFamilyRose", {"images": [{"filename": "rose_tilt_atlas.png", "idiom": "universal"}], "info": {"version": 1}})
        path = self.rose / "rose_tilt_atlas.png"
        path.unlink()
        path.symlink_to(self.catalog / "CrystalPilot.imageset/aqua_tilt_atlas.png")
        self.assertIn("symlink resolves outside", self.errors())

    def test_wrong_layout_mode_empty_border_and_corrupt(self):
        path = self.rose / "rose_tilt_atlas.png"
        for image in (Image.new("RGBA", (256, 256)), Image.new("RGB", (2304, 256)), Image.new("RGBA", (2304, 256))):
            image.save(path)
            self.errors()
        image = Image.new("RGBA", (2304, 256), "#00FFFFFF")
        image.save(path)
        self.assertIn("nontransparent outer border", self.errors())
        path.write_bytes(b"broken PNG")
        self.assertIn("cannot identify image file", self.errors())

    def test_each_adopted_atlas_and_legacy_pilot_has_its_own_pin(self):
        for asset, filename in validator.EXPECTED.items():
            path = self.catalog / f"{asset}.imageset" / filename
            with Image.open(path) as image:
                changed = image.copy()
            changed.putpixel((128, 128), (255, 0, 0, 255))
            changed.save(path)
        report = validator.validate(self.catalog)
        self.assertEqual(sum("pinned approved" in error for error in report["errors"]), 6)
        self.assertFalse(report["passed"])

    def test_swapping_current_aqua_and_legacy_pilot_rejects_both(self):
        family = self.catalog / "StarshardFamilyAqua.imageset/aqua_tilt_atlas.png"
        pilot = self.catalog / "CrystalPilot.imageset/aqua_tilt_atlas.png"
        current, legacy = family.read_bytes(), pilot.read_bytes()
        family.write_bytes(legacy)
        pilot.write_bytes(current)
        report = validator.validate(self.catalog)
        self.assertEqual(sum("pinned approved" in error for error in report["errors"]), 2)
        self.assertFalse(report["passed"])

    def test_identical_aqua_copies_cannot_replace_distinct_revision_pins(self):
        family = self.catalog / "StarshardFamilyAqua.imageset/aqua_tilt_atlas.png"
        pilot = self.catalog / "CrystalPilot.imageset/aqua_tilt_atlas.png"
        for raw in (family.read_bytes(), pilot.read_bytes()):
            family.write_bytes(raw)
            pilot.write_bytes(raw)
            report = validator.validate(self.catalog)
            self.assertTrue(report["aqua_copies_identical"])
            self.assertEqual(sum("pinned approved" in error for error in report["errors"]), 1)
            self.assertFalse(report["passed"])

    def test_oversized_png_header_is_a_reported_failure(self):
        path = self.rose / "rose_tilt_atlas.png"
        raw = bytearray(path.read_bytes())
        # Alter only IHDR dimensions/CRC; allocate no oversized pixel image.
        raw[16:24] = struct.pack(">II", 300000, 300000)
        raw[29:33] = struct.pack(">I", zlib.crc32(raw[12:29]) & 0xFFFFFFFF)
        path.write_bytes(raw)
        self.assertIn("decompression bomb", self.errors().lower())
        result = subprocess.run([sys.executable, "-B", str(Path(validator.__file__)),
                                 "--assets", str(self.catalog), "--json"], capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertFalse(json.loads(result.stdout)["passed"])
        self.assertNotIn("Traceback", result.stderr)

    def test_cli_nonzero_and_json(self):
        command = [sys.executable, "-B", str(Path(validator.__file__)), "--assets", str(self.catalog), "--json"]
        passing = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(passing.returncode, 0)
        self.assertTrue(json.loads(passing.stdout)["passed"])
        (self.rose / "Contents.json").unlink()
        failing = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(failing.returncode, 1)
        self.assertFalse(json.loads(failing.stdout)["passed"])


if __name__ == "__main__":
    unittest.main()
