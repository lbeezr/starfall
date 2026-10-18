#!/usr/bin/env python3
"""Compare complete retained generation 0/1/2 encoded histories before supply tuning."""
from pathlib import Path
import argparse, hashlib, json, subprocess, sys, tempfile
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'tools/environments'))
from export_lab import export_committed_tree
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--baseline',required=True)
args=parser.parse_args()
baseline=export_committed_tree(ROOT,'starfall-gravity-supply-baseline-',args.baseline)
probe=Path(__file__).with_name('GravitySupplyReplay.swift')
with tempfile.TemporaryDirectory(prefix='starfall-gravity-supply-replay-') as directory:
    directory=Path(directory);outputs=[]
    for name,tree in [('baseline',baseline),('candidate',ROOT)]:
        binary=directory/name
        subprocess.run(['swiftc','-O',*map(str,sorted((tree/'Sources/StarfallCore').glob('*.swift'))),str(probe),'-o',str(binary)],check=True)
        outputs.append(subprocess.check_output([str(binary)]))
    if outputs[0]!=outputs[1]:raise RuntimeError('Retained generation histories changed')
    print(json.dumps({'baseline':args.baseline,'byteEqual':True,'encodedStates':outputs[0].count(b'\n'),'sha256':hashlib.sha256(outputs[0]).hexdigest(),'generations':[0,1,2],'seeds':40,'policies':2,'showerCap':36},indent=2))
