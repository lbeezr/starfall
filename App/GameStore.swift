import SwiftUI
import SpriteKit
import StarfallCore

/// The store commits rules and persistence; presentation may finish now or later.
/// This boundary lets tests control completion without depending on frame timing.
@MainActor protocol TurnPresenting: AnyObject {
    var reduceMotion: Bool { get set }
    func render(_ game: Game)
    func nudge(_ cell: Cell)
    func cancelAnimations()
    func animate(turn: Turn, old: Game, new: Game, completion: @escaping () -> Void)
}

@MainActor final class GameStore: ObservableObject {
    @Published private(set) var game: Game
    @Published var message = "Tap 3 or more touching jewels"
    @Published private(set) var busy = false
    @Published var playing = false
    @Published var settings = false
    @AppStorage("soundEnabled") var soundEnabled = false
    @AppStorage("calmEffects") var calmEffects = false
    let scene: JewelScene
    private let presenter: any TurnPresenting
    private let defaults: UserDefaults
    private let arguments: [String]
    private var activeTurnID: UUID?
    private let saveKey = "starfall.game.v1"
    init(defaults: UserDefaults = .standard,
         arguments: [String] = ProcessInfo.processInfo.arguments,
         presenter: (any TurnPresenting)? = nil) {
        let scene = JewelScene()
        self.scene = scene
        self.defaults = defaults
        self.arguments = arguments
        self.presenter = presenter ?? scene
        _soundEnabled = AppStorage(wrappedValue: false, "soundEnabled", store: defaults)
        _calmEffects = AppStorage(wrappedValue: false, "calmEffects", store: defaults)
        if arguments.contains("--reset-save") { defaults.removeObject(forKey: "starfall.game.v1") }
        if arguments.contains("--demo") {
            game = Game(seed: 42); playing = true
            if arguments.contains("--demo-clear"), let cell = (0..<49).map({ Cell($0 / 7, $0 % 7) }).first(where: { game.group(at: $0).count >= 3 }) {
                game.tap(cell)
                message = "Demo: first cluster cleared and settled"
            }
        } else if let data = defaults.data(forKey: "starfall.game.v1"),
           let saved = try? JSONDecoder().decode(Game.self, from: data), saved.isValidSave {
            game = saved
        } else {
            // A deterministic fresh-game fallback for native tests; never overrides a save.
            // Release builds always choose a random seed.
            var seed = UInt64.random(in: 0...UInt64.max)
            #if DEBUG
            if let argument = arguments.first(where: { $0.hasPrefix("--seed=") }),
               let testSeed = UInt64(argument.dropFirst("--seed=".count)) { seed = testSeed }
            #endif
            game = Game(seed: seed)
            #if DEBUG
            if let argument = arguments.first(where: { $0.hasPrefix("--endgame-seed=") }),
               let testSeed = UInt64(argument.dropFirst("--endgame-seed=".count)) {
                game = Self.beforeTerminalTurn(seed: testSeed)
            }
            #endif
        }
        if let terminalMessage { message = terminalMessage }
        scene.store = self
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
    }
    private var terminalMessage: String? {
        switch game.outcome {
        case .won: "You lit the sky!"
        case .lost: "A lovely attempt. Try a fresh sky"
        case .playing: nil
        }
    }
    #if DEBUG
    /// Native acceptance fixture: replay legal rules, stopping before the terminal tap.
    /// This is not a balancing test or a customization surface in Release builds.
    private static func beforeTerminalTurn(seed: UInt64) -> Game {
        var game = Game(seed: seed)
        for _ in 0..<Game.startingMoves {
            guard let cell = (0..<(Game.side * Game.side)).map({ Cell($0 / Game.side, $0 % Game.side) })
                .first(where: { game.group(at: $0).count >= 3 }) else { break }
            var next = game
            next.tap(cell)
            if next.outcome != .playing { return game }
            game = next
        }
        assertionFailure("Expected a terminal turn within the move budget")
        return game
    }
    #endif
    func start() {
        save() // Preserve the initial board even if the app closes before the first move.
        playing = true; presenter.render(game)
    }
    /// Rules commit before animation. Interrupted presentation settles to that committed state.
    func settlePresentation() {
        activeTurnID = nil
        presenter.cancelAnimations()
        presenter.render(game) // Replaces animated children as well as their pending visual actions.
        busy = false
    }
    func updateReducedMotion(_ enabled: Bool) {
        presenter.reduceMotion = enabled
        if enabled { settlePresentation() }
    }
    func restart() {
        activeTurnID = nil
        presenter.cancelAnimations(); busy = false
        game = Game(seed: UInt64.random(in: 0...UInt64.max))
        message = "A fresh sky. Find your first cluster"
        save(); presenter.render(game)
    }
    func tap(_ cell: Cell) {
        guard !busy, game.outcome == .playing else { return }
        let old = game
        guard let turn = game.tap(cell) else {
            message = "Find at least 3 matching jewels touching sideways or vertically"
            presenter.nudge(cell); return
        }
        let turnID = UUID()
        activeTurnID = turnID
        busy = true; save()
        message = turn.reshuffled ? "A fresh cluster appeared. No extra move used" : "+\(turn.cleared.count) starlight"
        if let terminalMessage { message = terminalMessage }
        presenter.animate(turn: turn, old: old, new: game) { [weak self] in
            guard let self, self.activeTurnID == turnID else { return }
            self.activeTurnID = nil
            self.busy = false
        }
    }
    private func save() {
        guard !arguments.contains("--demo") else { return }
        if let data = try? JSONEncoder().encode(game) { defaults.set(data, forKey: saveKey) }
    }
}

