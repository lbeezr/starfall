import Foundation
import Observation
import OSLog
import SwiftUI
import StarfallCore

@MainActor protocol FallingSkyPresenting: AnyObject {
    var reduceMotion: Bool { get set }
    func render(_ game: FallingSky)
    func animate(_ turn: FallingSkyTurn, from old: FallingSky,
                 to game: FallingSky, completion: @escaping () -> Void)
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 phaseBegan: @escaping (Int) -> Void, completion: @escaping () -> Void)
    func prepareOpening(_ game: FallingSky)
    func presentOpening(_ game: FallingSky, completion: @escaping () -> Void)
    func showBufferedInput(_ action: SkyPlayerInput?)
}

extension FallingSkyPresenting {
    func showBufferedInput(_ action: SkyPlayerInput?) {}
    func prepareOpening(_ game: FallingSky) { render(game) }
    func presentOpening(_ game: FallingSky, completion: @escaping () -> Void) {
        render(game); completion()
    }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 phaseBegan: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        for index in turn.resolutionPhases.indices { phaseBegan(index) }
        animate(turn, from: old, to: game, completion: completion)
    }
}

/// One cancellable deadline; no repeating timer or catch-up queue.
@MainActor protocol FallingSkyRainScheduling: AnyObject {
    var now: TimeInterval { get }
    func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void)
    func cancel()
}

@MainActor private final class FallingSkyRainClock: FallingSkyRainScheduling {
    private var task: Task<Void, Never>?
    var now: TimeInterval { ProcessInfo.processInfo.systemUptime }
    func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void) {
        cancel()
        task = Task {
            do { try await Task.sleep(for: .seconds(delay)) }
            catch { return }
            guard !Task.isCancelled else { return }
            action()
        }
    }
    func cancel() { task?.cancel(); task = nil }
    deinit { task?.cancel() }
}

/// Admission reasons shared by physical, button and accessibility input. Pausing
/// automatic showers deliberately leaves explicit actions available.
enum SkyInputAvailability: Equatable {
    case ready, suspended, gameOver, showerDue, emptySelection
    case settling(Set<Int>)
    var isReady: Bool { self == .ready }
}

struct SkyInputPolicy {
    let suspended: Bool
    let gameOver: Bool
    let showerDue: Bool
    let changingColumns: Set<Int>
    let presenting: Bool

    var receiving: SkyInputAvailability {
        if suspended { return .suspended }
        if gameOver { return .gameOver }
        if showerDue { return .showerDue }
        return .ready
    }
    var wholeBoard: SkyInputAvailability {
        guard receiving.isReady else { return receiving }
        return presenting ? .settling(changingColumns) : .ready
    }
    func reserving(_ columns: Set<Int>) -> SkyInputAvailability {
        guard receiving.isReady else { return receiving }
        let blocked = columns.intersection(changingColumns)
        return blocked.isEmpty ? .ready : .settling(blocked)
    }
}

/// Terminal speech has one presentation owner; explicit nonterminal feedback stays store-owned.
enum SkyTerminalSpeech { case feedback, ceremony }

// Existing persistence keys and launch arguments survive the production naming promotion.
@MainActor @Observable final class FallingSkyStore {
    private(set) var tutorial: SkyTutorialRun?
    let journey: WorldJourneyStore
    let mastery: StoryMasteryStore
    var terminalSpeech: SkyTerminalSpeech = .feedback
    static let saveKey = SkySaveArchive.key
    private(set) var game: FallingSky
    private(set) var hasSavedSky = false
    private let archiveWriter: @MainActor (FallingSky, UserDefaults) throws -> Void
    private(set) var persistenceNotice: SkyPersistenceNotice?
    private(set) var saveFailed = false
    private(set) var masterySaveFailed = false
    private var lastSavedGame: FallingSky?
    private(set) var rejectedSaveKey: String?
    private static let persistenceLog = Logger(subsystem: "com.starfall.prototype", category: "persistence")
    var busy: Bool { presentations.busy || openingPresenting }
    private(set) var openingPending = false
    private(set) var openingPresenting = false
    private var openingGeneration: UInt64 = 0
    private(set) var suspended = true
    private(set) var sceneReady = false
    private(set) var isPaused = true
    /// Interval/phase leading to the next shower, including while paused or overdue.
    private(set) var nextShowerCadence: SkyCadenceStep = .init(delay: 4, phase: .steady)
    let dialogue = SkyDialogueSession()
    private(set) var guideLine = SkyDialogueLibrary.line("guide.opening")
    var message: String { guideLine.text }
    var pausedGuideLine: SkyDialogueLine {
        if dialogue.visible, let line = dialogue.line { return line }
        return SkyDialogueLibrary.contextual(guideLine, game: game, cadence: nextShowerCadence)
    }

    private func guide(_ id: String, values: [String: String] = [:], visible: Bool = false) {
        guide(SkyDialogueLibrary.line(id, values: values), visible: visible)
    }

    private func guide(_ line: SkyDialogueLine, visible: Bool = false) {
        guideLine = line
        if visible {
            guideLine = SkyDialogueLibrary.contextual(guideLine, game: game, cadence: nextShowerCadence)
            dialogue.show(guideLine, interrupt: true)
        }
    }

    @discardableResult func say(_ script: SkyDialogueScript) -> Bool {
        guard !suspended, !game.isOver, dialogue.play(script) else { return false }
        if let line = dialogue.line { feedback.announce(line.spokenText) }
        return true
    }
    func nextDialogue() {
        guard !suspended, !game.isOver else { return }
        dialogue.next()
        if dialogue.visible, let line = dialogue.line { feedback.announce(line.spokenText) }
    }
    private let lightReceipts = SkyLightReceiptSession()
    var celebration: StarlightCelebration? { lightReceipts.current }
    var finalLight: SkyFinalLightReceipt? { lightReceipts.lastEarned }
    var finalSurvivorCount: Int { lightReceipts.lastSurvivorCount ?? 0 }
    var finalScoreExplanation: SkyScoreExplanation? { lightReceipts.lastScore }
    var lastClear: SkyLastClearSnapshot? { lightReceipts.lastClear }
    private(set) var techniqueResult = ""
    private var techniqueRelay = SkyTechniqueRelay()
    #if DEBUG
    private(set) var isTechniqueFixture = false
    #endif

    private(set) var constellationInputGeneration: UInt64 = 0
    private(set) var constellationTracing = false
    private var constellationHold: UInt64?
    private var constellationHoldSequence: UInt64 = 0
    @ObservationIgnored private var traceFeedbackCount = 0
    @ObservationIgnored private var traceReadySignaled = false
    private var inputQueue: [SkyBufferedInput] = []
    var bufferedInput: SkyBufferedInput? { inputQueue.first }
    var queuedInputCount: Int { inputQueue.count }
    var queuedInputs: [SkyPlayerInput] { inputQueue.map(\.action) }
    var queuedInputCapacity: Int { SkyBufferedInput.capacity }
    @ObservationIgnored private var queuedAdmissions = 0
    @ObservationIgnored private var dispatchingQueuedInput = false
    @ObservationIgnored private var bufferedInputSequence: UInt64 = 0

    /// Only the owner may release a live hold; late callbacks cannot resume a newer touch.
    @discardableResult func beginConstellationHold(at cell: Cell? = nil) -> UInt64? {
        guard game.supportsManualClears else { return nil }
        return beginContact(at: cell, allowingSettling: false)
    }
    @discardableResult func beginResponsiveContact(at cell: Cell?) -> UInt64? {
        beginContact(at: cell, allowingSettling: true)
    }
    private func beginContact(at cell: Cell?, allowingSettling: Bool) -> UInt64? {
        guard (allowingSettling ? canReceiveInput : (cell.map(canContact) ?? canClear)), constellationHold == nil else { return nil }
        constellationHoldSequence &+= 1
        constellationHold = constellationHoldSequence
        constellationTracing = true
        traceFeedbackCount = 0; traceReadySignaled = false
        freezeClock(for: .contact)
        // Contact freezes dispatch, while previous accepted commands retain
        // their FIFO order. Releasing this ticket may dispatch only the head.
        #if DEBUG
        observeTiming(.state)
        #endif
        return constellationHold
    }
    func endConstellationHold(_ ticket: UInt64?) {
        guard let ticket, constellationHold == ticket else { return }
        constellationHold = nil; constellationTracing = false
        traceFeedbackCount = 0; traceReadySignaled = false
        if !deliverBufferedInputIfReady() { armClock() }
        #if DEBUG
        observeTiming(.state)
        #endif
    }
    private var presentations = SkyPresentationLedger()
    private struct InputFeedback: Equatable {
        let text: String
        let waitingColumns: Set<Int>?
    }
    private var inputFeedback: InputFeedback?
    var inputMessage: String? { inputFeedback?.text }
    var pending: FallingSkyTurn? { presentations.pending }
    var changingColumns: Set<Int> {
        openingPending || openingPresenting ? Set(0..<FallingSky.side) : presentations.changingColumns
    }

    func showInputFeedback(_ text: String?) {
        inputFeedback = text.map { InputFeedback(text: $0, waitingColumns: nil) }
        if let text { dialogue.show(SkyDialogueLibrary.line("guide.input", values: ["detail": text]), interrupt: true) }
        else if dialogue.line?.id == "guide.input.1" { dialogue.reset() }
    }

    func explainInputFailure(_ text: String) {
        showInputFeedback(text)
        feedback.announce(text)
    }

    /// Selection cues share device/preference policy with committed feedback.
    func traceArmed() {
        guard canReceiveInput, constellationTracing else { return }
        feedback.traceArmed(enabled: hapticsEnabled && !presenter.reduceMotion)
    }

    func traceStep(path: [Cell], snapshot: FallingSky, generation: UInt64, holdTicket: UInt64?) {
        guard canReceiveInput, constellationTracing, let holdTicket, holdTicket == constellationHold,
              generation == constellationInputGeneration, snapshot == game,
              canTrace(path), game.isValidConstellationPrefix(path) else { return }
        let count = Set(path).count
        guard count > traceFeedbackCount else { return }
        let ready = game.constellationCells(along: path) != nil
        let becameReady = ready && !traceReadySignaled
        traceFeedbackCount = count
        traceReadySignaled = traceReadySignaled || ready
        feedback.traceStep(count: count, becameReady: becameReady,
                           enabled: hapticsEnabled && !presenter.reduceMotion)
    }

    /// A value snapshot cannot announce after its generation/hold was replaced.
    /// Delivery is synchronous; this boundary creates no delayed speech task.
    func announceTraceSelection(count: Int, value: Int, ready: Bool,
                                generation ticket: UInt64, holdTicket: UInt64?) {
        guard canReceiveInput, ticket == constellationInputGeneration,
              holdTicket == constellationHold, count == 0 || holdTicket != nil else { return }
        let message = count > 0
            ? SkyCopy.text(.inputTraceAnnouncement, values: ["count": String(count), "score": value.formatted(), "status": SkyCopy.text(ready ? .inputTraceReleaseReady : game.supportsArrangingStars ? .inputTraceShort : .inputTraceChallengeShort)])
            : SkyCopy.text(.inputTraceCanceled)
        feedback.announce(message)
    }

    func explainSettling(at cell: Cell) { explainAvailability(clearAvailability(cell)) }

    private func explainAvailability(_ availability: SkyInputAvailability) {
        switch availability {
        case .settling(let columns):
            showInputFeedback(SkyCopy.text(.statusSettling))
            inputFeedback = InputFeedback(text: SkyCopy.text(.statusSettling), waitingColumns: columns)
            feedback.announce(SkyCopy.text(.statusSettling))
        case .showerDue: explainInputFailure(SkyCopy.text(.inputShowerDue))
        case .suspended, .gameOver, .emptySelection, .ready: break
        }
    }
    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled"); if !soundEnabled { feedback.stopSounds() } }
    }
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: "starfall.haptics") }
    }
    let scene: FallingSkyScene
    @ObservationIgnored private let feedback: any FallingSkyFeedbackProviding
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let presenter: any FallingSkyPresenting
    @ObservationIgnored private let clock: any FallingSkyRainScheduling
    @ObservationIgnored private var rainGeneration: UInt64 = 0
    private var deadline: TimeInterval?
    private var remaining: TimeInterval = 0
    private var rainDue = false
    #if DEBUG
    @ObservationIgnored private var timingLookup: ((FallingSky) -> SkyCadenceStep)?
    @ObservationIgnored private var timingObserver: ((TimingEvent) -> Void)?

    struct TimingSnapshot {
        let time: TimeInterval
        let game: FallingSky
        let cadence: SkyCadenceStep
        let scheduledDeadline: TimeInterval?
        let rainDue: Bool
        let busy: Bool
        let paused: Bool
        let suspended: Bool
        let canClear: Bool
        let canTap: Bool
        /// Legal ordinary groups admitted now; excludes traces and invalid explanatory taps.
        let admittedTapGroups: Int
        let canCallShower: Bool
        let inputGeneration: UInt64
    }
    enum TimingEventKind: Equatable {
        case scheduled, due, deferred, cancelled, automaticShower, manualShower, tapAccepted, traceAccepted
        case invalidated(String), state
    }
    struct TimingEvent {
        let kind: TimingEventKind
        let snapshot: TimingSnapshot
        let showerDeadline: TimeInterval?
    }
    var timingSnapshot: TimingSnapshot {
        .init(time: clock.now, game: game, cadence: nextShowerCadence,
              scheduledDeadline: deadline, rainDue: rainDue, busy: busy,
              paused: isPaused, suspended: suspended, canClear: canClear,
              canTap: canClear && !constellationTracing,
              admittedTapGroups: constellationTracing || !game.supportsManualClears ? 0 : game.legalGroups.filter { group in
                  group.first.map(canClear) ?? false
              }.count,
              canCallShower: !constellationTracing && !busy && !suspended && !game.isOver,
              inputGeneration: constellationInputGeneration)
    }
    /// One test-only entry, before activation. Lookup/observer must be pure/non-reentrant.
    func configureTimingTest(lookup: ((FallingSky) -> SkyCadenceStep)? = nil,
                             observe: ((TimingEvent) -> Void)? = nil) {
        precondition(suspended && isPaused && deadline == nil && (lookup == nil || game.turns == 0))
        timingLookup = lookup; timingObserver = observe
        refreshCadence(); remaining = showerInterval
    }
    private func observeTiming(_ kind: TimingEventKind, showerDeadline: TimeInterval? = nil) {
        let sourceDeadline: TimeInterval?
        switch kind {
        case .automaticShower, .manualShower: sourceDeadline = showerDeadline
        default: sourceDeadline = deadline
        }
        timingObserver?(.init(kind: kind, snapshot: timingSnapshot, showerDeadline: sourceDeadline))
    }
    #endif

    private func refreshCadence() {
        #if DEBUG
        nextShowerCadence = (game.hasOpeningCascade && game.challenge == nil ? timingLookup?(game) : nil) ?? game.cadenceStep
        #else
        nextShowerCadence = game.cadenceStep
        #endif
    }
    private func invalidateInput(_ reason: String) {
        if reason != "clear" || !dispatchingQueuedInput { cancelBufferedInput() }
        endConstellationHold(constellationHold)
        if inputQueue.isEmpty { showInputFeedback(nil) }
        constellationInputGeneration &+= 1
        #if DEBUG
        observeTiming(.invalidated(reason))
        #endif
        if reason != "clear" { techniqueRelay.reset(); techniqueResult = "" }
    }

    init(defaults: UserDefaults = .standard,
         arguments: [String] = ProcessInfo.processInfo.arguments,
         presenter: (any FallingSkyPresenting)? = nil,
         clock: (any FallingSkyRainScheduling)? = nil,
         feedback: (any FallingSkyFeedbackProviding)? = nil,
         tutorial: SkyTutorial? = nil,
         archiveWriter: @escaping @MainActor (FallingSky, UserDefaults) throws -> Void = SkySaveArchive.save,
         masteryWriter: @escaping @MainActor (Data, UserDefaults) throws -> Void = StoryMasteryStore.write) {
        self.defaults = defaults
        journey = WorldJourneyStore(defaults: defaults, ignoreSaved: tutorial != nil || arguments.contains("--starfalls-reset"))
        mastery = StoryMasteryStore(defaults: defaults, ignoreSaved: tutorial != nil || arguments.contains("--starfalls-reset"),
                                    writer: masteryWriter)
        self.tutorial = tutorial.map(SkyTutorialRun.init)
        self.archiveWriter = archiveWriter
        self.feedback = feedback ?? GameFeedback()
        soundEnabled = defaults.object(forKey: "soundEnabled") == nil ? true : defaults.bool(forKey: "soundEnabled")
        hapticsEnabled = defaults.object(forKey: "starfall.haptics") == nil ? true : defaults.bool(forKey: "starfall.haptics")
        self.clock = clock ?? FallingSkyRainClock()
        let scene = FallingSkyScene()
        self.scene = scene
        self.presenter = presenter ?? scene
        // SwiftUI may construct stores for discarded view values. Keep initialization read-only.
        if tutorial == nil, !arguments.contains("--starfalls-reset"), case .loaded(let saved) = SkySaveArchive.inspect(from: defaults) {
            game = saved.removingGravity().adoptingFeedingDusk().disablingAutomaticAging().adoptingCurrentChallengeActions()
            hasSavedSky = true
            lastSavedGame = game
            guide(saved.outcome == .won ? (saved.challenge?.wonGuideID ?? "guide.won") : saved.isOver ? "guide.full"
                : saved.fullBoardRestoreGuideID ?? "guide.restore",
                values: saved.isOver ? ["score": saved.displayScore.formatted()] : [:],
                visible: saved.usesFullBoardRefill && !saved.isOver)
        } else {
            let argument = arguments.first { $0.hasPrefix("--starfalls-seed=") }
            let seed = argument.flatMap { UInt64($0.dropFirst("--starfalls-seed=".count)) } ?? 5
            game = FallingSky.freshSurvival(seed: seed)
            if tutorial == nil, !arguments.contains("--starfalls-reset"), case .rejected(let key) = SkySaveArchive.inspect(from: defaults) {
                rejectedSaveKey = key
                persistenceNotice = .rejected
                Self.persistenceLog.error("Rejected sky archive; preserving it before the next committed save")
            }
        }
        #if DEBUG
        if let retained = ObservatoryReviewFixture.fullBoardV5(arguments: arguments) {
            game = retained
        }
        if arguments.contains("--starfalls-reset"), arguments.contains("--dialogue-review"), arguments.contains("--world-legacy-review") {
            journey.useLegacyReviewAccess()
        }
        if arguments.contains("--starfalls-reset"), arguments.contains("--observatory-review") {
            let reviewScore = arguments.first { $0.hasPrefix("--night-score=") }.flatMap { Int($0.dropFirst("--night-score=".count)) } ?? 0
            game = ObservatoryReviewFixture.game(dense: arguments.contains("--observatory-dense"), score: min(2_000_000_000,max(0,reviewScore))).adoptingFeedingDusk()
        }
        // Explicit reset plus the existing isolated review suite prevents this
        // deterministic art/interaction sample from replacing a player's save.
        let requestedReviews = StarfallChallenge.allCases.flatMap { challenge in
            let prefix = challenge.restorationReviewArgumentPrefix
            return arguments.filter { $0.hasPrefix(prefix) }.map { (challenge, String($0.dropFirst(prefix.count))) }
        }
        if arguments.contains("--starfalls-reset"), arguments.contains("--dialogue-review"), requestedReviews.count == 1,
           let (challenge, value) = requestedReviews.first, let score = Int(value),
           (0...challenge.target).contains(score) {
            game = ObservatoryReviewFixture.game(dense: arguments.contains("--restoration-dense"), score: score, challenge: challenge)
            if arguments.contains("--world-silver-complete-review") {
                journey.useReviewCompletion(ObservatoryReviewFixture.game(dense: false, score: 18, challenge: .silverPools))
            }
            if arguments.contains("--world-frostfruit-complete-review") {
                journey.useReviewCompletion(ObservatoryReviewFixture.game(dense: false, score: 18, challenge: .frostfruitOrchard))
            }
        }
        #endif
        #if DEBUG
        if arguments.contains("--starfalls-reset"), let name = arguments.first(where: { $0.hasPrefix("--constellation-fixture=") }),
           let fixture = ConstellationFixture(rawValue: String(name.dropFirst("--constellation-fixture=".count))) {
            game = fixture.game().adoptingFeedingDusk()
            guide("guide.fixture", values: ["detail": fixture.title + ". Draw through matching stars."])
        }
        #endif
        #if DEBUG
        if arguments.contains("--starfalls-reset"), arguments.contains("--technique-review"),
           let name = arguments.first(where: { $0.hasPrefix("--technique-example=") }),
           let example = SkyTechniqueExample(rawValue:String(name.dropFirst("--technique-example=".count))) {
            game = example.game(); isTechniqueFixture = true
            guide("guide.fixture",values:["detail":example.title + " review board. Swipe to move, or hold then draw a recipe."])
        }
        #endif
        refreshCadence()
        #if DEBUG
        if arguments.contains("--starfalls-reset"), let name = arguments.first(where: { $0.hasPrefix("--gravity-fixture=") }),
           let fixture = GravityFixture(rawValue: String(name.dropFirst("--gravity-fixture=".count))) {
            game = fixture.game().adoptingFeedingDusk(); guide("guide.fixture", values: ["detail": fixture.message])
        }
        #endif
        #if DEBUG
        if arguments.contains("--starfalls-reset"), let name = arguments.first(where: { $0.hasPrefix("--dusk-fixture=") }),
           let fixture = DuskFixture(rawValue: String(name.dropFirst("--dusk-fixture=".count))) {
            game = fixture.game(rule: .patientFeeding)
            guide("guide.dusk-arrival")
        }
        #endif
        #if DEBUG
        if arguments.contains("--starfalls-reset"), arguments.contains("--critical-mass-review") {
            game = CriticalMassFixture.game()
        }
        #endif
        if let tutorial { game = tutorial.game(); persistenceNotice = nil; hasSavedSky = false }
        refreshCadence()
        remaining = showerInterval
        scene.decorativeMotionActive = !suspended
        scene.onLayout = { [weak self] in
            self?.settleInterruptedPresentation(reason: "presentation")
        }
        scene.onReadinessChanged = { [weak self] ready in
            guard let self else { return }
            self.sceneReady = ready
            // Detachment must reject a due clock callback before SwiftUI observes
            // readiness on its next update. Re-admission remains view-owned.
            if !ready { self.setSuspended(true) }
        }
    }

    var phaseCue: SkyPhaseCue? { SkyPhaseCue(game: game, pending: pending) }
    var pressureCue: SkyPressureCue? { game.usesFullBoardRefill ? nil : SkyPressureCue(game: game) }
    var forecast: [IncomingStar] { game.usesFullBoardRefill ? [] : pending?.forecast ?? game.incoming }
    var showerInterval: TimeInterval { nextShowerCadence.delay }
    /// The renderer samples the scheduler's monotonic clock and frozen remainder.
    /// It cannot schedule, resume or commit rain through this value boundary.
    var showerCountdown: SkyShowerCountdown {
        .init(remaining: rainDue ? 0 : max(0, deadline.map { $0 - clock.now } ?? remaining),
              interval: showerInterval, advancing: deadline != nil && !rainDue,
              paused: isPaused || suspended || game.isOver,
              arriving: pending?.arrivals.isEmpty == false || rainDue)
    }
    var inputPolicy: SkyInputPolicy {
        .init(suspended: suspended || openingPending || openingPresenting, gameOver: game.isOver, showerDue: rainDue,
              changingColumns: changingColumns, presenting: busy)
    }
    var canClear: Bool { game.supportsManualClears && inputPolicy.wholeBoard.isReady }
    var canReceiveInput: Bool { inputPolicy.receiving.isReady }
    func canContact(_ cell: Cell) -> Bool { inputPolicy.reserving([cell.column]).isReady }

    func clearAvailability(_ cell: Cell) -> SkyInputAvailability {
        let contact = inputPolicy.reserving([cell.column])
        guard contact.isReady else { return contact }
        // No outstanding presentation can reserve a column. Legality still belongs
        // to the real commit; invalid taps retain their explanatory feedback.
        guard busy else { return .ready }
        var preview = game
        // Invalid input still reaches the rule explanation; admission owns only timing.
        let columns = preview.clear(cell)?.changingColumns ?? [cell.column]
        return inputPolicy.reserving(columns)
    }
    func canClear(_ cell: Cell) -> Bool { game.supportsManualClears && clearAvailability(cell).isReady }

    func traceAvailability(_ path: [Cell]) -> SkyInputAvailability {
        guard inputPolicy.receiving.isReady else { return inputPolicy.receiving }
        guard !path.isEmpty else { return .emptySelection }
        guard busy else { return .ready }
        var preview = game
        let columns = preview.clearConstellation(path)?.changingColumns ?? Set(path.map(\.column))
        return inputPolicy.reserving(columns)
    }
    func canTrace(_ path: [Cell]) -> Bool { game.supportsManualClears && traceAvailability(path).isReady }

    /// A contact names a visible, stationary identity. Never use the final
    /// occupant of a cell while another star is visibly departing from it.
    func inputSnapshot(at cell: Cell) -> FallingSky? {
        guard canReceiveInput, let id = game.gem(at: cell)?.id,
              presentations.preservesInputIdentity(at: cell, id: id) else { return nil }
        let projected = inputQueue.last?.projectedGame ?? game
        guard projected.gem(at: cell)?.id == id, !projected.isOver else { return nil }
        return game
    }
    func canQueueInput(at cell: Cell) -> Bool { inputSnapshot(at: cell) != nil }

    /// Physical and accessibility requests plan against the FIFO tail. Only
    /// independent visible endpoints are accepted; no source follows a moved ID
    /// to a different cell and no destination is silently reinterpreted.
    @discardableResult func requestTap(_ cell: Cell) -> Bool {
        requestInput(.tap(cell), snapshot: game, generation: constellationInputGeneration)
    }

    @discardableResult func requestInput(_ action: SkyPlayerInput, snapshot: FallingSky, generation: UInt64) -> Bool {
        guard snapshot == game, generation == constellationInputGeneration, canReceiveInput else { return false }
        let projected = inputQueue.last?.projectedGame ?? game
        guard let sourceID = game.gem(at: action.source)?.id,
              presentations.preservesInputIdentity(at: action.source, id: sourceID) else {
            explainSettling(at: action.source); return false
        }
        guard projected.gem(at: action.source)?.id == sourceID else {
            explainInputFailure(SkyCopy.text(.inputQueueChanged)); return false
        }
        if let destination = action.destination {
            let visibleID = game.gem(at: destination)?.id
            guard visibleID == projected.gem(at: destination)?.id else {
                explainInputFailure(SkyCopy.text(.inputQueueChanged)); return false
            }
            guard visibleID.map({ presentations.preservesInputIdentity(at: destination, id: $0) })
                    ?? !changingColumns.contains(destination.column) else {
                explainSettling(at: destination); return false
            }
        }
        guard let turn = action.preview(in: projected) else {
            if case .tap(let cell) = action, inputQueue.isEmpty { inspectStar(cell) }
            return false
        }
        var heldTap = false
        if case .tap = action { heldTap = constellationTracing }
        if !busy && inputQueue.isEmpty && !heldTap {
            queuedAdmissions = 0
            return executeInput(action)
        }
        guard queuedAdmissions < SkyBufferedInput.capacity, inputQueue.count < SkyBufferedInput.capacity else {
            explainInputFailure(SkyCopy.text(.inputQueueFull)); return false
        }
        guard !projected.isOver else { return false }
        // A manual tap names its actual group too, rather than collecting a
        // different projected neighborhood after an earlier queued clear.
        if case .tap = action {
            guard let visible = action.preview(in: game),
                  Set(visible.cleared.compactMap { game.gem(at: $0)?.id })
                    == Set(turn.cleared.compactMap { projected.gem(at: $0)?.id }) else { return false }
            guard visible.cleared.allSatisfy({ cell in
                guard let id = game.gem(at: cell)?.id else { return false }
                return presentations.preservesInputIdentity(at: cell, id: id)
            }) else {
                explainInputFailure(SkyCopy.text(.inputQueueChanged)); return false
            }
        }
        bufferedInputSequence &+= 1
        guard let pending = SkyBufferedInput(ticket: bufferedInputSequence, action: action, game: projected) else { return false }
        inputQueue.append(pending)
        queuedAdmissions += 1
        freezeClock(for: .contact)
        presenter.showBufferedInput(inputQueue.first?.action)
        showInputFeedback(SkyCopy.text(.inputBuffered))
        feedback.announce(SkyCopy.text(.inputBuffered))
        return true
    }

    private func executeInput(_ action: SkyPlayerInput) -> Bool {
        switch action {
        case .tap(let cell):
            guard !constellationTracing, canClear(cell) else { return false }
            let before = game; clear(cell); return game != before
        case .swap(let from, let to):
            return performTechnique(.nudge(from, to), snapshot: game, generation: constellationInputGeneration)
        }
    }

    /// Lifecycle cancellation retires every uncommitted command. A contact or
    /// ordinary command completion never calls this replacement boundary.
    func cancelBufferedInput() {
        let hadQueue = !inputQueue.isEmpty
        inputQueue.removeAll()
        queuedAdmissions = 0
        presenter.showBufferedInput(nil)
        if hadQueue {
            showInputFeedback(nil)
            armClock()
        }
    }

    @discardableResult private func deliverBufferedInputIfReady() -> Bool {
        guard !busy, !constellationTracing, let pending = inputQueue.first else { return false }
        guard canReceiveInput, pending.matches(game),
              let turn = pending.action.preview(in: game),
              inputPolicy.reserving(turn.changingColumns).isReady else {
            cancelBufferedInput(); return false
        }
        // Retire the head before committing. Ordinary present invalidation keeps
        // the remaining exact projected states; lifecycle invalidation clears all.
        inputQueue.removeFirst()
        presenter.showBufferedInput(inputQueue.first?.action)
        dispatchingQueuedInput = true
        defer { dispatchingQueuedInput = false }
        return executeInput(pending.action)
    }

    func clear(_ cell: Cell) {
        guard canReceiveInput, !constellationTracing else { return }
        if !game.supportsManualClears {
            guard canContact(cell) else { explainSettling(at: cell); return }
            inspectStar(cell)
            return
        }
        guard canClear(cell) else { explainSettling(at: cell); return }
        showInputFeedback(nil)
        let old = game
        guard let turn = game.clear(cell) else {
            inspectStar(cell)
            return
        }
        #if DEBUG
        observeTiming(.tapAccepted)
        #endif
        if game.isOver { freezeClock() }
        present(turn, from: old)
    }

    /// Inspection has no commit capability and can answer an invalid tap while
    /// its physical contact still owns release and queued dispatch.
    private func inspectStar(_ cell: Cell) {
        if !game.supportsManualClears {
            let inspection = SkyDialogueLibrary.ingredientInspection(at: cell, game: game)
                ?? SkyDialogueLibrary.line("guide.patterns-inspect", values: game.automaticPatternValues)
            guide(inspection, visible: true)
        } else {
            let gem = game.gem(at: cell)
            let id = gem?.gravityKind == .hole ? "guide.hole-help"
                : gem?.gravityKind == .magnet ? "guide.magnet-help"
                : gem?.isDark == true ? (game.duskRule != .legacy ? "guide.dusk-help" : "guide.dark-help")
                : gem?.isLight == true ? "guide.opal-help" : "guide.match-help"
            guide(id, values: id == "guide.dusk-help" ? ["feeds": String(game.duskRule.feedingShowers)] : [:], visible: true)
        }
        feedback.announce(guideLine.spokenText)
    }

    func clearTracedConstellation(_ path: [Cell], snapshot: FallingSky, generation ticket: UInt64) {
        guard !suspended, !game.isOver, game == snapshot, ticket == constellationInputGeneration else { return }
        guard canTrace(path) else {
            explainAvailability(traceAvailability(path))
            return
        }
        let old = game
        guard let turn = game.clearConstellation(path) else { return }
        #if DEBUG
        observeTiming(.traceAccepted)
        #endif
        if game.isOver { freezeClock() }
        present(turn, from: old, path: path)
    }

    /// New actions share current column ownership, hold tickets and committed presentation.
    private func readyTechnique(_ action: SkyBoardAction) -> (FallingSky, FallingSkyTurn)? {
        guard canReceiveInput, game.canArrangeStars else { return nil }
        var next = game
        let turn: FallingSkyTurn?
        switch action {
        case .recipe(let recipe): turn = next.activate(recipe)
        case .nudge(let from,let to): turn = next.nudge(from:from,to:to)
        }
        guard let turn, inputPolicy.reserving(turn.changingColumns).isReady else { return nil }
        return (next,turn)
    }
    func canPerformTechnique(_ action: SkyBoardAction) -> Bool { readyTechnique(action) != nil }

    @discardableResult func performTechnique(_ action: SkyBoardAction, snapshot: FallingSky, generation ticket: UInt64) -> Bool {
        guard snapshot == game, ticket == constellationInputGeneration,
              let (next,turn) = readyTechnique(action) else { return false }
        let old = game
        game = next
        if game.isOver { freezeClock() }
        if case .recipe(let recipe) = action { present(turn, from: old, recipe: recipe) }
        else { present(turn, from: old) }
        return true
    }

    private func celebrate(_ turn: FallingSkyTurn, from old: FallingSky, path: [Cell], recipe: StarRecipe?) {
        guard turn.collected > 0 else { cancelCelebration(); return }
        cancelCelebration()
        guard let receipt = StarlightCelebration(id: lightReceipts.nextSequence(), turn: turn, from: old,
            total: game.displayScore, path: path, recipe: recipe, relayDepth: techniqueRelay.depth) else { return }
        publishCelebration(receipt)
    }

    private func celebratePhase(_ index: Int, turn: FallingSkyTurn, oldScore: Int) {
        guard turn.resolutionPhases.indices.contains(index) else { return }
        cancelCelebration()
        let cumulative = turn.resolutionPhases.prefix(index + 1).reduce(0) { $0 + $1.award.displayPoints }
        let receipt = StarlightCelebration(id: lightReceipts.nextSequence(), phase: turn.resolutionPhases[index],
            cumulativeAward: cumulative, total: oldScore + cumulative,
            precedingPhases: Array(turn.resolutionPhases.prefix(index)))
        publishCelebration(receipt)
    }

    private func publishCelebration(_ receipt: StarlightCelebration) {
        lightReceipts.publish(receipt)
        feedback.collected(receipt.level, soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled,
                           reducedMotion: presenter.reduceMotion)
    }

    func cancelCelebration() {
        lightReceipts.cancel()
    }


    /// Explicit input works while paused too, without starting an automatic clock.
    func callShower() {
        #if DEBUG
        guard !isTechniqueFixture else { return }
        #endif
        guard !game.usesFullBoardRefill, !constellationTracing, !busy, !suspended, !game.isOver else { return }
        freezeClock()
        remaining = showerInterval
        commitShower(announcesResult: true)
    }

    func togglePause() {
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        invalidateInput("pause")
        guard !game.usesFullBoardRefill, !suspended, !game.isOver else { return }
        let before = game
        isPaused.toggle()
        self.tutorial?.observe(isPaused ? .pause : .resume, before: before, after: game)
        if isPaused {
            interruptPlay(reason: "pause")
            dialogue.reset(); guide("guide.paused")
        } else {
            dialogue.reset()
            if !game.supportsManualClears, let line = game.challengeGuideLine { guideLine = line }
            else { guide("guide.started") }
            dialogue.show(pausedGuideLine)
            armClock()
        }
    }

    private func armClock() {
        guard !game.usesFullBoardRefill else { return }
        if let tutorial {
            guard tutorial.chapter.allowsClock, !tutorial.complete, !tutorial.needsRetry,
                  tutorial.next != .pause else { return }
        }
        #if DEBUG
        guard !isTechniqueFixture else { return }
        #endif
        guard !openingPending, !openingPresenting, !constellationTracing, bufferedInput == nil,
              !isPaused, !suspended, !game.isOver, deadline == nil, !rainDue else { return }
        rainGeneration &+= 1
        let ticket = rainGeneration
        deadline = clock.now + remaining
        #if DEBUG
        observeTiming(.scheduled)
        #endif
        clock.schedule(after: remaining) { [weak self] in
            guard let self, self.rainGeneration == ticket, !self.isPaused, !self.suspended, !self.game.isOver else { return }
            #if DEBUG
            self.observeTiming(.due)
            #endif
            self.rainDue = true
            #if DEBUG
            if self.busy { self.observeTiming(.deferred) }
            #endif
            self.deliverRainIfReady()
        }
    }

    private enum ClockFreezeReason { case contact, interruption }

    private func freezeClock(for reason: ClockFreezeReason = .interruption) {
        #if DEBUG
        if deadline != nil || rainDue { observeTiming(.cancelled) }
        #endif
        let minimumRemaining: TimeInterval = reason == .contact ? 0 : 0.5
        if rainDue { remaining = minimumRemaining }
        else if let deadline {
            remaining = min(showerInterval, max(minimumRemaining, deadline - clock.now))
        } else {
            // A background/pause interruption can arrive while contact already owns
            // the frozen clock. Apply that interruption's policy to the held remainder.
            remaining = min(showerInterval, max(minimumRemaining, remaining))
        }
        rainGeneration &+= 1
        clock.cancel()
        deadline = nil; rainDue = false
    }

    private func deliverRainIfReady() {
        guard !game.usesFullBoardRefill, rainDue, !busy, !constellationTracing, bufferedInput == nil, !suspended, !isPaused, !game.isOver else { return }
        let dueDeadline = deadline
        rainDue = false
        deadline = nil
        commitShower(announcesResult: false, scheduledDeadline: dueDeadline)
    }

    private func commitShower(announcesResult: Bool, scheduledDeadline: TimeInterval? = nil) {
        guard !game.usesFullBoardRefill else { return }
        let old = game
        let previousCadence = nextShowerCadence
        guard let turn = game.letStarsFall() else { return }
        refreshCadence()
        if game.isOver { freezeClock() }
        else { remaining = showerInterval; armClock() }
        #if DEBUG
        observeTiming(announcesResult ? .manualShower : .automaticShower, showerDeadline: scheduledDeadline)
        #endif
        present(turn, from: old, announcesResult: announcesResult, previousCadence: previousCadence)
    }

    private func present(_ turn: FallingSkyTurn, from old: FallingSky, announcesResult: Bool = true, previousCadence: SkyCadenceStep? = nil, path: [Cell] = [], recipe: StarRecipe? = nil) {
        let isShower = !turn.arrivals.isEmpty || turn.blockedColumn != nil
        if tutorial != nil {
            let action: SkyTutorial.Action
            if let exchange = turn.exchange { action = .swap(exchange.from, exchange.to) }
            else if isShower { action = announcesResult ? .shower : .automaticShower }
            else if !path.isEmpty { action = .trace(path) }
            else if let recipe { action = .trace(SkyTutorial.walk(recipe)) }
            else { action = .tap(turn.cleared.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }.first ?? Cell(0,0)) }
            tutorial?.observe(action, before: old, after: game)
            if tutorial?.complete == true || tutorial?.needsRetry == true || tutorial?.next == .pause { freezeClock() }
        }
        // The exact committed selection names its achievement, independent of
        // whether it arrived through a tap, held trace or accessible action.
        // Neighboring Dusk removals are consequences, not recipe ingredients.
        let selected = path.isEmpty ? turn.cleared.filter { old.gem(at: $0)?.isDark == false } : Set(path)
        let resolvedRecipe = recipe ?? (old.canArrangeStars
            ? old.recipe(matching: selected) : nil)
        lightReceipts.capture(turn, from: old, to: game, path: path, recipe: resolvedRecipe)
        invalidateInput(isShower ? (announcesResult ? "manualShower" : "automaticShower") : "clear")
        if turn.exchange != nil {
            techniqueRelay.reset()
            techniqueResult = SkyCopy.text(old.board == game.board ? .techniqueSettledBack : .techniqueMoved)
        } else if !turn.cleared.isEmpty {
            techniqueRelay.record(before:old,after:game,cleared:turn.cleared)
            techniqueResult = techniqueRelay.depth > 1 ? SkyCopy.text(.techniqueRelay, values: ["count": String(techniqueRelay.depth)]) : SkyCopy.text(.techniqueSupport)
        }
        if turn.resolutionPhases.isEmpty { celebrate(turn, from: old, path: path, recipe: resolvedRecipe) }
        else if presenter.reduceMotion {
            celebratePhase(turn.resolutionPhases.count - 1, turn: turn, oldScore: old.displayScore)
        } else { cancelCelebration() }
        let ticket = presentations.begin(turn, from: old, to: game)
        if game.isOver { cancelBufferedInput() }
        guideLine = SkyDialogueLibrary.result(for: turn, from: old, to: game,
            tracedCount: Set(path).count, recipe: resolvedRecipe, relayDepth: techniqueRelay.depth,
            techniqueResult: techniqueResult)
        // The committed phase/cadence has one visible and spoken owner. No queued notices.
        let transition = SkyDialogueLibrary.transition(from: old, to: game,
                                                       previousCadence: previousCadence, cadence: nextShowerCadence)
        let announcesTransition = SkyDialogueLibrary.announcesTransition(from: old, to: game,
            previousCadence: previousCadence, cadence: nextShowerCadence)
        let resultLine = SkyDialogueLibrary.contextual(guideLine, game: game, cadence: nextShowerCadence)
        let spokenResult: SkyDialogueLine? = transition.map {
            SkyDialogueLibrary.contextual($0, game: game, cadence: nextShowerCadence, includeTiming: false)
        } ?? (announcesResult || game.isOver || (DuskWarning(game: game) != nil || CriticalMassPresentation.warning(game: game) != nil) ? resultLine : nil)
        save() // Commit before animation: backgrounding cannot replay arrivals.
        let publishesImmediately = !isShower && announcesResult && !game.isOver
        if publishesImmediately, let spokenResult {
            publishResult(spokenResult, interrupt: true, announces: true)
        }
        let dialogueRevision = dialogue.revision
        var presentedPhase = presenter.reduceMotion
        var latestPhase = -1
        presenter.animate(turn, from: old, to: game, phaseBegan: { [weak self] index in
            guard let self, self.presentations.isActive(ticket), self.presentations.isLatest(ticket),
                  !self.suspended, !self.presenter.reduceMotion,
                  turn.resolutionPhases.indices.contains(index), index > latestPhase else { return }
            latestPhase = index
            presentedPhase = true
            self.celebratePhase(index, turn: turn, oldScore: old.displayScore)
        }) { [weak self] in
            guard let self, self.presentations.complete(ticket) else { return }
            // The scene also honors system Reduce Motion/VoiceOver and may be
            // detached. A quiet completion gets exactly one aggregate receipt.
            if !presentedPhase, !turn.resolutionPhases.isEmpty,
               self.presentations.isLatest(ticket), !self.suspended {
                self.celebratePhase(turn.resolutionPhases.count - 1, turn: turn, oldScore: old.displayScore)
            }
            if let columns = self.inputFeedback?.waitingColumns, columns.isDisjoint(with: self.changingColumns) {
                self.showInputFeedback(nil)
            }
            if self.deliverBufferedInputIfReady() { return }
            if !self.busy && self.inputQueue.isEmpty {
                self.queuedAdmissions = 0
                self.presenter.showBufferedInput(nil)
                self.armClock()
            }
            // Completion order cannot give an older automatic result ownership of current feedback.
            if !publishesImmediately, self.inputFeedback == nil, let spokenResult,
               self.dialogue.revision == dialogueRevision, self.presentations.isLatest(ticket),
               !self.game.isOver || self.terminalSpeech == .feedback {
                self.publishResult(spokenResult, interrupt: announcesResult,
                                   announces: announcesResult || self.game.isOver || announcesTransition)
            }
            self.deliverRainIfReady()
            #if DEBUG
            self.observeTiming(.state)
            #endif
        }
        #if DEBUG
        observeTiming(.state)
        #endif
    }

    private func publishResult(_ line: SkyDialogueLine, interrupt: Bool, announces: Bool) {
        if dialogue.show(line, interrupt: interrupt), announces { feedback.announce(line.spokenText) }
    }

    /// Called only after Entry has consumed its pending choice. The round remains
    /// suspended until the view admits play; existing reset/save ownership stays here.
    @discardableResult func beginEntry(_ request: SkyEntryRequest) -> Bool {
        guard request == .initial || canReplaceMasteryReceipt() else { return false }
        switch request {
        case .initial: break // Keep the established first-launch seed and preview.
        case .fresh: restart(sameSky: false)
        case .replay: restart(sameSky: true)
        case .firstLight, .fullBoardLantern:
            var fresh = request == .firstLight ? FallingSky.freshChallenge(.firstLight) : FallingSky.fullBoardLantern()
            _ = fresh.enrollMastery(runID: UUID())
            beginChallenge(fresh)
        case .ribbonCrossing: startChallenge(.ribbonCrossing)
        case .fullBoardRibbon: startFullBoardRibbon()
        case .kiteHarbor: startChallenge(.kiteHarbor)
        case .seedMoon: startChallenge(.seedMoon)
        case .silverPools: startChallenge(.silverPools)
        case .frostfruitOrchard: startChallenge(.frostfruitOrchard)
        case .sunwheelMill: startChallenge(.sunwheelMill)
        }
        return true
    }

    func restart(sameSky: Bool) {
        guard canReplaceMasteryReceipt() else { return }
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        isPaused = true
        interruptPlay(reason: "restart")
        lightReceipts.beginRound()
        #if DEBUG
        let replayAllowed = !isTechniqueFixture && sameSky
        isTechniqueFixture = false
        #else
        let replayAllowed = sameSky
        #endif
        if replayAllowed {
            game = game.removingGravity().adoptingFeedingDusk().disablingAutomaticAging().adoptingCurrentChallengeActions().replay(masteryRunID: UUID())
        } else {
            // First Light's fixed balance belongs to that challenge, not the next normal sky.
            let balance = game.challenge == nil ? game.balance : StarfallBalance()
            game = FallingSky.freshSurvival(seed: UInt64.random(in: 0...UInt64.max), balance: balance)
        }
        refreshCadence()
        remaining = showerInterval
        dialogue.reset()
        if game.usesFullBoardRefill, let line = game.challengeGuideLine {
            guideLine = line; dialogue.show(line)
        }
        else { guide(sameSky ? "guide.replay" : "guide.new") }
        prepareRoundOpening()
    }

    #if DEBUG
    func loadConstellationFixture(_ fixture: ConstellationFixture) {
        isPaused = true
        interruptPlay(reason: "fixture")
        lightReceipts.beginRound()
        game = fixture.game().adoptingFeedingDusk()
        refreshCadence()
        remaining = showerInterval
        guide("guide.fixture", values: ["detail": fixture.title + ". Draw through matching stars."])
        save(); presenter.render(game)
    }

    #endif

    #if DEBUG
    func loadGravityFixture(_ fixture: GravityFixture) {
        isPaused = true
        interruptPlay(reason: "presentation")
        lightReceipts.beginRound()
        game = fixture.game().adoptingFeedingDusk(); refreshCadence(); remaining = showerInterval
        guide("guide.fixture", values: ["detail": fixture.message])
        save(); presenter.render(game)
    }

    #endif

    func startFirstLight() { startChallenge(.firstLight) }
    func startFullBoardLantern() { beginChallenge(FallingSky.fullBoardLantern()) }
    func startFullBoardRibbon() { beginChallenge(FallingSky.fullBoardRibbon()) }

    func startChallenge(_ challenge: StarfallChallenge) {
        beginChallenge(FallingSky.freshChallenge(challenge))
    }

    private func beginChallenge(_ fresh: FallingSky) {
        guard canReplaceMasteryReceipt() else { return }
        #if DEBUG
        isTechniqueFixture = false
        #endif
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        isPaused = true
        interruptPlay(reason: "challenge")
        lightReceipts.beginRound()
        game = fresh
        refreshCadence()
        remaining = showerInterval
        dialogue.reset()
        if let line = game.challengeGuideLine {
            guideLine = line
            if game.usesFullBoardRefill { dialogue.show(line) }
        }
        prepareRoundOpening()
    }

    func setBalance(_ balance: StarfallBalance) {
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        guard game.challenge == nil, balance != game.balance else { return }
        freezeClock()
        game.setBalance(balance)
        refreshCadence()
        remaining = showerInterval
        // Balance changes freeze before committing the new cadence; settle afterward.
        settleInterruptedPresentation(reason: "balance")
        dialogue.reset(); guide("guide.balance")
        save()
        armClock()
    }

    func setPace(_ pace: StarfallBalance.Pace) {
        var balance = game.balance
        balance.pace = pace
        setBalance(balance)
    }

    func setDarkStarFrequency(_ frequency: StarfallBalance.DarkStarFrequency) {
        var balance = game.balance
        balance.darkStars = frequency
        setBalance(balance)
    }

    func setSuspended(_ value: Bool) {
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        guard suspended != value else { return }
        suspended = value
        scene.decorativeMotionActive = !value
        if value { interruptPlay(reason: "suspension") }
        else {
            // Persist the retained store's chosen sky before its clock can run.
            save()
            presentPendingOpening()
            armClock()
        }
    }

    func setReducedMotion(_ value: Bool) {
        guard presenter.reduceMotion != value else { return }
        presenter.reduceMotion = value
        settleInterruptedPresentation(reason: "motion")
    }

    /// Round/clock interruptions stop the single deadline before invalidating input.
    /// Callers choose pause/suspension and replacement state explicitly.
    private func interruptPlay(reason: String) {
        freezeClock()
        openingPending = false
        settleInterruptedPresentation(reason: reason)
    }

    /// Presentation-only interruptions preserve clock phase. Settling owns input
    /// generation, celebration expiry, outstanding animations and stale completions.
    private func settleInterruptedPresentation(reason: String) {
        feedback.stopSounds()
        settlePresentation(reason: reason)
    }

    func settlePresentation(reason: String = "presentation") {
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        invalidateInput(reason)
        let interruptedOpening = openingPresenting
        openingGeneration &+= 1
        openingPresenting = false
        presentations.invalidate()
        cancelCelebration()
        if openingPending { presenter.prepareOpening(game) }
        else { presenter.render(game) }
        if interruptedOpening { armClock() }
        deliverRainIfReady()
    }

    /// The opening is already committed. Its rain is shown once on admission;
    /// restoration and interruption always reveal that same saved arrangement.
    private func prepareRoundOpening() {
        openingPending = game.supportsAutomaticRecipes
        save()
        if openingPending { presenter.prepareOpening(game) }
        else { presenter.render(game) }
        if !suspended { presentPendingOpening() }
    }

    private func presentPendingOpening() {
        guard openingPending, !suspended else { return }
        openingPending = false
        openingPresenting = true
        openingGeneration &+= 1
        let ticket = openingGeneration
        presenter.presentOpening(game) { [weak self] in
            guard let self, self.openingGeneration == ticket, self.openingPresenting else { return }
            self.openingPresenting = false
            self.armClock()
        }
    }

    func dismissPersistenceNotice() { persistenceNotice = nil }

    func loadTutorial(_ chapter: SkyTutorial) {
        guard tutorial != nil else { return }
        isPaused = true
        interruptPlay(reason: "tutorial")
        lightReceipts.beginRound()
        tutorial = SkyTutorialRun(chapter)
        game = chapter.game()
        refreshCadence(); remaining = showerInterval
        dialogue.reset()
        presenter.render(game)
    }

    /// Keep the saved winner as the bounded retry receipt until its optional
    /// best projection succeeds. New input must never discard that only proof.
    private func canReplaceMasteryReceipt() -> Bool {
        guard tutorial == nil, game.completedMasteryRun != nil else { return true }
        if lastSavedGame != game {
            save()
            return lastSavedGame == game && !masterySaveFailed
        }
        do {
            try mastery.record(game)
            masterySaveFailed = false
            if persistenceNotice == .masteryFailed { persistenceNotice = nil }
            return true
        } catch {
            masterySaveFailed = true
            persistenceNotice = .masteryFailed
            return false
        }
    }

    private func save() {
        guard tutorial == nil else { return }
        #if DEBUG
        guard !isTechniqueFixture else { return }
        #endif
        do { try archiveWriter(game, defaults) }
        catch {
            if !saveFailed { persistenceNotice = .failed }
            saveFailed = true
            Self.persistenceLog.error("Sky archive encoding/validation failed; existing save retained")
            return
        }
        lastSavedGame = game
        hasSavedSky = true
        // Both projections consume the durable round independently. Optional
        // best failure cannot withhold a repair, or submit an unsaved win.
        do {
            try journey.record(game)
            saveFailed = false
            if persistenceNotice == .failed { persistenceNotice = nil }
        } catch {
            if !saveFailed { persistenceNotice = .failed }
            saveFailed = true
        }
        do {
            try mastery.record(game)
            masterySaveFailed = false
            if persistenceNotice == .masteryFailed { persistenceNotice = nil }
        } catch {
            if !masterySaveFailed && persistenceNotice == nil { persistenceNotice = .masteryFailed }
            masterySaveFailed = true
        }
    }
}
