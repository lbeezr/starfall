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
        HStack(spacing: 12) {
            Button(action: done) {
                HStack {
                    Image(systemName: "chevron.left").font(.system(size: 20, weight: .semibold))
                    if !textSize.isAccessibilitySize { Text(SkyCopy.text(.worldBack)) }
                }.frame(minWidth: 44, minHeight: 44)
            }.accessibilityLabel(SkyCopy.text(.worldBack)).accessibilityIdentifier("world.done")
            Spacer(minLength: 0)
            Button(action: { list.toggle() }) {
                Label(SkyCopy.text(list ? .worldMap : .worldPlaces), systemImage: list ? "map" : "list.bullet")
                    .labelStyle(.iconOnly).font(.system(size: 20, weight: .semibold)).frame(width: 44, height: 44)
            }.accessibilityIdentifier("world.list")
            Button(action: learn) {
                Label(SkyCopy.text(.practiceTitle), systemImage: "book.closed")
                    .labelStyle(.iconOnly).font(.system(size: 20, weight: .semibold)).frame(width: 44, height: 44)
            }.accessibilityIdentifier("world.learn")
        }
        .font(.headline).foregroundStyle(StarfallTheme.Colors.actionPrimary)
        .buttonStyle(.plain).padding(.horizontal, 20).padding(.vertical, 4)
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
        .frame(maxWidth: StarfallTheme.Layout.menuWidth, alignment: .leading)
        .padding(.horizontal, 24).padding(.top, 12)
        .frame(maxWidth: .infinity)
    }
    private var locations: some View {
        VStack(spacing: 0) {
            ForEach(WorldLocation.allCases) { location in
                Button { choose(location) } label: {
                    HStack {
                        Image(systemName: journey.completed.contains(location) ? "sparkle" : journey.canEnter(location) ? "moon" : "cloud.fog").accessibilityHidden(true)
                        VStack(alignment: .leading) {
                            Text(location.title).font(.headline)
                            Text(location.status(in: journey)).font(.subheadline)
                        }
                        Spacer()
                        if selected == location { Image(systemName: "checkmark.circle.fill") }
                    }.frame(minHeight: 54).padding(.horizontal).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("world.place.\(location.id)")
                Divider()
            }
        }
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
