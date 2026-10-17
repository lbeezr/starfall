import UIKit
import Observation
import SwiftUI
import StarfallCore

@MainActor protocol ExperimentPresenting: AnyObject {
    var reduceMotion: Bool { get set }
    func render(_ game: StarfallExperiment)
    func animate(_ turn: StarfallExperimentTurn, from old: StarfallExperiment,
                 to game: StarfallExperiment, completion: @escaping () -> Void)
}

/// One cancellable deadline; no repeating timer or catch-up queue.
@MainActor protocol ExperimentRainScheduling: AnyObject {
    var now: TimeInterval { get }
    func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void)
    func cancel()
}

@MainActor private final class ExperimentRainClock: ExperimentRainScheduling {
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

@MainActor @Observable final class StarfallExperimentStore {
    static let saveKey = "starfall.accumulation.v3"
    private(set) var game: StarfallExperiment
    private(set) var busy = false
    private(set) var suspended = true
    private(set) var isPaused = true
    private(set) var nextShowerDate: Date?
    private(set) var message = "Start the sky. Clear matching stars to make room; adjust the balance in Settings."
    private(set) var pending: StarfallExperimentTurn?
    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: "soundEnabled"); if !soundEnabled { feedback.stopSounds() } }
    }
    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: "starfall.haptics") }
    }
    let scene: StarfallExperimentScene
    @ObservationIgnored private let feedback: any FallingSkyFeedbackProviding
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let presenter: any ExperimentPresenting
    @ObservationIgnored private let clock: any ExperimentRainScheduling
    @ObservationIgnored private var generation: UInt64 = 0
    @ObservationIgnored private var rainGeneration: UInt64 = 0
    @ObservationIgnored private var deadline: TimeInterval?
    @ObservationIgnored private var remaining: TimeInterval = 4
    @ObservationIgnored private var rainDue = false

    init(defaults: UserDefaults = .standard,
         arguments: [String] = ProcessInfo.processInfo.arguments,
         presenter: (any ExperimentPresenting)? = nil,
         clock: (any ExperimentRainScheduling)? = nil,
         feedback: (any FallingSkyFeedbackProviding)? = nil) {
        self.defaults = defaults
        self.feedback = feedback ?? GameFeedback()
        soundEnabled = defaults.bool(forKey: "soundEnabled")
        hapticsEnabled = defaults.bool(forKey: "starfall.haptics")
        self.clock = clock ?? ExperimentRainClock()
        let scene = StarfallExperimentScene()
        self.scene = scene
        self.presenter = presenter ?? scene
        // SwiftUI may construct stores for discarded view values. Keep initialization read-only.
        if !arguments.contains("--starfalls-reset"), let data = defaults.data(forKey: Self.saveKey),
           let saved = try? JSONDecoder().decode(StarfallExperiment.self, from: data), saved.isValidSave {
            game = saved
            message = saved.outcome == .won ? "First Light complete. Replay it or start a new sky." : saved.isOver ? "This sky is full. Replay it or try a new sky." : "Your sky is paused. Resume when you're ready."
        } else {
            let argument = arguments.first { $0.hasPrefix("--starfalls-seed=") }
            let seed = argument.flatMap { UInt64($0.dropFirst("--starfalls-seed=".count)) } ?? 5
            game = StarfallExperiment(seed: seed)
        }
        remaining = showerInterval
        scene.onLayout = { [weak self] in self?.settlePresentation() }
    }

    var forecast: [IncomingStar] { pending?.forecast ?? game.incoming }
    var showerInterval: TimeInterval { TimeInterval(game.balance.pace.rawValue) }
    var canClear: Bool { !busy && !suspended && !game.isOver && !rainDue }

    func clear(_ cell: Cell) {
        guard canClear else { return }
        let old = game
        guard let turn = game.clear(cell) else {
            message = game.gem(at: cell)?.isDark == true
                ? "Clear a matching group beside the dark star to dissolve it."
                : "Match stars worth 3 or more. Large stars count as 2."
            announce(message)
            return
        }
        if game.isOver { freezeClock() }
        feedback.collected(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled,
                           reducedMotion: presenter.reduceMotion)
        present(turn, from: old)
    }

    /// Explicit input works while paused too, without starting an automatic clock.
    func callShower() {
        guard !busy, !suspended, !game.isOver else { return }
        freezeClock()
        remaining = showerInterval
        commitShower()
    }

    func togglePause() {
        guard !suspended, !game.isOver else { return }
        isPaused.toggle()
        if isPaused {
            freezeClock()
            settlePresentation()
            feedback.stopSounds()
            message = "Sky paused. Clear at your pace or call the next shower."
        } else {
            message = "Watch the preview. Clear matching stars before the columns fill."
            armClock()
        }
    }

    private func armClock() {
        guard !isPaused, !suspended, !game.isOver, deadline == nil, !rainDue else { return }
        rainGeneration &+= 1
        let ticket = rainGeneration
        deadline = clock.now + remaining
        nextShowerDate = Date().addingTimeInterval(remaining)
        clock.schedule(after: remaining) { [weak self] in
            guard let self, self.rainGeneration == ticket, !self.isPaused, !self.suspended, !self.game.isOver else { return }
            self.deadline = nil; self.nextShowerDate = nil
            self.remaining = self.showerInterval
            self.rainDue = true
            self.deliverRainIfReady()
        }
    }

    private func freezeClock() {
        if let deadline { remaining = min(showerInterval, max(0.5, deadline - clock.now)) }
        else if rainDue { remaining = 0.5 }
        rainGeneration &+= 1
        clock.cancel()
        deadline = nil; nextShowerDate = nil; rainDue = false
    }

    private func deliverRainIfReady() {
        guard rainDue, !busy, !suspended, !isPaused, !game.isOver else { return }
        rainDue = false
        commitShower()
    }

    private func commitShower() {
        let old = game
        guard let turn = game.letStarsFall() else { return }
        if game.isOver { freezeClock() }
        else { remaining = showerInterval; armClock() }
        present(turn, from: old)
    }

    private func present(_ turn: StarfallExperimentTurn, from old: StarfallExperiment) {
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
        } else if growth > 0 {
            message = "\(growth == 1 ? "A star grew" : "\(growth) stars grew") — worth 2 when cleared."
        } else {
            message = "\(turn.arrivals.count == 1 ? "One star arrived" : "\(turn.arrivals.count) stars arrived"). Make room for the next shower."
        }
        save() // Commit before animation: backgrounding cannot replay arrivals.
        presenter.animate(turn, from: old, to: game) { [weak self] in
            guard let self, self.generation == ticket, self.busy else { return }
            self.pending = nil; self.busy = false
            self.announce(self.message)
            self.deliverRainIfReady()
        }
    }

    func restart(sameSky: Bool) {
        isPaused = true
        feedback.stopSounds()
        freezeClock(); remaining = showerInterval
        settlePresentation()
        if sameSky, let challenge = game.challenge {
            game = StarfallExperiment(challenge: challenge)
        } else {
            game = StarfallExperiment(seed: sameSky ? game.seed : UInt64.random(in: 0...UInt64.max), balance: game.balance)
        }
        remaining = showerInterval
        message = sameSky ? "Same sky, a fresh start. Start when you're ready." : "A new sky. Start when you're ready."
        save(); presenter.render(game)
    }

    func startFirstLight() {
        isPaused = true
        feedback.stopSounds()
        freezeClock()
        settlePresentation()
        game = StarfallExperiment(challenge: .firstLight)
        remaining = showerInterval
        message = "Collect 18 starlight to complete First Light. Start the sky or call a shower."
        save(); presenter.render(game)
    }

    func setBalance(_ balance: StarfallBalance) {
        guard game.challenge == nil, balance != game.balance else { return }
        freezeClock()
        game.setBalance(balance)
        remaining = showerInterval
        settlePresentation()
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
        guard suspended != value else { return }
        suspended = value
        if value { feedback.stopSounds(); freezeClock(); settlePresentation() }
        else {
            // Persist the retained store's chosen sky before its clock can run.
            save()
            armClock()
        }
    }

    func setReducedMotion(_ value: Bool) {
        guard presenter.reduceMotion != value else { return }
        presenter.reduceMotion = value
        settlePresentation()
    }

    func settlePresentation() {
        generation &+= 1
        pending = nil; busy = false
        presenter.render(game)
        deliverRainIfReady()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(game) { defaults.set(data, forKey: Self.saveKey) }
    }

    private func announce(_ text: String) {
        if UIAccessibility.isVoiceOverRunning {
            feedback.stopSounds()
            UIAccessibility.post(notification: .announcement, argument: text)
        }
    }
}
