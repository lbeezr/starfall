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

/// A passive native companion to the shower trail. It exposes destinations
/// without predicting whether a landing will grow, clear a pattern or block.
struct SkyForecastDestinations: View {
    let forecast: [IncomingStar]
    let arriving: Bool
    @ScaledMetric(relativeTo: .caption) private var minimumChipWidth: CGFloat = 32

    var stateLabel: String {
        SkyCopy.text(arriving ? .forecastArrivingColumns : .forecastNextColumns)
    }

    var body: some View {
        let snapshot = SkyForecastSnapshot(forecast: forecast)
        if !snapshot.entries.isEmpty {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: StarfallTheme.Spacing.small) {
                    title
                    HStack(spacing: StarfallTheme.Spacing.small) { chips(snapshot) }
                }
                .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                    title
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumChipWidth),
                                                  spacing: StarfallTheme.Spacing.small,
                                                  alignment: .leading)],
                              alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                        chips(snapshot)
                    }
                }
            }
            .font(StarfallTheme.Typography.skyCaption)
            .foregroundStyle(StarfallTheme.Colors.textSecondary)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(stateLabel)
            .accessibilityValue(snapshot.accessibilityValue)
            .accessibilityHint(SkyCopy.text(.forecastColumnsHint))
            .accessibilityIdentifier("sky.forecast.destinations")
            .allowsHitTesting(false)
        }
    }

    private var title: some View {
        Text(stateLabel)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func chips(_ snapshot: SkyForecastSnapshot) -> some View {
        ForEach(snapshot.entries) { entry in
            HStack(spacing: StarfallTheme.Spacing.compact) {
                Image(uiImage: SkyPiece.image(for: .init(entry.family)))
                    .resizable().scaledToFit().frame(width: 18, height: 18)
                    .accessibilityHidden(true)
                Text(String(entry.column))
                    .monospacedDigit()
                    .fixedSize(horizontal: true, vertical: false)
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
}
