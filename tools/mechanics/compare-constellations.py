#!/usr/bin/env python3
"""Offline constellation trial; strict changes in temporary source, never app saves."""
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]

from constellation_candidate import candidate_source

source = root / "Sources/StarfallCore/FallingSky.swift"
text = candidate_source(source.read_text(), analysis=True)
report = {"source": subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
          "dirtyPaths": subprocess.check_output(['git', 'status', '--short'], cwd=root, text=True).splitlines(),
          "candidateSHA256": hashlib.sha256(text.encode()).hexdigest(),
          "inputSHA256": {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in [Path(__file__), root/'tools/mechanics/constellation_candidate.py', root/'tools/mechanics/ConstellationChecks.swift', root/'tools/sample-falling-sky-balance.swift', *sorted((root/'Sources/StarfallCore').glob('*.swift'))]}}
with tempfile.TemporaryDirectory(prefix='starfall-constellations-') as temporary:
    workspace = Path(temporary)
    sources = []
    for original in sorted((root/'Sources/StarfallCore').glob('*.swift')):
        target = workspace/original.name
        target.write_bytes(original.read_bytes())
        sources.append(str(target))
    for mode in ['baseline', 'candidate']:
        if mode == 'candidate':
            (workspace/'FallingSky.swift').write_text(text)
        flags = ['-D', 'CONSTELLATIONS'] if mode == 'candidate' else []
        checker = workspace/'checks'
        subprocess.run(['swiftc', '-O', *flags, *sources, str(root/'tools/mechanics/ConstellationChecks.swift'), '-o', str(checker)], check=True)
        report[mode+'Checks'] = json.loads(subprocess.check_output([str(checker)], text=True))
        sampler = (root/'tools/sample-falling-sky-balance.swift').read_text()
        sampler = sampler.replace('game.letStarsFall()', 'game.letStarsFall(); precondition(game.isValidSave)')
        sampler = sampler.replace('game.clear(chosen.cell);', 'game.clear(chosen.cell); precondition(game.isValidSave); precondition(try! JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game)) == game);')
        sample = workspace/'Sample.swift'
        sample.write_text(sampler)
        executable = workspace/'sample'
        subprocess.run(['swiftc', '-O', *sources, str(sample), '-o', str(executable)], check=True)
        report[mode] = json.loads(subprocess.check_output([str(executable)], text=True))
print(json.dumps(report, indent=2, sort_keys=True))
