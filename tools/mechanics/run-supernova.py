#!/usr/bin/env python3
"""Build an isolated rules candidate; never patch the checkout or touch app saves."""
from pathlib import Path
import argparse
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--rotate", action="store_true", help="Rotate each perimeter survivor to the next identity")
arguments = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="starfall-supernova-") as temporary:
    workspace = Path(temporary)
    source = workspace / "Sources/StarfallCore"
    source.mkdir(parents=True)
    for original in (root / "Sources/StarfallCore").glob("*.swift"):
        (source / original.name).write_bytes(original.read_bytes())
    with (root / "tools/mechanics/supernova.patch").open("rb") as patch:
        subprocess.run(["patch", "--batch", "--fuzz=0", "-p1"], cwd=workspace,
                       stdin=patch, stdout=subprocess.DEVNULL, check=True)
    if arguments.rotate:
        candidate = source / "FallingSky.swift"
        text = candidate.read_text()
        original = "id: survivor.id, kind: kind, grown: survivor.grown)"
        assert text.count(original) == 1, "Candidate patch contract changed"
        text = text.replace(original, "id: survivor.id, kind: Jewel(rawValue: (survivor.kind!.rawValue + 1) % Jewel.allCases.count)!, grown: survivor.grown)")
        # Rotation needs only eligibility, not the charging group's identity.
        text = text.replace("guard value(of: cells) >= 5, let kind = gem(at: cell)?.kind else", "guard value(of: cells) >= 5 else")
        candidate.write_text(text)
    executable = workspace / "sample"
    flags = ["-D", "ROTATE"] if arguments.rotate else []
    subprocess.run(["swiftc", "-O", *flags, *map(str, sorted(source.glob("*.swift"))),
                    str(root / "tools/mechanics/SupernovaSample.swift"),
                    "-o", str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
