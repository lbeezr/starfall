"""Derive the isolated selected-walk interaction from the canonical constellation core."""
from pathlib import Path
from constellation_candidate import replace_once


def trace_core(text: str) -> str:
    start = text.index('        let collected = value(of: cells)', text.index('public mutating func clear('))
    end = text.index('    /// Clock-independent event:', start)
    tail = text[start:end]
    text = text[:start] + '        return clearCommitted(cells)\n    }\n\n' + text[end:]
    methods = '''
    /// Ordinary taps never spend a diagonally connected neighbor.
    @discardableResult public mutating func clearOrdinary(_ cell: Cell) -> FallingSkyTurn? {
        guard !isOver else { return nil }
        let cells = orthogonalGroup(at: cell)
        guard value(of: cells) >= 3 else { return nil }
        return clearCommitted(cells)
    }

    /// Walk order, family and distinct count are rules, not gesture/presentation decisions.
    public func constellationCells(along path: [Cell]) -> Set<Cell>? {
        guard path.count <= 196, let first = path.first, let kind = gem(at: first)?.kind else { return nil }
        var previous = first
        for cell in path {
            guard gem(at: cell)?.kind == kind,
                  abs(cell.row-previous.row) <= 1, abs(cell.column-previous.column) <= 1 else { return nil }
            previous = cell
        }
        let cells = Set(path)
        return cells.count >= 5 ? cells : nil
    }

    @discardableResult public mutating func clearConstellation(_ path: [Cell]) -> FallingSkyTurn? {
        guard !isOver, let cells = constellationCells(along: path) else { return nil }
        return clearCommitted(cells)
    }

    private mutating func clearCommitted(_ cells: Set<Cell>) -> FallingSkyTurn {
'''+tail
    return replace_once(text, '    /// Clock-independent event:', methods+'    /// Clock-independent event:')


def apply_trace(workspace: Path):
    mechanics = Path(__file__).resolve().parent
    def edit(name, old, new):
        p = workspace/name
        p.write_text(replace_once(p.read_text(), old, new))
    def append(name, fragment):
        with (workspace/name).open('a') as output: output.write('\n'+(mechanics/fragment).read_text())
    core = workspace/'Sources/StarfallCore/FallingSky.swift'
    core.write_text(trace_core(core.read_text()))
    edit('App/FallingSkyStore.swift', '    private(set) var pending: FallingSkyTurn?',
         '    private(set) var constellationInputGeneration: UInt64 = 0\n    var constellationTracing = false\n    private(set) var pending: FallingSkyTurn?')
    edit('App/FallingSkyStore.swift', '        generation &+= 1\n        pending = nil;',
         '        constellationInputGeneration &+= 1\n        generation &+= 1\n        pending = nil;')
    edit('App/FallingSkyStore.swift', 'guard let turn = game.clear(cell) else {', 'guard let turn = game.clearOrdinary(cell) else {')
    edit('App/FallingSkyStore.swift', '    /// Explicit input works while paused too,', '''    func clearTracedConstellation(_ path: [Cell], snapshot: FallingSky, generation ticket: UInt64) {
        guard canClear, game == snapshot, ticket == constellationInputGeneration else { return }
        let old = game
        guard let turn = game.clearConstellation(path) else { return }
        if game.isOver { freezeClock() }
        feedback.collected(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled,
                           reducedMotion: presenter.reduceMotion)
        present(turn, from: old)
    }

    /// Explicit input works while paused too,''')
    edit('App/FallingSkyStore.swift', 'private(set) var message = "Tap five matching stars linked sideways or diagonally to clear the whole constellation. Large stars count as one star, worth two light. Ordinary matches still need three light."',
         'private(set) var message = "Gather starlight. Draw your own constellations."')
    edit('App/FallingSkyView.swift', '    @State private var settings = false',
         '    @State private var trace = ConstellationTraceIntent()\n    @State private var settings = false')
    edit('App/FallingSkyView.swift', 'import SpriteKit', 'import SpriteKit\nimport UIKit')
    edit('App/FallingSkyView.swift', '    @State private var trace = ConstellationTraceIntent()',
         '    @State private var trace = ConstellationTraceIntent()\n    @State private var traceFeedback = ConstellationTraceFeedback()')
    edit('App/FallingSkyView.swift', '                    }\n                    }\n                }', """                    }
                    ConstellationTraceSurface(size: geometry.size, enabled: store.canClear,
                                              generation: store.constellationInputGeneration,
                                              traceEligible: { store.game.group(at: $0).count >= 5 },
                                              tap: { cell in cancelConstellation(); store.clear(cell) },
                                              begin: { beginConstellation($0, size: geometry.size) },
                                              move: { moveConstellation($0, size: geometry.size) },
                                              end: releaseConstellation, cancel: cancelConstellation)
                    }
                }""")
    edit('App/FallingSkyStore.swift', '        guard canClear else { return }',
         '        guard canClear, !constellationTracing else { return }')
    edit('App/FallingSkyStore.swift', '        generation &+= 1\n        let ticket = generation',
         '        constellationInputGeneration &+= 1\n        generation &+= 1\n        let ticket = generation')
    edit('App/FallingSkyStore.swift', '    func togglePause() {',
         '    func togglePause() {\n        constellationInputGeneration &+= 1')
    edit('App/FallingSkyView.swift', 'return Button { store.clear(cell) } label:',
         'return Button { cancelConstellation(); store.clear(cell) } label:')
    edit('App/FallingSkyView.swift', '        .onDisappear { store.setSuspended(true) }',
         '        .onDisappear { cancelConstellation(); store.setSuspended(true) }\n        .onChange(of: store.constellationInputGeneration) { cancelConstellation() }\n        .onChange(of: store.game) { cancelConstellation() }\n        .onChange(of: store.canClear) { _, enabled in if !enabled { cancelConstellation() } }\n        .onChange(of: store.isPaused) { cancelConstellation() }')
    edit('App/FallingSkyView.swift', '        let group = store.game.group(at: cell)',
         '        let group = store.game.orthogonalGroup(at: cell)')
    edit('App/FallingSkyView.swift', '.accessibilityValue("\\(group.count) matching stars, \\(value) starlight connected")',
         '.accessibilityValue("\\(value) starlight connected")')
    edit('App/FallingSkyView.swift', '.accessibilityRotorEntry(id: cell, in: matchingGroups)', '''.accessibilityAction(named: Text("Add to constellation")) { accessibleTrace(cell) }
        .accessibilityAction(named: Text("Release constellation")) { releaseConstellation() }
        .accessibilityAction(named: Text("Cancel constellation")) { cancelConstellation() }
        .accessibilityRotorEntry(id: cell, in: matchingGroups)''')
    edit('App/FallingSkyView.swift', '? (group.count >= 5 ? "Clear the whole constellation and any dark stars directly beside it" : (store.game.darkStarsBeside(group).isEmpty ? "Clear this group to make room" : "Clear this group and dissolve the dark stars beside it"))',
         '? (store.game.darkStarsBeside(group).isEmpty ? "Tap to clear this ordinary match" : "Tap to clear this ordinary match and adjacent dark stars")')
    edit('App/FallingSkyScene.swift', '        renderConstellationLinks(game)\n', '')
    scene = workspace/'App/FallingSkyScene.swift'
    text = scene.read_text()
    # Retire the tap-lab's automatically drawn solution entirely.
    marker = '// Appended within the exported scene file; uses its authoritative shared projection.'
    if text.count(marker) != 1: raise RuntimeError('Missing old scene-link boundary')
    text = text[:text.index(marker)]
    text = text.replace('        grid.children.filter { $0.name == "lab.constellation.link" }.forEach { $0.removeFromParent() }\n','')
    scene.write_text(text)
    edit('App/FallingSkyScene.swift', '    private let pieces = SKNode(), effects = SKNode(), grid = SKNode()',
         '    private let pieces = SKNode(), effects = SKNode(), grid = SKNode()\n    private let constellationTrail = SKNode()')
    edit('App/FallingSkyScene.swift', '        effects.zPosition = 20',
         '        effects.zPosition = 20\n        constellationTrail.zPosition = 12; addChild(constellationTrail)')
    edit('App/FallingSkyScene.swift', '        rendered = game\n        removeAllActions()',
         '        rendered = game\n        constellationTrail.removeAllChildren()\n        removeAllActions()')
    edit('App/FallingSkyScene.swift', '                halo.position = point(cell); grid.addChild(halo)', '''                if game.group(at: cell).count >= 5 {
                    halo.strokeColor = UIColor(StarfallTheme.Observatory.lanternGlow).withAlphaComponent(0.5)
                    halo.glowWidth = 3
                    if !reduceMotion {
                        halo.run(.repeatForever(.sequence([.fadeAlpha(to: 0.3, duration: 1.1), .fadeAlpha(to: 0.85, duration: 1.1)])))
                    }
                }
                halo.position = point(cell); grid.addChild(halo)''')
    append('App/FallingSkyStore.swift', 'ConstellationTraceIntent.swift')
    append('App/FallingSkyScene.swift', 'ConstellationTraceScene.swift')
    append('App/FallingSkyView.swift', 'ConstellationTraceView.swift')
    append('App/FallingSkyView.swift', 'ConstellationTraceSurface.swift')
    edit('App/FallingSkyMenu.swift', 'Text("Clear ordinary matching stars worth at least 3 light, connected horizontally or vertically. Or tap any member of a same-family constellation of five actual stars connected sideways or diagonally: the whole constellation clears. A large star counts as one star and scores two light.")',
         'Text("Tap ordinary matches worth three light. To draw a constellation, swipe through at least five distinct matching stars, each beside the last, including diagonals. Lift to release only the stars you traced. You may retrace your path to branch; a star counts once. Large stars count as one star and score two light. Lift before five or leave the board to cancel.")')
