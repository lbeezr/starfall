#!/usr/bin/env python3
"""Check the exact isolated candidate and byte-equivalent ordinary replay sample."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
from gravity_candidate import BASE
ROOT=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ref',default=BASE)
args=parser.parse_args()
workspace=Path(subprocess.check_output([sys.executable,str(HERE/'prepare-gravity-lab.py'),'--core-only','--ref',args.ref],text=True).strip())
log=workspace/'package-tests.log'
with log.open('w') as out:
    subprocess.run(['swift','test','--package-path',str(workspace)],stdout=out,stderr=subprocess.STDOUT,check=True)
sys.path.insert(0,str(ROOT/'tools/environments'))
from export_lab import export_committed_tree
baseline=export_committed_tree(ROOT,'starfall-gravity-baseline-',args.ref)
results={}
for label, source in [('baseline',baseline),('candidate',workspace)]:
    binary=workspace/('replay-'+label)
    subprocess.run(['swiftc','-O',*map(str,sorted((source/'Sources/StarfallCore').glob('*.swift'))),str(HERE/'GravityOrdinaryReplay.swift'),'-o',str(binary)],check=True)
    results[label]=subprocess.check_output([str(binary)])
if results['baseline'] != results['candidate']:
    raise RuntimeError('Ordinary encoded replay differs')
manifest=json.loads((workspace/'GRAVITY-LAB.json').read_text())
manifest.update(packageLog=str(log),ordinaryReplayStates=results['baseline'].count(b'\n'),ordinaryReplaySHA256=hashlib.sha256(results['baseline']).hexdigest(),ordinaryReplayEqual=True)
(workspace/'GRAVITY-CHECKS.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest,indent=2))
