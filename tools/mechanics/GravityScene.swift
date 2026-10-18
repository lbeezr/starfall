// Appended to the scene owner in the isolated export. All motion presents Core phases.
extension FallingSkyScene {
    private func renderGravityField(_ field: OrbitField?) {
        grid.children.filter { $0.name == "gravity.field" }.forEach { $0.removeFromParent() }
        guard let field else { return }
        let root = SKNode(); root.name = "gravity.field"
        let center = point(field.center)
        for cell in field.slots {
            let path = CGMutablePath(); path.move(to:center); path.addLine(to:point(cell))
            let line = SKShapeNode(path:path.copy(dashingWithPhase:0,lengths:[3,4]))
            line.strokeColor = UIColor(StarfallTheme.Colors.actionPrimary).withAlphaComponent(0.65); line.lineWidth = 1.5
            root.addChild(line)
        }
        for index in 0..<field.windowsRemaining {
            let dot=SKShapeNode(circleOfRadius:step*0.035)
            dot.fillColor = .white; dot.strokeColor = .clear
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
            pulse.strokeColor = UIColor(StarfallTheme.Colors.actionPrimary); pulse.lineWidth=2; pulse.glowWidth=3
            effects.addChild(pulse)
            pulse.run(.sequence([.group([.scale(to:3,duration:duration),.fadeOut(withDuration:duration)]),.removeFromParent()]))
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

@MainActor private enum GravityMaterial {
    static func node(_ role: GravityKind, radius: CGFloat) -> SKNode {
        let root=SKNode()
        let body=SKShapeNode(circleOfRadius:radius*(role == .hole ? 0.95 : 0.72))
        body.fillColor = role == .hole ? StarfallTheme.Observatory.contactShadow : StarfallTheme.Observatory.softContactShadow
        body.strokeColor = UIColor(StarfallTheme.Colors.actionPrimary); body.lineWidth=radius*0.10
        root.addChild(body)
        let glyph=SKLabelNode(text:role == .hole ? "↻" : "↔")
        glyph.fontName="AvenirNext-Bold"; glyph.fontSize=radius*1.4
        glyph.verticalAlignmentMode = .center; glyph.fontColor = .white
        root.addChild(glyph)
        return root
    }
    static func decorate(_ node: FallingSkyCharacter, gem: StarfallGem, step: CGFloat) {
        guard let role=gem.gravityKind else { return }
        node.character.isHidden=true
        node.addChild(Self.node(role,radius:step*0.35))
    }
}
