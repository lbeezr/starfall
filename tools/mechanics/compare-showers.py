#!/usr/bin/env python3
"""Compare paired five-star showers with a pinned baseline in temporary copies."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import tempfile
from shower_candidate import apply_candidate

root = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
variant = parser.add_mutually_exclusive_group()
variant.add_argument("--natural-only", action="store_true", help="Pair natural five-star showers only; preserve dry-board relief")
variant.add_argument("--pressure", action="store_true", help="Target a higher eligible primary column in natural five-star showers")
variant.add_argument("--burst", action="store_true", help="Alternate nine low-column showers with three pressure showers")
variant.add_argument("--dense-burst", action="store_true", help="Use five-star showers during the three-shower pressure burst")
arguments = parser.parse_args()
compatibility = root / "tools/mechanics/ShowerCompatibility.swift"
mode = "dense-burst" if arguments.dense_burst else "burst" if arguments.burst else "pressure" if arguments.pressure else "natural-only" if arguments.natural_only else "broad"
patch_path = root / "tools/mechanics/paired-showers-natural.patch"
revision = "30af812"
inputs = [Path(__file__).resolve(), compatibility, patch_path, root / "tools/mechanics/shower_candidate.py", root / "tools/mechanics/PressureDecisionFixture.swift"]
if mode in ("burst", "dense-burst"):
    inputs.append(root / "tools/mechanics/ShowerBurstChecks.swift")
    inputs.append(root / "tools/mechanics/ShowerBurstPhase.swift")
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
            report["candidateCoreSHA256"] = apply_candidate(workspace, mode)
        executable = workspace / name
        # Validate every sampled committed state without changing either policy.
        text = sampler.read_text().replace("game.letStarsFall()", "game.letStarsFall(); precondition(game.isValidSave)")
        text = text.replace("game.clear(chosen.cell);", "game.clear(chosen.cell); precondition(game.isValidSave);")
        additions = {
            "        var exampleSeeds:": "        var choiceBy20 = 0, choiceAfter20 = 0, noChoice = 0\n        var exampleSeeds:",
            "                var dryRun = 0": "                var firstChoice: Int?\n                var dryRun = 0",
            "                    result.groupCountTotal += available": "                    if available > 1 && firstChoice == nil { firstChoice = game.turns }\n                    result.groupCountTotal += available",
            "                        if groups.count > 1 { result.choiceStates += 1 }": "                        if groups.count > 1 { result.choiceStates += 1; if firstChoice == nil { firstChoice = game.turns } }",
            "                result.rounds += 1;": "                if let firstChoice {\n                    if firstChoice <= 20 { result.choiceBy20 += 1 } else { result.choiceAfter20 += 1 }\n                } else { result.noChoice += 1 }\n                result.rounds += 1;",
        }
        for original, replacement in additions.items():
            if text.count(original) != 1:
                raise RuntimeError("Pinned sampler first-choice metric anchor changed")
            text = text.replace(original, replacement)
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
    if mode in ("burst", "dense-burst"):
        checker = workspace / "burst-checks"
        subprocess.run(["swiftc", "-O", *map(str, sorted(source.glob("*.swift"))),
                        str(root / "tools/mechanics/ShowerBurstChecks.swift"), "-o", str(checker)], check=True)
        report["phaseChecks"] = subprocess.check_output([str(checker)], text=True).strip()
    if mode == "pressure":
        finder = workspace / "decision"
        # Reuse the sampler's authoritative height/pressure definitions.
        analysis = workspace / "Analysis.swift"
        analysis_text = checked_sampler.read_text()
        if analysis_text.count("@main struct BalanceSample") != 1:
            raise RuntimeError("Pinned sampler entry point changed")
        analysis.write_text(analysis_text.replace("@main struct BalanceSample", "struct BalanceSample"))
        subprocess.run(["swiftc", "-O", *map(str, sorted(source.glob("*.swift"))),
                        str(analysis), str(root / "tools/mechanics/PressureDecisionFixture.swift"), "-o", str(finder)], check=True)
        report["decisionFixture"] = json.loads(subprocess.check_output([str(finder)], text=True))
print(json.dumps(report, indent=2, sort_keys=True))
