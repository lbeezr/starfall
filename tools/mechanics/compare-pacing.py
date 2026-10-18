#!/usr/bin/env python3
"""Execute unchanged Debug Store on macOS with a modeled presenter; no app export/install."""
import argparse
import hashlib
import json
import os
import statistics
import sys
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
p = argparse.ArgumentParser(description=__doc__)
p.add_argument('--seeds', type=int, default=16)
p.add_argument('--seconds', type=float, default=120)
p.add_argument('--baseline-cadence', choices=['openingV1', 'announcedCycleV1', 'announcedCycleV2'], default='openingV1')
p.add_argument('--candidate-cadence', choices=['openingV1', 'announcedCycleV1', 'announcedCycleV2'], default='announcedCycleV1')
p.add_argument('--reaction-seconds', type=float, default=0.45)
p.add_argument('--trace-step-seconds', type=float, default=0.12)
p.add_argument('--output', type=Path, default=root / 'artifacts/pacing')
a = p.parse_args()
if not 1 <= a.seeds <= 200 or not 10 <= a.seconds <= 600:
    p.error('bounds: seeds 1...200, seconds 10...600')
if a.baseline_cadence == a.candidate_cadence:
    p.error('baseline and candidate cadences must differ')
if not 0.05 <= a.reaction_seconds <= 5 or not 0.02 <= a.trace_step_seconds <= 1:
    p.error('bounds: reaction-seconds 0.05...5, trace-step-seconds 0.02...1')
a.output.mkdir(parents=True, exist_ok=True)
inputs = [*sorted((root/'Sources/StarfallCore').glob('*.swift')), root/'App/FallingSkyStore.swift',
          root/'App/ObservatoryReviewFixture.swift', root/'App/SkySaveArchive.swift', root/'App/SkyFlowState.swift', root/'App/FallingSkyHUD.swift',
          root/'Tests/StarfallCoreTests/TimingCycleFixture.swift', *sorted((root/'tools/mechanics').glob('Pacing*.swift')), Path(__file__).resolve()]
def hashes():
    return {str(f.relative_to(root)): hashlib.sha256(f.read_bytes()).hexdigest() for f in inputs}
before = hashes()
with tempfile.TemporaryDirectory(prefix='starfall-pacing-') as d:
    d = Path(d)
    core = sorted((root/'Sources/StarfallCore').glob('*.swift'))
    subprocess.run(['xcrun','swiftc','-O','-DDEBUG','-emit-library','-emit-module','-module-name','StarfallCore',*map(str,core),'-o',str(d/'libStarfallCore.dylib'),'-emit-module-path',str(d/'StarfallCore.swiftmodule')],check=True)
    sources = [f for f in inputs if f.suffix == '.swift' and f not in core
               and f.name not in ('FallingSkyHUD.swift', 'SkyFlowState.swift')]
    # Compile exact current value declarations, excluding unrelated SwiftUI screens.
    hud = (root/'App/FallingSkyHUD.swift').read_text()
    flow = (root/'App/SkyFlowState.swift').read_text()
    values = d/'PacingProductionValues.swift'
    values.write_text('import Foundation\nimport StarfallCore\n'
        + hud[hud.index('struct SkyPhaseCue:'):hud.index('@MainActor struct SkyPhaseLabel')]
        + hud[hud.index('struct SkyCadenceCueCopy:'):hud.index('struct SkyCadenceCue:')]
        + flow[flow.index('enum SkyEntryRequest:'):flow.index('enum SkyFlowEffect:')])
    sources.append(values)
    subprocess.run(['xcrun','swiftc','-Onone','-g','-DDEBUG','-I',str(d),'-L',str(d),'-lStarfallCore',*map(str,sources),'-o',str(d/'pacing')],check=True)
    env = dict(os.environ, DYLD_LIBRARY_PATH=str(d))
    with (a.output/'runs.json').open('w') as out:
        subprocess.run([str(d/'pacing'),str(a.seeds),str(a.seconds),a.baseline_cadence,a.candidate_cadence,str(a.reaction_seconds),str(a.trace_step_seconds)],stdout=out,env=env,check=True)
if hashes() != before:
    raise RuntimeError('Inputs changed during measurement')
metadata = {'head': subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(),
            'dirty': subprocess.check_output(['git','status','--short'],cwd=root,text=True),
            'sha256':before,'platform':subprocess.check_output(['sw_vers'],text=True),
            'toolchain':subprocess.check_output(['xcrun','swiftc','--version'],text=True),
            'command':['python3', *sys.argv],
            'personaVersion':'visible-components-v1', 'timingModelVersion':'scene-durations-v1',
            'reactionSeconds':a.reaction_seconds, 'traceStepSeconds':a.trace_step_seconds,
            'baselineCadence':a.baseline_cadence, 'candidateCadence':a.candidate_cadence,
            'evidence':'Real Debug Store and trace intent; injected virtual clock and model presenter. No native rendering, touch, VoiceOver or human evidence.'}
(a.output/'source.json').write_text(json.dumps(metadata,indent=2)+'\n')
runs = json.loads((a.output/'runs.json').read_text())
def distribution(values):
    values = sorted(values)
    return {'min': values[0], 'median': statistics.median(values), 'p90': values[min(len(values)-1, int(.9*len(values)))], 'max': values[-1]} if values else None
summary = {}
for motion in ['full-motion-model','quiet-model']:
    for persona in ['largest-clear','height-safety','trace-oriented']:
        for cadence in [a.baseline_cadence,a.candidate_cadence]:
            group = [r for r in runs if (r['motion'],r['persona'],r['cadence']) == (motion,persona,cadence)]
            key = '/'.join([motion,persona,cadence])
            summary[key] = {'rounds':len(group), 'overflows':sum(r['overflow'] for r in group),
                'firstClear':distribution([r['firstAcceptedClear'] for r in group if 'firstAcceptedClear' in r]),
                'noOpportunitySeconds':distribution([r['noOpportunitySeconds'] for r in group]),
                'noOpportunityFraction':distribution([r['noOpportunitySeconds']/r['activeSeconds'] for r in group]),
                'longestEarlyGap':distribution([r['longestEarlyGap'] for r in group]),
                'clearsPerActiveMinute':distribution([(r['taps']+r['traces'])*60/r['activeSeconds'] for r in group]),
                'tracesPerActiveMinute':distribution([r['traces']*60/r['activeSeconds'] for r in group]),
                'presentationFraction':distribution([r['presentationSeconds']/r['activeSeconds'] for r in group]),
                'deadlineCancelledTraces':sum(r['deadlineCancelledTraces'] for r in group),
                'traceStarts':sum(r['traceStarts'] for r in group),
                'deferred':sum(r['deferred'] for r in group),
                'lateness':distribution([v for r in group for v in r['lateness']]),
                'deliveredIntervals':distribution([v for r in group for v in r['deliveredIntervals']]),
                'maxHeight':distribution([r['maxHeight'] for r in group]),
                'minimumIncomingHeadroom':distribution([r['minimumIncomingHeadroom'] for r in group])}
pairs = []
for base in [r for r in runs if r['cadence']==a.baseline_cadence]:
    candidate = next(r for r in runs if r['cadence']==a.candidate_cadence and all(r[k]==base[k] for k in ['seed','persona','motion']))
    pairs.append({k:base[k] for k in ['seed','persona','motion']} | {
        'deltaNoOpportunitySeconds':candidate['noOpportunitySeconds']-base['noOpportunitySeconds'],
        'deltaActiveSeconds':candidate['activeSeconds']-base['activeSeconds'],
        'deltaNoOpportunityFraction':candidate['noOpportunitySeconds']/candidate['activeSeconds']-base['noOpportunitySeconds']/base['activeSeconds'],
        'deltaClearsPerActiveMinute':(candidate['taps']+candidate['traces'])*60/candidate['activeSeconds']-(base['taps']+base['traces'])*60/base['activeSeconds'],
        'deltaLongestEarlyGap':candidate['longestEarlyGap']-base['longestEarlyGap'],
        'deltaAcceptedClears':candidate['taps']+candidate['traces']-base['taps']-base['traces'],
        'deltaDeadlineCancelledTraces':candidate['deadlineCancelledTraces']-base['deadlineCancelledTraces']})
(a.output/'summary.json').write_text(json.dumps({'groups':summary,'pairedCounterexamples': sorted(pairs,key=lambda p:p['deltaNoOpportunityFraction'],reverse=True)[:8], 'allPairs':pairs, 'parityCommits':sum(r['parityCommits'] for r in runs)},indent=2)+'\n')
print(a.output/'summary.json')
