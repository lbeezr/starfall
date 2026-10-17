#!/usr/bin/env python3
"""Export matched natural/Surge comparisons from one current Observatory snapshot."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import sys
import tempfile
import subprocess
import tarfile
import io
from burst_fragments import burst_labels, render_burst_fragment
from shower_candidate import apply_candidate

root = Path(__file__).resolve().parents[2]
mechanics = Path(__file__).resolve().parent
sys.path.insert(0, str(root / "tools/environments"))
from export_lab import export_current_tree

parser = argparse.ArgumentParser(description=__doc__)
selection = parser.add_mutually_exclusive_group()
selection.add_argument("--source", type=Path, help="Reuse an immutable export containing ENVIRONMENT-LAB-SOURCE.json")
selection.add_argument("--ref", help="Capture a committed Git revision, excluding working-tree edits")
args = parser.parse_args()
if args.ref:
    revision = subprocess.check_output(["git", "rev-parse", args.ref + "^{commit}"], cwd=root, text=True).strip()
    snapshot = Path(tempfile.mkdtemp(prefix="starfall-mechanics-committed-source-"))
    archived = subprocess.check_output(["git", "archive", revision], cwd=root)
    files = {}
    with tarfile.open(fileobj=io.BytesIO(archived)) as archive:
        for member in archive:
            if member.isdir():
                continue
            if not member.isfile() or Path(member.name).is_absolute() or ".." in Path(member.name).parts:
                raise RuntimeError("Unexpected archived source: " + member.name)
            data = archive.extractfile(member).read()
            target = snapshot / member.name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            target.chmod(member.mode)
            files[member.name] = hashlib.sha256(data).hexdigest()
    provenance = {"head": revision, "dirtyStatus": "", "files": files}
    (snapshot / "ENVIRONMENT-LAB-SOURCE.json").write_text(json.dumps(provenance, indent=2) + "\n")
else:
    snapshot = args.source or export_current_tree(root, "starfall-mechanics-source-")
provenance = json.loads((snapshot / "ENVIRONMENT-LAB-SOURCE.json").read_text())
# Refuse an incomplete or subsequently edited snapshot before deriving either app.
for name, expected in provenance["files"].items():
    path = snapshot / name
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise RuntimeError("Snapshot bytes changed: " + name)
if args.source is None and args.ref is None:
    for name, expected in provenance["files"].items():
        if name.startswith(("App/", "AppTests/", "UITests/", "Sources/", "Config/", "Starfall.xcodeproj/")) or name == "Package.swift":
            if hashlib.sha256((root / name).read_bytes()).hexdigest() != expected:
                raise RuntimeError("Source changed during export; capture a stable snapshot: " + name)

exports = {"snapshot": str(snapshot)}
for mode, suffix, display in [("natural-only", "natural", "Shower Observatory"),
                              ("dense-burst", "surge", "Surge Observatory")]:
    workspace = Path(tempfile.mkdtemp(prefix="starfall-mechanics-" + suffix + "-"))
    shutil.copytree(snapshot, workspace, dirs_exist_ok=True)
    def replace(name, before, after):
        path = workspace / name
        text = path.read_text()
        if text.count(before) != 1:
            raise RuntimeError("Expected one mechanics anchor in " + name + ": " + repr(before))
        path.write_text(text.replace(before, after))
    bundle = "com.starfall.mechanics.observatory." + suffix
    replace("Config/Clean.xcconfig", "PRODUCT_BUNDLE_IDENTIFIER = com.starfall.prototype",
            "PRODUCT_BUNDLE_IDENTIFIER = " + bundle + "\nINFOPLIST_KEY_CFBundleDisplayName = " + display)
    replace("App/FallingSkyStore.swift", "defaults: UserDefaults = .standard",
            'defaults: UserDefaults = UserDefaults(suiteName: "starfall.mechanics.observatory.' + suffix + '")!')
    core_hash = apply_candidate(workspace, mode)
    # Current production owns paused guidance. Adapt only the recognized legacy
    # view when replaying an older snapshot; do not duplicate its current copy.
    old_guide = 'message: compact ? "Match stars worth three." : store.game.turns == 0 ? "Welcome to the Observatory. Match stars worth three to gather their light." : "Take a breath. Clear at your pace, or invite the next shower.", showsPortrait: !compact)'
    current_guide = 'message: store.message, showsPortrait: !compact)'
    view_source = (workspace / "App/FallingSkyView.swift").read_text()
    if view_source.count(old_guide) == 1:
        replace("App/FallingSkyView.swift", old_guide, current_guide)
    elif view_source.count(current_guide) != 1:
        raise RuntimeError("Unrecognized paused guide owner")
    intro_prefix = "private(set) var message = "
    intro_lines = [line.strip() for line in (root / "App/FallingSkyStore.swift").read_text().splitlines()
                   if line.strip().startswith(intro_prefix)]
    if len(intro_lines) != 1:
        raise RuntimeError("Expected one production initial-message owner")
    legacy_intro = 'private(set) var message = "Start the sky. Clear matching stars to make room; adjust the balance in Settings."'
    store_source = (workspace / "App/FallingSkyStore.swift").read_text()
    if store_source.count(legacy_intro) == 1:
        replace("App/FallingSkyStore.swift", legacy_intro, intro_lines[0])
    elif store_source.count(intro_lines[0]) != 1:
        raise RuntimeError("Unrecognized initial guidance")
    feedback_tests = render_burst_fragment(mechanics / "ObservatoryFeedbackUITests.swift",
                                          {"__LAB_BUNDLE__": bundle})
    if mode == "dense-burst":
        feedback_tests += "\n" + render_burst_fragment(mechanics / "ObservatoryDarkFeedbackUITests.swift",
                                                         {"__LAB_BUNDLE__": bundle})
    with (workspace / "UITests/FallingSkyInteractionTests.swift").open("a") as output:
        output.write("\n" + feedback_tests)
    # The rename fixture compares two legacy generators. A new candidate init
    # intentionally selects new generation; choose legacy explicitly for its
    # independent control while retaining every original fixture assertion.
    replace("Tests/StarfallCoreTests/FallingSkyTests.swift",
            "        var control = FallingSky(seed: 5)\n        for _ in 0..<5",
            '''        var control = FallingSky(seed: 5)
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(control)) as? [String: Any])
        fields.removeValue(forKey: "pairedShowers")
        control = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
        for _ in 0..<5''')
    replace("App/FallingSkyStore.swift", "        remaining = showerInterval\n        scene.onLayout", '''        if arguments.contains("--shower-phase-fixture") {
            game = FallingSky(seed: 5)
            for _ in 0..<8 {
                game.letStarsFall()
                if let cell = game.legalGroups.first?.first { game.clear(cell) }
            }
            precondition(game.isValidSave && !game.isOver && game.turns == 8)
            message = "Sky paused. Clear at your pace or call the next shower."
        }
        remaining = showerInterval
        scene.onLayout''')
    if mode == "dense-burst":
        labels = burst_labels(bundle, surge=True, preview_visible=False)
        def fragment(name):
            text = render_burst_fragment(mechanics / name, labels).replace("StarfallExperiment", "FallingSky").replace("ExperimentRecorder", "FallingSkyRecorder")
            if name == "NativeBurstView.swift":
                text = text.replace('Label(phaseText, systemImage:', 'Label(largeText ? shortPhaseText : phaseText, systemImage:')
                text = text.replace('.accessibilityIdentifier("lab.phase")', '.accessibilityLabel(phaseText)\n            .accessibilityIdentifier("lab.phase")')
                anchor = "    private var phaseCue: some View {"
                if text.count(anchor) != 1:
                    raise RuntimeError("Expected one phase presentation owner")
                text = text.replace(anchor, '''    // Short visual copy makes room at accessibility sizes without shrinking type.
    // Full phase wording remains the authoritative spoken label.
    private var shortPhaseText: String {
        if store.game.isOver { return "Sky ended" }
        if store.game.challenge != nil { return "First Light" }
        switch FallingSky.showerPhase(for: phaseForecastNumber) {
        case .preparation(let remaining):
            if remaining == 1 { return "Surge next" }
            return "\\(phaseForecastNumber > 12 ? "Recovery" : "Calm") · \\(remaining)"
        case .pressure(let remaining): return "Surge · \\(remaining)"
        }
    }

''' + anchor)
            return text
        view = "App/FallingSkyView.swift"
        replace(view, "import SpriteKit", "import SpriteKit\nimport UIKit")
        replace(view, "                compactHeader\n", '''                compactHeader
                if !largeText {
                    phaseCue.padding(.horizontal, StarfallTheme.Spacing.small)
                        .padding(.vertical, StarfallTheme.Spacing.compact)
                        .foregroundStyle(StarfallTheme.Colors.textPrimary)
                        .shadow(color: StarfallTheme.Colors.skyTop, radius: 3)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
''')
        replace(view, "            if largeText {\n                ScrollView {", '''            if largeText {
                VStack(spacing: 0) {
                    phaseCue.labelStyle(.titleOnly)
                        .padding(StarfallTheme.Spacing.small)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(StarfallTheme.Colors.textPrimary)
                        .background(StarfallTheme.Colors.skyTop)
                    ScrollView {''')
        replace(view, "                .ignoresSafeArea()\n            } else {",
                "                .ignoresSafeArea()\n                }\n            } else {")
        for destination, text in [(view, fragment("NativeBurstView.swift")),
                                  ("AppTests/FallingSkyStoreTests.swift", fragment("BurstStoreTests.swift")),
                                  ("AppTests/FallingSkyStoreTests.swift", fragment("BurstAnnouncementTests.swift")),
                                  ("UITests/FallingSkyInteractionTests.swift", fragment("NativeBurstUITestSupport.swift")),
                                  ("UITests/FallingSkyInteractionTests.swift", fragment("ObservatoryBurstUITests.swift"))]:
            with (workspace / destination).open("a") as output:
                output.write("\n" + text)
    normalized = (workspace / "Sources/StarfallCore/FallingSky.swift").read_text().replace("FallingSky", "StarfallExperiment")
    normalized = normalized.replace(
        "/// Production falling-sky rules with deterministic shower events. The Debug classic Game is independent.",
        "/// Separate accumulation experiment with deterministic shower events. The original Game is unchanged.")
    tool_inputs = [Path(__file__), root / "App/FallingSkyStore.swift", mechanics / "shower_candidate.py", mechanics / "paired-showers-natural.patch",
                   mechanics / "burst_fragments.py", mechanics / "ShowerBurstPhase.swift",
                   mechanics / "ObservatoryFeedbackUITests.swift"]
    if mode == "dense-burst":
        tool_inputs += [mechanics / name for name in ["NativeBurstView.swift", "BurstStoreTests.swift", "BurstAnnouncementTests.swift",
                                                     "NativeBurstUITestSupport.swift", "ObservatoryBurstUITests.swift", "ObservatoryDarkFeedbackUITests.swift"]]
    manifest = {"baselineSource": provenance["head"], "snapshot": str(snapshot), "candidate": mode,
                "bundle": bundle, "presentation": "paused-committed-feedback", "candidateCoreSHA256": core_hash,
                "normalizedFrozenCoreSHA256": hashlib.sha256(normalized.encode()).hexdigest(),
                "toolSHA256": {str(path.relative_to(root)): hashlib.sha256(path.read_bytes()).hexdigest() for path in tool_inputs}}
    (workspace / "MECHANICS-LAB.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    exports[suffix] = str(workspace)
print(json.dumps(exports, indent=2, sort_keys=True))
