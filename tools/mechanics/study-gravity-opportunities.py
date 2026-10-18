#!/usr/bin/env python3
"""Compare old and candidate gravity supply using the existing action enumerator."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--seed-start',type=int,required=True)
parser.add_argument('--seeds',type=int,default=64)
parser.add_argument('--showers',type=int,default=36)
parser.add_argument('--output',type=Path,required=True)
args=parser.parse_args()
if not (0<=args.seed_start<=10000 and 1<=args.seeds<=200 and 6<=args.showers<=60):parser.error('Study bounds exceeded')
args.output.mkdir(parents=True,exist_ok=False)
files=sorted((ROOT/'Sources/StarfallCore').glob('*.swift'))
study=ROOT/'tools/mechanics/opal-choice-study.swift'
fragment=Path(__file__).with_name('GravityOpportunityStudy.swift')
inputs=[*files,study,fragment,Path(__file__)]
hashes=lambda:{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
initial=hashes()
with tempfile.TemporaryDirectory(prefix='starfall-gravity-supply-') as directory:
    directory=Path(directory)
    sources=[]
    for source in files:
        copied=directory/source.name;copied.write_bytes(source.read_bytes());sources.append(str(copied))
    text=study.read_text()
    anchor='    static func main() throws {'
    if text.count(anchor)!=1:raise RuntimeError('Study entry contract changed')
    text=text.replace(anchor,anchor+'\n        if CommandLine.arguments[1] == "--gravity-opportunities" { checks(); try gravityOpportunityStudy(); return }')
    combined=directory/'study.swift';combined.write_text(text+'\n'+fragment.read_text())
    binary=directory/'study'
    with (args.output/'compile.log').open('w') as log:
        subprocess.run(['swiftc','-O','-DDEBUG',*sources,str(combined),'-o',str(binary)],stdout=log,stderr=subprocess.STDOUT,check=True)
    command=[str(binary),'--gravity-opportunities',str(args.seed_start),str(args.seeds),str(args.showers)]
    with (args.output/'runs.json').open('w') as out:subprocess.run(command,stdout=out,check=True)
if hashes()!=initial:raise RuntimeError('Inputs changed during sampling')
provenance={'source':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
            'dirtyPaths':subprocess.check_output(['git','status','--short'],text=True).splitlines(),
            'inputSHA256':initial,'method':'One visible-board action per shower; full components/taps and bounded fives at Opal states; collision-first uses only current board; no forecast oracle in selection.'}
(args.output/'source.json').write_text(json.dumps(provenance,indent=2,sort_keys=True)+'\n')
data=json.loads((args.output/'runs.json').read_text())
for item in data['summaries']:
    rounds=item.pop('rounds');item.pop('example')
    item.update(rounds=len(rounds),pairRounds=sum(x['pairOffers']>0 for x in rounds),fieldRounds=sum(x['fieldsCreated']>0 for x in rounds),
                fields=sum(x['fieldsCreated'] for x in rounds),overflow=sum(x['overflow'] for x in rounds),censored=sum(not x['overflow'] for x in rounds),score=sum(x['score'] for x in rounds))
print(json.dumps(data,indent=2,sort_keys=True))
