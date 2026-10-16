import SpriteKit
import UIKit
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
    private let arrivalEffects = StarfallArrivalEffects()
    private var activeTouch: UITouch?
    private var touchStartCell: Cell?
    private(set) var previewedCells: Set<Cell> = []
    static let maximumClearSparks = 12
    private var presentationGeneration: UInt64 = 0
    // Shared bounded cache in production; injectable to exercise unavailable art.
    var artwork = StarshardArtwork.shared
    private var activeFamily: [Jewel: StarshardArtwork.FrameSet]? {
        #if DEBUG
        // Keep the original aqua pilot a separate, explicit comparison route.
        if crystalPilotEnabled { return nil }
        #endif
        return artwork.completeFamily
    }
    var crystalPilotEnabled = CrystalPilot.isEnabled(arguments: ProcessInfo.processInfo.arguments)
    private var hasCrystalPilot: Bool {
        #if DEBUG
        return crystalPilotEnabled && CrystalPilot.frames.count == 9 && CrystalPilot.shards.count == 4
        #else
        return false
        #endif
    }
    // Read-only renderer diagnostics for focused hosted tests.
    var transientNodeCount: Int {
        func descendants(_ root: SKNode) -> Int {
            root.children.reduce(0) { $0 + 1 + descendants($1) }
        }
        // Arrival trails are children of jewels; include them in cleanup diagnostics.
        return descendants(effectRoot) + boardRoot.children.reduce(0) { $0 + descendants($1) }
    }
    var renderedJewelCount: Int { nodes.count }
    var starshardArtworkIsActive: Bool { activeFamily != nil }
    func renderedTexture(at cell: Cell) -> SKTexture? { (nodes[cell] as? SKSpriteNode)?.texture }
    func renderedSize(at cell: Cell) -> CGSize? { (nodes[cell] as? SKSpriteNode)?.size }
    func renderedPosition(at cell: Cell) -> CGPoint? { nodes[cell]?.position }
    func renderedAlpha(at cell: Cell) -> CGFloat? { nodes[cell]?.alpha }
    func renderedAnchorPoint(at cell: Cell) -> CGPoint? { (nodes[cell] as? SKSpriteNode)?.anchorPoint }
    private var step: CGFloat { min(size.width, size.height) / 7.7 }
    private var motionIsSuppressed: Bool {
        reduceMotion || store?.calmEffects == true || UIAccessibility.isReduceMotionEnabled
            || UIAccessibility.isVoiceOverRunning || view == nil
    }
    override func didMove(to view: SKView) {
        if boardRoot.parent == nil { addChild(boardRoot) }
        if effectRoot.parent == nil { effectRoot.zPosition = 1; addChild(effectRoot) }
        if let game = store?.game { render(game) }
    }
    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != size else { return }
        cancelTouch()
        if let store {
            // Layout can change during a turn. Settle both the visuals and store lock.
            store.settlePresentation()
        } else {
            cancelAnimations()
        }
    }
    override func willMove(from view: SKView) {
        cancelTouch()
        if let store { store.settlePresentation() } else { cancelAnimations() }
    }
    private func point(_ cell: Cell) -> CGPoint {
        CGPoint(x: size.width/2 + (CGFloat(cell.column)-3)*step, y: size.height/2 + (CGFloat(cell.row)-3)*step)
    }
    func render(_ game: Game) {
        cancelTouch()
        arrivalEffects.cancel()
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
        if let frames = activeFamily?[kind] {
            let sprite = SKSpriteNode(texture: frames.neutralFrame)
            let side = frames.canvasSide(radius: radius)
            sprite.size = CGSize(width: side, height: side)
            // Preserve the authored 128/128 pivot, including amber's high silhouette.
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            return sprite
        }
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
        cancelTouch()
        arrivalEffects.cancel()
        effectRoot.removeAllChildren()
        effectRoot.removeAllActions()
        removeAllActions()
        boardRoot.removeAllActions()
        for node in boardRoot.children { node.removeAllActions() }
    }
    func nudge(_ cell: Cell) {
        guard let node = nodes[cell] else { return }
        node.removeAction(forKey: "touch-feedback")
        node.setScale(1)
        let frames = store?.game.jewel(at: cell).flatMap { activeFamily?[$0] }
        if let frames { (node as? SKSpriteNode)?.texture = frames.neutralFrame }
        guard !motionIsSuppressed else { return }
        if let frames {
            node.run(.animate(with: frames.tiltSequence(),
                                     timePerFrame: StarshardArtwork.tiltTimePerFrame,
                                     resize: false, restore: false), withKey: "touch-feedback")
            return
        }
        node.run(.sequence([.scale(to: 0.94, duration: 0.07), .scale(to: 1, duration: 0.10)]),
                 withKey: "touch-feedback")
    }
    func animate(turn: Turn, old: Game, new: Game, completion: @escaping () -> Void) {
        cancelAnimations()
        let generation = presentationGeneration
        if motionIsSuppressed { render(new); completion(); return }
        let mapping = RefillMapping(turn: turn, settled: new)
        // Stable order makes the global shard cap deterministic without touching gameplay RNG.
        let cleared = turn.cleared.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        let family = activeFamily
        // Cancelling an invalid-tap response freezes its current scale or tilt frame.
        // Restore the source board's neutral pose before this turn clears any pieces.
        for (cell, node) in nodes {
            node.setScale(1)
            if let kind = old.jewel(at: cell), let frames = family?[kind],
               let sprite = node as? SKSpriteNode {
                sprite.texture = frames.neutralFrame
            }
        }
        var shardBudget = family == nil ? CrystalPilot.maximumShards : StarshardArtwork.maximumShards
        // Large clears share twelve soft sparks instead of filling every cell with effects.
        let sparkStride = max(1, Int(ceil(Double(cleared.count) / Double(Self.maximumClearSparks))))
        for (clearIndex, cell) in cleared.enumerated() {
            if let kind = old.jewel(at: cell), let frames = family?[kind] {
                nodes[cell]?.run(.sequence([
                    .animate(with: frames.clearTiltSequence(), timePerFrame: StarshardArtwork.tiltTimePerFrame,
                             resize: false, restore: false),
                    .fadeOut(withDuration: 0.02), .removeFromParent()]))
                if shardBudget >= StarshardArtwork.fragmentCount {
                    addShards(textures: frames.fragments, side: frames.canvasSide(radius: step * 0.37), at: cell)
                    shardBudget -= StarshardArtwork.fragmentCount
                }
                continue
            }
            if hasCrystalPilot && old.jewel(at: cell) == .aqua {
                nodes[cell]?.run(.sequence([CrystalPilot.tiltAction(), .fadeOut(withDuration: 0.02), .removeFromParent()]))
                if shardBudget >= 4 {
                    addCrystalShards(at: cell)
                    shardBudget -= 4
                }
                continue
            }
            nodes[cell]?.run(.sequence([.scale(to: 1.12, duration: 0.06), .group([.fadeOut(withDuration: 0.13), .scale(to: 0.15, duration: 0.13)]), .removeFromParent()]))
            if clearIndex % sparkStride == 0 {
                let spark = SKLabelNode(text: "✦")
                spark.fontSize = step * 0.25
                spark.fontColor = old.jewel(at: cell)?.color
                spark.verticalAlignmentMode = .center
                spark.position = point(cell); effectRoot.addChild(spark)
                spark.run(.sequence([.group([.moveBy(x: 0, y: step * 0.28, duration: 0.19),
                                            .fadeOut(withDuration: 0.19)]), .removeFromParent()]))
            }
        }
        run(.sequence([.wait(forDuration: 0.20), .run { [weak self] in
            guard let self, self.presentationGeneration == generation else { return }
            self.render(new)
            self.arrivalEffects.play(
                mapping: mapping, nodes: self.nodes,
                boardBounds: CGRect(origin: .zero, size: self.size), step: self.step,
                in: self.effectRoot, calmEffects: self.store?.calmEffects ?? false,
                reduceMotion: self.reduceMotion, point: { self.point($0) }
            ) { [weak self] in
                guard let self, self.presentationGeneration == generation else { return }
                // Arrival completion has snapped the final nodes and removed every
                // arrival action, trail and clock. Keep those already-settled sprites.
                completion()
            }
        }]))
    }
    private func addCrystalShards(at cell: Cell) {
        addShards(textures: CrystalPilot.shards, side: CrystalPilot.canvasSide(radius: step * 0.37), at: cell)
    }
    private func addShards(textures: [SKTexture], side: CGFloat, at cell: Cell) {
        for (index, texture) in textures.enumerated() {
            let x: CGFloat = index % 2 == 0 ? -1 : 1
            let y: CGFloat = index / 2 == 0 ? 1 : -1
            let shard = SKSpriteNode(texture: texture)
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
    /// Full-cell hit targets, with explicit bounds before converting coordinates to Int.
    /// The outer board padding never chooses an edge cell or sends an invalid rule tap.
    func cell(at location: CGPoint) -> Cell? {
        guard step.isFinite, step > 0, location.x.isFinite, location.y.isFinite else { return nil }
        let edge = CGFloat(Game.side) * step / 2
        let minX = size.width / 2 - edge, minY = size.height / 2 - edge
        guard location.x >= minX, location.x < minX + edge * 2,
              location.y >= minY, location.y < minY + edge * 2 else { return nil }
        return Cell(Int(floor((location.y - minY) / step)), Int(floor((location.x - minX) / step)))
    }

    /// A still emphasis shows the exact connected group without moving any jewel.
    /// It carries no exclusive information and is also safe in Calm/Reduce Motion.
    func showTouchPreview(at cell: Cell?) {
        let wasPreviewing = !previewedCells.isEmpty
        previewedCells.removeAll()
        if wasPreviewing { for node in nodes.values { node.alpha = 1 } }
        guard let cell, let store, store.playing, !store.settings, !store.busy, store.game.outcome == .playing else { return }
        let group = store.game.group(at: cell)
        guard group.count >= 3 else { return }
        previewedCells = group
        for (cell, node) in nodes { node.alpha = group.contains(cell) ? 1 : 0.48 }
    }
    private func cancelTouch() {
        activeTouch = nil
        touchStartCell = nil
        showTouchPreview(at: nil)
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, touches.count == 1, (event?.allTouches?.count ?? 1) == 1,
              let store, store.playing, !store.settings, !store.busy, store.game.outcome == .playing,
              let touch = touches.first, let cell = cell(at: touch.location(in: self)) else {
            cancelTouch()
            return
        }
        activeTouch = touch
        touchStartCell = cell
        showTouchPreview(at: cell)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        if cell(at: touch.location(in: self)) != touchStartCell { cancelTouch() }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelTouch()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let selected = touchStartCell
        let touch = activeTouch
        let endsInSameCell = touch.map { cell(at: $0.location(in: self)) == selected } ?? false
        cancelTouch()
        guard let touch, touches.count == 1, touches.contains(touch), endsInSameCell,
              let selected else { return }
        store?.tap(selected)
    }
}
