import SwiftUI
import SpriteKit
import StarfallCore

@main struct StarfallApp: App {
    var body: some Scene { WindowGroup { StarfallView() } }
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
                        Text("Gentle sound").fixedSize(horizontal: false, vertical: true).padding(.vertical, 4)
                    }.accessibilityIdentifier("settings.sound")
                    Toggle(isOn: $store.calmEffects) {
                        Text("Calm effects").fixedSize(horizontal: false, vertical: true).padding(.vertical, 4)
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
