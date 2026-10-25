import SwiftUI
import StarfallCore

/// One ordered, immutable view of the committed forecast. Column numbers remain
/// attached to their actual stars, including repeated destinations.
struct SkyForecastSnapshot: Equatable, Sendable {
    struct Entry: Equatable, Sendable, Identifiable {
        let id: Int
        let family: SkyIdentity
        let column: Int
    }

    let entries: [Entry]

    init(forecast: [IncomingStar]) {
        entries = forecast.map { Entry(id: $0.id, family: $0.identity, column: $0.column + 1) }
    }

    @MainActor var accessibilityValue: String {
        let descriptions = entries.map { entry in
            SkyCopy.text(.forecastDestination, values: [
                "star": SkyPiece.description(for: .init(entry.family)),
                "column": String(entry.column)
            ])
        }
        guard let first = descriptions.first else { return "" }
        return descriptions.dropFirst().reduce(first) { summary, next in
            SkyCopy.text(.forecastDestinationList, values: ["first": summary, "next": next])
        }
    }
}

/// The shower trail's native destinations can identify an actual column without
/// predicting whether a landing will grow, clear a pattern or block.
@MainActor struct SkyForecastDestinations: View {
    let forecast: [IncomingStar]
    let arriving: Bool
    var selectedID: Int? = nil
    var select: (Int) -> Void = { _ in }
    var inspectShower: (() -> Void)? = nil
    var inspectionEnabled = true
    @ScaledMetric(relativeTo: .caption) private var minimumChipWidth: CGFloat = 32

    var stateLabel: String {
        SkyCopy.text(arriving ? .forecastArrivingColumns : .forecastNextColumns)
    }

    var body: some View {
        let snapshot = SkyForecastSnapshot(forecast: forecast)
        if !snapshot.entries.isEmpty {
            HStack(alignment: .top, spacing: StarfallTheme.Spacing.small) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: StarfallTheme.Spacing.small) {
                        title
                        HStack(spacing: StarfallTheme.Spacing.small) { chips(snapshot) }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                        title
                        HStack(spacing: StarfallTheme.Spacing.small) { chips(snapshot) }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                        title
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: max(44, minimumChipWidth)),
                                                      spacing: StarfallTheme.Spacing.small,
                                                      alignment: .leading)],
                                  alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                            chips(snapshot)
                        }
                    }
                }
                if let inspectShower {
                    Button(action: inspectShower) {
                        ObservatoryIcon(.help, size: StarfallTheme.Layout.hudSymbolSide)
                    }
                    .buttonStyle(StarfallUtilityButtonStyle())
                    .disabled(!inspectionEnabled)
                    .accessibilityLabel(SkyCopy.text(.showerInspectionAction))
                    .accessibilityIdentifier("sky.showerInspection.open")
                }
            }
            .font(StarfallTheme.Typography.skyCaption)
            .foregroundStyle(StarfallTheme.Colors.textSecondary)
            .starfallSceneryProtection()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(stateLabel)
            .accessibilityValue(snapshot.accessibilityValue)
            .accessibilityHint(SkyCopy.text(.forecastColumnsHint))
            .accessibilityIdentifier("sky.forecast.destinations")
        }
    }

    private var title: some View {
        Text(stateLabel)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func chips(_ snapshot: SkyForecastSnapshot) -> some View {
        ForEach(snapshot.entries) { entry in
            Button { select(entry.id) } label: {
                HStack(spacing: StarfallTheme.Spacing.compact) {
                    Image(uiImage: SkyPiece.image(for: .init(entry.family)))
                        .resizable().scaledToFit().frame(width: 18, height: 18)
                        .accessibilityHidden(true)
                    Text(String(entry.column))
                        .monospacedDigit()
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
            .buttonStyle(StarfallGameButtonStyle(role: .forecast(selected: selectedID == entry.id)))
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(SkyCopy.text(.forecastDestination, values: [
                "star": SkyPiece.description(for: .init(entry.family)), "column": String(entry.column)
            ]))
            .accessibilityHint(SkyCopy.text(.forecastInspectHint))
            .accessibilityAddTraits(selectedID == entry.id ? .isSelected : [])
            .accessibilityIdentifier("sky.forecast.star.\(entry.id)")
        }
    }
}
