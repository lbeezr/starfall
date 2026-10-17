
extension FallingSkyScene {
    func clearConstellationTrace() { constellationTrail.removeAllActions(); constellationTrail.removeAllChildren() }

    func showConstellationTrace(_ path: [Cell], ready: Bool) {
        clearConstellationTrace()
        guard path.count <= 196, !path.isEmpty else { return }
        let route = CGMutablePath()
        route.move(to: point(path[0]))
        for cell in path.dropFirst() { route.addLine(to: point(cell)) }
        let thread = SKShapeNode(path: route)
        thread.name = "lab.trace.thread"
        thread.strokeColor = UIColor(StarfallTheme.Observatory.lanternGlow).withAlphaComponent(ready ? 1 : 0.7)
        thread.lineWidth = ready ? 2.4 : 1.5; thread.glowWidth = reduceMotion ? 0 : 4
        constellationTrail.addChild(thread)
        for (index, cell) in Set(path).sorted(by: { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }).enumerated() {
            let spark = SKShapeNode(circleOfRadius: step * 0.055)
            spark.name = "lab.trace.spark"
            spark.position = point(cell)
            spark.fillColor = UIColor(StarfallTheme.Observatory.lanternGlow); spark.strokeColor = .white
            spark.glowWidth = reduceMotion ? 0 : 3
            constellationTrail.addChild(spark)
            if !reduceMotion {
                spark.run(.repeatForever(.sequence([.wait(forDuration: Double(index%3)*0.05), .fadeAlpha(to: 0.3, duration: 0.2), .fadeAlpha(to: 1, duration: 0.2)])))
            }
        }
        let tip = SKShapeNode(circleOfRadius: step * 0.075)
        tip.name = "lab.trace.tip"; tip.fillColor = .white; tip.strokeColor = .clear
        tip.glowWidth = reduceMotion ? 0 : 5; tip.position = point(path.last!)
        constellationTrail.addChild(tip)
        let lead = SKShapeNode()
        lead.name = "lab.trace.lead"; lead.position = point(path.last!)
        lead.strokeColor = UIColor(StarfallTheme.Observatory.lanternGlow).withAlphaComponent(0.65)
        lead.lineWidth = 1.4; lead.glowWidth = reduceMotion ? 0 : 3
        constellationTrail.addChild(lead)
    }

    func moveConstellationTip(_ location: CGPoint) {
        let current = CGPoint(x: location.x, y: size.height-location.y)
        if let tip = constellationTrail.childNode(withName: "lab.trace.tip") {
            let previous = tip.position
            if !reduceMotion && hypot(current.x-previous.x,current.y-previous.y) >= 3 {
                let motes = constellationTrail.children.filter { $0.name == "lab.trace.mote" }
                if motes.count >= 24 { motes.first?.removeFromParent() }
                let mote = SKShapeNode(circleOfRadius: step*0.025)
                mote.name = "lab.trace.mote"; mote.position = previous
                mote.fillColor = .white; mote.strokeColor = .clear; mote.glowWidth = 2
                constellationTrail.addChild(mote)
                mote.run(.sequence([.group([.fadeOut(withDuration: 0.25),.scale(to:0.1,duration:0.25)]),.removeFromParent()]))
            }
            tip.position = current
        }
        if let lead = constellationTrail.childNode(withName:"lab.trace.lead") as? SKShapeNode {
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
        pulseShape.name="lab.trace.release-shape";pulseShape.strokeColor = .white
        pulseShape.lineWidth=2.8;pulseShape.glowWidth=6;pulseShape.alpha=0.8
        effects.addChild(pulseShape)
        pulseShape.run(.sequence([.fadeAlpha(to:1,duration:0.06),.wait(forDuration:0.08),.fadeOut(withDuration:0.2),.removeFromParent()]))
        for cell in Set(path) {
            let center = point(cell)
            let pulse = SKShapeNode(circleOfRadius: step*0.15)
            pulse.position = center; pulse.strokeColor = UIColor(StarfallTheme.Observatory.lanternGlow)
            pulse.lineWidth = 2; pulse.glowWidth = 3
            effects.addChild(pulse)
            pulse.run(.sequence([.wait(forDuration:0.06),.group([.scale(to: 3, duration: 0.25), .fadeOut(withDuration: 0.3)]), .removeFromParent()]))
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
