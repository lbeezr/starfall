#!/usr/bin/env python3
"""Export an isolated white-connector fixture app; never edit shipping sources."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import argparse

root = Path(__file__).resolve().parents[2]
mechanics = Path(__file__).resolve().parent
sys.path.insert(0, str(root / 'tools/environments'))
from export_lab import export_committed_tree

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--ref', default='10346f4', help='Committed comparison source; keep fixed until the current choice trial closes')
args = parser.parse_args()
workspace = export_committed_tree(root, 'starfall-white-native-', args.ref)
provenance = json.loads((workspace / 'ENVIRONMENT-LAB-SOURCE.json').read_text())

def edit(name, before, after):
    path = workspace / name
    text = path.read_text()
    if text.count(before) != 1:
        raise RuntimeError('Expected one white-lab anchor: ' + name + ': ' + repr(before))
    path.write_text(text.replace(before, after))

def append(name, source):
    with (workspace / name).open('a') as output:
        output.write('\n' + (mechanics / source).read_text())

subprocess.run(['patch', '--batch', '--fuzz=0', '-p1'], cwd=workspace,
               input=(mechanics / 'white-connector.patch').read_bytes(), stdout=subprocess.DEVNULL, check=True)
bundle = 'com.starfall.whiteconnector.lab'
suite = 'starfall.whiteconnector.lab.v1'
edit('Config/Clean.xcconfig', 'PRODUCT_BUNDLE_IDENTIFIER = com.starfall.prototype',
     'PRODUCT_BUNDLE_IDENTIFIER = ' + bundle + '\nINFOPLIST_KEY_CFBundleDisplayName = White Connector Lab')
project = workspace / 'Starfall.xcodeproj/project.pbxproj'
project.write_text(project.read_text().replace('com.starfall.prototype.', bundle + '.'))
edit('App/FallingSkyStore.swift', 'defaults: UserDefaults = .standard',
     'defaults: UserDefaults = UserDefaults(suiteName: "' + suite + '")!')
edit('App/FallingSkyStore.swift', 'static let saveKey = "starfall.accumulation.v3"',
     'static let saveKey = "starfall.whiteconnector.lab.v1"')
append('Sources/StarfallCore/FallingSky.swift', 'WhiteConnectorFixtures.swift')
edit('App/FallingSkyStore.swift', '        remaining = showerInterval\n        scene.onLayout', '''        if let argument = arguments.first(where: { $0.hasPrefix("--white-fixture=") }),
           let fixture = WhiteConnectorFixture(rawValue: String(argument.dropFirst("--white-fixture=".count))) {
            game = fixture.game(); message = fixture.message
        }
        remaining = showerInterval
        scene.onLayout''')
edit('App/FallingSkyStore.swift', '    func startFirstLight() {', '''    func loadWhiteFixture(_ fixture: WhiteConnectorFixture) {
        isPaused = true
        feedback.stopSounds()
        freezeClock()
        settlePresentation()
        game = fixture.game()
        remaining = showerInterval
        message = fixture.message
        save(); presenter.render(game)
    }

    func startFirstLight() {''')
edit('App/FallingSkyStore.swift', '            message = game.gem(at: cell)?.isDark == true', '''            if game.gem(at: cell)?.isLight == true {
                message = "Tap a colored neighbor to use the white connector. It is spent with that family."
                announce(message)
                return
            }
            message = game.gem(at: cell)?.isDark == true''')
edit('App/FallingSkyMenu.swift', '    let done: () -> Void',
     '    let done: () -> Void\n    let whiteFixture: (WhiteConnectorFixture) -> Void')
edit('App/FallingSkyMenu.swift', '                Section("Feel & atmosphere") {', '''                Section("White connector examples") {
                    Text(WhiteConnectorFixture.guide)
                    Text("These examples replace only this lab sky.")
                    ForEach(WhiteConnectorFixture.allCases, id: \\.self) { fixture in
                        Button(fixture.title) { whiteFixture(fixture) }
                            .accessibilityIdentifier("white.fixture.\\(fixture.rawValue)")
                    }
                }
                Section("Feel & atmosphere") {''')
edit('App/FallingSkyView.swift', 'setBalance: store.setBalance, done: { settings = false })',
     'setBalance: store.setBalance, done: { settings = false },\n                       whiteFixture: { fixture in environmentGeneration += 1; store.loadWhiteFixture(fixture); settings = false })')
edit('App/FallingSkyView.swift', '        guard let kind = gem.kind else',
     '        if gem.isLight { return "White connector, worth one, \\(position)" }\n        guard let kind = gem.kind else')
edit('App/FallingSkyView.swift', '.accessibilityValue("\\(value) starlight connected")',
     '.accessibilityValue(gemValue(cell, group: group, value: value))')
edit('App/FallingSkyView.swift', '.accessibilityHint(store.game.gem(at: cell)?.isDark == true', '''.accessibilityHint(store.game.gem(at: cell)?.isLight == true
            ? "Tap a colored neighbor. Clearing spends this connector for that family"
            : store.game.gem(at: cell)?.isDark == true''')
edit('App/FallingSkyView.swift', '    private func cellLabel(_ cell: Cell) -> String {', '''    private func gemValue(_ cell: Cell, group: Set<Cell>, value: Int) -> String {
        if store.game.gem(at: cell)?.isLight == true { return "Shared connector" }
        let connectors = group.filter { store.game.gem(at: $0)?.isLight == true }.count
        if connectors > 0 {
            return value >= 3 ? "\\(value) light, spends white" : "\\(value) light with white"
        }
        return "\\(value) starlight connected"
    }

    private func cellLabel(_ cell: Cell) -> String {''')
edit('App/FallingSkyView.swift', '        let shade = store.game.isGrowthBlocked(at: cell)', '''        if store.game.group(at: cell).contains(where: { store.game.gem(at: $0)?.isLight == true }) {
            let shape = StarCast.character(for: kind).description.split(separator: ",")[0]
            return "\\(gem.grown ? "Large " : "")\\(shape), \\(position)"
        }
        let shade = store.game.isGrowthBlocked(at: cell)''')
edit('App/FallingSkyMotion.swift', 'character = JewelScene.makeStarCharacter(gem.kind,',
     'character = JewelScene.makeStarCharacter(gem.isLight ? .amber : gem.kind,')
edit('App/FallingSkyMotion.swift', '        smallSize = character.size',
     '        if gem.isLight { WhiteConnectorMaterial.decorate(character, radius: step * 0.35) }\n        smallSize = character.size')
motion = workspace / 'App/FallingSkyMotion.swift'
text = motion.read_text()
text = text.replace('StarCast.setExpression(expression, for: gem.kind, on: character)', 'applyExpression(expression)')
text = text.replace('StarCast.setExpression(.landing, for: gem.kind, on: character, facing: facing)', 'applyExpression(.landing, facing: facing)')
text = text.replace('StarCast.setExpression(expression, for: self.gem.kind, on: self.character)', 'self.applyExpression(expression)')
motion.write_text(text)
edit('App/FallingSkyMotion.swift', '    /// Finite, local response.', '''    private func applyExpression(_ expression: StarCast.Expression, facing: StarCast.Facing = .front) {
        if gem.isLight { WhiteConnectorMaterial.apply(to: character) }
        else { StarCast.setExpression(expression, for: gem.kind, on: character, facing: facing) }
    }

    /// Finite, local response.''')
append('App/FallingSkyMotion.swift', 'WhiteConnectorMaterial.swift')
shutil.copyfile(mechanics / 'WhiteConnectorTests.swift', workspace / 'Tests/StarfallCoreTests/WhiteConnectorTests.swift')
append('Tests/StarfallCoreTests/WhiteConnectorTests.swift', 'WhiteConnectorNativeCoreTests.swift')
append('AppTests/FallingSkyStoreTests.swift', 'WhiteConnectorStoreTests.swift')
edit('AppTests/FallingSkyStoreTests.swift', 'defaults.removeObject(forKey: "starfall.accumulation.v3")',
     'defaults.removeObject(forKey: FallingSkyStore.saveKey)')
append('UITests/FallingSkyInteractionTests.swift', 'WhiteConnectorUITests.swift')
inputs = [Path(__file__), root / 'tools/environments/export_lab.py', mechanics / 'white-connector.patch', *sorted(mechanics.glob('WhiteConnector*.swift'))]
manifest = {'source': provenance['head'], 'sourceDirtyStatus': provenance['dirtyStatus'], 'workspace': str(workspace),
            'bundle': bundle, 'suite': suite, 'saveKey': suite,
            'scope': 'Scripted fixture choices only; no natural white generation or production changes',
            'toolSHA256': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs},
            'exportSHA256': {str(p.relative_to(workspace)): hashlib.sha256(p.read_bytes()).hexdigest()
                             for folder in ['App', 'AppTests', 'UITests', 'Sources', 'Config', 'Starfall.xcodeproj']
                             for p in sorted((workspace / folder).rglob('*')) if p.is_file()}}
(workspace / 'WHITE-CONNECTOR-NATIVE.json').write_text(json.dumps(manifest, indent=2, sort_keys=True) + '\n')
print(json.dumps(manifest, indent=2, sort_keys=True))
