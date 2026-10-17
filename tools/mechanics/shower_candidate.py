"""One owner for deriving isolated shower variants from the canonical patch."""
from pathlib import Path
import hashlib
import subprocess

def apply_candidate(workspace: Path, mode: str) -> str:
    if mode not in ("natural-only", "pressure", "burst", "dense-burst", "broad"):
        raise ValueError(f"Unknown shower candidate: {mode}")
    patch_path = Path(__file__).with_name("paired-showers-natural.patch")
    owners = [name for name in ("StarfallExperiment", "FallingSky")
              if (workspace / f"Sources/StarfallCore/{name}.swift").is_file()]
    if len(owners) != 1:
        raise RuntimeError("Expected exactly one falling-sky core owner")
    owner = owners[0]
    patch = patch_path.read_text().replace("StarfallExperiment", owner)
    subprocess.run(["patch", "--batch", "--fuzz=0", "-p1"], cwd=workspace,
                   input=patch.encode(), stdout=subprocess.DEVNULL, check=True)
    candidate = workspace / f"Sources/StarfallCore/{owner}.swift"
    text = candidate.read_text()
    if mode == "broad":
        original = " && count == 5 && reliefColumn == nil"
        replacement = " && count == 5"
    elif mode == "pressure":
        original = "? (reliefColumn ?? heights.indices.filter { heights[$0] <= 4 }.min { heights[$0] < heights[$1] })"
        replacement = original.replace(".min", ".max")
    elif mode in ("burst", "dense-burst"):
        text += "\n" + Path(__file__).with_name("ShowerBurstPhase.swift").read_text().replace("StarfallExperiment", owner)
        if mode == "dense-burst":
            count = "let count = reliefColumn == nil ? naturalCount : 5"
            if text.count(count) != 1:
                raise RuntimeError("Canonical shower count anchor changed")
            text = text.replace(count, "let count = reliefColumn == nil ? (Self.isPressureShower(turns + 1) && pairedShowers == true && challenge == nil ? 5 : naturalCount) : 5")
        selection = "heights.indices.filter { heights[$0] <= 4 }.min { heights[$0] < heights[$1] }"
        original = "? (reliefColumn ?? " + selection + ")"
        replacement = "? (reliefColumn ?? (Self.isPressureShower(turns + 1) ? " + selection.replace(".min", ".max") + " : " + selection + "))"
    else:
        original = replacement = None
    if original is not None:
        if text.count(original) != 1:
            raise RuntimeError("Canonical paired-shower comparison anchor changed")
        text = text.replace(original, replacement)
    candidate.write_text(text)
    return hashlib.sha256(candidate.read_bytes()).hexdigest()
