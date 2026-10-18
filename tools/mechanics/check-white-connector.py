#!/usr/bin/env python3
"""Check an isolated white-connector rule patch; never edit production sources."""
from pathlib import Path
import argparse
import hashlib
import io
import json
import re
import shutil
import subprocess
import tarfile
import tempfile

root = Path(__file__).resolve().parents[2]
mechanics = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ref', default='202aabb', help='Committed baseline with the current FallingSky owner')
arguments = parser.parse_args()
revision = subprocess.check_output(['git', 'rev-parse', arguments.ref + '^{commit}'], cwd=root, text=True).strip()
workspace = Path(tempfile.mkdtemp(prefix='starfall-white-connector-'))
with tarfile.open(fileobj=io.BytesIO(subprocess.check_output(['git', 'archive', revision], cwd=root))) as archive:
    for member in archive:
        if member.isdir():
            continue
        if not member.isfile() or Path(member.name).is_absolute() or '..' in Path(member.name).parts:
            raise RuntimeError('Unexpected archived source: ' + member.name)
        target = workspace / member.name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(archive.extractfile(member).read())
        target.chmod(member.mode)
baseline = workspace / 'baseline-core'
shutil.copytree(workspace / 'Sources/StarfallCore', baseline)
patch = mechanics / 'white-connector.patch'
subprocess.run(['patch', '--batch', '--fuzz=0', '-p1'], cwd=workspace, input=patch.read_bytes(),
               stdout=subprocess.DEVNULL, check=True)
tests = mechanics / 'WhiteConnectorTests.swift'
shutil.copyfile(tests, workspace / 'Tests/StarfallCoreTests/WhiteConnectorTests.swift')
log = workspace / 'package-tests.log'
with log.open('w') as output:
    subprocess.run(['swift', 'test', '--package-path', str(workspace)], stdout=output,
                   stderr=subprocess.STDOUT, check=True)
probe = mechanics / 'WhiteConnectorOrdinaryReplay.swift'
reports = {}
for name, source in [('baseline', baseline), ('candidate', workspace / 'Sources/StarfallCore')]:
    binary = workspace / ('ordinary-' + name)
    subprocess.run(['swiftc', '-O', *map(str, sorted(source.glob('*.swift'))), str(probe), '-o', str(binary)], check=True)
    result = workspace / ('ordinary-' + name + '.jsonl')
    with result.open('wb') as output:
        subprocess.run([str(binary)], stdout=output, check=True)
    reports[name] = result
baseline_bytes = reports['baseline'].read_bytes()
if baseline_bytes != reports['candidate'].read_bytes():
    raise RuntimeError('Ordinary-only deterministic/encoded behavior changed')
def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
counts = re.findall(r'Executed (\d+) tests, with 0 failures', log.read_text())
if not counts:
    raise RuntimeError('No passing package test count found')
summary = {
    'baselineSource': revision, 'workspace': str(workspace), 'packageTestsPassed': max(map(int, counts)),
    'packageLog': str(log), 'ordinaryReplayStates': baseline_bytes.count(b'\n'),
    'ordinaryReplaySHA256': hashlib.sha256(baseline_bytes).hexdigest(),
    'ordinaryReplayEqual': True, 'seeds': [0, 39], 'showerCap': 24,
    'policies': ['first-ready-until-none', 'largest-ready-until-none'],
    'baselineCoreSHA256': sha(baseline / 'FallingSky.swift'),
    'candidateCoreSHA256': sha(workspace / 'Sources/StarfallCore/FallingSky.swift'),
    'toolSHA256': {str(p.relative_to(root)): sha(p) for p in [Path(__file__), patch, tests, probe]},
    'scope': 'Rules/fixtures only; no white spawning, app presentation, production source or normal saves changed',
}
(workspace / 'WHITE-CONNECTOR-LAB.json').write_text(json.dumps(summary, indent=2, sort_keys=True) + '\n')
print(json.dumps(summary, indent=2, sort_keys=True))
