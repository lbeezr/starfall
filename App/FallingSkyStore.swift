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
    private(set) var busy = false
    private(set) var suspended = true
    private(set) var sceneReady = false
    private(set) var isPaused = true
    private(set) var nextShowerDate: Date?
    /// Interval/phase leading to the next shower, including while paused or overdue.
    private(set) var nextShowerCadence: SkyCadenceStep = .init(delay: 4, phase: .steady)
    private(set) var message = "Gather starlight. Draw your own constellations."
    private(set) var constellationInputGeneration: UInt64 = 0
    var constellationTracing = false {
        didSet {
            guard oldValue != constellationTracing else { return }
            if constellationTracing { freezeClock() } else { armClock() }
            #if DEBUG
            observeTiming(.state)
            #endif
        }
    }
    private(set) var pending: FallingSkyTurn?
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
        constellationTracing = false
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
            message = saved.outcome == .won ? "First Light complete. Replay it or start a new sky." : saved.isOver ? "This sky is full. Replay it or try a new sky." : "Your sky is paused. Resume when you're ready."
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
            message = fixture.title + ". Draw through matching stars."
        }
        #endif
        refreshCadence()
        #if DEBUG
        if arguments.contains("--starfalls-reset"), let name = arguments.first(where: { $0.hasPrefix("--gravity-fixture=") }),
           let fixture = GravityFixture(rawValue: String(name.dropFirst("--gravity-fixture=".count))) {
            game = fixture.game(); message = fixture.message
        }
        #endif
        refreshCadence()
        remaining = showerInterval
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
    var canClear: Bool { !busy && !suspended && !game.isOver && !rainDue }

    func clear(_ cell: Cell) {
        guard canClear, !constellationTracing else { return }
        let old = game
        guard let turn = game.clear(cell) else {
            if game.gem(at: cell)?.gravityKind != nil {
                message = game.gem(at: cell)?.gravityKind == .hole
                    ? "Clear a matching group containing a captive to close the hole."
                    : "Clear beside a magnet to dissolve it, or clear between a pair to form a hole."
                feedback.announce(message); return
            }
            message = game.gem(at: cell)?.isDark == true
                ? "Clear a matching group beside the dark star to dissolve it."
                : game.gem(at: cell)?.isLight == true
                    ? "Start on a colored star. The Opal Orb can join that color’s match or constellation and is spent when cleared."
                : "Match three light side by side, or five actual stars linked sideways or diagonally. Large stars count as one star, worth two light."
            feedback.announce(message)
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
        guard canClear, game == snapshot, ticket == constellationInputGeneration else { return }
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
            message = "Sky paused. Clear at your pace or call the next shower."
        } else {
            message = "Watch the preview. Clear matching stars before the columns fill."
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
        guard rainDue, !busy, !suspended, !isPaused, !game.isOver else { return }
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
        generation &+= 1
        let ticket = generation
        busy = true; pending = turn
        let growth = turn.arrivals.filter(\.grew).count
        let dissolved = turn.cleared.filter { old.gem(at: $0)?.isDark == true }.count
        if game.outcome == .won {
            message = "First Light complete! \(game.score) starlight collected. Replay it or start a new sky."
        } else if turn.blockedColumn != nil {
            message = "There was no room for the next star. \(game.score) starlight collected."
        } else if turn.collected > 0 {
            message = "+\(turn.collected) starlight. " + (dissolved > 0 ? "\(dissolved == 1 ? "Dark star dissolved" : "Dark stars dissolved")." : "A little more room to breathe.")
        } else if turn.arrivals.contains(where: { $0.gem.isDark }) {
            message = "A dark star blocks nearby growth. Clear beside it to dissolve it."
        } else if turn.arrivals.contains(where: { $0.gem.isLight }) {
            message = "An Opal Orb arrived. Start on a colored star to include it in that family’s match or constellation. Clearing spends the orb."
        } else if turn.arrivals.contains(where: { $0.gem.gravityKind == .magnet }) {
            message = "A magnetic pair arrived. Clear their middle to form a hole, or clear beside a lone magnet to dissolve it."
        } else if growth > 0 {
            message = "\(growth == 1 ? "A star grew" : "\(growth) stars grew") — worth 2 when cleared."
        } else {
            message = "\(turn.arrivals.count == 1 ? "One star arrived" : "\(turn.arrivals.count) stars arrived"). Make room for the next shower."
        }
        if !game.isOver, let field = game.orbit {
            message = "Orbit: \(field.windowsRemaining) windows left. Clear a captive to release the others."
        } else if !game.isOver, turn.gravityPhases.contains(where: { $0.event == .release }) {
            message = "The hole closed. Its stars are free."
        }
        // One settled, generation-guarded announcement owns both pressure axes.
        // Ordinary automatic arrivals leave exploration speech alone.
        var transitions: [String] = []
        if !game.isOver, game.challenge == nil, let previousCadence {
            if let cue = SkyPhaseCue(game: game), cue.announcesTransition,
               cue != SkyPhaseCue(game: old) { transitions.append(cue.text) }
            let cadence = nextShowerCadence
            if (cadence.warnsFasterNext && !previousCadence.warnsFasterNext)
                || (cadence.phase == .breathing && previousCadence.phase != .breathing),
               let copy = SkyCadenceCueCopy(step: cadence) { transitions.append(copy.label) }
        }
        let speech = (announcesResult || game.isOver ? [message] : []) + transitions
        let spokenResult = speech.isEmpty ? nil : speech.joined(separator: ". ")
        save() // Commit before animation: backgrounding cannot replay arrivals.
        presenter.animate(turn, from: old, to: game) { [weak self] in
            guard let self, self.generation == ticket, self.busy else { return }
            self.pending = nil; self.busy = false
            if let spokenResult, !self.game.isOver || self.terminalSpeech == .feedback {
                self.feedback.announce(spokenResult)
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
        message = sameSky ? "Same sky, a fresh start. Start when you're ready." : "A new sky. Start when you're ready."
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
        message = fixture.title + ". Draw through matching stars."
        save(); presenter.render(game)
    }

    #endif

    #if DEBUG
    func loadGravityFixture(_ fixture: GravityFixture) {
        isPaused = true
        feedback.stopSounds()
        freezeClock(); settlePresentation()
        game = fixture.game(); refreshCadence(); remaining = showerInterval
        message = fixture.message
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
        message = "Collect 18 starlight to complete First Light. Start the sky or call a shower."
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
        message = "Balance updated. Your sky is ready when you are."
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
        pending = nil; busy = false
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
