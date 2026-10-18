import importlib.util
from pathlib import Path
import unittest
import json
import subprocess
import tempfile
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('rc_platforms', Path(__file__).with_name('rc-platforms.py'))
rc = importlib.util.module_from_spec(spec); spec.loader.exec_module(rc)


class RCPlatformsTests(unittest.TestCase):
    def inventory(self):
        def device(name, family, uid, available=True):
            return dict(name=name, udid=uid, isAvailable=available,
                        deviceTypeIdentifier='com.apple.CoreSimulator.SimDeviceType.' + family)
        return {'devices': {
            'com.apple.CoreSimulator.SimRuntime.iOS-17-5': [device('Renamed QA phone', 'iPhone-SE', 'old')],
            'com.apple.CoreSimulator.SimRuntime.iOS-27-0': [device('New phone', 'iPhone-17', 'new'), device('QA tablet', 'iPad-mini', 'pad')],
            'com.apple.CoreSimulator.SimRuntime.tvOS-27-0': [device('Wrong platform', 'iPad-mini', 'tv')],
        }}

    def test_minimum_os_is_not_satisfied_by_newest_phone_and_custom_names_are_supported(self):
        selected = rc.select_platforms(self.inventory())
        self.assertEqual([s['udid'] for s in selected], ['old', 'pad'])
        self.assertIn(rc.TABLET_TEST, selected[1]['tests'])
        self.assertNotIn(rc.TABLET_TEST, selected[0]['tests'])

    def test_missing_minimum_runtime_or_tablet_blocks_acceptance(self):
        data = self.inventory(); del data['devices']['com.apple.CoreSimulator.SimRuntime.iOS-17-5']
        with self.assertRaisesRegex(ValueError, 'minimum-ios'):
            rc.select_platforms(data)
        data = self.inventory(); data['devices']['com.apple.CoreSimulator.SimRuntime.iOS-27-0'][1]['isAvailable'] = False
        with self.assertRaisesRegex(ValueError, 'tablet'):
            rc.select_platforms(data)

    def test_selected_tests_cannot_pass_with_skips_or_missing_executions(self):
        good = dict(passedTests=3, totalTestCount=3, failedTests=0, skippedTests=0)
        rc.verify_summary(good, 3)
        for field in good:
            bad = {**good, field: good[field] + 1}
            with self.assertRaises(ValueError): rc.verify_summary(bad, 3)
        with self.assertRaises(ValueError): rc.verify_summary({}, 3)

    def test_matrix_names_exist_and_iphone_plan_accounts_for_tablet_exclusion(self):
        from native_test_plan import plan, TABLET_ONLY
        root = Path(__file__).resolve().parents[1]
        expected, _ = plan(root, 'dev')
        names = [n for values in expected['StarfallUITests']['testMethodsBySource'].values() for n in values]
        self.assertNotIn('testLandscapeWelcomeEntryAndPreferences', names)
        self.assertEqual(list(TABLET_ONLY.values()), [rc.TABLET_TEST])
        source = '\n'.join(p.read_text() for p in (root / 'UITests').glob('*.swift'))
        for tests in rc.TESTS.values():
            for identifier in tests: self.assertIn('func ' + identifier.rsplit('/', 1)[1] + '(', source)

    def test_command_preserves_selected_device_bounded_waits_and_ad_hoc_signing(self):
        selection = rc.select_platforms(self.inventory())[0]
        command = rc.test_command(selection, Path('/tmp/derived'), Path('/tmp/result'))
        self.assertIn('platform=iOS Simulator,id=old', command)
        self.assertIn('240', command); self.assertIn('CODE_SIGN_IDENTITY=-', command)
        self.assertEqual(sum(arg.startswith('-only-testing:') for arg in command), 3)
        self.assertFalse(any('skip-testing' in arg for arg in command))


class RCExecutionTests(unittest.TestCase):
    def execute(self, *, boot_error=None, test_error=None, returncode=0, summary_error=None, cleanup_error=None, booted=False, summary=None):
        root = Path(self.directory.name)
        artifacts = root / 'artifacts'; artifacts.mkdir(exist_ok=True)
        temporary = root / 'temporary'; temporary.mkdir(exist_ok=True)
        selection = dict(role='tablet', udid='pad', state='Booted' if booted else 'Shutdown', tests=rc.TESTS['tablet'])
        commands = []

        def run(command, **kwargs):
            commands.append(command)
            if 'boot' in command and boot_error: raise boot_error
            if command[0] == 'xcodebuild':
                result = Path(command[command.index('-resultBundlePath') + 1])
                result.mkdir(exist_ok=True); (result / 'partial').write_text('native failure evidence')
                kwargs['stdout'].write('x' * (rc.MAX_LOG_BYTES + 100))
                if test_error: raise test_error
                return subprocess.CompletedProcess(command, returncode)
            if 'shutdown' in command and cleanup_error: raise cleanup_error
            return subprocess.CompletedProcess(command, 0)

        def export(*args, **kwargs):
            if summary_error: raise summary_error
            return json.dumps(summary or dict(passedTests=3, totalTestCount=3, failedTests=0, skippedTests=0)).encode()

        with patch.object(rc.subprocess, 'run', side_effect=run), patch.object(rc.subprocess, 'check_output', side_effect=export):
            error = None
            try: rc.run(selection, artifacts, temporary)
            except Exception as caught: error = caught
        record = json.loads((artifacts / 'rc-tablet-execution.json').read_text())
        return error, record, artifacts, temporary, commands

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)

    def test_timeout_survives_shutdown_timeout_and_partial_bundle_survives_temporary_cleanup(self):
        timeout = subprocess.TimeoutExpired(['xcodebuild'], 900)
        cleanup = subprocess.TimeoutExpired(['simctl', 'shutdown'], 30)
        error, record, artifacts, temporary, _ = self.execute(test_error=timeout, cleanup_error=cleanup)
        self.assertIs(error, timeout)
        self.assertEqual(record['status'], 'failed'); self.assertEqual(record['stage'], 'tests')
        self.assertIn('shutdown:', record['secondaryErrors'][0])
        import shutil
        shutil.rmtree(temporary)
        self.assertEqual((artifacts / 'rc-tablet-failure.xcresult' / 'partial').read_text(), 'native failure evidence')
        self.assertLessEqual((artifacts / 'rc-tablet.log').stat().st_size, rc.MAX_LOG_BYTES + 20)
        self.assertTrue((artifacts / 'rc-tablet-summary.json').exists())

    def test_nonzero_tests_are_primary_even_when_summary_export_fails(self):
        error, record, _, _, _ = self.execute(returncode=65, summary_error=ValueError('partial unavailable'))
        self.assertIsInstance(error, subprocess.CalledProcessError); self.assertEqual(error.returncode, 65)
        self.assertEqual(record['stage'], 'tests')
        self.assertIn('partial summary:', record['secondaryErrors'][0])
        self.assertEqual(record['result']['status'], 'retained')

    def test_summary_export_or_count_failure_cannot_pass(self):
        error, record, _, _, _ = self.execute(summary_error=ValueError('bad summary'))
        self.assertIsInstance(error, ValueError); self.assertEqual(record['stage'], 'summary')
        error, record, _, _, _ = self.execute(summary=dict(passedTests=2, totalTestCount=3, failedTests=1, skippedTests=0))
        self.assertIsInstance(error, ValueError); self.assertEqual(record['status'], 'failed')

    def test_cleanup_failure_fails_successful_tests_but_never_shuts_down_prebooted_device(self):
        cleanup = subprocess.TimeoutExpired(['simctl', 'shutdown'], 30)
        error, record, _, _, _ = self.execute(cleanup_error=cleanup)
        self.assertIs(error, cleanup); self.assertEqual(record['stage'], 'shutdown')
        error, record, artifacts, _, commands = self.execute(cleanup_error=cleanup, booted=True)
        self.assertIsNone(error); self.assertEqual(record['status'], 'passed')
        self.assertFalse(any('shutdown' in command or 'boot' in command for command in commands))
        self.assertFalse((artifacts / 'rc-tablet-failure.xcresult').exists())

    def test_boot_failure_cannot_attach_a_previous_log_or_summary(self):
        artifacts = Path(self.directory.name) / 'artifacts'; artifacts.mkdir()
        (artifacts / 'rc-tablet.log').write_text('old successful output')
        (artifacts / 'rc-tablet-summary.json').write_text('{"passedTests":3}')
        boot = subprocess.TimeoutExpired(['simctl', 'boot'], 60)
        cleanup = subprocess.TimeoutExpired(['simctl', 'shutdown'], 30)
        error, record, _, _, _ = self.execute(boot_error=boot, cleanup_error=cleanup)
        self.assertIs(error, boot); self.assertEqual(record['stage'], 'boot')
        self.assertIsNone(record['log']); self.assertEqual(record['result']['status'], 'unavailable')
        self.assertFalse((artifacts / 'rc-tablet-summary.json').exists())
        self.assertFalse((artifacts / 'rc-tablet.log').exists())

    def test_main_marks_failed_run_before_temporary_storage_is_removed(self):
        import os
        original = Path.cwd()
        self.addCleanup(os.chdir, original)
        os.chdir(self.directory.name)
        error = subprocess.TimeoutExpired(['xcodebuild'], 900)
        visited = []
        def fail(selection, artifacts, temporary):
            visited.append(temporary)
            self.assertTrue(temporary.exists())
            raise error
        with patch('sys.argv', ['rc-platforms.py']), patch.object(rc.subprocess, 'check_output', return_value=json.dumps(RCPlatformsTests().inventory()).encode()), patch.object(rc, 'run', side_effect=fail):
            with self.assertRaises(subprocess.TimeoutExpired) as caught: rc.main()
        self.assertIs(caught.exception, error)
        self.assertEqual(json.loads(Path('artifacts/rc-platform-plan.json').read_text())['status'], 'failed')
        self.assertFalse(visited[0].exists())

    def test_oversize_bundle_retains_bounded_inventory_and_replaces_previous_bundle(self):
        result = Path(self.directory.name) / 'result'; result.mkdir()
        (result / 'large').write_bytes(b'12345')
        destination = Path(self.directory.name) / 'retained'; destination.mkdir()
        (destination / 'stale').write_text('old')
        with patch.object(rc, 'MAX_RESULT_BYTES', 4):
            record = rc.retain_failure(result, destination)
        self.assertEqual(record['status'], 'over-limit'); self.assertEqual(record['files'], ['large'])
        self.assertFalse(destination.exists())


if __name__ == '__main__': unittest.main()
