"""Bounded RC checks for the minimum supported iOS and a landscape-capable iPad."""
import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

from native_test_plan import TABLET_ONLY
from owned_process import run_owned

TESTS = {
    'minimum-ios': [
        'StarfallUITests/SkyFlowInteractionTests/testWelcomeEntryBackgroundAndAnotherSky',
        'StarfallUITests/SkyFlowInteractionTests/testCurrentRibbonWinReplayAndFullSky',
        'StarfallUITests/FallingSkyInteractionTests/testSystemReduceMotionKeepsManualPlayWorking'],
    'tablet': [*TABLET_ONLY.values(),
        'StarfallUITests/SkyFlowInteractionTests/testLargestTextWelcomeEntryAndBackRemainReachable',
        'StarfallUITests/CriticalMassInteractionTests/testLargestTextCalmKeepsWarningAndHelpUsable'],
}


def select_platforms(inventory):
    candidates = []
    for runtime, devices in inventory.get('devices', {}).items():
        match = re.search(r'\.iOS-(\d+)(?:-(\d+))?', runtime)
        if not match:
            continue
        version = (int(match[1]), int(match[2] or 0))
        for device in devices:
            if device.get('isAvailable') and device.get('udid'):
                candidates.append({**device, 'runtime': runtime, 'version': version})
    roles = {
        'minimum-ios': [d for d in candidates if d['version'][0] == 17 and '.iPhone-' in d.get('deviceTypeIdentifier', '')],
        'tablet': [d for d in candidates if d['version'] >= (17, 0) and '.iPad-' in d.get('deviceTypeIdentifier', '')],
    }
    missing = [role for role, choices in roles.items() if not choices]
    if missing:
        raise ValueError('RC platform coverage unavailable: ' + ', '.join(missing) + '. Install/select the required local runtime/device before RC acceptance; no downloads are performed.')
    return [{**max(choices, key=lambda d: (d['version'], d['name'], d['udid'])), 'role': role, 'tests': TESTS[role]}
            for role, choices in roles.items()]


def test_command(selection, derived, result):
    return ['xcodebuild', '-project', 'Starfall.xcodeproj', '-scheme', 'Starfall',
            '-configuration', 'Debug', '-sdk', 'iphonesimulator',
            '-destination', 'platform=iOS Simulator,id=' + selection['udid'],
            '-derivedDataPath', str(derived), '-resultBundlePath', str(result),
            '-parallel-testing-enabled', 'NO', '-test-timeouts-enabled', 'YES',
            '-default-test-execution-time-allowance', '90', '-maximum-test-execution-time-allowance', '240',
            'CODE_SIGN_IDENTITY=-', 'CODE_SIGNING_ALLOWED=YES', 'DEVELOPMENT_TEAM=', 'CODE_SIGN_STYLE=Manual',
            *['-only-testing:' + name for name in selection['tests']], 'test']


def verify_summary(summary, expected):
    if (summary.get('passedTests') != expected or summary.get('totalTestCount') != expected
            or summary.get('failedTests') != 0 or summary.get('skippedTests') != 0):
        raise ValueError(f'RC platform expected {expected} passes, zero failures/skips: {summary}')


MAX_LOG_BYTES = 2_000_000
MAX_RESULT_BYTES = 64_000_000


def retain_failure(result, destination):
    """One bounded result per role, plus a compact inventory when too large."""
    if destination.exists():
        shutil.rmtree(destination)
    if not result.exists():
        return {'status': 'unavailable'}
    files = sorted(p for p in result.rglob('*') if p.is_file())
    size = sum(p.stat().st_size for p in files)
    record = {'bytes': size, 'fileCount': len(files)}
    if size <= MAX_RESULT_BYTES:
        shutil.copytree(result, destination)
        return {**record, 'status': 'retained', 'path': str(destination)}
    return {**record, 'status': 'over-limit', 'limitBytes': MAX_RESULT_BYTES,
            'files': [str(p.relative_to(result))[:512] for p in files[:100]]}


def run(selection, artifacts, temporary):
    role = selection['role']
    booted_here = selection.get('state') != 'Booted'
    log = artifacts / ('rc-' + role + '.log')
    result = temporary / (role + '.xcresult')
    retained = artifacts / ('rc-' + role + '-failure.xcresult')
    summary_path = artifacts / ('rc-' + role + '-summary.json')
    # Remove only this role's previous run outputs. Never accept a stale summary.
    summary_path.unlink(missing_ok=True)
    log.unlink(missing_ok=True)
    if retained.exists():
        shutil.rmtree(retained)
    primary = None
    secondary = []
    summary = None
    stage = 'boot'
    try:
        if booted_here:
            run_owned(['xcrun', 'simctl', 'boot', selection['udid']], check=True, timeout=60)
        run_owned(['xcrun', 'simctl', 'bootstatus', selection['udid'], '-b'], check=True, timeout=180)
        stage = 'tests'
        with log.open('w') as output:
            execution = run_owned(test_command(selection, temporary / 'derived', result), stdout=output,
                                  stderr=subprocess.STDOUT, check=False, timeout=900)
        if execution.returncode:
            raise subprocess.CalledProcessError(execution.returncode, execution.args)
        stage = 'summary'
        summary = json.loads(run_owned(
            ['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(result), '--compact'],
            stdout=subprocess.PIPE, check=True, timeout=60).stdout)
        summary_path.write_text(json.dumps(summary, indent=2) + '\n')
        verify_summary(summary, len(selection['tests']))
    except BaseException as error:
        primary = error
    finally:
        # Partial bundles may still export a summary after xcodebuild fails/times out.
        if primary is not None and summary is None and result.exists() and stage != 'summary':
            try:
                summary = json.loads(run_owned(
                    ['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(result), '--compact'],
                    stdout=subprocess.PIPE, check=True, timeout=60).stdout)
                summary_path.write_text(json.dumps(summary, indent=2) + '\n')
            except Exception as error:
                secondary.append('partial summary: ' + str(error))
        evidence = None
        if primary is not None:
            try:
                evidence = retain_failure(result, retained)
            except Exception as error:
                secondary.append('result retention: ' + str(error))
        try:
            if log.exists() and log.stat().st_size > MAX_LOG_BYTES:
                with log.open('rb') as source:
                    source.seek(-MAX_LOG_BYTES, 2)
                    tail = source.read(MAX_LOG_BYTES)
                log.write_bytes(b'[final 2 MB]\n' + tail)
        except Exception as error:
            secondary.append('log retention: ' + str(error))
        if booted_here:
            try:
                run_owned(['xcrun', 'simctl', 'shutdown', selection['udid']], timeout=30, check=True)
            except Exception as error:
                secondary.append('shutdown: ' + str(error))
                if primary is None:
                    primary = error
                    stage = 'shutdown'
        record = {'status': 'failed' if primary else 'passed', 'role': role, 'stage': stage,
                  'primaryError': str(primary) if primary else None, 'secondaryErrors': secondary,
                  'result': evidence, 'log': str(log) if log.exists() else None}
        try:
            (artifacts / ('rc-' + role + '-execution.json')).write_text(json.dumps(record, indent=2) + '\n')
        except OSError:
            if primary is None:
                raise
    if primary is not None:
        raise primary
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plan-only', action='store_true')
    args = parser.parse_args()
    artifacts = Path('artifacts'); artifacts.mkdir(exist_ok=True)
    inventory = json.loads(run_owned(['xcrun', 'simctl', 'list', 'devices', 'available', '--json'],
                                    stdout=subprocess.PIPE, check=True, timeout=30).stdout)
    try:
        selections = select_platforms(inventory)
    except ValueError as error:
        (artifacts / 'rc-platform-plan.json').write_text(json.dumps({'status': 'blocked', 'reason': str(error)}, indent=2) + '\n')
        raise SystemExit(str(error))
    (artifacts / 'rc-platform-plan.json').write_text(json.dumps({'status': 'planned', 'selections': selections}, indent=2) + '\n')
    if not args.plan_only:
        records = []
        try:
            with tempfile.TemporaryDirectory(prefix='starfall-rc-platforms-') as directory:
                for selection in selections:
                    records.append(run(selection, artifacts, Path(directory)))
        except BaseException as error:
            try:
                (artifacts / 'rc-platform-plan.json').write_text(json.dumps(
                    {'status': 'failed', 'selections': selections, 'completed': records, 'error': str(error)}, indent=2) + '\n')
            except OSError:
                pass  # The original execution error remains authoritative.
            raise
        (artifacts / 'rc-platform-plan.json').write_text(json.dumps(
            {'status': 'passed', 'selections': selections, 'completed': records}, indent=2) + '\n')
        print('PASS: minimum-iOS and tablet native checks; physical VoiceOver remains a separate RC gate.')


if __name__ == '__main__':
    main()
