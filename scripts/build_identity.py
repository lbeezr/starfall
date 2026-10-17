"""One runtime fingerprint for local device installs and historical lab exports."""
import hashlib
from pathlib import Path


def build_id(root: Path) -> str:
    digest = hashlib.sha256()
    for folder in ['App', 'Sources', 'Config', 'Starfall.xcodeproj']:
        for path in sorted((root / folder).rglob('*')):
            if path.is_file() and 'xcuserdata' not in path.parts:
                name = str(path.relative_to(root)).encode()
                data = path.read_bytes()
                digest.update(len(name).to_bytes(8, 'big')); digest.update(name)
                digest.update(len(data).to_bytes(8, 'big')); digest.update(data)
    return 'dev.' + digest.hexdigest()[:10]
