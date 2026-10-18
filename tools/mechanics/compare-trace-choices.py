#!/usr/bin/env python3
"""Measure bounded selected-trace choices without changing shipping Core or saves."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import sys
import re
from constellation_candidate import candidate_source
from constellation_trace import trace_core

root = Path(__file__).resolve().parents[2]
mechanics = Path(__file__).resolve().parent
sys.path.insert(0, str(root / 'tools/environments'))
from export_lab import export_committed_tree

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ref', default='HEAD', help='Committed production source for the canonical trace transforms')
args = parser.parse_args()
inputs = [Path(__file__), mechanics / 'TraceChoiceAnalysis.swift', mechanics / 'constellation_candidate.py',
          mechanics / 'constellation_trace.py', root / 'tools/environments/export_lab.py']
input_hashes = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
workspace = export_committed_tree(root, 'starfall-trace-choices-', args.ref)
provenance = json.loads((workspace / 'ENVIRONMENT-LAB-SOURCE.json').read_text())
core = workspace / 'Sources/StarfallCore/FallingSky.swift'
core.write_text(trace_core(candidate_source(core.read_text())))
log = workspace / 'package-tests.log'
with log.open('w') as output:
    subprocess.run(['swift', 'test', '--package-path', str(workspace)], stdout=output, stderr=subprocess.STDOUT, check=True)
binary = workspace / 'trace-choices'
analysis_source = workspace / 'TraceChoiceAnalysis.swift'
analysis_source.write_bytes((mechanics / 'TraceChoiceAnalysis.swift').read_bytes())
subprocess.run(['swiftc', '-O', *map(str, sorted((workspace / 'Sources/StarfallCore').glob('*.swift'))),
                str(analysis_source), '-o', str(binary)], check=True)
result = json.loads(subprocess.check_output([str(binary)], text=True))
if input_hashes != {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}:
    raise RuntimeError('Analysis inputs changed during execution')
counts = re.findall(r'Executed (\d+) tests, with 0 failures', log.read_text())
if not counts:
    raise RuntimeError('No executed passing package suite found')
native = json.loads((root / 'docs/evidence/constellation-trace-2026-10-17/source.json').read_text())
native_core = native['exportSHA256']['Sources/StarfallCore/FallingSky.swift']
core_hash = hashlib.sha256(core.read_bytes()).hexdigest()
if core_hash != native_core:
    raise RuntimeError('Derived Core differs from the published selected-trace native evidence; rebase explicitly')
result['provenance'] = {'source': provenance['head'], 'sourceDirtyStatus': provenance['dirtyStatus'],
                        'workspace': str(workspace), 'packageLog': str(log),
                        'packageCount': max(map(int, counts)), 'traceCoreSHA256': core_hash,
                        'publishedTraceNativeCoreMatch': True, 'publishedTraceNativeBuild': native['buildID'],
                        'inputSHA256': input_hashes}
(workspace / 'TRACE-CHOICE-BASELINE.json').write_text(json.dumps(result, indent=2, sort_keys=True) + '\n')
print(json.dumps(result, indent=2, sort_keys=True))
