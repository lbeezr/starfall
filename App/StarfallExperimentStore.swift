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

@MainActor @Observable final class StarfallExperimentStore {
    private(set) var game: StarfallExperiment
    private(set) var busy = false
    private(set) var suspended = false
    private(set) var message = "Invite a shower to begin. Nothing moves until you choose."
    private(set) var pending: StarfallExperimentTurn?
    let scene: StarfallExperimentScene
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let presenter: any ExperimentPresenting
    @ObservationIgnored private var generation: UInt64 = 0
    static let saveKey = "starfall.accumulation.v1"

    init(defaults: UserDefaults = .standard,
         arguments: [String] = ProcessInfo.processInfo.arguments,
         presenter: (any ExperimentPresenting)? = nil) {
        self.defaults = defaults
        let scene = StarfallExperimentScene()
        self.scene = scene
        self.presenter = presenter ?? scene
        if arguments.contains("--starfalls-reset") { defaults.removeObject(forKey: Self.saveKey) }
        if let data = defaults.data(forKey: Self.saveKey),
           let saved = try? JSONDecoder().decode(StarfallExperiment.self, from: data), saved.isValidSave {
            game = saved
            message = saved.isOver ? "This sky is full. Replay it or try a new sky." : "Your sky is waiting. The next shower is ready."
        } else {
            let argument = arguments.first { $0.hasPrefix("--starfalls-seed=") }
            let seed = argument.flatMap { UInt64($0.dropFirst("--starfalls-seed=".count)) } ?? 5
            game = StarfallExperiment(seed: seed)
        }
        scene.onLayout = { [weak self] in self?.settlePresentation() }
        save()
    }

    var forecast: [IncomingStar] { pending?.forecast ?? game.incoming }

    func clear(_ cell: Cell) {
        guard !busy, !suspended, !game.isOver else { return }
        let old = game
        guard let turn = game.clear(cell) else {
            message = "Connect matching jewels worth 3 or more. Large jewels count as 2. No turn used."
            announce(message)
            return
        }
        present(turn, from: old)
    }

    func inviteShower() {
        guard !busy, !suspended, !game.isOver else { return }
        let old = game
        guard let turn = game.letStarsFall() else { return }
        present(turn, from: old)
    }

    private func present(_ turn: StarfallExperimentTurn, from old: StarfallExperiment) {
        generation &+= 1
        let ticket = generation
        busy = true; pending = turn
        let growth = turn.arrivals.filter(\.grew).count
        if let column = turn.blockedColumn {
            message = "Column \(column + 1) could not fit the next star. \(game.score) starlight collected."
        } else if growth > 0 {
            message = "\(turn.collected > 0 ? "+\(turn.collected) starlight. " : "")\(growth == 1 ? "A jewel grew" : "\(growth) jewels grew") — worth 2 when cleared."
        } else {
            message = turn.collected > 0 ? "+\(turn.collected) starlight. Three new stars arrived." : "Three stars arrived. Make room for the next shower."
        }
        save() // Commit before animation: backgrounding cannot replay arrivals.
        presenter.animate(turn, from: old, to: game) { [weak self] in
            guard let self, self.generation == ticket, self.busy else { return }
            self.pending = nil; self.busy = false
            self.announce(self.message)
        }
    }

    func restart(sameSky: Bool) {
        settlePresentation()
        game = StarfallExperiment(seed: sameSky ? game.seed : UInt64.random(in: 0...UInt64.max))
        message = sameSky ? "Same sky, a fresh start. Try a different choice." : "A new sky. Invite the first shower."
        save(); presenter.render(game)
    }

    func setSuspended(_ value: Bool) {
        suspended = value
        if value { settlePresentation() }
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
    }

    private func save() {
        if let data = try? JSONEncoder().encode(game) { defaults.set(data, forKey: Self.saveKey) }
    }

    private func announce(_ text: String) {
        if UIAccessibility.isVoiceOverRunning { UIAccessibility.post(notification: .announcement, argument: text) }
    }
}
#endif
