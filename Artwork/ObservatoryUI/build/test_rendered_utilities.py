#!/usr/bin/env python3
"""Behavioral checks with synthetic PNG fixtures; no production artwork is read/written."""

import argparse
import binascii
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile
import unittest
import zlib

import rendered_utilities as exporter


NODE = "node"
NODE_MODULES = None


def png_fixture(*, alpha=True, clipped=False, fringe=False):
    """A small colored rectangle with partial-alpha edge pixels, not game art."""
    width, height = 128, 96
    rows = bytearray()
    for y in range(height):
        rows.append(0)
        for x in range(width):
            visible = 20 <= x < 108 and 30 <= y < 66
            opacity = 160 if x in (20, 107) else 255
            if not visible:
                opacity = 0
            if clipped and x == 0 and y == 0:
                opacity = 16
            if fringe and x == 0 and y == 0:
                opacity = 15
            rows.extend((230, 190, 110))
            if alpha:
                rows.append(opacity)

    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", binascii.crc32(kind + data) & 0xFFFFFFFF))

    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6 if alpha else 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(bytes(rows)))
            + chunk(b"IEND", b""))


def snapshot(folder):
    return {str(path.relative_to(folder)): path.read_bytes()
            for path in folder.rglob("*") if path.is_file()}


class RenderedUtilityExportTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="starfall-utility-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.sources = self.root / "masters"
        self.outputs = self.root / "output"
        self.catalog = self.root / "catalog"
        self.sources.mkdir()
        self.outputs.mkdir()
        self.catalog.mkdir()
        self.provenance = {"version": 1, "generator": "Built-in ImageGen", "assets": []}
        data = png_fixture()
        for key in exporter.GLYPHS:
            (self.sources / f"{key}.png").write_bytes(data)
            self.provenance["assets"].append({
                "key": key, "master": f"{key}.png",
                "source": f"/test-fixture/{key}.png", "sourceSHA256": hashlib.sha256(data).hexdigest(),
                "prompt": f"Synthetic fixture for {key}; not generated art.",
            })
            folder = self.catalog / f"{exporter.asset_name(key)}.imageset"
            folder.mkdir()
            (folder / "glyph.pdf").write_bytes(b"historical fixture PDF")
            (folder / "Contents.json").write_text('{"fixture":true}\n')
        self.save_provenance()

    def save_provenance(self):
        (self.sources / "PROMPTS.json").write_bytes(exporter.json_bytes(self.provenance))

    def command(self, *extra):
        command = [sys.executable, str(Path(exporter.__file__)), "--node", NODE,
                   "--source-root", str(self.sources), "--output-root", str(self.outputs),
                   "--catalog-root", str(self.catalog)]
        if NODE_MODULES:
            command.extend(["--node-modules", NODE_MODULES])
        command.extend(extra)
        return subprocess.run(command, text=True, capture_output=True, timeout=60)

    def replace_source(self, key, data):
        (self.sources / f"{key}.png").write_bytes(data)
        next(entry for entry in self.provenance["assets"] if entry["key"] == key)["sourceSHA256"] = (
            hashlib.sha256(data).hexdigest()
        )
        self.save_provenance()

    def testExportsAreDeterministicAndReplaceOnlyRegisteredCatalogPayloads(self):
        original_sources = snapshot(self.sources)
        result = self.command()
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = json.loads((self.outputs / exporter.MANIFEST_NAME).read_bytes())
        self.assertEqual(len(manifest["assets"]), 20)
        self.assertEqual(manifest["provenance"]["file"], "../masters/PROMPTS.json")
        self.assertEqual((self.outputs / manifest["provenance"]["file"]).resolve(),
                         self.sources.resolve() / "PROMPTS.json")
        self.assertEqual(manifest["totals"]["decodedRGBABytes"], 645_120)
        self.assertEqual(manifest["budgets"]["decodedRGBABytes3xSelection"], 414_720)
        self.assertLessEqual(manifest["totals"]["encodedBytes"], exporter.MAX_ALL_EXPORT_BYTES)
        self.assertEqual({preview["filename"] for preview in manifest["previews"]},
                         {"rendered-utilities-small-sizes.png", "rendered-utilities-raw-sources.png"})
        for preview in manifest["previews"]:
            data = (self.outputs / exporter.PREVIEW_FOLDER / preview["filename"]).read_bytes()
            self.assertEqual(hashlib.sha256(data).hexdigest(), preview["sha256"])
            self.assertEqual(list(struct.unpack(">II", data[16:24])), preview["dimensions"])
            self.assertFalse(list(self.catalog.rglob(preview["filename"])))
        for asset in manifest["assets"]:
            key = asset["key"]
            self.assertEqual(asset["source"]["alpha"]["bounds"], [20, 30, 108, 66])
            self.assertEqual(asset["registration"]["cropPixels"], [16, 26, 112, 70])
            self.assertEqual(asset["registration"]["subjectAlphaThreshold"], 16)
            self.assertEqual(asset["registration"]["sourceBleedPixels"], 4)
            folder = self.catalog / f"{asset['assetName']}.imageset"
            contents = json.loads((folder / "Contents.json").read_bytes())
            self.assertEqual(contents, exporter.catalog_contents(key))
            self.assertFalse((folder / "glyph.pdf").exists())
            for rendition in asset["exports"]:
                data = (self.outputs / exporter.EXPORT_FOLDER / rendition["filename"]).read_bytes()
                side = 24 * rendition["density"]
                self.assertEqual(struct.unpack(">II", data[16:24]), (side, side))
                self.assertEqual(hashlib.sha256(data).hexdigest(), rendition["sha256"])
                self.assertEqual((folder / rendition["filename"]).read_bytes(), data)
                self.assertGreater(rendition["alpha"]["visiblePixels"], 0)
                self.assertTrue(all(value >= 2 * rendition["density"]
                                    for value in rendition["alpha"]["padding"]))
        self.assertEqual(snapshot(self.sources), original_sources)
        first = snapshot(self.outputs)
        catalog_first = snapshot(self.catalog)
        repeat = self.command()
        self.assertEqual(repeat.returncode, 0, repeat.stderr)
        self.assertEqual(snapshot(self.outputs), first)
        self.assertEqual(snapshot(self.catalog), catalog_first)

    def testCheckOnlyValidatesWithoutPublishingOrChangingOriginals(self):
        before = snapshot(self.root)
        result = self.command("--check-only")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(json.loads(result.stdout)["checkOnly"])
        self.assertFalse(json.loads(result.stdout)["catalogReplaced"])
        self.assertEqual(snapshot(self.root), before)

    def testHashMismatchLeavesAllDestinationsUntouched(self):
        before = snapshot(self.catalog)
        (self.sources / "trace.png").write_bytes(png_fixture(clipped=True))
        result = self.command()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("differs from recorded original source bytes", result.stderr)
        self.assertEqual(snapshot(self.catalog), before)
        self.assertEqual(snapshot(self.outputs), {})

    def testClippedAlphaOrMissingAlphaIsRejectedBeforePublication(self):
        before = snapshot(self.catalog)
        for data, expected in [(png_fixture(clipped=True), "visible subject needs a clear outer frame"),
                               (png_fixture(alpha=False), "expected one alpha PNG")]:
            with self.subTest(expected=expected):
                self.replace_source("trace", data)
                result = self.command()
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(expected, result.stderr)
                self.assertEqual(snapshot(self.catalog), before)
                self.assertEqual(snapshot(self.outputs), {})

    def testLowAlphaEdgeFringeDoesNotShrinkVisibleRegistration(self):
        clean_result = self.command()
        self.assertEqual(clean_result.returncode, 0, clean_result.stderr)
        clean_exports = snapshot(self.outputs / exporter.EXPORT_FOLDER)
        self.replace_source("trace", png_fixture(fringe=True))
        fringe_result = self.command()
        self.assertEqual(fringe_result.returncode, 0, fringe_result.stderr)
        self.assertEqual(snapshot(self.outputs / exporter.EXPORT_FOLDER), clean_exports)
        manifest = json.loads((self.outputs / exporter.MANIFEST_NAME).read_bytes())
        trace = next(asset for asset in manifest["assets"] if asset["key"] == "trace")
        self.assertEqual(trace["source"]["alpha"]["bounds"], [0, 0, 108, 66])
        self.assertEqual(trace["source"]["alphaAt16"]["bounds"], [20, 30, 108, 66])
        self.assertEqual(trace["registration"]["cropPixels"], [16, 26, 112, 70])
        self.assertEqual(trace["source"]["discardedOutsideCrop"],
                         {"pixelCount": 1, "maximumAlpha": 15, "alphaSum": 15})

    def testUnknownCatalogFileIsPreservedAndPreventsReplacement(self):
        folder = self.catalog / "ObservatoryGlyphTrace.imageset"
        (folder / "unowned.txt").write_text("retain me")
        before = snapshot(self.catalog)
        result = self.command()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Unowned catalog entry", result.stderr)
        self.assertEqual(snapshot(self.catalog), before)
        self.assertEqual(snapshot(self.outputs), {})

    def testDuplicateProvenanceAndSymlinkMastersAreRejected(self):
        self.provenance["assets"][-1] = dict(self.provenance["assets"][0])
        self.save_provenance()
        with self.assertRaisesRegex(ValueError, "Duplicate"):
            exporter.read_provenance(self.sources)
        self.provenance["assets"][-1]["key"] = "trace"
        self.provenance["assets"][-1]["master"] = "trace.png"
        self.save_provenance()
        (self.sources / "trace.png").unlink()
        (self.sources / "trace.png").symlink_to(self.sources / "story.png")
        with self.assertRaisesRegex(ValueError, "regular file"):
            exporter.read_provenance(self.sources)

    def testLinkedParentCannotRedirectCatalogReplacement(self):
        link = self.root / "linked-parent"
        link.symlink_to(self.root, target_is_directory=True)
        before = snapshot(self.catalog)
        result = self.command("--catalog-root", str(link / "catalog"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Root must not traverse a symlink", result.stderr)
        self.assertEqual(snapshot(self.catalog), before)
        self.assertEqual(snapshot(self.outputs), {})


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--node", default=NODE)
    parser.add_argument("--node-modules")
    options, remaining = parser.parse_known_args()
    NODE = options.node
    NODE_MODULES = options.node_modules
    unittest.main(argv=[sys.argv[0], *remaining])
