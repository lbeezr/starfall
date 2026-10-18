"""Fingerprint runtime/build inputs; documentation and developer state are excluded."""
import hashlib
from pathlib import Path


RUNTIME_FOLDERS = ('App', 'Sources', 'Config', 'Starfall.xcodeproj')
ROOT_BUILD_INPUTS = ('Package.swift', 'Package.resolved')


def build_id(root: Path) -> str:
    digest = hashlib.sha256(b'Starfall runtime inputs v2\0')
    inputs = {root / name for name in ROOT_BUILD_INPUTS if (root / name).is_file()}
    for folder in RUNTIME_FOLDERS:
        inputs.update(path for path in (root / folder).rglob('*')
                      if path.is_file() and 'xcuserdata' not in path.parts
                      and path.suffix.lower() != '.md' and path.name != '.DS_Store')
    for path in sorted(inputs, key=lambda path: path.relative_to(root).as_posix()):
        name = path.relative_to(root).as_posix().encode()
        data = path.read_bytes()
        digest.update(len(name).to_bytes(8, 'big')); digest.update(name)
        digest.update(len(data).to_bytes(8, 'big')); digest.update(data)
    return 'dev.' + digest.hexdigest()[:10]
