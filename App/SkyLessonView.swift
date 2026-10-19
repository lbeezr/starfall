import SwiftUI
import StarfallCore

extension SkyLesson {
    var title: String {
        let key: SkyCopy.Key = switch self {
        case .square: .lessonSquareTitle
        case .cross: .lessonCrossTitle
        case .opal: .lessonOpalTitle
        case .relay: .lessonRelayTitle
        }
        return SkyCopy.text(key)
    }
    func explanation(after step: Int) -> String {
        let keys: [SkyCopy.Key]
        switch self {
        case .square: keys = [.lessonSquareStart, .lessonSquareReady, .lessonSquareDone]
        case .cross: keys = [.lessonCrossStart, .lessonCrossDone]
        case .opal: keys = [.lessonOpalStart, .lessonOpalDone]
        case .relay: keys = [.lessonRelayStart, .lessonRelayReady, .lessonRelayDone]
        }
        return SkyCopy.text(keys[min(step, keys.count-1)])
    }
    func action(at step: Int) -> String {
        let keys: [SkyCopy.Key]
        switch self {
        case .square: keys = [.lessonSwap, .lessonTraceSquare]
        case .cross: keys = [.lessonTraceCross]
        case .opal: keys = [.lessonTapSpark]
        case .relay: keys = [.lessonTapSunny, .lessonTraceSquare]
        }
        return SkyCopy.text(keys[min(step, keys.count-1)])
    }
}

/// Owns only a local value example. No Store, archive, shower clock or delayed callbacks.
struct SkyLessonView: View {
    let lesson: SkyLesson
    @State private var game: FallingSky
    @State private var step = 0
    @State private var gain: Int?
    @State private var failed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("calmEffects") private var calm = false

    init(lesson: SkyLesson) {
        self.lesson = lesson
        _game = State(initialValue: lesson.game())
    }

    private var nextMove: SkyLesson.Move? { step < lesson.moves.count ? lesson.moves[step] : nil }
    private var legal: Bool {
        guard let nextMove else { return false }
        var preview = game
        return nextMove.perform(in: &preview) != nil
    }
    private var stars: [(gem: StarfallGem, cell: Cell)] {
        game.board.enumerated().compactMap { index, gem in
            gem.map { ($0, Cell(index / FallingSky.side, index % FallingSky.side)) }
        }
    }
    private var diagramCells: [Cell] {
        lesson.game().board.enumerated().compactMap { index, gem in
            gem == nil ? nil : Cell(index / FallingSky.side, index % FallingSky.side)
        }
    }
    private var diagramRows: Int { (diagramCells.map(\.row).max() ?? 0) + 1 }
    private var diagramColumns: Int { (diagramCells.map(\.column).max() ?? 0) + 1 }
    private var highlighted: Set<Cell> {
        switch nextMove {
        case .swap(let from, _): [from]
        case .trace(let path): Set(path)
        case .tap(let cell): Set(game.group(at: cell))
        case nil: []
        }
    }
    private var boardDescription: String {
        stars.sorted { $0.cell.row == $1.cell.row ? $0.cell.column < $1.cell.column : $0.cell.row > $1.cell.row }
            .map { "\(StarCast.character(for: .init($0.gem)).description), \(SkyCopy.position(row: $0.cell.row+1, column: $0.cell.column+1))" }
            .joined(separator: "; ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StarfallTheme.Spacing.large) {
                Text(lesson.explanation(after: step))
                    .font(StarfallTheme.Typography.body)
                    .accessibilityIdentifier("lesson.explanation")
                diagram
                Text(SkyCopy.text(.lessonScore, values: ["score": String(game.score)]))
                    .font(StarfallTheme.Typography.heading)
                    .accessibilityIdentifier("lesson.score")
                if let gain {
                    Text(gain == 0 ? SkyCopy.text(.lessonNoClear) : SkyCopy.text(.lessonGain, values: ["gain": String(gain)]))
                        .font(StarfallTheme.Typography.supporting)
                        .accessibilityIdentifier("lesson.result")
                }
                if nextMove != nil {
                    Button(lesson.action(at: step), action: advance)
                        .buttonStyle(StarfallButtonStyle(role: .primary))
                        .disabled(!legal)
                        .accessibilityIdentifier("lesson.advance")
                    Text(SkyCopy.text(.lessonExampleNote)).font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                }
                if failed { Text(SkyCopy.text(.lessonFailed)) }
                Button(SkyCopy.text(.lessonRetry), action: reset)
                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                    .accessibilityIdentifier("lesson.retry")
            }
            .frame(maxWidth: StarfallTheme.Layout.contentWidth, alignment: .leading)
            .padding(StarfallTheme.Spacing.large)
            .frame(maxWidth: .infinity)
        }
        .background(StarfallTheme.Colors.skyTop)
        .navigationTitle(lesson.title).navigationBarTitleDisplayMode(.inline)
    }

    private var diagram: some View {
        GeometryReader { proxy in
            let unit = min(proxy.size.width / CGFloat(diagramColumns), 64)
            let left = (proxy.size.width - unit * CGFloat(diagramColumns)) / 2
            ZStack {
                ForEach(stars, id: \.gem.id) { star in
                    Image(uiImage: StarCast.image(for: .init(star.gem)))
                        .resizable().scaledToFit()
                        .frame(width: unit, height: unit)
                        .background {
                            if highlighted.contains(star.cell) {
                                Circle().stroke(StarfallTheme.Colors.actionPrimary, style: StrokeStyle(lineWidth: 1.5, dash: [3,3]))
                            }
                        }
                        .position(x: left + (CGFloat(star.cell.column) + 0.5) * unit,
                                  y: (CGFloat(diagramRows) - 0.5 - CGFloat(star.cell.row)) * unit)
                        .transition(.opacity.combined(with: .scale(scale: 0.5)))
                }
            }
        }
        .frame(height: CGFloat(diagramRows) * 64)
        .animation(reduceMotion || calm ? nil : .easeInOut(duration: 0.35), value: game.board)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(boardDescription.isEmpty ? SkyCopy.text(.lessonEmpty) : boardDescription)
        .accessibilityIdentifier("lesson.board")
    }

    private func advance() {
        guard let nextMove else { return }
        var committed = game
        guard let turn = nextMove.perform(in: &committed) else { failed = true; return }
        // Core commits first. Animation has no authority over actions or results.
        game = committed; step += 1; gain = turn.collected; failed = false
    }
    private func reset() {
        game = lesson.game(); step = 0; gain = nil; failed = false
    }
}
