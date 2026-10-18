"""Real-file checks for required shipping captures and partial native evidence."""
import base64
import json
from pathlib import Path
import tempfile
import subprocess
import sys
import unittest
from unittest.mock import patch
import export_native_evidence as evidence

PNG = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=')


class NativeEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(); self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / 'export'; self.root.mkdir()
        self.output = Path(self.temporary.name) / 'output'; self.output.mkdir()
        self.summary = Path(self.temporary.name) / 'summary.json'
        self.summary.write_text(json.dumps(dict(passedTests=2, totalTestCount=2, failedTests=0, skippedTests=0)))
        self.expectations = Path(self.temporary.name) / 'expectations.json'
        self.expectations.write_text('{"StarfallUITests":{"expectedCount":2}}')
        self.manifest = []
        for index, name in enumerate(evidence.REQUIRED_IMAGES):
            filename = f'{index}.png'; (self.root / filename).write_bytes(PNG)
            self.manifest.append(dict(exportedFileName=filename, suggestedHumanReadableName=name + '_0_UUID.png'))
        self.write_manifest()

    def write_manifest(self):
        (self.root / 'manifest.json').write_text(json.dumps([dict(attachments=self.manifest)]))

    def run_export(self, exit_code=0):
        return evidence.export(self.root, self.output, self.summary, self.expectations, exit_code)

    def test_complete_run_requires_and_exports_classic_and_shipping_frames(self):
        result = self.run_export()
        self.assertTrue(result['complete']); self.assertFalse(result['partialEvidenceOnly'])
        self.assertEqual(result['namedScreenshotsExported'], len(evidence.REQUIRED_IMAGES))
        records = json.loads((self.output / 'ui-attachment-manifest.json').read_text())
        self.assertEqual([record['name'] for record in records], evidence.REQUIRED_IMAGES)
        self.assertTrue(set(evidence.SHIPPING_IMAGES).issubset(record['name'] for record in records))
        self.assertTrue(all((self.output / record['file']).read_bytes() == PNG for record in records))

    def test_classic_only_success_is_rejected_and_cannot_reuse_a_previous_shipping_frame(self):
        self.run_export()
        self.manifest = self.manifest[:len(evidence.CLASSIC_IMAGES)]; self.write_manifest()
        with self.assertRaisesRegex(ValueError, 'flow-welcome'): self.run_export()
        status = json.loads((self.output / 'ui-evidence-status.json').read_text())
        self.assertFalse(status['complete'])
        self.assertFalse((self.output / 'flow-welcome.png').exists())
        self.assertEqual(status['namedScreenshotsExported'], len(evidence.CLASSIC_IMAGES))

    def test_every_shipping_capture_is_mandatory_and_duplicate_prefixes_do_not_substitute(self):
        original = list(self.manifest)
        for name in evidence.SHIPPING_IMAGES:
            self.manifest = [item for item in original if not evidence.named(item, name)]
            self.manifest.append(dict(exportedFileName='0.png', suggestedHumanReadableName=name + '-different_0_UUID.png'))
            self.write_manifest()
            with self.assertRaisesRegex(ValueError, name): self.run_export()
        self.manifest = original + [original[0]]; self.write_manifest()
        with self.assertRaisesRegex(ValueError, 'exactly one'): self.run_export()

    def test_partial_failed_run_exports_available_frames_even_without_summary(self):
        self.run_export()
        self.manifest = self.manifest[-1:]; self.write_manifest(); self.summary.unlink()
        result = self.run_export(65)
        self.assertFalse(result['complete']); self.assertTrue(result['partialEvidenceOnly'])
        self.assertEqual(result['xcodebuildExitCode'], 65); self.assertEqual(result['namedScreenshotsExported'], 1)
        self.assertTrue(result['errors'])
        self.assertFalse((self.output / 'flow-welcome.png').exists())
        self.assertTrue((self.output / 'flow-full.png').exists())

    def test_failed_run_without_any_export_is_explicitly_incomplete(self):
        (self.root / 'manifest.json').unlink(); self.summary.write_text('invalid')
        result = self.run_export(65)
        self.assertEqual(result['namedScreenshotsExported'], 0)
        self.assertFalse(result['complete']); self.assertEqual(len(result['errors']), 2)

    def test_passing_run_rejects_missing_summary_wrong_counts_and_skips(self):
        for summary in [None, {}, dict(passedTests=1,totalTestCount=2,failedTests=0,skippedTests=1), []]:
            if summary is None: self.summary.write_text('invalid')
            else: self.summary.write_text(json.dumps(summary))
            with self.assertRaises(ValueError): self.run_export()

    def test_unsafe_paths_symlinks_wrong_format_and_oversized_exports_are_rejected(self):
        for name in ['../outside.png', '/tmp/outside.png', 'nested/image.png']:
            self.manifest[0]['exportedFileName'] = name; self.write_manifest()
            with self.assertRaises(ValueError): self.run_export()
        self.manifest[0]['exportedFileName'] = 'link.png'; self.write_manifest()
        (self.root / 'link.png').symlink_to(self.root / '0.png')
        with self.assertRaisesRegex(ValueError, 'nonsymlink'): self.run_export()
        self.manifest[0]['exportedFileName'] = '0.png'; self.write_manifest()
        (self.root / '0.png').write_text('not a PNG')
        with self.assertRaisesRegex(ValueError, 'PNG'): self.run_export()
        (self.root / '0.png').write_bytes(PNG)
        with patch.object(evidence, 'MAX_IMAGE_BYTES', len(PNG)-1):
            with self.assertRaisesRegex(ValueError, 'PNG'): self.run_export()
        with patch.object(evidence, 'MAX_MANIFEST_BYTES', 10):
            with self.assertRaisesRegex(ValueError, 'manifest exceeds'): self.run_export()

    def test_startup_reset_clears_owned_acceptance_but_preserves_unrelated_evidence(self):
        self.run_export()
        unrelated = self.output / 'other-investigation.png'; unrelated.write_bytes(PNG)
        result = subprocess.run([sys.executable, evidence.__file__, '--reset-only', '--output', str(self.output)],
                                capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.output / 'ui-evidence-status.json').exists())
        self.assertFalse((self.output / 'flow-welcome.png').exists())
        self.assertEqual(unrelated.read_bytes(), PNG)

    def test_required_names_are_unique_and_have_real_native_capture_calls(self):
        self.assertEqual(len(set(evidence.REQUIRED_IMAGES)), len(evidence.REQUIRED_IMAGES))
        source = '\n'.join(path.read_text() for path in (Path(__file__).resolve().parents[1] / 'UITests').glob('*.swift'))
        for name in evidence.SHIPPING_IMAGES: self.assertIn('"' + name + '"', source)


if __name__ == '__main__': unittest.main()
