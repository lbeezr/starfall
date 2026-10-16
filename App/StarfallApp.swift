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
        if let terminalMessage { message = terminalMessage }
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = 52.0
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
                    // A Form switch reserves trailing width. Let its label wrap to
                    // its full ideal height instead of clipping at accessibility sizes.
                    Toggle(isOn: $store.soundEnabled) {
                        Text("Gentle sound").fixedSize(horizontal: false, vertical: true)
                    }.accessibilityIdentifier("settings.sound")
                    Toggle(isOn: $store.calmEffects) {
                        Text("Calm effects").fixedSize(horizontal: false, vertical: true)
                    }.accessibilityIdentifier("settings.calm")
                    Text("No timer. No purchases or ads. Your game stays on this device.")
                        .fixedSize(horizontal: false, vertical: true)
                }.navigationTitle("Settings").toolbar {
                    Button { store.settings = false } label: {
                        Text("Done").frame(minWidth: 44, minHeight: 44)
                    }.accessibilityIdentifier("settings.done")
                }
            }.presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        }
    }
    // Keep ordinary layouts centered and allow larger text to scroll instead of
    // shrinking the board or compressing essential controls below the viewport.
    private var menu: some View {
        GeometryReader { geometry in
            ScrollView {
                menuContent
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
        }
    }
    private var menuContent: some View {
        VStack(spacing: 24) {
            Text("✦").font(.system(size: 72)).foregroundStyle(.cyan.opacity(0.8)).accessibilityHidden(true)
            Text("Starfall").font(.system(size: titleSize, weight: .light, design: .rounded))
            Text("A little light, one cluster at a time").foregroundStyle(.secondary)
            Text("Clear 70 jewels in 18 moves.\nTap groups of 3 or more matching jewels\nconnected horizontally or vertically.").multilineTextAlignment(.center)
            Button(store.game.moves < Game.startingMoves ? "Continue" : "Play") { store.start() }.accessibilityIdentifier("menu.play").buttonStyle(.borderedProminent).tint(.indigo).controlSize(.large)
            Button { store.settings = true } label: {
                Text("Settings").frame(minWidth: 44, minHeight: 44)
            }.accessibilityIdentifier("menu.settings")
        }.padding(24)
    }
    private var gameView: some View {
        GeometryReader { geometry in
            ScrollView {
                gameContent
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .frame(maxWidth: .infinity)
            }
        }
    }
    private var gameContent: some View {
        VStack(spacing: 14) {
            if dynamicTypeSize.isAccessibilitySize {
                Text("Starfall").font(.title2.weight(.light))
            }
            HStack {
                Button { store.playing = false } label: {
                    Text("Menu").frame(minWidth: 44, minHeight: 44)
                }.disabled(store.busy).accessibilityIdentifier("game.menu")
                Spacer()
                if !dynamicTypeSize.isAccessibilitySize {
                    Text("Starfall").font(.title2.weight(.light))
                    Spacer()
                }
                Button { store.settings = true } label: {
                    Image(systemName: "gearshape").frame(minWidth: 44, minHeight: 44)
                }.accessibilityLabel("Settings").accessibilityIdentifier("game.settings")
            }
            // At larger sizes the two statistics stack without truncation.
            let statisticsLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout())
            statisticsLayout {
                Label("\(store.game.score) / 70", systemImage: "sparkle")
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(store.game.score) of \(Game.target) jewels cleared")
                    .accessibilityIdentifier("game.score")
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                Text("\(store.game.moves) moves").monospacedDigit().accessibilityIdentifier("game.moves")
            }.font(.headline)
            ProgressView(value: Double(min(store.game.score, Game.target)), total: Double(Game.target))
                .tint(.cyan)
                // The thin bar needs a larger area for accessible touch exploration.
                .frame(minHeight: 44).contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Starlight progress")
                .accessibilityValue("\(min(store.game.score, Game.target)) of \(Game.target)")
                .accessibilityIdentifier("game.progress")
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
                Text(store.game.outcome == .won ? "Sky illuminated" : "Out of moves").font(.title2).accessibilityIdentifier("game.outcome")
            }
            Button { store.restart() } label: {
                Text("New game").frame(minWidth: 44, minHeight: 44)
            }.buttonStyle(.bordered).disabled(store.busy).accessibilityIdentifier("game.restart")
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
