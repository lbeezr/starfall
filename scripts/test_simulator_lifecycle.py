"""Execution checks for primary CI subprocess bounds, ownership and cleanup."""
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('simulator_command', SCRIPTS / 'simulator-command.py')
stage = importlib.util.module_from_spec(spec); spec.loader.exec_module(stage)


class SimulatorCommandTests(unittest.TestCase):
    def test_timeout_stops_descendants_before_they_can_mutate_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); marker = root / 'late-output'; ready = root / 'ready'
            child = 'import signal, time; from pathlib import Path; signal.signal(signal.SIGTERM, signal.SIG_IGN); Path(' + repr(str(ready)) + ').write_text("ready"); time.sleep(2); Path(' + repr(str(marker)) + ').write_text("orphan")'
            parent = 'import subprocess, sys, time; subprocess.Popen([sys.executable, "-c", ' + repr(child) + ']); time.sleep(60)'
            self.assertEqual(stage.execute('descendants', 1, [sys.executable, '-c', parent], root / 'receipt'), 124)
            self.assertTrue(ready.exists(), 'The descendant must actually start before timeout')
            # The delayed sentinel demonstrates survival; it is not a test-readiness wait.
            import time
            time.sleep(2.2)
            self.assertFalse(marker.exists(), 'A timed-out stage must not leave a child writing evidence')

    def test_timeout_does_not_kill_an_unrelated_process(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); marker = root / 'unrelated-output'
            command = 'import time; from pathlib import Path; time.sleep(0.2); Path(' + repr(str(marker)) + ').write_text("finished")'
            with subprocess.Popen([sys.executable, '-c', command]) as unrelated:
                self.assertEqual(stage.execute('owned-only', 0.05,
                    [sys.executable, '-c', 'import time; time.sleep(60)'], root / 'receipt'), 124)
                self.assertEqual(unrelated.wait(timeout=5), 0)
            self.assertEqual(marker.read_text(), 'finished')

    def test_real_timeout_is_bounded_and_records_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            receipt = Path(directory) / 'receipt.jsonl'
            status = stage.execute('readiness', 0.05, [sys.executable, '-c', 'import time; time.sleep(60)'], receipt)
            self.assertEqual(status, 124)
            record = json.loads(receipt.read_text())
            self.assertEqual(record['stage'], 'readiness'); self.assertEqual(record['exitCode'], 124)
            self.assertLess(record['elapsedSeconds'], 5)

    def test_nonzero_missing_command_signal_and_receipt_failure_keep_correct_status(self):
        with tempfile.TemporaryDirectory() as directory:
            receipt = Path(directory) / 'receipt.jsonl'
            self.assertEqual(stage.execute('nonzero', 5, [sys.executable, '-c', 'raise SystemExit(9)'], receipt), 9)
            self.assertEqual(stage.execute('missing', 5, [str(Path(directory) / 'absent')], receipt), 127)
            self.assertEqual(stage.execute('signal', 5, [sys.executable, '-c', 'import os, signal; os.kill(os.getpid(), signal.SIGTERM)'], receipt), 143)
            bad_receipt = Path(directory)  # A directory cannot receive a JSON line.
            self.assertEqual(stage.execute('failure', 5, [sys.executable, '-c', 'raise SystemExit(9)'], bad_receipt), 9)
            self.assertEqual(stage.execute('success-no-receipt', 5, [sys.executable, '-c', 'pass'], bad_receipt), 1)

    def test_stdout_pid_contract_survives_runner_and_receipt_has_no_command_output(self):
        with tempfile.TemporaryDirectory() as directory:
            receipt = Path(directory) / 'receipt.jsonl'
            result = subprocess.run([sys.executable, str(SCRIPTS / 'simulator-command.py'), '--receipt', str(receipt),
                                     'launch', '5', sys.executable, '-c', 'print("com.starfall.prototype: 123")'], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0)
            self.assertEqual(result.stdout.strip(), 'com.starfall.prototype: 123')
            self.assertNotIn('prototype', receipt.read_text())


class SimulatorOwnershipTests(unittest.TestCase):
    def run_ci_prefix(self, initial_state, fail_stage='', shutdown_status=0):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'scripts').mkdir(); (root / 'artifacts').mkdir()
            for name in ['simulator-command.py', 'simulator-lifecycle.sh']:
                shutil.copyfile(SCRIPTS / name, root / 'scripts' / name)
            fake = root / 'xcrun'
            fake.write_text('#!' + sys.executable + '\n' + '''import json, os, sys
from pathlib import Path
with Path('calls.jsonl').open('a') as output: output.write(json.dumps(sys.argv[1:])+'\\n')
operation = sys.argv[2]
if operation == 'shutdown': raise SystemExit(int(os.environ['SHUTDOWN_STATUS']))
if operation == os.environ['FAIL_STAGE']: raise SystemExit(9)
''')
            fake.chmod(0o755)
            script = (SCRIPTS / 'ci-simulator.sh').read_text()
            # Exercise the actual primary runner cleanup/trap, not a copy in this test.
            prefix = script[script.index('SIMULATOR_ID=""'):script.index('# Select the newest installed stable Xcode')]
            body = '\nstart_simulator qa "$INITIAL_STATE"\ntimed_simctl boot-ready 5 xcrun simctl bootstatus qa -b\ntimed_simctl install 5 xcrun simctl install qa app\n'
            result = subprocess.run(['bash', '-c', 'set -euo pipefail\n' + prefix + body], cwd=root,
                                    env={**os.environ, 'PATH': str(root) + os.pathsep + os.environ['PATH'],
                                         'INITIAL_STATE': initial_state, 'FAIL_STAGE': fail_stage, 'SHUTDOWN_STATUS': str(shutdown_status)},
                                    capture_output=True, text=True, timeout=10)
            calls = [json.loads(line)[1] for line in (root / 'calls.jsonl').read_text().splitlines()]
            receipts = [json.loads(line) for line in (root / 'artifacts/simulator-stage-timings.jsonl').read_text().splitlines()]
            return result, calls, receipts

    def test_prebooted_device_is_never_booted_or_shutdown(self):
        result, calls, receipts = self.run_ci_prefix('Booted')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ['bootstatus', 'install'])
        self.assertEqual([r['stage'] for r in receipts], ['boot-ready', 'install'])

    def test_cold_device_has_owned_cleanup_even_when_install_and_shutdown_fail(self):
        result, calls, receipts = self.run_ci_prefix('Shutdown', fail_stage='install', shutdown_status=8)
        self.assertEqual(result.returncode, 9, result.stderr)
        self.assertEqual(calls, ['boot', 'bootstatus', 'install', 'shutdown'])
        self.assertEqual(receipts[-1]['exitCode'], 8)

    def test_failed_boot_retains_primary_status_and_still_cleans_its_attempt(self):
        result, calls, _ = self.run_ci_prefix('Shutdown', fail_stage='boot', shutdown_status=8)
        self.assertEqual(result.returncode, 9, result.stderr)
        self.assertEqual(calls, ['boot', 'shutdown'])

    def test_cleanup_failure_fails_an_otherwise_successful_run(self):
        result, calls, _ = self.run_ci_prefix('Shutdown', shutdown_status=8)
        self.assertEqual(result.returncode, 8, result.stderr)
        self.assertEqual(calls[-1], 'shutdown')

    def test_every_primary_simctl_operation_uses_bounded_runner(self):
        for line in (SCRIPTS / 'ci-simulator.sh').read_text().splitlines():
            if 'xcrun simctl ' in line and not line.lstrip().startswith('#'):
                self.assertIn('timed_simctl', line)


if __name__ == '__main__': unittest.main()
