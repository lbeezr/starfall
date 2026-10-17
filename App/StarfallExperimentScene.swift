import UIKit
import SpriteKit
import StarfallCore

/// Only presents committed turns. The view supplies native, full-cell buttons.
@MainActor final class StarfallExperimentScene: SKScene, ExperimentPresenting {
    var reduceMotion = false
    var onLayout: (() -> Void)?
    private var nodes: [Int: SKNode] = [:]
    private var rendered: StarfallExperiment?
    private let pieces = SKNode(), effects = SKNode(), grid = SKNode()
    private var step: CGFloat { size.width / 7.7 }

    override init(size: CGSize) {
        super.init(size: size)
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
        if let kind = gem.kind {
            return JewelScene.makeBaseJewel(kind, radius: step * (gem.grown ? 0.42 : 0.32))
        }
        let node = SKNode()
        node.name = "dark-star"
        let corona = SKShapeNode(circleOfRadius: step * 0.36)
        corona.strokeColor = .systemPurple.withAlphaComponent(0.8)
        corona.lineWidth = 1.5; corona.glowWidth = 4
        let core = SKShapeNode(circleOfRadius: step * 0.28)
        core.fillColor = UIColor(red: 0.06, green: 0.03, blue: 0.12, alpha: 1)
        core.strokeColor = .white.withAlphaComponent(0.55)
        core.lineWidth = 1
        node.addChild(corona); node.addChild(core)
        return node
    }

    private func shade(_ node: SKNode, at cell: Cell) {
        node.alpha = 0.65
        let ring = SKShapeNode(circleOfRadius: step * 0.45)
        ring.position = point(cell)
        ring.strokeColor = .systemPurple.withAlphaComponent(0.45)
        ring.lineWidth = 1; ring.fillColor = .clear
        grid.addChild(ring)
    }

    func render(_ game: StarfallExperiment) {
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
            }
        } }
    }

    func animate(_ turn: StarfallExperimentTurn, from old: StarfallExperiment,
                 to game: StarfallExperiment, completion: @escaping () -> Void) {
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
                let ring = SKShapeNode(circleOfRadius: step * 0.30)
                ring.position = node.position
                ring.strokeColor = old.gem(at: cell)?.kind?.color ?? .systemPurple
                ring.lineWidth = 2; ring.glowWidth = 3
                effects.addChild(ring)
                ring.run(.sequence([.group([.scale(to: 1.7, duration: 0.24), .fadeOut(withDuration: 0.24)]), .removeFromParent()]))
                node.run(.sequence([.group([.fadeOut(withDuration: 0.12), .scale(to: 1.2, duration: 0.12)]), .removeFromParent()]))
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
        for index in turn.settled.indices {
            if let gem = turn.settled[index], let node = nodes[gem.id] {
                let move = SKAction.move(to: point(Cell(index/7, index%7)), duration: 0.20)
                move.timingMode = .easeInEaseOut
                node.run(.sequence([.wait(forDuration: 0.12), move]))
            }
        }
        if turn.arrivals.isEmpty {
            run(.sequence([.wait(forDuration: 0.34), .run { [weak self] in self?.render(game); completion() }]))
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

    private func sendStar(_ arrival: StarfallExperimentTurn.Arrival) {
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
        if arrival.star.isDark {
            comet.addChild(makeNode(arrival.gem))
        } else {
            let star = SKLabelNode(text: "✦")
            star.fontSize = step * 0.55; star.fontColor = .white
            star.verticalAlignmentMode = .center
            comet.addChild(star)
        }
        comet.position = CGPoint(x: point(arrival.cell).x, y: size.height + step)
        effects.addChild(comet)
        let fall = SKAction.move(to: point(arrival.cell), duration: 0.48)
        fall.timingMode = .easeIn
        comet.run(.sequence([fall, .removeFromParent()]))
    }

    private func land(_ arrival: StarfallExperimentTurn.Arrival) {
        nodes[arrival.gem.id]?.removeFromParent()
        let node = makeNode(arrival.gem)
        node.position = point(arrival.cell)
        pieces.addChild(node); nodes[arrival.gem.id] = node
        node.setScale(0.8)
        node.run(.sequence([.scale(to: 1.10, duration: 0.12), .scale(to: 1, duration: 0.16)]))
        let ring = SKShapeNode(circleOfRadius: step * (arrival.grew ? 0.42 : 0.28))
        ring.position = node.position
        ring.strokeColor = (arrival.star.kind?.color ?? .systemPurple).withAlphaComponent(0.85)
        ring.lineWidth = 1.5; ring.glowWidth = 2
        effects.addChild(ring)
        ring.run(.sequence([.group([.scale(to: 1.7, duration: 0.28), .fadeOut(withDuration: 0.28)]), .removeFromParent()]))
    }
}
