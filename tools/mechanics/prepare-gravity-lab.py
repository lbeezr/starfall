#!/usr/bin/env python3
"""Export the bounded gravity candidate without changing production source or saves."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import sys
from gravity_candidate import BASE, candidate_source
ROOT=Path(__file__).resolve().parents[2]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools/environments'))
from export_lab import export_committed_tree
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ref',default=BASE)
parser.add_argument('--core-only',action='store_true')
args=parser.parse_args()
workspace=export_committed_tree(ROOT,'starfall-gravity-',args.ref)
core=workspace/'Sources/StarfallCore/FallingSky.swift'
core.write_text(candidate_source(core.read_text())+'\n'+(HERE/'GravityFixtures.swift').read_text())
shutil.copyfile(HERE/'GravityTypes.swift',workspace/'Sources/StarfallCore/GravityTypes.swift')
shutil.copyfile(HERE/'GravityTests.swift',workspace/'Tests/StarfallCoreTests/GravityTests.swift')
if not args.core_only:
    from gravity_native import apply_native
    apply_native(workspace)
build_id=None
if not args.core_only:
    digest=hashlib.sha256()
    for folder in ['App','Sources','Config','Starfall.xcodeproj']:
        for path in sorted((workspace/folder).rglob('*')):
            if path.is_file():
                digest.update(str(path.relative_to(workspace)).encode()); digest.update(path.read_bytes())
    build_id='dev.'+digest.hexdigest()[:10]
    config=workspace/'Config/Clean.xcconfig'
    config.write_text(config.read_text().replace('STARFALL_BUILD_ID = dev.local','STARFALL_BUILD_ID = '+build_id))
inputs=[Path(__file__),ROOT/'tools/environments/export_lab.py',HERE/'gravity_candidate.py',*HERE.glob('Gravity*.swift')]
if not args.core_only: inputs.append(HERE/'gravity_native.py')
manifest={'source':json.loads((workspace/'ENVIRONMENT-LAB-SOURCE.json').read_text())['head'],
          'workspace':str(workspace),'buildID':build_id,'coreOnly':args.core_only,'trace':True,
          'inputs':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}}
(workspace/'GRAVITY-LAB.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(workspace)
