import SwiftUI
import StarfallCore

/// A passive reading aid for one frozen advice frame, never a second playable board.
@MainActor struct SkyFullBoardChoiceDiagramView: View {
    let frame: SkyFullBoardChoiceDiagram.Frame
    let identifier: String

    var body: some View {
        // Resolve the existing bounded material cache before entering Canvas.
        let images = frame.board.prefix(49).map { gem in
            gem.map { Image(uiImage: SkyPiece.image(for: .init($0))) }
        }
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            Text(frame.title)
                .font(StarfallTheme.Typography.supporting)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("fullBoard.choices.frame.\(identifier)")
            Canvas { context, size in
                guard let geometry = SkyFullBoardChoiceGeometry(size: size) else { return }
                Self.draw(in: &context, frame: frame, geometry: geometry, images: images)
            }
            // Axis numbers belong to the fixed miniature. Equivalent native
            // swipe prose and the caption above retain the reader's text size.
            .dynamicTypeSize(.medium)
            .aspectRatio(1, contentMode: .fit)
            .frame(minWidth: 112, maxWidth: 300, minHeight: 112, maxHeight: 300)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(frame.title)
            .accessibilityValue(frame.detail)
            .accessibilityIdentifier("fullBoard.choices.diagram.\(identifier)")
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .allowsHitTesting(false)
        .transaction { $0.animation = nil; $0.disablesAnimations = true }
    }

    /// One 49-piece image pass, fourteen axis labels and bounded static annotation paths.
    static func draw(in context: inout GraphicsContext, frame: SkyFullBoardChoiceDiagram.Frame,
                     geometry: SkyFullBoardChoiceGeometry, images: [Image?]) {
        guard frame.board.count == 49, images.count == 49 else { return }
        context.fill(Path(roundedRect: geometry.board.insetBy(dx: -2, dy: -2), cornerRadius: 6),
                     with: .color(StarfallTheme.Colors.skyTop.opacity(0.62)))
        drawAxes(in: &context, geometry: geometry)
        for index in 0..<49 {
            guard let gem = frame.board[index], let image = images[index] else { continue }
            context.draw(image, in: geometry.imageRect(at: Cell(index / 7, index % 7), grown: gem.grown))
        }
        if let exchange = frame.exchange {
            // A before-frame names only the actual exchange, never its future pattern.
            drawExchange(in: &context, exchange: exchange, geometry: geometry)
        } else {
            drawPatterns(in: &context, recipes: frame.recipes, geometry: geometry)
        }
    }

    private static func drawAxes(in context: inout GraphicsContext, geometry: SkyFullBoardChoiceGeometry) {
        for index in 0..<7 {
            let label = Text(String(index + 1))
                .font(StarfallTheme.Typography.skyCaption)
                .monospacedDigit()
                .foregroundStyle(StarfallTheme.Colors.textSecondary)
            let column = geometry.point(Cell(6, index))
            context.draw(label, at: CGPoint(x: column.x, y: geometry.board.minY - 12))
            let row = geometry.point(Cell(6 - index, 0))
            context.draw(label, at: CGPoint(x: geometry.board.minX - 12, y: row.y))
        }
    }

    private static func drawExchange(in context: inout GraphicsContext,
                                     exchange: FallingSkyTurn.Exchange, geometry: SkyFullBoardChoiceGeometry) {
        guard valid(exchange.from), valid(exchange.to),
              abs(exchange.from.row - exchange.to.row) + abs(exchange.from.column - exchange.to.column) == 1 else { return }
        let from = geometry.point(exchange.from), to = geometry.point(exchange.to)
        let direction = CGVector(dx: (to.x - from.x) / geometry.step,
                                 dy: (to.y - from.y) / geometry.step)
        var normal = CGVector(dx: -direction.dy, dy: direction.dx)
        let middle = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
        if (middle.x - geometry.board.midX) * normal.dx + (middle.y - geometry.board.midY) * normal.dy > 0 {
            normal = CGVector(dx: -normal.dx, dy: -normal.dy)
        }
        // The arrow sits beside the pair, preserving both actual shard bodies.
        let offset = geometry.step * 0.45
        let start = CGPoint(x: from.x + normal.dx * offset, y: from.y + normal.dy * offset)
        let tip = CGPoint(x: to.x + normal.dx * offset, y: to.y + normal.dy * offset)
        let wing = geometry.step * StarfallTheme.SelectionCue.arrowWing
        var arrow = Path()
        arrow.move(to: start); arrow.addLine(to: tip)
        for sign: CGFloat in [-1, 1] {
            arrow.move(to: CGPoint(x: tip.x - direction.dx * wing + normal.dx * wing * sign,
                                  y: tip.y - direction.dy * wing + normal.dy * wing * sign))
            arrow.addLine(to: tip)
        }
        var endpoints = Path()
        let radius = geometry.step * 0.42
        for center in [from, to] {
            endpoints.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius,
                                           width: radius * 2, height: radius * 2))
        }
        stroke(endpoints, in: &context, color: StarfallTheme.Colors.textPrimary)
        stroke(arrow, in: &context, color: StarfallTheme.Colors.actionPrimary)
    }

    private static func drawPatterns(in context: inout GraphicsContext, recipes: [StarRecipe],
                                     geometry: SkyFullBoardChoiceGeometry) {
        guard !recipes.isEmpty, recipes.count <= PatternReturnLayout.maximumPatterns,
              recipes.allSatisfy({ recipe in
                  recipe.cells.allSatisfy(valid) && Set(recipe.cells).count == recipe.cells.count
                      && (recipe.shape == .square ? recipe.cells.count == 4
                          : recipe.shape == .cross ? recipe.cells.count == 5 : (4...7).contains(recipe.cells.count))
              }) else { return }
        var patterns = Path()
        var ingredients = Set<Cell>()
        for recipe in recipes {
            let points = recipe.presentationPath.map(geometry.point)
            guard let first = points.first, points.count <= PatternReturnLayout.maximumPathEntries else { return }
            patterns.move(to: first)
            for point in points.dropFirst() { patterns.addLine(to: point) }
            ingredients.formUnion(recipe.cells)
        }
        // Starting every recipe independently preserves simultaneous and overlapping figures.
        stroke(patterns, in: &context, color: StarfallTheme.Colors.actionPrimary)
        var marks = Path()
        let radius = geometry.step * 0.36
        for cell in ingredients {
            let center = geometry.point(cell)
            marks.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius,
                                       width: radius * 2, height: radius * 2))
        }
        stroke(marks, in: &context, color: StarfallTheme.Colors.textPrimary)
    }

    private static func stroke(_ path: Path, in context: inout GraphicsContext, color: Color) {
        context.stroke(path, with: .color(StarfallTheme.Colors.skyTop),
                       style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
        context.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round))
    }

    private static func valid(_ cell: Cell) -> Bool {
        (0..<7).contains(cell.row) && (0..<7).contains(cell.column)
    }
}
