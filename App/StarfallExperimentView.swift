#if DEBUG
import SwiftUI
import SpriteKit
import StarfallCore

@MainActor struct StarfallExperimentView: View {
    @State private var store = StarfallExperimentStore()
    @State private var settings = false
    @AppStorage("calmEffects") private var calmEffects = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Namespace private var matchingGroups

    var body: some View {
        ZStack {
            NightSkyBackdrop()
            ScrollView {
                VStack(spacing: 14) {
                    HStack {
                        Button("Close") { store.setSuspended(true); dismiss() }
                            .accessibilityIdentifier("experiment.close")
                        Spacer()
                        Text("Starfall").font(StarfallTheme.Typography.title)
                        Spacer()
                        Button { settings = true } label: { Image(systemName: "gearshape") }
                            .accessibilityLabel("Settings").accessibilityIdentifier("experiment.settings")
                    }
                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                    Text("ACCUMULATION EXPERIMENT")
                        .font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                    HStack {
                        Text("\(store.game.score) starlight").accessibilityIdentifier("experiment.score")
                        Spacer()
                        Text("\(store.game.turns) showers").accessibilityIdentifier("experiment.turns")
                    }
                    .font(StarfallTheme.Typography.heading).monospacedDigit()
                    forecast
                    board
                    if store.game.isOver {
                        Text("This sky is full")
                            .font(StarfallTheme.Typography.title)
                            .accessibilityAddTraits(.isHeader).accessibilityIdentifier("experiment.outcome")
                    }
                    Text(store.message)
                        .font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("experiment.message")
                    Button("Let stars fall") { store.inviteShower() }
                        .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))
                        .disabled(store.busy || store.suspended || store.game.isOver)
                        .accessibilityIdentifier("experiment.invite")
                    HStack {
                        Button("Replay this sky") { store.restart(sameSky: true) }
                            .accessibilityIdentifier("experiment.replay")
                        Spacer()
                        Button("New sky") { store.restart(sameSky: false) }
                            .accessibilityIdentifier("experiment.new")
                    }
                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                    Text("Clear matching jewels worth 3+. Large jewels count as 2. Every clear brings a shower. No timer.")
                        .font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                }
                .padding(16).frame(maxWidth: StarfallTheme.Layout.contentWidth)
                .frame(maxWidth: .infinity)
            }
            .accessibilityHidden(settings)
        }
        .preferredColorScheme(.dark)
        .tint(StarfallTheme.Colors.actionPrimary)
        .onAppear { store.setSuspended(false); store.settlePresentation(); updateMotion() }
        .onDisappear { store.setSuspended(true) }
        .onChange(of: scenePhase) { _, phase in store.setSuspended(phase != .active || settings) }
        .onChange(of: settings) { _, shown in store.setSuspended(shown || scenePhase != .active) }
        .onChange(of: reduceMotion) { updateMotion() }
        .onChange(of: voiceOver) { updateMotion() }
        .onChange(of: calmEffects) { updateMotion() }
        .sheet(isPresented: $settings) { settingsView }
    }

    private func updateMotion() { store.setReducedMotion(reduceMotion || calmEffects || voiceOver) }

    private var forecast: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(store.game.isOver ? "Replay to try another approach" : "Next shower · left to right")
                .font(StarfallTheme.Typography.supporting)
            if !store.game.isOver {
                HStack(spacing: 12) {
                    ForEach(store.forecast) { star in
                        HStack(spacing: 6) {
                            Text(star.kind.symbol).font(.title2).foregroundStyle(Color(star.kind.color))
                            Text("↓ \(star.column + 1)").font(.headline).monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(star.kind.label), column \(star.column + 1)")
                        .accessibilityIdentifier("experiment.incoming.\(star.id % 3)")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .starfallPanel(inset: 12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("experiment.forecast")
    }

    private var board: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(1...7, id: \.self) { column in
                    Text("\(column)").font(.caption).frame(maxWidth: .infinity)
                }
            }
            .foregroundStyle(StarfallTheme.Colors.textSecondary)
            .padding(.horizontal, 16).accessibilityHidden(true)
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: StarfallTheme.Radius.board)
                        .fill(StarfallTheme.Colors.surface)
                    SpriteView(scene: store.scene, options: [.allowsTransparency])
                        .allowsHitTesting(false).accessibilityHidden(true)
                    VStack(spacing: 0) {
                        ForEach((0..<7).reversed(), id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<7, id: \.self) { column in cellButton(Cell(row, column)) }
                            }
                        }
                    }
                    .padding(geometry.size.width * 0.35 / 7.7)
                }
                .clipShape(RoundedRectangle(cornerRadius: StarfallTheme.Radius.board))
            }
            .aspectRatio(1, contentMode: .fit)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Starfall board, seven columns. Row one is the top.")
            .accessibilityIdentifier("experiment.board")
            .accessibilityRotor("Matching groups") {
                ForEach(store.game.legalGroups.compactMap(\.first), id: \.self) { cell in
                    AccessibilityRotorEntry(Text(cellLabel(cell)), id: cell, in: matchingGroups)
                }
            }
        }
    }

    private func cellButton(_ cell: Cell) -> some View {
        let group = store.game.group(at: cell)
        let value = store.game.value(of: group)
        return Button { store.clear(cell) } label: {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cellLabel(cell))
        .accessibilityValue("\(value) starlight connected")
        .accessibilityHint(value >= 3 ? "Clear this group, then the forecast shower arrives" : "Needs matching jewels worth three. Large jewels count as two. No turn will be used")
        .accessibilityIdentifier("experiment.cell.\(cell.row).\(cell.column)")
        .accessibilityRotorEntry(id: cell, in: matchingGroups)
        .disabled(store.busy || store.suspended || store.game.isOver)
    }

    private func cellLabel(_ cell: Cell) -> String {
        let position = "row \(7-cell.row), column \(cell.column+1)"
        guard let gem = store.game.gem(at: cell) else { return "Empty, \(position)" }
        return "\(gem.kind.label), value \(gem.value), \(position)"
    }

    private var settingsView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Calm effects", isOn: $calmEffects)
                        .accessibilityIdentifier("experiment.calm")
                    Text("Three stars arrive after every clear or invitation, in the previewed order and columns.")
                    Text("A star matching the small jewel on top grows it to value 2. A grown jewel cannot grow again, so the next star stacks above it.")
                    Text("Clear connected matching jewels worth at least 3. A large jewel counts as 2, so a large jewel beside one small match can clear. Collect their combined value as starlight.")
                    Text("Make room before a star reaches a full column. There is no timer. Replay a sky to try different choices.")
                }
                .font(StarfallTheme.Typography.body).padding(20)
                .fixedSize(horizontal: false, vertical: true)
            }
            .background(StarfallTheme.Colors.skyTop)
            .navigationTitle("How starfalls work")
            .toolbar { Button("Done") { settings = false }.accessibilityIdentifier("experiment.done") }
        }
        .presentationDetents([.large])
    }
}
#endif
