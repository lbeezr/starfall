import UIKit
import SpriteKit
import StarfallCore

/// Only presents committed turns. The view supplies native, full-cell buttons.
@MainActor final class FallingSkyScene: SKScene, FallingSkyPresenting {
    var reduceMotion = false
    var onLayout: (() -> Void)?
    private var nodes: [Int: FallingSkyCharacter] = [:]
    private var cellsByID: [Int: Cell] = [:]
    private var rendered: FallingSky?
    private let pieces = SKNode(), effects = SKNode(), grid = SKNode()
    private var step: CGFloat { ObservatoryGeometry(size: size).imageRect.width / 7.7 }

    override init(size: CGSize) {
        super.init(size: size)
        StarCast.prewarm()
        scaleMode = .resizeFill; backgroundColor = .clear
        addChild(grid); addChild(pieces); addChild(effects)
        effects.zPosition = 20
    }
    override convenience init() { self.init(size: CGSize(width: 350, height: 350)) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != size else { return }
        onLayout?()
    }
    override func didMove(to view: SKView) { if let rendered { render(rendered) } }
    override func willMove(from view: SKView) { onLayout?() }

    private func point(_ cell: Cell) -> CGPoint {
        ObservatoryGeometry(size: size).scenePoint(cell)
    }

    private func makeNode(_ gem: StarfallGem) -> FallingSkyCharacter {
        FallingSkyCharacter(gem: gem, step: step)
    }

    private func ground(_ gem: StarfallGem, at cell: Cell) {
        let root = SKNode()
        root.name = "sky.ground.\(gem.id)"
        root.position = CGPoint(x: point(cell).x, y: point(cell).y - groundOffset(gem))
        // A contact core stays dark under the crystal; the wider pool separates it from the floor.
        for contact in [false, true] {
            let shadow = SKShapeNode(ellipseOf: CGSize(width: step * (contact ? 0.24 : 0.61),
                                                       height: step * (contact ? 0.055 : 0.12)))
            shadow.name = contact ? "sky.shadow.contact" : "sky.shadow.soft"
            shadow.fillColor = contact ? StarfallTheme.Observatory.contactShadow : StarfallTheme.Observatory.softContactShadow
            shadow.strokeColor = .clear
            shadow.position.x = contact ? 0 : step * 0.045
            root.addChild(shadow)
        }
        grid.addChild(root)
    }

    private func groundOffset(_ gem: StarfallGem) -> CGFloat {
        StarCast.groundOffset(for: gem.kind, radius: step * (gem.grown ? 0.43 : 0.35))
    }

    private func light(at anchor: CGPoint, color: UIColor, strength: CGFloat) {
        // Two finite ellipses, below the stars. No particles, texture generation or broad flash.
        for index in 0..<2 {
            let pool = SKShapeNode(ellipseOf: CGSize(width: step * (index == 0 ? 0.95 : 0.48),
                                                     height: step * (index == 0 ? 0.22 : 0.10)))
            pool.name = "sky.surface-light"
            pool.position = CGPoint(x: anchor.x, y: anchor.y - step * 0.31)
            pool.fillColor = color.withAlphaComponent((index == 0 ? 0.16 : 0.24) * strength)
            pool.strokeColor = .clear; pool.glowWidth = index == 0 ? 4 : 1
            pool.blendMode = .add; pool.zPosition = -effects.zPosition - 1
            effects.addChild(pool)
            pool.run(.sequence([.group([.scale(to: 1.25, duration: 0.25), .fadeOut(withDuration: 0.25)]), .removeFromParent()]))
        }
    }

    private func shade(_ node: SKNode, at cell: Cell) {
        node.alpha = 0.65
        let ring = SKShapeNode(circleOfRadius: step * 0.45)
        ring.position = point(cell)
        ring.strokeColor = .systemPurple.withAlphaComponent(0.45)
        ring.lineWidth = 1; ring.fillColor = .clear
        grid.addChild(ring)
    }

    func render(_ game: FallingSky) {
        rendered = game
        removeAllActions(); effects.removeAllChildren(); effects.removeAllActions()
        pieces.removeAllChildren(); grid.removeAllChildren(); nodes.removeAll(); cellsByID.removeAll()
        let matchable = Set(game.legalGroups.flatMap { $0 })
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            if matchable.contains(cell) {
                let halo = SKShapeNode(circleOfRadius: step * 0.46)
                halo.strokeColor = .white.withAlphaComponent(0.32)
                halo.fillColor = .clear; halo.lineWidth = 1
                halo.position = point(cell); grid.addChild(halo)
            }
            if let gem = game.gem(at: cell) {
                ground(gem, at: cell)
                let node = makeNode(gem); node.position = point(cell)
                node.zPosition = CGFloat(7-cell.row)
                if game.isGrowthBlocked(at: cell) { shade(node, at: cell) }
                pieces.addChild(node); nodes[gem.id] = node; cellsByID[gem.id] = cell

            }
        } }
    }

    func animate(_ turn: FallingSkyTurn, from old: FallingSky,
                 to game: FallingSky, completion: @escaping () -> Void) {
        render(old)
        rendered = game
        if view == nil { render(game); completion(); return }
        if reduceMotion || UIAccessibility.isReduceMotionEnabled || UIAccessibility.isVoiceOverRunning {
            render(game)
            // A short input gate still absorbs an accidental double tap.
            run(.sequence([.wait(forDuration: 0.15), .run(completion)]))
            return
        }
        for cell in turn.cleared {
            if let id = old.gem(at: cell)?.id, let node = nodes.removeValue(forKey: id) {
                node.update(node.gem, expression: .clearing)
                cellsByID.removeValue(forKey: id)
                grid.childNode(withName: "sky.ground.\(id)")?.run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
                run(.sequence([.wait(forDuration: StarfallMotion.gatherDuration), .run { [weak self] in
                    guard let self else { return }
                    self.light(at: self.point(cell), color: old.gem(at: cell)?.kind?.color ?? .systemPurple, strength: 0.75)
                }]))
                let ring = SKShapeNode(circleOfRadius: step * 0.30)
                ring.position = node.position
                ring.strokeColor = old.gem(at: cell)?.kind?.color ?? .systemPurple
                ring.lineWidth = 2; ring.glowWidth = 3
                effects.addChild(ring)
                ring.run(.sequence([.wait(forDuration: StarfallMotion.gatherDuration), .group([.scale(to: 1.7, duration: 0.24), .fadeOut(withDuration: 0.24)]), .removeFromParent()]))
                node.run(.sequence([.scale(to: 0.91, duration: StarfallMotion.gatherDuration), .group([.fadeOut(withDuration: 0.12), .scale(to: 1.2, duration: 0.12), .rotate(byAngle: 0.18, duration: 0.12)]), .removeFromParent()]))
            }
        }
        if turn.collected > 0, !turn.cleared.isEmpty {
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
        for index in turn.settled.indices {
            if let gem = turn.settled[index], let node = nodes[gem.id],
               cellsByID[gem.id] != Cell(index/7, index%7) {
                let move = SKAction.move(to: point(Cell(index/7, index%7)), duration: 0.20)
                move.timingMode = .easeInEaseOut
                node.run(.sequence([.wait(forDuration: StarfallMotion.gravityStart), move]))
                if let shadow = grid.childNode(withName: "sky.ground.\(gem.id)") {
                    let destination = point(Cell(index/7, index%7))
                    let moveShadow = SKAction.move(to: CGPoint(x: destination.x, y: destination.y - groundOffset(gem)), duration: 0.20)
                    moveShadow.timingMode = .easeInEaseOut
                    shadow.run(.sequence([.wait(forDuration: StarfallMotion.gravityStart), moveShadow]))
                }
            }
        }
        if turn.arrivals.isEmpty {
            run(.sequence([.wait(forDuration: StarfallMotion.clearDuration), .run { [weak self] in self?.render(game); completion() }]))
            return
        }
        let flights = turn.arrivals.enumerated().map { index, arrival in
            SKAction.sequence([
                .wait(forDuration: Double(index) * 0.09),
                .run { [weak self] in self?.sendStar(arrival) },
                .wait(forDuration: StarfallMotion.flightDuration),
                .run { [weak self] in self?.land(arrival) }
            ])
        }
        run(.sequence([.group(flights), .wait(forDuration: StarfallMotion.landingDuration),
                       .run { [weak self] in self?.render(game); completion() }]))
    }

    /// One outward impulse per survivor, from its nearest cleared star. No cascades or rule changes.
    private func ripple(_ turn: FallingSkyTurn, from old: FallingSky) {
        let sources = turn.cleared.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        guard !sources.isEmpty else { return }
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
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
            let kick = CGPoint(x: origin.x + delta.x / distance * strength,
                               y: origin.y + delta.y / distance * strength)
            let outward = SKAction.move(to: kick, duration: 0.055)
            outward.timingMode = .easeOut
            let recover = SKAction.move(to: origin, duration: 0.11)
            recover.timingMode = .easeInEaseOut
            node.run(.sequence([.wait(forDuration: StarfallMotion.gatherDuration + Double(distance / step) * 0.025), outward, recover]),
                     withKey: "sky.ripple")
        } }
    }

    private func receiver(for arrival: FallingSkyTurn.Arrival) -> FallingSkyCharacter? {
        if arrival.grew { return nodes[arrival.gem.id] }
        let direction = StarfallMotion.drift(for: arrival.star.id, column: arrival.cell.column) > 0 ? 1 : -1
        let side = Cell(arrival.cell.row, arrival.cell.column - direction)
        let below = Cell(arrival.cell.row - 1, arrival.cell.column)
        for cell in [side, below] {
            guard let id = cellsByID.first(where: { $0.value == cell })?.key, let node = nodes[id] else { continue }
            let offset = point(cell)
            let target = point(arrival.cell)
            guard hypot(offset.x-target.x, offset.y-target.y) <= step * 1.15 else { continue }
            return node
        }
        return nil
    }

    private func sendStar(_ arrival: FallingSkyTurn.Arrival) {
        let comet = SKNode()
        let color = arrival.star.kind?.color ?? .systemPurple
        // A bounded handful of shapes per star, with no emitters or accumulating particles.
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -step * 0.13, y: 0))
        tailPath.addQuadCurve(to: CGPoint(x: 0, y: step * 2.7), control: CGPoint(x: -step * 0.08, y: step))
        tailPath.addQuadCurve(to: CGPoint(x: step * 0.13, y: 0), control: CGPoint(x: step * 0.08, y: step))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = color.withAlphaComponent(0.3); tail.strokeColor = .clear
        tail.glowWidth = 4
        comet.addChild(tail)
        let halo = SKShapeNode(circleOfRadius: step * 0.20)
        halo.fillColor = color.withAlphaComponent(0.3); halo.strokeColor = color.withAlphaComponent(0.5)
        halo.glowWidth = 9
        comet.addChild(halo)
        let traveler = JewelScene.makeStarCharacter(arrival.star.kind, expression: .landing, radius: step * 0.35)
        traveler.zRotation = arrival.star.id.isMultiple(of: 2) ? -0.12 : 0.12
        traveler.run(.group([
            StarCast.turnAction(for: arrival.star.kind, expression: .landing,
                                toward: arrival.star.id.isMultiple(of: 2) ? .left : .right, duration: 0.48),
            .rotate(toAngle: 0, duration: 0.48)
        ]))
        comet.addChild(traveler)
        let drift = StarfallMotion.drift(for: arrival.star.id, column: arrival.cell.column) * step
        comet.position = CGPoint(x: point(arrival.cell).x - drift, y: size.height + step)
        // Align the tail with the actual incoming vector.
        comet.zRotation = atan2(drift, comet.position.y - point(arrival.cell).y)
        effects.addChild(comet)
        let destination = point(arrival.cell)
        let receiver = receiver(for: arrival)
        let receiverCell = receiver.flatMap { cellsByID[$0.gem.id] }
        let contact: CGPoint? = receiverCell.map { cell in
            let anchor = point(cell)
            if arrival.grew { return CGPoint(x: anchor.x - drift * 0.05, y: anchor.y + step * 0.70) }
            if cell.row == arrival.cell.row {
                let radius = step * (0.35 + (receiver?.gem.grown == true ? 0.43 : 0.35))
                return CGPoint(x: anchor.x + (destination.x > anchor.x ? radius : -radius), y: anchor.y + step * 0.12)
            }
            return CGPoint(x: anchor.x + drift * 0.08, y: anchor.y + step * 0.68)
        }
        let flight = StarfallMotion.Flight(start: comet.position, destination: destination, contact: contact, step: step)
        let fall = SKAction.customAction(withDuration: StarfallMotion.flightDuration) { node, elapsed in
            node.position = flight.point(at: elapsed / CGFloat(StarfallMotion.flightDuration))
        }
        if let receiver, let receiverCell, let contact {
            let resistance = StarfallMotion.resistance(receiver.gem)
            let impulse = CGVector(dx: (contact.x > point(receiverCell).x ? -0.10 : 0.10) * resistance,
                                   dy: -0.035 * resistance)
            comet.run(.sequence([.wait(forDuration: StarfallMotion.flightDuration * Double(StarfallMotion.contactFraction)),
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
                comet.run(.sequence([.wait(forDuration: 0.38), .run { [weak observer] in
                    observer?.acknowledge(from: destination, impulse: .zero, step: flight.step)
                }]))
            }
        }
        tail.run(.sequence([.wait(forDuration: 0.34), .fadeOut(withDuration: 0.14)]))
        comet.run(.sequence([fall, .removeFromParent()]))
    }

    private func land(_ arrival: FallingSkyTurn.Arrival) {
        let existing = nodes[arrival.gem.id]
        let node = existing ?? makeNode(arrival.gem)
        node.update(arrival.gem, expression: .landing)
        node.run(.sequence([.wait(forDuration: 0.12), .run { [weak node] in
            guard let node else { return }
            node.update(arrival.gem, expression: arrival.gem.grown ? .grown : .idle)
        }]))
        let destination = point(arrival.cell)
        node.position = destination
        node.zPosition = CGFloat(7-arrival.cell.row)
        if existing == nil { pieces.addChild(node) }
        nodes[arrival.gem.id] = node; cellsByID[arrival.gem.id] = arrival.cell
        grid.childNode(withName: "sky.ground.\(arrival.gem.id)")?.removeFromParent()
        ground(arrival.gem, at: arrival.cell)
        light(at: destination, color: arrival.star.kind?.color ?? .systemPurple,
              strength: arrival.gem.isDark ? 0.25 : arrival.grew ? 1 : 0.65)
        node.xScale = 1.13; node.yScale = 0.78
        node.zRotation = arrival.gem.id.isMultiple(of: 2) ? -0.10 : 0.10
        let rebound = StarfallMotion.rebound(dark: arrival.gem.isDark, grew: arrival.grew) * step
        let drift = StarfallMotion.drift(for: arrival.star.id, column: arrival.cell.column) * step
        let bounce = SKAction.move(to: CGPoint(x: destination.x + drift * 0.10, y: destination.y + rebound), duration: 0.10)
        bounce.timingMode = .easeOut
        let settle = SKAction.move(to: destination, duration: 0.18)
        settle.timingMode = .easeInEaseOut
        node.run(.group([
            .sequence([bounce, settle]),
            .sequence([.scaleX(to: 0.94, y: 1.08, duration: 0.12), .scaleX(to: 1, y: 1, duration: 0.16)]),
            .sequence([.rotate(toAngle: -node.zRotation * 0.6, duration: 0.12), .rotate(toAngle: 0, duration: 0.16)])
        ]))
        let ring = SKShapeNode(circleOfRadius: step * (arrival.grew ? 0.42 : 0.28))
        ring.position = node.position
        ring.strokeColor = (arrival.star.kind?.color ?? .systemPurple).withAlphaComponent(0.85)
        ring.lineWidth = 1.5; ring.glowWidth = 2
        effects.addChild(ring)
        ring.run(.sequence([.group([.scale(to: 1.7, duration: 0.28), .fadeOut(withDuration: 0.28)]), .removeFromParent()]))
    }
}
