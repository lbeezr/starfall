import SwiftUI
import StarfallCore

/// Optional reading of one captured transaction. The existing menu owns its
/// dismissal and suspension; no control here can repeat or award the clear.
@MainActor struct SkyLastClearView: View {
    let snapshot: SkyLastClearSnapshot
    let done: () -> Void
    var back = false

    var body: some View {
        SkyMenuSurface(title: SkyCopy.text(.scoreExplanationTitle), glyph: .help, done: done,
                       back: back, footerTitle: SkyCopy.text(.actionReturn)) {
            Text(SkyCopy.text(.lastClearIntro))
                .fixedSize(horizontal: false, vertical: true)
            Text(SkyLastClearCopy.context(snapshot.context))
                .font(StarfallTheme.Typography.supporting)
                .foregroundStyle(StarfallTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("sky.lastClear.mode")
            ForEach(Array(snapshot.phases.enumerated()), id: \.offset) { index, phase in
                SkyMenuRule()
                VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
                    Text(SkyLastClearCopy.phaseTitle(index + 1))
                        .font(StarfallTheme.Typography.skyHeading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("sky.lastClear.phase.\(index + 1)")
                    SkyLastClearDiagramView(phase: phase, number: index + 1)
                    Text(SkyCopy.text(.lastClearDiagramLegend))
                        .font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if phase.survivors?.movements.isEmpty == false {
                        Text(SkyCopy.text(.lastClearSurvivorLegend))
                            .font(StarfallTheme.Typography.supporting)
                            .foregroundStyle(StarfallTheme.Colors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(SkyLastClearCopy.ingredients(phase))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("sky.lastClear.ingredients.\(index + 1)")
                    Text(phase.score.explanationText)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("sky.lastClear.score.\(index + 1)")
                    Text(SkyLastClearCopy.refills(phase))
                        .font(StarfallTheme.Typography.supporting)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            SkyMenuRule()
            Text(snapshot.score.totalText)
                .font(StarfallTheme.Typography.skyHeading)
                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("sky.lastClear.total")
            if let survivors = SkySurvivorCopy.fact(snapshot.survivorCount) {
                Text(survivors)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("sky.lastClear.survivors")
            }
            if let room = SkyLastClearCopy.room(snapshot) {
                Text(room)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("sky.lastClear.room")
            }
        }
    }
}

/// Read-only coordinates share the existing7×7 miniature mapping. Separate
/// walks keep their order, gaps and revisits; ingredient sets never become paths.
struct SkyLastClearDiagramLayout {
    let geometry: SkyFullBoardChoiceGeometry
    let paths: [[CGPoint]]
    let clearedCells: [Cell]
    let clearedPoints: [CGPoint]
    let survivorCells: [Cell]
    let survivorPoints: [CGPoint]

    init?(phase: SkyLastClearSnapshot.Phase, size: CGSize) {
        let maximumEntries = max(ConstellationReturnLayout.maximumWalkEntries,
                                 PatternReturnLayout.maximumPatterns * PatternReturnLayout.maximumPathEntries)
        guard let geometry = SkyFullBoardChoiceGeometry(size: size),
              phase.board.count == FallingSky.side * FallingSky.side,
              phase.drained.allSatisfy({ Self.valid($0) && phase.board[$0.row * 7 + $0.column] != nil }),
              !phase.cleared.isEmpty, phase.cleared.count <= 49,
              phase.cleared.allSatisfy({ Self.valid($0) && phase.board[$0.row * 7 + $0.column] != nil }),
              phase.paths.count <= PatternReturnLayout.maximumPatterns,
              phase.paths.reduce(0, { $0 + $1.count }) <= maximumEntries,
              phase.paths.allSatisfy({ path in
                  path.count > 1 && path.count <= (phase.paths.count == 1
                      ? ConstellationReturnLayout.maximumWalkEntries : PatternReturnLayout.maximumPathEntries)
                      && path.allSatisfy({ Self.valid($0) && phase.cleared.contains($0) })
              }) else { return nil }
        let moved = phase.survivors?.movements ?? []
        guard moved.count <= SkySurvivorIngredients.maximumMovements,
              Set(moved.map(\.to)).count == moved.count,
              moved.allSatisfy({ phase.cleared.contains($0.to)
                  && phase.board[$0.to.row * 7 + $0.to.column]?.id == $0.id }) else { return nil }
        self.geometry = geometry
        paths = phase.paths.map { $0.map(geometry.point) }
        clearedCells = phase.cleared.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row > $1.row }
        clearedPoints = clearedCells.map(geometry.point)
        survivorCells = moved.map(\.to)
        survivorPoints = survivorCells.map(geometry.point)
    }

    private static func valid(_ cell: Cell) -> Bool {
        (0..<7).contains(cell.row) && (0..<7).contains(cell.column)
    }
}

/// The miniature remains a passive image: a pan beginning over any shard or
/// annotation belongs to the native reader, never to an exchange or trace.
@MainActor struct SkyLastClearDiagramView: View {
    let phase: SkyLastClearSnapshot.Phase
    let number: Int

    var body: some View {
        let images = phase.board.prefix(49).map { gem in
            gem.map { Image(uiImage: SkyPiece.image(for: .init($0))) }
        }
        Canvas { context, size in
            guard let layout = SkyLastClearDiagramLayout(phase: phase, size: size) else { return }
            Self.draw(in: &context, phase: phase, layout: layout, images: images)
        }
        .dynamicTypeSize(.medium)
        .aspectRatio(1, contentMode: .fit)
        .frame(minWidth: 112, maxWidth: 300, minHeight: 112, maxHeight: 300)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(SkyLastClearCopy.phaseTitle(number))
        .accessibilityValue(SkyLastClearCopy.ingredients(phase))
        .accessibilityIdentifier("sky.lastClear.diagram.\(number)")
        .frame(maxWidth: .infinity, alignment: .center)
        .allowsHitTesting(false)
        .transaction { $0.animation = nil; $0.disablesAnimations = true }
    }

    static func draw(in context: inout GraphicsContext, phase: SkyLastClearSnapshot.Phase,
                     layout: SkyLastClearDiagramLayout, images: [Image?]) {
        // Reuse the accepted material sizing, board backing and14 axis labels.
        // Empty recipes suppress its choice-only annotations; this receipt's
        // exact captured paths and ingredients are drawn separately below.
        let base = SkyFullBoardChoiceDiagram.Frame(board: phase.board, exchange: nil, recipes: [], step: 0)
        let coloredImages = images.enumerated().map { index, image in
            phase.drained.contains(Cell(index / 7, index % 7)) ? nil : image
        }
        SkyFullBoardChoiceDiagramView.draw(in: &context, frame: base, geometry: layout.geometry, images: coloredImages)
        // The static reader names exactly these committed drained cells. Gray
        // is its diagram convention, not a replay of the living node shader.
        var gray = context
        gray.addFilter(.saturation(0))
        for cell in phase.drained {
            let index = cell.row * 7 + cell.column
            guard images.indices.contains(index), let image = images[index], let gem = phase.board[index] else { continue }
            gray.draw(image, in: layout.geometry.imageRect(at: cell, grown: gem.grown))
        }
        var paths = Path()
        for points in layout.paths {
            guard let first = points.first else { continue }
            paths.move(to: first)
            for point in points.dropFirst() { paths.addLine(to: point) }
        }
        stroke(paths, in: &context, color: StarfallTheme.Colors.actionPrimary, step: layout.geometry.step)
        var ingredients = Path()
        for (cell, center) in zip(layout.clearedCells, layout.clearedPoints) {
            let grown = phase.board[cell.row * 7 + cell.column]?.grown == true
            let radius = layout.geometry.step * (grown ? 0.44 : 0.36)
            ingredients.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius,
                                              width: radius * 2, height: radius * 2))
        }
        stroke(ingredients, in: &context, color: StarfallTheme.Colors.textPrimary, step: layout.geometry.step)
        var survivors = Path()
        let radius = layout.geometry.step * 0.46
        for center in layout.survivorPoints {
            survivors.move(to: CGPoint(x: center.x, y: center.y - radius))
            survivors.addLines([CGPoint(x: center.x + radius, y: center.y),
                                CGPoint(x: center.x, y: center.y + radius),
                                CGPoint(x: center.x - radius, y: center.y)])
            survivors.closeSubpath()
        }
        stroke(survivors, in: &context, color: StarfallTheme.Colors.textPrimary, step: layout.geometry.step)
    }

    private static func stroke(_ path: Path, in context: inout GraphicsContext, color: Color, step: CGFloat) {
        let width = min(3.5, step * 0.1)
        context.stroke(path, with: .color(StarfallTheme.Colors.skyTop),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: width * 0.36, lineCap: .round, lineJoin: .round))
    }
}
