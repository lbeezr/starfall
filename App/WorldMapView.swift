import SwiftUI
import StarfallCore

extension WorldLocation {
    var title: String {
        if let challenge { return challenge.locationTitle }
        switch self {
        case .frostfruitOrchard: return SkyCopy.text(.worldFrostfruit)
        case .sunwheelMill: return SkyCopy.text(.worldSunwheel)
        case .bellChoir: return SkyCopy.text(.worldBell)
        case .starferryStation: return SkyCopy.text(.worldStarferry)
        case .auroraFalls: return SkyCopy.text(.worldAurora)
        case .petalBeacon: return SkyCopy.text(.worldPetal)
        case .hollowCrown: return SkyCopy.text(.worldCrown)
        default: return ""
        }
    }
    func status(in journey: WorldJourney) -> String {
        if challenge == nil { return SkyCopy.text(.worldUnavailable) }
        if journey.completed.contains(self) { return SkyCopy.text(.worldRestored) }
        if journey.canEnter(self) { return SkyCopy.text(.worldReady) }
        return SkyCopy.text(.worldLocked, values: ["place": predecessor?.title ?? StarfallChallenge.firstLight.locationTitle])
    }
}

/// Map and accessible list use the same identities and entry checks. Selection
/// never replaces the saved round; the existing Entry ceremony owns Begin.
struct WorldMapView: View {
    let journey: WorldJourney
    let quiet: Bool
    let recovered: Bool
    let select: (WorldLocation) -> Void
    let enter: (StarfallChallenge) -> Void
    let resume: (() -> Void)?
    let learn: () -> Void
    let done: () -> Void
    @State private var list = false
    @State private var marker: WorldLocation
    @State private var selectionRequest = 0
    @Environment(\.dynamicTypeSize) private var textSize
    init(journey: WorldJourney, quiet: Bool, recovered: Bool = false, select: @escaping (WorldLocation) -> Void,
         enter: @escaping (StarfallChallenge) -> Void, resume: (() -> Void)? = nil, learn: @escaping () -> Void, done: @escaping () -> Void) {
        self.journey = journey; self.quiet = quiet; self.recovered = recovered; self.select = select
        self.enter = enter; self.resume = resume; self.learn = learn; self.done = done
        _marker = State(initialValue: journey.canEnter(journey.selected) ? journey.selected : .firstLight)
    }
    private var selected: WorldLocation { journey.selected }
    var body: some View {
        GeometryReader { viewport in
            VStack(spacing: 0) {
                navigation
                if list || textSize.isAccessibilitySize {
                    ScrollViewReader { scroll in
                        ScrollView {
                            VStack(spacing: StarfallTheme.Spacing.section) {
                                destination.id("selection")
                                locations
                            }.padding(.vertical)
                        }
                        .onChange(of: selectionRequest) {
                            withAnimation(quiet ? nil : .easeOut(duration: 0.25)) { scroll.scrollTo("selection", anchor: .top) }
                        }
                    }
                } else if viewport.size.width > viewport.size.height {
                    HStack(spacing: 24) {
                        painting
                        ScrollView { destination }
                            .frame(width: min(360, viewport.size.width * 0.4))
                    }.padding(.horizontal, 24)
                } else {
                    painting
                    destination.padding(.bottom, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background { SkyBackdrop().ignoresSafeArea() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("world.page")
        .onChange(of: selected) { _, next in
            if journey.canEnter(next) { withAnimation(quiet ? nil : .easeInOut(duration: 0.4)) { marker = next } }
        }
    }
    private var navigation: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            if textSize.isAccessibilitySize { navigationTitle }
            HStack(spacing: 12) {
                Button(action: done) {
                    ObservatoryIcon(.back)
                }
                .buttonStyle(StarfallGameButtonStyle(tint: StarfallTheme.Colors.textPrimary))
                .accessibilityLabel(SkyCopy.text(.worldBack)).accessibilityIdentifier("world.done")
                if !textSize.isAccessibilitySize { navigationTitle }
                Spacer(minLength: 0)
                Button(action: { list.toggle() }) {
                    ObservatoryIcon(list ? .story : .list)
                }
                .buttonStyle(StarfallGameButtonStyle(tint: StarfallTheme.Colors.textPrimary))
                .accessibilityLabel(SkyCopy.text(list ? .worldMap : .worldPlaces))
                .accessibilityIdentifier("world.list")
                Button(action: learn) {
                    ObservatoryIcon(.tutorial)
                }
                .buttonStyle(StarfallGameButtonStyle(tint: StarfallTheme.Colors.textPrimary))
                .accessibilityLabel(SkyCopy.text(.practiceTitle)).accessibilityIdentifier("world.learn")
            }
        }
        .padding(.horizontal, StarfallTheme.Spacing.page)
        .padding(.vertical, StarfallTheme.Spacing.compact)
    }
    private var navigationTitle: some View {
        Text(SkyCopy.text(list || textSize.isAccessibilitySize ? .worldPlaces : .worldMap))
            .font(StarfallTheme.Typography.title)
            .foregroundStyle(StarfallTheme.Colors.textPrimary)
            .accessibilityAddTraits(.isHeader)
            .fixedSize(horizontal: false, vertical: true)
    }
    private var painting: some View {
        GeometryReader { canvas in
            WorldMapPainting(journey: journey, selected: selected, traveler: marker, quiet: quiet, select: choose)
                .frame(width: min(canvas.size.width, canvas.size.height * 2 / 3),
                       height: min(canvas.size.height, canvas.size.width * 3 / 2))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    private var destination: some View {
        VStack(alignment: .leading, spacing: 10) {
            if recovered { Text(SkyCopy.text(.worldRecovery)).font(.callout) }
            selection
        }
        .starfallPanel(inset: StarfallTheme.Spacing.large)
        .frame(maxWidth: StarfallTheme.Layout.menuWidth, alignment: .leading)
        .padding(.horizontal, 24).padding(.top, 12)
        .frame(maxWidth: .infinity)
    }
    private var locations: some View {
        VStack(spacing: 0) {
            ForEach(WorldLocation.allCases) { location in
                Button { choose(location) } label: {
                    HStack(spacing: StarfallTheme.Spacing.medium) {
                        ObservatoryIcon(journey.completed.contains(location) ? .check : journey.canEnter(location) ? .story : .lock)
                            .foregroundStyle(StarfallTheme.Ceremony.gold)
                        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                            Text(location.title).font(StarfallTheme.Typography.skyHeading)
                                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                            Text(location.status(in: journey)).font(StarfallTheme.Typography.supporting)
                                .foregroundStyle(StarfallTheme.Colors.textSecondary)
                        }
                        Spacer(minLength: StarfallTheme.Spacing.small)
                        if selected == location { ObservatoryIcon(.check, size: 20) }
                    }
                    .frame(minHeight: 54)
                    .padding(StarfallTheme.Spacing.large)
                    .background(selected == location ? StarfallTheme.Colors.surfacePressed.opacity(0.6) : .clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected == location ? .isSelected : [])
                .accessibilityIdentifier("world.place.\(location.id)")
                Divider()
            }
        }
        .frame(maxWidth: StarfallTheme.Layout.contentWidth)
        .padding(.horizontal, StarfallTheme.Spacing.page)
        .frame(maxWidth: .infinity)
    }
    private func choose(_ location: WorldLocation) {
        select(location)
        selectionRequest += 1
    }
    private var selection: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.medium) {
            Text(selected.title).font(.system(.title2, design: .serif, weight: .semibold)).foregroundStyle(StarfallTheme.Ceremony.gold).accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("world.selection")
            Text(selected.status(in: journey)).font(.subheadline).foregroundStyle(.secondary)
                .accessibilityIdentifier("world.status")
            if let challenge = selected.challenge, journey.canEnter(selected) {
                if let resume {
                    Button(SkyCopy.text(.actionContinue), action: resume)
                        .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))
                        .accessibilityIdentifier("world.resume")
                }
                Button(SkyCopy.text(resume != nil ? .worldRestart : journey.completed.contains(selected) ? .worldRevisit : .worldVisit,
                                    values: resume != nil ? [:] : ["place": selected.title])) { enter(challenge) }
                    .buttonStyle(StarfallButtonStyle(role: resume == nil ? .primary : .quiet, expands: true))
                    .accessibilityIdentifier("world.visit")
            } else if selected.challenge == nil {
                Text(SkyCopy.text(.worldComing))
            }
        }
    }
}
