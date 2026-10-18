"""Bounded RC checks for the minimum supported iOS and a landscape-capable iPad."""
import argparse
import json
from pathlib import Path
import re
import subprocess
import tempfile

TABLET_TEST = 'StarfallUITests/SkyFlowInteractionTests/testLandscapeWelcomeEntryAndPreferences'
TESTS = {
    'minimum-ios': [
        'StarfallUITests/SkyFlowInteractionTests/testWelcomeEntryBackgroundAndAnotherSky',
        'StarfallUITests/SkyFlowInteractionTests/testFirstLightWinReplayAndFullSky',
        'StarfallUITests/FallingSkyInteractionTests/testSystemReduceMotionKeepsManualPlayWorking'],
    'tablet': [TABLET_TEST,
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


def run(selection, artifacts, temporary):
    role = selection['role']
    booted_here = selection.get('state') != 'Booted'
    log = artifacts / ('rc-' + role + '.log')
    try:
        if booted_here:
            subprocess.run(['xcrun', 'simctl', 'boot', selection['udid']], check=True, timeout=60)
        subprocess.run(['xcrun', 'simctl', 'bootstatus', selection['udid'], '-b'], check=True, timeout=180)
        result = temporary / (role + '.xcresult')
        with log.open('w') as output:
            execution = subprocess.run(test_command(selection, temporary / 'derived', result), stdout=output,
                                       stderr=subprocess.STDOUT, check=False, timeout=900)
        summary = json.loads(subprocess.check_output(
            ['xcrun', 'xcresulttool', 'get', 'test-results', 'summary', '--path', str(result), '--compact'], timeout=60))
        (artifacts / ('rc-' + role + '-summary.json')).write_text(json.dumps(summary, indent=2) + '\n')
        if execution.returncode:
            raise subprocess.CalledProcessError(execution.returncode, execution.args)
        verify_summary(summary, len(selection['tests']))
    finally:
        if log.exists() and log.stat().st_size > 2_000_000:
            log.write_bytes(b'[final 2 MB]\n' + log.read_bytes()[-2_000_000:])
        if booted_here:
            subprocess.run(['xcrun', 'simctl', 'shutdown', selection['udid']], timeout=30, check=False)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plan-only', action='store_true')
    args = parser.parse_args()
    artifacts = Path('artifacts'); artifacts.mkdir(exist_ok=True)
    inventory = json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', 'devices', 'available', '--json'], timeout=30))
    try:
        selections = select_platforms(inventory)
    except ValueError as error:
        (artifacts / 'rc-platform-plan.json').write_text(json.dumps({'status': 'blocked', 'reason': str(error)}, indent=2) + '\n')
        raise SystemExit(str(error))
    (artifacts / 'rc-platform-plan.json').write_text(json.dumps({'status': 'planned', 'selections': selections}, indent=2) + '\n')
    if not args.plan_only:
        with tempfile.TemporaryDirectory(prefix='starfall-rc-platforms-') as directory:
            for selection in selections:
                run(selection, artifacts, Path(directory))
        print('PASS: minimum-iOS and tablet native checks; physical VoiceOver remains a separate RC gate.')


if __name__ == '__main__':
    main()
