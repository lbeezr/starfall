import SpriteKit
import StarfallCore

/// Reads committed age. No clocks, cached artwork or autonomous state transitions.
@MainActor enum CriticalMassPresentation {
    private static let corruptionShader = """
    void main() {
        vec4 color = texture2D(u_texture, v_tex_coord);
        float light = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
        float body = smoothstep(0.10, 0.42, light);
        vec3 purple = u_corruption.rgb * (0.35 + light * 0.90) * color.a;
        gl_FragColor = vec4(mix(color.rgb, purple, body * 0.94), color.a) * v_color_mix;
    }
    """

    static func configure(_ node: FallingSkyCharacter, game: FallingSky, cell: Cell, step: CGFloat) {
        guard game.hasCriticalMass else { return }
        guard node.gem.isCritical else { return }
        let shader = SKShader(source: corruptionShader)
        shader.uniforms = [SKUniform(name: "u_corruption", vectorFloat4: StarfallTheme.Dusk.corruption)]
        node.character.shader = shader
        let cue = SKNode(); cue.name = "sky.critical-mass"
        // A broken inward diamond distinguishes corruption from violet Nova and value glints.
        let path = CGMutablePath()
        for direction in [CGVector(dx: 0, dy: 1), CGVector(dx: 1, dy: 0), CGVector(dx: 0, dy: -1), CGVector(dx: -1, dy: 0)] {
            path.move(to: CGPoint(x: direction.dx * step * 0.48, y: direction.dy * step * 0.48))
            path.addLine(to: CGPoint(x: direction.dx * step * 0.36, y: direction.dy * step * 0.36))
        }
        let marks = SKShapeNode(path: path)
        marks.strokeColor = StarfallTheme.Dusk.rim; marks.lineWidth = 2.5
        cue.addChild(marks)
        let core = SKShapeNode(circleOfRadius: step * 0.1)
        core.fillColor = StarfallTheme.Dusk.core
        core.strokeColor = StarfallTheme.Dusk.rim
        core.position = CGPoint(x: 0, y: -step * 0.22)
        cue.addChild(core)
        cue.zPosition = 3; node.addChild(cue)
    }

    nonisolated static func warning(game: FallingSky) -> String? {
        guard game.hasCriticalMass, !game.isOver,
              let gem = game.board.compactMap({ $0 }).filter(\.isCritical).max(by: { $0.stellarAge < $1.stellarAge }) else { return nil }
        return SkyCopy.text(.massWarning, values: ["showers": SkyCopy.count(.massShowersOne, .massShowersMany, CriticalMassRule.collapseAge - gem.stellarAge)])
    }

    nonisolated static func consequence(game: FallingSky, cell: Cell) -> String {
        guard game.hasCriticalMass, let gem = game.gem(at: cell) else { return "" }
        let age = SkyCopy.text(.massState, values: ["stage": String(gem.massStage), "showers": SkyCopy.count(.massShowersOne, .massShowersMany, CriticalMassRule.collapseAge - gem.stellarAge)])
        guard gem.isCritical else { return age }
        let positions = game.criticalMassTargets(at: cell).sorted {
            $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
        }.map { SkyCopy.position(row: 7-$0.row, column: $0.column+1) }.joined(separator: "; ")
        return age + " " + SkyCopy.text(.massTargets, values: ["positions": positions.isEmpty ? SkyCopy.text(.massNoNeighbors) : positions])
    }
}

/// One bounded swallow animation for current stars and historical Dusk sources.
@MainActor enum StarCollapsePresentation {
    static let collapseDuration: TimeInterval = 0.46

    static func threats(game: FallingSky, cell: Cell, point: (Cell) -> CGPoint, step: CGFloat) -> SKNode? {
        let targets = game.hasCriticalMass ? game.criticalMassTargets(at: cell) : game.duskTargets(at: cell)
        let imminent = game.hasCriticalMass
            ? game.gem(at: cell)?.stellarAge == CriticalMassRule.collapseAge - 1
            : game.gem(at: cell)?.duskFeeds == game.duskRule.feedingShowers - 1
        guard !targets.isEmpty else { return nil }
        let root = SKNode(); root.name = "sky.collapse-threats"; root.zPosition = -1
        root.userData = ["column": cell.column]
        let center = point(cell)
        for target in targets {
            let start = point(target)
            let delta = CGVector(dx: center.x-start.x, dy: center.y-start.y)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: start.x+delta.dx*0.36,y: start.y+delta.dy*0.36))
            path.addLine(to: CGPoint(x: start.x+delta.dx*0.64,y: start.y+delta.dy*0.64))
            let line = SKShapeNode(path: path)
            line.strokeColor = StarfallTheme.Dusk.rim.withAlphaComponent(imminent ? 0.9 : 0.4)
            line.lineWidth = imminent ? 2.5 : 1.5
            root.addChild(line)
        }
        return root
    }


    static func collapse(_ events: [StarCollapse], from game: FallingSky,
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
