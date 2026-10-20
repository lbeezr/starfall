import SpriteKit
import UIKit
import StarfallCore

// Bounded material transitions for committed Dusk influence.
extension FallingSkyCharacter {
    func setDrain(_ amount: Float) {
        setDrainDecoration(amount > 0)
        LivingLight.setDrain(amount, on: character)
    }

    func animateDrain(from start: Float, to end: Float) {
        removeAction(forKey: "dusk.drain")
        setDrain(max(0.001, start))
        run(.sequence([
            .customAction(withDuration: 0.38) { node, elapsed in
                guard let star = node as? FallingSkyCharacter else { return }
                star.setDrain(start + (end-start) * min(1, Float(elapsed / 0.38)))
            },
            .run { [weak self] in self?.setDrain(end) }
        ]), withKey: "dusk.drain")
    }
}

/// Presentation consumes committed targets. It never advances feeding or chooses removals.
@MainActor enum DuskPresentation {
    static func configure(_ node: FallingSkyCharacter, game: FallingSky, cell: Cell, step: CGFloat) {
        let drained = game.isDrained(at: cell)
        node.setDrain(drained ? 1 : 0)
        node.userData = node.userData ?? NSMutableDictionary()
        node.userData?["dusk.drained"] = drained
        node.childNode(withName: "dusk.progress")?.removeFromParent()
        guard game.duskRule != .legacy, node.gem.isDark else { return }
        let stage = node.gem.duskFeeds
        let root = SKNode(); root.name = "dusk.progress"
        let halo = SKShapeNode(circleOfRadius: step * (0.37 + CGFloat(stage) / CGFloat(game.duskRule.feedingShowers-1) * 0.11))
        halo.strokeColor = StarfallTheme.Dusk.rim; halo.fillColor = .clear
        halo.lineWidth = stage == game.duskRule.feedingShowers - 1 ? 2.5 : 1.2; halo.glowWidth = CGFloat(stage)
        root.addChild(halo)
        if stage > 0 {
            let core = SKShapeNode(circleOfRadius: step * (stage == game.duskRule.feedingShowers - 1 ? 0.23 : 0.15))
            core.fillColor = StarfallTheme.Dusk.core.withAlphaComponent(stage == game.duskRule.feedingShowers - 1 ? 0.72 : 0.38)
            core.strokeColor = StarfallTheme.Dusk.rim.withAlphaComponent(0.6)
            core.lineWidth = 1; core.zPosition = 2
            root.addChild(core)
        }
        for index in 0..<game.duskRule.feedingShowers {
            let mark = SKShapeNode(circleOfRadius: step * 0.045)
            mark.name = index < stage ? "dusk.fed" : "dusk.remaining"
            mark.position = CGPoint(x: (CGFloat(index)-CGFloat(game.duskRule.feedingShowers-1)/2)*step*0.15, y: -step*0.44)
            mark.strokeColor = StarfallTheme.Dusk.rim
            mark.fillColor = index < stage ? StarfallTheme.Dusk.rim : StarfallTheme.Dusk.core
            mark.lineWidth = 1.2; root.addChild(mark)
        }
        node.addChild(root)
    }

    static func transition(_ node: FallingSkyCharacter, wasDrained: Bool, drained: Bool, effects: SKNode, step: CGFloat) {
        guard wasDrained != drained else { return }
        node.animateDrain(from: wasDrained ? 1 : 0, to: drained ? 1 : 0)
        guard !drained else { return }
        let wave = SKShapeNode(circleOfRadius: step*0.32)
        wave.name = "dusk.release"; wave.position = node.position
        wave.strokeColor = StarCast.Identity(node.gem).color; wave.lineWidth = 2; wave.glowWidth = 3
        effects.addChild(wave)
        wave.run(.sequence([.group([.scale(to: 1.8,duration: 0.38),.fadeOut(withDuration: 0.38)]),.removeFromParent()]))
    }

}
