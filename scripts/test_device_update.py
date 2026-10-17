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

    def test_identity_ignores_docs_but_changes_with_runtime(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); (root / 'App').mkdir(); (root / 'docs').mkdir()
            p = root / 'App/main.swift'; p.write_text('first')
            initial = build_id(root)
            (root / 'docs/note.md').write_text('documentation only')
            self.assertEqual(build_id(root), initial)
            p.write_text('second'); self.assertNotEqual(build_id(root), initial)

    def test_ci_reports_latest_main_push_for_exact_source(self):
        runs = [{'name': 'Starfall simulator', 'head_sha': 'abc', 'head_branch': 'main', 'event': 'push',
                 'run_number': 2, 'run_attempt': 1, 'status': 'completed', 'conclusion': 'success'}]
        def check():
            with patch.object(updater.urllib.request, 'urlopen', return_value=io.BytesIO(json.dumps({'workflow_runs': runs}).encode())):
                return updater.ci_status('lbeezr/starfall', 'abc')
        self.assertEqual(check(), 'passed')
        runs[0]['conclusion'] = 'failure'; self.assertEqual(check(), 'failed')
        runs[0]['conclusion'] = 'success'
        runs.append(dict(runs[0], run_attempt=2, status='in_progress', conclusion=None))
        self.assertEqual(check(), 'pending')
        runs[:] = [dict(runs[0], head_sha='other')]; self.assertEqual(check(), 'missing')

    def test_failed_ci_retains_installed_app_and_does_not_build(self):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder)
            with patch.object(updater, 'connected', return_value=True), patch.object(updater, 'ci_status', return_value='failed'), patch.object(updater, 'build_id', return_value='dev.new'), patch.object(updater.subprocess, 'run'), patch.object(updater, 'run', return_value='newsha') as command:
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

    def exercise_install(self, fail_first, core_failure=False):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder); source = state / 'fixture'; (source / 'App').mkdir(parents=True)
            (source / 'App/main.swift').write_text('runtime')
            fingerprint = build_id(source); commands = []; attempts = []; revision = ['abc']
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
                elif args[0] == 'xcodebuild':
                    app.mkdir(parents=True)
                    (app / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': updater.BUNDLE, 'StarfallBuildID': fingerprint}))
                elif args[:4] == ['xcrun', 'devicectl', 'device', 'install']:
                    attempts.append(args)
                    if fail_first and len(attempts) == 1:
                        raise RuntimeError('locked')
                return ''
            config = {'device': 'phone', 'team': 'team', 'repository': 'lbeezr/starfall'}
            with patch.object(updater, 'connected', return_value=True), patch.object(updater, 'ci_status', return_value='pending'), patch.object(updater, 'run', side_effect=command), patch.object(updater.subprocess, 'run', side_effect=archive):
                if core_failure:
                    with self.assertRaisesRegex(RuntimeError, 'core tests failed'):
                        updater.update(config, state)
                    self.assertFalse((state / 'installed.json').exists())
                    self.assertFalse(any(c[0] == 'xcodebuild' or 'install' in c for c in commands))
                    return
                if fail_first:
                    with self.assertRaisesRegex(RuntimeError, 'locked'):
                        updater.update(config, state)
                    self.assertFalse((state / 'installed.json').exists())
                self.assertIn('Installed', updater.update(config, state))
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
