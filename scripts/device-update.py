#!/usr/bin/env python3
"""Update one connected iPhone from clean GitHub main; never reset or uninstall."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from build_identity import build_id

BUNDLE = 'com.starfall.prototype'
LABEL = 'com.starfall.device-updates'
DEFAULT_STATE = Path.home() / 'Library/Application Support/Starfall Device Updates'


def run(args, *, cwd=None, output=None):
    if output:
        with output.open('a') as log:
            subprocess.run(args, cwd=cwd, stdout=log, stderr=subprocess.STDOUT, check=True, timeout=1200)
        return ''
    return subprocess.check_output(args, cwd=cwd, stderr=subprocess.STDOUT, text=True, timeout=1200).strip()


def atomic_json(path, value):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value, indent=2) + '\n')
    temporary.replace(path)


def ci_ready(repository, revision):
    request = urllib.request.Request(
        'https://api.github.com/repos/' + repository + '/actions/runs?head_sha=' + revision + '&per_page=30',
        headers={'Accept': 'application/vnd.github+json', 'User-Agent': 'Starfall-Device-Updater'})
    with urllib.request.urlopen(request, timeout=30) as response:
        runs = json.load(response)['workflow_runs']
    matching = [r for r in runs if r['name'] == 'Starfall simulator' and r['head_sha'] == revision
                and r['head_branch'] == 'main' and r['event'] == 'push']
    latest = max(matching, key=lambda r: (r['run_number'], r.get('run_attempt', 1)), default=None)
    return bool(latest and latest['status'] == 'completed' and latest['conclusion'] == 'success')


def connected(device, state):
    receipt = state / 'devices.json'
    run(['xcrun', 'devicectl', 'list', 'devices', '--json-output', str(receipt)], output=state / 'device.log')
    for item in json.loads(receipt.read_text())['result']['devices']:
        ids = [item.get('identifier'), item.get('hardwareProperties', {}).get('udid')]
        if (device in ids and item.get('hardwareProperties', {}).get('reality') == 'physical'
                and item.get('connectionProperties', {}).get('tunnelState') == 'connected'):
            return True
    return False


def update(config, state):
    if not connected(config['device'], state):
        return 'Waiting for the configured iPhone.'
    mirror = state / 'repository.git'
    url = 'https://github.com/' + config['repository'] + '.git'
    if not mirror.exists():
        run(['git', 'clone', '--bare', url, str(mirror)], output=state / 'fetch.log')
    run(['git', 'fetch', '--no-tags', 'origin', 'refs/heads/main'], cwd=mirror, output=state / 'fetch.log')
    revision = run(['git', 'rev-parse', 'FETCH_HEAD'], cwd=mirror)
    installed = json.loads((state / 'installed.json').read_text()) if (state / 'installed.json').exists() else {}
    if installed.get('source') == revision:
        return 'Up to date: ' + installed['buildID']
    target = state / 'source'
    # An archive cannot include uncommitted developer files or alter their checkout.
    archive = state / 'source.tar'
    with archive.open('wb') as stream:
        subprocess.run(['git', '-C', str(mirror), 'archive', revision], stdout=stream, check=True, timeout=120)
    staging = state / 'source.next'
    if staging.exists():
        shutil.rmtree(staging)
    staging.mkdir()
    run(['tar', '-xf', str(archive), '-C', str(staging)])
    fingerprint = build_id(staging)
    if installed.get('buildID') == fingerprint:
        installed['source'] = revision
        atomic_json(state / 'installed.json', installed)
        shutil.rmtree(staging)
        return 'Up to date: ' + fingerprint
    if not ci_ready(config['repository'], revision):
        shutil.rmtree(staging)
        return 'Waiting for successful main CI: ' + revision[:10]
    if target.exists():
        shutil.rmtree(target)
    staging.rename(target)
    metadata = state / 'built.json'
    built = json.loads(metadata.read_text()) if metadata.exists() else {}
    app = state / 'DerivedData/Build/Products/Debug-iphoneos/Starfall.app'
    log = state / 'build.log'
    if built.get('buildID') != fingerprint or not app.exists():
        log.write_text('Source: ' + revision + '\nBuild: ' + fingerprint + '\n')
        run(['xcodebuild', '-project', 'Starfall.xcodeproj', '-scheme', 'Starfall', '-configuration', 'Debug',
             '-destination', 'id=' + config['device'], '-derivedDataPath', str(state / 'DerivedData'),
             'DEVELOPMENT_TEAM=' + config['team'], 'STARFALL_BUILD_ID=' + fingerprint,
             '-allowProvisioningUpdates', 'build'], cwd=target, output=log)
    info = plistlib.loads((app / 'Info.plist').read_bytes())
    if info.get('CFBundleIdentifier') != BUNDLE or info.get('StarfallBuildID') != fingerprint:
        raise RuntimeError('Built app identity does not match the one-app contract.')
    run(['codesign', '--verify', '--deep', '--strict', str(app)], output=log)
    atomic_json(metadata, {'buildID': fingerprint, 'source': revision})
    # No automatic launch: updating should not start the clock or trigger a fixture.
    run(['xcrun', 'devicectl', 'device', 'install', 'app', '--device', config['device'], str(app),
         '--timeout', '90', '--json-output', str(state / 'installation.json')], output=state / 'device.log')
    atomic_json(state / 'installed.json', {'buildID': fingerprint, 'source': revision, 'bundle': BUNDLE})
    return 'Installed ' + fingerprint + ' from main ' + revision[:10]


def enable(state):
    config = state / 'config.json'
    if not config.exists():
        raise RuntimeError('Configure the device/team before enabling updates.')
    for name in ['device-update.py', 'build_identity.py']:
        shutil.copyfile(Path(__file__).with_name(name), state / name)
    agent = Path.home() / 'Library/LaunchAgents' / (LABEL + '.plist')
    agent.parent.mkdir(parents=True, exist_ok=True)
    agent.write_bytes(plistlib.dumps({
        'Label': LABEL, 'ProgramArguments': [sys.executable, str(state / 'device-update.py'), '--state', str(state), 'run'],
        'StartInterval': 120, 'RunAtLoad': True,
        'EnvironmentVariables': {'PATH': '/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin'},
        'StandardOutPath': str(state / 'service.log'), 'StandardErrorPath': str(state / 'service-error.log')}))
    subprocess.run(['launchctl', 'bootout', 'gui/' + str(os.getuid()), str(agent)], capture_output=True)
    run(['launchctl', 'bootstrap', 'gui/' + str(os.getuid()), str(agent)])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--state', type=Path, default=DEFAULT_STATE)
    parser.add_argument('action', choices=['configure', 'run', 'status', 'enable', 'disable'])
    parser.add_argument('--device'); parser.add_argument('--team')
    parser.add_argument('--repository', default='lbeezr/starfall')
    args = parser.parse_args()
    state = args.state.expanduser().resolve(); state.mkdir(parents=True, exist_ok=True)
    for name in ['device.log', 'fetch.log', 'service.log', 'service-error.log']:
        log = state / name
        if log.exists() and log.stat().st_size > 2_000_000:
            log.write_text('Previous log trimmed at 2 MB.\n')
    if args.action == 'configure':
        if not args.device or not args.team or args.repository != 'lbeezr/starfall':
            parser.error('Supply --device and --team; this updater is scoped to lbeezr/starfall.')
        atomic_json(state / 'config.json', {'device': args.device, 'team': args.team, 'repository': args.repository})
    elif args.action == 'enable':
        enable(state)
    elif args.action == 'disable':
        agent = Path.home() / 'Library/LaunchAgents' / (LABEL + '.plist')
        subprocess.run(['launchctl', 'bootout', 'gui/' + str(os.getuid()), str(agent)], capture_output=True)
        agent.unlink(missing_ok=True)
    elif args.action == 'status':
        print((state / 'status.json').read_text() if (state / 'status.json').exists() else 'Not run yet.')
    else:
        with (state / 'update.lock').open('w') as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                return
            try:
                message = update(json.loads((state / 'config.json').read_text()), state)
                result = {'status': message}
            except Exception as error:
                result = {'status': 'Update deferred; existing app retained.', 'error': str(error)[-1500:]}
            previous = json.loads((state / 'status.json').read_text()) if (state / 'status.json').exists() else None
            atomic_json(state / 'status.json', result)
            if previous != result:
                print(json.dumps(result), flush=True)


if __name__ == '__main__':
    main()
