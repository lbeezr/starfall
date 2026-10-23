import Foundation

/// Production falling-sky rules with deterministic shower events. The Debug classic Game is independent.
public struct StarfallGem: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    public let kind: Jewel?
    public var grown: Bool
    private var savedStellarAge: Int?
    /// Committed showers survived; independent of collected starlight.
    public var stellarAge: Int { savedStellarAge ?? 0 }
    public var massStage: Int { max(grown ? 2 : 1, 1 + stellarAge / CriticalMassRule.showersPerStage) }
    public var isCritical: Bool { massStage == 3 }
    mutating func removeStellarAge() { savedStellarAge = nil }
    mutating func ageStar() { savedStellarAge = stellarAge + 1 }
    func validStellarAge(enabled: Bool) -> Bool {
        guard let age = savedStellarAge else { return true }
        return enabled && !isDark && gravityKind == nil && (1..<CriticalMassRule.collapseAge).contains(age)
    }
    private var savedDuskFeeds: Int?
    public var duskFeeds: Int { savedDuskFeeds ?? 0 }
    mutating func feedDusk() { savedDuskFeeds = duskFeeds + 1 }
    func validDuskFeeds(rule: DuskRule) -> Bool { savedDuskFeeds.map { isDark && (1..<rule.feedingShowers).contains($0) } ?? true }
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
    public struct Arrival: Equatable, Sendable {
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
    public var stellarCollapses: [StarCollapse] = []
    public var stellarAffectedColumns: Set<Int> = []
    public var duskCollapses: [DuskCollapse] = []
    public var duskAffectedColumns: Set<Int> = []
    public var presentationPhases: [SkyPresentationPhase] = []
    /// Revision-two clear phases, including an initiating manual clear when present.
    /// Historical turns retain their original presentation and leave this empty.
    public let resolutionPhases: [SkyResolutionPhase]
    public let award: SkyScoreAward?
    public var displayAward: Int { award?.displayPoints ?? collected }
    /// Compatibility spelling for historical tools. These phases also present ordinary collapses.
    public var gravityPhases: [SkyPresentationPhase] {
        get { presentationPhases }
        set { presentationPhases = newValue }
    }
    public let cleared: Set<Cell>
    public let collected: Int
    public let settled: [StarfallGem?]
    public let forecast: [IncomingStar]
    public let arrivals: [Arrival]
    public let blockedColumn: Int?

    init(exchange: Exchange? = nil, stellarCollapses: [StarCollapse] = [],
         stellarAffectedColumns: Set<Int> = [], duskCollapses: [DuskCollapse] = [],
         duskAffectedColumns: Set<Int> = [], presentationPhases: [SkyPresentationPhase] = [],
         resolutionPhases: [SkyResolutionPhase] = [],
         award: SkyScoreAward? = nil, cleared: Set<Cell>, collected: Int,
         settled: [StarfallGem?], forecast: [IncomingStar], arrivals: [Arrival], blockedColumn: Int?) {
        self.exchange = exchange
        self.stellarCollapses = stellarCollapses
        self.stellarAffectedColumns = stellarAffectedColumns
        self.duskCollapses = duskCollapses
        self.duskAffectedColumns = duskAffectedColumns
        self.presentationPhases = presentationPhases
        self.resolutionPhases = resolutionPhases
        self.award = award
        self.cleared = cleared
        self.collected = collected
        self.settled = settled
        self.forecast = forecast
        self.arrivals = arrivals
        self.blockedColumn = blockedColumn
    }
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
    private var savedCriticalMassRule: Int?
    public var hasCriticalMass: Bool { savedCriticalMassRule == CriticalMassRule.version }
    /// Version 2 retires aging while preserving the no-Dusk generator and lost-light ledger.
    public var hasPocketedDusk: Bool { savedCriticalMassRule != nil }
    public func disablingAutomaticAging() -> FallingSky {
        guard hasCriticalMass else { return self }
        var result = self
        result.savedCriticalMassRule = CriticalMassRule.retiredVersion
        for index in result.board.indices { result.board[index]?.removeStellarAge() }
        return result
    }
    private var savedDuskRule: Int?
    private var unscoredStarlight: Int?
    public var duskRule: DuskRule { DuskRule(rawValue: savedDuskRule ?? 0) ?? .legacy }
    public var lostStarlight: Int { unscoredStarlight ?? 0 }

    /// Explicit app migration. Committed board/score/preview/RNG/cadence stay intact.
    public func adoptingFeedingDusk() -> FallingSky {
        guard !hasPocketedDusk, challenge == nil, duskRule != .patientFeeding else { return self }
        var adopted = self
        adopted.savedDuskRule = DuskRule.patientFeeding.rawValue
        adopted.unscoredStarlight = lostStarlight
        return adopted
    }
    public private(set) var blockedColumn: Int?
    public private(set) var challenge: StarfallChallenge?
    // Missing in retained rounds: preserve historical raw replay until explicit app migration.
    private var savedChallengeActions: Int?
    private var savedChallengeRevision: Int?
    private var storyScoreLedger: StoryScoreLedger?
    private var fullBoardSupply: FullBoardSupply?
    public var challengeRevision: Int { savedChallengeRevision ?? 0 }
    /// Explicit Lantern comparison; ordinary Story visits retain their saved sky rules.
    public var usesFullBoardRefill: Bool { challenge == .firstLight && challengeRevision == 5 }
    private var storyDefinition: StoryChallengeDefinition? {
        guard let challenge else { return nil }
        return StoryChallengeDefinition(challenge, revision: challengeRevision)
    }
    /// Authored revisions two onward resolve recipes after committed settling.
    public var supportsAutomaticRecipes: Bool { (storyDefinition?.revision ?? 0) >= 2 }
    /// The saved round's actual-star threshold; retained rules may omit lines.
    public var automaticLineLength: Int? { storyDefinition?.automaticLineLength }
    /// Revisions three onward earn clears only by completing automatic board patterns.
    public var supportsManualClears: Bool { challengeRevision < 3 }
    /// Player-facing points for this saved revision; `score` remains conserved light.
    public var displayScore: Int {
        guard challengeRevision != 0 else { return score }
        let (units, unitOverflow) = score.addingReportingOverflow(storyScoreLedger?.bonusUnits ?? 0)
        let (points, pointOverflow) = units.multipliedReportingOverflow(by: 1_000)
        return unitOverflow || pointOverflow ? Int.max : points
    }
    /// The saved round's objective, including an unchanged historical 18-light finish.
    public var displayTarget: Int? { storyDefinition?.target ?? challenge?.target }
    public func displayAward(for turn: FallingSkyTurn) -> Int { turn.displayAward }
    /// Pure award preview. Callers still validate the selected action before committing.
    public func displayReward(of cells: Set<Cell>) -> Int {
        guard supportsManualClears else { return 0 }
        guard storyDefinition != nil else { return reward(of: cells) }
        if supportsAutomaticRecipes {
            let actual = cells.filter { gem(at: $0) != nil }
            guard actual.count >= 2, value(of: actual) >= 3 else { return scoreAward(for: actual).displayPoints }
            let phases = SkyRecipeResolution.resolve(board, manualClear: actual)
            return SkyScoreAward(summing: phases.map(\.award)).displayPoints
        }
        return scoreAward(for: cells).displayPoints
    }
    public var challengeActionVersion: Int { savedChallengeActions ?? 0 }
    public var supportsArrangingStars: Bool { challenge == nil || challengeActionVersion == 1 }

    /// Add current input actions without changing any committed state or seeded supply.
    public func adoptingCurrentChallengeActions() -> FallingSky {
        guard challenge != nil, challengeActionVersion == 0 else { return self }
        var result = self
        result.savedChallengeActions = 1
        return result
    }
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
        if let target = displayTarget, displayScore >= target { return .won }
        return blockedColumn == nil ? .playing : .lost
    }
    public var isOver: Bool { outcome != .playing }
    public var occupiedCount: Int { board.compactMap { $0 }.count }

    public init(seed: UInt64, balance: StarfallBalance = StarfallBalance(), openingCascade: Bool = true,
                generation: SkyGeneration = .legacy, cadence: SkyCadenceID = .announcedCycleV2, duskRule: DuskRule = .legacy, criticalMass: Bool = false) {
        precondition(!openingCascade || cadence != .originalV1)
        self.seed = seed
        precondition(!criticalMass || (duskRule == .legacy && generation == .standardSky))
        savedCriticalMassRule = criticalMass ? CriticalMassRule.version : nil
        savedDuskRule = duskRule == .legacy ? nil : duskRule.rawValue
        unscoredStarlight = duskRule == .legacy && !criticalMass ? nil : 0
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

    /// Current normal-app entry point. Explicit initializers still reconstruct retained versions.
    public static func freshSurvival(seed: UInt64, balance: StarfallBalance = StarfallBalance()) -> FallingSky {
        FallingSky(seed: seed, balance: balance, generation: .current,
                   cadence: .announcedCycleV1, criticalMass: true).disablingAutomaticAging()
    }

    /// Historical unversioned content, also used by the disposable restoration lesson.
    /// Normal new visits use `freshChallenge`; saved rounds restore their own revision.
    public init(challenge: StarfallChallenge) {
        self.init(seed: challenge.seed, balance: challenge.balance, openingCascade: false, generation: .legacy)
        self.challenge = challenge
        savedChallengeActions = 1
    }

    /// New visits select current authored content. Resume and replay never call this.
    public static func freshChallenge(_ challenge: StarfallChallenge) -> FallingSky {
        guard let definition = StoryChallengeDefinition(challenge) else { return FallingSky(challenge: challenge) }
        return FallingSky(definition: definition)
    }

    public static func fullBoardLantern() -> FallingSky {
        FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 5)!)
    }

    /// Reconstruct a specific shipped definition; normal new visits use `freshChallenge`.
    public init(definition: StoryChallengeDefinition) {
        self.init(seed: definition.seed, balance: definition.balance, openingCascade: false)
        challenge = definition.challenge
        savedChallengeActions = 1
        savedChallengeRevision = definition.revision
        storyScoreLedger = StoryScoreLedger(automaticRecipes: definition.revision >= 2)
        fullBoardSupply = definition.revision == 5 ? FullBoardSupply() : nil
        board = definition.initialBoard
        starsLanded = definition.initialLight
        random = SeededRandom(seed: definition.seed)
        remainingColumns = []
        incoming = definition.shower(number: 1)
    }

    /// Reset committed play while retaining timing, tuning and historical generation rules.
    public func replay() -> FallingSky {
        var replay = self
        replay.board = Array(repeating: nil, count: Self.side * Self.side)
        replay.incoming = []
        replay.score = 0
        replay.turns = 0
        replay.starsLanded = 0
        if let definition = storyDefinition {
            replay.board = definition.initialBoard
            replay.starsLanded = definition.initialLight
            replay.storyScoreLedger = StoryScoreLedger(automaticRecipes: definition.revision >= 2)
            replay.fullBoardSupply = usesFullBoardRefill ? FullBoardSupply() : nil
        }
        replay.darkStarsCleared = 0
        replay.unscoredStarlight = duskRule != .legacy || hasPocketedDusk ? 0 : nil
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
        guard duskRule != .legacy, let gem = gem(at: cell), gem.kind != nil || gem.isLight else { return false }
        return !darkStarsBeside([cell]).isEmpty
    }

    public func reward(of cells: Set<Cell>) -> Int {
        cells.reduce(0) { $0 + (isDrained(at: $1) ? 0 : (gem(at: $1)?.value ?? 0)) }
    }

    public func duskTargets(at cell: Cell) -> Set<Cell> {
        guard duskRule != .legacy, gem(at: cell)?.isDark == true else { return [] }
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
        guard supportsManualClears else { return [] }
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
        guard supportsManualClears, !isOver else { return nil }
        let cells = group(at: cell)
        guard value(of: cells) >= 3 else { return nil }
        return clearCommitted(cells)
    }

    /// Connection geometry shared by eligibility and selected-path validation.
    /// Family membership is checked separately so Opal keeps the first star's family.
    public func canLinkConstellation(_ from: Cell, to: Cell) -> Bool {
        guard let first = gem(at: from), !first.isDark,
              let last = gem(at: to), !last.isDark else { return false }
        let dr = abs(to.row-from.row), dc = abs(to.column-from.column)
        if dr <= 1 && dc <= 1 { return true }
        guard max(dr, dc) == 2, dr == 0 || dc == 0 || dr == dc else { return false }
        return gem(at: Cell((from.row+to.row)/2, (from.column+to.column)/2)) == nil
    }

    /// Walk order, family and distinct count are rules, not gesture/presentation decisions.
    /// Shared prefix legality for live input and committed walks. The first
    /// colored star fixes the family even after the path crosses a white orb.
    public func isValidConstellationPrefix(_ path: [Cell]) -> Bool {
        guard supportsManualClears, path.count <= 196, let first = path.first, let kind = gem(at: first)?.kind else { return false }
        var previous = first
        for cell in path {
            guard matchesFamily(kind, at: cell),
                  canLinkConstellation(previous, to: cell) else { return false }
            previous = cell
        }
        return true
    }

    /// Start eligibility is shared by native hit testing and transient selections.
    public func canStartConstellation(at cell: Cell) -> Bool {
        // Holding chooses drawing even before a complete constellation exists.
        // Completion still validates family, links and the selected distinct count.
        supportsManualClears && !isOver && gem(at: cell)?.kind != nil
    }

    public func constellationCells(along path: [Cell]) -> Set<Cell>? {
        guard isValidConstellationPrefix(path) else { return nil }
        let cells = Set(path)
        return cells.count >= 5 || (supportsArrangingStars && cells.count == 4 && recipe(matching:cells)?.shape == .square) ? cells : nil
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
        guard supportsManualClears, canArrangeStars, recipes.contains(recipe) else { return nil }
        return clearCommitted(Set(recipe.cells))
    }

    @discardableResult public mutating func nudge(from: Cell, to: Cell) -> FallingSkyTurn? {
        guard canNudge(from:from,to:to) else { return nil }
        let before = self
        board.swapAt(from.row * Self.side + from.column, to.row * Self.side + to.column)
        board = SkyBoardSettling.settle(board)
        let phases: [SkyResolutionPhase]
        if usesFullBoardRefill {
            // In this untimed comparison, turns count committed exchanges,
            // including setup swaps. No exchange consumes a shower preview.
            turns += 1
            phases = FullBoardLanternResolution.resolve(board, random: &random, nextID: &starsLanded)
            fullBoardSupply?.record(phases)
        } else {
            phases = supportsAutomaticRecipes ? SkyRecipeResolution.resolve(board, lineLength: automaticLineLength) : []
        }
        let award = commitResolution(phases)
        return .init(exchange:.init(from:from,to:to),stellarAffectedColumns: criticalMassChangedColumns(from: before),duskAffectedColumns:duskChangedColumns(from:before),
                     resolutionPhases: phases, award: award, cleared:[],collected:award?.baseLight ?? 0,settled:board,
                     forecast:incoming,arrivals:[],blockedColumn:nil)
    }

    private mutating func clearCommitted(_ cells: Set<Cell>) -> FallingSkyTurn {
        if supportsAutomaticRecipes {
            let phases = SkyRecipeResolution.resolve(board, manualClear: cells)
            let award = commitResolution(phases)!
            return .init(resolutionPhases: phases, award: award, cleared: cells,
                         collected: award.baseLight, settled: board, forecast: incoming, arrivals: [], blockedColumn: nil)
        }
        let before = self
        let collected = reward(of: cells)
        let award = storyDefinition == nil ? nil : scoreAward(for: cells)
        if let award { storyScoreLedger?.record(award) }
        if duskRule != .legacy { unscoredStarlight = lostStarlight + value(of: cells) - collected }
        if orbit != nil || board.contains(where: { $0?.gravityKind != nil }) {
            var phases: [SkyPresentationPhase] = []
            score += collected
            let removed = resolveGravityClear(cells, into: &phases)
            return .init(stellarAffectedColumns: criticalMassChangedColumns(from: before), duskAffectedColumns: duskChangedColumns(from: before), presentationPhases: phases, cleared: removed, collected: collected, settled: board,
                         forecast: incoming, arrivals: [], blockedColumn: nil)
        }
        let darkStars = darkStarsBeside(cells)
        let removed = cells.union(darkStars)
        darkStarsCleared += darkStars.count
        score += collected
        for cell in removed { board[cell.row * Self.side + cell.column] = nil }
        board = SkyBoardSettling.settle(board)
        return .init(stellarAffectedColumns: criticalMassChangedColumns(from: before), duskAffectedColumns: duskChangedColumns(from: before), award: award, cleared: removed, collected: collected, settled: board,
                     forecast: incoming, arrivals: [], blockedColumn: nil)
    }

    private func scoreAward(for cells: Set<Cell>) -> SkyScoreAward {
        let collected = reward(of: cells)
        let stars = cells.filter { !isDrained(at: $0) && (gem(at: $0)?.value ?? 0) > 0 }.count
        return SkyScoreAward(baseLight: collected, clearedStarCount: stars)
    }

    private mutating func commitResolution(_ phases: [SkyResolutionPhase]) -> SkyScoreAward? {
        guard let last = phases.last else { return nil }
        for phase in phases { storyScoreLedger?.record(phase.award, depth: phase.comboDepth) }
        let award = SkyScoreAward(summing: phases.map(\.award))
        score += award.baseLight
        board = last.refilled
        return award
    }

    /// Clock-independent event: the presentation layer decides when the sky advances.
    /// Clearing never consumes or regenerates this preview.
    @discardableResult public mutating func letStarsFall() -> FallingSkyTurn? {
        guard !usesFullBoardRefill, !isOver else { return nil }
        let before = self
        turns += 1
        var phases: [SkyPresentationPhase] = []
        let stellarCollapses = advanceCriticalMass(into: &phases)
        let collapses = advanceDusk(into: &phases)
        advanceOrbit(into: &phases)
        let settled = board, forecast = incoming
        var arrivals: [FallingSkyTurn.Arrival] = []
        for star in forecast {
            let height = SkyBoardSettling.height(board, column: star.column)
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
        // An ordered arrival that overflows commits the existing loss. Only a
        // fully landed shower can begin recipe resolution and a new forecast.
        let resolution = supportsAutomaticRecipes && blockedColumn == nil
            ? SkyRecipeResolution.resolve(board, lineLength: automaticLineLength) : []
        let award = commitResolution(resolution)
        if !isOver || (supportsAutomaticRecipes && blockedColumn == nil) { incoming = nextShower() }
        return .init(stellarCollapses: stellarCollapses,
                     stellarAffectedColumns: criticalMassChangedColumns(from: before), duskCollapses: collapses, duskAffectedColumns: duskChangedColumns(from: before), presentationPhases: phases,
                     resolutionPhases: resolution, award: award, cleared: [], collected: award?.baseLight ?? 0, settled: settled,
                     forecast: forecast, arrivals: arrivals, blockedColumn: blockedColumn)
    }

    private mutating func nextShower() -> [IncomingStar] {
        if let definition = storyDefinition { return definition.shower(number: turns + 1) }
        let modern = generation != .legacy && challenge == nil && turns >= 4
        let storm = modern && generation.phase(for: turns + 1)?.isStorm == true
        let sizes = [1, 2, 2, 3, 3, 3, 5]
        let naturalCount = sizes[Int(random.next() % UInt64(sizes.count))]
        // A dry board gets a useful run in its next forecast, plus two pressure
        // stars. Never rewrite an announced preview or alter the board for free.
        let heights = (0..<Self.side).map { column in
            SkyBoardSettling.height(board, column: column)
        }
        let reliefColumn = cohesiveShowers == true && turns > 0 && legalGroups.isEmpty
            ? heights.indices.filter { heights[$0] <= 4 }.min { heights[$0] < heights[$1] } : nil
        let count = reliefColumn == nil ? (storm ? 5 : naturalCount) : 5
        let darkIndex: Int?
        if !hasPocketedDusk, let gap = balance.darkStars.showerGap, showersUntilDark == 0 {
            darkIndex = reliefColumn == nil ? Int(random.next() % UInt64(count)) : 3 + Int(random.next() % 2)
            showersUntilDark = gap.lowerBound - 1 + Int(random.next() % UInt64(gap.count))
        } else {
            darkIndex = nil
            if !hasPocketedDusk, balance.darkStars != .none { showersUntilDark -= 1 }
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
        guard supportsManualClears else { return [] }
        guard let kind = gem(at: start)?.kind else { return [] }
        var found: Set<Cell> = [start], pending = [start]
        while let cell = pending.popLast() {
            for dr in -2...2 { for dc in -2...2 where dr != 0 || dc != 0 {
                let next = Cell(cell.row + dr, cell.column + dc)
                if !found.contains(next), canLinkConstellation(cell, to: next), matchesFamily(kind, at: next) {
                    found.insert(next); pending.append(next)
                }
            } }
        }
        return found.count >= 5 ? found : []
    }

    public var isValidSave: Bool {
        // Reject scalar corruption before deriving a shower number or doing
        // conservation arithmetic, for every retained and current ruleset.
        guard board.count == 49, [nil, 1, 2, 3, 4, 5].contains(savedChallengeRevision),
              turns >= 0, turns < Int.max / 6, score >= 0, starsLanded >= 0 else { return false }
        if let definition = storyDefinition {
            guard challengeActionVersion == 1, seed == definition.seed, balance == definition.balance,
                  !hasOpeningCascade, generation == .legacy, duskRule == .legacy, darkStarsCleared == 0,
                  savedCriticalMassRule == nil, turns >= 0, turns < Int.max / 6 - 1,
                  board.allSatisfy({ $0 == nil || ($0?.kind.map { definition.palette.contains($0) } == true
                                                  && $0?.gravityKind == nil && $0?.isLight != true) }),
                  incoming == definition.shower(number: blockedColumn == nil ? turns + 1 : max(1, turns)),
                  storyScoreLedger?.isValid(light: score, target: definition.target,
                                           automaticRecipes: supportsAutomaticRecipes,
                                           manualClears: supportsManualClears,
                                           fullBoardRefill: usesFullBoardRefill) == true else { return false }
            if supportsAutomaticRecipes && blockedColumn == nil && !recipes.isEmpty { return false }
            if usesFullBoardRefill {
                guard let ledger = storyScoreLedger, let supply = fullBoardSupply,
                      blockedColumn == nil, occupiedCount == 49,
                      board.allSatisfy({ $0?.grown == false }),
                      starsLanded == 49 + score,
                      supply.isValid(score: score, turns: turns, ledger: ledger, random: random, seed: seed) else { return false }
            } else {
                guard fullBoardSupply == nil else { return false }
                let expectedLight = definition.initialLight + definition.suppliedLight(after: turns)
                if blockedColumn == nil {
                    guard starsLanded == expectedLight else { return false }
                } else {
                    guard turns > 0, starsLanded >= definition.initialLight + definition.suppliedLight(after: turns - 1),
                          starsLanded < expectedLight else { return false }
                }
            }
        } else if savedChallengeRevision != nil || storyScoreLedger != nil || fullBoardSupply != nil { return false }
        guard [nil, 1].contains(savedChallengeActions),
              savedChallengeActions == nil || challenge != nil,
              [nil, CriticalMassRule.version, CriticalMassRule.retiredVersion].contains(savedCriticalMassRule),
              !hasPocketedDusk || (challenge == nil && generation == .standardSky && duskRule == .legacy
                && !board.contains(where: { $0?.isDark == true }) && !incoming.contains(where: \.isDark)),
              board.allSatisfy({ ($0?.validStellarAge(enabled: hasCriticalMass) ?? true) && (($0?.stellarAge ?? 0) == 0 || ($0?.stellarAge ?? 0) < turns) }),
              SkyGeneration(rawValue: savedGeneration ?? 0) != nil,
              DuskRule(rawValue: savedDuskRule ?? 0) != nil,
              (duskRule != .legacy || hasPocketedDusk) ? (unscoredStarlight != nil && lostStarlight >= 0 && lostStarlight <= starsLanded) : unscoredStarlight == nil,
              board.allSatisfy({ $0?.validDuskFeeds(rule: duskRule) ?? true }),
              duskRule != .legacy || board.allSatisfy({ ($0?.duskFeeds ?? 0) == 0 }) else { return false }
        if generation != .legacy && cohesiveShowers != true { return false }
        if !generation.supportsGravity {
            if orbit != nil || incoming.contains(where: { $0.gravityKind != nil }) || board.contains(where: { $0?.gravityKind != nil }) { return false }
            if generation != .standardSky && (nextGravityID != nil || retiredMagnetic != nil) { return false }
        }
        if generation == .legacy && (incoming.contains(where: \.isLight) || board.contains(where: { $0?.isLight == true })) { return false }
        if let challenge, storyDefinition == nil,
           seed != challenge.seed || balance != challenge.balance || hasOpeningCascade || generation != .legacy { return false }
        if let savedCadence, (savedCadence != .originalV1) != (openingCascade == true) { return false }
        guard board.count == 49, usesFullBoardRefill ? incoming.isEmpty : Self.showerSizes.contains(incoming.count),
              remainingColumns.allSatisfy({ (0..<7).contains($0) }),
              Set(remainingColumns).count == remainingColumns.count,
              turns >= 0, turns < Int.max / 6, score >= 0, starsLanded >= 0,
              (0...(balance.darkStars.showerGap.map { $0.upperBound - 1 } ?? 0)).contains(showersUntilDark),
              darkStarsCleared >= 0, darkStarsCleared <= starsLanded,
              incoming.allSatisfy({ (0..<7).contains($0.column) && $0.id >= 0 && (!$0.isLight || $0.kind == nil) && $0.gravityKind != .hole && ($0.gravityKind == nil || ($0.kind == nil && !$0.isLight)) }),
              Set(incoming.map(\.id)).count == incoming.count,
              blockedColumn.map({ (0..<7).contains($0) }) ?? true else { return false }
        // Overflow was committed against a full column. Explicit gravity retirement
        // can later remove its supports without reopening that historical result.
        // Existing retired archives carry mass accounting, not a pre-retirement board.
        if let column = blockedColumn, SkyBoardSettling.height(board, column: column) != 7,
           !(generation == .standardSky && !hasCriticalMass && (retiredMagnetic ?? 0) > 0) { return false }
        // Retired and lost light are disjoint parts of landed light. Bound each
        // subtraction before conservation arithmetic, including corrupted archives.
        let magnetic = retiredMagnetic ?? 0
        guard magnetic >= 0, magnetic <= starsLanded - darkStarsCleared,
              lostStarlight <= starsLanded - darkStarsCleared - magnetic else { return false }
        let available = starsLanded - darkStarsCleared - magnetic - lostStarlight
        let gems = board.compactMap { $0 }
        guard Set(gems.map(\.id)).count == gems.count,
              gems.allSatisfy({ $0.id >= 0 && $0.id < max(starsLanded, nextGravityID ?? 0) && !(($0.isDark || $0.isLight) && $0.grown) && (!$0.isLight || $0.kind == nil) }),
              usesFullBoardRefill || starsLanded <= turns * Self.maximumShowerSize + (storyDefinition?.initialLight ?? 0),
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

// Historical Dusk pressure retains the committed board boundary. Orbit mutation
// is delegated to HistoricalGravityState without moving encoded state.
extension FallingSky {
    /// All mature sources see the same committed neighborhood. No cascading targets.
    private mutating func advanceDusk(into phases: inout [SkyPresentationPhase]) -> [DuskCollapse] {
        guard duskRule != .legacy else { return [] }
        var collapses: [DuskCollapse] = []
        for index in board.indices {
            let cell = Cell(index/7,index%7)
            guard var gem = board[index], gem.isDark else { continue }
            let targets = duskTargets(at: cell)
            guard !targets.isEmpty else { continue }
            if gem.duskFeeds == duskRule.feedingShowers - 1 {
                collapses.append(.init(center: cell, duskID: gem.id, consumed: targets))
            } else { gem.feedDusk(); board[index] = gem }
        }
        guard !collapses.isEmpty else { return [] }
        let consumed = collapses.reduce(into: Set<Cell>()) { $0.formUnion($1.consumed) }
        unscoredStarlight = lostStarlight + value(of: consumed)
        darkStarsCleared += collapses.count
        for cell in consumed.union(collapses.map(\.center)) { board[cell.row*7+cell.column] = nil }
        recordPhase(.removal, into: &phases)
        if let field = orbit, !consumed.isDisjoint(with: field.slots) {
            closeOrbit(into: &phases, settles: false)
        }
        board = GravityFieldRules.settle(board, field: orbit)
        recordPhase(.settling, into: &phases)
        return collapses
    }

    private mutating func recordPhase(_ event: SkyPresentationPhase.Event, into phases: inout [SkyPresentationPhase]) {
        phases.append(SkyPresentationPhase(event: event, board: board, field: orbit))
    }
    private var historicalGravity: HistoricalGravityState {
        .init(board: board, orbit: orbit, nextGravityID: nextGravityID,
              retiredMagnetic: retiredMagnetic, starsLanded: starsLanded)
    }
    private mutating func applyHistoricalGravity(_ state: HistoricalGravityState) {
        board = state.board; orbit = state.orbit
        nextGravityID = state.nextGravityID; retiredMagnetic = state.retiredMagnetic
    }
    private mutating func allocateGravityID() -> Int {
        var state = historicalGravity
        let id = state.allocateGravityID()
        applyHistoricalGravity(state)
        return id
    }
    private mutating func closeOrbit(into phases: inout [SkyPresentationPhase], settles: Bool = true) {
        var state = historicalGravity
        state.closeOrbit(into: &phases, settles: settles)
        applyHistoricalGravity(state)
    }
    private mutating func resolveGravityClear(_ selected: Set<Cell>, into phases: inout [SkyPresentationPhase]) -> Set<Cell> {
        let dark = darkStarsBeside(selected)
        darkStarsCleared += dark.count
        var state = historicalGravity
        let removed = state.resolveGravityClear(selected, dark: dark, into: &phases)
        applyHistoricalGravity(state)
        return removed
    }
    private mutating func advanceOrbit(into phases: inout [SkyPresentationPhase]) {
        guard orbit != nil else { return }
        var state = historicalGravity
        state.advanceOrbit(into: &phases)
        applyHistoricalGravity(state)
    }
    private var gravityStateValid: Bool { historicalGravity.isValid }
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

// Universal pressure is versioned independently from historical Dusk rules.
extension FallingSky {
    public func criticalMassTargets(at cell: Cell) -> Set<Cell> {
        guard hasCriticalMass, let source = gem(at: cell), source.isCritical else { return [] }
        return Set(neighbors(of: cell).filter {
            guard let target = gem(at: $0) else { return false }
            return !target.isDark && target.gravityKind == nil
        })
    }

    private func criticalMassChangedColumns(from old: FallingSky) -> Set<Int> {
        guard hasCriticalMass else { return [] }
        return Set(board.indices.compactMap { index in
            board[index] != old.board[index]
                || criticalMassTargets(at: Cell(index / Self.side, index % Self.side)) != old.criticalMassTargets(at: Cell(index / Self.side, index % Self.side))
                ? index % Self.side : nil
        })
    }

    private mutating func advanceCriticalMass(into phases: inout [SkyPresentationPhase]) -> [StarCollapse] {
        guard hasCriticalMass else { return [] }
        // Read one pre-aging neighborhood: simultaneous sources cannot create chains.
        let sources = board.indices.filter { (board[$0]?.stellarAge ?? 0) == CriticalMassRule.collapseAge - 1 }
        let collapses = sources.map { index in
            let cell = Cell(index / Self.side, index % Self.side)
            return StarCollapse(center: cell, sourceID: board[index]!.id, consumed: criticalMassTargets(at: cell))
        }
        let removed = collapses.reduce(into: Set<Cell>()) { $0.formUnion($1.consumed); $0.insert($1.center) }
        unscoredStarlight = lostStarlight + value(of: removed)
        for index in board.indices {
            let cell = Cell(index / Self.side, index % Self.side)
            if removed.contains(cell) { board[index] = nil }
            else if var gem = board[index] { gem.ageStar(); board[index] = gem }
        }
        if !collapses.isEmpty {
            recordPhase(.removal, into: &phases)
            board = SkyBoardSettling.settle(board)
            recordPhase(.settling, into: &phases)
        }
        return collapses
    }
}
