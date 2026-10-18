import Foundation
import Observation
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

/// Terminal speech has one presentation owner; explicit nonterminal feedback stays store-owned.
enum SkyTerminalSpeech { case feedback, ceremony }

// Existing persistence keys and launch arguments survive the production naming promotion.
@MainActor @Observable final class FallingSkyStore {
    var terminalSpeech: SkyTerminalSpeech = .feedback
    static let saveKey = SkySaveArchive.key
    private(set) var game: FallingSky
    private(set) var hasSavedSky = false
    var busy: Bool { !presentations.isEmpty }
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
        return SkyDialogueLibrary.timing(game: game, cadence: nextShowerCadence) ?? guideLine
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
    private struct Presentation {
        let id: UInt64
        let turn: FallingSkyTurn
    }
    private var presentations: [Presentation] = []
    private var presentationSequence: UInt64 = 0
    private struct InputFeedback: Equatable {
        let text: String
        let waitingColumns: Set<Int>?
    }
    private var inputFeedback: InputFeedback?
    var inputMessage: String? { inputFeedback?.text }
    var pending: FallingSkyTurn? {
        presentations.first(where: { !$0.turn.arrivals.isEmpty })?.turn ?? presentations.last?.turn
    }
    var changingColumns: Set<Int> { presentations.reduce(into: []) { $0.formUnion($1.turn.changingColumns) } }

    func showInputFeedback(_ text: String?) {
        inputFeedback = text.map { InputFeedback(text: $0, waitingColumns: nil) }
    }

    func explainInputFailure(_ text: String) {
        showInputFeedback(text)
        feedback.announce(text)
    }

    func explainSettling(at cell: Cell) {
        var preview = game
        let columns = preview.clear(cell)?.changingColumns ?? [cell.column]
        showSettling(columns)
    }

    private func showSettling(_ columns: Set<Int>) {
        inputFeedback = InputFeedback(text: "Stars settling…", waitingColumns: columns.intersection(changingColumns))
        feedback.announce("Stars settling")
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
    @ObservationIgnored private var generation: UInt64 = 0
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
        if !arguments.contains("--starfalls-reset"), let saved = SkySaveArchive.load(from: defaults) {
            game = saved
            hasSavedSky = true
            guide(saved.outcome == .won ? "guide.won" : saved.isOver ? "guide.full" : "guide.restore", values: saved.isOver ? ["score": String(saved.score)] : [:])
        } else {
            let argument = arguments.first { $0.hasPrefix("--starfalls-seed=") }
            let seed = argument.flatMap { UInt64($0.dropFirst("--starfalls-seed=".count)) } ?? 5
            game = FallingSky(seed: seed, generation: .current)
        }
        #if DEBUG
        if arguments.contains("--starfalls-reset"), arguments.contains("--observatory-review") {
            game = ObservatoryReviewFixture.game(dense: arguments.contains("--observatory-dense"))
        }
        #endif
        #if DEBUG
        if arguments.contains("--starfalls-reset"), let name = arguments.first(where: { $0.hasPrefix("--constellation-fixture=") }),
           let fixture = ConstellationFixture(rawValue: String(name.dropFirst("--constellation-fixture=".count))) {
            game = fixture.game()
            guide("guide.fixture", values: ["detail": fixture.title + ". Draw through matching stars."])
        }
        #endif
        refreshCadence()
        #if DEBUG
        if arguments.contains("--starfalls-reset"), let name = arguments.first(where: { $0.hasPrefix("--gravity-fixture=") }),
           let fixture = GravityFixture(rawValue: String(name.dropFirst("--gravity-fixture=".count))) {
            game = fixture.game(); guide("guide.fixture", values: ["detail": fixture.message])
        }
        #endif
        refreshCadence()
        remaining = showerInterval
        scene.decorativeMotionActive = !suspended
        scene.onLayout = { [weak self] in self?.settlePresentation() }
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
    var canClear: Bool { !busy && canReceiveInput }
    var canReceiveInput: Bool { !suspended && !game.isOver && !rainDue }

    func canContact(_ cell: Cell) -> Bool { canReceiveInput && !changingColumns.contains(cell.column) }

    func canClear(_ cell: Cell) -> Bool {
        guard canContact(cell) else { return false }
        var preview = game
        guard let turn = preview.clear(cell) else { return true } // Invalid input still explains its rule.
        return turn.changingColumns.isDisjoint(with: changingColumns)
    }

    func canTrace(_ path: [Cell]) -> Bool {
        guard canReceiveInput, !path.isEmpty else { return false }
        var preview = game
        if let turn = preview.clearConstellation(path) {
            return turn.changingColumns.isDisjoint(with: changingColumns)
        }
        return path.allSatisfy { !changingColumns.contains($0.column) }
    }

    func clear(_ cell: Cell) {
        guard canReceiveInput, !constellationTracing else { return }
        guard canClear(cell) else { explainSettling(at: cell); return }
        showInputFeedback(nil)
        let old = game
        guard let turn = game.clear(cell) else {
            let gem = game.gem(at: cell)
            let id = gem?.gravityKind == .hole ? "guide.hole-help"
                : gem?.gravityKind == .magnet ? "guide.magnet-help"
                : gem?.isDark == true ? "guide.dark-help"
                : gem?.isLight == true ? "guide.opal-help" : "guide.match-help"
            guide(id, visible: true)
            feedback.announce(guideLine.spokenText)
            return
        }
        #if DEBUG
        observeTiming(.tapAccepted)
        #endif
        if game.isOver { freezeClock() }
        feedback.collected(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled,
                           reducedMotion: presenter.reduceMotion)
        present(turn, from: old)
    }

    func clearTracedConstellation(_ path: [Cell], snapshot: FallingSky, generation ticket: UInt64) {
        guard !suspended, !game.isOver, game == snapshot, ticket == constellationInputGeneration else { return }
        guard canTrace(path) else {
            var preview = game
            showSettling(preview.clearConstellation(path)?.changingColumns ?? Set(path.map(\.column)))
            return
        }
        let old = game
        guard let turn = game.clearConstellation(path) else { return }
        #if DEBUG
        observeTiming(.traceAccepted)
        #endif
        if game.isOver { freezeClock() }
        feedback.collected(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled,
                           reducedMotion: presenter.reduceMotion)
        present(turn, from: old)
    }

    /// Explicit input works while paused too, without starting an automatic clock.
    func callShower() {
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
            freezeClock()
            settlePresentation(reason: "pause")
            feedback.stopSounds()
            dialogue.reset(); guide("guide.paused")
        } else {
            dialogue.reset(); guide("guide.started"); dialogue.show(pausedGuideLine)
            armClock()
        }
    }

    private func armClock() {
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

    private func present(_ turn: FallingSkyTurn, from old: FallingSky, announcesResult: Bool = true, previousCadence: SkyCadenceStep? = nil) {
        invalidateInput(turn.arrivals.isEmpty && turn.blockedColumn == nil ? "clear" : (announcesResult ? "manualShower" : "automaticShower"))
        let epoch = generation
        presentationSequence &+= 1
        let ticket = presentationSequence
        presentations.append(Presentation(id: ticket, turn: turn))
        let growth = turn.arrivals.filter(\.grew).count
        let dissolved = turn.cleared.filter { old.gem(at: $0)?.isDark == true }.count
        if game.outcome == .won {
            guide("guide.won", values: ["score": String(game.score)])
        } else if turn.blockedColumn != nil {
            guide("guide.full", values: ["score": String(game.score)])
        } else if turn.collected > 0 {
            if dissolved > 0 {
                guide("guide.dissolved", values: ["score": String(turn.collected), "dark": dissolved == 1 ? "Dark star" : "Dark stars"])
            } else { guide("guide.clear", values: ["score": String(turn.collected)]) }
        } else if turn.arrivals.contains(where: { $0.gem.isDark }) {
            guide("guide.dark-arrival")
        } else if turn.arrivals.contains(where: { $0.gem.isLight }) {
            guide("guide.opal-arrival")
        } else if turn.arrivals.contains(where: { $0.gem.gravityKind == .magnet }) {
            guide("guide.magnet-arrival")
        } else if growth > 0 {
            guide("guide.growth", values: ["growth": growth == 1 ? "A star grew" : "\(growth) stars grew"])
        } else {
            guide("guide.arrival", values: ["arrival": turn.arrivals.count == 1 ? "One star arrived" : "\(turn.arrivals.count) stars arrived"])
        }
        if !game.isOver, let field = game.orbit {
            guide("guide.orbit", values: ["windows": String(field.windowsRemaining)])
        } else if !game.isOver, turn.gravityPhases.contains(where: { $0.event == .release }) {
            guide("guide.release")
        }
        // The committed phase/cadence has one visible and spoken owner. No queued notices.
        let transition = SkyDialogueLibrary.transition(from: old, to: game,
                                                       previousCadence: previousCadence, cadence: nextShowerCadence)
        let announcesTransition = SkyDialogueLibrary.announcesTransition(from: old, to: game,
            previousCadence: previousCadence, cadence: nextShowerCadence)
        let resultLine = SkyDialogueLibrary.contextual(guideLine, game: game, cadence: nextShowerCadence)
        let spokenResult: SkyDialogueLine? = transition ?? (announcesResult || game.isOver ? resultLine : nil)
        save() // Commit before animation: backgrounding cannot replay arrivals.
        presenter.animate(turn, from: old, to: game) { [weak self] in
            guard let self, self.generation == epoch,
                  self.presentations.contains(where: { $0.id == ticket }) else { return }
            self.presentations.removeAll { $0.id == ticket }
            if let columns = self.inputFeedback?.waitingColumns, columns.isDisjoint(with: self.changingColumns) {
                self.showInputFeedback(nil)
            }
            if let spokenResult, (!announcesResult || ticket == self.presentationSequence),
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
        feedback.stopSounds()
        freezeClock(); remaining = showerInterval
        settlePresentation(reason: "restart")
        if sameSky {
            game = game.replay()
        } else {
            // First Light's fixed balance belongs to that challenge, not the next normal sky.
            let balance = game.challenge == nil ? game.balance : StarfallBalance()
            game = FallingSky(seed: UInt64.random(in: 0...UInt64.max), balance: balance, generation: .current)
        }
        refreshCadence()
        remaining = showerInterval
        dialogue.reset(); guide(sameSky ? "guide.replay" : "guide.new")
        save(); presenter.render(game)
    }

    #if DEBUG
    func loadConstellationFixture(_ fixture: ConstellationFixture) {
        isPaused = true
        feedback.stopSounds()
        freezeClock()
        settlePresentation(reason: "fixture")
        game = fixture.game()
        refreshCadence()
        remaining = showerInterval
        guide("guide.fixture", values: ["detail": fixture.title + ". Draw through matching stars."])
        save(); presenter.render(game)
    }

    #endif

    #if DEBUG
    func loadGravityFixture(_ fixture: GravityFixture) {
        isPaused = true
        feedback.stopSounds()
        freezeClock(); settlePresentation()
        game = fixture.game(); refreshCadence(); remaining = showerInterval
        guide("guide.fixture", values: ["detail": fixture.message])
        save(); presenter.render(game)
    }

    #endif

    func startFirstLight() {
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        isPaused = true
        feedback.stopSounds()
        freezeClock()
        settlePresentation(reason: "challenge")
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
        settlePresentation(reason: "balance")
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
        if value { feedback.stopSounds(); freezeClock(); settlePresentation(reason: "suspension") }
        else {
            // Persist the retained store's chosen sky before its clock can run.
            save()
            armClock()
        }
    }

    func setReducedMotion(_ value: Bool) {
        guard presenter.reduceMotion != value else { return }
        presenter.reduceMotion = value
        settlePresentation(reason: "motion")
    }

    func settlePresentation(reason: String = "presentation") {
        #if DEBUG
        defer { observeTiming(.state) }
        #endif
        invalidateInput(reason)
        generation &+= 1
        presentations.removeAll()
        presenter.render(game)
        deliverRainIfReady()
    }

    private func save() {
        if let data = try? SkySaveArchive.encode(game) {
            hasSavedSky = true
            defaults.set(data, forKey: Self.saveKey)
        }
    }
}


/// Transient input ticket. Core remains the authority for whether a walk can clear.
@MainActor final class ConstellationTraceIntent {
    // The coordinator releases this after terminal commit/cancellation. Selection
    // cancellation alone must not discard a ticket before the store receives it.
    var holdTicket: UInt64?
    var lastFinger: CGPoint?
    private(set) var path: [Cell] = []
    private(set) var snapshot: FallingSky?
    private(set) var generation: UInt64 = 0
    private(set) var sequence: UInt64 = 0
    var count: Int { Set(path).count }
    var value: Int { snapshot?.value(of: Set(path)) ?? 0 }

    @discardableResult func begin(_ cell: Cell, game: FallingSky, generation: UInt64, enabled: Bool) -> UInt64? {
        cancel()
        guard enabled, !game.isOver, game.constellationGroup(at: cell).count >= 5 else { return nil }
        sequence &+= 1
        snapshot = game; self.generation = generation; path = [cell]
        return sequence
    }
    @discardableResult func visit(_ cell: Cell, ticket: UInt64?, game: FallingSky, generation: UInt64, enabled: Bool) -> Bool {
        guard ticket == sequence, snapshot != nil else { return false }
        guard enabled, snapshot == game, self.generation == generation,
              let last = path.last, path.count < 196 else {
            cancel(); return false
        }
        guard cell != last, game.isValidConstellationPrefix(path + [cell]) else { return false }
        path.append(cell)
        return true
    }
    func finish(ticket: UInt64?, game: FallingSky, generation: UInt64, enabled: Bool) -> (path: [Cell], snapshot: FallingSky, generation: UInt64)? {
        defer { cancel() }
        guard ticket == sequence, let snapshot, snapshot == game, self.generation == generation,
              enabled, game.constellationCells(along: path) != nil else { return nil }
        return (path, snapshot, generation)
    }
    func cancel() { lastFinger = nil; path = []; snapshot = nil; sequence &+= 1 }
}
