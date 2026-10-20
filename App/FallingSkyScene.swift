import UIKit
import SpriteKit
import StarfallCore

/// Only presents committed turns. The view supplies native, full-cell buttons.
@MainActor final class FallingSkyScene: SKScene, FallingSkyPresenting {
    var reduceMotion = false { didSet { refreshGrowthMotion() } }
    var decorativeMotionActive = true { didSet { refreshGrowthMotion() } }
    var onLayout: (() -> Void)?
    var onReadinessChanged: ((Bool) -> Void)?
    private var nodes: [Int: FallingSkyCharacter] = [:]
    private var cellsByID: [Int: Cell] = [:]
    private var rendered: FallingSky?
    private var openingPrepared = false
    private var animatingColumns: Set<Int> = []
    private let pieces = SKNode(), effects = SKNode(), grid = SKNode()
    private let constellationTrail = SKNode()
    private let bufferedInputLayer = SKNode()
    private var step: CGFloat { LandingGeometry(size: size).starStep }

    override init(size: CGSize) {
        super.init(size: size)
        SkyPiece.prewarm(); SkyPieceMotion.prewarm()
        scaleMode = .resizeFill; backgroundColor = .clear
        addChild(grid); addChild(pieces); addChild(effects)
        effects.zPosition = 20
        constellationTrail.zPosition = 12; addChild(constellationTrail)
        bufferedInputLayer.zPosition = 13; addChild(bufferedInputLayer)
    }
    override convenience init() { self.init(size: CGSize(width: 350, height: 350)) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != size else { return }
        onLayout?()
        reportReadiness()
    }
    override func didMove(to view: SKView) {
        if let rendered {
            if openingPrepared { prepareOpening(rendered) }
            else { render(rendered) }
        }
        reportReadiness()
    }
    override func willMove(from view: SKView) {
        for node in nodes.values { node.setGrowthMotion(false); node.setPieceMotion(false) }
        cancelFlightPoses()
        onReadinessChanged?(false); onLayout?()
    }

    private func reportReadiness() {
        guard let view else { onReadinessChanged?(false); return }
        onReadinessChanged?(size.width > 0 && size.height > 0 &&
            abs(size.width - view.bounds.width) < 1 && abs(size.height - view.bounds.height) < 1)
    }

    private func point(_ cell: Cell) -> CGPoint {
        LandingGeometry(size: size).scenePoint(cell)
    }

    private func makeNode(_ gem: StarfallGem) -> FallingSkyCharacter {
        let node = FallingSkyCharacter(gem: gem, step: step)
        node.setGrowthMotion(growthMotionEnabled)
        node.setPieceMotion(pieceMotionEnabled)
        return node
    }

    private var pieceMotionEnabled: Bool {
        decorativeMotionActive && !reduceMotion && !UIAccessibility.isReduceMotionEnabled
            && !UIAccessibility.isVoiceOverRunning
    }

    private var growthMotionEnabled: Bool {
        pieceMotionEnabled && rendered?.isOver != true
    }

    private func refreshGrowthMotion() {
        for node in nodes.values {
            node.setGrowthMotion(growthMotionEnabled)
            node.setPieceMotion(pieceMotionEnabled)
        }
        if !pieceMotionEnabled { cancelFlightPoses() }
    }

    private func cancelFlightPoses() {
        for flight in effects.children where flight.name?.hasPrefix("sky.flight.") == true {
            for sprite in flight.children.compactMap({ $0 as? SKSpriteNode }) {
                SkyPieceMotion.reset(sprite)
            }
        }
    }

    /// A removed character may still finish its exit animation; its idle decoration ends now.
    private func takeCharacter(_ id: Int) -> FallingSkyCharacter? {
        let node = nodes.removeValue(forKey: id)
        node?.setGrowthMotion(false)
        node?.setPieceMotion(false)
        return node
    }

    private func light(at anchor: CGPoint, color: UIColor, strength: CGFloat) {
        // A small radial clear glow in open space; never a projected floor reflection.
        for index in 0..<2 {
            let pool = SKShapeNode(ellipseOf: CGSize(width: step * (index == 0 ? 0.95 : 0.48),
                                                     height: step * (index == 0 ? 0.95 : 0.48)))
            pool.name = "sky.clear-light"
            pool.position = anchor
            pool.fillColor = color.withAlphaComponent((index == 0 ? 0.16 : 0.24) * strength)
            pool.strokeColor = .clear; pool.glowWidth = index == 0 ? 4 : 1
            pool.blendMode = .add; pool.zPosition = -effects.zPosition - 1
            effects.addChild(pool)
            pool.run(.sequence([.group([.scale(to: 1.25, duration: 0.25), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
        }
    }

    private func shade(_ node: SKNode) { node.alpha = 0.65 }

    func render(_ game: FallingSky) { renderSnapshot(game, preservingInput: false) }

    private func renderSnapshot(_ game: FallingSky, preservingInput: Bool) {
        rendered = game
        openingPrepared = false
        if !preservingInput { constellationTrail.removeAllChildren(); showBufferedInput(nil) }
        removeAllActions(); cancelFlightPoses(); effects.removeAllChildren(); effects.removeAllActions()
        for node in nodes.values { node.setGrowthMotion(false); node.setPieceMotion(false) }
        pieces.removeAllChildren(); grid.removeAllChildren(); nodes.removeAll(); cellsByID.removeAll()
        animatingColumns.removeAll()
        renderColumns(Set(0..<7), from: game)
        renderGravityField(game.orbit)
    }

    private func renderColumns(_ columns: Set<Int>, from game: FallingSky) {
        let removed = cellsByID.filter { columns.contains($0.value.column) }.map(\.key)
        for id in removed { takeCharacter(id)?.removeFromParent(); cellsByID.removeValue(forKey: id) }
        for node in grid.children where columns.contains(node.userData?["column"] as? Int ?? -1) { node.removeFromParent() }
        for row in 0..<7 { for column in columns.sorted() {
            let cell = Cell(row, column)
            if let gem = game.gem(at: cell) {
                let node = makeNode(gem); node.position = point(cell)
                node.zPosition = CGFloat(7-cell.row)
                if game.isGrowthBlocked(at: cell) { shade(node) }
                DuskPresentation.configure(node, game: game, cell: cell, step: step)
                CriticalMassPresentation.configure(node, game: game, cell: cell, step: step)
                if let threats = StarCollapsePresentation.threats(game: game, cell: cell, point: point, step: step) { grid.addChild(threats) }
                pieces.addChild(node); nodes[gem.id] = node; cellsByID[gem.id] = cell
            }
        } }
    }

    private func finishColumns(_ columns: Set<Int>, completion: () -> Void) {
        let previousDrain = nodes.mapValues { $0.userData?["dusk.drained"] as? Bool ?? false }
        animatingColumns.subtract(columns)
        if let rendered {
            if animatingColumns.isEmpty { renderSnapshot(rendered, preservingInput: true) }
            else {
                renderColumns(columns, from: rendered)
                for (id, cell) in cellsByID where !animatingColumns.contains(cell.column) {
                    nodes[id]?.alpha = rendered.isGrowthBlocked(at: cell) ? 0.65 : 1
                }
            }
            if !reduceMotion && !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning {
                for (id, cell) in cellsByID where !animatingColumns.contains(cell.column) {
                    if let node = nodes[id] {
                        DuskPresentation.transition(node, wasDrained: previousDrain[id] ?? false,
                            drained: rendered.isDrained(at: cell), effects: effects, step: step)
                    }
                }
            }
        }
        completion()
    }

    func animate(_ turn: FallingSkyTurn, from old: FallingSky,
                 to game: FallingSky, completion: @escaping () -> Void) {
        animate(turn, from: old, to: game, phaseBegan: { _ in }, completion: completion)
    }

    func animate(_ turn: FallingSkyTurn, from old: FallingSky,
                 to game: FallingSky, phaseBegan: @escaping (Int) -> Void,
                 completion: @escaping () -> Void) {
        if !turn.resolutionPhases.isEmpty {
            precondition(animatingColumns.isEmpty, "Recipe resolution owns the whole board")
            animateResolution(turn, from: old, to: game,
                              phaseBegan: phaseBegan, completion: completion)
            return
        }
        if !turn.presentationPhases.isEmpty {
            precondition(animatingColumns.isEmpty, "Gravity presentation owns the whole board")
            animatePhases(turn, from: old, to: game, completion: completion); return
        }
        if animatingColumns.isEmpty && rendered != old { render(old) }
        let columns = turn.changingColumns
        precondition(columns.isDisjoint(with: animatingColumns), "Overlapping presentation ownership")
        renderColumns(columns, from: old)
        animatingColumns.formUnion(columns)
        rendered = game
        if view == nil { render(game); completion(); return }
        if reduceMotion || UIAccessibility.isReduceMotionEnabled || UIAccessibility.isVoiceOverRunning {
            // The committed quiet board is already final; release its input ownership now.
            finishColumns(columns, completion: completion)
            return
        }
        for cell in turn.cleared {
            if let id = old.gem(at: cell)?.id, let node = takeCharacter(id) {
                node.update(node.gem, expression: .clearing)
                cellsByID.removeValue(forKey: id)
                run(.sequence([.wait(forDuration: StarfallMotion.gatherDuration), .run { [weak self] in
                    guard let self else { return }
                    self.light(at: self.point(cell), color: old.gem(at: cell).map { StarCast.Identity($0).color } ?? .systemPurple, strength: 0.75)
                }]))
                node.run(.sequence([.scale(to: 0.91, duration: StarfallMotion.gatherDuration), .group([.fadeOut(withDuration: 0.12), .scale(to: 1.2, duration: 0.12), .rotate(byAngle: 0.18, duration: 0.12)]), .removeFromParent()]))
            }
        }
        if turn.collected == 0, !turn.cleared.isEmpty {
            let label = SKLabelNode(text: "+\(turn.collected)")
            label.fontName = "AvenirNext-Bold"; label.fontSize = step * 0.55
            label.fontColor = .white; label.verticalAlignmentMode = .center
            let center = turn.cleared.map { point($0) }.reduce(CGPoint.zero) {
                CGPoint(x: $0.x + $1.x, y: $0.y + $1.y)
            }
            label.position = CGPoint(x: center.x / CGFloat(turn.cleared.count), y: center.y / CGFloat(turn.cleared.count))
            effects.addChild(label)
            label.run(.sequence([.group([.moveBy(x: 0, y: step * 0.45, duration: 0.32), .fadeOut(withDuration: 0.32)]), .removeFromParent()]))
        }
        ripple(turn, from: old)
        var exchangeDuration = StarfallMotion.exchangeSlideDuration
        for index in turn.settled.indices where columns.contains(index % 7) {
            if let gem = turn.settled[index], let node = nodes[gem.id],
               cellsByID[gem.id] != Cell(index/7, index%7) || turn.exchange.map({
                   old.gem(at: $0.from)?.id == gem.id || old.gem(at: $0.to)?.id == gem.id
               }) == true {
                let waypoint = turn.exchange.flatMap { exchange -> Cell? in
                    if old.gem(at:exchange.from)?.id == gem.id { return exchange.to }
                    if old.gem(at:exchange.to)?.id == gem.id { return exchange.from }
                    return nil
                }
                let restingCell = Cell(index/7, index%7)
                let settles = (waypoint ?? cellsByID[gem.id]) != restingCell
                let settlingDuration: TimeInterval = settles ? 0.20 : 0
                exchangeDuration = max(exchangeDuration, StarfallMotion.exchangeSlideDuration + settlingDuration)
                let move = SKAction.move(to: point(restingCell), duration: settlingDuration)
                move.timingMode = .easeInEaseOut
                let lead = waypoint.map { SKAction.move(to:point($0),duration:StarfallMotion.exchangeSlideDuration) }
                    ?? .wait(forDuration:turn.exchange == nil ? StarfallMotion.gravityStart : StarfallMotion.exchangeSlideDuration)
                node.run(.sequence([lead,move]),withKey:"sky.settle")

            }
        }
        if turn.arrivals.isEmpty {
            run(.sequence([.wait(forDuration: turn.exchange == nil ? StarfallMotion.clearDuration : exchangeDuration), .run { [weak self] in self?.finishColumns(columns, completion: completion) }]))
            return
        }
        run(.sequence([arrivalFlights(turn.arrivals), .wait(forDuration: StarfallMotion.landingDuration),
                       .run { [weak self] in self?.finishColumns(columns, completion: completion) }]))
    }

    /// One outward impulse per survivor, from its nearest cleared star. No cascades or rule changes.
    private func ripple(_ turn: FallingSkyTurn, from old: FallingSky) {
        let sources = turn.cleared.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        guard !sources.isEmpty else { return }
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            guard !animatingColumns.contains(column) || turn.changingColumns.contains(column) else { continue }
            guard !turn.cleared.contains(cell), let gem = old.gem(at: cell), let node = nodes[gem.id] else { continue }
            let origin = point(cell)
            guard let source = sources.min(by: {
                hypot(point($0).x - origin.x, point($0).y - origin.y) < hypot(point($1).x - origin.x, point($1).y - origin.y)
            }) else { continue }
            let delta = CGPoint(x: origin.x - point(source).x, y: origin.y - point(source).y)
            let distance = hypot(delta.x, delta.y)
            guard distance > 0, distance < step * 3 else { continue }
            let strength = StarfallMotion.ripple(distance: distance / step, collected: turn.collected,
                                                heavy: gem.isDark || gem.grown) * step
            let impulse = CGVector(dx: delta.x / distance * strength / step,
                                   dy: delta.y / distance * strength / step)
            let sourcePoint = point(source), spacing = step
            node.run(.sequence([.wait(forDuration: StarfallMotion.gatherDuration + Double(distance / step) * 0.025),
                                .run { [weak node] in
                                    node?.acknowledge(from: sourcePoint, impulse: impulse, step: spacing)
                                }]),
                     withKey: "sky.ripple")
        } }
    }

    /// A visual arrival can describe either a committed shower or the reveal of
    /// an already saved opening. Constructing one never changes the game.
    private struct ArrivalPresentation {
        let star: IncomingStar
        let cell: Cell
        let gem: StarfallGem
        let grew: Bool

        init(_ arrival: FallingSkyTurn.Arrival) {
            star = arrival.star; cell = arrival.cell; gem = arrival.gem; grew = arrival.grew
        }
        init(gem: StarfallGem, cell: Cell) {
            star = IncomingStar(id: gem.id, kind: gem.kind, column: cell.column,
                                light: gem.isLight, gravity: gem.gravityKind)
            self.cell = cell; self.gem = gem; grew = false
        }
    }

    private func receiver(for arrival: ArrivalPresentation) -> FallingSkyCharacter? {
        if arrival.grew { return nodes[arrival.gem.id] }
        let direction = StarfallMotion.drift(for: arrival.star.id, column: arrival.cell.column) > 0 ? 1 : -1
        let side = Cell(arrival.cell.row, arrival.cell.column - direction)
        let below = Cell(arrival.cell.row - 1, arrival.cell.column)
        for cell in [side, below] {
            guard let id = cellsByID.first(where: { $0.value == cell })?.key, let node = nodes[id],
                  node.gem.gravityKind != .magnet else { continue }
            let offset = point(cell)
            let target = point(arrival.cell)
            guard hypot(offset.x-target.x, offset.y-target.y) <= step * 1.15 else { continue }
            return node
        }
        return nil
    }

    /// Both ordinary and gravity turns share full approach, stagger and contact.
    private func arrivalFlights(_ arrivals: [FallingSkyTurn.Arrival]) -> SKAction {
        arrivalFlights(arrivals.map(ArrivalPresentation.init),
                       duration: StarfallMotion.flightDuration, stagger: StarfallMotion.arrivalStagger)
    }

    private func arrivalFlights(_ arrivals: [ArrivalPresentation],
                                duration: TimeInterval, stagger: TimeInterval) -> SKAction {
        .group(arrivals.enumerated().map { index, arrival in
            .sequence([.wait(forDuration: Double(index) * stagger),
                       .run { [weak self] in self?.sendStar(arrival, duration: duration) },
                       .wait(forDuration: duration),
                       .run { [weak self] in self?.land(arrival) }])
        })
    }

    private func sendStar(_ arrival: ArrivalPresentation, duration: TimeInterval) {
        let comet = SKNode()
        comet.name = "sky.flight.\(arrival.star.id)"
        let color = StarCast.Identity(arrival.star).color
        // A bounded handful of shapes per star, with no emitters or accumulating particles.
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -step * 0.13, y: 0))
        tailPath.addQuadCurve(to: CGPoint(x: 0, y: step * 2.7), control: CGPoint(x: -step * 0.08, y: step))
        tailPath.addQuadCurve(to: CGPoint(x: step * 0.13, y: 0), control: CGPoint(x: step * 0.08, y: step))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = color.withAlphaComponent(arrival.star.isLight ? 0.14 : 0.3); tail.strokeColor = .clear
        tail.glowWidth = arrival.star.isLight ? 2 : 4
        comet.addChild(tail)
        let halo = SKShapeNode(circleOfRadius: step * 0.20)
        halo.fillColor = color.withAlphaComponent(arrival.star.isLight ? 0.06 : 0.3)
        halo.strokeColor = color.withAlphaComponent(arrival.star.isLight ? 0.10 : 0.5)
        halo.glowWidth = arrival.star.isLight ? 3 : 9
        comet.addChild(halo)
        let drift = StarfallMotion.drift(for: arrival.star.id, column: arrival.cell.column) * step
        let traveler = SkyPiece.makeNode(for: .init(arrival.star), radius: step * StarfallMotion.pieceRadius)
        if pieceMotionEnabled {
            SkyPieceMotion.prepareFlight(traveler, identity: .init(arrival.star), direction: drift < 0 ? -1 : 1)
        }
        comet.addChild(traveler)
        comet.position = CGPoint(x: point(arrival.cell).x - drift, y: size.height + step)
        // Align the tail with the actual incoming vector.
        comet.zRotation = atan2(drift, comet.position.y - point(arrival.cell).y)
        effects.addChild(comet)
        let destination = point(arrival.cell)
        let receiver = receiver(for: arrival)
        let receiverCell = receiver.flatMap { cellsByID[$0.gem.id] }
        let contact: CGPoint? = receiverCell.map { cell in
            let anchor = point(cell)
            let receiverRadius = StarfallMotion.pieceRadius * (receiver.map { FallingSkyCharacter.bodyScale(for: $0.gem) } ?? 1)
            let combinedRadius = step * (StarfallMotion.pieceRadius + receiverRadius)
            if arrival.grew { return CGPoint(x: anchor.x - drift * 0.05, y: anchor.y + combinedRadius) }
            if cell.row == arrival.cell.row {
                return CGPoint(x: anchor.x + (destination.x > anchor.x ? combinedRadius : -combinedRadius), y: anchor.y + step * 0.12)
            }
            return CGPoint(x: anchor.x + drift * 0.08, y: anchor.y + combinedRadius * 0.97)
        }
        let flight = StarfallMotion.Flight(start: comet.position, destination: destination, contact: contact, step: step)
        let fall = SKAction.customAction(withDuration: duration) { node, elapsed in
            node.position = flight.point(at: elapsed / CGFloat(duration))
        }
        if let receiver, let receiverCell, let contact {
            let resistance = StarfallMotion.resistance(receiver.gem)
            let impulse = CGVector(dx: (contact.x > point(receiverCell).x ? -0.10 : 0.10) * resistance,
                                   dy: -0.035 * resistance)
            comet.run(.sequence([.wait(forDuration: duration * Double(StarfallMotion.contactFraction)),
                                 .run { [weak self, weak receiver] in
                                     guard let self, let receiver else { return }
                                     receiver.acknowledge(from: contact, impulse: impulse, step: self.step)
                                     self.light(at: self.point(receiverCell), color: color, strength: arrival.star.isDark ? 0.25 : 0.75)
                                 }]))
        } else {
            // One nearby observer, with no invented physical kick across an empty gap.
            let observer = cellsByID.compactMap { id, cell -> (FallingSkyCharacter, CGPoint)? in
                guard let node = nodes[id], id != arrival.gem.id else { return nil }
                let anchor = point(cell)
                let distance = hypot(anchor.x-destination.x, anchor.y-destination.y)
                return distance > 0 && distance < step * 1.7 ? (node, anchor) : nil
            }.sorted { a, b in
                let da = hypot(a.1.x-destination.x, a.1.y-destination.y)
                let db = hypot(b.1.x-destination.x, b.1.y-destination.y)
                return da == db ? a.0.gem.id < b.0.gem.id : da < db
            }.first?.0
            if let observer {
                let responseDelay = duration * StarfallMotion.receiverResponseDelay / StarfallMotion.flightDuration
                comet.run(.sequence([.wait(forDuration: responseDelay), .run { [weak observer] in
                    observer?.acknowledge(from: destination, impulse: .zero, step: flight.step)
                }]))
            }
        }
        tail.run(.sequence([.wait(forDuration: duration * 0.34 / StarfallMotion.flightDuration),
                            .fadeOut(withDuration: duration * 0.14 / StarfallMotion.flightDuration)]))
        comet.run(.sequence([fall, .removeFromParent()]))
    }

    private func land(_ arrival: ArrivalPresentation) {
        // Scene actions and child actions can advance on adjacent frames. The
        // landing handoff owns removal, so one committed star has one visible body.
        effects.childNode(withName: "sky.flight.\(arrival.star.id)")?.removeFromParent()
        let existing = nodes[arrival.gem.id]
        let node = existing ?? makeNode(arrival.gem)
        node.update(arrival.gem, expression: .landing)
        let destination = point(arrival.cell)
        node.position = destination
        node.zPosition = CGFloat(7-arrival.cell.row)
        if existing == nil { pieces.addChild(node) }
        nodes[arrival.gem.id] = node; cellsByID[arrival.gem.id] = arrival.cell
        if arrival.gem.gravityKind == .magnet {
            node.character.run(.sequence([.fadeAlpha(to: 0.55, duration: 0.12),
                                          .fadeAlpha(to: 1, duration: 0.16)]), withKey: "gravity.field-formation")
            return
        }
        light(at: destination, color: StarCast.Identity(arrival.star).color,
              strength: arrival.gem.isDark ? 0.25 : arrival.grew ? 1 : 0.65)
        let drift = StarfallMotion.drift(for: arrival.star.id, column: arrival.cell.column) * step
        if pieceMotionEnabled { node.land(direction: drift < 0 ? -1 : 1, step: step) }
    }
}


extension FallingSkyScene {
    private enum ResolutionMotion {
        static let pop: TimeInterval = 0.22
        static let settle: TimeInterval = 0.20
        static let readSettled: TimeInterval = 0.04
        static let openingFlight: TimeInterval = 0.34
        static let openingStagger: TimeInterval = 0.022
    }

    /// Stage the committed board before Entry hands over the playfield, without
    /// exposing its resting stars for a frame before their reveal.
    func prepareOpening(_ game: FallingSky) {
        render(game)
        for id in Array(nodes.keys) { takeCharacter(id)?.removeFromParent() }
        cellsByID.removeAll()
        grid.removeAllChildren()
        openingPrepared = true
    }

    /// The Store calls this only for a newly begun/replayed round. A restored
    /// board uses render(_:), so the saved opening is never earned or replayed.
    func presentOpening(_ game: FallingSky, completion: @escaping () -> Void) {
        prepareOpening(game)
        guard view != nil, !reduceMotion, !UIAccessibility.isReduceMotionEnabled,
              !UIAccessibility.isVoiceOverRunning else { render(game); completion(); return }
        let arrivals = game.board.enumerated().compactMap { index, gem in
            gem.map { ArrivalPresentation(gem: $0, cell: Cell(index / 7, index % 7)) }
        }
        guard !arrivals.isEmpty else { render(game); completion(); return }
        openingPrepared = false
        animatingColumns = Set(0..<7)
        run(.sequence([
            arrivalFlights(arrivals, duration: ResolutionMotion.openingFlight,
                           stagger: ResolutionMotion.openingStagger),
            .wait(forDuration: 0.25),
            .run { [weak self] in
                guard let self else { return }
                self.render(game)
                completion()
            }
        ]), withKey: "sky.opening")
    }

    private func animateResolution(_ turn: FallingSkyTurn, from old: FallingSky,
                                   to game: FallingSky, phaseBegan: @escaping (Int) -> Void,
                                   completion: @escaping () -> Void) {
        render(old)
        rendered = game
        guard view != nil, !reduceMotion, !UIAccessibility.isReduceMotionEnabled,
              !UIAccessibility.isVoiceOverRunning else { render(game); completion(); return }
        guard let first = turn.resolutionPhases.first else { render(game); completion(); return }
        animatingColumns = Set(0..<7)
        var actions: [SKAction] = []
        if let exchange = turn.exchange {
            actions += [.run { [weak self] in
                guard let self else { return }
                for (source, destination) in [(exchange.from, exchange.to), (exchange.to, exchange.from)] {
                    guard let gem = old.gem(at: source), let node = self.nodes[gem.id] else { continue }
                    let slide = SKAction.move(to: self.point(destination),
                                              duration: StarfallMotion.exchangeSlideDuration)
                    slide.timingMode = .easeInEaseOut
                    node.run(slide, withKey: "sky.exchange")
                }
            }, .wait(forDuration: StarfallMotion.exchangeSlideDuration),
            .run { [weak self] in
                self?.settleResolutionBoard(first.before, duration: ResolutionMotion.settle)
            }, .wait(forDuration: ResolutionMotion.settle)]
        } else if !turn.arrivals.isEmpty {
            actions += [arrivalFlights(turn.arrivals), .wait(forDuration: StarfallMotion.landingDuration)]
        }
        for (index, phase) in turn.resolutionPhases.enumerated() {
            actions += [
                .run { [weak self] in
                    guard let self else { return }
                    self.popResolution(phase)
                    phaseBegan(index)
                },
                .wait(forDuration: ResolutionMotion.pop),
                .run { [weak self] in
                    self?.settleResolutionBoard(phase.settled, duration: ResolutionMotion.settle)
                },
                .wait(forDuration: ResolutionMotion.settle + ResolutionMotion.readSettled)
            ]
        }
        actions.append(.run { [weak self] in
            guard let self else { return }
            self.render(game)
            completion()
        })
        run(.sequence(actions), withKey: "sky.resolution")
    }

    private func popResolution(_ phase: SkyResolutionPhase) {
        // The preceding flight/fall is finished. Use Core's exact identities and
        // cells even when a later phase reuses a cell cleared earlier.
        settleResolutionBoard(phase.before, duration: 0)
        for cell in phase.cleared {
            guard let gem = phase.before[cell.row * 7 + cell.column],
                  let node = takeCharacter(gem.id) else { continue }
            cellsByID.removeValue(forKey: gem.id)
            node.update(gem, expression: .clearing)
            node.run(.sequence([
                .scale(to: 0.91, duration: StarfallMotion.gatherDuration),
                .group([.fadeOut(withDuration: 0.12), .scale(to: 1.2, duration: 0.12),
                        .rotate(byAngle: 0.18, duration: 0.12)]),
                .removeFromParent()
            ]), withKey: "sky.recipe-pop")
            run(.sequence([
                .wait(forDuration: StarfallMotion.gatherDuration),
                .run { [weak self] in
                    guard let self else { return }
                    self.light(at: self.point(cell), color: StarCast.Identity(gem).color,
                               strength: phase.comboDepth > 1 ? 1 : 0.75)
                }
            ]))
        }
    }

    /// Reconciles only presentation snapshots; it never constructs a game or
    /// discovers matches. Deleted stars finish popping before survivors move.
    private func settleResolutionBoard(_ board: [StarfallGem?], duration: TimeInterval) {
        let targetIDs = Set(board.compactMap { $0?.id })
        for id in Array(nodes.keys) where !targetIDs.contains(id) {
            takeCharacter(id)?.removeFromParent()
            cellsByID.removeValue(forKey: id)
        }
        for child in pieces.children {
            if let character = child as? FallingSkyCharacter, !targetIDs.contains(character.gem.id) {
                character.removeFromParent()
            }
        }
        for (index, gem) in board.enumerated() {
            guard let gem else { continue }
            let cell = Cell(index / 7, index % 7)
            let existing = nodes[gem.id]
            let node = existing ?? makeNode(gem)
            if existing == nil {
                pieces.addChild(node)
                nodes[gem.id] = node
                node.position = point(cell)
            } else if node.gem != gem {
                node.update(gem, expression: gem.grown ? .grown : .idle)
            }
            node.removeAction(forKey: "sky.recipe-settle")
            if duration == 0 {
                node.position = point(cell)
            } else if node.position != point(cell) {
                let fall = SKAction.move(to: point(cell), duration: duration)
                fall.timingMode = .easeIn
                node.run(fall, withKey: "sky.recipe-settle")
            }
            node.zPosition = CGFloat(7 - cell.row)
            cellsByID[gem.id] = cell
        }
    }
}



extension FallingSkyScene {
    func showBufferedInput(_ action: SkyPlayerInput?) {
        bufferedInputLayer.removeAllChildren()
        guard let action else { return }
        let outline = contactOutline(action.source, ready: true)
        outline.name = "sky.input.buffered"
        bufferedInputLayer.addChild(outline)
        guard let destination = action.destination else { return }
        let from = point(action.source), to = point(destination)
        let length = hypot(to.x - from.x, to.y - from.y)
        guard length > 0 else { return }
        let direction = CGVector(dx: (to.x-from.x)/length, dy: (to.y-from.y)/length)
        let tip = CGPoint(x: from.x + direction.dx*length*0.65, y: from.y + direction.dy*length*0.65)
        let wing = step * StarfallTheme.SelectionCue.arrowWing
        let route = CGMutablePath()
        route.move(to: CGPoint(x: from.x + direction.dx*step*StarfallTheme.SelectionCue.innerRadius,
                              y: from.y + direction.dy*step*StarfallTheme.SelectionCue.innerRadius))
        route.addLine(to: tip)
        for sign: CGFloat in [-1, 1] {
            route.move(to: CGPoint(x: tip.x-direction.dx*wing-direction.dy*wing*sign,
                                  y: tip.y-direction.dy*wing+direction.dx*wing*sign))
            route.addLine(to: tip)
        }
        let arrow = SKShapeNode(path: route)
        arrow.name = "sky.input.buffered.direction"
        arrow.strokeColor = UIColor(StarfallTheme.Colors.textPrimary)
        arrow.lineWidth = StarfallTheme.SelectionCue.readyWidth
        bufferedInputLayer.addChild(arrow)
    }

    private func contactOutline(_ cell: Cell, ready: Bool, armed: Bool = false) -> SKShapeNode {
        let rays = CGMutablePath()
        for index in 0..<4 {
            let angle = (armed ? 0 : CGFloat.pi / 4) + CGFloat(index) * .pi / 2
            let inner = step * (armed ? StarfallTheme.SelectionCue.holdInnerRadius : StarfallTheme.SelectionCue.innerRadius)
            let outer = step * (armed ? StarfallTheme.SelectionCue.holdOuterRadius : StarfallTheme.SelectionCue.outerRadius)
            rays.move(to: CGPoint(x: cos(angle) * inner, y: sin(angle) * inner))
            rays.addLine(to: CGPoint(x: cos(angle) * outer, y: sin(angle) * outer))
        }
        let cue = SKShapeNode(path: rays)
        cue.name = armed ? "sky.input.drawing.armed" : "sky.input.contact"; cue.position = point(cell)
        cue.strokeColor = UIColor(StarfallTheme.Colors.textPrimary)
        cue.lineWidth = ready ? StarfallTheme.SelectionCue.readyWidth : StarfallTheme.SelectionCue.contactWidth
        cue.fillColor = .clear
        return cue
    }

    func showContact(_ cell: Cell, drawingEligible: Bool = false) {
        clearConstellationTrace()
        constellationTrail.addChild(contactOutline(cell, ready: false))
        if pieceMotionEnabled, let id = rendered?.gem(at: cell)?.id {
            nodes[id]?.attend()
        }
        guard drawingEligible, growthMotionEnabled else { return }
        let progress = SKNode()
        progress.name = "sky.input.hold.progress"; progress.position = point(cell)
        for index in 0..<StarfallTheme.SelectionCue.holdMarkCount {
            let angle = CGFloat(index % 4) * .pi / 2
            let segment = CGFloat(index / 4)
            let inner = step * StarfallTheme.SelectionCue.holdInnerRadius
            let length = step * (StarfallTheme.SelectionCue.holdOuterRadius-StarfallTheme.SelectionCue.holdInnerRadius) / 3
            let ray = CGMutablePath()
            ray.move(to: CGPoint(x:cos(angle)*(inner+length*segment),y:sin(angle)*(inner+length*segment)))
            ray.addLine(to: CGPoint(x:cos(angle)*(inner+length*(segment+0.8)),y:sin(angle)*(inner+length*(segment+0.8))))
            let mark = SKShapeNode(path:ray)
            mark.strokeColor = UIColor(StarfallTheme.Colors.textPrimary); mark.fillColor = .clear
            mark.lineWidth = StarfallTheme.SelectionCue.contactWidth
            mark.alpha = 0.15
            let delay = SkyGestureTiming.drawingHoldDuration * Double(index+1) / Double(StarfallTheme.SelectionCue.holdMarkCount)
            mark.run(.sequence([.wait(forDuration: delay), .fadeAlpha(to: 1, duration: 0.015)]))
            progress.addChild(mark)
        }
        constellationTrail.addChild(progress)
    }

    func clearConstellationTrace() { constellationTrail.removeAllActions(); constellationTrail.removeAllChildren() }

    func showConstellationTrace(_ path: [Cell], ready: Bool) {
        clearConstellationTrace()
        guard path.count <= 196, !path.isEmpty else { return }
        constellationTrail.addChild(contactOutline(path[0], ready:true, armed:true))
        let route = CGMutablePath()
        route.move(to: point(path[0]))
        for cell in path.dropFirst() { route.addLine(to: point(cell)) }
        let thread = SKShapeNode(path: route)
        thread.name = "constellation.trace.thread"
        thread.strokeColor = UIColor(StarfallTheme.Observatory.lanternGlow).withAlphaComponent(ready ? 1 : 0.7)
        thread.lineWidth = ready ? 2.4 : 1.5; thread.glowWidth = reduceMotion ? 0 : 4
        constellationTrail.addChild(thread)
        for (index, cell) in Set(path).sorted(by: { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }).enumerated() {
            constellationTrail.addChild(contactOutline(cell, ready: ready))
            let spark = SKShapeNode(circleOfRadius: step * 0.055)
            spark.name = "constellation.trace.spark"
            spark.position = point(cell)
            spark.fillColor = UIColor(StarfallTheme.Observatory.lanternGlow); spark.strokeColor = .white
            spark.glowWidth = reduceMotion ? 0 : 3
            constellationTrail.addChild(spark)
            if !reduceMotion {
                spark.run(.repeatForever(.sequence([.wait(forDuration: Double(index%3)*0.05), .fadeAlpha(to: 0.3, duration: 0.2), .fadeAlpha(to: 1, duration: 0.2)])))
            }
        }
        let tip = SKShapeNode(circleOfRadius: step * 0.075)
        tip.name = "constellation.trace.tip"; tip.fillColor = .white; tip.strokeColor = .clear
        tip.glowWidth = reduceMotion ? 0 : 5; tip.position = point(path.last!)
        constellationTrail.addChild(tip)
        let lead = SKShapeNode()
        lead.name = "constellation.trace.lead"; lead.position = point(path.last!)
        lead.strokeColor = UIColor(StarfallTheme.Observatory.lanternGlow).withAlphaComponent(0.65)
        lead.lineWidth = 1.4; lead.glowWidth = reduceMotion ? 0 : 3
        constellationTrail.addChild(lead)
    }

    func moveConstellationTip(_ location: CGPoint) {
        let current = CGPoint(x: location.x, y: size.height-location.y)
        if let tip = constellationTrail.childNode(withName: "constellation.trace.tip") {
            let previous = tip.position
            if !reduceMotion && hypot(current.x-previous.x,current.y-previous.y) >= 3 {
                let motes = constellationTrail.children.filter { $0.name == "constellation.trace.mote" }
                if motes.count >= 24 { motes.first?.removeFromParent() }
                let mote = SKShapeNode(circleOfRadius: step*0.025)
                mote.name = "constellation.trace.mote"; mote.position = previous
                mote.fillColor = .white; mote.strokeColor = .clear; mote.glowWidth = 2
                constellationTrail.addChild(mote)
                mote.run(.sequence([.group([.fadeOut(withDuration: 0.25),.scale(to:0.1,duration:0.25)]),.removeFromParent()]))
            }
            tip.position = current
        }
        if let lead = constellationTrail.childNode(withName:"constellation.trace.lead") as? SKShapeNode {
            let path=CGMutablePath(); path.move(to:.zero)
            path.addLine(to:CGPoint(x:current.x-lead.position.x,y:current.y-lead.position.y));lead.path=path
        }
    }


}

// Finite gravity presentation follows committed Core phases.
extension FallingSkyScene {
    private func renderGravityField(_ field: OrbitField?) {
        grid.children.filter { $0.name == "gravity.field" }.forEach { $0.removeFromParent() }
        guard let field else { return }
        let root = SKNode(); root.name = "gravity.field"
        let center = point(field.center)
        for cell in field.slots {
            let path = CGMutablePath(); path.move(to:center); path.addLine(to:point(cell))
            let line = SKShapeNode(path:path.copy(dashingWithPhase:0,lengths:[3,4]))
            line.strokeColor = StarfallTheme.Gravity.orbitLight.withAlphaComponent(0.65); line.lineWidth = 1.5
            root.addChild(line)
        }
        for index in 0..<field.windowsRemaining {
            let dot=SKShapeNode(circleOfRadius:step*0.035)
            dot.fillColor = StarfallTheme.Gravity.magneticLight; dot.strokeColor = .clear
            dot.position = CGPoint(x:center.x+CGFloat(index-1)*step*0.13,y:center.y-step*0.42)
            root.addChild(dot)
        }
        grid.addChild(root)
    }
    private func applyPhase(_ phase: SkyPresentationPhase, duration: TimeInterval) {
        let targetIDs=Set(phase.board.compactMap { $0?.id })
        for id in Array(nodes.keys) where !targetIDs.contains(id) {
            let node=takeCharacter(id)
            cellsByID.removeValue(forKey:id)
            var disappearance: [SKAction] = [.scale(to:0.1,duration:duration),.fadeOut(withDuration:duration)]
            if phase.event == .collision,
               let hole=phase.board.firstIndex(where: { $0?.gravityKind == .hole }) {
                disappearance.append(.move(to:point(Cell(hole/7,hole%7)),duration:duration))
            }
            if phase.event == .collision, let node,
               let hole = phase.board.firstIndex(where: { $0?.gravityKind == .hole }) {
                let direction: CGFloat = point(Cell(hole/7,hole%7)).x > node.position.x ? 1 : -1
                node.character.run(GravityMotion.attraction(direction: direction, step: step, duration: duration))
            }
            node?.run(.sequence([.group(disappearance),.removeFromParent()]))
        }
        grid.removeAllChildren()
        for index in phase.board.indices {
            guard let gem=phase.board[index] else { continue }
            let cell=Cell(index/7,index%7), destination=point(cell)
            let existing=nodes[gem.id]
            let node=existing ?? makeNode(gem)
            if existing == nil {
                node.position=destination; node.setScale(0.1); pieces.addChild(node); nodes[gem.id]=node
                node.run(.scale(to:1,duration:duration))
            }
            if phase.event == .rotation, gem.gravityKind == .hole {
                node.character.run(GravityMotion.ringResponse(duration: duration), withKey: "gravity.ring-response")
            }
            if cellsByID[gem.id] != cell {
                if phase.event == .rotation, let field=phase.field {
                    let center=point(field.center), start=node.position
                    let a=atan2(start.y-center.y,start.x-center.x)
                    let b=atan2(destination.y-center.y,destination.x-center.x)
                    var delta=b-a
                    // Scene y points up: clockwise takes a negative angle, even for skipped slots.
                    while delta >= 0 { delta -= 2 * .pi }
                    let ra=hypot(start.x-center.x,start.y-center.y)
                    let rb=hypot(destination.x-center.x,destination.y-center.y)
                    node.run(.customAction(withDuration:duration) { target, elapsed in
                        let t=min(1,CGFloat(elapsed)/CGFloat(duration))
                        let radius=ra+(rb-ra)*t, angle=a+delta*t
                        // Floor arcs lift into the terrace rather than travelling below its front edge.
                        let dy=sin(angle)*radius
                        target.position=CGPoint(x:center.x+cos(angle)*radius,
                                                y:center.y+(field.center.row == 0 ? abs(dy) : dy))
                    })
                } else {
                    let move=SKAction.move(to:destination,duration:duration); move.timingMode = .easeInEaseOut
                    node.run(move)
                }
            }
            node.zPosition=CGFloat(7-cell.row); cellsByID[gem.id]=cell
        }
        renderGravityField(phase.field)
        if phase.event == .collision, let index=phase.board.firstIndex(where: { $0?.gravityKind == .hole }) {
            let pulse=SKShapeNode(circleOfRadius:step*0.18); pulse.position=point(Cell(index/7,index%7))
            pulse.strokeColor = StarfallTheme.Gravity.magneticLight; pulse.lineWidth=2; pulse.glowWidth=3
            effects.addChild(pulse)
            pulse.run(.sequence([.group([.scale(to:3,duration:duration),.fadeOut(withDuration:duration)]),.removeFromParent()]))
            let infall = SKShapeNode(ellipseOf: CGSize(width: step * 1.1, height: step * 0.62))
            infall.position = pulse.position
            infall.strokeColor = StarfallTheme.Gravity.orbitLight; infall.lineWidth = 2
            infall.name = "gravity.formation"; effects.addChild(infall)
            infall.run(.sequence([.group([.scale(to: 0.12, duration: duration), .fadeOut(withDuration: duration)]), .removeFromParent()]))
        }
    }
    private func animatePhases(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                                completion: @escaping () -> Void) {
        render(old); rendered=game
        guard view != nil else { render(game); completion(); return }
        if reduceMotion || UIAccessibility.isReduceMotionEnabled || UIAccessibility.isVoiceOverRunning {
            render(game); completion(); return
        }
        let timeline = StarfallMotion.PhaseTimeline(phases: turn.presentationPhases.map(\.event), arrivals: turn.arrivals.count)
        var phases: [SKAction] = []
        for (phase, duration) in zip(turn.presentationPhases, timeline.phaseDurations) {
            phases.append(.run { [weak self] in self?.applyPhase(phase, duration: duration) })
            phases.append(.wait(forDuration: duration))
        }
        var presentation = [SKAction.sequence(phases)]
        if !turn.arrivals.isEmpty {
            presentation.append(.sequence([.wait(forDuration: timeline.flightStart), arrivalFlights(turn.arrivals),
                                           .wait(forDuration: StarfallMotion.landingDuration)]))
        }
        var sequence: [SKAction] = []
        if !turn.duskCollapses.isEmpty || !turn.stellarCollapses.isEmpty {
            sequence = [.run { [weak self] in
                guard let self else { return }
                StarCollapsePresentation.collapse(turn.stellarCollapses + turn.duskCollapses.map { StarCollapse(center: $0.center, sourceID: $0.duskID, consumed: $0.consumed) }, from: old, nodes: self.nodes,
                    effects: self.effects, point: self.point, step: self.step)
            }, .wait(forDuration: StarCollapsePresentation.collapseDuration)]
        }
        sequence += [.group(presentation), .run { [weak self] in self?.render(game); completion() }]
        run(.sequence(sequence))
    }
}
