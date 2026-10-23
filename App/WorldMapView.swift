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

/// Selection only inspects the journey. Entry owns Begin; visiting the map never
/// replaces a retained round or changes which destinations are unlocked.
struct WorldMapView: View {
    let journey: WorldJourney
    let quiet: Bool
    let recovered: Bool
    let accessible: Bool
    let goal: WorldMapGoalSnapshot?
    let masteryRecords: [StoryMasteryRecord]
    let select: (WorldLocation) -> Void
    let enter: (StarfallChallenge) -> Void
    let resume: (() -> Void)?
    let learn: () -> Void
    let done: () -> Void
    @Binding private var list: Bool
    @State private var selectionRequest = 0
    @State private var reservedHeights: [WorldMapReservedRegion: CGFloat] = [:]
    @State private var worldOverflows = false
    @Environment(\.dynamicTypeSize) private var textSize

    init(journey: WorldJourney, list: Binding<Bool>, quiet: Bool, recovered: Bool = false, accessible: Bool = true,
         goal: WorldMapGoalSnapshot? = nil, masteryRecords: [StoryMasteryRecord] = [],
         select: @escaping (WorldLocation) -> Void,
         enter: @escaping (StarfallChallenge) -> Void, resume: (() -> Void)? = nil, learn: @escaping () -> Void, done: @escaping () -> Void) {
        self.journey = journey; _list = list; self.quiet = quiet; self.recovered = recovered; self.accessible = accessible; self.select = select
        self.enter = enter; self.resume = resume; self.learn = learn; self.done = done; self.goal = goal
        self.masteryRecords = masteryRecords
    }
    private var selected: WorldLocation { journey.selected }

    var body: some View {
        ZStack {
            // Native scroll descendants can remain in the accessibility tree
            // beneath a full-screen cover despite an ignored/hidden parent.
            // Withdraw the interactive subtree; this owner retains Places mode
            // and measurements, and the world restores the selected destination.
            if accessible {
                mapContent
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("world.page")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { WorldMapBackdrop(quiet: quiet).ignoresSafeArea() }
        .onPreferenceChange(WorldMapReservedHeights.self) {
            if accessible && !$0.isEmpty { reservedHeights = $0 }
        }
    }

    private var mapContent: some View {
        GeometryReader { viewport in
            // Preserve full-size names and native targets when there is not room
            // for the illustrated route. The equivalent Places view is explicit.
            let wideDestination = viewport.size.width >= 900 && viewport.size.width > viewport.size.height
            // A stable footer reservation keeps overflow feedback from changing
            // the viewport it measures or the Map/Places fit decision.
            let hintHeight: CGFloat = 24
            let availableWorldHeight = viewport.size.height - (reservedHeights[.navigation] ?? 0)
                - (reservedHeights[.destination] ?? 0) - StarfallTheme.Spacing.small * 2 - hintHeight
            let placesRequired = textSize >= .xxLarge || viewport.size.height < 600 || viewport.size.width < 350
                || availableWorldHeight < WorldMapLayout.minimumViewportHeight
            let showingPlaces = list || placesRequired
            VStack(spacing: 0) {
                navigation(showingPlaces: showingPlaces, allowsMap: !placesRequired)
                if showingPlaces {
                    places(wide: wideDestination)
                } else {
                    world
                    Color.clear
                        .frame(height: hintHeight)
                        .overlay {
                            if worldOverflows {
                                Text(SkyCopy.text(.worldExplore))
                                    .font(StarfallTheme.Typography.skyCaption)
                                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(StarfallTheme.Colors.skyTop.opacity(0.7))
                                    .accessibilityIdentifier("world.explore")
                            }
                        }
                        .allowsHitTesting(false)
                    destination(wide: wideDestination).padding(.vertical, StarfallTheme.Spacing.small)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func navigation(showingPlaces: Bool, allowsMap: Bool) -> some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
            if textSize.isAccessibilitySize { navigationTitle(showingPlaces: showingPlaces) }
            HStack(spacing: StarfallTheme.Spacing.compact) {
                Button(action: done) { ObservatoryIcon(.back) }
                    .buttonStyle(StarfallUtilityButtonStyle())
                    .accessibilityLabel(SkyCopy.text(.worldBack)).accessibilityIdentifier("world.done")
                if !textSize.isAccessibilitySize { navigationTitle(showingPlaces: showingPlaces) }
                Spacer(minLength: 0)
                if allowsMap {
                    Button { list.toggle() } label: {
                        HStack(spacing: StarfallTheme.Spacing.compact) {
                            ObservatoryIcon(showingPlaces ? .story : .list, size: 18)
                            Text(SkyCopy.text(showingPlaces ? .worldMap : .worldPlaces))
                        }
                    }
                    .buttonStyle(StarfallGameButtonStyle(tint: StarfallTheme.Colors.textPrimary))
                    .accessibilityLabel(SkyCopy.text(showingPlaces ? .worldMap : .worldPlaces))
                    .accessibilityIdentifier("world.list")
                }
                Button(action: learn) { ObservatoryIcon(.tutorial) }
                    .buttonStyle(StarfallUtilityButtonStyle())
                    .accessibilityLabel(SkyCopy.text(.practiceTitle)).accessibilityIdentifier("world.learn")
            }
        }
        .padding(.horizontal, StarfallTheme.Spacing.small)
        .padding(.vertical, StarfallTheme.Spacing.compact)
        .background(StarfallTheme.Colors.skyTop.opacity(0.55))
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: WorldMapReservedHeights.self, value: [.navigation: geometry.size.height])
            }
        }
    }

    private func navigationTitle(showingPlaces: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(SkyCopy.text(showingPlaces ? .worldPlaces : .worldMap))
                .font(StarfallTheme.Typography.title)
                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
            Text(SkyCopy.text(.worldChoose))
                .font(StarfallTheme.Typography.skyCaption)
                .foregroundStyle(StarfallTheme.Colors.textSecondary)
        }.fixedSize(horizontal: false, vertical: true)
    }

    private var world: some View {
        GeometryReader { viewport in
            ScrollViewReader { scroll in
                ScrollView(.vertical) {
                    WorldMapPainting(journey: journey, selected: selected, quiet: quiet, select: choose,
                                     maximumNodeHeight: max(0, viewport.size.height - WorldMapLayout.targetViewportInset * 2))
                        .frame(maxWidth: .infinity, minHeight: viewport.size.height)
                        .background {
                            GeometryReader { content in
                                Color.clear.preference(key: WorldMapOverflow.self,
                                                       value: content.size.height > viewport.size.height + 1)
                            }
                        }
                }
                .accessibilityIdentifier("world.canvas")
                .onPreferenceChange(WorldMapOverflow.self) { worldOverflows = $0 }
                .onAppear { scroll.scrollTo(selected.challenge == nil ? .firstLight : selected, anchor: .center) }
                .onChange(of: selected) {
                    guard selected.challenge != nil else { return }
                    withAnimation(quiet ? nil : .easeOut(duration: 0.25)) {
                        scroll.scrollTo(selected, anchor: .center)
                    }
                }
                .onChange(of: viewport.size) {
                    scroll.scrollTo(selected.challenge == nil ? .firstLight : selected, anchor: .center)
                }
            }
        }
    }

    private func places(wide: Bool) -> some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(spacing: StarfallTheme.Spacing.small) {
                    destination(wide: wide).id("selection")
                    locations
                }.padding(.vertical, StarfallTheme.Spacing.small)
            }
            .onChange(of: selectionRequest) {
                withAnimation(quiet ? nil : .easeOut(duration: 0.25)) { scroll.scrollTo("selection", anchor: .top) }
            }
        }
    }

    private func destination(wide: Bool) -> some View {
        let layout = wide
            ? AnyLayout(HStackLayout(alignment: .center, spacing: StarfallTheme.Spacing.large))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: StarfallTheme.Spacing.small))
        return layout {
            destinationSummary.frame(maxWidth: .infinity, alignment: .leading)
            if let challenge = selected.challenge, journey.canEnter(selected) {
                destinationActions(challenge).frame(width: wide ? 340 : nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .observatoryReadingPanel(inset: 24)
        .frame(maxWidth: wide ? 900 : StarfallTheme.Layout.menuWidth)
        .padding(.horizontal, StarfallTheme.Spacing.small)
        .frame(maxWidth: .infinity)
        .background {
            GeometryReader { geometry in
                Color.clear.preference(key: WorldMapReservedHeights.self, value: [.destination: geometry.size.height])
            }
        }
    }

    private var destinationSummary: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            if recovered {
                Text(SkyCopy.text(.worldRecovery)).font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                    .accessibilityIdentifier("world.recovery")
            }
            Text(selected.title).font(StarfallTheme.Typography.title)
                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader).accessibilityIdentifier("world.selection")
            Text(selected.status(in: journey)).font(StarfallTheme.Typography.supporting)
                .foregroundStyle(StarfallTheme.Colors.textSecondary).accessibilityIdentifier("world.status")
            if let goal {
                if let retained = goal.retainedLabel {
                    Text(retained).font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textPrimary)
                        .accessibilityIdentifier("world.savedProgress")
                }
                Text(goal.newVisitLabel).font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                    .accessibilityIdentifier("world.newVisitGoal")
            }
            if selected == .firstLight, journey.completed.contains(selected) || !masteryRecords.isEmpty {
                ForEach(SkyMasteryBestSnapshot.lantern(records: masteryRecords)) { best in
                    Text(best.label).font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                        .accessibilityIdentifier("world.mastery." + best.id)
                }
            }
            if selected.challenge == nil {
                Text(SkyCopy.text(.worldComing)).font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func destinationActions(_ challenge: StarfallChallenge) -> some View {
        if let resume {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: StarfallTheme.Spacing.small) {
                    continueButton(resume)
                    restartButton(challenge)
                }.fixedSize(horizontal: true, vertical: false)
                VStack(spacing: StarfallTheme.Spacing.small) {
                    continueButton(resume)
                    restartButton(challenge)
                }
            }
        } else {
            Button(SkyCopy.text(journey.completed.contains(selected) ? .worldRevisit : .worldVisit,
                                values: ["place": selected.title])) { enter(challenge) }
                .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))
                .accessibilityIdentifier("world.visit")
        }
    }

    private func continueButton(_ resume: @escaping () -> Void) -> some View {
        Button(SkyCopy.text(.worldContinue), action: resume)
            .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))
            .accessibilityIdentifier("world.resume")
    }

    private func restartButton(_ challenge: StarfallChallenge) -> some View {
        Button(SkyCopy.text(.worldRestart)) { enter(challenge) }
            .buttonStyle(StarfallButtonStyle(role: .quiet))
            .accessibilityIdentifier("world.visit")
    }

    private var locations: some View {
        VStack(spacing: StarfallTheme.Spacing.compact) {
            ForEach(WorldLocation.allCases) { location in
                Button { choose(location) } label: {
                    HStack(spacing: StarfallTheme.Spacing.medium) {
                        ObservatoryIcon(journey.completed.contains(location) ? .check : journey.canEnter(location) ? .story : .lock)
                            .foregroundStyle(StarfallTheme.Colors.actionPrimary)
                        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                            Text(location.title).font(StarfallTheme.Typography.skyHeading)
                                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                            Text(location.status(in: journey)).font(StarfallTheme.Typography.supporting)
                                .foregroundStyle(StarfallTheme.Colors.textSecondary)
                        }
                        Spacer(minLength: 0)
                        if selected == location { ObservatoryIcon(.check, size: 20) }
                    }
                    .padding(.vertical, StarfallTheme.Spacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(selected == location ? StarfallTheme.Colors.surfacePressed.opacity(0.6) : .clear,
                                in: RoundedRectangle(cornerRadius: StarfallTheme.Radius.control))
                }
                .buttonStyle(StarfallGameButtonStyle())
                .accessibilityLabel(location.title).accessibilityValue(location.status(in: journey))
                .accessibilityAddTraits(selected == location ? .isSelected : [])
                .accessibilityIdentifier("world.place.\(location.id)")
                if location != WorldLocation.allCases.last { Divider() }
            }
        }
        .observatoryReadingPanel()
        .frame(maxWidth: StarfallTheme.Layout.contentWidth)
        .padding(.horizontal, StarfallTheme.Spacing.small)
        .frame(maxWidth: .infinity)
    }

    private func choose(_ location: WorldLocation) {
        select(location)
        selectionRequest += 1
    }
}

private enum WorldMapReservedRegion: Hashable { case navigation, destination }
private struct WorldMapReservedHeights: PreferenceKey {
    static var defaultValue: [WorldMapReservedRegion: CGFloat] { [:] }
    static func reduce(value: inout [WorldMapReservedRegion: CGFloat], nextValue: () -> [WorldMapReservedRegion: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

private struct WorldMapOverflow: PreferenceKey {
    static var defaultValue: Bool { false }
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
