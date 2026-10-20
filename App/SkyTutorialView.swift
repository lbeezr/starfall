import SwiftUI
import StarfallCore

extension SkyTutorial {
    var title: String {
        switch self {
        case .match: SkyCopy.text(.practiceMatchTitle)
        case .grown: SkyCopy.text(.practiceGrownTitle)
        case .exchange: SkyCopy.text(.practiceExchangeTitle)
        case .emptySpace: SkyCopy.text(.practiceEmptySpaceTitle)
        case .trace: SkyCopy.text(.practiceTraceTitle)
        case .diagonal: SkyCopy.text(.practiceDiagonalTitle)
        case .gap: SkyCopy.text(.practiceGapTitle)
        case .branch: SkyCopy.text(.practiceBranchTitle)
        case .square: SkyCopy.text(.practiceSquareTitle)
        case .cross: SkyCopy.text(.practiceCrossTitle)
        case .opal: SkyCopy.text(.practiceOpalTitle)
        case .relay: SkyCopy.text(.practiceRelayTitle)
        case .trim: SkyCopy.text(.practiceTrimTitle)
        case .dropIn: SkyCopy.text(.practiceDropInTitle)
        case .bank: SkyCopy.text(.practiceBankTitle)
        case .fork: SkyCopy.text(.practiceForkTitle)
        case .doubleSetup: SkyCopy.text(.practiceDoubleSetupTitle)
        case .showers: SkyCopy.text(.practiceShowersTitle)
        case .storm: SkyCopy.text(.practiceStormTitle)
        case .room: SkyCopy.text(.practiceRoomTitle)
        case .restoration: SkyCopy.text(.practiceRestorationTitle)
        }
    }
    var detail: String {
        switch self {
        case .match: SkyCopy.text(.practiceMatchDetail)
        case .grown: SkyCopy.text(.practiceGrownDetail)
        case .exchange: SkyCopy.text(.practiceExchangeDetail)
        case .emptySpace: SkyCopy.text(.practiceEmptySpaceDetail)
        case .trace: SkyCopy.text(.practiceTraceDetail)
        case .diagonal: SkyCopy.text(.practiceDiagonalDetail)
        case .gap: SkyCopy.text(.practiceGapDetail)
        case .branch: SkyCopy.text(.practiceBranchDetail)
        case .square: SkyCopy.text(.practiceSquareDetail)
        case .cross: SkyCopy.text(.practiceCrossDetail)
        case .opal: SkyCopy.text(.practiceOpalDetail)
        case .relay: SkyCopy.text(.practiceRelayDetail)
        case .trim: SkyCopy.text(.practiceTrimDetail)
        case .dropIn: SkyCopy.text(.practiceDropInDetail)
        case .bank: SkyCopy.text(.practiceBankDetail)
        case .fork: SkyCopy.text(.practiceForkDetail)
        case .doubleSetup: SkyCopy.text(.practiceDoubleSetupDetail)
        case .showers: SkyCopy.text(.practiceShowersDetail)
        case .storm: SkyCopy.text(.practiceStormDetail)
        case .room: SkyCopy.text(.practiceRoomDetail)
        case .restoration: SkyCopy.text(.practiceRestorationDetail)
        }
    }
    var nextChapter: Self? {
        guard let index = Self.allCases.firstIndex(of: self), index + 1 < Self.allCases.count else { return nil }
        return Self.allCases[index + 1]
    }
}

extension SkyTutorial.Action {
    var instruction: String {
        func position(_ cell: Cell) -> String { SkyCopy.text(.practicePosition, values: ["row": String(cell.row + 1), "column": String(cell.column + 1)]) }
        switch self {
        case .tap(let cell): return SkyCopy.text(.practiceTap, values: ["position": position(cell)])
        case .swap(let from, let to):
            let direction = to.row > from.row ? SkyCopy.text(.practiceUp) : to.row < from.row ? SkyCopy.text(.practiceDown) : to.column > from.column ? SkyCopy.text(.practiceRight) : SkyCopy.text(.practiceLeft)
            return SkyCopy.text(.practiceSwipe, values: ["direction": direction, "position": position(from)])
        case .trace(let path):
            return SkyCopy.text(.practiceDraw, values: ["path": path.map { "\($0.row + 1),\($0.column + 1)" }.joined(separator: " → ")])
        case .shower: return SkyCopy.text(.practiceShower)
        case .automaticShower: return SkyCopy.text(.practiceAutomatic)
        case .pause: return SkyCopy.text(.practicePause)
        case .resume: return SkyCopy.text(.practiceResume)
        }
    }
}

struct SkyTutorialView: View {
    let done: () -> Void
    @State private var chapter: SkyTutorial?
    init(initial: SkyTutorial? = nil, done: @escaping () -> Void) {
        self.done = done; _chapter = State(initialValue: initial)
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: StarfallTheme.Spacing.medium) {
                Text(SkyCopy.text(.practiceTitle))
                    .font(StarfallTheme.Typography.title)
                    .foregroundStyle(StarfallTheme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: StarfallTheme.Spacing.small)
                Button(SkyCopy.text(.actionDone), action: done)
                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                    .accessibilityIdentifier("tutorial.done")
            }
            .padding(.horizontal, StarfallTheme.Spacing.page)
            .padding(.vertical, StarfallTheme.Spacing.small)
            ScrollView {
                VStack(alignment: .leading, spacing: StarfallTheme.Spacing.section) {
                    HStack(alignment: .top, spacing: StarfallTheme.Spacing.large) {
                        ObservatoryEmblem(.tutorial)
                        Text(SkyCopy.text(.practiceIntro))
                            .font(StarfallTheme.Typography.body)
                            .foregroundStyle(StarfallTheme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, StarfallTheme.Spacing.medium)
                    Text(SkyCopy.text(.practiceChapters))
                        .font(StarfallTheme.Typography.skyHeading)
                        .foregroundStyle(StarfallTheme.Ceremony.gold)
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: 0) {
                        ForEach(SkyTutorial.allCases) { lesson in
                            Button { chapter = lesson } label: {
                                HStack(spacing: StarfallTheme.Spacing.medium) {
                                    ObservatoryIcon(lesson.interfaceGlyph, size: 20)
                                        .foregroundStyle(StarfallTheme.Ceremony.gold)
                                    Text(lesson.title)
                                        .font(StarfallTheme.Typography.skyHeading)
                                        .foregroundStyle(StarfallTheme.Colors.textPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: StarfallTheme.Spacing.small)
                                    ObservatoryIcon(.next, size: 20)
                                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                                }
                                .padding(.vertical, StarfallTheme.Spacing.large)
                                .frame(minHeight: StarfallTheme.Layout.minimumTarget, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("tutorial.chapter.\(lesson.id)")
                            Divider()
                        }
                    }
                }
                .frame(maxWidth: StarfallTheme.Layout.contentWidth, alignment: .leading)
                .padding(StarfallTheme.Spacing.section)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background { SkyBackdrop().ignoresSafeArea() }
        .fullScreenCover(item: $chapter) { lesson in
            SkyTutorialPlayer(chapter: lesson, exit: { chapter = nil })
        }
    }
}

private extension SkyTutorial {
    var interfaceGlyph: ObservatoryGlyph {
        switch self {
        case .exchange, .emptySpace: .direction
        case .trace, .diagonal, .gap, .branch, .square, .cross, .trim, .fork: .trace
        case .showers: .pause
        case .storm, .room: .freePlay
        case .restoration: .story
        default: .tutorial
        }
    }
}

private struct SkyTutorialPlayer: View {
    let chapter: SkyTutorial
    let exit: () -> Void
    @State private var store: FallingSkyStore
    init(chapter: SkyTutorial, exit: @escaping () -> Void) {
        self.chapter = chapter; self.exit = exit
        _store = State(initialValue: FallingSkyStore(arguments: [], tutorial: chapter))
    }
    var body: some View {
        FallingSkyView(store: store, flow: SkyFlowState(practice: chapter), tutorialExit: exit)
    }
}

struct SkyTutorialGuide: View {
    let run: SkyTutorialRun
    let constrained: Bool
    let retry: () -> Void
    let next: (SkyTutorial) -> Void
    let exit: () -> Void
    @State private var showDetail = false
    var body: some View {
        Group {
            if constrained { ScrollView { content }.scrollBounceBehavior(.basedOnSize) }
            else { content }
        }
        .starfallPanel(inset: StarfallTheme.Spacing.medium)
        .foregroundStyle(StarfallTheme.Colors.textPrimary)
    }
    private var content: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(run.chapter.title).font(StarfallTheme.Typography.skyHeading).accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("tutorial.title")
                Text(run.complete ? SkyCopy.text(.practiceComplete) : run.needsRetry ? SkyCopy.text(.practiceRetryMessage) : run.next?.instruction ?? "")
                    .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("tutorial.instruction")
                if showDetail || run.step == 0 {
                    Text(run.chapter.detail).font(.caption)
                    Text(SkyCopy.text(.practiceCoordinates)).font(.caption)
                }
                ViewThatFits(in: .horizontal) {
                    HStack { actions }.fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading) { actions }
                }.buttonStyle(StarfallButtonStyle(role: .quiet))
            }
    }
    @ViewBuilder private var actions: some View {
        Button(SkyCopy.text(.practiceRetry), action: retry).accessibilityIdentifier("tutorial.retry")
        Button(showDetail ? SkyCopy.text(.practiceLess) : SkyCopy.text(.practiceHint)) { showDetail.toggle() }.accessibilityIdentifier("tutorial.hint")
        if let chapter = run.chapter.nextChapter {
            Button(run.complete ? SkyCopy.text(.practiceNext) : SkyCopy.text(.practiceSkip)) { next(chapter) }
                .accessibilityIdentifier("tutorial.next")
        } else { Button(SkyCopy.text(.practiceFinish), action: exit).accessibilityIdentifier("tutorial.finish") }
    }
}
