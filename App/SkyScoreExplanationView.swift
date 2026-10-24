import SwiftUI

/// Static reading of already-earned values; no award, clock or replay capability.
struct SkyScoreExplanationView: View {
    let explanation: SkyScoreExplanation
    var survivorCount: Int = 0

    var body: some View {
        VStack(spacing: StarfallTheme.Spacing.small) {
            Text(SkyCopy.text(.scoreExplanationTitle)).accessibilityAddTraits(.isHeader)
            if let fact = SkySurvivorCopy.fact(survivorCount) {
                Text(fact).accessibilityIdentifier("score.survivors")
            }
            ForEach(Array(explanation.phases.enumerated()), id: \.offset) { index, phase in
                Text(phase.explanationText)
                    .accessibilityIdentifier("score.phase.\(index + 1)")
            }
            if explanation.phases.count > 1 {
                Text(explanation.totalText)
                    .accessibilityIdentifier("score.total")
            }
        }
        .font(StarfallTheme.Typography.supporting)
        .foregroundStyle(StarfallTheme.Colors.textPrimary)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("score.explanation")
    }
}

/// The same bounded live-label composition is renderable without a running clock.
struct SkyScoreReceiptLabel: View {
    let event: StarlightCelebration
    let tint: Color
    let width: CGFloat
    let height: CGFloat
    let age: TimeInterval
    let quiet: Bool
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        CrystalCelebrationLabel(event: event, tint: tint, width: width, height: max(0,height),
                                showsTitle: !textSize.isAccessibilitySize, age: age, quiet: quiet)
            .frame(width: max(0,width),height:max(0,height))
    }
}
