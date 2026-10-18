"""Canonical gravity transform for a published production source; export-local only."""
from pathlib import Path
HERE = Path(__file__).resolve().parent
BASE = '06ce514'  # Published Opal/trace/flow source, not an unpublished worktree ancestor.

def replace_once(text, before, after):
    if text.count(before) != 1:
        raise RuntimeError('Expected one gravity anchor: ' + repr(before[:100]))
    return text.replace(before, after)

def candidate_source(text):
    def edit(before, after):
        nonlocal text
        text = replace_once(text, before, after)
    for typ in ['StarfallGem', 'IncomingStar']:
        start=text.index('public struct '+typ+':'); end=text.index('\n}',start)+2
        part=text[start:end]
        part=replace_once(part,'    public var isDark: Bool { kind == nil && !isLight }', '''    public let gravityKind: GravityKind?
    public var identity: SkyIdentity {
        if let gravityKind { return gravityKind == .magnet ? .magnet : .hole }
        if isLight { return .white }
        return kind.map(SkyIdentity.colored) ?? .dusk
    }
    public var isDark: Bool { kind == nil && !isLight && gravityKind == nil }''')
        if typ=='StarfallGem':
            part=part.replace('isDark ? 0 : isLight ? 1 : grown ? 2 : 1','gravityKind != nil || isDark ? 0 : isLight ? 1 : grown ? 2 : 1')
        part=replace_once(part,'light: Bool = false)', 'light: Bool = false, gravity: GravityKind? = nil)')
        part=replace_once(part,'lightStar = light ? true : nil','lightStar = light ? true : nil; gravityKind = gravity')
        text=text[:start]+part+text[end:]
    edit('    public let cleared: Set<Cell>', '    public var gravityPhases: [GravityPhase] = []\n    public let cleared: Set<Cell>')
    edit('    public private(set) var darkStarsCleared = 0', '''    public private(set) var darkStarsCleared = 0
    public private(set) var orbit: OrbitField?
    private var nextGravityID: Int?
    private var retiredMagnetic: Int?''')
    edit('        replay.darkStarsCleared = 0', '''        replay.darkStarsCleared = 0
        replay.orbit = nil; replay.nextGravityID = nil; replay.retiredMagnetic = nil''')
    edit('        let darkStars = darkStarsBeside(cells)\n        let removed = cells.union(darkStars)', '''        if orbit != nil || board.contains(where: { $0?.gravityKind != nil }) {
            var phases: [GravityPhase] = []
            score += collected
            let removed = resolveGravityClear(cells, into: &phases)
            return .init(gravityPhases: phases, cleared: removed, collected: collected, settled: board,
                         forecast: incoming, arrivals: [], blockedColumn: nil)
        }
        let darkStars = darkStarsBeside(cells)
        let removed = cells.union(darkStars)''')
    edit('        let settled = board, forecast = incoming', '''        var phases: [GravityPhase] = []
        advanceOrbit(into: &phases)
        let settled = board, forecast = incoming''')
    edit('            let height = (0..<Self.side).filter { board[$0 * Self.side + star.column] != nil }.count',
         '            let height = GravityFieldRules.height(board, column: star.column)')
    edit('if let kind = star.kind, !star.isLight, height > 0,', 'if let kind = star.kind, !star.isLight, star.gravityKind == nil, height > 0,')
    edit('top.kind == kind, !top.isLight, !top.grown,', 'top.kind == kind, !top.isLight, top.gravityKind == nil, !top.grown,')
    edit('                let gem = StarfallGem(id: starsLanded, kind: star.kind, light: star.isLight)', '''                let id = nextGravityID == nil && star.gravityKind == nil ? starsLanded : allocateGravityID()
                let gem = StarfallGem(id: id, kind: star.kind, light: star.isLight, gravity: star.gravityKind)''')
    edit('        if !isOver { incoming = nextShower() }', '''        if let nextGravityID { self.nextGravityID = max(nextGravityID, starsLanded) }
        if !isOver { incoming = nextShower() }''')
    edit('        return .init(cleared: [], collected: 0, settled: settled,',
         '        return .init(gravityPhases: phases, cleared: [], collected: 0, settled: settled,')
    edit('            (0..<Self.side).filter { board[$0 * Self.side + column] != nil }.count',
         '            GravityFieldRules.height(board, column: column)')
    edit('$0.id >= 0 && (!$0.isLight || $0.kind == nil)',
         '$0.id >= 0 && (!$0.isLight || $0.kind == nil) && $0.gravityKind != .hole && ($0.gravityKind == nil || ($0.kind == nil && !$0.isLight))')
    edit('$0.id < starsLanded &&', '$0.id < max(starsLanded, nextGravityID ?? 0) &&')
    edit('score == starsLanded - darkStarsCleared - gems.reduce(0, { $0 + ($1.isDark ? 1 : $1.value) })',
         'score == starsLanded - darkStarsCleared - (retiredMagnetic ?? 0) - gems.reduce(0, { $0 + ($1.gravityKind == .hole ? 2 : $1.gravityKind == .magnet || $1.isDark ? 1 : $1.value) })')
    edit('        for column in 0..<7 {\n            var foundSpace = false', '''        guard gravityStateValid else { return false }
        if orbit != nil { return true }
        for column in 0..<7 {
            var foundSpace = false''')
    return text+'\n'+(HERE/'GravityCore.swift').read_text()
