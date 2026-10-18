import SpriteKit
import UIKit
import StarfallCore

// Bounded material transitions for committed Dusk influence.
extension FallingSkyCharacter {
    private static let drainShaderSource = """
    void main() {
        vec4 color = texture2D(u_texture, v_tex_coord);
        float light = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
        vec2 d = vec2(0.009);
        float neighbor = min(min(texture2D(u_texture, v_tex_coord + vec2(d.x, 0.0)).a,
                                 texture2D(u_texture, v_tex_coord - vec2(d.x, 0.0)).a),
                             min(texture2D(u_texture, v_tex_coord + vec2(0.0, d.y)).a,
                                 texture2D(u_texture, v_tex_coord - vec2(0.0, d.y)).a));
        float rim = smoothstep(0.08, 0.45, color.a - neighbor);
        vec3 gray = vec3(light * 0.62 + color.a * 0.06);
        vec3 drained = mix(gray, color.rgb, rim * 0.9);
        gl_FragColor = vec4(mix(color.rgb, drained, u_drain), color.a) * v_color_mix;
    }
    """

    func setDrain(_ amount: Float) {
        setDrainDecoration(amount > 0)
        if amount <= 0 { character.shader = nil; return }
        if character.shader == nil {
            let shader = SKShader(source: Self.drainShaderSource)
            shader.uniforms = [SKUniform(name: "u_drain", float: amount)]
            character.shader = shader
        } else { character.shader?.uniformNamed("u_drain")?.floatValue = amount }
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
    static let collapseDuration: TimeInterval = 0.46

    static func configure(_ node: FallingSkyCharacter, game: FallingSky, cell: Cell, step: CGFloat) {
        let drained = game.isDrained(at: cell)
        node.setDrain(drained ? 1 : 0)
        node.userData = node.userData ?? NSMutableDictionary()
        node.userData?["dusk.drained"] = drained
        node.childNode(withName: "dusk.progress")?.removeFromParent()
        guard game.duskRule == .feeding, node.gem.isDark else { return }
        let stage = node.gem.duskFeeds
        let root = SKNode(); root.name = "dusk.progress"
        let halo = SKShapeNode(circleOfRadius: step * (0.37 + CGFloat(stage) * 0.055))
        halo.strokeColor = StarfallTheme.Dusk.rim; halo.fillColor = .clear
        halo.lineWidth = stage == DuskRule.feedingShowers - 1 ? 2.5 : 1.2; halo.glowWidth = CGFloat(stage)
        root.addChild(halo)
        if stage > 0 {
            let core = SKShapeNode(circleOfRadius: step * (stage == DuskRule.feedingShowers - 1 ? 0.23 : 0.15))
            core.fillColor = StarfallTheme.Dusk.core.withAlphaComponent(stage == DuskRule.feedingShowers - 1 ? 0.72 : 0.38)
            core.strokeColor = StarfallTheme.Dusk.rim.withAlphaComponent(0.6)
            core.lineWidth = 1; core.zPosition = 2
            root.addChild(core)
        }
        for index in 0..<DuskRule.feedingShowers {
            let mark = SKShapeNode(circleOfRadius: step * 0.045)
            mark.name = index < stage ? "dusk.fed" : "dusk.remaining"
            mark.position = CGPoint(x: CGFloat(index-1)*step*0.15, y: -step*0.44)
            mark.strokeColor = StarfallTheme.Dusk.rim
            mark.fillColor = index < stage ? StarfallTheme.Dusk.rim : StarfallTheme.Dusk.core
            mark.lineWidth = 1.2; root.addChild(mark)
        }
        node.addChild(root)
    }

    static func threats(game: FallingSky, cell: Cell, point: (Cell) -> CGPoint, step: CGFloat) -> SKNode? {
        let targets = game.duskTargets(at: cell)
        guard !targets.isEmpty else { return nil }
        let root = SKNode(); root.name = "dusk.threats"; root.zPosition = -1
        root.userData = ["column": cell.column]
        let center = point(cell)
        for target in targets {
            let start = point(target)
            let delta = CGVector(dx: center.x-start.x, dy: center.y-start.y)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: start.x+delta.dx*0.36,y: start.y+delta.dy*0.36))
            path.addLine(to: CGPoint(x: start.x+delta.dx*0.64,y: start.y+delta.dy*0.64))
            let line = SKShapeNode(path: path)
            line.strokeColor = StarfallTheme.Dusk.rim.withAlphaComponent(game.gem(at: cell)?.duskFeeds == DuskRule.feedingShowers - 1 ? 0.9 : 0.4)
            line.lineWidth = game.gem(at: cell)?.duskFeeds == DuskRule.feedingShowers - 1 ? 2.5 : 1.5
            root.addChild(line)
        }
        return root
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

    static func collapse(_ events: [DuskCollapse], from game: FallingSky,
                         nodes: [Int: FallingSkyCharacter], effects: SKNode,
                         point: (Cell) -> CGPoint, step: CGFloat) {
        var consumed: Set<Cell> = []
        for event in events {
            let center = point(event.center)
            let well = SKShapeNode(circleOfRadius: step*0.46)
            well.name = "dusk.collapse"; well.position = center
            well.fillColor = StarfallTheme.Dusk.core; well.strokeColor = StarfallTheme.Dusk.rim
            well.lineWidth = 3; well.glowWidth = 4
            effects.addChild(well)
            well.run(.sequence([.scale(to: 1.25,duration: 0.12),.group([.scale(to: 0.02,duration: 0.34),.fadeOut(withDuration: 0.34)]),.removeFromParent()]))
            for cell in event.consumed.union([event.center]).sorted(by: { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }) {
                guard consumed.insert(cell).inserted, let id = game.gem(at: cell)?.id, let node = nodes[id] else { continue }
                node.setGrowthMotion(false)
                node.run(.group([.move(to: center,duration: collapseDuration),
                                 .scale(to: 0.02,duration: collapseDuration),
                                 .rotate(byAngle: .pi*0.8,duration: collapseDuration),
                                 .fadeOut(withDuration: collapseDuration)]))
            }
        }
    }
}
