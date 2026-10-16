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

@MainActor final class JewelScene: SKScene, TurnPresenting {
    weak var store: GameStore?
    var reduceMotion = false
    private var nodes: [Cell: SKNode] = [:]
    private let boardRoot = SKNode()
    private let effectRoot = SKNode()
    private var presentationGeneration: UInt64 = 0
    var crystalPilotEnabled = CrystalPilot.isEnabled(arguments: ProcessInfo.processInfo.arguments)
    private var hasCrystalPilot: Bool {
        #if DEBUG
        return crystalPilotEnabled && CrystalPilot.frames.count == 9 && CrystalPilot.shards.count == 4
        #else
        return false
        #endif
    }
    // Read-only renderer diagnostics for focused hosted tests.
    var transientNodeCount: Int { effectRoot.children.count }
    var renderedJewelCount: Int { nodes.count }
    private var step: CGFloat { min(size.width, size.height) / 7.7 }
    override func didMove(to view: SKView) {
        if boardRoot.parent == nil { addChild(boardRoot) }
        if effectRoot.parent == nil { effectRoot.zPosition = 1; addChild(effectRoot) }
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
        effectRoot.removeAllChildren()
        boardRoot.removeAllChildren(); nodes.removeAll()
        for row in 0..<Game.side { for column in 0..<Game.side {
            let cell = Cell(row, column)
            let node = jewel(game.jewel(at: cell)!, radius: step * 0.37)
            node.position = point(cell); boardRoot.addChild(node); nodes[cell] = node
        } }
    }
    // Five size-independent textures are rasterized once, then shared by every cell.
    // The artwork has transparent padding; its silhouette still uses radius 0.37 × pitch.
    private static var jewelTextures: [Int: SKTexture] = [:]
    private func jewel(_ kind: Jewel, radius: CGFloat) -> SKNode {
        if kind == .aqua && hasCrystalPilot {
            let sprite = SKSpriteNode(texture: CrystalPilot.frames[CrystalPilot.neutralIndex])
            let side = CrystalPilot.canvasSide(radius: radius)
            sprite.size = CGSize(width: side, height: side)
            return sprite
        }
        let texture: SKTexture
        if let cached = Self.jewelTextures[kind.rawValue] {
            texture = cached
        } else {
            texture = Self.makeGlassTexture(kind)
            Self.jewelTextures[kind.rawValue] = texture
        }
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = CGSize(width: radius * 128 / 52, height: radius * 128 / 52)
        return sprite
    }

    private static func silhouette(_ kind: Jewel, radius: CGFloat) -> CGPath {
        if kind == .rose {
            return CGPath(ellipseIn: CGRect(x: -radius, y: -radius,
                                           width: radius * 2, height: radius * 2), transform: nil)
        }
        let sides = [0, 4, 3, 6, 4][kind.rawValue]
        let angle: CGFloat = kind == .mint ? .pi / 4 : .pi / 2
        let path = CGMutablePath()
        for index in 0..<sides {
            let a = angle + CGFloat(index) * 2 * .pi / CGFloat(sides)
            let vertex = CGPoint(x: cos(a) * radius, y: sin(a) * radius)
            if index == 0 { path.move(to: vertex) } else { path.addLine(to: vertex) }
        }
        path.closeSubpath()
        return path
    }

    private static func makeGlassTexture(_ kind: Jewel) -> SKTexture {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 2
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128), format: format)
        let image = renderer.image { drawing in
            let context = drawing.cgContext
            // Match SpriteKit's upward-positive coordinates for all five original silhouettes.
            context.translateBy(x: 64, y: 64)
            context.scaleBy(x: 1, y: -1)
            let path = silhouette(kind, radius: 52)
            let innerPath = silhouette(kind, radius: 44)
            let color = kind.color
            func tint(_ amount: CGFloat, toward target: UIColor) -> UIColor {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                target.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
                return UIColor(red: r + (tr - r) * amount,
                               green: g + (tg - g) * amount,
                               blue: b + (tb - b) * amount, alpha: 1)
            }
            func gradient(_ colors: [UIColor], from start: CGPoint, to end: CGPoint) {
                guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                                colors: colors.map { $0.cgColor } as CFArray,
                                                locations: nil) else { return }
                context.drawLinearGradient(gradient, start: start, end: end,
                                           options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            }
            let midnight = UIColor(red: 0.08, green: 0.06, blue: 0.24, alpha: 1)

            // Soft contact shadow, baked into the texture rather than a live blur node.
            context.saveGState()
            context.setShadow(offset: CGSize(width: 0, height: -4), blur: 7,
                              color: UIColor.black.withAlphaComponent(0.42).cgColor)
            context.addPath(path)
            context.setFillColor(tint(0.55, toward: midnight).cgColor)
            context.fillPath()
            context.restoreGState()

            // The outer bevel catches moonlight on its upper-left edge.
            context.saveGState()
            context.addPath(path); context.clip()
            gradient([tint(0.80, toward: .white), color, tint(0.56, toward: midnight)],
                     from: CGPoint(x: -38, y: 52), to: CGPoint(x: 28, y: -52))
            context.restoreGState()

            // A saturated inset keeps each color legible against the dark board.
            context.saveGState()
            context.addPath(innerPath); context.clip()
            gradient([tint(0.20, toward: .white), color, tint(0.34, toward: midnight)],
                     from: CGPoint(x: -24, y: 46), to: CGPoint(x: 20, y: -46))

            // Broad transparent reflection, clipped inside the same silhouette.
            let reflection = CGMutablePath()
            reflection.move(to: CGPoint(x: -58, y: 8))
            reflection.addLine(to: CGPoint(x: 10, y: 58))
            reflection.addLine(to: CGPoint(x: 39, y: 58))
            reflection.addLine(to: CGPoint(x: -45, y: -22))
            reflection.closeSubpath()
            context.saveGState()
            context.addPath(reflection); context.clip()
            gradient([UIColor.white.withAlphaComponent(0.36), UIColor.white.withAlphaComponent(0.02)],
                     from: CGPoint(x: -25, y: 40), to: CGPoint(x: 10, y: -32))
            context.restoreGState()

            // Low, soft caustic adds depth without another sharp concentric outline.
            if let glow = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: [tint(0.50, toward: .white).withAlphaComponent(0.48).cgColor,
                                              color.withAlphaComponent(0).cgColor] as CFArray,
                                     locations: [0, 1]) {
                context.drawRadialGradient(glow, startCenter: CGPoint(x: 12, y: -29), startRadius: 0,
                                           endCenter: CGPoint(x: 12, y: -29), endRadius: 39,
                                           options: [])
            }
            context.restoreGState()

            context.addPath(innerPath)
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.30).cgColor)
            context.setLineWidth(1.2); context.strokePath()
            context.addPath(path)
            context.setStrokeColor(tint(0.45, toward: .white).withAlphaComponent(0.85).cgColor)
            context.setLineWidth(1.4); context.strokePath()

            // Small reflected light source, always clipped so triangles stay triangles.
            context.saveGState()
            context.addPath(innerPath); context.clip()
            context.translateBy(x: -15, y: 24)
            context.rotate(by: .pi / 5)
            context.setFillColor(UIColor.white.withAlphaComponent(0.88).cgColor)
            context.fillEllipse(in: CGRect(x: -10, y: -3, width: 20, height: 6))
            context.restoreGState()
            context.saveGState()
            context.addPath(innerPath); context.clip()
            context.setFillColor(UIColor.white.withAlphaComponent(0.60).cgColor)
            context.fillEllipse(in: CGRect(x: 19, y: -27, width: 5, height: 5))
            context.restoreGState()
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }
    func cancelAnimations() {
        presentationGeneration &+= 1
        effectRoot.removeAllChildren()
        effectRoot.removeAllActions()
        removeAllActions()
        boardRoot.removeAllActions()
        for node in boardRoot.children { node.removeAllActions() }
    }
    func nudge(_ cell: Cell) {
        guard !reduceMotion else { return }
        nodes[cell]?.run(.sequence([.scale(to: 0.90, duration: 0.07), .scale(to: 1, duration: 0.10)]))
    }
    func animate(turn: Turn, old: Game, new: Game, completion: @escaping () -> Void) {
        cancelAnimations()
        let generation = presentationGeneration
        if store?.soundEnabled == true { AudioServicesPlaySystemSound(1104) }
        if reduceMotion || UIAccessibility.isVoiceOverRunning || view == nil { render(new); completion(); return }
        // Stable order makes the global shard cap deterministic without touching gameplay RNG.
        let cleared = turn.cleared.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        var shardBudget = CrystalPilot.maximumShards
        for cell in cleared {
            if hasCrystalPilot && old.jewel(at: cell) == .aqua {
                nodes[cell]?.run(.sequence([CrystalPilot.tiltAction(), .fadeOut(withDuration: 0.02), .removeFromParent()]))
                if shardBudget >= 4 {
                    addCrystalShards(at: cell)
                    shardBudget -= 4
                }
                continue
            }
            nodes[cell]?.run(.sequence([.scale(to: 1.12, duration: 0.06), .group([.fadeOut(withDuration: 0.13), .scale(to: 0.15, duration: 0.13)]), .removeFromParent()]))
            let spark = SKLabelNode(text: "✦")
            spark.fontSize = 14; spark.fontColor = old.jewel(at: cell)?.color
            spark.position = point(cell); effectRoot.addChild(spark)
            spark.run(.sequence([.group([.moveBy(x: 0, y: 18, duration: 0.28), .fadeOut(withDuration: 0.28)]), .removeFromParent()]))
        }
        run(.sequence([.wait(forDuration: 0.20), .run { [weak self] in
            guard let self, self.presentationGeneration == generation else { return }
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
            guard let self, self.presentationGeneration == generation else { return }
            self.render(new); completion()
        }]))
    }
    private func addCrystalShards(at cell: Cell) {
        let side = CrystalPilot.canvasSide(radius: step * 0.37)
        for index in 0..<4 {
            let x: CGFloat = index % 2 == 0 ? -1 : 1
            let y: CGFloat = index / 2 == 0 ? 1 : -1
            let shard = SKSpriteNode(texture: CrystalPilot.shards[index])
            shard.size = CGSize(width: side / 2, height: side / 2)
            shard.position = CGPoint(x: point(cell).x + x * side / 4,
                                     y: point(cell).y + y * side / 4)
            shard.alpha = 0
            effectRoot.addChild(shard)
            shard.run(.sequence([.wait(forDuration: 0.06), .fadeIn(withDuration: 0),
                .group([.moveBy(x: x * step * 0.18, y: y * step * 0.18, duration: 0.13),
                        .rotate(byAngle: x * y * 0.35, duration: 0.13),
                        .fadeOut(withDuration: 0.13)]), .removeFromParent()]))
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: self), step > 0 else { return }
        let column = Int(round((location.x-size.width/2)/step + 3))
        let row = Int(round((location.y-size.height/2)/step + 3))
        store?.tap(Cell(row, column))
    }
}
