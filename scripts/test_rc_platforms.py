import importlib.util
from pathlib import Path
import unittest
import json
import subprocess
import tempfile
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('rc_platforms', Path(__file__).with_name('rc-platforms.py'))
rc = importlib.util.module_from_spec(spec); spec.loader.exec_module(rc)

MINIMUM_IOS_TESTS = [
    'StarfallUITests/SkyFlowInteractionTests/testWelcomeEntryBackgroundAndAnotherSky',
    'StarfallUITests/SkyFlowInteractionTests/testCurrentRibbonWinReplayAndFullSky',
    'StarfallUITests/FallingSkyInteractionTests/testSystemReduceMotionKeepsManualPlayWorking',
]
TABLET_TESTS = [
    'StarfallUITests/SkyFlowInteractionTests/testLandscapeWelcomeEntryAndPreferences',
    'StarfallUITests/LanternLandingInteractionTests/testTabletRotationKeepsRestorationAndNativeInput',
    'StarfallUITests/RibbonCrossingInteractionTests/testTabletRotationKeepsRibbonRestorationAndNativeInput',
    'StarfallUITests/KiteHarborInteractionTests/testTabletRotationKeepsKiteRestorationAndNativeInput',
    'StarfallUITests/SeedMoonInteractionTests/testTabletRotationKeepsSeedRestorationAndNativeInput',
    'StarfallUITests/SilverPoolsInteractionTests/testTabletRotationKeepsSilverRestorationAndNativeInput',
    'StarfallUITests/SilverPoolsInteractionTests/testTabletDenseSilverCompletionKeepsNativeInput',
    'StarfallUITests/FrostfruitOrchardInteractionTests/testTabletRotationKeepsFrostfruitRestorationAndNativeInput',
    'StarfallUITests/FrostfruitOrchardInteractionTests/testTabletDenseFrostfruitCompletionKeepsNativeInput',
    'StarfallUITests/SunwheelMillInteractionTests/testTabletRotationKeepsSunwheelRestorationAndNativeInput',
    'StarfallUITests/SunwheelMillInteractionTests/testTabletDenseSunwheelCompletionKeepsNativeInput',
    'StarfallUITests/SkyFlowInteractionTests/testLargestTextWelcomeEntryAndBackRemainReachable',
    'StarfallUITests/CriticalMassInteractionTests/testLargestTextCalmKeepsWarningAndHelpUsable',
]


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
        self.assertEqual(selected[0]['tests'], MINIMUM_IOS_TESTS)
        self.assertEqual(selected[1]['tests'], TABLET_TESTS)

    def test_missing_minimum_runtime_or_tablet_blocks_acceptance(self):
        data = self.inventory(); del data['devices']['com.apple.CoreSimulator.SimRuntime.iOS-17-5']
        with self.assertRaisesRegex(ValueError, 'minimum-ios'):
            rc.select_platforms(data)
        data = self.inventory(); data['devices']['com.apple.CoreSimulator.SimRuntime.iOS-27-0'][1]['isAvailable'] = False
        with self.assertRaisesRegex(ValueError, 'tablet'):
            rc.select_platforms(data)

    def test_selected_tests_cannot_pass_with_skips_or_missing_executions(self):
        for count in (len(MINIMUM_IOS_TESTS), len(TABLET_TESTS)):
            good = dict(passedTests=count, totalTestCount=count, failedTests=0, skippedTests=0)
            rc.verify_summary(good, count)
            for field in good:
                bad = {**good, field: good[field] + 1}
                with self.assertRaises(ValueError): rc.verify_summary(bad, count)
            with self.assertRaises(ValueError): rc.verify_summary({}, count)
        with self.assertRaises(ValueError):
            rc.verify_summary(dict(passedTests=3, totalTestCount=3, failedTests=0, skippedTests=0), len(TABLET_TESTS))

    def test_matrix_names_exist_and_iphone_plan_accounts_for_tablet_exclusion(self):
        from native_test_plan import plan, TABLET_ONLY
        root = Path(__file__).resolve().parents[1]
        self.assertEqual(rc.TESTS, {'minimum-ios': MINIMUM_IOS_TESTS, 'tablet': TABLET_TESTS})
        self.assertTrue(set(TABLET_ONLY.values()).issubset(rc.TESTS['tablet']))
        self.assertTrue(set(TABLET_ONLY.values()).isdisjoint(rc.TESTS['minimum-ios']))
        for stage in ('dev', 'rc'):
            expected, _ = plan(root, stage)
            names = [n for values in expected['StarfallUITests']['testMethodsBySource'].values() for n in values]
            self.assertTrue(set(TABLET_ONLY).isdisjoint(names), stage)
        for tests in rc.TESTS.values():
            self.assertEqual(len(tests), len(set(tests)))
            for identifier in tests:
                target, source, method = identifier.split('/')
                self.assertEqual(target, 'StarfallUITests')
                self.assertIn('func ' + method + '(', (root / 'UITests' / (source + '.swift')).read_text())

    def test_command_preserves_selected_device_bounded_waits_and_ad_hoc_signing(self):
        for selection, tests in zip(rc.select_platforms(self.inventory()), (MINIMUM_IOS_TESTS, TABLET_TESTS)):
            command = rc.test_command(selection, Path('/tmp/derived'), Path('/tmp/result'))
            self.assertIn('platform=iOS Simulator,id=' + selection['udid'], command)
            self.assertIn('240', command); self.assertIn('CODE_SIGN_IDENTITY=-', command)
            self.assertEqual([arg for arg in command if arg.startswith('-only-testing:')],
                             ['-only-testing:' + name for name in tests])
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
            if 'xcresulttool' in command:
                return subprocess.CompletedProcess(command, 0, stdout=export())
            if 'shutdown' in command and cleanup_error: raise cleanup_error
            return subprocess.CompletedProcess(command, 0)

        def export(*args, **kwargs):
            if summary_error: raise summary_error
            count = len(TABLET_TESTS)
            return json.dumps(summary if summary is not None else dict(passedTests=count, totalTestCount=count, failedTests=0, skippedTests=0)).encode()

        with patch.object(rc, 'run_owned', side_effect=run):
            error = None
            try: rc.run(selection, artifacts, temporary)
            except Exception as caught: error = caught
        record = json.loads((artifacts / 'rc-tablet-execution.json').read_text())
        return error, record, artifacts, temporary, commands

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)

    def test_real_test_timeout_stops_descendant_log_writes_before_failure_retention(self):
        import os
        import sys
        import time
        from owned_process import run_owned
        root = Path(self.directory.name)
        artifacts = root / 'artifacts'; artifacts.mkdir()
        temporary = root / 'temporary'; temporary.mkdir()
        result = temporary / 'tablet.xcresult'
        ready = root / 'descendant-ready'
        late = root / 'late-output'
        pid_file = root / 'test.pid'
        child = 'import time; from pathlib import Path; Path(' + repr(str(ready)) + ').write_text("ready"); time.sleep(2); Path(' + repr(str(late)) + ').write_text("late"); print("late log output",flush=True)'
        parent = 'import os,subprocess,sys,time; from pathlib import Path; Path(' + repr(str(pid_file)) + ').write_text(str(os.getpid())); p=Path(' + repr(str(result)) + '); p.mkdir(); (p/"partial").write_text("committed failure evidence"); subprocess.Popen([sys.executable,"-c",' + repr(child) + ']); time.sleep(30)'
        command = [sys.executable, '-c', parent]
        selection = dict(role='tablet', udid='fixture-only', state='Shutdown', tests=rc.TESTS['tablet'])
        calls = []
        def execute(selected, **kwargs):
            calls.append(selected)
            if selected == command:
                return run_owned(selected, **{**kwargs, 'timeout': 1})
            self.assertEqual(selected[0], 'xcrun')
            if 'shutdown' in selected:
                raise RuntimeError('fixture shutdown failure')
            if 'xcresulttool' in selected:
                return subprocess.CompletedProcess(selected, 0, stdout=b'{}')
            return subprocess.CompletedProcess(selected, 0)
        with patch.object(rc, 'test_command', return_value=command), patch.object(rc, 'run_owned', side_effect=execute):
            with self.assertRaises(subprocess.TimeoutExpired):
                rc.run(selection, artifacts, temporary)
        self.assertTrue(ready.exists(), 'The real descendant must start before timeout')
        with self.assertRaises(ChildProcessError):
            os.waitpid(int(pid_file.read_text()), os.WNOHANG)
        record = json.loads((artifacts / 'rc-tablet-execution.json').read_text())
        self.assertEqual((record['status'], record['stage']), ('failed', 'tests'))
        self.assertIn('timed out', record['primaryError'])
        self.assertEqual(record['secondaryErrors'], ['shutdown: fixture shutdown failure'])
        retained = artifacts / 'rc-tablet-failure.xcresult' / 'partial'
        self.assertEqual(retained.read_text(), 'committed failure evidence')
        log = artifacts / 'rc-tablet.log'
        returned_log = log.read_bytes()
        # This deliberate delayed sentinel detects escaped helpers after finalization.
        time.sleep(2.2)
        self.assertFalse(late.exists(), 'A timed-out RC command must not keep writing after return')
        self.assertEqual(log.read_bytes(), returned_log)
        self.assertEqual(retained.read_text(), 'committed failure evidence')

    def test_interruption_is_recorded_as_primary_even_when_cleanup_fails(self):
        interruption = KeyboardInterrupt('fixture cancellation')
        with self.assertRaises(KeyboardInterrupt) as caught:
            self.execute(test_error=interruption, cleanup_error=RuntimeError('fixture shutdown failure'))
        self.assertIs(caught.exception, interruption)
        record = json.loads((Path(self.directory.name) / 'artifacts/rc-tablet-execution.json').read_text())
        self.assertEqual((record['status'], record['stage']), ('failed', 'tests'))
        self.assertEqual(record['primaryError'], 'fixture cancellation')
        self.assertEqual(record['secondaryErrors'], ['shutdown: fixture shutdown failure'])

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
        with patch('sys.argv', ['rc-platforms.py']), patch.object(rc, 'run_owned', return_value=subprocess.CompletedProcess(['inventory'], 0, stdout=json.dumps(RCPlatformsTests().inventory()).encode())), patch.object(rc, 'run', side_effect=fail):
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
