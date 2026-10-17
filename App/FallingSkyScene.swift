import UIKit
import SpriteKit
import StarfallCore

/// Only presents committed turns. The view supplies native, full-cell buttons.
@MainActor final class FallingSkyScene: SKScene, FallingSkyPresenting {
    var reduceMotion = false
    var onLayout: (() -> Void)?
    private var nodes: [Int: SKNode] = [:]
    private var rendered: FallingSky?
    private let pieces = SKNode(), effects = SKNode(), grid = SKNode()
    private var step: CGFloat { size.width / 7.7 }

    override init(size: CGSize) {
        super.init(size: size)
        StarCast.prewarm()
        scaleMode = .resizeFill; backgroundColor = .clear
        addChild(grid); addChild(pieces); addChild(effects)
        effects.zPosition = 5
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
        CGPoint(x: size.width/2 + (CGFloat(cell.column)-3)*step,
                y: size.height/2 + (CGFloat(cell.row)-3)*size.height/7.7)
    }

    private func makeNode(_ gem: StarfallGem) -> SKNode {
        JewelScene.makeStarCharacter(gem.kind, expression: gem.grown ? .grown : .idle,
                                    radius: step * (gem.grown ? 0.43 : 0.35))
    }

    private func shade(_ node: SKNode, at cell: Cell) {
        node.alpha = 0.65
        let ring = SKShapeNode(circleOfRadius: step * 0.45)
        ring.position = point(cell)
        ring.strokeColor = .systemPurple.withAlphaComponent(0.45)
        ring.lineWidth = 1; ring.fillColor = .clear
        grid.addChild(ring)
    }

    func render(_ game: FallingSky) { render(game, ambient: true) }

    private func render(_ game: FallingSky, ambient: Bool) {
        rendered = game
        removeAllActions(); effects.removeAllChildren(); effects.removeAllActions()
        pieces.removeAllChildren(); grid.removeAllChildren(); nodes.removeAll()
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
                let node = makeNode(gem); node.position = point(cell)
                if game.isGrowthBlocked(at: cell) { shade(node, at: cell) }
                pieces.addChild(node); nodes[gem.id] = node
                if ambient && !reduceMotion && !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning {
                    let expression: StarCast.Expression = gem.grown ? .grown : .idle
                    let turn = StarCast.turnAction(for: gem.kind, expression: expression,
                                                   toward: gem.id.isMultiple(of: 2) ? .left : .right, duration: 0.65)
                    // Staggered, sparse character motion; one owned action per occupied cell.
                    node.run(.repeatForever(.sequence([.wait(forDuration: 5 + Double(gem.id % 7)), turn])),
                             withKey: "star-cast.ambient")
                }
            }
        } }
    }

    func animate(_ turn: FallingSkyTurn, from old: FallingSky,
                 to game: FallingSky, completion: @escaping () -> Void) {
        render(old, ambient: false)
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
                if let sprite = node as? SKSpriteNode {
                    StarCast.setExpression(.clearing, for: old.gem(at: cell)?.kind, on: sprite)
                }
                let ring = SKShapeNode(circleOfRadius: step * 0.30)
                ring.position = node.position
                ring.strokeColor = old.gem(at: cell)?.kind?.color ?? .systemPurple
                ring.lineWidth = 2; ring.glowWidth = 3
                effects.addChild(ring)
                ring.run(.sequence([.group([.scale(to: 1.7, duration: 0.24), .fadeOut(withDuration: 0.24)]), .removeFromParent()]))
                node.run(.sequence([.group([.fadeOut(withDuration: 0.12), .scale(to: 1.2, duration: 0.12), .rotate(byAngle: 0.18, duration: 0.12)]), .removeFromParent()]))
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
            if let gem = turn.settled[index], let node = nodes[gem.id] {
                let move = SKAction.move(to: point(Cell(index/7, index%7)), duration: 0.20)
                move.timingMode = .easeInEaseOut
                node.run(.sequence([.wait(forDuration: 0.26), move]))
            }
        }
        if turn.arrivals.isEmpty {
            run(.sequence([.wait(forDuration: 0.48), .run { [weak self] in self?.render(game); completion() }]))
            return
        }
        let flights = turn.arrivals.enumerated().map { index, arrival in
            SKAction.sequence([
                .wait(forDuration: Double(index) * 0.09),
                .run { [weak self] in self?.sendStar(arrival) },
                .wait(forDuration: 0.48),
                .run { [weak self] in self?.land(arrival) }
            ])
        }
        run(.sequence([.group(flights), .wait(forDuration: 0.28),
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
            node.run(.sequence([.wait(forDuration: Double(distance / step) * 0.025), outward, recover]),
                     withKey: "sky.ripple")
        } }
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
        let fall = SKAction.move(to: point(arrival.cell), duration: 0.48)
        fall.timingMode = .easeIn
        comet.run(.sequence([fall, .removeFromParent()]))
    }

    private func land(_ arrival: FallingSkyTurn.Arrival) {
        nodes[arrival.gem.id]?.removeFromParent()
        let node = JewelScene.makeStarCharacter(arrival.gem.kind, expression: .landing,
                                                radius: step * (arrival.gem.grown ? 0.43 : 0.35))
        node.run(.sequence([.wait(forDuration: 0.12),
                            .run { [weak node] in
                                guard let node else { return }
                                StarCast.setExpression(arrival.gem.grown ? .grown : .idle,
                                                       for: arrival.gem.kind, on: node)
                            }]))
        let destination = point(arrival.cell)
        node.position = destination
        pieces.addChild(node); nodes[arrival.gem.id] = node
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

/// Presentation-only tuning in cell units: fixed from committed identities, never advances the RNG.
enum StarfallMotion {
    static func drift(for id: Int, column: Int) -> CGFloat {
        let direction: CGFloat = column == 0 ? 1 : column == 6 ? -1 : id.isMultiple(of: 2) ? 1 : -1
        return direction * (id.isMultiple(of: 3) ? 1.5 : 0.85)
    }
    static func rebound(dark: Bool, grew: Bool) -> CGFloat {
        dark ? 0.045 : grew ? 0.09 : 0.18
    }
    static func ripple(distance: CGFloat, collected: Int, heavy: Bool) -> CGFloat {
        guard distance > 0, distance < 3 else { return 0 }
        return (collected >= 5 ? 0.21 : 0.12) * (1 - distance / 3) * (heavy ? 0.55 : 1)
    }
}
