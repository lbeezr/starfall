#!/usr/bin/env python3
"""Export separately saved baseline and constellation iPhone apps from one snapshot."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import sys
import tempfile
from constellation_candidate import candidate_source, replace_once
from constellation_trace import apply_trace
from lab_build import stamp_lab

root = Path(__file__).resolve().parents[2]
mechanics = Path(__file__).resolve().parent
sys.path.insert(0, str(root/'tools/environments'))
from export_lab import export_current_tree

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--source', type=Path, help='Reuse an immutable ENVIRONMENT-LAB-SOURCE.json snapshot')
parser.add_argument('--output', type=Path, help='New directory for durable local app projects; never overwrite an existing export')
args = parser.parse_args()
if args.output:
    args.output = args.output.resolve()
    args.output.mkdir(parents=True, exist_ok=False)

snapshot = args.source.resolve() if args.source else export_current_tree(root, 'starfall-constellation-source-')
provenance = json.loads((snapshot/'ENVIRONMENT-LAB-SOURCE.json').read_text())
for name, digest in provenance['files'].items():
    if not (snapshot/name).is_file() or hashlib.sha256((snapshot/name).read_bytes()).hexdigest() != digest:
        raise RuntimeError('Snapshot changed: '+name)
exports = {'snapshot': str(snapshot)}
for mode, title in [('baseline', 'Starfall Control'), ('candidate', 'Constellation Lab')]:
    workspace = args.output/mode if args.output else Path(tempfile.mkdtemp(prefix='starfall-constellation-'+mode+'-'))
    shutil.copytree(snapshot, workspace, dirs_exist_ok=True)
    def edit(name, old, new):
        p = workspace/name
        p.write_text(replace_once(p.read_text(), old, new))
    def append(name, text):
        with (workspace/name).open('a') as output: output.write('\n'+text)
    bundle = 'com.starfall.constellations.'+mode
    suite = 'starfall.constellations.'+mode
    edit('Config/Clean.xcconfig', 'PRODUCT_BUNDLE_IDENTIFIER = com.starfall.prototype',
         'PRODUCT_BUNDLE_IDENTIFIER = '+bundle+'\nINFOPLIST_KEY_CFBundleDisplayName = '+title)
    # No test bundle may collide with production test helpers either.
    project = workspace/'Starfall.xcodeproj/project.pbxproj'
    project.write_text(project.read_text().replace('com.starfall.prototype.', bundle+'.'))
    edit('App/FallingSkyStore.swift', 'defaults: UserDefaults = .standard',
         'defaults: UserDefaults = UserDefaults(suiteName: "'+suite+'")!')
    core = workspace/'Sources/StarfallCore/FallingSky.swift'
    if mode == 'candidate': core.write_text(candidate_source(core.read_text()))
    shutil.copyfile(mechanics/'ConstellationFixture.swift', workspace/'Sources/StarfallCore/ConstellationFixture.swift')
    intro = ('Tap five matching stars linked sideways or diagonally to clear the whole constellation. Large stars count as one star, worth two light. Ordinary matches still need three light.'
             if mode == 'candidate' else 'Control sky: ordinary side-by-side matches need three light. Diagonal connections do not clear.')
    edit('App/FallingSkyStore.swift', 'private(set) var message = "Match stars worth three. Large stars count as two."',
         'private(set) var message = "'+intro+'"')
    # Local reset fixtures must be deliberate; never loaded implicitly on launch.
    edit('App/FallingSkyStore.swift', '        remaining = showerInterval\n        scene.onLayout', '''        if let name = arguments.first(where: { $0.hasPrefix("--constellation-fixture=") }),
           let fixture = ConstellationFixture(rawValue: String(name.dropFirst("--constellation-fixture=".count))) {
            game = fixture.game()
            message = fixture.title + ". Tap a star to try the connection."
        }
        remaining = showerInterval
        scene.onLayout''')
    edit('App/FallingSkyStore.swift', '    func startFirstLight() {', '''    func loadConstellationFixture(_ fixture: ConstellationFixture) {
        isPaused = true
        feedback.stopSounds()
        freezeClock()
        settlePresentation()
        game = fixture.game()
        remaining = showerInterval
        message = fixture.title + ". Tap a star to try the connection."
        save(); presenter.render(game)
    }

    func startFirstLight() {''')
    edit('App/FallingSkyMenu.swift', '    let done: () -> Void', '    let done: () -> Void\n    let labFixture: (ConstellationFixture) -> Void')
    edit('App/FallingSkyMenu.swift', '                Section("Feel & atmosphere") {', '''                Section("'''+title+'''") {
                    Text("Separate comparison app. These examples replace only this lab sky.")
                    ForEach(ConstellationFixture.allCases, id: \\.self) { fixture in
                        Button(fixture.title) { labFixture(fixture) }
                            .accessibilityIdentifier("lab.fixture.\\(fixture.rawValue)")
                    }
                }
                Section("Feel & atmosphere") {''')
    edit('App/FallingSkyView.swift', 'setBalance: store.setBalance, done: { settings = false })',
         'setBalance: store.setBalance, done: { settings = false },\n                       labFixture: { fixture in environmentGeneration += 1; store.loadConstellationFixture(fixture); settings = false })')
    edit('App/FallingSkyMenu.swift', '.navigationTitle("Sky menu")', '.navigationTitle("'+title+'")')
    if mode == 'candidate':
        edit('App/FallingSkyMenu.swift', 'Text("Clear connected matching stars worth at least 3. Small stars count as 1; grown stars count as 2.")',
             'Text("Clear ordinary matching stars worth at least 3 light, connected horizontally or vertically. Or tap any member of a same-family constellation of five actual stars connected sideways or diagonally: the whole constellation clears. A large star counts as one star and scores two light.")')
        edit('App/FallingSkyStore.swift', '"Match stars worth 3 or more. Large stars count as 2."',
             '"Match three light side by side, or five actual stars linked sideways or diagonally. Large stars count as one star, worth two light."')
        edit('App/FallingSkyView.swift', '.accessibilityValue("\\(value) starlight connected")',
             '.accessibilityValue("\\(group.count) matching stars, \\(value) starlight connected")')
        edit('App/FallingSkyView.swift', ': "Needs matching stars worth three. Grown stars count as two")',
             ': "Needs three light horizontally or vertically, or five actual matching stars linked sideways or diagonally")')
        edit('App/FallingSkyView.swift', '? (store.game.darkStarsBeside(group).isEmpty ? "Clear this group to make room" : "Clear this group and dissolve the dark stars beside it")',
             '? (group.count >= 5 ? "Clear the whole constellation and any dark stars directly beside it" : (store.game.darkStarsBeside(group).isEmpty ? "Clear this group to make room" : "Clear this group and dissolve the dark stars beside it"))')
        edit('App/FallingSkyScene.swift', '        let matchable = Set(game.legalGroups.flatMap { $0 })',
             '        renderConstellationLinks(game)\n        let matchable = Set(game.legalGroups.flatMap { $0 })')
        edit('App/FallingSkyScene.swift', '        render(old)\n        rendered = game',
             '        render(old)\n        grid.children.filter { $0.name == "lab.constellation.link" }.forEach { $0.removeFromParent() }\n        rendered = game')
        append('App/FallingSkyScene.swift', (mechanics/'ConstellationLinks.swift').read_text())
    if mode == 'candidate':
        # Same eligibility assertion with the candidate's added spoken star count.
        ui = workspace/'UITests/FallingSkyInteractionTests.swift'
        tests = ui.read_text().replace('"([3-9]|[1-9][0-9]) starlight connected"',
                                       '"([0-9]+ matching stars, )?([3-9]|[1-9][0-9]) starlight connected"')
        tests = tests.replace('NSPredicate(format: "value == %@", "3 starlight connected")',
                              'NSPredicate(format: "value MATCHES %@", "([0-9]+ matching stars, )?3 starlight connected")')
        tests = tests.replace('"Large stars count as 2"', '"Large stars count as one star"')
        ui.write_text(tests)
    if mode == 'candidate':
        apply_trace(workspace)
        # These inherited store regressions exercise ordinary tap actions. Their
        # fixture finder must select a tap-clearable group, not a trace-only group.
        hosted = workspace/'AppTests/FallingSkyStoreTests.swift'
        hosted.write_text(hosted.read_text().replace('store.game.legalGroups', 'store.game.orthogonalLegalGroups'))
        append('AppTests/FallingSkyStoreTests.swift', (mechanics/'ConstellationTraceTests.swift').read_text())
        append('UITests/FallingSkyInteractionTests.swift', (mechanics/'ConstellationTraceUITests.swift').read_text())
    else:
        append('AppTests/FallingSkyStoreTests.swift', (mechanics/'ConstellationStoreTests.swift').read_text().replace('__CANDIDATE__', 'false'))
        append('UITests/FallingSkyInteractionTests.swift', (mechanics/'ConstellationUITests.swift').read_text().replace('__CANDIDATE__', 'false'))
    build_id = stamp_lab(workspace) if mode == 'candidate' else None
    manifest = {'buildID': build_id, 'source': provenance['head'], 'sourceSnapshot': str(snapshot), 'sourceDirtyStatus': provenance['dirtyStatus'],
                'bundle': bundle, 'defaultsSuite': suite, 'mode': mode,
                'toolSHA256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in
                               [Path(__file__), mechanics/'constellation_candidate.py', mechanics/'constellation_trace.py', mechanics/'lab_build.py', *sorted(mechanics.glob('Constellation*.swift'))]},
                'exportSHA256': {str(p.relative_to(workspace)): hashlib.sha256(p.read_bytes()).hexdigest()
                                 for folder in ['App','AppTests','UITests','Sources','Config','Starfall.xcodeproj']
                                 for p in sorted((workspace/folder).rglob('*')) if p.is_file()}}
    (workspace/'CONSTELLATION-LAB.json').write_text(json.dumps(manifest, indent=2, sort_keys=True)+'\n')
    exports[mode] = str(workspace)
print(json.dumps(exports, indent=2, sort_keys=True))
