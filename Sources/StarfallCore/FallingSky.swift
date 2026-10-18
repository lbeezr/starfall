import Foundation

/// Production falling-sky rules with deterministic shower events. The Debug classic Game is independent.
public struct StarfallGem: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    public let kind: Jewel?
    public var grown: Bool
    private var savedDuskFeeds: Int?
    public var duskFeeds: Int { savedDuskFeeds ?? 0 }
    mutating func feedDusk() { savedDuskFeeds = duskFeeds + 1 }
    var validDuskFeeds: Bool { savedDuskFeeds.map { isDark && (1..<DuskRule.feedingShowers).contains($0) } ?? true }
    private var lightStar: Bool?
    public var isLight: Bool { lightStar == true }
    public let gravityKind: GravityKind?
    public var identity: SkyIdentity {
        if let gravityKind { return gravityKind == .magnet ? .magnet : .hole }
        if isLight { return .white }
        return kind.map(SkyIdentity.colored) ?? .dusk
    }
    public var isDark: Bool { kind == nil && !isLight && gravityKind == nil }
    public var value: Int { gravityKind != nil || isDark ? 0 : isLight ? 1 : grown ? 2 : 1 }
    public init(id: Int, kind: Jewel?, grown: Bool = false, light: Bool = false, gravity: GravityKind? = nil) {
        self.id = id; self.kind = kind; self.grown = grown
        lightStar = light ? true : nil; gravityKind = gravity
    }
}

public struct IncomingStar: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    public let kind: Jewel?
    public let column: Int
    private var lightStar: Bool?
    public var isLight: Bool { lightStar == true }
    public let gravityKind: GravityKind?
    public var identity: SkyIdentity {
        if let gravityKind { return gravityKind == .magnet ? .magnet : .hole }
        if isLight { return .white }
        return kind.map(SkyIdentity.colored) ?? .dusk
    }
    public var isDark: Bool { kind == nil && !isLight && gravityKind == nil }
    public init(id: Int, kind: Jewel?, column: Int, light: Bool = false, gravity: GravityKind? = nil) {
        self.id = id; self.kind = kind; self.column = column
        lightStar = light ? true : nil; gravityKind = gravity
    }
}

public struct FallingSkyTurn: Sendable {
    public struct Arrival: Sendable {
        public let star: IncomingStar
        public let cell: Cell
        public let gem: StarfallGem
        public let grew: Bool
    }
    public struct Exchange: Sendable {
        public let from: Cell
        public let to: Cell
    }
    public var exchange: Exchange? = nil
    public var duskCollapses: [DuskCollapse] = []
    public var duskAffectedColumns: Set<Int> = []
    public var gravityPhases: [GravityPhase] = []
    public let cleared: Set<Cell>
    public let collected: Int
    public let settled: [StarfallGem?]
    public let forecast: [IncomingStar]
    public let arrivals: [Arrival]
    public let blockedColumn: Int?
}

public struct FallingSky: Codable, Equatable, Sendable {
    public static let side = 7
    public static let maximumShowerSize = 5
    public static let showerSizes = [1, 2, 3, 5]
    public private(set) var board: [StarfallGem?]
    public private(set) var incoming: [IncomingStar]
    public private(set) var score = 0
    public private(set) var turns = 0
    public private(set) var starsLanded = 0
    public private(set) var darkStarsCleared = 0
    public private(set) var orbit: OrbitField?
    private var nextGravityID: Int?
    private var retiredMagnetic: Int?
    private var savedDuskRule: Int?
    private var unscoredStarlight: Int?
    public var duskRule: DuskRule { DuskRule(rawValue: savedDuskRule ?? 0) ?? .legacy }
    public var lostStarlight: Int { unscoredStarlight ?? 0 }

    /// Explicit app migration. Committed board/score/preview/RNG/cadence stay intact.
    public func adoptingFeedingDusk() -> FallingSky {
        guard challenge == nil, duskRule == .legacy else { return self }
        var adopted = self
        adopted.savedDuskRule = DuskRule.feeding.rawValue
        adopted.unscoredStarlight = 0
        return adopted
    }
    public private(set) var blockedColumn: Int?
    public private(set) var challenge: StarfallChallenge?
    public let seed: UInt64
    private var random: SeededRandom
    private var remainingColumns: [Int] = []
    private var showersUntilDark = 5
    // Optional storage lets pre-tuning v3 saves retain their board and original balance.
    private var savedBalance: StarfallBalance?
    // Missing in older saves: retain their original independent-color sky.
    private var cohesiveShowers: Bool?
    private var savedGeneration: Int?
    public var generation: SkyGeneration { SkyGeneration(rawValue: savedGeneration ?? 0) ?? .legacy }
    public var forecastPhase: SkyShowerPhase? {
        guard !isOver, challenge == nil else { return nil }
        return generation.phase(for: turns + 1)
    }
    // Missing in historical saves: retain the original clock, including empty skies.
    private var openingCascade: Bool?
    // Absent markers retain the saved opening and balance contract without migration.
    private var savedCadence: SkyCadenceID?
    public var cadenceID: SkyCadenceID { savedCadence ?? (openingCascade == true ? .openingV1 : .originalV1) }
    public var cadenceStep: SkyCadenceStep { cadenceID.step(committedShowers: turns, pace: balance.pace) }
    public var hasOpeningCascade: Bool { cadenceID != .originalV1 }
    public var isOpeningCascade: Bool { cadenceStep.phase == .opening }
    public var automaticShowerDelay: Double { cadenceStep.delay }
    public var balance: StarfallBalance { savedBalance ?? StarfallBalance(pace: .steady) }
    public var outcome: Outcome {
        challenge?.outcome(score: score, overflowed: blockedColumn != nil)
            ?? (blockedColumn == nil ? .playing : .lost)
    }
    public var isOver: Bool { outcome != .playing }
    public var occupiedCount: Int { board.compactMap { $0 }.count }

    public init(seed: UInt64, balance: StarfallBalance = StarfallBalance(), openingCascade: Bool = true,
                generation: SkyGeneration = .legacy, cadence: SkyCadenceID = .announcedCycleV2, duskRule: DuskRule = .legacy) {
        precondition(!openingCascade || cadence != .originalV1)
        self.seed = seed
        savedDuskRule = duskRule == .legacy ? nil : duskRule.rawValue
        unscoredStarlight = duskRule == .legacy ? nil : 0
        savedGeneration = generation == .legacy ? nil : generation.rawValue
        self.openingCascade = openingCascade ? true : nil
        savedCadence = openingCascade ? cadence : nil
        savedBalance = balance
        cohesiveShowers = true
        showersUntilDark = balance.darkStars.showerGap.map { $0.upperBound - 1 } ?? 0
        random = SeededRandom(seed: seed)
        board = Array(repeating: nil, count: Self.side * Self.side)
        incoming = []
        incoming = nextShower()
    }

    public init(challenge: StarfallChallenge) {
        self.init(seed: challenge.seed, balance: challenge.balance, openingCascade: false, generation: .legacy)
        self.challenge = challenge
    }

    /// Reset committed play while retaining timing, tuning and historical generation rules.
    public func replay() -> FallingSky {
        var replay = self
        replay.board = Array(repeating: nil, count: Self.side * Self.side)
        replay.incoming = []
        replay.score = 0
        replay.turns = 0
        replay.starsLanded = 0
        replay.darkStarsCleared = 0
        replay.unscoredStarlight = duskRule == .feeding ? 0 : nil
        replay.orbit = nil; replay.nextGravityID = nil; replay.retiredMagnetic = nil
        replay.blockedColumn = nil
        replay.random = SeededRandom(seed: seed)
        replay.remainingColumns = []
        replay.showersUntilDark = balance.darkStars.showerGap.map { $0.upperBound - 1 } ?? 0
        replay.incoming = replay.nextShower()
        return replay
    }

    /// Retire gravity at the normal-play boundary, after validating a historical save.
    /// Raw decoding/replay remains source-faithful for compatibility and Debug reproductions.
    public func removingGravity() -> FallingSky {
        guard generation.supportsGravity else { return self }
        precondition(isValidSave)
        var result = self
        result.savedGeneration = SkyGeneration.standardSky.rawValue
        let retired = board.compactMap { $0 }.reduce(0) { total, gem in
            total + (gem.gravityKind == .hole ? 2 : gem.gravityKind == .magnet ? 1 : 0)
        }
        if retired > 0 { result.retiredMagnetic = (retiredMagnetic ?? 0) + retired }
        result.orbit = nil
        result.board = GravityFieldRules.settle(board.map { $0?.gravityKind == nil ? $0 : nil }, field: nil)
        // Preserve the committed shower's size, order, columns and IDs without drawing RNG.
        let replacement = incoming.compactMap(\.kind).first ?? .aqua
        result.incoming = incoming.map { star in
            star.gravityKind == nil ? star : IncomingStar(id: star.id, kind: replacement, column: star.column)
        }
        // Retain the monotonic allocator and retired mass: survivor IDs and arrival
        // conservation stay valid even when an old collision allocated an extra ID.
        precondition(result.isValidSave)
        return result
    }

    // Internal deterministic positions for rule tests, not an app customization API.
    init(board: [StarfallGem?], incoming: [IncomingStar], seed: UInt64 = 1, generation: SkyGeneration = .legacy) {
        precondition(board.count == 49 && Self.showerSizes.contains(incoming.count))
        self.seed = seed; self.board = board; self.incoming = incoming
        savedGeneration = generation == .legacy ? nil : generation.rawValue
        if generation != .legacy { cohesiveShowers = true }
        starsLanded = board.compactMap { $0 }.reduce(0) { $0 + ($1.isDark ? 1 : $1.value) }
        random = SeededRandom(seed: seed)
    }

    /// Keep the board and announced preview; new frequency starts with later previews.
    public mutating func setBalance(_ newBalance: StarfallBalance) {
        guard challenge == nil else { return }
        if newBalance.darkStars != balance.darkStars {
            showersUntilDark = newBalance.darkStars.showerGap.map { $0.upperBound - 1 } ?? 0
        }
        savedBalance = newBalance
    }

    public func gem(at cell: Cell) -> StarfallGem? {
        guard (0..<Self.side).contains(cell.row), (0..<Self.side).contains(cell.column) else { return nil }
        return board[cell.row * Self.side + cell.column]
    }

    private func neighbors(of cell: Cell) -> [Cell] {
        [Cell(cell.row-1, cell.column), Cell(cell.row+1, cell.column),
         Cell(cell.row, cell.column-1), Cell(cell.row, cell.column+1)]
    }

    /// Only orthogonal neighbors are shaded. Existing growth and matching stay intact.
    public func isGrowthBlocked(at cell: Cell) -> Bool {
        guard duskRule == .legacy, let jewel = gem(at: cell), jewel.kind != nil, !jewel.isLight else { return false }
        return neighbors(of: cell).contains { gem(at: $0)?.isDark == true }
    }

    public func isDrained(at cell: Cell) -> Bool {
        guard duskRule == .feeding, let gem = gem(at: cell), gem.kind != nil || gem.isLight else { return false }
        return !darkStarsBeside([cell]).isEmpty
    }

    public func reward(of cells: Set<Cell>) -> Int {
        cells.reduce(0) { $0 + (isDrained(at: $1) ? 0 : (gem(at: $1)?.value ?? 0)) }
    }

    public func duskTargets(at cell: Cell) -> Set<Cell> {
        guard duskRule == .feeding, gem(at: cell)?.isDark == true else { return [] }
        return Set(neighbors(of: cell).filter { neighbor in
            guard let gem = gem(at: neighbor) else { return false }
            return gem.kind != nil || gem.isLight
        })
    }

    private func duskChangedColumns(from old: FallingSky) -> Set<Int> {
        var columns: Set<Int> = []
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row,column)
            if isDrained(at: cell) != old.isDrained(at: cell)
                || gem(at: cell)?.duskFeeds != old.gem(at: cell)?.duskFeeds {
                columns.insert(column)
            }
        } }
        return columns
    }

    public func darkStarsBeside(_ cells: Set<Cell>) -> Set<Cell> {
        Set(cells.flatMap { neighbors(of: $0) }.filter { gem(at: $0)?.isDark == true })
    }

    // One membership rule for taps, diagonal components and selected walks.
    private func matchesFamily(_ family: Jewel, at cell: Cell) -> Bool {
        guard let member = gem(at: cell) else { return false }
        return member.kind == family || member.isLight
    }

    public func group(at start: Cell) -> Set<Cell> {
        guard let kind = gem(at: start)?.kind else { return [] }
        var found: Set<Cell> = [start], pending = [start]
        while let cell = pending.popLast() {
            for next in neighbors(of: cell) {
                if !found.contains(next), matchesFamily(kind, at: next) {
                    found.insert(next); pending.append(next)
                }
            }
        }
        return found
    }

    public var legalGroups: [[Cell]] {
        var seen: Set<Cell> = [], groups: [[Cell]] = []
        for row in 0..<Self.side { for column in 0..<Self.side {
            let cell = Cell(row, column)
            guard !seen.contains(cell), let member = gem(at: cell), member.kind != nil, !member.isLight else { continue }
            let group = group(at: cell)
            // A connector is shared across families; only colored members deduplicate a component.
            seen.formUnion(group.filter { gem(at: $0)?.isLight != true })
            if value(of: group) >= 3 {
                groups.append(group.sorted {
                    let lhsLight = gem(at: $0)?.isLight == true, rhsLight = gem(at: $1)?.isLight == true
                    if lhsLight != rhsLight { return !lhsLight }
                    return $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
                })
            }
        } }
        return groups
    }

    /// Growth counts toward both the clear threshold and collected starlight.
    public func value(of cells: Set<Cell>) -> Int {
        cells.reduce(0) { $0 + (gem(at: $1)?.value ?? 0) }
    }

    /// Invalid clears never advance the forecast, score, turn counter, or RNG.
    @discardableResult public mutating func clear(_ cell: Cell) -> FallingSkyTurn? {
        guard !isOver else { return nil }
        let cells = group(at: cell)
        guard value(of: cells) >= 3 else { return nil }
        return clearCommitted(cells)
    }

    /// Walk order, family and distinct count are rules, not gesture/presentation decisions.
    /// Shared prefix legality for live input and committed walks. The first
    /// colored star fixes the family even after the path crosses a white orb.
    public func isValidConstellationPrefix(_ path: [Cell]) -> Bool {
        guard path.count <= 196, let first = path.first, let kind = gem(at: first)?.kind else { return false }
        var previous = first
        for cell in path {
            guard matchesFamily(kind, at: cell),
                  abs(cell.row-previous.row) <= 1, abs(cell.column-previous.column) <= 1 else { return false }
            previous = cell
        }
        return true
    }

    public func constellationCells(along path: [Cell]) -> Set<Cell>? {
        guard isValidConstellationPrefix(path) else { return nil }
        let cells = Set(path)
        return cells.count >= 5 || (challenge == nil && cells.count == 4 && recipe(matching:cells)?.shape == .square) ? cells : nil
    }

    @discardableResult public mutating func clearConstellation(_ path: [Cell]) -> FallingSkyTurn? {
        guard !isOver, let cells = constellationCells(along: path) else { return nil }
        return clearCommitted(cells)
    }

    @discardableResult public mutating func clearSelected(_ path: [Cell]) -> FallingSkyTurn? {
        guard canArrangeStars else { return nil }
        return clearConstellation(path)
    }

    @discardableResult public mutating func activate(_ recipe: StarRecipe) -> FallingSkyTurn? {
        guard canArrangeStars, recipes.contains(recipe) else { return nil }
        return clearCommitted(Set(recipe.cells))
    }

    @discardableResult public mutating func nudge(from: Cell, to: Cell) -> FallingSkyTurn? {
        guard canNudge(from:from,to:to) else { return nil }
        let before = self
        board.swapAt(from.row * Self.side + from.column, to.row * Self.side + to.column)
        board = GravityFieldRules.settle(board,field:nil)
        return .init(exchange:.init(from:from,to:to),duskAffectedColumns:duskChangedColumns(from:before),cleared:[],collected:0,settled:board,
                     forecast:incoming,arrivals:[],blockedColumn:nil)
    }

    private mutating func clearCommitted(_ cells: Set<Cell>) -> FallingSkyTurn {
        let before = self
        let collected = reward(of: cells)
        if duskRule == .feeding { unscoredStarlight = lostStarlight + value(of: cells) - collected }
        if orbit != nil || board.contains(where: { $0?.gravityKind != nil }) {
            var phases: [GravityPhase] = []
            score += collected
            let removed = resolveGravityClear(cells, into: &phases)
            return .init(duskAffectedColumns: duskChangedColumns(from: before), gravityPhases: phases, cleared: removed, collected: collected, settled: board,
                         forecast: incoming, arrivals: [], blockedColumn: nil)
        }
        let darkStars = darkStarsBeside(cells)
        let removed = cells.union(darkStars)
        darkStarsCleared += darkStars.count
        score += collected
        for cell in removed { board[cell.row * Self.side + cell.column] = nil }
        for column in 0..<Self.side {
            let survivors = (0..<Self.side).compactMap { board[$0 * Self.side + column] }
            for row in 0..<Self.side {
                board[row * Self.side + column] = row < survivors.count ? survivors[row] : nil
            }
        }
        return .init(duskAffectedColumns: duskChangedColumns(from: before), cleared: removed, collected: collected, settled: board,
                     forecast: incoming, arrivals: [], blockedColumn: nil)
    }

    /// Clock-independent event: the presentation layer decides when the sky advances.
    /// Clearing never consumes or regenerates this preview.
    @discardableResult public mutating func letStarsFall() -> FallingSkyTurn? {
        guard !isOver else { return nil }
        let before = self
        turns += 1
        var phases: [GravityPhase] = []
        let collapses = advanceDusk(into: &phases)
        advanceOrbit(into: &phases)
        let settled = board, forecast = incoming
        var arrivals: [FallingSkyTurn.Arrival] = []
        for star in forecast {
            let height = GravityFieldRules.height(board, column: star.column)
            // A matching small top jewel can grow even when its column is full.
            if let kind = star.kind, !star.isLight, star.gravityKind == nil, height > 0, var top = board[(height-1) * Self.side + star.column],
               top.kind == kind, !top.isLight, top.gravityKind == nil, !top.grown, !isGrowthBlocked(at: Cell(height-1, star.column)) {
                top.grown = true
                let cell = Cell(height-1, star.column)
                board[cell.row * Self.side + cell.column] = top
                starsLanded += 1
                arrivals.append(.init(star: star, cell: cell, gem: top, grew: true))
            } else {
                guard height < Self.side else { blockedColumn = star.column; break }
                let cell = Cell(height, star.column)
                let id = nextGravityID == nil && star.gravityKind == nil ? starsLanded : allocateGravityID()
                let gem = StarfallGem(id: id, kind: star.kind, light: star.isLight, gravity: star.gravityKind)
                board[cell.row * Self.side + cell.column] = gem
                starsLanded += 1
                arrivals.append(.init(star: star, cell: cell, gem: gem, grew: false))
            }
        }
        if let nextGravityID { self.nextGravityID = max(nextGravityID, starsLanded) }
        if !isOver { incoming = nextShower() }
        return .init(duskCollapses: collapses, duskAffectedColumns: duskChangedColumns(from: before), gravityPhases: phases, cleared: [], collected: 0, settled: settled,
                     forecast: forecast, arrivals: arrivals, blockedColumn: blockedColumn)
    }

    private mutating func nextShower() -> [IncomingStar] {
        let modern = generation != .legacy && challenge == nil && turns >= 4
        let storm = modern && generation.phase(for: turns + 1)?.isStorm == true
        let sizes = [1, 2, 2, 3, 3, 3, 5]
        let naturalCount = sizes[Int(random.next() % UInt64(sizes.count))]
        // A dry board gets a useful run in its next forecast, plus two pressure
        // stars. Never rewrite an announced preview or alter the board for free.
        let heights = (0..<Self.side).map { column in
            GravityFieldRules.height(board, column: column)
        }
        let reliefColumn = cohesiveShowers == true && turns > 0 && legalGroups.isEmpty
            ? heights.indices.filter { heights[$0] <= 4 }.min { heights[$0] < heights[$1] } : nil
        let count = reliefColumn == nil ? (storm ? 5 : naturalCount) : 5
        let darkIndex: Int?
        if let gap = balance.darkStars.showerGap, showersUntilDark == 0 {
            darkIndex = reliefColumn == nil ? Int(random.next() % UInt64(count)) : 3 + Int(random.next() % 2)
            showersUntilDark = gap.lowerBound - 1 + Int(random.next() % UInt64(gap.count))
        } else {
            darkIndex = nil
            if balance.darkStars != .none { showersUntilDark -= 1 }
        }
        let sharedKind = cohesiveShowers == true ? random.jewel() : nil
        // A fresh sky teaches the clear immediately with three adjacent stars.
        // Keep column coverage fair by reserving the other four for later.
        if cohesiveShowers == true, turns == 0, starsLanded == 0 {
            let start = Int(random.next() % 5)
            remainingColumns = (0..<Self.side).filter { !(start..<(start + 3)).contains($0) }
            return (0..<3).map { IncomingStar(id: $0, kind: sharedKind!, column: start + $0) }
        }
        // Preserve the established paired-shower candidate, now behind an explicit
        // saved generation. Legacy skies execute their original RNG/arrival path.
        let eligible = heights.indices.filter { heights[$0] <= 4 }
        let primaryColumn = modern && cohesiveShowers == true && count == 5 && reliefColumn == nil
            ? (storm ? eligible.max { heights[$0] < heights[$1] } : eligible.min { heights[$0] < heights[$1] }) : nil
        let secondaryColumn = primaryColumn.flatMap { primary in
            heights.indices.filter { column in
                guard column != primary, heights[column] > 0, heights[column] <= 5,
                      let kind = gem(at: Cell(heights[column] - 1, column))?.kind else { return false }
                return kind != sharedKind
            }.min { heights[$0] < heights[$1] }
        }
        let secondaryKind = secondaryColumn.flatMap { gem(at: Cell(heights[$0] - 1, $0))?.kind }
        // One opal opportunity every sixth shower, after the opening. Dusk retains
        // its slot; never replace the first three colored stars of dry-board relief.
        let lightIndex = modern && (turns + 1).isMultiple(of: 6)
            ? (0..<count).last { $0 != darkIndex && (reliefColumn == nil || $0 >= 3) } : nil
        let forecast = (0..<count).map { offset in
            let kind = random.jewel()
            // Natural arrivals rotate through columns; relief runs deliberately
            // stack three matching stars in a low column to restore a choice.
            if remainingColumns.isEmpty { remainingColumns = Array(0..<Self.side) }
            let index = Int(random.next() % UInt64(remainingColumns.count))
            let naturalColumn = remainingColumns.remove(at: index)
            let light = offset == lightIndex
            let family = offset >= 3 ? (secondaryKind ?? sharedKind ?? kind) : (sharedKind ?? kind)
            return IncomingStar(id: turns * Self.maximumShowerSize + offset,
                                kind: offset == darkIndex || light ? nil : family,
                                column: offset < 3 ? (primaryColumn ?? reliefColumn ?? naturalColumn) : (secondaryColumn ?? naturalColumn),
                                light: light)
        }
        return magneticForecast(replacing: forecast, heights: heights, relief: reliefColumn != nil)
    }

    /// A versioned late-calm pair opportunity. No accumulating orphans.
    /// The forecast remains committed; later clears cannot retarget this pair.
    private func magneticForecast(replacing forecast: [IncomingStar], heights: [Int], relief: Bool) -> [IncomingStar] {
        guard generation.offersMagneticPair(at: turns + 1), challenge == nil,
              !relief, !forecast.contains(where: { $0.isDark || $0.isLight }), orbit == nil, !board.contains(where: { $0?.gravityKind != nil }) else { return forecast }
        let centers: [Int] = (1..<6).filter { column in
            let leftHeight = heights[column - 1]
            let rightHeight = heights[column + 1]
            let middleHeight = heights[column]
            guard leftHeight == rightHeight, leftHeight <= 4,
                  middleHeight > leftHeight else { return false }
            return gem(at: Cell(leftHeight, column))?.kind != nil
        }
        guard let middle = centers.min(by: { heights[$0-1] < heights[$1-1] }) else { return forecast }
        let family = gem(at: Cell(heights[middle-1], middle))!.kind!
        // Two ordinary endpoint survivors make capture useful even at the floor.
        let columns = [middle-1, middle+1, middle-1, middle+1, middle]
        return columns.enumerated().map { offset, column in
            let magnet = offset < 2
            let kind = magnet ? nil : offset == 4 ? family : Jewel.allCases[(Jewel.allCases.firstIndex(of: family)! + offset) % Jewel.allCases.count]
            return IncomingStar(id: turns * 5 + offset, kind: kind, column: column, gravity: magnet ? .magnet : nil)
        }
    }

    // Trace eligibility is distinct from ordinary tap groups and generator relief.
    public func constellationGroup(at start: Cell) -> Set<Cell> {
        guard let kind = gem(at: start)?.kind else { return [] }
        var found: Set<Cell> = [start], pending = [start]
        while let cell = pending.popLast() {
            for dr in -1...1 { for dc in -1...1 where dr != 0 || dc != 0 {
                let next = Cell(cell.row + dr, cell.column + dc)
                if !found.contains(next), matchesFamily(kind, at: next) {
                    found.insert(next); pending.append(next)
                }
            } }
        }
        return found.count >= 5 ? found : []
    }

    public var isValidSave: Bool {
        guard SkyGeneration(rawValue: savedGeneration ?? 0) != nil,
              DuskRule(rawValue: savedDuskRule ?? 0) != nil,
              duskRule == .feeding ? (unscoredStarlight != nil && lostStarlight >= 0 && lostStarlight <= starsLanded) : unscoredStarlight == nil,
              board.allSatisfy({ $0?.validDuskFeeds ?? true }),
              duskRule == .feeding || board.allSatisfy({ ($0?.duskFeeds ?? 0) == 0 }) else { return false }
        if generation != .legacy && cohesiveShowers != true { return false }
        if !generation.supportsGravity {
            if orbit != nil || incoming.contains(where: { $0.gravityKind != nil }) || board.contains(where: { $0?.gravityKind != nil }) { return false }
            if generation != .standardSky && (nextGravityID != nil || retiredMagnetic != nil) { return false }
        }
        if generation == .legacy && (incoming.contains(where: \.isLight) || board.contains(where: { $0?.isLight == true })) { return false }
        if let challenge, seed != challenge.seed || balance != challenge.balance || hasOpeningCascade || generation != .legacy { return false }
        if let savedCadence, (savedCadence != .originalV1) != (openingCascade == true) { return false }
        guard board.count == 49, Self.showerSizes.contains(incoming.count),
              remainingColumns.allSatisfy({ (0..<7).contains($0) }),
              Set(remainingColumns).count == remainingColumns.count,
              turns >= 0, turns < Int.max / 6, score >= 0, starsLanded >= 0,
              (0...(balance.darkStars.showerGap.map { $0.upperBound - 1 } ?? 0)).contains(showersUntilDark),
              darkStarsCleared >= 0, darkStarsCleared <= starsLanded,
              incoming.allSatisfy({ (0..<7).contains($0.column) && $0.id >= 0 && (!$0.isLight || $0.kind == nil) && $0.gravityKind != .hole && ($0.gravityKind == nil || ($0.kind == nil && !$0.isLight)) }),
              blockedColumn.map({ (0..<7).contains($0) }) ?? true else { return false }
        // Retired and lost light are disjoint parts of landed light. Bound each
        // subtraction before conservation arithmetic, including corrupted archives.
        let magnetic = retiredMagnetic ?? 0
        guard magnetic >= 0, magnetic <= starsLanded - darkStarsCleared,
              lostStarlight <= starsLanded - darkStarsCleared - magnetic else { return false }
        let available = starsLanded - darkStarsCleared - magnetic - lostStarlight
        let gems = board.compactMap { $0 }
        guard Set(gems.map(\.id)).count == gems.count,
              gems.allSatisfy({ $0.id >= 0 && $0.id < max(starsLanded, nextGravityID ?? 0) && !(($0.isDark || $0.isLight) && $0.grown) && (!$0.isLight || $0.kind == nil) }),
              starsLanded <= turns * Self.maximumShowerSize,
              score == available - gems.reduce(0, { $0 + ($1.gravityKind == .hole ? 2 : $1.gravityKind == .magnet || $1.isDark ? 1 : $1.value) }) else { return false }
        guard gravityStateValid else { return false }
        if orbit != nil { return true }
        for column in 0..<7 {
            var foundSpace = false
            for row in 0..<7 {
                if board[row * 7 + column] == nil { foundSpace = true }
                else if foundSpace { return false }
            }
        }
        return true
    }
}

// Committed gravity mutation shares the FallingSky state boundary.
extension FallingSky {
    /// All mature sources see the same committed neighborhood. No cascading targets.
    private mutating func advanceDusk(into phases: inout [GravityPhase]) -> [DuskCollapse] {
        guard duskRule == .feeding else { return [] }
        var collapses: [DuskCollapse] = []
        for index in board.indices {
            let cell = Cell(index/7,index%7)
            guard var gem = board[index], gem.isDark else { continue }
            let targets = duskTargets(at: cell)
            guard !targets.isEmpty else { continue }
            if gem.duskFeeds == DuskRule.feedingShowers - 1 {
                collapses.append(.init(center: cell, duskID: gem.id, consumed: targets))
            } else { gem.feedDusk(); board[index] = gem }
        }
        guard !collapses.isEmpty else { return [] }
        let consumed = collapses.reduce(into: Set<Cell>()) { $0.formUnion($1.consumed) }
        unscoredStarlight = lostStarlight + value(of: consumed)
        darkStarsCleared += collapses.count
        for cell in consumed.union(collapses.map(\.center)) { board[cell.row*7+cell.column] = nil }
        gravityPhase(.removal, into: &phases)
        if let field = orbit, !consumed.isDisjoint(with: field.slots) {
            closeOrbit(into: &phases, settles: false)
        }
        board = GravityFieldRules.settle(board, field: orbit)
        gravityPhase(.settling, into: &phases)
        return collapses
    }

    private mutating func gravityPhase(_ event: GravityPhase.Event, into phases: inout [GravityPhase]) {
        phases.append(GravityPhase(event: event, board: board, field: orbit))
    }
    private mutating func allocateGravityID() -> Int {
        let id = max(nextGravityID ?? starsLanded, starsLanded)
        nextGravityID = id + 1
        return id
    }
    private mutating func closeOrbit(into phases: inout [GravityPhase], settles: Bool = true) {
        guard let field = orbit else { return }
        board[field.center.row*7+field.center.column] = nil
        retiredMagnetic = (retiredMagnetic ?? 0) + 2
        orbit = nil
        gravityPhase(.release, into: &phases)
        if settles {
            board = GravityFieldRules.settle(board, field: nil)
            gravityPhase(.settling, into: &phases)
        }
    }
    private mutating func resolveGravityClear(_ selected: Set<Cell>, into phases: inout [GravityPhase]) -> Set<Cell> {
        let hadOrbit = orbit != nil
        let dark = darkStarsBeside(selected)
        darkStarsCleared += dark.count
        let removed = selected.union(dark)
        let captiveHit = orbit.map { !selected.isDisjoint(with: $0.slots) } ?? false
        for cell in removed { board[cell.row*7+cell.column] = nil }
        gravityPhase(.removal, into: &phases)
        if captiveHit { closeOrbit(into: &phases, settles: false) }
        let middle = hadOrbit ? nil : GravityFieldRules.collision(in: board, opened: removed)
        let pair: Set<Cell> = middle.map { [Cell($0.row,$0.column-1),Cell($0.row,$0.column+1)] } ?? []
        let nearby = Set(selected.flatMap(GravityFieldRules.neighbors)).subtracting(pair)
        for cell in nearby where board[cell.row*7+cell.column]?.gravityKind == .magnet {
            board[cell.row*7+cell.column] = nil
            retiredMagnetic = (retiredMagnetic ?? 0) + 1
        }
        var newbornID: Int?
        if let middle {
            for cell in pair { board[cell.row*7+cell.column] = nil }
            let id = allocateGravityID(); newbornID = id
            board[middle.row*7+middle.column] = StarfallGem(id: id, kind: nil, gravity: .hole)
            gravityPhase(.collision, into: &phases)
        }
        board = GravityFieldRules.settle(board, field: orbit)
        gravityPhase(.settling, into: &phases)
        if let id = newbornID, let index = board.firstIndex(where: { $0?.id == id }) {
            let center = Cell(index/7,index%7)
            let slots = GravityFieldRules.neighbors(center).filter { board[$0.row*7+$0.column]?.kind != nil }
            orbit = OrbitField(holeID: id, center: center, slots: slots, windowsRemaining: 3)
            gravityPhase(.capture, into: &phases)
            if slots.count < 2 { closeOrbit(into: &phases) }
        }
        return removed
    }
    private mutating func advanceOrbit(into phases: inout [GravityPhase]) {
        guard var field = orbit else { return }
        if field.windowsRemaining == 1 { closeOrbit(into: &phases); return }
        let occupants = field.slots.map { board[$0.row*7+$0.column] }
        for index in field.slots.indices {
            let target = field.slots[(index+1)%field.slots.count]
            board[target.row*7+target.column] = occupants[index]
        }
        field.windowsRemaining -= 1; orbit = field
        gravityPhase(.rotation, into: &phases)
    }
    private var gravityStateValid: Bool {
        let special = board.compactMap { $0 }.filter { $0.gravityKind != nil }
        guard special.allSatisfy({ $0.kind == nil && !$0.grown && !$0.isLight }),
              retiredMagnetic.map({ $0 >= 0 && $0 <= starsLanded }) ?? true,
              nextGravityID.map({ $0 >= starsLanded && $0 < Int.max/2 }) ?? true else { return false }
        if let field = orbit {
            guard (0..<7).contains(field.center.row), (0..<7).contains(field.center.column),
                  (1...3).contains(field.windowsRemaining), (2...4).contains(field.slots.count),
                  Set(field.slots).count == field.slots.count,
                  field.slots == GravityFieldRules.neighbors(field.center).filter({ field.slots.contains($0) }),
                  gem(at: field.center)?.gravityKind == .hole, gem(at: field.center)?.id == field.holeID,
                  field.slots.allSatisfy({ gem(at: $0)?.kind != nil }),
                  special.filter({ $0.gravityKind == .hole }).count == 1 else { return false }
        } else if special.contains(where: { $0.gravityKind == .hole }) { return false }
        return GravityFieldRules.settle(board, field: orbit) == board
    }
    /// Preview the exact deterministic consequence without mutating input, forecast or RNG.
    public func gravityPreview(at cell: Cell) -> FallingSky? {
        var copy = self
        return copy.clear(cell) == nil ? nil : copy
    }
}

#if DEBUG
public enum GravityFixture: String, CaseIterable, Sendable {
    case opportunity, takeNow, stranded, supports, trace, naturalOpportunity, naturalOffer
    public var title: String { if self == .naturalOffer { return "A magnetic pair arrives" }; if self == .naturalOpportunity { return "A natural gravity choice" }; if self == .trace { return "Trace a captive" }; if self == .supports { return "Release suspended stars" }; if self == .stranded { return "Release a lone magnet" }; return self == .opportunity ? "Wait for the connection" : "Take the connection now" }
    public var message: String {
        if self == .naturalOffer { return "A calm-wave magnetic pair has arrived. Clear space, then decide when to open its middle." }
        if self == .naturalOpportunity { return "Choose a clear around the orbit. The stars you leave determine the next connection." }
        if self == .trace { return "Clear the pink middle, then trace five aqua stars including the captive to release the orbit." }
        if self == .supports { return "Clear the pink middle, then the front aqua group. Captives hold their positions until the hole closes." }
        if self == .stranded { return "Clear the aqua group beside the lone magnet. No partner is required to remove it." }
        return self == .opportunity
        ? "Clear the pink middle. A hole catches the two survivors. Next shower swaps them into matching neighbors."
        : "Clear the pink middle. The captured stars already have matching neighbors; another rotation breaks those connections."
    }
    public func game() -> FallingSky {
        if self == .naturalOpportunity { return GravityOpportunityFixture.game() }
        if self == .naturalOffer { return GravityOpportunityFixture.game(through:7) }
        var game = FallingSky(seed: 5, balance: .init(pace: .gentle, darkStars: .none), openingCascade: false, generation: .gravityOrbits)
        if self == .trace {
            game = GravityFixture.takeNow.game()
            for _ in 0..<10 { game.scriptGravityShower([(.colored(.aqua),2)]) }
            game.setGravityForecast([(.colored(.violet),6)])
            return game
        }
        if self == .supports {
            game.scriptGravityShower([(.colored(.aqua),0),(.colored(.aqua),1),(.colored(.aqua),2),(.colored(.mint),3),(.colored(.mint),4)])
            game.scriptGravityShower([(.magnet,2),(.magnet,4),(.colored(.rose),3)])
            game.scriptGravityShower([(.colored(.amber),2),(.colored(.violet),4),(.colored(.rose),3)])
            game.scriptGravityShower([(.colored(.rose),3)])
            game.scriptGravityShower([(.colored(.amber),3)])
            game.setGravityForecast([(.colored(.violet),2)])
            return game
        }
        if self == .stranded {
            game.scriptGravityShower([(.colored(.aqua),1),(.colored(.aqua),2),(.magnet,3)])
            game.scriptGravityShower([(.colored(.aqua),1)])
            return game
        }
        // All fixture pieces arrive through normal committed showers, including growth.
        game.scriptGravityShower([(.magnet,2),(.magnet,4),(.colored(.rose),3)])
        game.scriptGravityShower([(.colored(.aqua),2),(.colored(.amber),4),(.colored(.rose),3)])
        game.scriptGravityShower([(.colored(.rose),3)])
        let left: Jewel = self == .opportunity ? .amber : .aqua
        let right: Jewel = self == .opportunity ? .aqua : .amber
        game.scriptGravityShower([(.colored(left),1),(.colored(right),5)])
        game.scriptGravityShower([(.colored(left),1),(.colored(right),5)])
        // Explicit local future: normal generated arrivals resume after this forecast.
        game.setGravityForecast([(.colored(.violet),6)])
        precondition(game.isValidSave)
        return game
    }
}
extension FallingSky {
    mutating func setGravityForecast(_ items: [(SkyIdentity,Int)]) {
        incoming = items.enumerated().map { index, item in
            let kind: Jewel?
            let gravity: GravityKind?
            switch item.0 {
            case .colored(let family): kind = family; gravity = nil
            case .dusk: kind = nil; gravity = nil
            case .magnet: kind = nil; gravity = .magnet
            case .white: kind = nil; gravity = nil
            case .hole: preconditionFailure("Holes form only by collision")
            }
            return IncomingStar(id: turns*5+index, kind: kind, column: item.1, light: item.0 == .white, gravity: gravity)
        }
    }
    mutating func scriptGravityShower(_ items: [(SkyIdentity,Int)]) {
        setGravityForecast(items)
        precondition(letStarsFall() != nil && isValidSave)
    }
}

extension GravityFixture {
    static func duskBoundaryGame() -> FallingSky {
        var game=FallingSky(seed:5,balance:.init(pace:.gentle,darkStars:.none),openingCascade:false, generation:.gravityOrbits)
        game.scriptGravityShower([(.magnet,3),(.dusk,2),(.colored(.mint),1)])
        game.scriptGravityShower([(.colored(.mint),1)])
        game.scriptGravityShower([(.colored(.mint),1)])
        return game
    }
    /// Committed sparse histories for bounded zero/one/three-captive edge checks.
    static func sparse(captives: Int) -> FallingSky {
        precondition((0...3).contains(captives))
        var game=FallingSky(seed:5,balance:.init(pace:.gentle,darkStars:.none),openingCascade:false, generation:.gravityOrbits)
        game.scriptGravityShower([(.magnet,2),(.magnet,4),(.colored(.rose),3)])
        game.scriptGravityShower([(.colored(.rose),3)])
        game.scriptGravityShower([(.colored(.rose),3)])
        if captives > 0 { game.scriptGravityShower([(.colored(.aqua),2)]) }
        if captives > 1 { game.scriptGravityShower([(.colored(.amber),4)]) }
        if captives > 2 { game.scriptGravityShower([(.colored(.violet),3)]) }
        return game
    }
}

extension GravityFixture {
    static func opalBoundaryGame() -> FallingSky {
        var game = FallingSky(seed:5,balance:.init(darkStars:.none),openingCascade:false,generation:.gravityOrbits)
        game.scriptGravityShower([(.magnet,2),(.magnet,4),(.colored(.rose),3)])
        game.scriptGravityShower([(.white,2),(.colored(.aqua),4)])
        for _ in 0..<9 { game.scriptGravityShower([(.colored(.rose),3)]) }
        game.scriptGravityShower([(.colored(.amber),3)])
        game.setGravityForecast([(.colored(.violet),6)])
        return game
    }
}

#endif
