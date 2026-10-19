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
        NavigationStack {
            List {
                Section {
                    Text(SkyCopy.text(.practiceIntro))
                }
                Section(SkyCopy.text(.practiceChapters)) {
                    ForEach(SkyTutorial.allCases) { lesson in
                        Button { chapter = lesson } label: {
                            Text(lesson.title).font(.headline).padding(.vertical, 6)
                                .frame(minHeight: 44, alignment: .leading)
                        }.accessibilityIdentifier("tutorial.chapter.\(lesson.id)")
                    }
                }
            }
            .navigationTitle(SkyCopy.text(.practiceTitle)).navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button(SkyCopy.text(.actionDone), action: done)
                    .buttonStyle(StarfallButtonStyle(role: .quiet, expands: true))
                    .accessibilityIdentifier("tutorial.done")
                    .padding(8).background(StarfallTheme.Colors.skyTop)
            }
            .fullScreenCover(item: $chapter) { lesson in
                SkyTutorialPlayer(chapter: lesson, exit: { chapter = nil })
            }
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
        .background(StarfallTheme.Colors.skyTop.opacity(0.94), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.white)
    }
    private var content: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(run.chapter.title).font(.headline).accessibilityAddTraits(.isHeader)
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
            }.padding(8)
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
