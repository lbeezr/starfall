"""Behavioral checks for the one-app updater without touching a device or network."""
import importlib.util
import io
import json
from pathlib import Path
import plistlib
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch

from build_identity import build_id

spec = importlib.util.spec_from_file_location('device_update', Path(__file__).with_name('device-update.py'))
updater = importlib.util.module_from_spec(spec); spec.loader.exec_module(updater)


class DeviceUpdateTests(unittest.TestCase):
    def test_reconfiguration_invalidates_only_device_and_signing_owned_metadata(self):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder); config = {'device': 'first', 'team': 'team'}
            updater.configure(config, state)
            for name in ['installed.json', 'built.json', 'backup.plist']:
                (state / name).write_text('retained')
            updater.configure(config, state)
            self.assertTrue((state / 'installed.json').exists())
            updater.configure(dict(config, device='second'), state)
            self.assertFalse((state / 'installed.json').exists())
            self.assertFalse((state / 'built.json').exists())
            self.assertEqual((state / 'backup.plist').read_text(), 'retained')

    def test_configuration_cannot_race_an_active_update(self):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder)
            with (state / 'update.lock').open('a') as lock:
                updater.fcntl.flock(lock, updater.fcntl.LOCK_EX | updater.fcntl.LOCK_NB)
                with self.assertRaisesRegex(RuntimeError, 'update is running'):
                    updater.configure({'device': 'second', 'team': 'new-team'}, state)
            self.assertFalse((state / 'config.json').exists())

    def test_service_reload_cannot_interrupt_an_active_update(self):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder); updater.configure({'device': 'phone', 'team': 'team'}, state)
            with (state / 'update.lock').open('a') as lock, patch.object(updater.subprocess, 'run') as command, patch.object(updater.shutil, 'copyfile') as copy:
                updater.fcntl.flock(lock, updater.fcntl.LOCK_EX | updater.fcntl.LOCK_NB)
                with self.assertRaisesRegex(RuntimeError, 'update is running'):
                    updater.enable(state)
                command.assert_not_called(); copy.assert_not_called()

    def test_identity_ignores_docs_but_changes_with_runtime(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); (root / 'App').mkdir(); (root / 'docs').mkdir()
            p = root / 'App/main.swift'; p.write_text('first')
            initial = build_id(root)
            (root / 'docs/note.md').write_text('documentation only')
            self.assertEqual(build_id(root), initial)
            p.write_text('second'); self.assertNotEqual(build_id(root), initial)

    def test_identity_tracks_manifest_resolution_resources_and_configuration(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            for name in ['Package.swift', 'Package.resolved', 'App/main.swift',
                         'App/Assets.xcassets/Cast.imageset/Contents.json', 'App/LaunchScreen.storyboard',
                         'Config/Clean.xcconfig', 'Starfall.xcodeproj/project.pbxproj',
                         'Starfall.xcodeproj/xcshareddata/xcschemes/Starfall.xcscheme',
                         'Starfall.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved']:
                with self.subTest(input=name):
                    before = build_id(root)
                    path = root / name; path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_text('initial')
                    created = build_id(root)
                    self.assertNotEqual(before, created)
                    path.write_text('changed'); self.assertNotEqual(created, build_id(root))
                    path.unlink(); self.assertEqual(before, build_id(root))

    def test_identity_ignores_nested_docs_tests_and_user_workspace_state(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); before = build_id(root)
            for name in ['App/README.md', 'Sources/StarfallCore/README.md', 'Config/README.md',
                         'Starfall.xcodeproj/README.md', 'AppTests/Test.swift', 'UITests/Test.swift',
                         'Tests/StarfallCoreTests/Test.swift', 'docs/guide.md', 'App/.DS_Store',
                         'Starfall.xcodeproj/xcuserdata/developer.xcuserdatad/UserInterfaceState.xcuserstate']:
                path = root / name; path.parent.mkdir(parents=True, exist_ok=True); path.write_text('local')
                self.assertEqual(before, build_id(root), name)

    def test_ci_failure_during_build_holds_install_and_reuses_verified_build(self):
        self.exercise_install(fail_first=False, late_ci_failure=True)

    def test_ci_reports_latest_main_push_for_exact_source(self):
        runs = [{'name': 'Starfall simulator', 'head_sha': 'abc', 'head_branch': 'main', 'event': 'push',
                 'run_number': 2, 'run_attempt': 1, 'status': 'completed', 'conclusion': 'success'}]
        def check():
            with patch.object(updater.urllib.request, 'urlopen', return_value=io.BytesIO(json.dumps({'workflow_runs': runs}).encode())):
                return updater.ci_status('lbeezr/starfall', 'abc')
        self.assertEqual(check(), 'passed')
        runs[0]['conclusion'] = 'failure'; self.assertEqual(check(), 'failed')
        runs[0]['conclusion'] = 'cancelled'; self.assertEqual(check(), 'unavailable')
        runs[0]['conclusion'] = 'timed_out'; self.assertEqual(check(), 'unavailable')
        runs[0]['conclusion'] = 'success'
        runs.append(dict(runs[0], run_attempt=2, status='in_progress', conclusion=None))
        self.assertEqual(check(), 'pending')
        runs[:] = [dict(runs[0], head_sha='other')]; self.assertEqual(check(), 'missing')

    def test_failed_ci_retains_installed_app_and_does_not_build(self):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder)
            with patch.object(updater, 'connected', return_value=True), patch.object(updater, 'app_installation', return_value=None), patch.object(updater, 'ci_status', return_value='failed'), patch.object(updater, 'build_id', return_value='dev.new'), patch.object(updater.subprocess, 'run'), patch.object(updater, 'run', return_value='newsha') as command:
                self.assertIn('Held: main CI failed', updater.update({'device': 'phone', 'repository': 'lbeezr/starfall'}, state))
                self.assertFalse((state / 'installed.json').exists())
                self.assertFalse(any(call.args[0][0] == 'xcodebuild' or 'install' in call.args[0] for call in command.call_args_list))

    def test_disconnect_does_not_fetch_or_build(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(updater, 'connected', return_value=False), patch.object(updater, 'run') as command:
            self.assertIn('Waiting', updater.update({'device': 'phone'}, Path(folder)))
            command.assert_not_called()

    def test_failed_install_retries_cached_build_without_marking_installed(self):
        self.exercise_install(fail_first=True)

    def test_unchanged_runtime_does_not_reinstall(self):
        self.exercise_install(fail_first=False)

    def test_failed_local_core_tests_prevent_build_and_install(self):
        self.exercise_install(fail_first=False, core_failure=True)

    def test_external_replacement_is_repaired_even_when_source_receipt_is_current(self):
        self.exercise_install(fail_first=False, external_change='replacement')

    def test_missing_app_and_legacy_receipt_cannot_report_up_to_date(self):
        for change in ['missing', 'legacy', 'version']:
            with self.subTest(change=change):
                self.exercise_install(fail_first=False, external_change=change)

    def test_main_advancing_during_build_prevents_install(self):
        self.exercise_install(fail_first=False, moves_during_build=True)

    def test_post_install_inventory_mismatch_cannot_mark_revision_delivered(self):
        self.exercise_install(fail_first=False, bad_post_install=True)

    def test_changed_source_and_failed_signature_cannot_install(self):
        for failure in ['source', 'signature']:
            with self.subTest(failure=failure):
                self.exercise_install(fail_first=False, validation_failure=failure)

    def test_non_descendant_main_cannot_build_install_or_rewrite_receipt(self):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder); receipt = {'source': 'previous', 'checkedSource': 'checked-docs'}
            updater.atomic_json(state / 'installed.json', receipt)
            def command(args, **kwargs):
                if args[:2] == ['git', 'rev-parse']: return 'stale'
                if args[:2] == ['git', 'merge-base']:
                    self.assertEqual(args[-2:], ['checked-docs', 'stale'])
                    raise subprocess.CalledProcessError(1, args)
                return ''
            with patch.object(updater, 'connected', return_value=True), patch.object(updater, 'run', side_effect=command) as calls, patch.object(updater, 'app_installation') as inventory:
                self.assertIn('Held: fetched main', updater.update({'device': 'phone', 'repository': 'lbeezr/starfall'}, state))
                inventory.assert_not_called()
                self.assertFalse(any('install' in call.args[0] or call.args[0][0] in ['swift', 'xcodebuild'] for call in calls.call_args_list))
                self.assertEqual(json.loads((state / 'installed.json').read_text()), receipt)

    def test_ancestry_uses_real_git_and_fails_closed_for_missing_objects(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            def git(*args):
                return subprocess.check_output(['git', '-C', str(root), *args], stderr=subprocess.DEVNULL).decode().strip()
            git('init', '-b', 'main'); git('config', 'user.name', 'Fixture'); git('config', 'user.email', 'fixture@example.invalid')
            git('commit', '--allow-empty', '-m', 'base'); base = git('rev-parse', 'HEAD')
            git('commit', '--allow-empty', '-m', 'new'); new = git('rev-parse', 'HEAD')
            self.assertTrue(updater.includes_previous_main(root, base, new))
            self.assertFalse(updater.includes_previous_main(root, new, base))
            self.assertFalse(updater.includes_previous_main(root, 'a' * 40, new))
            git('checkout', '-b', 'sibling', base)
            git('commit', '--allow-empty', '-m', 'divergent')
            self.assertFalse(updater.includes_previous_main(root, new, git('rev-parse', 'HEAD')))

    def test_unknown_device_inventory_fails_instead_of_claiming_current(self):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder)
            for payload in [{'result': {'apps': 'invalid'}}, {'result': {'apps': [{'bundleIdentifier': updater.BUNDLE, 'url': 'unknown', 'bundleVersion': '1'}]}}]:
                (state / 'apps.json').write_text(json.dumps(payload))
                with patch.object(updater, 'run'), self.assertRaises(RuntimeError):
                    updater.app_installation({'device': 'phone'}, state)

    def exercise_install(self, fail_first, core_failure=False, late_ci_failure=False,
                         external_change=None, moves_during_build=False, bad_post_install=False,
                         validation_failure=None):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder); source = state / 'fixture'; (source / 'App').mkdir(parents=True)
            (source / 'App/main.swift').write_text('runtime')
            fingerprint = build_id(source); commands = []; attempts = []; revision = ['abc']; actual = [None]
            app = state / 'DerivedData/Build/Products/Debug-iphoneos/Starfall.app'
            def archive(args, **kwargs):
                self.assertEqual(args[0], 'git')
                with tarfile.open(fileobj=kwargs['stdout'], mode='w') as stream:
                    stream.add(source / 'App', arcname='App')
            def command(args, **kwargs):
                commands.append(args)
                if args[:2] == ['git', 'clone']:
                    (state / 'repository.git').mkdir()
                elif args[:2] == ['git', 'rev-parse']:
                    return revision[0]
                elif args[0] == 'tar':
                    subprocess.check_call(args)
                elif args[:2] == ['swift', 'test'] and core_failure:
                    raise RuntimeError('core tests failed')
                elif args[0] == 'codesign' and validation_failure:
                    if validation_failure == 'signature': raise RuntimeError('signature failed')
                    (state / 'source/App/main.swift').write_text('changed during validation')
                elif args[0] == 'xcodebuild':
                    app.mkdir(parents=True)
                    (app / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': updater.BUNDLE, 'StarfallBuildID': fingerprint, 'CFBundleVersion': '1'}))
                    if moves_during_build: revision[0] = 'new-main'
                elif args[:5] == ['xcrun', 'devicectl', 'device', 'info', 'apps']:
                    apps = [] if actual[0] is None else [{'bundleIdentifier': updater.BUNDLE,
                        'url': actual[0]['installationURL'], 'bundleVersion': actual[0]['bundleVersion']}]
                    (state / 'apps.json').write_text(json.dumps({'result': {'apps': apps}}))
                elif args[:4] == ['xcrun', 'devicectl', 'device', 'install']:
                    attempts.append(args)
                    if fail_first and len(attempts) == 1:
                        raise RuntimeError('locked')
                    url = 'file:///private/var/containers/Bundle/Application/install-' + str(len(attempts)) + '/Starfall.app/'
                    (state / 'installation.json').write_text(json.dumps({'result': {'installedApplications': [{'bundleID': updater.BUNDLE, 'installationURL': url}]}}))
                    actual[0] = {'installationURL': 'file:///another-install/Starfall.app/' if bad_post_install else url, 'bundleVersion': '1'}
                return ''
            config = {'device': 'phone', 'team': 'team', 'repository': 'lbeezr/starfall'}
            with patch.object(updater, 'connected', return_value=True), patch.object(updater, 'ci_status', side_effect=iter(['pending', 'failed', 'pending', 'pending']) if late_ci_failure else lambda *_: 'pending'), patch.object(updater, 'run', side_effect=command), patch.object(updater.subprocess, 'run', side_effect=archive):
                if core_failure:
                    with self.assertRaisesRegex(RuntimeError, 'core tests failed'):
                        updater.update(config, state)
                    self.assertFalse((state / 'installed.json').exists())
                    self.assertFalse(any(c[0] == 'xcodebuild' or 'install' in c for c in commands))
                    return
                if validation_failure:
                    with self.assertRaisesRegex(RuntimeError, 'source changed|signature failed'):
                        updater.update(config, state)
                    self.assertFalse(attempts); self.assertFalse((state / 'installed.json').exists())
                    return
                if moves_during_build:
                    self.assertIn('Held: main advanced', updater.update(config, state))
                    self.assertFalse(attempts); self.assertFalse((state / 'installed.json').exists())
                    return
                if bad_post_install:
                    with self.assertRaisesRegex(RuntimeError, 'on-device identity'):
                        updater.update(config, state)
                    self.assertEqual(len(attempts), 1); self.assertFalse((state / 'installed.json').exists())
                    return
                if late_ci_failure:
                    self.assertIn('Held: main CI failed before installation', updater.update(config, state))
                    self.assertFalse((state / 'installed.json').exists())
                    self.assertTrue((state / 'built.json').exists())
                    self.assertFalse(attempts)
                if fail_first:
                    with self.assertRaisesRegex(RuntimeError, 'locked'):
                        updater.update(config, state)
                    self.assertFalse((state / 'installed.json').exists())
                self.assertIn('Installed', updater.update(config, state))
                if external_change:
                    if external_change == 'replacement': actual[0]['installationURL'] = 'file:///stale-branch/Starfall.app/'
                    elif external_change == 'missing': actual[0] = None
                    elif external_change == 'version': actual[0]['bundleVersion'] = 'old'
                    elif external_change == 'legacy':
                        receipt = json.loads((state / 'installed.json').read_text())
                        receipt.pop('installationURL'); receipt.pop('bundleVersion')
                        updater.atomic_json(state / 'installed.json', receipt)
                    self.assertIn('Installed', updater.update(config, state))
                    self.assertEqual(len(attempts), 2)
                self.assertIn('Up to date', updater.update(config, state))
                revision[0] = 'docs-only'
                self.assertIn('Up to date', updater.update(config, state))
                self.assertEqual(json.loads((state / 'installed.json').read_text())['source'], 'abc')
                self.assertEqual(json.loads((state / 'installed.json').read_text())['checkedSource'], 'docs-only')
            self.assertEqual(sum(c[0] == 'xcodebuild' for c in commands), 1)
            self.assertLess(next(i for i, c in enumerate(commands) if c[:2] == ['swift', 'test']), next(i for i, c in enumerate(commands) if 'install' in c))
            self.assertEqual(json.loads((state / 'installed.json').read_text())['buildID'], fingerprint)
            self.assertEqual(json.loads((state / 'installed.json').read_text())['validation']['mainCIAtInstall'], 'pending')
            self.assertTrue(all(updater.BUNDLE not in ' '.join(c) or 'uninstall' not in c for c in commands))
            self.assertFalse(any('launch' in c or '--starfalls-reset' in c for c in commands))


if __name__ == '__main__':
    unittest.main()
