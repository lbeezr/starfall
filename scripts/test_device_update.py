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
    def test_identity_ignores_docs_but_changes_with_runtime(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder); (root / 'App').mkdir(); (root / 'docs').mkdir()
            p = root / 'App/main.swift'; p.write_text('first')
            initial = build_id(root)
            (root / 'docs/note.md').write_text('documentation only')
            self.assertEqual(build_id(root), initial)
            p.write_text('second'); self.assertNotEqual(build_id(root), initial)

    def test_ci_requires_latest_successful_main_push_for_exact_source(self):
        runs = [{'name': 'Starfall simulator', 'head_sha': 'abc', 'head_branch': 'main', 'event': 'push',
                 'run_number': 2, 'run_attempt': 1, 'status': 'completed', 'conclusion': 'success'}]
        def check():
            with patch.object(updater.urllib.request, 'urlopen', return_value=io.BytesIO(json.dumps({'workflow_runs': runs}).encode())):
                return updater.ci_ready('lbeezr/starfall', 'abc')
        self.assertTrue(check())
        runs.append(dict(runs[0], run_attempt=2, status='in_progress', conclusion=None))
        self.assertFalse(check())
        runs[:] = [dict(runs[0], head_sha='other')]; self.assertFalse(check())

    def test_pending_ci_retains_installed_app_and_does_not_build(self):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder)
            with patch.object(updater, 'connected', return_value=True), patch.object(updater, 'ci_ready', return_value=False), patch.object(updater, 'build_id', return_value='dev.new'), patch.object(updater.subprocess, 'run'), patch.object(updater, 'run', return_value='newsha') as command:
                self.assertIn('Waiting for successful main CI', updater.update({'device': 'phone', 'repository': 'lbeezr/starfall'}, state))
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

    def exercise_install(self, fail_first):
        with tempfile.TemporaryDirectory() as folder:
            state = Path(folder); source = state / 'fixture'; (source / 'App').mkdir(parents=True)
            (source / 'App/main.swift').write_text('runtime')
            fingerprint = build_id(source); commands = []; attempts = []
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
                    return 'abc'
                elif args[0] == 'tar':
                    subprocess.check_call(args)
                elif args[0] == 'xcodebuild':
                    app.mkdir(parents=True)
                    (app / 'Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': updater.BUNDLE, 'StarfallBuildID': fingerprint}))
                elif args[:4] == ['xcrun', 'devicectl', 'device', 'install']:
                    attempts.append(args)
                    if fail_first and len(attempts) == 1:
                        raise RuntimeError('locked')
                return ''
            config = {'device': 'phone', 'team': 'team', 'repository': 'lbeezr/starfall'}
            with patch.object(updater, 'connected', return_value=True), patch.object(updater, 'ci_ready', return_value=True), patch.object(updater, 'run', side_effect=command), patch.object(updater.subprocess, 'run', side_effect=archive):
                if fail_first:
                    with self.assertRaisesRegex(RuntimeError, 'locked'):
                        updater.update(config, state)
                    self.assertFalse((state / 'installed.json').exists())
                self.assertIn('Installed', updater.update(config, state))
                self.assertIn('Up to date', updater.update(config, state))
            self.assertEqual(sum(c[0] == 'xcodebuild' for c in commands), 1)
            self.assertEqual(json.loads((state / 'installed.json').read_text())['buildID'], fingerprint)
            self.assertTrue(all(updater.BUNDLE not in ' '.join(c) or 'uninstall' not in c for c in commands))
            self.assertFalse(any('launch' in c or '--starfalls-reset' in c for c in commands))


if __name__ == '__main__':
    unittest.main()
