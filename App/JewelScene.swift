import SpriteKit
import UIKit
import AudioToolbox
import StarfallCore

extension Jewel {
    var color: UIColor {
        switch self {
        case .rose: return UIColor(red: 1, green: 0.35, blue: 0.60, alpha: 1)
        case .aqua: return UIColor(red: 0.28, green: 0.85, blue: 1, alpha: 1)
        case .amber: return UIColor(red: 1, green: 0.76, blue: 0.28, alpha: 1)
        case .violet: return UIColor(red: 0.70, green: 0.49, blue: 1, alpha: 1)
        case .mint: return UIColor(red: 0.35, green: 1, blue: 0.72, alpha: 1)
        }
    }
    var label: String { ["Rose circle", "Aqua diamond", "Amber triangle", "Violet hexagon", "Mint square"][rawValue] }
    var symbol: String { ["●", "◆", "▲", "⬡", "■"][rawValue] }
}

@MainActor final class JewelScene: SKScene {
    weak var store: GameStore?
    var reduceMotion = false
    private var nodes: [Cell: SKNode] = [:]
    private let boardRoot = SKNode()
    private var step: CGFloat { min(size.width, size.height) / 7.7 }
    override func didMove(to view: SKView) {
        if boardRoot.parent == nil { addChild(boardRoot) }
        if let game = store?.game { render(game) }
    }
    override func didChangeSize(_ oldSize: CGSize) {
        guard store?.busy != true, let game = store?.game else { return }
        render(game)
    }
    private func point(_ cell: Cell) -> CGPoint {
        CGPoint(x: size.width/2 + (CGFloat(cell.column)-3)*step, y: size.height/2 + (CGFloat(cell.row)-3)*step)
    }
    func render(_ game: Game) {
        boardRoot.removeAllChildren(); nodes.removeAll()
        for row in 0..<Game.side { for column in 0..<Game.side {
            let cell = Cell(row, column)
            let node = jewel(game.jewel(at: cell)!, radius: step * 0.37)
            node.position = point(cell); boardRoot.addChild(node); nodes[cell] = node
        } }
    }
    private func jewel(_ kind: Jewel, radius: CGFloat) -> SKNode {
        let root = SKNode()
        let path: CGPath
        if kind == .rose {
            path = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius*2, height: radius*2), transform: nil)
        } else {
            let sides = [0, 4, 3, 6, 4][kind.rawValue]
            let angle: CGFloat = kind == .mint ? .pi/4 : .pi/2
            let p = CGMutablePath()
            for index in 0..<sides {
                let a = angle + CGFloat(index)*2 * .pi/CGFloat(sides)
                let v = CGPoint(x: cos(a)*radius, y: sin(a)*radius)
                if index == 0 { p.move(to: v) } else { p.addLine(to: v) }
            }
            p.closeSubpath(); path = p
        }
        let shadow = SKShapeNode(path: path)
        shadow.fillColor = kind.color.withAlphaComponent(0.12); shadow.strokeColor = .clear
        shadow.setScale(1.19); shadow.position.y = -3; root.addChild(shadow)
        let glass = SKShapeNode(path: path)
        glass.fillColor = kind.color.withAlphaComponent(0.62)
        glass.strokeColor = kind.color.withAlphaComponent(0.95)
        glass.lineWidth = 1.5; glass.glowWidth = 1.2; root.addChild(glass)
        let inset = SKShapeNode(path: path)
        inset.setScale(0.75); inset.fillColor = .clear; inset.strokeColor = .white.withAlphaComponent(0.27); inset.lineWidth = 0.7
        root.addChild(inset)
        let glint = SKShapeNode(ellipseOf: CGSize(width: radius*0.48, height: radius*0.19))
        glint.fillColor = .white.withAlphaComponent(0.65); glint.strokeColor = .clear
        glint.position = CGPoint(x: -radius*0.23, y: radius*0.37); glint.zRotation = 0.45; root.addChild(glint)
        return root
    }
    func nudge(_ cell: Cell) {
        guard !reduceMotion else { return }
        nodes[cell]?.run(.sequence([.scale(to: 0.90, duration: 0.07), .scale(to: 1, duration: 0.10)]))
    }
    func animate(turn: Turn, old: Game, new: Game, completion: @escaping () -> Void) {
        if store?.soundEnabled == true { AudioServicesPlaySystemSound(1104) }
        if reduceMotion || UIAccessibility.isVoiceOverRunning || view == nil { render(new); completion(); return }
        for cell in turn.cleared {
            nodes[cell]?.run(.sequence([.scale(to: 1.12, duration: 0.06), .group([.fadeOut(withDuration: 0.13), .scale(to: 0.15, duration: 0.13)]), .removeFromParent()]))
            let spark = SKLabelNode(text: "✦")
            spark.fontSize = 14; spark.fontColor = old.jewel(at: cell)?.color
            spark.position = point(cell); boardRoot.addChild(spark)
            spark.run(.sequence([.group([.moveBy(x: 0, y: 18, duration: 0.28), .fadeOut(withDuration: 0.28)]), .removeFromParent()]))
        }
        run(.sequence([.wait(forDuration: 0.20), .run { [weak self] in
            guard let self else { completion(); return }
            self.render(new)
            // Survivor offsets follow their actual pre-clear rows; new jewels fall from above.
            for column in 0..<Game.side {
                let survivingRows = (0..<Game.side).filter { !turn.cleared.contains(Cell($0, column)) }
                for row in 0..<Game.side {
                    let cell = Cell(row, column)
                    guard let node = self.nodes[cell] else { continue }
                    let sourceRow = row < survivingRows.count ? survivingRows[row] : Game.side + row - survivingRows.count
                    node.position.y += CGFloat(sourceRow-row) * self.step
                    let move = SKAction.move(to: self.point(cell), duration: 0.26)
                    move.timingMode = .easeOut; node.run(move)
                }
            }
        }, .wait(forDuration: 0.28), .run { [weak self] in
            self?.render(new); completion()
        }]))
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self), step > 0 else { return }
        let column = Int(round((location.x-size.width/2)/step + 3))
        let row = Int(round((location.y-size.height/2)/step + 3))
        store?.tap(Cell(row, column))
    }
}
