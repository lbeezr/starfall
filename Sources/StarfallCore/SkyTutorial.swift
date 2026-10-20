import Foundation

/// Authored, disposable practice. These boards deliberately have no archive
/// contract; normal saves and journey completion never accept a tutorial session.
public enum SkyTutorial: String, CaseIterable, Sendable, Identifiable {
    case match, grown, exchange, emptySpace, trace, diagonal, gap, branch
    case square, cross, opal, relay, trim, dropIn, bank, fork, doubleSetup
    case showers, storm, room, restoration
    public var id: String { rawValue }

    public enum Action: Equatable, Sendable {
        case tap(Cell), swap(Cell, Cell), trace([Cell]), shower, automaticShower, pause, resume
        @discardableResult public func perform(in game: inout FallingSky) -> FallingSkyTurn? {
            switch self {
            case .tap(let cell): game.clear(cell)
            case .swap(let from, let to): game.nudge(from: from, to: to)
            case .trace(let path): game.clearConstellation(path)
            case .shower, .automaticShower: game.letStarsFall()
            case .pause, .resume: nil
            }
        }
        func sameMethod(as other: Self) -> Bool {
            switch (self, other) {
            case (.tap, .tap), (.trace, .trace), (.swap, .swap), (.shower, .shower),
                 (.automaticShower, .automaticShower), (.pause, .pause), (.resume, .resume): true
            default: false
            }
        }
    }

    public var allowsClock: Bool { self == .showers }
    public func game() -> FallingSky {
        switch self {
        case .square: return SkyLesson.square.game()
        case .cross, .branch: return SkyLesson.cross.game()
        case .opal: return SkyLesson.opal.game()
        case .relay: return SkyLesson.relay.game()
        case .showers: return FallingSky.freshSurvival(seed: 5)
        case .storm:
            var sky = FallingSky.freshSurvival(seed: 5)
            for _ in 0..<100 {
                if sky.forecastPhase?.isStorm == true { return sky }
                if let cell = sky.legalGroups.first?.first { _ = sky.clear(cell) }
                _ = sky.letStarsFall()
                if sky.isOver { break }
            }
            return sky
        case .restoration: return FallingSky(challenge: .firstLight)
        default: break
        }
        let rows: [String]
        switch self {
        case .match: rows = ["AAAP"]
        case .grown: rows = ["gAP"]
        case .exchange: rows = ["ASP", "PAS", "SPA"]
        case .emptySpace: rows = ["AP", ".A"]
        case .trace: rows = ["AAAAAA"]
        case .diagonal: rows = ["APPPP", "PAPPP", "PPAPP", "PPPAP", "PPPPA"]
        case .gap: rows = ["AA.AAA"]
        case .trim: rows = ["ASPPA", "SSAAP", "SSA.S", "AA", ".S"]
        case .dropIn: rows = ["AAS", "ASS", ".A"]
        case .bank: rows = ["PPAAA", "PPPSP", "SPPP", "PSPS"]
        case .fork: rows = ["PPAPP", "SSSSP", "SSS.A", "SSP", "PPP"]
        case .doubleSetup: rows = ["PSAPP", "SSSAP", "ASAPA", "PAPPP", "PAPS"]
        case .room: rows = ["AAAP", "P", "S", "P", "S", "P", "S"]
        default: rows = []
        }
        let kinds: [Character: Jewel] = ["A": .aqua, "g": .aqua, "S": .amber, "P": .mint]
        var board: [StarfallGem?] = Array(repeating: nil, count: 49)
        var id = 0
        for (row, text) in rows.enumerated() {
            for (column, key) in text.enumerated() where key != "." {
                board[row * 7 + column] = .init(id: id, kind: kinds[key], grown: key == "g")
                id += 1
            }
        }
        return FallingSky(board: board, incoming: [.init(id: 100, kind: .rose, column: self == .room ? 0 : 6)])
    }

    public var actions: [Action] {
        switch self {
        case .match, .grown: return [.tap(Cell(0,0))]
        case .exchange: return [.swap(Cell(1,1), Cell(1,2)), .swap(Cell(1,2), Cell(1,1)),
                               .swap(Cell(1,1), Cell(2,1)), .swap(Cell(2,1), Cell(1,1))]
        case .emptySpace: return [.swap(Cell(1,1), Cell(1,0))]
        case .trace: return [.trace((0..<5).map { Cell(0,$0) })]
        case .diagonal: return [.trace((0..<5).map { Cell($0,$0) })]
        case .gap: return [.trace([0,1,3,4,5].map { Cell(0,$0) })]
        case .square, .cross, .branch, .opal, .relay:
            let lesson: SkyLesson = self == .square ? .square : self == .opal ? .opal : self == .relay ? .relay : .cross
            return lesson.moves.map {
                switch $0 {
                case .tap(let cell): .tap(cell)
                case .swap(let a, let b): .swap(a,b)
                case .trace(let path): self == .branch ? .trace(path) : .tap(path[0])
                }
            }
        case .trim: return strategy(first: (.square, Cell(2,0)), thenBestTap: true)
        case .dropIn:
            var sky = game(); _ = sky.clear(Cell(0,2))
            return [.tap(Cell(0,2))] + sky.recipes.first.map { [.trace(Self.walk($0))] }!
        case .bank: return strategy(first: (.cross, Cell(3,2)), thenBestTap: false, second: (.square, Cell(0,0)))
        case .fork: return strategy(first: (.square, Cell(1,0)), thenBestTap: true)
        case .doubleSetup:
            return strategy(first: (.cross, Cell(0,1)), thenBestTap: false, second: (.square, Cell(3,3)), third: (.square, Cell(0,1)))
        case .showers: return [.shower, .resume, .automaticShower, .pause, .shower]
        case .storm: return [.shower]
        case .room: return [.tap(Cell(0,0)), .shower]
        case .restoration:
            var sky = game(); var result: [Action] = []
            for _ in 0..<60 where !sky.isOver {
                let action = sky.legalGroups.first?.first.map(Action.tap) ?? .shower
                _ = action.perform(in: &sky); result.append(action)
            }
            return result
        }
    }

    private func strategy(first: (StarRecipe.Shape, Cell), thenBestTap: Bool,
                          second: (StarRecipe.Shape, Cell)? = nil, third: (StarRecipe.Shape, Cell)? = nil) -> [Action] {
        var sky = game(); var result: [Action] = []
        for choice in [first, second, third].compactMap({ $0 }) {
            guard let recipe = sky.recipes.first(where: { $0.shape == choice.0 && $0.cells.contains(choice.1) }) else { return [] }
            let action = Action.trace(Self.walk(recipe)); _ = action.perform(in: &sky); result.append(action)
        }
        if thenBestTap, let group = sky.legalGroups.max(by: { sky.reward(of: Set($0)) < sky.reward(of: Set($1)) }), let cell = group.first {
            result.append(.tap(cell))
        }
        return result
    }

    public static func walk(_ recipe: StarRecipe) -> [Cell] {
        if recipe.shape == .line { return recipe.cells }
        let rows = recipe.cells.map(\.row), columns = recipe.cells.map(\.column)
        if recipe.shape == .square {
            let r = rows.min()!, c = columns.min()!
            return [Cell(r,c), Cell(r,c+1), Cell(r+1,c+1), Cell(r+1,c)]
        }
        let center = Cell((rows.min()! + rows.max()!) / 2, (columns.min()! + columns.max()!) / 2)
        return [center, Cell(center.row+1,center.column), center, Cell(center.row,center.column-1),
                center, Cell(center.row,center.column+1), center, Cell(center.row-1,center.column)]
    }
}

/// Advances only from committed actions. Different taps/paths that spend the same
/// ingredients are accepted; another legal result stays visible for comparison/retry.
public struct SkyTutorialRun: Equatable, Sendable {
    public let chapter: SkyTutorial
    public private(set) var step = 0
    public private(set) var needsRetry = false
    private let actions: [SkyTutorial.Action]
    private var expected: FallingSky
    public init(_ chapter: SkyTutorial) {
        self.chapter = chapter
        actions = chapter.actions
        expected = chapter.game()
    }
    public var complete: Bool { step == actions.count && !needsRetry }
    public var next: SkyTutorial.Action? { complete || needsRetry ? nil : actions[step] }
    public mutating func observe(_ action: SkyTutorial.Action, before: FallingSky, after: FallingSky) {
        guard let next else { return }
        let prior = expected
        var result = prior
        _ = next.perform(in: &result)
        guard before == prior, after == result, action.sameMethod(as: next) else { needsRetry = true; return }
        expected = result
        step += 1
    }
}
