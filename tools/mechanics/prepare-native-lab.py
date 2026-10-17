#!/usr/bin/env python3
"""Export a pinned mechanics lab; production source and saves stay untouched."""
from pathlib import Path
import argparse
import json
import hashlib
import subprocess
import tempfile
from shower_candidate import apply_candidate

root = Path(__file__).resolve().parents[2]
mechanics = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
mode = parser.add_mutually_exclusive_group()
mode.add_argument("--showers", action="store_true", help="Export the natural-only paired-shower lab instead of supernova")
mode.add_argument("--baseline", action="store_true", help="Export the matching unchanged baseline for observed comparison")
mode.add_argument("--pressure-showers", action="store_true", help="Export higher-column paired showers with a decision fixture")
mode.add_argument("--burst-showers", action="store_true", help="Export nine preparation / three pressure showers with phase cues")
mode.add_argument("--surge-showers", action="store_true", help="Export three five-star surge showers between preparation phases")
parser.add_argument("--compact-hud", action="store_true", help="Compare the committed compact HUD in a separate phase app")
arguments = parser.parse_args()
if arguments.compact_hud and not (arguments.burst_showers or arguments.surge_showers):
    parser.error("--compact-hud requires --burst-showers or --surge-showers")
revision = "30af812"
is_phase = arguments.burst_showers or arguments.surge_showers
is_shower = arguments.showers or arguments.pressure_showers or is_phase
prefix = "starfall-native-baseline-" if arguments.baseline else "starfall-native-showers-" if is_shower else "starfall-native-supernova-"
workspace = Path(tempfile.mkdtemp(prefix=prefix))
archive = subprocess.run(["git", "archive", revision], cwd=root, check=True, stdout=subprocess.PIPE).stdout
subprocess.run(["tar", "-xf", "-", "-C", str(workspace)], input=archive, check=True)

# Retained jewel-renderer contracts share one owner with the current hosted suite.
renderer_test_paths = ["AppTests/CrystalPilotTests.swift", "AppTests/StarshardFamilyPilotTests.swift"]
for path in renderer_test_paths:
    (workspace / path).write_bytes((root / path).read_bytes())

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
        "bundle": bundle, "toolSHA256": digests,
        "rendererTestSHA256": {path: hashlib.sha256((workspace / path).read_bytes()).hexdigest()
                               for path in renderer_test_paths}, **details}, indent=2, sort_keys=True))
    print(workspace)

if is_shower or arguments.baseline:
    candidate = "dense-burst" if arguments.surge_showers else "burst" if arguments.burst_showers else "pressure" if arguments.pressure_showers else "natural-only" if is_shower else "baseline"
    core_hash = apply_candidate(workspace, candidate) if is_shower else None
    # Keep the ID-generation assertion owned by the current test suite. The
    # frozen test assumed every idle sky survives ten showers; terminal reads
    # intentionally retain the final preview rather than generate fresh IDs.
    contract_path = root / "Tests/StarfallCoreTests/FallingSkyTests.swift"
    contract = contract_path.read_text()
    signature = "    func testSeededShowersVaryAcrossAllFourSizesAndHaveUniqueIDs()"
    start = contract.index(signature)
    end = contract.index("\n    func ", start + len(signature))
    contract = contract[start:end].replace("FallingSky", "StarfallExperiment")
    frozen_path = workspace / "Tests/StarfallCoreTests/StarfallExperimentTests.swift"
    frozen = frozen_path.read_text()
    start = frozen.index(signature)
    end = frozen.index("\n    func ", start + len(signature))
    frozen_path.write_text(frozen[:start] + contract + frozen[end:])
    bundle = "com.starfall.pressureshowerslab" if arguments.pressure_showers else "com.starfall.baselinelab" if arguments.baseline else "com.starfall.pairedshowerslab"
    display = "Pressure Lab" if arguments.pressure_showers else "Sky Baseline" if arguments.baseline else "Shower Lab"
    suite = "starfall.pressure-showers.lab" if arguments.pressure_showers else "starfall.baseline.lab" if arguments.baseline else "starfall.paired-showers.lab"
    if arguments.burst_showers:
        bundle, display, suite = "com.starfall.burstshowerslab", "Phase Lab", "starfall.burst-showers.lab"
    if arguments.surge_showers:
        bundle, display, suite = "com.starfall.surgeshowerslab", "Surge Lab", "starfall.surge-showers.lab"
    if arguments.compact_hud:
        # Presentation-only comparison: retain frozen rules/renderer, but reuse
        # one committed production view/theme instead of forking a compact HUD.
        hud_revision = "be4d869"
        bundle += ".compact"
        display += " HUD"
        suite += ".compact"
        for destination, original in [("App/StarfallExperimentView.swift", "App/FallingSkyView.swift"),
                                      ("App/StarfallTheme.swift", "App/StarfallTheme.swift")]:
            text = subprocess.check_output(["git", "show", hud_revision + ":" + original], cwd=root, text=True)
            (workspace / destination).write_text(text.replace("FallingSky", "StarfallExperiment"))
    replace("Config/Clean.xcconfig", "PRODUCT_BUNDLE_IDENTIFIER = com.starfall.prototype",
            f"PRODUCT_BUNDLE_IDENTIFIER = {bundle}\nINFOPLIST_KEY_CFBundleDisplayName = {display}")
    replace("App/StarfallExperimentStore.swift", "defaults: UserDefaults = .standard",
            f'defaults: UserDefaults = UserDefaults(suiteName: "{suite}")!')
    if not arguments.compact_hud:
        replace("App/StarfallExperimentView.swift", 'store.game.challenge?.title ?? "Starfall"',
                f'store.game.challenge?.title ?? "{display}"')
    if is_shower:
        replace("App/StarfallExperimentStore.swift",
                "Start the sky. Clear matching stars to make room; adjust the balance in Settings.",
                "Clear connected matching stars worth 3+. A grown star (2) beside one small match (1) can clear.")
    if is_phase:
        labels = {
            "__LAB_BUNDLE__": bundle,
            "__BURST_WARNING__": "Five-star surge follows" if arguments.surge_showers else "Pressure follows this shower",
            "__BURST_COUNT__": r'Surge · \(remaining) five-star \(remaining == 1 ? "shower" : "showers")' if arguments.surge_showers else r'Pressure · \(remaining) \(remaining == 1 ? "shower" : "showers") remaining',
            "__BURST_THREE__": "Surge · 3 five-star showers" if arguments.surge_showers else "Pressure · 3 showers remaining",
            "__BURST_PREVIEW_CHECK__": '''            if remaining > 0 {
                XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(
                    format: "identifier BEGINSWITH %@", "experiment.incoming.")).count, 5)
            }''' if arguments.surge_showers and not arguments.compact_hud else "",
            "__BURST_STORE_CHECK__": '''            if (9...11).contains(turn) { XCTAssertEqual(stores[0].game.incoming.count, 5) }
            if (10...12).contains(turn) { XCTAssertEqual(stores[0].pending?.forecast.count, 5) }''' if arguments.surge_showers else "",
        }
        def phase_fragment(name):
            text = (mechanics / name).read_text()
            for token, value in labels.items():
                text = text.replace(token, value)
            if "__BURST_" in text or "__LAB_" in text:
                raise RuntimeError("Unresolved phase fragment token in " + name)
            return text
        view = "App/StarfallExperimentView.swift"
        replace(view, "import SpriteKit", "import SpriteKit\nimport UIKit")
        anchor = "                        compactHeader" if arguments.compact_hud else "                        forecast"
        replace(view, anchor, anchor + "\n                        if !largeText { phaseCue }" if arguments.compact_hud
                else "                        if !largeText { phaseCue }\n" + anchor)
        # At accessibility sizes the controls require scrolling. Keep their
        # announced phase in a sibling region so scrolling cannot hide it.
        replace(view, "            GeometryReader { viewport in\n                ScrollView {", '''            GeometryReader { viewport in
                VStack(spacing: StarfallTheme.Spacing.small) {
                    if largeText {
                        phaseCue.padding(.horizontal, StarfallTheme.Spacing.medium)
                    }
                ScrollView {''')
        replace(view, "            }\n            .accessibilityHidden(settings)",
                "                }\n            }\n            .accessibilityHidden(settings)")
        with (workspace / view).open("a") as output:
            output.write("\n" + phase_fragment("NativeBurstView.swift"))
        replace("App/StarfallExperimentStore.swift", "        remaining = showerInterval\n        scene.onLayout", '''        if arguments.contains("--shower-phase-fixture") {
            game = StarfallExperiment(seed: 5)
            for _ in 0..<8 {
                game.letStarsFall()
                if let cell = game.legalGroups.first?.first { game.clear(cell) }
            }
            precondition(game.isValidSave && !game.isOver && game.turns == 8)
        }
        remaining = showerInterval
        scene.onLayout''')
        ui_path = workspace / "UITests/StarfallExperimentInteractionTests.swift"
        if arguments.compact_hud:
            # This HUD has different controls; retain dedicated assertions rather
            # than running archived forecast-strip tests against a hidden strip.
            ui_path.write_text("import XCTest\n")
        with ui_path.open("a") as output:
            output.write("\n" + phase_fragment("NativeBurstUITestSupport.swift"))
        for destination, fragment in [
            ("UITests/StarfallExperimentInteractionTests.swift",
             "NativeCompactBurstUITests.swift" if arguments.compact_hud else "NativeBurstUITests.swift"),
            ("AppTests/StarfallExperimentStoreTests.swift", "BurstStoreTests.swift"),
        ]:
            with (workspace / destination).open("a") as output:
                output.write("\n" + phase_fragment(fragment))
    if arguments.showers:
        with (workspace / "UITests/StarfallExperimentInteractionTests.swift").open("a") as output:
            output.write("\n" + (mechanics / "NativeShowerUITests.swift").read_text().replace("com.starfall.pairedshowerslab", bundle))
    if arguments.pressure_showers:
        report = json.loads((root / "docs/evidence/pressure-showers-2026-10-17/comparison.json").read_text())
        if report["candidateCoreSHA256"] != core_hash:
            raise RuntimeError("Pressure fixture and exported generator differ")
        fixture = report["decisionFixture"]
        data = json.dumps(fixture["state"], separators=(",", ":"))
        replace("App/StarfallExperimentStore.swift", "        remaining = showerInterval\n        scene.onLayout", f'''        if arguments.contains("--shower-decision-fixture") {{
            game = try! JSONDecoder().decode(StarfallExperiment.self, from: Data(#"{data}"#.utf8))
            precondition(game.isValidSave)
            message = "Two legal groups. Compare which clear leaves room for the announced shower."
        }}
        remaining = showerInterval
        scene.onLayout''')
        for destination, fragment in [
            ("UITests/StarfallExperimentInteractionTests.swift", "NativePressureUITests.swift"),
            ("AppTests/StarfallExperimentStoreTests.swift", "PressureStoreTests.swift"),
        ]:
            tests = (mechanics / fragment).read_text()
            for key in ["safeCell", "unsafeCell"]:
                for axis in ["row", "column"]:
                    tests = tests.replace(f"__{key}_{axis}__", str(fixture[key][axis]))
            tests = tests.replace("__SAFE_SCORE__", str(fixture["state"]["score"] + fixture["safeCollected"]))
            tests = tests.replace("__UNSAFE_SCORE__", str(fixture["state"]["score"] + fixture["unsafeCollected"]))
            tests = tests.replace("__COLD_CHOICES__", str(fixture["seed5ChoiceShowersBy20"]))
            tests = tests.replace("__COLD_SCORE__", str(fixture["seed5ScoreAfter20"]))
            with (workspace / destination).open("a") as output:
                output.write("\n" + tests)
    finish(bundle, candidate=candidate, candidateCoreSHA256=core_hash,
           compactHUDSource=subprocess.check_output(["git", "rev-parse", hud_revision], cwd=root, text=True).strip() if arguments.compact_hud else None,
           uniqueIDTestSHA256=hashlib.sha256(contract.encode()).hexdigest())
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
