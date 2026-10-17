#!/usr/bin/env python3
"""Export committed source for simulator-only Debug pacing comparison. No build/install."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile


def replace(path, old, new):
    text = path.read_text()
    if text.count(old) != 1:
        raise RuntimeError(f"Expected one export anchor in {path}: {old!r}")
    path.write_text(text.replace(old, new))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", default="HEAD", help="Committed source ref")
    parser.add_argument("--output", type=Path, required=True, help="New empty destination")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    revision = subprocess.check_output(["git", "rev-parse", args.source], cwd=root, text=True).strip()
    destination = args.output.resolve()
    if destination.exists():
        raise SystemExit("Output must not already exist")
    payload = subprocess.check_output(["git", "archive", revision], cwd=root)
    destination.mkdir(parents=True)
    with tarfile.open(fileobj=io.BytesIO(payload)) as archive:
        # Support the system Python shipped with Xcode as well as newer Python.
        for member in archive.getmembers():
            target = (destination / member.name).resolve()
            if destination not in target.parents or not (member.isfile() or member.isdir()):
                raise RuntimeError(f"Unsupported archive entry: {member.name}")
        archive.extractall(destination)
    fixture = destination / "Tests/StarfallCoreTests/TimingCycleFixture.swift"
    fixture_hash = hashlib.sha256(fixture.read_bytes()).hexdigest()
    project = destination / "Starfall.xcodeproj/project.pbxproj"
    app_sources = "00000000000000000000000A = { isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ("
    replace(project, app_sources, app_sources + "CADE00000000000000000002,")
    view = destination / "App/FallingSkyView.swift"
    replace(view, "@State private var store = FallingSkyStore.forSkyFlowApp()", '''@State private var store: FallingSkyStore = {
        #if DEBUG && targetEnvironment(simulator)
        let arguments = ProcessInfo.processInfo.arguments
        let policy = arguments.first { $0.hasPrefix("--pacing-policy=") } ?? "--pacing-policy=A"
        precondition(["--pacing-policy=A", "--pacing-policy=B"].contains(policy))
        // One simulator app identity; isolated defaults, reset round required for B.
        let defaults = UserDefaults(suiteName: "starfall.pacing.candidate")!
        let store = FallingSkyStore(defaults: defaults)
        if policy == "--pacing-policy=B" {
            precondition(arguments.contains("--starfalls-reset"), "Candidate B must start a fresh test round")
            store.configureTimingTest(lookup: {
                TimingCycleFixture.step(committedShowers: $0.turns, pace: $0.balance.pace)
            })
        }
        return store
        #else
        return FallingSkyStore.forSkyFlowApp()
        #endif
    }()''')
    # B needs fixed layout from opening onward: scene resizing settles presentation.
    # Keep this comparison-only choice out of the normal app's launch routes.
    replace(view, "    private var cadenceCueCopy:", "    private var reservesTimingCueSpace: Bool { ProcessInfo.processInfo.arguments.contains(\"--pacing-policy=B\") }\n\n    private var cadenceCueCopy:")
    replace(view, """                if !settings, let copy = cadenceCueCopy {
                    SkyCadenceCue(copy: copy)
                }""", """                if reservesTimingCueSpace {
                    ZStack(alignment: .leading) {
                        // Stable slot remains behind ceremonies and Settings.
                        // Only gameplay exposes the real cue through cadenceCueCopy.
                        SkyCadenceCue(copy: SkyCadenceCueCopy(step: .init(delay: 0, phase: .steady, warnsFasterNext: true))!)
                            .hidden().accessibilityHidden(true).accessibilityIdentifier("sky.cadence.measurement")
                        if !settings, let copy = cadenceCueCopy {
                            SkyCadenceCue(copy: copy)
                        }
                    }
                }""")
    content = view.read_text()
    if content.count("cadenceCueCopy == nil ? .all : [.horizontal, .bottom]") != 2:
        raise RuntimeError("Expected two shared cue layout branches")
    view.write_text(content.replace("cadenceCueCopy == nil ? .all : [.horizontal, .bottom]",
                                    "reservesTimingCueSpace ? [.horizontal, .bottom] : .all"))
    replace(destination / "UITests/PacingCueUITests.swift", "static let isCandidateExport = false", "static let isCandidateExport = true")
    manifest = {"source": revision, "fixture": str(fixture.relative_to(destination)),
                "fixtureSHA256": fixture_hash, "policyB": "announcedCycleV1",
                "configuration": "Debug simulator only", "bundleID": "com.starfall.prototype",
                "launchA": ["--starfalls-reset", "--starfalls-seed=5", "--pacing-policy=A"],
                "launchB": ["--starfalls-reset", "--starfalls-seed=5", "--pacing-policy=B"],
                "adaptations": ["fixture app membership", "simulator Debug view initializer", "candidate UI test marker", "fixed B cue slot to preserve scene size"]}
    (destination / "pacing-candidate-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(json.dumps({"output": str(destination), **manifest}, indent=2))


if __name__ == "__main__":
    main()
