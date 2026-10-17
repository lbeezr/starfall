#!/usr/bin/env python3
"""Measure same-state pressure effects; verify observation preserves every sampled state."""
from pathlib import Path
import argparse
import hashlib
import json
import subprocess
import tempfile
from shower_candidate import apply_candidate

root = Path(__file__).resolve().parents[2]
revision = "30af812"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--dense-burst", action="store_true")
arguments = parser.parse_args()
mode = "dense-burst" if arguments.dense_burst else "burst"
driver = Path(__file__).with_name("ShowerBurstExposure.swift")
inputs = [Path(__file__).resolve(), driver, Path(__file__).with_name("shower_candidate.py"),
          Path(__file__).with_name("ShowerBurstPhase.swift"), Path(__file__).with_name("paired-showers-natural.patch")]
report = {"baselineSource": subprocess.check_output(["git", "rev-parse", revision], cwd=root, text=True).strip(),
          "candidate": mode,
          "method": "Seeds 0...199, canonical first legal group after each delivered shower, cap 60. Compare the generated pressure forecast with preparation targeting from the identical pre-generation state and RNG. Count delivered showers separately from unconsumed previews. No player reaction-time model.",
          "inputSHA256": {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs}}
with tempfile.TemporaryDirectory(prefix="starfall-burst-exposure-") as temporary:
    workspace = Path(temporary)
    archive = subprocess.check_output(["git", "archive", revision, "Sources/StarfallCore"], cwd=root)
    subprocess.run(["tar", "-xf", "-", "-C", str(workspace)], input=archive, check=True)
    report["candidateCoreSHA256"] = apply_candidate(workspace, mode)
    core = workspace / "Sources/StarfallCore/StarfallExperiment.swift"
    sources = sorted((workspace / "Sources/StarfallCore").glob("*.swift"))
    results = []
    for observed in [False, True]:
        if observed:
            text = core.read_text()
            phase = "Self.isPressureShower(turns + 1)"
            if text.count(phase) != (2 if arguments.dense_burst else 1):
                raise RuntimeError("Pressure generation phase anchor changed")
            text = text.replace(phase, "(pressureOverride ?? " + phase + ")")
            substitutions = {
                "private mutating func nextShower() -> [IncomingStar]":
                    "private mutating func nextShower(pressureOverride: Bool? = nil) -> [IncomingStar]",
                "if !isOver { incoming = nextShower() }": """if !isOver {
            let before = self
            incoming = nextShower()
            if Self.isPressureShower(turns + 1) {
                var alternate = before
                let preparation = alternate.nextShower(pressureOverride: false)
                BurstExposureRecorder.record(before, pressure: incoming, preparation: preparation)
            }
        }""",
            }
            for original, replacement in substitutions.items():
                if text.count(original) != 1:
                    raise RuntimeError("Burst exposure observation anchor changed: " + original)
                text = text.replace(original, replacement)
            core.write_text(text)
            report["observedCoreSHA256"] = hashlib.sha256(core.read_bytes()).hexdigest()
        executable = workspace / ("observed" if observed else "reference")
        subprocess.run(["swiftc", "-O", *map(str, sources), str(driver), "-o", str(executable)], check=True)
        results.append(json.loads(subprocess.check_output([str(executable)], text=True)))
    if results[0]["rounds"] != results[1]["rounds"]:
        raise RuntimeError("Observation changed a sampled game state or outcome")
    report["trajectoryVerification"] = "PASS: all 200 per-round committed-state SHA256 traces equal the uninstrumented candidate"
    rounds = results[1]["rounds"]
    events = results[1]["events"]
    delivered = {r["seed"]: r["delivered"] for r in rounds}
    consumed = [e for e in events if e["shower"] <= delivered[e["seed"]]]
    first = [e for e in consumed if 10 <= e["shower"] <= 12]
    reached = [r for r in rounds if r["delivered"] >= 10]
    changed_seeds = sorted({e["seed"] for e in first if e["changed"]})
    if arguments.dense_burst and any(len(e["pressureColumns"]) != 5 for e in consumed):
        raise RuntimeError("Dense burst delivered a pressure forecast with fewer than five stars")
    report.update(rounds=rounds, events=events,
                  summary={"reachedFirstBurst": len(reached), "firstBurstDeliveredShowers": len(first),
                           "firstBurstChangedShowers": sum(e["changed"] for e in first),
                           "firstBurstCountChanges": sum(len(e["pressureColumns"]) != len(e["preparationColumns"]) for e in first),
                           "firstBurstExtraOfferedStars": sum(len(e["pressureColumns"]) - len(e["preparationColumns"]) for e in first),
                           "firstBurstChangedSeeds": changed_seeds,
                           "allDeliveredPressureShowers": len(consumed),
                           "allChangedPressureShowers": sum(e["changed"] for e in consumed),
                           "unconsumedPressurePreviews": len(events) - len(consumed),
                           "seed5FirstBurst": [e for e in first if e["seed"] == 5]})
print(json.dumps(report, indent=2, sort_keys=True))
