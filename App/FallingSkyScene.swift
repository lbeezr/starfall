import UIKit
import SpriteKit
import StarfallCore

/// Only presents committed turns. The view supplies native, full-cell buttons.
@MainActor final class FallingSkyScene: SKScene, FallingSkyPresenting {
    var reduceMotion = false
    var onLayout: (() -> Void)?
    var onReadinessChanged: ((Bool) -> Void)?
    private var nodes: [Int: FallingSkyCharacter] = [:]
    private var cellsByID: [Int: Cell] = [:]
    private var rendered: FallingSky?
    private let pieces = SKNode(), effects = SKNode(), grid = SKNode()
    private let constellationTrail = SKNode()
    private var step: CGFloat { ObservatoryGeometry(size: size).imageRect.width / 7.7 }

    override init(size: CGSize) {
        super.init(size: size)
        StarCast.prewarm(); OpalMotion.prewarm()
        scaleMode = .resizeFill; backgroundColor = .clear
        addChild(grid); addChild(pieces); addChild(effects)
        effects.zPosition = 20
        constellationTrail.zPosition = 12; addChild(constellationTrail)
    }
    override convenience init() { self.init(size: CGSize(width: 350, height: 350)) }
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func didChangeSize(_ oldSize: CGSize) {
        guard oldSize != size else { return }
        onLayout?()
        reportReadiness()
    }
    override func didMove(to view: SKView) {
        if let rendered { render(rendered) }
        reportReadiness()
    }
    override func willMove(from view: SKView) { onReadinessChanged?(false); onLayout?() }

    private func reportReadiness() {
        guard let view else { onReadinessChanged?(false); return }
        onReadinessChanged?(size.width > 0 && size.height > 0 &&
            abs(size.width - view.bounds.width) < 1 && abs(size.height - view.bounds.height) < 1)
    }

    private func point(_ cell: Cell) -> CGPoint {
        ObservatoryGeometry(size: size).scenePoint(cell)
    }

    private func makeNode(_ gem: StarfallGem) -> FallingSkyCharacter {
        FallingSkyCharacter(gem: gem, step: step)
    }

    private func ground(_ gem: StarfallGem, at cell: Cell) {
        guard gem.gravityKind != .magnet else { return }
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
        StarCast.groundOffset(for: .init(gem), radius: step * (gem.grown ? 0.43 : 0.35))
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

    private func shade(_ node: SKNode) { node.alpha = 0.65 }

    func render(_ game: FallingSky) {
        rendered = game
        constellationTrail.removeAllChildren()
        removeAllActions(); effects.removeAllChildren(); effects.removeAllActions()
        pieces.removeAllChildren(); grid.removeAllChildren(); nodes.removeAll(); cellsByID.removeAll()
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            if let gem = game.gem(at: cell) {
                ground(gem, at: cell)
                let node = makeNode(gem); node.position = point(cell)
                node.zPosition = CGFloat(7-cell.row)
                if game.isGrowthBlocked(at: cell) { shade(node) }
                pieces.addChild(node); nodes[gem.id] = node; cellsByID[gem.id] = cell

            }
        } }
        renderGravityField(game.orbit)
    }

    func animate(_ turn: FallingSkyTurn, from old: FallingSky,
                 to game: FallingSky, completion: @escaping () -> Void) {
        if !turn.gravityPhases.isEmpty {
            animateGravity(turn, from: old, to: game, completion: completion); return
        }
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
                    self.light(at: self.point(cell), color: old.gem(at: cell).map { StarCast.Identity($0).color } ?? .systemPurple, strength: 0.75)
                }]))
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
            guard let id = cellsByID.first(where: { $0.value == cell })?.key, let node = nodes[id],
                  node.gem.gravityKind != .magnet else { continue }
            let offset = point(cell)
            let target = point(arrival.cell)
            guard hypot(offset.x-target.x, offset.y-target.y) <= step * 1.15 else { continue }
            return node
        }
        return nil
    }

    private func sendStar(_ arrival: FallingSkyTurn.Arrival) {
        let comet = SKNode()
        comet.name = "sky.flight.\(arrival.star.id)"
        let color = StarCast.Identity(arrival.star).color
        // A bounded handful of shapes per star, with no emitters or accumulating particles.
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -step * 0.13, y: 0))
        tailPath.addQuadCurve(to: CGPoint(x: 0, y: step * 2.7), control: CGPoint(x: -step * 0.08, y: step))
        tailPath.addQuadCurve(to: CGPoint(x: step * 0.13, y: 0), control: CGPoint(x: step * 0.08, y: step))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor = color.withAlphaComponent(arrival.star.isLight ? 0.14 : 0.3); tail.strokeColor = .clear
        tail.glowWidth = arrival.star.isLight ? 2 : 4
        comet.addChild(tail)
        let halo = SKShapeNode(circleOfRadius: step * 0.20)
        halo.fillColor = color.withAlphaComponent(arrival.star.isLight ? 0.06 : 0.3)
        halo.strokeColor = color.withAlphaComponent(arrival.star.isLight ? 0.10 : 0.5)
        halo.glowWidth = arrival.star.isLight ? 3 : 9
        comet.addChild(halo)
        let traveler = JewelScene.makeStarCharacter(.init(arrival.star), expression: .landing, radius: step * 0.35)
        if arrival.star.isLight {
            traveler.subdivisionLevels = 2
            traveler.warpGeometry = OpalMotion.falling
        }
        traveler.zRotation = arrival.star.id.isMultiple(of: 2) ? -0.12 : 0.12
        traveler.run(.group([
            StarCast.turnAction(for: .init(arrival.star), expression: .landing,
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
        // Scene actions and child actions can advance on adjacent frames. The
        // landing handoff owns removal, so one committed star has one visible body.
        effects.childNode(withName: "sky.flight.\(arrival.star.id)")?.removeFromParent()
        let existing = nodes[arrival.gem.id]
        let node = existing ?? makeNode(arrival.gem)
        node.update(arrival.gem, expression: .landing)
        node.run(.sequence([.wait(forDuration: 0.12), .run { [weak node] in
            guard let node else { return }
            node.showExpression(arrival.gem.grown ? .grown : .idle)
        }]))
        let destination = point(arrival.cell)
        node.position = destination
        node.zPosition = CGFloat(7-arrival.cell.row)
        if existing == nil { pieces.addChild(node) }
        nodes[arrival.gem.id] = node; cellsByID[arrival.gem.id] = arrival.cell
        grid.childNode(withName: "sky.ground.\(arrival.gem.id)")?.removeFromParent()
        ground(arrival.gem, at: arrival.cell)
        if arrival.gem.gravityKind == .magnet {
            node.character.run(.sequence([.fadeAlpha(to: 0.55, duration: 0.12),
                                          .fadeAlpha(to: 1, duration: 0.16)]), withKey: "gravity.field-formation")
            return
        }
        light(at: destination, color: StarCast.Identity(arrival.star).color,
              strength: arrival.gem.isDark ? 0.25 : arrival.grew ? 1 : 0.65)
        node.xScale = arrival.gem.isLight ? 1 : 1.13
        node.yScale = arrival.gem.isLight ? 1 : 0.78
        node.zRotation = arrival.gem.isLight ? 0 : arrival.gem.id.isMultiple(of: 2) ? -0.10 : 0.10
        node.softenLanding()
        let rebound = (arrival.gem.isLight ? 0.12 : StarfallMotion.rebound(dark: arrival.gem.isDark, grew: arrival.grew)) * step
        let drift = StarfallMotion.drift(for: arrival.star.id, column: arrival.cell.column) * step
        let bounce = SKAction.move(to: CGPoint(x: destination.x + drift * 0.10, y: destination.y + rebound), duration: 0.10)
        bounce.timingMode = .easeOut
        let settle = SKAction.move(to: destination, duration: 0.18)
        settle.timingMode = .easeInEaseOut
        node.run(.group([
            .sequence([bounce, settle]),
            arrival.gem.isLight ? .wait(forDuration: 0) : .sequence([.scaleX(to: 0.94, y: 1.08, duration: 0.12), .scaleX(to: 1, y: 1, duration: 0.16)]),
            .sequence([.rotate(toAngle: -node.zRotation * 0.6, duration: 0.12), .rotate(toAngle: 0, duration: 0.16)])
        ]))
    }
}



extension FallingSkyScene {
    func clearConstellationTrace() { constellationTrail.removeAllActions(); constellationTrail.removeAllChildren() }

    func showConstellationTrace(_ path: [Cell], ready: Bool) {
        clearConstellationTrace()
        guard path.count <= 196, !path.isEmpty else { return }
        let route = CGMutablePath()
        route.move(to: point(path[0]))
        for cell in path.dropFirst() { route.addLine(to: point(cell)) }
        let thread = SKShapeNode(path: route)
        thread.name = "constellation.trace.thread"
        thread.strokeColor = UIColor(StarfallTheme.Observatory.lanternGlow).withAlphaComponent(ready ? 1 : 0.7)
        thread.lineWidth = ready ? 2.4 : 1.5; thread.glowWidth = reduceMotion ? 0 : 4
        constellationTrail.addChild(thread)
        for (index, cell) in Set(path).sorted(by: { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }).enumerated() {
            let spark = SKShapeNode(circleOfRadius: step * 0.055)
            spark.name = "constellation.trace.spark"
            spark.position = point(cell)
            spark.fillColor = UIColor(StarfallTheme.Observatory.lanternGlow); spark.strokeColor = .white
            spark.glowWidth = reduceMotion ? 0 : 3
            constellationTrail.addChild(spark)
            if !reduceMotion {
                spark.run(.repeatForever(.sequence([.wait(forDuration: Double(index%3)*0.05), .fadeAlpha(to: 0.3, duration: 0.2), .fadeAlpha(to: 1, duration: 0.2)])))
            }
        }
        let tip = SKShapeNode(circleOfRadius: step * 0.075)
        tip.name = "constellation.trace.tip"; tip.fillColor = .white; tip.strokeColor = .clear
        tip.glowWidth = reduceMotion ? 0 : 5; tip.position = point(path.last!)
        constellationTrail.addChild(tip)
        let lead = SKShapeNode()
        lead.name = "constellation.trace.lead"; lead.position = point(path.last!)
        lead.strokeColor = UIColor(StarfallTheme.Observatory.lanternGlow).withAlphaComponent(0.65)
        lead.lineWidth = 1.4; lead.glowWidth = reduceMotion ? 0 : 3
        constellationTrail.addChild(lead)
    }

    func moveConstellationTip(_ location: CGPoint) {
        let current = CGPoint(x: location.x, y: size.height-location.y)
        if let tip = constellationTrail.childNode(withName: "constellation.trace.tip") {
            let previous = tip.position
            if !reduceMotion && hypot(current.x-previous.x,current.y-previous.y) >= 3 {
                let motes = constellationTrail.children.filter { $0.name == "constellation.trace.mote" }
                if motes.count >= 24 { motes.first?.removeFromParent() }
                let mote = SKShapeNode(circleOfRadius: step*0.025)
                mote.name = "constellation.trace.mote"; mote.position = previous
                mote.fillColor = .white; mote.strokeColor = .clear; mote.glowWidth = 2
                constellationTrail.addChild(mote)
                mote.run(.sequence([.group([.fadeOut(withDuration: 0.25),.scale(to:0.1,duration:0.25)]),.removeFromParent()]))
            }
            tip.position = current
        }
        if let lead = constellationTrail.childNode(withName:"constellation.trace.lead") as? SKShapeNode {
            let path=CGMutablePath(); path.move(to:.zero)
            path.addLine(to:CGPoint(x:current.x-lead.position.x,y:current.y-lead.position.y));lead.path=path
        }
    }

    func constellationBurst(_ path: [Cell]) {
        clearConstellationTrace()
        guard !reduceMotion else { return }
        let shape=CGMutablePath()
        if let first=path.first { shape.move(to:point(first)) }
        for cell in path.dropFirst() { shape.addLine(to:point(cell)) }
        let pulseShape=SKShapeNode(path:shape)
        pulseShape.name="constellation.trace.release-shape";pulseShape.strokeColor = .white
        pulseShape.lineWidth=2.8;pulseShape.glowWidth=6;pulseShape.alpha=0.8
        effects.addChild(pulseShape)
        pulseShape.run(.sequence([.fadeAlpha(to:1,duration:0.06),.wait(forDuration:0.08),.fadeOut(withDuration:0.2),.removeFromParent()]))
        for cell in Set(path) {
            let center = point(cell)
            for index in 0..<6 {
                let angle = CGFloat(index) * .pi / 3
                let spark = SKShapeNode(circleOfRadius: step*0.025)
                spark.position = center; spark.fillColor = .white; spark.strokeColor = .clear; spark.glowWidth = 2
                effects.addChild(spark)
                spark.run(.sequence([.wait(forDuration:0.12),.group([.moveBy(x: cos(angle)*step*0.7, y: sin(angle)*step*0.55, duration: 0.36), .fadeOut(withDuration: 0.4)]), .removeFromParent()]))
            }
        }
    }
}

// Finite gravity presentation follows committed Core phases.
extension FallingSkyScene {
    private func renderGravityField(_ field: OrbitField?) {
        grid.children.filter { $0.name == "gravity.field" }.forEach { $0.removeFromParent() }
        guard let field else { return }
        let root = SKNode(); root.name = "gravity.field"
        let center = point(field.center)
        for cell in field.slots {
            let path = CGMutablePath(); path.move(to:center); path.addLine(to:point(cell))
            let line = SKShapeNode(path:path.copy(dashingWithPhase:0,lengths:[3,4]))
            line.strokeColor = StarfallTheme.Gravity.orbitLight.withAlphaComponent(0.65); line.lineWidth = 1.5
            root.addChild(line)
        }
        for index in 0..<field.windowsRemaining {
            let dot=SKShapeNode(circleOfRadius:step*0.035)
            dot.fillColor = StarfallTheme.Gravity.magneticLight; dot.strokeColor = .clear
            dot.position = CGPoint(x:center.x+CGFloat(index-1)*step*0.13,y:center.y-step*0.42)
            root.addChild(dot)
        }
        grid.addChild(root)
    }
    private func applyGravityPhase(_ phase: GravityPhase, duration: TimeInterval) {
        let targetIDs=Set(phase.board.compactMap { $0?.id })
        for id in Array(nodes.keys) where !targetIDs.contains(id) {
            let node=nodes.removeValue(forKey:id)
            cellsByID.removeValue(forKey:id)
            var disappearance: [SKAction] = [.scale(to:0.1,duration:duration),.fadeOut(withDuration:duration)]
            if phase.event == .collision,
               let hole=phase.board.firstIndex(where: { $0?.gravityKind == .hole }) {
                disappearance.append(.move(to:point(Cell(hole/7,hole%7)),duration:duration))
            }
            if phase.event == .collision, let node,
               let hole = phase.board.firstIndex(where: { $0?.gravityKind == .hole }) {
                let direction: CGFloat = point(Cell(hole/7,hole%7)).x > node.position.x ? 1 : -1
                node.character.run(GravityMotion.attraction(direction: direction, step: step, duration: duration))
            }
            node?.run(.sequence([.group(disappearance),.removeFromParent()]))
        }
        grid.removeAllChildren()
        for index in phase.board.indices {
            guard let gem=phase.board[index] else { continue }
            let cell=Cell(index/7,index%7), destination=point(cell)
            let existing=nodes[gem.id]
            let node=existing ?? makeNode(gem)
            if existing == nil {
                node.position=destination; node.setScale(0.1); pieces.addChild(node); nodes[gem.id]=node
                node.run(.scale(to:1,duration:duration))
            }
            if phase.event == .rotation, gem.gravityKind == .hole {
                node.character.run(GravityMotion.ringResponse(duration: duration), withKey: "gravity.ring-response")
            }
            if cellsByID[gem.id] != cell {
                if phase.event == .rotation, let field=phase.field {
                    let center=point(field.center), start=node.position
                    let a=atan2(start.y-center.y,start.x-center.x)
                    let b=atan2(destination.y-center.y,destination.x-center.x)
                    var delta=b-a
                    // Scene y points up: clockwise takes a negative angle, even for skipped slots.
                    while delta >= 0 { delta -= 2 * .pi }
                    let ra=hypot(start.x-center.x,start.y-center.y)
                    let rb=hypot(destination.x-center.x,destination.y-center.y)
                    node.run(.customAction(withDuration:duration) { target, elapsed in
                        let t=min(1,CGFloat(elapsed)/CGFloat(duration))
                        let radius=ra+(rb-ra)*t, angle=a+delta*t
                        // Floor arcs lift into the terrace rather than travelling below its front edge.
                        let dy=sin(angle)*radius
                        target.position=CGPoint(x:center.x+cos(angle)*radius,
                                                y:center.y+(field.center.row == 0 ? abs(dy) : dy))
                    })
                } else {
                    let move=SKAction.move(to:destination,duration:duration); move.timingMode = .easeInEaseOut
                    node.run(move)
                }
            }
            node.zPosition=CGFloat(7-cell.row); cellsByID[gem.id]=cell
            ground(gem,at:cell)
        }
        renderGravityField(phase.field)
        if phase.event == .collision, let index=phase.board.firstIndex(where: { $0?.gravityKind == .hole }) {
            let pulse=SKShapeNode(circleOfRadius:step*0.18); pulse.position=point(Cell(index/7,index%7))
            pulse.strokeColor = StarfallTheme.Gravity.magneticLight; pulse.lineWidth=2; pulse.glowWidth=3
            effects.addChild(pulse)
            pulse.run(.sequence([.group([.scale(to:3,duration:duration),.fadeOut(withDuration:duration)]),.removeFromParent()]))
            let infall = SKShapeNode(ellipseOf: CGSize(width: step * 1.1, height: step * 0.62))
            infall.position = pulse.position
            infall.strokeColor = StarfallTheme.Gravity.orbitLight; infall.lineWidth = 2
            infall.name = "gravity.formation"; effects.addChild(infall)
            infall.run(.sequence([.group([.scale(to: 0.12, duration: duration), .fadeOut(withDuration: duration)]), .removeFromParent()]))
        }
    }
    private func animateGravity(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                                completion: @escaping () -> Void) {
        render(old); rendered=game
        guard view != nil else { render(game); completion(); return }
        if reduceMotion || UIAccessibility.isReduceMotionEnabled || UIAccessibility.isVoiceOverRunning {
            render(game); run(.sequence([.wait(forDuration:0.15),.run(completion)])); return
        }
        var actions: [SKAction]=[]
        for phase in turn.gravityPhases {
            let duration: TimeInterval = phase.event == .rotation ? 0.5 : phase.event == .collision ? 0.32 : 0.20
            actions.append(.run { [weak self] in self?.applyGravityPhase(phase,duration:duration) })
            actions.append(.wait(forDuration:duration))
        }
        if !turn.arrivals.isEmpty {
            let flights=turn.arrivals.enumerated().map { index,arrival in
                SKAction.sequence([.wait(forDuration:Double(index)*0.09),
                    .run { [weak self] in self?.sendStar(arrival) }, .wait(forDuration:StarfallMotion.flightDuration),
                    .run { [weak self] in self?.land(arrival) }])
            }
            actions += [.group(flights),.wait(forDuration:StarfallMotion.landingDuration)]
        }
        actions.append(.run { [weak self] in self?.render(game); completion() })
        run(.sequence(actions))
    }
}
