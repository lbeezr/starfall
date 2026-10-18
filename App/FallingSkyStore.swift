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
    var terminalSpeech: SkyTerminalSpeech = .feedback
    static let saveKey = SkySaveArchive.key
    private(set) var game: FallingSky
    private(set) var hasSavedSky = false
    private(set) var saveFailed = false
    private(set) var rejectedSaveKey: String?
    private static let persistenceLog = Logger(subsystem: "com.starfall.prototype", category: "persistence")
    var busy: Bool { presentations.busy }
    private(set) var suspended = true
    private(set) var sceneReady = false
    private(set) var isPaused = true
    private(set) var nextShowerDate: Date?
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
        guideLine = SkyDialogueLibrary.line(id, values: values)
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
    private(set) var celebration: StarlightCelebration?
    @ObservationIgnored private var celebrationTask: Task<Void, Never>?
    @ObservationIgnored private var celebrationSequence: UInt64 = 0
    private(set) var techniqueResult = ""
    private var techniqueRelay = SkyTechniqueRelay()
    #if DEBUG
    private(set) var isTechniqueFixture = false
    #endif

    private(set) var constellationInputGeneration: UInt64 = 0
    private(set) var constellationTracing = false
    private var constellationHold: UInt64?
    private var constellationHoldSequence: UInt64 = 0

    /// Only the owner may release a live hold; late callbacks cannot resume a newer touch.
    @discardableResult func beginConstellationHold(at cell: Cell? = nil) -> UInt64? {
        guard (cell.map(canContact) ?? canClear), constellationHold == nil else { return nil }
        constellationHoldSequence &+= 1
        constellationHold = constellationHoldSequence
        constellationTracing = true
        freezeClock()
        #if DEBUG
        observeTiming(.state)
        #endif
        return constellationHold
    }
    func endConstellationHold(_ ticket: UInt64?) {
        guard let ticket, constellationHold == ticket else { return }
        constellationHold = nil; constellationTracing = false
        armClock()
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
    var changingColumns: Set<Int> { presentations.changingColumns }

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
    func traceStep(count: Int) {
        guard canReceiveInput, constellationTracing, count > 0 else { return }
        feedback.traceStep(count: count, enabled: hapticsEnabled && !presenter.reduceMotion)
    }

    /// A value snapshot cannot announce after its generation/hold was replaced.
    /// Delivery is synchronous; this boundary creates no delayed speech task.
    func announceTraceSelection(count: Int, value: Int, ready: Bool,
                                generation ticket: UInt64, holdTicket: UInt64?) {
        guard canReceiveInput, ticket == constellationInputGeneration,
              holdTicket == constellationHold, count == 0 || holdTicket != nil else { return }
        let message = count > 0
            ? SkyCopy.text(.inputTraceAnnouncement, values: ["count": String(count), "score": String(value), "status": SkyCopy.text(ready ? .inputTraceReleaseReady : game.challenge == nil ? .inputTraceShort : .inputTraceChallengeShort)])
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
    @ObservationIgnored private var deadline: TimeInterval?
    @ObservationIgnored private var remaining: TimeInterval = 0
    @ObservationIgnored private var rainDue = false
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
              admittedTapGroups: constellationTracing ? 0 : game.legalGroups.filter { group in
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
        endConstellationHold(constellationHold)
        showInputFeedback(nil)
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
         feedback: (any FallingSkyFeedbackProviding)? = nil) {
        self.defaults = defaults
        self.feedback = feedback ?? GameFeedback()
        soundEnabled = defaults.object(forKey: "soundEnabled") == nil ? true : defaults.bool(forKey: "soundEnabled")
        hapticsEnabled = defaults.object(forKey: "starfall.haptics") == nil ? true : defaults.bool(forKey: "starfall.haptics")
        self.clock = clock ?? FallingSkyRainClock()
        let scene = FallingSkyScene()
        self.scene = scene
        self.presenter = presenter ?? scene
        // SwiftUI may construct stores for discarded view values. Keep initialization read-only.
        if !arguments.contains("--starfalls-reset"), case .loaded(let saved) = SkySaveArchive.inspect(from: defaults) {
            game = saved.removingGravity().adoptingFeedingDusk()
            hasSavedSky = true
            guide(saved.outcome == .won ? "guide.won" : saved.isOver ? "guide.full" : "guide.restore", values: saved.isOver ? ["score": String(saved.score)] : [:])
        } else {
            let argument = arguments.first { $0.hasPrefix("--starfalls-seed=") }
            let seed = argument.flatMap { UInt64($0.dropFirst("--starfalls-seed=".count)) } ?? 5
            game = FallingSky.freshSurvival(seed: seed)
            if !arguments.contains("--starfalls-reset"), case .rejected(let key) = SkySaveArchive.inspect(from: defaults) {
                rejectedSaveKey = key
                Self.persistenceLog.error("Rejected sky archive; preserving it before the next committed save")
            }
        }
        #if DEBUG
        if arguments.contains("--starfalls-reset"), arguments.contains("--observatory-review") {
            game = ObservatoryReviewFixture.game(dense: arguments.contains("--observatory-dense")).adoptingFeedingDusk()
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
            guide("guide.fixture",values:["detail":example.title + " review board. Trace a recipe or swipe and hold."])
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
    var forecast: [IncomingStar] { pending?.forecast ?? game.incoming }
    var showerInterval: TimeInterval { nextShowerCadence.delay }
    var inputPolicy: SkyInputPolicy {
        .init(suspended: suspended, gameOver: game.isOver, showerDue: rainDue,
              changingColumns: changingColumns, presenting: busy)
    }
    var canClear: Bool { inputPolicy.wholeBoard.isReady }
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
    func canClear(_ cell: Cell) -> Bool { clearAvailability(cell).isReady }

    func traceAvailability(_ path: [Cell]) -> SkyInputAvailability {
        guard inputPolicy.receiving.isReady else { return inputPolicy.receiving }
        guard !path.isEmpty else { return .emptySelection }
        guard busy else { return .ready }
        var preview = game
        let columns = preview.clearConstellation(path)?.changingColumns ?? Set(path.map(\.column))
        return inputPolicy.reserving(columns)
    }
    func canTrace(_ path: [Cell]) -> Bool { traceAvailability(path).isReady }

    func clear(_ cell: Cell) {
        guard canReceiveInput, !constellationTracing else { return }
        guard canClear(cell) else { explainSettling(at: cell); return }
        showInputFeedback(nil)
        let old = game
        guard let turn = game.clear(cell) else {
            let gem = game.gem(at: cell)
            let id = gem?.gravityKind == .hole ? "guide.hole-help"
                : gem?.gravityKind == .magnet ? "guide.magnet-help"
                : gem?.isDark == true ? (game.duskRule != .legacy ? "guide.dusk-help" : "guide.dark-help")
                : gem?.isLight == true ? "guide.opal-help" : "guide.match-help"
            guide(id, values: id == "guide.dusk-help" ? ["feeds": String(game.duskRule.feedingShowers)] : [:], visible: true)
            feedback.announce(guideLine.spokenText)
            return
        }
        #if DEBUG
        observeTiming(.tapAccepted)
        #endif
        if game.isOver { freezeClock() }
        present(turn, from: old)
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
        if case .recipe(let recipe) = action { present(turn, from: old, recipe: recipe) }
        else { present(turn, from: old) }
        return true
    }

    private func celebrate(_ turn: FallingSkyTurn, from old: FallingSky, path: [Cell], recipe: StarRecipe?) {
        guard turn.collected > 0 else { cancelCelebration(); return }
        cancelCelebration()
        celebrationSequence &+= 1
        guard let receipt = StarlightCelebration(id: celebrationSequence, turn: turn, from: old,
            total: game.score, path: path, recipe: recipe, relayDepth: techniqueRelay.depth) else { return }
        celebration = receipt
        feedback.collected(receipt.level, soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled,
                           reducedMotion: presenter.reduceMotion)
        celebrationTask = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(StarlightCelebration.duration)) } catch { return }
            guard let self, self.celebration?.id == receipt.id else { return }
            self.celebration = nil; self.celebrationTask = nil
        }
    }

    func cancelCelebration() {
        celebrationTask?.cancel(); celebrationTask = nil; celebration = nil
    }

    deinit { celebrationTask?.cancel() }

    /// Explicit input works while paused too, without starting an automatic clock.
    func callShower() {
        #if DEBUG
        guard !isTechniqueFixture else { return }
        #endif
        guard !constellationTracing, !busy, !suspended, !game.isOver else { return }
        freezeClock()
        remaining = showerInterval
        commitShower(announcesResult: true)
    }

    func togglePause() {
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        invalidateInput("pause")
        guard !suspended, !game.isOver else { return }
        isPaused.toggle()
        if isPaused {
            interruptPlay(reason: "pause")
            dialogue.reset(); guide("guide.paused")
        } else {
            dialogue.reset(); guide("guide.started"); dialogue.show(pausedGuideLine)
            armClock()
        }
    }

    private func armClock() {
        #if DEBUG
        guard !isTechniqueFixture else { return }
        #endif
        guard !constellationTracing, !isPaused, !suspended, !game.isOver, deadline == nil, !rainDue else { return }
        rainGeneration &+= 1
        let ticket = rainGeneration
        deadline = clock.now + remaining
        nextShowerDate = Date().addingTimeInterval(remaining)
        #if DEBUG
        observeTiming(.scheduled)
        #endif
        clock.schedule(after: remaining) { [weak self] in
            guard let self, self.rainGeneration == ticket, !self.isPaused, !self.suspended, !self.game.isOver else { return }
            #if DEBUG
            self.observeTiming(.due)
            #endif
            self.nextShowerDate = nil
            self.rainDue = true
            #if DEBUG
            if self.busy { self.observeTiming(.deferred) }
            #endif
            self.deliverRainIfReady()
        }
    }

    private func freezeClock() {
        #if DEBUG
        if deadline != nil || rainDue { observeTiming(.cancelled) }
        #endif
        if rainDue { remaining = 0.5 }
        else if let deadline { remaining = min(showerInterval, max(0.5, deadline - clock.now)) }
        rainGeneration &+= 1
        clock.cancel()
        deadline = nil; nextShowerDate = nil; rainDue = false
    }

    private func deliverRainIfReady() {
        guard rainDue, !busy, !constellationTracing, !suspended, !isPaused, !game.isOver else { return }
        let dueDeadline = deadline
        rainDue = false
        deadline = nil
        commitShower(announcesResult: false, scheduledDeadline: dueDeadline)
    }

    private func commitShower(announcesResult: Bool, scheduledDeadline: TimeInterval? = nil) {
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
        invalidateInput(isShower ? (announcesResult ? "manualShower" : "automaticShower") : "clear")
        if turn.exchange != nil {
            techniqueRelay.reset(); techniqueResult = SkyCopy.text(.techniqueMoved)
        } else if !turn.cleared.isEmpty {
            techniqueRelay.record(before:old,after:game,cleared:turn.cleared)
            techniqueResult = techniqueRelay.depth > 1 ? SkyCopy.text(.techniqueRelay, values: ["count": String(techniqueRelay.depth)]) : SkyCopy.text(.techniqueSupport)
        }
        celebrate(turn, from: old, path: path, recipe: recipe)
        let ticket = presentations.begin(turn)
        guideLine = SkyDialogueLibrary.result(for: turn, from: old, to: game,
            tracedCount: Set(path).count, recipe: recipe, relayDepth: techniqueRelay.depth,
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
        presenter.animate(turn, from: old, to: game) { [weak self] in
            guard let self, self.presentations.complete(ticket) else { return }
            if let columns = self.inputFeedback?.waitingColumns, columns.isDisjoint(with: self.changingColumns) {
                self.showInputFeedback(nil)
            }
            if let spokenResult, (!announcesResult || self.presentations.isLatest(ticket)),
               !self.game.isOver || self.terminalSpeech == .feedback {
                let accepted = self.dialogue.show(spokenResult, interrupt: announcesResult)
                if accepted && (announcesResult || self.game.isOver || announcesTransition) {
                    self.feedback.announce(spokenResult.spokenText)
                }
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

    /// Called only after Entry has consumed its pending choice. The round remains
    /// suspended until the view admits play; existing reset/save ownership stays here.
    func beginEntry(_ request: SkyEntryRequest) {
        switch request {
        case .initial: break // Keep the established first-launch seed and preview.
        case .fresh: restart(sameSky: false)
        case .replay: restart(sameSky: true)
        case .firstLight: startFirstLight()
        }
    }

    func restart(sameSky: Bool) {
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        isPaused = true
        interruptPlay(reason: "restart")
        #if DEBUG
        let replayAllowed = !isTechniqueFixture && sameSky
        isTechniqueFixture = false
        #else
        let replayAllowed = sameSky
        #endif
        if replayAllowed {
            game = game.removingGravity().adoptingFeedingDusk().replay()
        } else {
            // First Light's fixed balance belongs to that challenge, not the next normal sky.
            let balance = game.challenge == nil ? game.balance : StarfallBalance()
            game = FallingSky.freshSurvival(seed: UInt64.random(in: 0...UInt64.max), balance: balance)
        }
        refreshCadence()
        remaining = showerInterval
        dialogue.reset(); guide(sameSky ? "guide.replay" : "guide.new")
        save(); presenter.render(game)
    }

    #if DEBUG
    func loadConstellationFixture(_ fixture: ConstellationFixture) {
        isPaused = true
        interruptPlay(reason: "fixture")
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
        game = fixture.game().adoptingFeedingDusk(); refreshCadence(); remaining = showerInterval
        guide("guide.fixture", values: ["detail": fixture.message])
        save(); presenter.render(game)
    }

    #endif

    func startFirstLight() {
        #if DEBUG
        isTechniqueFixture = false
        #endif
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        isPaused = true
        interruptPlay(reason: "challenge")
        game = FallingSky(challenge: .firstLight)
        refreshCadence()
        remaining = showerInterval
        dialogue.reset(); guide("guide.first-light")
        save(); presenter.render(game)
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
        presentations.invalidate()
        cancelCelebration()
        presenter.render(game)
        deliverRainIfReady()
    }

    private func save() {
        #if DEBUG
        guard !isTechniqueFixture else { return }
        #endif
        do {
            try SkySaveArchive.save(game, to: defaults)
            hasSavedSky = true
            saveFailed = false
        } catch {
            saveFailed = true
            Self.persistenceLog.error("Sky archive encoding/validation failed; existing save retained")
        }
    }
}
