#!/usr/bin/env python3
"""Compare paired five-star showers with a pinned baseline in temporary copies."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
variant = parser.add_mutually_exclusive_group()
variant.add_argument("--natural-only", action="store_true", help="Pair natural five-star showers only; preserve dry-board relief")
variant.add_argument("--pressure", action="store_true", help="Target a higher eligible primary column in natural five-star showers")
arguments = parser.parse_args()
compatibility = root / "tools/mechanics/ShowerCompatibility.swift"
mode = "pressure" if arguments.pressure else "natural-only" if arguments.natural_only else "broad"
patch_path = root / "tools/mechanics/paired-showers-natural.patch"
revision = "30af812"
inputs = [Path(__file__).resolve(), compatibility, patch_path]
report = {"baselineSource": subprocess.check_output(["git", "rev-parse", revision], cwd=root, text=True).strip(),
          "candidate": mode, "inputSHA256": {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest()
                          for path in inputs}}
with tempfile.TemporaryDirectory(prefix="starfall-shower-comparison-") as temporary:
    workspace = Path(temporary)
    source = workspace / "Sources/StarfallCore"
    archive = subprocess.check_output(["git", "archive", revision, "Sources/StarfallCore", "tools/sample-falling-sky-balance.swift"], cwd=root)
    subprocess.run(["tar", "-xf", "-", "-C", str(workspace)], input=archive, check=True)
    sampler = workspace / "tools/sample-falling-sky-balance.swift"
    report["inputSHA256"].update({str(path.relative_to(workspace)): hashlib.sha256(path.read_bytes()).hexdigest()
                                 for path in [sampler, *source.glob("*.swift")]})
    fixtures = workspace / "baseline-saves.json"
    for name in ["baseline", "paired"]:
        if name == "paired":
            with patch_path.open("rb") as patch:
                subprocess.run(["patch", "--batch", "--fuzz=0", "-p1"], cwd=workspace,
                               stdin=patch, stdout=subprocess.DEVNULL, check=True)
            candidate_file = source / "StarfallExperiment.swift"
            text = candidate_file.read_text()
            if mode == "broad":
                original = " && count == 5 && reliefColumn == nil"
                replacement = " && count == 5"
            elif mode == "pressure":
                original = "? (reliefColumn ?? heights.indices.filter { heights[$0] <= 4 }.min { heights[$0] < heights[$1] })"
                replacement = original.replace(".min", ".max")
            else:
                original = replacement = None
            if original is not None:
                if text.count(original) != 1:
                    raise RuntimeError("Canonical paired-shower comparison anchor changed")
                text = text.replace(original, replacement)
                candidate_file.write_text(text)
            report["candidateCoreSHA256"] = hashlib.sha256(candidate_file.read_bytes()).hexdigest()
        executable = workspace / name
        # Validate every sampled committed state without changing either policy.
        text = sampler.read_text().replace("game.letStarsFall()", "game.letStarsFall(); precondition(game.isValidSave)")
        text = text.replace("game.clear(chosen.cell);", "game.clear(chosen.cell); precondition(game.isValidSave);")
        checked_sampler = workspace / "Sample.swift"
        checked_sampler.write_text(text)
        subprocess.run(["swiftc", "-O", *map(str, sorted(source.glob("*.swift"))),
                        str(checked_sampler), "-o", str(executable)], check=True)
        report[name] = json.loads(subprocess.check_output([str(executable)], text=True))
        checker = workspace / (name + "-compatibility")
        subprocess.run(["swiftc", "-O", *map(str, sorted(source.glob("*.swift"))),
                        str(compatibility), "-o", str(checker)], check=True)
        if name == "baseline":
            subprocess.run([str(checker), str(fixtures), "--capture"], check=True)
        else:
            report["compatibility"] = subprocess.check_output([str(checker), str(fixtures)], text=True).strip()
print(json.dumps(report, indent=2, sort_keys=True))
