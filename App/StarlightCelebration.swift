import SwiftUI
import StarfallCore

/// A receipt for an already committed clear. Never encoded or used to award points.
struct StarlightCelebration: Equatable, Identifiable {
    enum Level: Equatable { case ordinary, brilliant, constellation, recipe(StarRecipe.Shape), relay(Int), cascade(Int) }
    let id: UInt64
    let started: Date
    /// Physical light drives presentation intensity; display points may include
    /// the committed story scale and bonus without changing the effect budget.
    let collected: Int
    let displayAward: Int
    let total: Int
    var awardText: String { "+\(displayAward.formatted())" }
    let cells: [Cell]
    /// Compatibility outline for selection callers. Automatic return rendering
    /// uses every entry in `patterns`, never this first-recipe outline alone.
    let path: [Cell]
    /// Only a committed manual walk returns as a player-authored constellation.
    let constellationPath: [Cell]
    /// Automatic patterns retain each committed recipe separately, including
    /// simultaneous and overlapping figures. They are never a manual walk.
    struct Pattern: Equatable {
        let shape: StarRecipe.Shape
        let cells: [Cell]
        let starIDs: Set<Int>
        let path: [Cell]

        init(recipe: StarRecipe) {
            shape = recipe.shape
            cells = recipe.cells
            starIDs = recipe.starIDs
            path = recipe.presentationPath
        }
    }
    let patterns: [Pattern]
    struct Contributor: Equatable {
        let cell: Cell
        let identity: SkyIdentity
        let reward: Int
    }
    let contributors: [Contributor]
    /// Award energy is continuous and bounded; categories still name real achievements.
    var energy: Double {
        let base = Self.energy(for: collected)
        if case .cascade(let depth) = level { return min(1, base + Double(depth - 1) * 0.2) }
        return base
    }
    static func energy(for award: Int) -> Double { min(1, max(0, Double(award - 3) / 15)) }
    var isExceptional: Bool {
        if case .relay = level { return true }
        if case .cascade = level { return true }
        return collected >= 8
    }
    static let maximumPackets = 6
    var packets: [Contributor] {
        let count = min(Self.maximumPackets, contributors.count)
        guard count > 1 else { return contributors }
        return (0..<count).map { contributors[$0 * (contributors.count - 1) / (count - 1)] }
    }
    struct PacketFlight {
        let start: TimeInterval
        let duration: TimeInterval
        let stagger: TimeInterval

        func arrivalTime(packetIndex: Int) -> TimeInterval {
            start + Double(packetIndex) * stagger + duration
        }

        func progress(at age: TimeInterval, packetIndex: Int) -> Double {
            min(1, max(0, (age - start - Double(packetIndex) * stagger) / duration))
        }
    }
    static func packetFlight(toRestoration: Bool) -> PacketFlight {
        if toRestoration {
            // Deliver every packet before the ordinary clear hands off to the
            // result. The committed win and its controls never wait for this art.
            return PacketFlight(start: StarfallMotion.gatherDuration, duration: 0.32, stagger: 0.015)
        }
        return PacketFlight(start: 0.15, duration: 0.48, stagger: 0.025)
    }
    let level: Level
    static let duration: TimeInterval = 1.4
    var title: String? {
        switch level {
        case .ordinary: nil
        case .brilliant: SkyCopy.text(.celebrationBrilliant)
        case .constellation: SkyCopy.text(.celebrationConstellation)
        case .recipe(let shape):
            switch shape {
            case .square: SkyCopy.text(.celebrationSquare)
            case .cross: SkyCopy.text(.celebrationCross)
            case .line: SkyCopy.text(.celebrationLine)
            }
        case .relay(let depth): SkyCopy.text(.celebrationRelay, values: ["count": String(depth)])
        case .cascade(let depth): SkyCopy.text(.celebrationCascade, values: ["count": String(depth)])
        }
    }

    /// Each receipt uses that phase's own board coordinates. The rising number is
    /// the committed total for this cascade, never another award to the save.
    init(id: UInt64, phase: SkyResolutionPhase, cumulativeAward: Int, total: Int, started: Date = .now) {
        self.id = id
        self.started = started
        collected = phase.award.baseLight
        displayAward = cumulativeAward
        self.total = total
        cells = phase.cleared.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        contributors = cells.compactMap { cell in
            phase.before[cell.row * FallingSky.side + cell.column].map {
                Contributor(cell: cell, identity: $0.identity, reward: $0.value)
            }
        }
        path = phase.recipes.first?.presentationPath ?? []
        constellationPath = []
        patterns = phase.kind == .recipe ? phase.recipes.map { Pattern(recipe: $0) } : []
        if phase.comboDepth > 1 { level = .cascade(phase.comboDepth) }
        else if let recipe = phase.recipes.first { level = .recipe(recipe.shape) }
        else { level = phase.award.sizeBonus > 0 || collected >= 8 ? .brilliant : .ordinary }
    }

    init?(id: UInt64, turn: FallingSkyTurn, from old: FallingSky, total: Int,
          path: [Cell] = [], recipe: StarRecipe? = nil, relayDepth: Int = 0, started: Date = .now) {
        guard turn.collected > 0 else { return nil }
        let cells = turn.cleared.filter { old.reward(of: [$0]) > 0 }
            .sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        guard !cells.isEmpty else { return nil }
        self.id = id; self.started = started; self.collected = turn.collected
        self.displayAward = turn.displayAward
        self.total = total; self.cells = cells
        contributors = cells.compactMap { cell in
            old.gem(at: cell).map { Contributor(cell: cell, identity: $0.identity, reward: old.reward(of: [cell])) }
        }
        // Only the validated input path supplied by the store names a constellation.
        self.path = path.isEmpty ? (recipe?.presentationPath ?? []) : path
        constellationPath = path
        patterns = path.isEmpty ? recipe.map { [Pattern(recipe: $0)] } ?? [] : []
        if relayDepth > 1 { level = .relay(relayDepth) }
        else if let recipe { level = .recipe(recipe.shape) }
        else {
            let largeClear = turn.collected >= 8 || (turn.award?.bonus ?? 0) > 0
            level = path.isEmpty ? (largeClear ? .brilliant : .ordinary) : .constellation
        }
    }
}

/// A bounded affine presentation of the exact committed walk. It never closes,
/// sorts or simplifies links, including revisits and empty-midpoint gaps.
struct ConstellationReturnLayout {
    static let maximumWalkEntries = FallingSky.side * FallingSky.side * 4
    static let maximumStars = FallingSky.side * FallingSky.side
    static let arrivalTime: TimeInterval = 0.92
    let walk: [Cell]
    let sourcePoints: [CGPoint]
    let destinationPoints: [CGPoint]
    let skyBounds: CGRect
    let labelBounds: CGRect

    init?(path: [Cell], board: CGRect, header: CGRect, award: CGRect, protectedSky: CGRect? = nil) {
        guard path.count > 1, path.count <= Self.maximumWalkEntries,
              Set(path).count <= Self.maximumStars,
              path.allSatisfy({ (0..<FallingSky.side).contains($0.row) && (0..<FallingSky.side).contains($0.column) }),
              ([board, header, award] + (protectedSky.map { [$0] } ?? [])).allSatisfy({ !$0.isNull && !$0.isInfinite &&
                  $0.minX.isFinite && $0.minY.isFinite && $0.width.isFinite && $0.height.isFinite }),
              board.width > 0, board.height > 0 else { return nil }
        let mapping = LandingGeometry(size: board.size)
        let arena = mapping.arenaFrame.offsetBy(dx: board.minX, dy: board.minY)
        let top = max(board.minY + 8, header.maxY + 8)
        let band = protectedSky?.insetBy(dx: 10, dy: 0)
            ?? CGRect(x: arena.minX + 10, y: top, width: arena.width - 20,
                      height: arena.minY - 10 - top)
        guard band.width >= 40, band.height >= 24 else { return nil }
        let sharesAwardBand = award.intersects(band)
        let width = min(120, band.width * 0.34)
        let height = min(100, band.height)
        let slot = CGRect(x: sharesAwardBand ? band.minX : band.midX - width / 2,
                          y: band.midY - height / 2, width: width, height: height)
        let labelLeft = max(award.minX, slot.maxX + 12)
        let label = sharesAwardBand
            ? CGRect(x: labelLeft, y: award.minY,
                     width: max(0, award.maxX - labelLeft), height: award.height)
            : award
        let source = path.map { cell in
            let point = mapping.viewPoint(cell)
            return CGPoint(x: point.x + board.minX, y: point.y + board.minY)
        }
        let xs = source.map(\.x), ys = source.map(\.y)
        guard let left = xs.min(), let right = xs.max(), let upper = ys.min(), let lower = ys.max() else { return nil }
        let center = CGPoint(x: (left + right) / 2, y: (upper + lower) / 2)
        let scale = min(0.7, (slot.width - 16) / max(1, right - left),
                        (slot.height - 16) / max(1, lower - upper))
        walk = path
        sourcePoints = source
        destinationPoints = source.map {
            CGPoint(x: slot.midX + ($0.x - center.x) * scale,
                    y: slot.midY + ($0.y - center.y) * scale)
        }
        skyBounds = slot
        labelBounds = label
    }

    static func returnProgress(at age: TimeInterval, quiet: Bool) -> Double {
        let elapsed = min(1, max(0, (age - 0.08) / (arrivalTime - 0.08)))
        return quiet ? 1 : elapsed * elapsed * (3 - 2 * elapsed)
    }

    func points(at age: TimeInterval, quiet: Bool = false) -> [CGPoint] {
        let progress = Self.returnProgress(at: age, quiet: quiet)
        return zip(sourcePoints, destinationPoints).map { start, end in
            CGPoint(x: start.x + (end.x - start.x) * progress,
                    y: start.y + (end.y - start.y) * progress)
        }
    }
}

/// Each actual recipe remains a separate subpath. One shared affine transform
/// preserves the original spacing and intersections of simultaneous patterns.
struct PatternReturnLayout {
    // Core can discover one square at each 2x2 origin, one cross at each
    // interior center and at most one >=4 run per family in each 7-cell axis.
    // This conservative geometry bound admits every committed recipe, including
    // wildcard-family lines, without truncating a real simultaneous phase.
    static let maximumPatterns = (FallingSky.side - 1) * (FallingSky.side - 1)
        + (FallingSky.side - 2) * (FallingSky.side - 2)
        + 2 * FallingSky.side * Jewel.allCases.count
    static let maximumPathEntries = 8 // cross retraces its center; lines have <=7
    let patterns: [StarlightCelebration.Pattern]
    let sourcePaths: [[CGPoint]]
    let destinationPaths: [[CGPoint]]
    let starCells: [Cell]
    let skyBounds: CGRect
    let labelBounds: CGRect

    init?(patterns: [StarlightCelebration.Pattern], board: CGRect, header: CGRect,
          award: CGRect, protectedSky: CGRect? = nil) {
        guard !patterns.isEmpty, patterns.count <= Self.maximumPatterns,
              patterns.allSatisfy({ pattern in
                  (2...Self.maximumPathEntries).contains(pattern.path.count)
                      && !pattern.cells.isEmpty && pattern.cells.count <= FallingSky.side
                      && Set(pattern.cells).count == pattern.cells.count
                      && pattern.starIDs.count == pattern.cells.count
                      && Set(pattern.path) == Set(pattern.cells)
              }) else { return nil }
        let footprint = Set(patterns.flatMap(\.cells)).sorted {
            $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
        }
        // The unique footprint supplies bounds only. Its ordering is NEVER
        // drawn: the original per-recipe presentation paths remain separate.
        guard let fit = ConstellationReturnLayout(path: footprint, board: board, header: header,
                                                  award: award, protectedSky: protectedSky) else { return nil }
        let source = Dictionary(uniqueKeysWithValues: zip(footprint, fit.sourcePoints))
        let destination = Dictionary(uniqueKeysWithValues: zip(footprint, fit.destinationPoints))
        self.patterns = patterns
        sourcePaths = patterns.map { $0.path.map { source[$0]! } }
        destinationPaths = patterns.map { $0.path.map { destination[$0]! } }
        starCells = footprint
        skyBounds = fit.skyBounds
        labelBounds = fit.labelBounds
    }

    func points(at age: TimeInterval, quiet: Bool = false) -> [[CGPoint]] {
        let progress = ConstellationReturnLayout.returnProgress(at: age, quiet: quiet)
        return zip(sourcePaths, destinationPaths).map { source, destination in
            zip(source, destination).map { start, end in
                CGPoint(x: start.x + (end.x - start.x) * progress,
                        y: start.y + (end.y - start.y) * progress)
            }
        }
    }
}

enum StarlightAnchor: Hashable { case board, score, header, award, constellationReturn, restorationLight, restorationScenery }
struct StarlightAnchors: PreferenceKey {
    static var defaultValue: [StarlightAnchor: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [StarlightAnchor: Anchor<CGRect>], nextValue: () -> [StarlightAnchor: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Adds one role without replacing anchors registered by descendants (score inside header).
    func starlightAnchor(_ role: StarlightAnchor) -> some View {
        transformAnchorPreference(key: StarlightAnchors.self, value: .bounds) { anchors, anchor in
            anchors[role] = anchor
        }
    }
}

/// Only this small subtree ticks. Board projection and the real header anchor share
/// the overlay's coordinate space; no screen-size assumptions or per-frame state writes.
struct StarlightCelebrationOverlay: View {
    let event: StarlightCelebration
    let board: CGRect
    let score: CGRect
    let header: CGRect
    let quiet: Bool
    var lightDestination: CGRect? = nil
    var awardBounds: CGRect? = nil
    var constellationBounds: CGRect? = nil
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: quiet)) { timeline in
            let age = quiet ? 0.3 : max(0, timeline.date.timeIntervalSince(event.started))
            let exit = min(1, max(0, (age - 1.08) / 0.32))
            let fade = quiet ? 1 : min(1, age / 0.07) * (1 - exit)
            let entrance = min(1, max(0, age - 0.04) / 0.22)
            let award = awardBounds ?? Self.awardRegion(board: board, header: header, accessible: textSize.isAccessibilitySize)
            let constellation = ConstellationReturnLayout(path: event.constellationPath, board: board, header: header,
                                                         award: award, protectedSky: constellationBounds)
            let patterns = PatternReturnLayout(patterns: event.patterns, board: board, header: header,
                                               award: award, protectedSky: constellationBounds)
            let region = constellation?.labelBounds ?? patterns?.labelBounds ?? award
            ZStack(alignment: .topLeading) {
                if !quiet || constellation != nil || patterns != nil {
                    Canvas { context, size in
                        if quiet {
                            if let constellation { drawConstellation(in: &context, layout: constellation, age: age, canvasSize: size) }
                            if let patterns { drawPatterns(in: &context, layout: patterns, age: age, canvasSize: size) }
                        } else {
                            draw(in: &context, age: age, canvasSize: size, constellation: constellation, patterns: patterns)
                        }
                    }
                }
                CrystalCelebrationLabel(event: event, tint: accent, width: region.width - 12,
                                        height: region.height - 8, showsTitle: !textSize.isAccessibilitySize,
                                        age: age, quiet: quiet)
                .multilineTextAlignment(.center)
                .shadow(color: StarfallTheme.Colors.skyTop, radius: 3)
                .shadow(color: accent.opacity(0.8), radius: quiet ? 0 : 4)
                .scaleEffect(quiet ? 1 : 0.84 + 0.16 * entrance)
                .offset(y: quiet ? 0 : 4 * (1 - entrance) - 4 * exit * exit)
                .frame(width: region.width, height: region.height)
                // Bound glyphs, glow and movement together. A larger reward must
                // never expand into a playable row or cover the score/header.
                .clipped()
                .position(x: region.midX, y: region.midY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .opacity(fade)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// One protected region for every award category, independent of occupied
    /// cells or animation positions. Large text has a separate guide below the canvas.
    static func awardRegion(board: CGRect, header: CGRect, accessible: Bool) -> CGRect {
        let mapping = LandingGeometry(size: board.size, largeHeader: accessible)
        let top = accessible ? board.minY + mapping.frame(Cell(0, 3)).maxY + 8 : header.maxY + 4
        let bottom = accessible ? board.minY + mapping.accessibleCanvasEnd - 8 : board.minY + mapping.frame(Cell(6, 3)).minY - 8
        return CGRect(x: board.minX + mapping.arenaFrame.minX + 8, y: top,
                      width: max(0, mapping.arenaFrame.width - 16), height: max(0, bottom - top))
    }

    private func color(_ contributor: StarlightCelebration.Contributor) -> Color {
        Color(StarCast.Identity(contributor.identity).color)
    }
    private var accent: Color {
        event.contributors.max(by: { $0.reward < $1.reward }).map(color) ?? .white
    }

    private func location(_ cell: Cell) -> CGPoint {
        let local = LandingGeometry(size: board.size).viewPoint(cell)
        return CGPoint(x: local.x + board.minX, y: local.y + board.minY)
    }

    private func draw(in context: inout GraphicsContext, age: Double, canvasSize: CGSize,
                      constellation: ConstellationReturnLayout?, patterns: PatternReturnLayout?) {
        guard age < StarlightCelebration.duration else { return }
        let points = event.cells.map(location)
        let origin = CGPoint(x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
                             y: points.map(\.y).reduce(0, +) / CGFloat(points.count))
        let energy = event.energy
        let strong = event.level != .ordinary
        let step = LandingGeometry(size: board.size).starStep
        if event.isExceptional, age < 0.85 {
            let t = min(1, max(0, age - 0.06) / 0.79)
            var aurora = context
            aurora.opacity = sin(t * .pi) * (0.16 + 0.12 * energy)
            let center = CGPoint(x: board.midX, y: board.minY + board.height * 0.45)
            aurora.fill(Path(board), with: .radialGradient(
                Gradient(colors: [accent, accent.opacity(0)]), center: center,
                startRadius: 0, endRadius: board.width * (0.65 + 0.35 * t)))
        }
        if age < 0.5 {
            let release = min(1, max(0, (age - 0.08) / 0.4))
            var pulse = context
            pulse.opacity = (1 - release) * (strong ? 0.95 : 0.6)
            // One finite budget per clear, independent of the selected star count.
            for index in 0..<(strong ? 24 : 10) {
                let angle = Double(index) * 2.39996
                let reach = Double((index * 7) % 13) / 12
                let distance = step * (0.08 + 0.35 * reach + release * (0.5 + (1.6 + energy) * reach))
                let point = CGPoint(x: origin.x + cos(angle) * distance, y: origin.y + sin(angle) * distance * 0.72)
                glint(in: &pulse, at: point, radius: index.isMultiple(of: 3) ? 4 : 2, color: color(event.contributors[index % event.contributors.count]))
            }
            if constellation == nil, event.patterns.isEmpty, !event.path.isEmpty {
                var outline = Path()
                outline.addLines(event.path.map(location))
                pulse.stroke(outline, with: .color(.white), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
        }
        if let constellation { drawConstellation(in: &context, layout: constellation, age: age, canvasSize: canvasSize) }
        if let patterns { drawPatterns(in: &context, layout: patterns, age: age, canvasSize: canvasSize) }
        drawPackets(in: &context, age: age, canvasSize: canvasSize)
        if age > 0.58 {
            let t = min(1, (age - 0.58) / 0.65)
            var bloom = context
            bloom.opacity = sin(t * .pi) * 0.9
            bloom.addFilter(.shadow(color: accent, radius: 5))
            let bounds = score.insetBy(dx: -8 - 5*t, dy: -3 - 3*t)
            bloom.stroke(Path(roundedRect: bounds, cornerRadius: 18), with: .color(accent), lineWidth: 1.5 + energy * 2)
            glint(in: &bloom, at: CGPoint(x: score.maxX + 8, y: score.minY), radius: 5, color: accent)
        }
    }

    /// The figure is passive ink, with no new nodes, clock or completion callback.
    /// The existing latest-only receipt owns its full 1.4-second lifetime.
    func drawConstellation(in context: inout GraphicsContext, layout: ConstellationReturnLayout,
                           age: Double, canvasSize: CGSize) {
        guard age < StarlightCelebration.duration else { return }
        let points = layout.points(at: age, quiet: quiet)
        var ink = context
        for exclusion in [score.insetBy(dx: -6, dy: -6), header, layout.labelBounds] where !exclusion.isEmpty {
            var visible = Path(CGRect(origin: .zero, size: canvasSize))
            visible.addRect(exclusion)
            ink.clip(to: visible, style: FillStyle(eoFill: true))
        }
        ink.opacity = quiet ? 1 : min(1, max(0, age / 0.07))
        var outline = Path()
        outline.addLines(points)
        var glow = ink
        if !quiet { glow.addFilter(.shadow(color: accent, radius: 4)) }
        glow.stroke(outline, with: .color(accent.opacity(0.75)),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        glow.stroke(outline, with: .color(.white),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        var drawn = Set<Cell>()
        for (cell, point) in zip(layout.walk, points) where drawn.insert(cell).inserted {
            glint(in: &glow, at: point, radius: quiet ? 3 : 3.5, color: .white)
        }
    }

    /// Automatic geometry shares the manual return's Canvas and affine fitting,
    /// while every recipe starts its own subpath and shared ingredients glint once.
    func drawPatterns(in context: inout GraphicsContext, layout: PatternReturnLayout,
                      age: Double, canvasSize: CGSize) {
        guard age < StarlightCelebration.duration else { return }
        let paths = layout.points(at: age, quiet: quiet)
        var ink = context
        for exclusion in [score.insetBy(dx: -6, dy: -6), header, layout.labelBounds] where !exclusion.isEmpty {
            var visible = Path(CGRect(origin: .zero, size: canvasSize))
            visible.addRect(exclusion)
            ink.clip(to: visible, style: FillStyle(eoFill: true))
        }
        ink.opacity = quiet ? 1 : min(1, max(0, age / 0.07))
        var outline = Path()
        for points in paths {
            guard let first = points.first else { continue }
            outline.move(to: first)
            for point in points.dropFirst() { outline.addLine(to: point) }
        }
        var glow = ink
        if !quiet { glow.addFilter(.shadow(color: accent, radius: 4)) }
        glow.stroke(outline, with: .color(accent.opacity(0.75)),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        glow.stroke(outline, with: .color(.white),
                    style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
        var drawn = Set<Cell>()
        for (pattern, points) in zip(layout.patterns, paths) {
            for (cell, point) in zip(pattern.path, points) where drawn.insert(cell).inserted {
                glint(in: &glow, at: point, radius: quiet ? 3 : 3.5, color: .white)
            }
        }
    }

    /// The same packet pass serves the live Canvas and fixed-age raster checks.
    func drawPackets(in context: inout GraphicsContext, age: Double, canvasSize: CGSize) {
        let energy = event.energy
        // Six packets maximum. All represent one committed award, not individual points.
        let target = lightDestination ?? score
        let destination = CGPoint(x: target.midX, y: target.midY)
        let flight = StarlightCelebration.packetFlight(toRestoration: lightDestination != nil)
        // Clip the composited light, including its shadow, outside the measured
        // score instrument. Paths and arrivals stay unchanged; the separate
        // arrival bloom still acknowledges collection around the instrument.
        var packets = context
        if !score.isEmpty, !score.isNull, !score.isInfinite {
            var visible = Path(CGRect(origin: .zero, size: canvasSize))
            visible.addRect(score.insetBy(dx: -4, dy: -4))
            packets.clip(to: visible, style: FillStyle(eoFill: true))
        }
        packets.drawLayer { layer in
            for (index, contributor) in event.packets.enumerated() {
                let point = location(contributor.cell)
                let emission = LivingLight.emission(for: StarCast.Identity(contributor.identity))
                let tint = Color(emission.family)
                let center = Color(emission.center)
                let weight = Double(contributor.reward - 1) * 0.65
                let t = flight.progress(at: age, packetIndex: index)
                guard t > 0, t < 1 else { continue }
                let control = CGPoint(x: point.x - board.width * 0.18, y: destination.y + (point.y - destination.y) * 0.35)
                func along(_ progress: Double) -> CGPoint {
                    let u = 1 - progress
                    return CGPoint(x: u*u*point.x + 2*u*progress*control.x + progress*progress*destination.x,
                                   y: u*u*point.y + 2*u*progress*control.y + progress*progress*destination.y)
                }
                var tail = Path()
                tail.addLines((0...12).map { along(max(0, t - 0.22 + Double($0) / 12 * 0.22)) })
                var glow = layer
                glow.addFilter(.shadow(color: tint, radius: 4 + 5 * energy))
                glow.stroke(tail, with: .color(tint.opacity(0.3)), style: StrokeStyle(lineWidth: 7 + energy * 7 + weight, lineCap: .round))
                glow.stroke(tail, with: .color(center), style: StrokeStyle(lineWidth: 2 + energy * 3 + weight, lineCap: .round))
                glint(in: &glow, at: along(t), radius: 3.5 + energy * 3 + weight, color: center)
            }
        }
    }

    private func glint(in context: inout GraphicsContext, at point: CGPoint, radius: CGFloat, color: Color) {
        var star = Path()
        star.move(to: CGPoint(x: point.x, y: point.y - radius))
        star.addLines([CGPoint(x: point.x + radius*0.3, y: point.y - radius*0.3), CGPoint(x: point.x + radius, y: point.y),
                       CGPoint(x: point.x + radius*0.3, y: point.y + radius*0.3), CGPoint(x: point.x, y: point.y + radius),
                       CGPoint(x: point.x - radius*0.3, y: point.y + radius*0.3), CGPoint(x: point.x - radius, y: point.y),
                       CGPoint(x: point.x - radius*0.3, y: point.y - radius*0.3)])
        star.closeSubpath()
        context.fill(star, with: .color(color))
    }
}
