#!/usr/bin/env python3
"""Export a pinned mechanics lab; production source and saves stay untouched."""
from pathlib import Path
import argparse
import json
import hashlib
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
mechanics = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
mode = parser.add_mutually_exclusive_group()
mode.add_argument("--showers", action="store_true", help="Export the natural-only paired-shower lab instead of supernova")
mode.add_argument("--baseline", action="store_true", help="Export the matching unchanged baseline for observed comparison")
arguments = parser.parse_args()
revision = "30af812"
prefix = "starfall-native-baseline-" if arguments.baseline else "starfall-native-showers-" if arguments.showers else "starfall-native-supernova-"
workspace = Path(tempfile.mkdtemp(prefix=prefix))
archive = subprocess.run(["git", "archive", revision], cwd=root, check=True, stdout=subprocess.PIPE).stdout
subprocess.run(["tar", "-xf", "-", "-C", str(workspace)], input=archive, check=True)

def replace(path, original, replacement):
    file = workspace / path
    text = file.read_text()
    if text.count(original) != 1:
        raise RuntimeError(f"Expected exactly one lab injection anchor in {path}: {original!r}")
    file.write_text(text.replace(original, replacement))

def finish(bundle, **details):
    digests = {path.name: hashlib.sha256(path.read_bytes()).hexdigest() for path in mechanics.iterdir()
               if path.suffix in (".swift", ".py", ".patch")}
    (workspace / "MECHANICS-LAB.json").write_text(json.dumps({
        "source": subprocess.check_output(["git", "rev-parse", revision], cwd=root, text=True).strip(),
        "bundle": bundle, "toolSHA256": digests, **details}, indent=2, sort_keys=True))
    print(workspace)

if arguments.showers or arguments.baseline:
    if arguments.showers:
        with (mechanics / "paired-showers-natural.patch").open("rb") as patch:
            subprocess.run(["patch", "--batch", "--fuzz=0", "-p1"], cwd=workspace, stdin=patch, check=True, stdout=subprocess.DEVNULL)
    bundle = "com.starfall.baselinelab" if arguments.baseline else "com.starfall.pairedshowerslab"
    display = "Sky Baseline" if arguments.baseline else "Shower Lab"
    suite = "starfall.baseline.lab" if arguments.baseline else "starfall.paired-showers.lab"
    replace("Config/Clean.xcconfig", "PRODUCT_BUNDLE_IDENTIFIER = com.starfall.prototype",
            f"PRODUCT_BUNDLE_IDENTIFIER = {bundle}\nINFOPLIST_KEY_CFBundleDisplayName = {display}")
    replace("App/StarfallExperimentStore.swift", "defaults: UserDefaults = .standard",
            f'defaults: UserDefaults = UserDefaults(suiteName: "{suite}")!')
    replace("App/StarfallExperimentView.swift", 'store.game.challenge?.title ?? "Starfall"',
            f'store.game.challenge?.title ?? "{display}"')
    if arguments.showers:
        with (workspace / "UITests/StarfallExperimentInteractionTests.swift").open("a") as output:
            output.write("\n" + (mechanics / "NativeShowerUITests.swift").read_text())
    finish(bundle, candidate="baseline" if arguments.baseline else "paired-showers-natural.patch")
    raise SystemExit(0)

# The offline supernova tool follows production naming. This frozen app uses
# its own archived patch so a later production rename cannot break the lab.
with (workspace / "tools/mechanics/supernova.patch").open("rb") as patch:
    subprocess.run(["patch", "--batch", "--fuzz=0", "-p1"], cwd=workspace, stdin=patch, check=True, stdout=subprocess.DEVNULL)

# Different bundle and defaults suite keep even this installed app separate.
replace("Config/Clean.xcconfig", "PRODUCT_BUNDLE_IDENTIFIER = com.starfall.prototype",
        "PRODUCT_BUNDLE_IDENTIFIER = com.starfall.supernovalab\nINFOPLIST_KEY_CFBundleDisplayName = Supernova Lab")
store = "App/StarfallExperimentStore.swift"
replace(store, "defaults: UserDefaults = .standard", 'defaults: UserDefaults = UserDefaults(suiteName: "starfall.supernova.lab")!')
replace(store, "    static let saveKey", (mechanics / "NativeChargeStore.swift").read_text() + "\n    static let saveKey")
replace(store, "func clear(_ cell: Cell)", "func clear(_ cell: Cell, charged: Bool = false)")
replace(store, "game.clear(cell)", "game.clear(cell, charged: charged)")
replace(store, "    private func present(_ turn: StarfallExperimentTurn, from old: StarfallExperiment) {",
        "    private func present(_ turn: StarfallExperimentTurn, from old: StarfallExperiment) {\n        cancelCharge()")
replace(store, "    func settlePresentation() {", "    func settlePresentation() {\n        cancelCharge()")
replace(store, "    func togglePause() {", "    func togglePause() {\n        cancelCharge()")

# Seed 124/shower 9 is an exact retained counterexample: tap preserves six
# immediately clearable starlight while charge preserves five.
example = json.loads((root / "docs/evidence/supernova-rules-2026-10-17/adopt-identity-depth.json").read_text())[0]["tapExamples"][0]
fixture = json.dumps(example["state"], separators=(",", ":"))
replace(store, "        remaining = showerInterval\n        scene.onLayout", f'''        if arguments.contains("--supernova-fixture") {{
            game = try! JSONDecoder().decode(StarfallExperiment.self, from: Data(#"{fixture}"#.utf8))
            precondition(game.isValidSave)
        }}
        remaining = showerInterval
        scene.onLayout''')

view = "App/StarfallExperimentView.swift"
replace(view, "import SpriteKit", "import SpriteKit\nimport UIKit")
file = workspace / view
text = file.read_text()
start = text.index("        return Button { store.clear(cell) }")
end = text.index("\n    private func cellLabel", start)
text = text[:start] + '''        return NativeChargeCell(label: cellLabel(cell), value: value,
            identifier: "experiment.cell.\\(cell.row).\\(cell.column)",
            enabled: store.canClear, canCharge: value >= 5 && store.game.challenge == nil,
            armed: store.chargeCell == cell,
            prepare: { store.prepareCharge(cell) }, arm: { store.armCharge($0) },
            commit: { store.commitCharge($0) }, cancel: { store.cancelCharge($0) },
            tap: { store.clear(cell) }, accessibleCharge: { store.accessibleCharge(cell) })
            .accessibilityRotorEntry(id: cell, in: matchingGroups)
    }
''' + text[end:]
text += "\n" + (mechanics / "NativeChargeControl.swift").read_text()
file.write_text(text)
replace(view, "                        forecast", '''                        Text(store.chargeCell == nil ? "SUPERNOVA LAB · Hold five or more, release to charge" : "Release for supernova · drag away to cancel")
                            .font(StarfallTheme.Typography.gameDetail)
                            .accessibilityIdentifier("lab.chargeStatus")
                        forecast''')

# Append tests to existing target members; no project membership edits required.
for destination, fragment in [
    ("AppTests/StarfallExperimentStoreTests.swift", "NativeChargeStoreTests.swift"),
    ("UITests/StarfallExperimentInteractionTests.swift", "NativeChargeUITests.swift"),
]:
    with (workspace / destination).open("a") as output:
        output.write("\n" + (mechanics / fragment).read_text())

finish("com.starfall.supernovalab", fixtureSeed=124, fixtureShower=9,
       corePatchSource=f"{revision}:tools/mechanics/supernova.patch",
       corePatchSHA256=hashlib.sha256((workspace / "tools/mechanics/supernova.patch").read_bytes()).hexdigest())
