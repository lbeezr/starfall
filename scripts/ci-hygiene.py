#!/usr/bin/env python3
"""Small tracked-file guard, not a Swift parser or a substitute for native tests."""
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
tracked = subprocess.check_output(
    ['git', 'ls-files', '-z'], cwd=root
).decode().split('\0')
errors = []
output_parts = {'.build', '.swiftpm', 'DerivedData', 'xcuserdata', '__pycache__'}
ui_modules = {'UIKit', 'AppKit', 'SwiftUI', 'SpriteKit', 'SceneKit', 'AVFoundation',
              'GameKit', 'StoreKit'}
for name in filter(None, tracked):
    path = Path(name)
    if (path.parts[0] == 'artifacts'
            or any(part in output_parts or part.endswith(('.xcresult', '.trace'))
                   for part in path.parts)
            or path.suffix in {'.xcuserstate', '.pyc', '.pyo', '.ipa', '.xcarchive'}
            or any(part.endswith('.xcarchive') for part in path.parts)
            or path.name == '.DS_Store'):
        errors.append(f'{name}: generated/user-specific output is tracked')
    if name.startswith('Sources/StarfallCore/') and path.suffix == '.swift':
        source = root / path
        if not source.exists():
            errors.append(f'{name}: tracked core source is missing')
            continue
        # Catch ordinary imports, including attributed and declaration imports.
        # Compiler/native review remains responsible for conditional/multiline code.
        for line_number, line in enumerate(source.read_text().splitlines(), 1):
            code = line.split('//', 1)[0]
            imported = re.search(
                r'\bimport\s+(?:(?:class|struct|enum|protocol|func|var|let|typealias)\s+)?(\w+)', code)
            if imported and imported[1] in ui_modules:
                errors.append(f'{name}:{line_number}: {imported[1]} belongs outside the core')

if errors:
    print('\n'.join(errors), file=sys.stderr)
    sys.exit(1)
print('PASS: tracked-file hygiene and core UI-import guard. Native validation is separate.')
