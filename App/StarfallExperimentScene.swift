#if DEBUG
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
    private var step: CGFloat { min(size.width, size.height) / 7.7 }

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
                y: size.height/2 + (CGFloat(cell.row)-3)*step)
    }

    private func makeNode(_ gem: StarfallGem) -> SKNode {
        let node = JewelScene.makeBaseJewel(gem.kind, radius: step * (gem.grown ? 0.42 : 0.32))
        if gem.grown {
            let value = SKLabelNode(text: "2")
            value.fontName = "AvenirNext-DemiBold"; value.fontSize = max(12, step * 0.25)
            value.fontColor = .white
            value.position = CGPoint(x: step * 0.29, y: -step * 0.37)
            node.addChild(value)
        }
        return node
    }

    func render(_ game: StarfallExperiment) {
        rendered = game
        removeAllActions(); effects.removeAllChildren(); effects.removeAllActions()
        pieces.removeAllChildren(); grid.removeAllChildren(); nodes.removeAll()
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            let square = SKShapeNode(rectOf: CGSize(width: step * 0.94, height: step * 0.94), cornerRadius: 5)
            square.fillColor = .white.withAlphaComponent(0.025)
            square.strokeColor = .white.withAlphaComponent(0.075)
            square.lineWidth = 1; square.position = point(cell); grid.addChild(square)
            if let gem = game.gem(at: cell) {
                let node = makeNode(gem); node.position = point(cell)
                pieces.addChild(node); nodes[gem.id] = node
            }
        } }
        if !game.isOver {
            for column in Set(game.incoming.map(\.column)) {
                let marker = SKShapeNode(rectOf: CGSize(width: step * 0.94, height: step * 7), cornerRadius: 6)
                marker.position = CGPoint(x: point(Cell(3, column)).x, y: size.height/2)
                marker.strokeColor = .white.withAlphaComponent(0.35); marker.lineWidth = 1
                marker.fillColor = .clear; grid.addChild(marker)
            }
        }
    }

    func animate(_ turn: StarfallExperimentTurn, from old: StarfallExperiment,
                 to game: StarfallExperiment, completion: @escaping () -> Void) {
        render(old)
        rendered = game
        if reduceMotion || UIAccessibility.isReduceMotionEnabled || UIAccessibility.isVoiceOverRunning || view == nil {
            render(game)
            // A short input gate still absorbs an accidental double tap.
            run(.sequence([.wait(forDuration: 0.15), .run(completion)]))
            return
        }
        for cell in turn.cleared {
            if let id = old.gem(at: cell)?.id, let node = nodes.removeValue(forKey: id) {
                node.run(.sequence([.group([.fadeOut(withDuration: 0.12), .scale(to: 0.5, duration: 0.12)]), .removeFromParent()]))
            }
        }
        for index in turn.settled.indices {
            if let gem = turn.settled[index], let node = nodes[gem.id] {
                let move = SKAction.move(to: point(Cell(index/7, index%7)), duration: 0.20)
                move.timingMode = .easeInEaseOut
                node.run(.sequence([.wait(forDuration: 0.12), move]))
            }
        }
        var sequence: [SKAction] = [.wait(forDuration: 0.34)]
        for arrival in turn.arrivals {
            sequence.append(.run { [weak self] in self?.sendStar(arrival) })
            sequence.append(.wait(forDuration: 0.19))
            sequence.append(.run { [weak self] in self?.land(arrival) })
            sequence.append(.wait(forDuration: 0.06))
        }
        sequence.append(.run { [weak self] in self?.render(game); completion() })
        run(.sequence(sequence))
    }

    private func sendStar(_ arrival: StarfallExperimentTurn.Arrival) {
        let star = SKLabelNode(text: "✦")
        star.fontSize = step * 0.66; star.fontColor = arrival.star.kind.color
        star.verticalAlignmentMode = .center
        star.position = CGPoint(x: point(arrival.cell).x, y: size.height + step)
        effects.addChild(star)
        let fall = SKAction.move(to: point(arrival.cell), duration: 0.18)
        fall.timingMode = .easeIn
        star.run(.sequence([fall, .removeFromParent()]))
    }

    private func land(_ arrival: StarfallExperimentTurn.Arrival) {
        nodes[arrival.gem.id]?.removeFromParent()
        let node = makeNode(arrival.gem)
        node.position = point(arrival.cell)
        pieces.addChild(node); nodes[arrival.gem.id] = node
        node.setScale(0.8)
        node.run(.scale(to: 1, duration: 0.06))
    }
}
#endif
