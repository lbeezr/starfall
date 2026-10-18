#!/usr/bin/env python3
"""Update one connected iPhone from clean GitHub main; never reset or uninstall."""
import argparse
from contextlib import contextmanager
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
from urllib.parse import unquote, urlparse
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


@contextmanager
def service_configuration_lock(state):
    with (state / 'update.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError('An update is running; retry configuration after it finishes.')
        yield


def configure(config, state):
    # Installed/cached state belongs to this device and signing context.
    with service_configuration_lock(state):
        path = state / 'config.json'
        previous = json.loads(path.read_text()) if path.exists() else None
        if previous is not None and previous != config:
            for name in ['installed.json', 'built.json']:
                (state / name).unlink(missing_ok=True)
        atomic_json(path, config)


def ci_status(repository, revision):
    request = urllib.request.Request(
        'https://api.github.com/repos/' + repository + '/actions/runs?head_sha=' + revision + '&per_page=30',
        headers={'Accept': 'application/vnd.github+json', 'User-Agent': 'Starfall-Device-Updater'})
    with urllib.request.urlopen(request, timeout=30) as response:
        runs = json.load(response)['workflow_runs']
    matching = [r for r in runs if r['name'] == 'Starfall simulator' and r['head_sha'] == revision
                and r['head_branch'] == 'main' and r['event'] == 'push']
    latest = max(matching, key=lambda r: (r['run_number'], r.get('run_attempt', 1)), default=None)
    if latest is None:
        return 'missing'
    if latest['status'] != 'completed':
        return 'pending'
    if latest['conclusion'] == 'success':
        return 'passed'
    return 'failed' if latest['conclusion'] == 'failure' else 'unavailable'


def connected(device, state):
    receipt = state / 'devices.json'
    run(['xcrun', 'devicectl', 'list', 'devices', '--json-output', str(receipt)], output=state / 'device.log')
    for item in json.loads(receipt.read_text())['result']['devices']:
        ids = [item.get('identifier'), item.get('hardwareProperties', {}).get('udid')]
        if (device in ids and item.get('hardwareProperties', {}).get('reality') == 'physical'
                and item.get('connectionProperties', {}).get('tunnelState') == 'connected'):
            return True
    return False


def app_installation(config, state):
    """Read the OS-owned installation, rather than trusting our last write."""
    inventory = state / 'apps.json'
    run(['xcrun', 'devicectl', 'device', 'info', 'apps', '--device', config['device'],
         '--bundle-id', BUNDLE, '--json-output', str(inventory)], output=state / 'device.log')
    apps = json.loads(inventory.read_text())['result']['apps']
    if not isinstance(apps, list):
        raise RuntimeError('Cannot verify the phone installation: invalid app inventory.')
    matching = [app for app in apps if app.get('bundleIdentifier') == BUNDLE]
    if len(matching) > 1:
        raise RuntimeError('Cannot verify the phone installation: ambiguous app inventory.')
    if not matching:
        return None
    app = matching[0]
    installation_path(app['url'])
    if not isinstance(app.get('bundleVersion'), str) or not app['bundleVersion']:
        raise RuntimeError('Cannot verify the phone installation: missing bundle version.')
    return {'installationURL': app['url'], 'bundleVersion': app['bundleVersion']}


def installation_path(value):
    parsed = urlparse(value)
    if parsed.scheme != 'file' or parsed.netloc or not parsed.path.startswith('/'):
        raise RuntimeError('Cannot verify the phone installation: invalid installation URL.')
    return unquote(parsed.path).rstrip('/')


def installation_matches(actual, receipt):
    if not actual or not receipt.get('installationURL') or not receipt.get('bundleVersion'):
        return False
    return (installation_path(actual['installationURL']) == installation_path(receipt['installationURL'])
            and actual['bundleVersion'] == receipt['bundleVersion'])


def fetch_main(mirror, state):
    run(['git', 'fetch', '--no-tags', 'origin', 'refs/heads/main'], cwd=mirror, output=state / 'fetch.log')
    return run(['git', 'rev-parse', 'FETCH_HEAD'], cwd=mirror)


def includes_previous_main(mirror, previous, revision):
    if not previous:
        return True
    try:
        run(['git', 'merge-base', '--is-ancestor', previous, revision], cwd=mirror)
        return True
    except subprocess.CalledProcessError:
        # A missing object also fails closed: ancestry was not established.
        return False


def update(config, state):
    if not connected(config['device'], state):
        return 'Waiting for the configured iPhone.'
    mirror = state / 'repository.git'
    url = 'https://github.com/' + config['repository'] + '.git'
    if not mirror.exists():
        run(['git', 'clone', '--bare', url, str(mirror)], output=state / 'fetch.log')
    revision = fetch_main(mirror, state)
    installed = json.loads((state / 'installed.json').read_text()) if (state / 'installed.json').exists() else {}
    previous = installed.get('checkedSource') or installed.get('source')
    if not includes_previous_main(mirror, previous, revision):
        return 'Held: fetched main does not include the previously delivered/checked main.'
    actual = app_installation(config, state)
    matches = installation_matches(actual, installed)
    if matches and revision in (installed.get('source'), installed.get('checkedSource')):
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
    if matches and installed.get('buildID') == fingerprint:
        installed['checkedSource'] = revision
        atomic_json(state / 'installed.json', installed)
        shutil.rmtree(staging)
        return 'Up to date: ' + fingerprint
    cloud_status = ci_status(config['repository'], revision)
    if cloud_status == 'failed':
        shutil.rmtree(staging)
        return 'Held: main CI failed for ' + revision[:10]
    if target.exists():
        shutil.rmtree(target)
    staging.rename(target)
    core_log = state / 'core-tests.log'
    core_log.write_text('Source: ' + revision + '\n')
    run(['swift', 'test'], cwd=target, output=core_log)
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
    if build_id(target) != fingerprint:
        raise RuntimeError('Build source changed during validation; refusing installation.')
    atomic_json(metadata, {'buildID': fingerprint, 'source': revision})
    # A long local build can outlive the initial remote check. A now-known
    # failure holds delivery, retaining this verified build for a later retry.
    if fetch_main(mirror, state) != revision:
        return 'Held: main advanced during validation; retry against the new main.'
    cloud_status = ci_status(config['repository'], revision)
    if cloud_status == 'failed':
        return 'Held: main CI failed before installation for ' + revision[:10]
    # No automatic launch: updating should not start the clock or trigger a fixture.
    run(['xcrun', 'devicectl', 'device', 'install', 'app', '--device', config['device'], str(app),
         '--timeout', '90', '--json-output', str(state / 'installation.json')], output=state / 'device.log')
    result = json.loads((state / 'installation.json').read_text())
    delivered = [item for item in result['result']['installedApplications'] if item.get('bundleID') == BUNDLE]
    actual = app_installation(config, state)
    if (len(delivered) != 1 or not actual or not installation_matches(actual, {
            'installationURL': delivered[0]['installationURL'], 'bundleVersion': info.get('CFBundleVersion')})):
        raise RuntimeError('Installation completed but its on-device identity could not be verified; receipt retained.')
    atomic_json(state / 'installed.json', {'buildID': fingerprint, 'source': revision, 'bundle': BUNDLE, **actual,
                                               'validation': {'coreTests': 'passed', 'signature': 'verified', 'mainCIAtInstall': cloud_status}})
    return 'Installed ' + fingerprint + ' from main ' + revision[:10]


def enable(state):
    # Reloading the service must not terminate a build or installation in flight.
    with service_configuration_lock(state):
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
        configure({'device': args.device, 'team': args.team, 'repository': args.repository}, state)
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
