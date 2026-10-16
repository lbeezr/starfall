import SwiftUI
import SpriteKit
import StarfallCore

@main struct StarfallApp: App {
    var body: some Scene { WindowGroup { StarfallView() } }
}

@MainActor final class GameStore: ObservableObject {
    @Published private(set) var game: Game
    @Published var message = "Tap 3 or more touching jewels"
    @Published var busy = false
    @Published var playing = false
    @Published var settings = false
    @AppStorage("soundEnabled") var soundEnabled = false
    @AppStorage("calmEffects") var calmEffects = false
    let scene = JewelScene()
    private let saveKey = "starfall.game.v1"
    init() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--reset-save") { UserDefaults.standard.removeObject(forKey: "starfall.game.v1") }
        if arguments.contains("--demo") {
            game = Game(seed: 42); playing = true
            if arguments.contains("--demo-clear"), let cell = (0..<49).map({ Cell($0 / 7, $0 % 7) }).first(where: { game.group(at: $0).count >= 3 }) {
                game.tap(cell)
                message = "Demo: first cluster cleared and settled"
            }
        } else if let data = UserDefaults.standard.data(forKey: "starfall.game.v1"),
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
        }
        scene.store = self
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
    }
    func start() {
        save() // Preserve the initial board even if the app closes before the first move.
        playing = true; scene.render(game)
    }
    /// Rules commit before animation. Interrupted presentation settles to that committed state.
    func settlePresentation() {
        scene.removeAllActions()
        scene.render(game) // Replaces animated children as well as their pending visual actions.
        busy = false
    }
    func updateReducedMotion(_ enabled: Bool) {
        scene.reduceMotion = enabled
        if enabled { settlePresentation() }
    }
    func restart() {
        scene.removeAllActions(); busy = false
        game = Game(seed: UInt64.random(in: 0...UInt64.max))
        message = "A fresh sky. Find your first cluster"
        save(); scene.render(game)
    }
    func tap(_ cell: Cell) {
        guard !busy, game.outcome == .playing else { return }
        let old = game
        guard let turn = game.tap(cell) else {
            message = "Find at least 3 matching jewels touching sideways or vertically"
            scene.nudge(cell); return
        }
        busy = true; save()
        message = turn.reshuffled ? "A fresh cluster appeared. No extra move used" : "+\(turn.cleared.count) starlight"
        if game.outcome == .won { message = "You lit the sky!" }
        if game.outcome == .lost { message = "A lovely attempt. Try a fresh sky" }
        scene.animate(turn: turn, old: old, new: game) { [weak self] in self?.busy = false }
    }
    private func save() {
        guard !ProcessInfo.processInfo.arguments.contains("--demo") else { return }
        if let data = try? JSONEncoder().encode(game) { UserDefaults.standard.set(data, forKey: saveKey) }
    }
}

struct StarfallView: View {
    @StateObject private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.035, green: 0.055, blue: 0.17), Color(red: 0.18, green: 0.10, blue: 0.29)], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            if store.playing { gameView } else { menu }
        }
        .preferredColorScheme(.dark)
        .onChange(of: reduceMotion, initial: true) { _, value in store.updateReducedMotion(value || store.calmEffects) }
        .onChange(of: store.calmEffects) { _, value in store.updateReducedMotion(value || reduceMotion) }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.settlePresentation() }
        }
        .sheet(isPresented: $store.settings) {
            NavigationStack {
                Form {
                    Toggle("Gentle sound", isOn: $store.soundEnabled).accessibilityIdentifier("settings.sound")
                    Toggle("Calm effects", isOn: $store.calmEffects).accessibilityIdentifier("settings.calm")
                    Text("No timer. No purchases or ads. Your game stays on this device.")
                }.navigationTitle("Settings").toolbar { Button("Done") { store.settings = false }.accessibilityIdentifier("settings.done") }
            }.presentationDetents([.medium])
        }
    }
    private var menu: some View {
        VStack(spacing: 24) {
            Text("✦").font(.system(size: 72)).foregroundStyle(.cyan.opacity(0.8)).accessibilityHidden(true)
            Text("Starfall").font(.system(size: 52, weight: .light, design: .rounded))
            Text("A little light, one cluster at a time").foregroundStyle(.secondary)
            Text("Clear 70 jewels in 18 moves.\nTap groups of 3 or more matching jewels\nconnected horizontally or vertically.").multilineTextAlignment(.center)
            Button(store.game.moves < Game.startingMoves ? "Continue" : "Play") { store.start() }.accessibilityIdentifier("menu.play").buttonStyle(.borderedProminent).tint(.indigo).controlSize(.large)
            Button("Settings") { store.settings = true }.accessibilityIdentifier("menu.settings")
        }.padding(24)
    }
    private var gameView: some View {
        VStack(spacing: 14) {
            HStack {
                Button("Menu") { store.playing = false }.disabled(store.busy).accessibilityIdentifier("game.menu")
                Spacer()
                Text("Starfall").font(.title2.weight(.light))
                Spacer()
                Button { store.settings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings").accessibilityIdentifier("game.settings")
            }
            HStack {
                Label("\(store.game.score) / 70", systemImage: "sparkle")
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(store.game.score) of \(Game.target) jewels cleared")
                    .accessibilityIdentifier("game.score")
                Spacer()
                Text("\(store.game.moves) moves").monospacedDigit().accessibilityIdentifier("game.moves")
            }.font(.headline)
            ProgressView(value: Double(min(store.game.score, Game.target)), total: Double(Game.target)).tint(.cyan)
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(.white.opacity(0.04))
                    // A frame marker only: coordinate taps still reach the SpriteKit view.
                    .accessibilityElement().accessibilityLabel("Jewel board")
                    .accessibilityIdentifier("game.board").accessibilityHidden(voiceOver)
                SpriteView(scene: store.scene, options: [.allowsTransparency])
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .opacity(voiceOver ? 0 : 1)
                    .accessibilityHidden(true)
                if voiceOver { accessibleBoard }
            }.aspectRatio(1, contentMode: .fit)
            Text(store.message).font(.callout).multilineTextAlignment(.center).frame(minHeight: 44).accessibilityLabel(store.message).accessibilityIdentifier("game.message")
            if store.game.outcome != .playing {
                Text(store.game.outcome == .won ? "Sky illuminated" : "Out of moves").font(.title2)
            }
            Button("New game") { store.restart() }.buttonStyle(.bordered).disabled(store.busy).accessibilityIdentifier("game.restart")
            Spacer(minLength: 0)
        }.padding(20).frame(maxWidth: 560)
    }
    private var accessibleBoard: some View {
        VStack(spacing: 2) {
            ForEach((0..<Game.side).reversed(), id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<Game.side, id: \.self) { column in
                        let cell = Cell(row, column)
                        let kind = store.game.jewel(at: cell)!
                        Button { store.tap(cell) } label: {
                            Text(kind.symbol).frame(maxWidth: .infinity, maxHeight: .infinity).foregroundStyle(Color(kind.color))
                        }
                        .accessibilityLabel("\(kind.label), row \(Game.side-row), column \(column+1)")
                        .accessibilityValue("\(store.game.group(at: cell).count) connected")
                        .accessibilityHint("Activate to clear a matching group of at least three")
                        .disabled(store.busy || store.game.outcome != .playing)
                    }
                }
            }
        }.padding(10)
    }
}
