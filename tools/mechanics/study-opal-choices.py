#!/usr/bin/env python3
"""Bounded production-Core opportunity study; never edits app rules or normal saves."""
from pathlib import Path
import argparse
import hashlib
import json
import statistics
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).with_name('opal-choice-study.swift')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--seed-start', type=int, default=0)
    parser.add_argument('--seeds', type=int, default=64)
    parser.add_argument('--showers', type=int, default=24)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--calibration', action='store_true', help='Current feeding-Dusk recipe/exchange action-budget study')
    parser.add_argument('--dusk-rule', choices=['feeding', 'patientFeeding'], default='patientFeeding',
                        help='Calibration only: explicit historical three-feed or current five-feed rule')
    args = parser.parse_args()
    maximum = 240 if args.calibration else 60
    if not (0 <= args.seed_start <= 10000 and 1 <= args.seeds <= 200 and 6 <= args.showers <= maximum):
        parser.error(f'Bounds: seed-start 0–10000, seeds 1–200, showers 6–{maximum}')
    args.output.mkdir(parents=True, exist_ok=False)
    files = sorted((ROOT / 'Sources/StarfallCore').glob('*.swift'))
    inputs = [Path(__file__), SOURCE, *files]
    digest = lambda: {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}
    hashes = digest()
    provenance = {'source': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
                  'dirtyPaths': subprocess.check_output(['git', 'status', '--short'], cwd=ROOT, text=True).splitlines(),
                  'inputSHA256': hashes,
                  'toolchain': subprocess.check_output(['swiftc', '--version'], text=True).strip(),
                  'command': ['python3', *sys.argv],
                  'method': 'Production Core unchanged; one visible-board clear per shower; complete taps/full components plus bounded connected fives; forecast outcomes are oracle diagnostics only.'}
    if args.calibration:
        provenance['method'] = 'Production Core unchanged, current generation/cadence with selected Dusk version; four visible-reward policies, bounded exchanges and one/all clear budgets. No human timing or forecast selection.'
    with tempfile.TemporaryDirectory(prefix='starfall-opal-choices-') as directory:
        temporary = Path(directory)
        copied = []
        for file in [*files, SOURCE]:
            destination = temporary / file.name
            destination.write_bytes(file.read_bytes())
            copied.append(str(destination))
        binary = temporary / 'study'
        command = ['swiftc', '-O', '-DDEBUG', *copied, '-o', str(binary)]
        provenance['compileFlags'] = ['-O', '-DDEBUG']
        with (args.output / 'compile.log').open('w') as log:
            subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=True)
        with (args.output / 'runs.json').open('w') as report, (args.output / 'progress.log').open('w') as progress:
            subprocess.run([str(binary), str(args.seed_start), str(args.seeds), str(args.showers)] + (['--calibration', '--dusk-rule=' + args.dusk_rule] if args.calibration else []),
                           stdout=report, stderr=progress, check=True)
    if digest() != hashes:
        raise RuntimeError('Inputs changed during analysis; discard this run')
    data = json.loads((args.output / 'runs.json').read_text())
    provenance['selfChecks'] = 'Passed before sampling: topology/cap, colored anchor legality, deduplication, fixture consumption, source immutability, Core JSON round-trip, phase boundaries, and drained legal clears use collectible reward.'
    if args.calibration:
        provenance['selfChecks'] += ' Calibration: authored setup improves visible reward, leaves source untouched and preserves turn/forecast; every sampled post-action state validates and round-trips.'
        def distribution(values):
            ordered = sorted(values)
            return {'min': ordered[0], 'median': statistics.median(ordered),
                    'p90': ordered[min(len(ordered) - 1, int(0.9 * len(ordered)))], 'max': ordered[-1]}
        summary = {'seedStart': args.seed_start, 'seeds': args.seeds, 'showerLimit': args.showers,
                   'duskRule': data['duskRule'], 'feedingShowers': data['feedingShowers'],
                   'limitation': data['method'], 'policies': {}}
        provenance['duskRule'] = data['duskRule']; provenance['feedingShowers'] = data['feedingShowers']
        for policy, rows in data['policies'].items():
            ended = sum(row['ended'] for row in rows)
            summary['policies'][policy] = {
                'rounds': len(rows), 'ended': ended, 'censored': len(rows) - ended,
                'observedShowers': distribution([row['showers'] for row in rows]),
                'score': distribution([row['score'] for row in rows]),
                'longestNoClearRun': distribution([row['longestNoClearRun'] for row in rows]),
                'totals': {key: sum(row[key] for row in rows) for key in
                           ['clears', 'traces', 'recipes', 'exchanges', 'noClearArrivals', 'lostStarlight']}}
        (args.output / 'summary.json').write_text(json.dumps(summary, indent=2, sort_keys=True) + '\n')
        print(json.dumps(summary, indent=2, sort_keys=True))
    else:
        provenance['selfChecks'] += ' Phase-count reconciliation passed after sampling.'
        print(json.dumps([{k: s[k] for k in ['policy', 'rounds', 'ended', 'score', 'showers', 'counts']}
                          for s in data['summaries']], indent=2, sort_keys=True))
    (args.output / 'source.json').write_text(json.dumps(provenance, indent=2, sort_keys=True) + '\n')


if __name__ == '__main__':
    main()
