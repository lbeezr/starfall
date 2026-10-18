import importlib.util
from pathlib import Path
import unittest

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


if __name__ == '__main__': unittest.main()
