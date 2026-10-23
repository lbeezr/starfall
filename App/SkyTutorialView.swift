import SwiftUI
import StarfallCore

extension SkyTutorial {
    var title: String {
        switch self {
        case .storySquare: SkyCopy.text(.practiceStorySquareTitle)
        case .storyRoom: SkyCopy.text(.practiceStoryRoomTitle)
        case .fullBoardRefill: SkyCopy.text(.practiceFullBoardRefillTitle)
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
        case .storySquare: SkyCopy.text(.practiceStorySquareDetail)
        case .storyRoom: SkyCopy.text(.practiceStoryRoomDetail)
        case .fullBoardRefill: SkyCopy.text(.practiceFullBoardRefillDetail)
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
    var showsDetailInitially: Bool {
        switch self {
        case .storySquare, .storyRoom, .fullBoardRefill: false
        default: true
        }
    }
}

extension SkyTutorial.Action {
    var instruction: String {
        func position(_ cell: Cell) -> String {
            let position = SkyCopy.boardPosition(cell)
            return SkyCopy.text(.practicePosition, values: ["row": String(position.row), "column": String(position.column)])
        }
        switch self {
        case .tap(let cell): return SkyCopy.text(.practiceTap, values: ["position": position(cell)])
        case .swap(let from, let to):
            let direction = to.row > from.row ? SkyCopy.text(.practiceUp) : to.row < from.row ? SkyCopy.text(.practiceDown) : to.column > from.column ? SkyCopy.text(.practiceRight) : SkyCopy.text(.practiceLeft)
            return SkyCopy.text(.practiceSwipe, values: ["direction": direction, "position": position(from)])
        case .trace(let path):
            return SkyCopy.text(.practiceDraw, values: ["path": path.map {
                let position = SkyCopy.boardPosition($0)
                return "\(position.row),\(position.column)"
            }.joined(separator: " → ")])
        case .shower: return SkyCopy.text(.practiceShower)
        case .automaticShower: return SkyCopy.text(.practiceAutomatic)
        case .pause: return SkyCopy.text(.practicePause)
        case .resume: return SkyCopy.text(.practiceResume)
        }
    }
}

extension SkyTutorialRun {
    var showsPauseControl: Bool { next == .pause || next == .resume }
    var showsShowerControl: Bool { next == .shower }
    func instruction(showingHint: Bool) -> String {
        if complete {
            let key: SkyCopy.Key = switch chapter {
            case .storySquare: .practiceStorySquareComplete
            case .storyRoom: .practiceStoryRoomComplete
            case .fullBoardRefill: .practiceFullBoardRefillComplete
            default: .practiceComplete
            }
            return SkyCopy.text(key)
        }
        if needsRetry { return SkyCopy.text(.practiceRetryMessage) }
        if !showingHint {
            switch chapter {
            case .storySquare: return SkyCopy.text(.practiceStorySquarePrompt)
            case .storyRoom:
                return SkyCopy.text(step == 0 ? .practiceStoryRoomPrompt : .practiceStoryRoomAfterClear)
            case .fullBoardRefill: return SkyCopy.text(.practiceFullBoardRefillPrompt)
            default: break
            }
        }
        return next?.instruction ?? ""
    }
}

struct SkyTutorialView: View {
    let done: () -> Void
    let returnsAfterLesson: Bool
    @State private var chapter: SkyTutorial?
    @State private var lastOpenedChapter: SkyTutorial?
    @Environment(\.dynamicTypeSize) private var textSize
    init(initial: SkyTutorial? = nil, returnsAfterLesson: Bool = false, done: @escaping () -> Void) {
        self.done = done
        self.returnsAfterLesson = returnsAfterLesson
        _chapter = State(initialValue: initial)
        _lastOpenedChapter = State(initialValue: initial)
    }
    var body: some View {
        ZStack {
            // A native full-screen cover can leave its underlying scroll
            // controls in the accessibility tree. Keep presentation ownership
            // mounted while withdrawing the covered chapter index itself.
            if chapter == nil { index }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { SkyBackdrop().ignoresSafeArea() }
        .fullScreenCover(item: $chapter, onDismiss: {
            if returnsAfterLesson { done() }
        }) { lesson in
            SkyTutorialPlayer(chapter: lesson) { lastChapter in
                lastOpenedChapter = lastChapter
                chapter = nil
            }
        }
    }

    private var index: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, StarfallTheme.Spacing.page)
                .padding(.vertical, StarfallTheme.Spacing.small)
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(alignment: .leading, spacing: StarfallTheme.Spacing.section) {
                        HStack(alignment: .top, spacing: StarfallTheme.Spacing.large) {
                            ObservatoryEmblem(.tutorial)
                            Text(SkyCopy.text(.practiceIntro))
                                .font(StarfallTheme.Typography.body)
                                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("tutorial.intro")
                        }
                        .padding(.vertical, StarfallTheme.Spacing.medium)
                        Text(SkyCopy.text(.practiceChapters))
                            .font(StarfallTheme.Typography.skyHeading)
                            .foregroundStyle(StarfallTheme.Ceremony.gold)
                            .accessibilityAddTraits(.isHeader)
                        VStack(spacing: 0) {
                            ForEach(SkyTutorial.allCases) { lesson in
                                Button {
                                    lastOpenedChapter = lesson
                                    chapter = lesson
                                } label: {
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
                                    .padding(.vertical, StarfallTheme.Spacing.small)
                                    .frame(minHeight: StarfallTheme.Layout.minimumTarget, alignment: .leading)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(StarfallButtonStyle(role: .quiet))
                                .accessibilityIdentifier("tutorial.chapter.\(lesson.id)")
                                .id(lesson)
                                Divider()
                            }
                        }
                    }
                    .frame(maxWidth: StarfallTheme.Layout.contentWidth, alignment: .leading)
                    .starfallPanel(inset: StarfallTheme.Spacing.medium)
                    .padding(StarfallTheme.Spacing.section)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                // The viewport owns pan input across its scene base. Decorative
                // panel artwork stays passive without leaving empty lanes inert.
                .background(StarfallTheme.Colors.skyTop)
                .onAppear {
                    if let lastOpenedChapter {
                        scroll.scrollTo(lastOpenedChapter, anchor: .center)
                    }
                }
            }
        }
    }

    private var header: some View {
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: StarfallTheme.Spacing.small))
            : AnyLayout(HStackLayout(spacing: StarfallTheme.Spacing.medium))
        return layout {
            Text(SkyCopy.text(.practiceTitle))
                .font(StarfallTheme.Typography.title)
                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
                .fixedSize(horizontal: false, vertical: true)
            if !textSize.isAccessibilitySize { Spacer(minLength: StarfallTheme.Spacing.small) }
            Button(SkyCopy.text(.actionDone), action: done)
                .buttonStyle(StarfallButtonStyle(role: .compact, expands: textSize.isAccessibilitySize))
                .accessibilityIdentifier("tutorial.done")
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
        case .storySquare, .storyRoom, .fullBoardRefill, .restoration: .story
        default: .tutorial
        }
    }
}

private struct SkyTutorialPlayer: View {
    let chapter: SkyTutorial
    let exit: (SkyTutorial) -> Void
    @State private var store: FallingSkyStore
    init(chapter: SkyTutorial, exit: @escaping (SkyTutorial) -> Void) {
        self.chapter = chapter; self.exit = exit
        _store = State(initialValue: FallingSkyStore(arguments: [], tutorial: chapter))
    }
    var body: some View {
        FallingSkyView(store: store, flow: SkyFlowState(practice: chapter), tutorialExit: {
            exit(store.tutorial?.chapter ?? chapter)
        })
    }
}

struct SkyTutorialGuide: View {
    let run: SkyTutorialRun
    let constrained: Bool
    let retry: () -> Void
    let next: (SkyTutorial) -> Void
    let exit: () -> Void
    @State private var showDetail: Bool
    init(run: SkyTutorialRun, constrained: Bool, retry: @escaping () -> Void,
         next: @escaping (SkyTutorial) -> Void, exit: @escaping () -> Void) {
        self.run = run; self.constrained = constrained
        self.retry = retry; self.next = next; self.exit = exit
        // Seed this mounted chapter's local disclosure; later chapters reset below.
        _showDetail = State(initialValue: run.chapter.showsDetailInitially)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            if constrained {
                ScrollView { reading }
                    .scrollBounceBehavior(.basedOnSize)
            } else {
                reading
            }
            ViewThatFits(in: .horizontal) {
                HStack { actions }.fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading) { actions }
            }
            .buttonStyle(StarfallButtonStyle(role: .compact))
        }
        .starfallPanel(inset: StarfallTheme.Spacing.medium)
        .foregroundStyle(StarfallTheme.Colors.textPrimary)
        .onChange(of: run.chapter) { _, chapter in showDetail = chapter.showsDetailInitially }
    }
    private var reading: some View {
            VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
                HStack(alignment: .firstTextBaseline, spacing: StarfallTheme.Spacing.small) {
                    ObservatoryIcon(run.chapter.interfaceGlyph, size: 18)
                        .foregroundStyle(StarfallTheme.Dialogue.brass)
                    Text(run.chapter.title)
                        .font(StarfallTheme.Typography.skyHeading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("tutorial.title")
                }
                Text(run.instruction(showingHint: showDetail))
                    .font(StarfallTheme.Typography.supporting).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("tutorial.instruction")
                if showDetail {
                    Text(run.chapter.detail).font(StarfallTheme.Typography.skyCaption)
                        .accessibilityIdentifier("tutorial.detail")
                    Text(SkyCopy.text(.practiceCoordinates)).font(StarfallTheme.Typography.skyCaption)
                        .accessibilityIdentifier("tutorial.coordinates")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    @ViewBuilder private var actions: some View {
        guideAction(SkyCopy.text(.practiceRetry), glyph: .replay, id: "tutorial.retry") {
            if !run.chapter.showsDetailInitially { showDetail = false }
            retry()
        }
        guideAction(showDetail ? SkyCopy.text(.practiceLess) : SkyCopy.text(.practiceHint), glyph: .help, id: "tutorial.hint") {
            showDetail.toggle()
        }
        if let chapter = run.chapter.nextChapter {
            guideAction(run.complete ? SkyCopy.text(.practiceNext) : SkyCopy.text(.practiceSkip), glyph: .next, id: "tutorial.next") {
                next(chapter)
            }
        } else {
            guideAction(SkyCopy.text(.practiceFinish), glyph: .check, id: "tutorial.finish", action: exit)
        }
    }
    private func guideAction(_ title: String, glyph: ObservatoryGlyph, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: StarfallTheme.Spacing.compact) {
                ObservatoryIcon(glyph, size: 16)
                Text(title).fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier(id)
    }
}
