#if DEBUG
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
    static let showerInterval: TimeInterval = 4
    static let saveKey = "starfall.accumulation.v2"
    private(set) var game: StarfallExperiment
    private(set) var busy = false
    private(set) var suspended = true
    private(set) var isPaused = true
    private(set) var nextShowerDate: Date?
    private(set) var message = "Start the sky. Stars fall every four seconds; clear matching jewels to make room."
    private(set) var pending: StarfallExperimentTurn?
    let scene: StarfallExperimentScene
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let presenter: any ExperimentPresenting
    @ObservationIgnored private let clock: any ExperimentRainScheduling
    @ObservationIgnored private var generation: UInt64 = 0
    @ObservationIgnored private var rainGeneration: UInt64 = 0
    @ObservationIgnored private var deadline: TimeInterval?
    @ObservationIgnored private var remaining = showerInterval
    @ObservationIgnored private var rainDue = false

    init(defaults: UserDefaults = .standard,
         arguments: [String] = ProcessInfo.processInfo.arguments,
         presenter: (any ExperimentPresenting)? = nil,
         clock: (any ExperimentRainScheduling)? = nil) {
        self.defaults = defaults
        self.clock = clock ?? ExperimentRainClock()
        let scene = StarfallExperimentScene()
        self.scene = scene
        self.presenter = presenter ?? scene
        if arguments.contains("--starfalls-reset") { defaults.removeObject(forKey: Self.saveKey) }
        if let data = defaults.data(forKey: Self.saveKey),
           let saved = try? JSONDecoder().decode(StarfallExperiment.self, from: data), saved.isValidSave {
            game = saved
            message = saved.isOver ? "This sky is full. Replay it or try a new sky." : "Your sky is paused. Resume when you're ready."
        } else {
            let argument = arguments.first { $0.hasPrefix("--starfalls-seed=") }
            let seed = argument.flatMap { UInt64($0.dropFirst("--starfalls-seed=".count)) } ?? 5
            game = StarfallExperiment(seed: seed)
        }
        scene.onLayout = { [weak self] in self?.settlePresentation() }
        save()
    }

    var forecast: [IncomingStar] { pending?.forecast ?? game.incoming }
    var canClear: Bool { !busy && !suspended && !isPaused && !game.isOver && !rainDue }

    func clear(_ cell: Cell) {
        guard canClear else { return }
        let old = game
        guard let turn = game.clear(cell) else {
            message = "Match jewels worth 3 or more. Large jewels count as 2."
            announce(message)
            return
        }
        present(turn, from: old)
    }

    func togglePause() {
        guard !suspended, !game.isOver else { return }
        isPaused.toggle()
        if isPaused {
            freezeClock()
            settlePresentation()
            message = "Sky paused. Take your time."
        } else {
            message = "Watch the preview. Clear matching jewels before the columns fill."
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
            self.remaining = Self.showerInterval
            self.rainDue = true
            self.deliverRainIfReady()
        }
    }

    private func freezeClock() {
        if let deadline { remaining = min(Self.showerInterval, max(0.5, deadline - clock.now)) }
        else if rainDue { remaining = 0.5 }
        rainGeneration &+= 1
        clock.cancel()
        deadline = nil; nextShowerDate = nil; rainDue = false
    }

    private func deliverRainIfReady() {
        guard rainDue, !busy, !suspended, !isPaused, !game.isOver else { return }
        rainDue = false
        let old = game
        guard let turn = game.letStarsFall() else { return }
        if game.isOver { freezeClock() }
        else { remaining = Self.showerInterval; armClock() }
        present(turn, from: old)
    }

    private func present(_ turn: StarfallExperimentTurn, from old: StarfallExperiment) {
        generation &+= 1
        let ticket = generation
        busy = true; pending = turn
        let growth = turn.arrivals.filter(\.grew).count
        if let column = turn.blockedColumn {
            message = "Column \(column + 1) could not fit the next star. \(game.score) starlight collected."
        } else if turn.collected > 0 {
            message = "+\(turn.collected) starlight. A little more room to breathe."
        } else if growth > 0 {
            message = "\(growth == 1 ? "A jewel grew" : "\(growth) jewels grew") — worth 2 when cleared."
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
        freezeClock(); remaining = Self.showerInterval
        settlePresentation()
        game = StarfallExperiment(seed: sameSky ? game.seed : UInt64.random(in: 0...UInt64.max))
        message = sameSky ? "Same sky, a fresh start. Start when you're ready." : "A new sky. Start when you're ready."
        save(); presenter.render(game)
    }

    func setSuspended(_ value: Bool) {
        guard suspended != value else { return }
        suspended = value
        if value { freezeClock(); settlePresentation() }
        else { armClock() }
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
        if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: text) }
    }
}
#endif
