import SwiftUI
import StarfallCore

/// A read-only view of the existing round. No local score, timing or outcome state.
struct StarlightHUD: View {
    let score: Int
    let moves: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var progress: Int { min(max(score, 0), Game.target) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if dynamicTypeSize.isAccessibilitySize {
                stackedStatistics
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: StarfallTheme.Spacing.medium) {
                        scoreLabel.fixedSize()
                        Spacer(minLength: StarfallTheme.Spacing.medium)
                        movesLabel.fixedSize()
                    }
                    stackedStatistics
                }
            }

            ProgressView(value: Double(progress), total: Double(Game.target))
                .progressViewStyle(StarfallProgressStyle())
                .frame(minHeight: StarfallTheme.Layout.minimumTarget)
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Starlight progress")
                .accessibilityValue("\(progress) of \(Game.target)")
                .accessibilityIdentifier("game.progress")
        }
        .foregroundStyle(StarfallTheme.Colors.textPrimary)
        // Even an inherited game transaction must not animate the authoritative HUD.
        // Both Reduce Motion and Calm effects therefore receive the same settled view.
        .transaction { $0.animation = nil }
    }

    private var stackedStatistics: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            scoreLabel
            movesLabel
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scoreLabel: some View {
        Text("Starlight · \(score) / \(Game.target)")
            .font(StarfallTheme.Typography.heading)
            .monospacedDigit()
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .ignore)
            // Preserve the current screen-reader and native test contract.
            .accessibilityLabel("\(score) of \(Game.target) jewels cleared")
            .accessibilityIdentifier("game.score")
    }

    private var movesLabel: some View {
        Text(moves == 1 ? "1 move" : "\(moves) moves")
            .font(StarfallTheme.Typography.heading)
            .monospacedDigit()
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("game.moves")
    }
}
