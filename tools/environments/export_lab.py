"""Snapshot tracked working-tree bytes for isolated native environment comparisons."""
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile


def export_current_tree(root: Path, prefix: str) -> Path:
    workspace = Path(tempfile.mkdtemp(prefix=prefix))
    provenance = {
        'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root).decode().strip(),
        'dirtyStatus': subprocess.check_output(['git', 'status', '--short'], cwd=root).decode(),
        'files': {},
    }
    paths = subprocess.check_output(['git', 'ls-files', '-z'], cwd=root).decode().split('\0')
    for name in filter(None, paths):
        source = root / name
        if source.is_file():
            data = source.read_bytes()
            target = workspace / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            target.chmod(source.stat().st_mode)
            provenance['files'][name] = hashlib.sha256(data).hexdigest()
    (workspace / 'ENVIRONMENT-LAB-SOURCE.json').write_text(json.dumps(provenance, indent=2))
    return workspace
