import SwiftUI
import StarfallCore

/// Optional reading of one frozen Core evaluation; this view owns no play or clock action.
@MainActor struct SkyShowerInspectionView: View {
    let inspection: SkyShowerInspection
    let paused: Bool
    let done: () -> Void

    var body: some View {
        SkyMenuSurface(title: SkyCopy.text(.showerInspectionTitle), glyph: .help, done: done,
                       footerTitle: SkyCopy.text(.actionReturn)) {
            Text(SkyCopy.text(.showerInspectionSnapshot))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("sky.showerInspection.warning")
            Text(SkyCopy.text(paused ? .showerInspectionPaused : .showerInspectionRunning))
                .font(StarfallTheme.Typography.supporting)
                .foregroundStyle(StarfallTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("sky.showerInspection.status")
            if inspection.prearrivalChanges {
                Text(SkyCopy.text(.showerInspectionPrelude))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("sky.showerInspection.prelude")
            }
            ForEach(Array(inspection.steps.enumerated()), id: \.element.id) { index, step in
                SkyMenuRule()
                stepView(step, number: index + 1)
            }
            SkyMenuRule()
            Text(patternsText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("sky.showerInspection.patterns")
        }
    }

    private func stepView(_ step: SkyShowerInspection.Step, number: Int) -> some View {
        let title = SkyCopy.text(.showerInspectionStep, values: [
            "number": String(number),
            "star": SkyPiece.description(for: .init(step.star.identity)),
            "column": String(step.star.column + 1)
        ])
        let detail = effectText(step)
        return VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            HStack(alignment: .top, spacing: StarfallTheme.Spacing.small) {
                Image(uiImage: SkyPiece.image(for: .init(step.star.identity)))
                    .resizable().scaledToFit().frame(width: 24, height: 24)
                    .allowsHitTesting(false).accessibilityHidden(true)
                Text(title)
                    .font(StarfallTheme.Typography.supporting.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(detail)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title + " " + detail)
        .accessibilityIdentifier("sky.showerInspection.step.\(step.id)")
    }

    private func effectText(_ step: SkyShowerInspection.Step) -> String {
        switch step.effect {
        case .grew(let cell, let gem):
            let position = SkyCopy.boardPosition(cell)
            return SkyCopy.text(.showerInspectionGrows, values: [
                "row": String(position.row), "column": String(position.column), "light": String(gem.value)
            ])
        case .landed(let cell, _):
            let position = SkyCopy.boardPosition(cell)
            return SkyCopy.text(.showerInspectionLands, values: [
                "row": String(position.row), "column": String(position.column)
            ])
        case .blocked:
            return SkyCopy.text(.showerInspectionBlocks, values: ["column": String(step.star.column + 1)])
        case .notReached:
            return SkyCopy.text(.showerInspectionUnreached)
        }
    }

    private var patternsText: String {
        guard !inspection.phases.isEmpty else { return SkyCopy.text(.showerInspectionNoPatterns) }
        let phases = inspection.phases.enumerated().map { index, phase in
            SkyCopy.text(.showerInspectionPhase, values: [
                "number": String(index + 1), "patterns": phase.recipes.map(\.title).joined(separator: ", ")
            ])
        }
        return SkyCopy.text(.showerInspectionPatterns, values: ["patterns": phases.joined(separator: "; ")])
    }
}
