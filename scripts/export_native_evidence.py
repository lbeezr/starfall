"""Export the bounded native acceptance captures without certifying partial runs."""
import argparse
import hashlib
import json
from pathlib import Path
import sys

MAX_IMAGE_BYTES = 5_000_000
MAX_MANIFEST_BYTES = 250_000
SHIPPING_IMAGES = ['flow-welcome', 'flow-entry', 'island-timer-active',
                   'critical-mass-rescue', 'flow-win', 'flow-full']
CLASSIC_IMAGES = [
    'real-touch-post-clear', 'real-touch-restarted',
    'adaptive-layout-initial', 'adaptive-layout-reflowed', 'adaptive-layout-restarted',
    'saved-game-resumed', 'saved-game-calm-turn',
    'terminal-won-restored', 'terminal-lost-restored', 'terminal-last-move-won-restored',
    'accessibility-large-text-menu-before-audit',
    'accessibility-large-text-game', 'accessibility-large-text-settings',
    'crystal-pilot-before-tap', 'crystal-pilot-after-tap',
    'rapid-input-settled', 'accessible-board-post-clear', 'settings-direct-largest-text',
    'settings-footer-fully-visible', 'settings-default-text', 'settings-default-initial',
    'family-calm-6-resumed', 'family-calm-0-resumed'
]
CLASSIC_IMAGES += [f'family-{kind}-{stage}'
                    for kind in ('rose', 'aqua', 'amber', 'violet', 'mint')
                    for stage in ('before', 'settled')]

REQUIRED_IMAGES = CLASSIC_IMAGES + SHIPPING_IMAGES


def objects(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from objects(child)
    elif isinstance(value, list):
        for child in value:
            yield from objects(child)


def named(record, name):
    label = record.get('suggestedHumanReadableName', '')
    return isinstance(label, str) and (label == name or label.startswith(name + '_'))


def select_images(manifest, root, output, passed, names, records=None):
    if records is None: records = []
    candidates = [value for value in objects(manifest) if value.get('exportedFileName')]
    for name in names:
        matches = [record for record in candidates if named(record, name)]
        if not matches and not passed:
            continue  # Failed runs need not have reached every later scene.
        if len(matches) != 1:
            raise ValueError(f'Expected exactly one named attachment {name}; found {len(matches)}')
        filename = matches[0]['exportedFileName']
        if not isinstance(filename, str) or Path(filename).name != filename or filename in ('.', '..'):
            raise ValueError('Unexpected attachment path')
        source = root / filename
        if source.is_symlink() or not source.is_file():
            raise ValueError('Expected a regular, nonsymlink attachment file')
        with source.open('rb') as image:
            data = image.read(MAX_IMAGE_BYTES + 1)
        if not data.startswith(b'\x89PNG\r\n\x1a\n') or len(data) > MAX_IMAGE_BYTES:
            raise ValueError(f'{name}: expected PNG below 5 MB')
        target = output / (name + '.png')
        target.write_bytes(data)
        records.append(dict(name=name, file=target.name, sha256=hashlib.sha256(data).hexdigest(), export=matches[0]))
    return records


def clear_outputs(output):
    output.mkdir(parents=True, exist_ok=True)
    for name in REQUIRED_IMAGES:
        (output / (name + '.png')).unlink(missing_ok=True)
    for name in ['ui-export-manifest.json', 'ui-attachment-manifest.json', 'ui-evidence-status.json']:
        (output / name).unlink(missing_ok=True)


def export(root, output, summary_path, expectations_path, exit_code):
    root = root.resolve()
    clear_outputs(output)
    status = dict(testPassed=exit_code == 0, xcodebuildExitCode=exit_code,
                  namedScreenshotsExported=0, partialEvidenceOnly=exit_code != 0,
                  complete=False, errors=[])
    records = []
    try:
        try:
            summary = json.loads(summary_path.read_text())
        except (OSError, ValueError) as error:
            if exit_code == 0:
                raise ValueError('Missing or invalid UI test summary') from error
            status['errors'].append('UI summary unavailable: ' + str(error))
            summary = None
        if exit_code == 0:
            if not isinstance(summary, dict):
                raise ValueError('UI test summary must be an object')
            expected = json.loads(expectations_path.read_text())['StarfallUITests']['expectedCount']
            if (summary.get('passedTests') != expected or summary.get('failedTests') != 0
                    or summary.get('skippedTests') != 0 or summary.get('totalTestCount') != expected):
                raise ValueError(f'Expected {expected} passing UI tests, zero failures/skips')
        manifest_path = root / 'manifest.json'
        if not manifest_path.exists() and exit_code != 0:
            status['errors'].append('Attachment manifest unavailable; no images certified')
            return status
        if manifest_path.is_symlink() or not manifest_path.is_file():
            raise ValueError('Expected a regular attachment manifest')
        with manifest_path.open('rb') as source:
            raw_manifest = source.read(MAX_MANIFEST_BYTES + 1)
        if len(raw_manifest) > MAX_MANIFEST_BYTES:
            raise ValueError('Attachment manifest exceeds compact evidence limit')
        manifest = json.loads(raw_manifest)
        (output / 'ui-export-manifest.json').write_bytes(raw_manifest)
        select_images(manifest, root, output, exit_code == 0, REQUIRED_IMAGES, records)
        status['namedScreenshotsExported'] = len(records)
        status['complete'] = exit_code == 0
        return status
    except Exception as error:
        status['errors'].append(str(error))
        raise
    finally:
        status['namedScreenshotsExported'] = len(records)
        (output / 'ui-attachment-manifest.json').write_text(json.dumps(records, indent=2) + '\n')
        (output / 'ui-evidence-status.json').write_text(json.dumps(status, indent=2) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reset-only', action='store_true')
    parser.add_argument('root', type=Path, nargs='?')
    parser.add_argument('exit_code', type=int, nargs='?')
    parser.add_argument('--output', type=Path, default=Path('artifacts'))
    parser.add_argument('--summary', type=Path, default=Path('artifacts/ui-test-summary.json'))
    parser.add_argument('--expectations', type=Path, default=Path('artifacts/native-test-expectations.json'))
    args = parser.parse_args()
    if args.reset_only:
        clear_outputs(args.output)
        return 0
    if args.root is None or args.exit_code is None:
        parser.error('root and exit_code are required for export')
    try:
        result = export(args.root, args.output, args.summary, args.expectations, args.exit_code)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(str(error), file=sys.stderr)
        return 1
    print(f"Exported {result['namedScreenshotsExported']} named screenshots; complete={result['complete']}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
