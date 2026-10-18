#!/usr/bin/env python3
"""Copy a verified selected-trace lab and append only test-target fixture bridges."""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import shutil
import tempfile

mechanics = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--lab', type=Path, required=True, help='Existing verified candidate project folder')
parser.add_argument('--report', type=Path, required=True, help='Output of compare-trace-choices.py')
parser.add_argument('--category', default='same-value-column-safety')
args = parser.parse_args()
source = args.lab.resolve()
manifest_path = source / 'CONSTELLATION-LAB.json'
manifest = json.loads(manifest_path.read_text())
report = json.loads(args.report.read_text())
fixture = next(f for f in report['fixtures'] if f['category'] == args.category)
if manifest['bundle'] != 'com.starfall.constellations.candidate':
    raise RuntimeError('This bridge requires the existing selected-trace lab identity')
for name, digest in manifest['exportSHA256'].items():
    if hashlib.sha256((source / name).read_bytes()).hexdigest() != digest:
        raise RuntimeError('Verified source changed: ' + name)
if manifest['exportSHA256']['Sources/StarfallCore/FallingSky.swift'] != report['provenance']['traceCoreSHA256']:
    raise RuntimeError('Analysis and native Core differ')
workspace = Path(tempfile.mkdtemp(prefix='starfall-trace-choice-capture-'))
for folder in ['App', 'AppTests', 'UITests', 'Sources', 'Config', 'Starfall.xcodeproj']:
    shutil.copytree(source / folder, workspace / folder)
shutil.copyfile(source / 'Package.swift', workspace / 'Package.swift')
for name, digest in manifest['exportSHA256'].items():
    if hashlib.sha256((workspace / name).read_bytes()).hexdigest() != digest:
        raise RuntimeError('Source changed during capture: ' + name)
saved = base64.b64encode(json.dumps(fixture['initial'], separators=(',', ':')).encode()).decode()
for destination, fragment in [('AppTests/FallingSkyStoreTests.swift', 'TraceChoiceStoreBridge.swift'),
                              ('UITests/FallingSkyInteractionTests.swift', 'TraceChoiceCaptureUITests.swift')]:
    text = (mechanics / fragment).read_text().replace('__SAVED_STATE__', saved).replace('__INITIAL_SCORE__', str(fixture['initial']['score']))
    with (workspace / destination).open('a') as output:
        output.write('\n' + text)
inputs = [Path(__file__), mechanics / 'TraceChoiceStoreBridge.swift', mechanics / 'TraceChoiceCaptureUITests.swift']
result = {'workspace': str(workspace), 'bundle': manifest['bundle'], 'buildID': manifest['buildID'],
          'originalLab': str(source), 'originalManifestSHA256': hashlib.sha256(manifest_path.read_bytes()).hexdigest(),
          'analysisReportSHA256': hashlib.sha256(args.report.read_bytes()).hexdigest(),
          'fixtureCategory': args.category, 'fixtureSeed': fixture['seed'], 'fixtureShower': fixture['shower'],
          'initialScore': fixture['initial']['score'], 'runtimeUnchanged': True,
          'scope': 'Test-only committed-save and store-path bridge; no native swipe or extra phone install',
          'toolSHA256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}}
(workspace / 'TRACE-CHOICE-CAPTURE.json').write_text(json.dumps(result, indent=2, sort_keys=True) + '\n')
print(json.dumps(result, indent=2, sort_keys=True))
