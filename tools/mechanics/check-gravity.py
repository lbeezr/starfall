#!/usr/bin/env python3
"""Compare retained generation bytes with pre-gravity production; no app/save writes."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--baseline', default='a1d448092be1caba0be0c7d5cff71cb8c42f3fb3')
args = parser.parse_args()
sys.path.insert(0, str(ROOT / 'tools/environments'))
from export_lab import export_committed_tree
baseline = export_committed_tree(ROOT, 'starfall-gravity-baseline-', args.baseline)
with tempfile.TemporaryDirectory(prefix='starfall-gravity-replay-') as directory:
    results = []
    for label, source in [('baseline', baseline), ('production', ROOT)]:
        binary = Path(directory) / label
        subprocess.run(['swiftc', '-O', *map(str, sorted((source / 'Sources/StarfallCore').glob('*.swift'))),
                        str(ROOT / 'tools/mechanics/GravityOrdinaryReplay.swift'), '-o', str(binary)], check=True)
        results.append(subprocess.check_output([str(binary)]))
    if results[0] != results[1]:
        raise RuntimeError('Retained ordinary generation bytes changed')
    print(json.dumps(dict(baseline=args.baseline, states=results[0].count(b'\n'),
                          sha256=hashlib.sha256(results[0]).hexdigest(), byteEqual=True), indent=2))
