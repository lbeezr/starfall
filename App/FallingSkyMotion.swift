import SpriteKit
import UIKit
import StarfallCore

/// The parent owns committed cell movement; only this child owns a local contact/look response.
@MainActor final class FallingSkyCharacter: SKNode {
    private(set) var gem: StarfallGem
    let character: SKSpriteNode
    private let smallSize: CGSize
    private let growthCue = SKNode()
    private var growthMotionEnabled = false
    private static let growthPulseKey = "sky.growth-pulse"
    private static let responseKey = "sky.character-response"

    init(gem: StarfallGem, step: CGFloat) {
        self.gem = gem
        character = JewelScene.makeStarCharacter(.init(gem), expression: gem.grown ? .grown : .idle,
                                                  radius: step * 0.35)
        smallSize = character.size
        super.init()
        name = "sky.star.\(gem.id)"
        addChild(character)
        makeGrowthCue(identity: .init(gem), step: step)
        update(gem, expression: gem.grown ? .grown : .idle)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(_ gem: StarfallGem, expression: StarCast.Expression) {
        self.gem = gem
        character.removeAllActions()
        character.position = .zero; character.zRotation = 0; character.setScale(1)
        character.warpGeometry = nil
        let growth = Self.bodyScale(for: gem)
        character.size = CGSize(width: smallSize.width * growth, height: smallSize.height * growth)
        showExpression(expression)
        growthCue.isHidden = gem.value != 2
        refreshGrowthMotion()
    }

    static func bodyScale(for gem: StarfallGem) -> CGFloat {
        gem.massStage >= 3 ? 1.34 : gem.grown ? 0.43 / 0.35 : gem.massStage == 2 ? 1.10 : 1
    }

    func setDrainDecoration(_ drained: Bool) {
        growthCue.alpha = drained ? 0.16 : 1
    }

    /// Cached body alpha supplies the exact family silhouette. No extra materials. Only the outer aura may animate.
    /// Attached to the character so contact responses and landing transforms carry the cue too.
    private func makeGrowthCue(identity: StarCast.Identity, step: CGFloat) {
        growthCue.name = "sky.growth-cue"
        character.addChild(growthCue)
        let side = smallSize.width * 0.43 / 0.35
        for (index, scale) in [CGFloat(1.22), 1.10].enumerated() {
            let echo = SKSpriteNode(texture: StarCast.texture(for: identity, expression: .idle))
            echo.name = index == 0 ? "sky.growth-aura" : "sky.growth-rim"
            echo.size = CGSize(width: side * scale, height: side * scale)
            echo.color = StarfallTheme.GrownStar.light; echo.colorBlendFactor = 1
            echo.alpha = index == 0 ? StarfallTheme.GrownStar.auraAlpha : StarfallTheme.GrownStar.rimAlpha
            echo.position = CGPoint(x: -step * 0.025, y: step * 0.035)
            echo.zPosition = CGFloat(index - 2)
            growthCue.addChild(echo)
        }
        // Two fixed diamond glints read as a double-value cue without color or motion alone.
        for (index, offset) in [CGPoint(x: -0.29, y: 0.32), CGPoint(x: 0.28, y: 0.25)].enumerated() {
            let radius = step * (index == 0 ? 0.085 : 0.06)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: radius))
            path.addLine(to: CGPoint(x: radius * 0.4, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -radius))
            path.addLine(to: CGPoint(x: -radius * 0.4, y: 0))
            path.closeSubpath()
            let glint = SKShapeNode(path: path)
            glint.name = "sky.growth-glint"
            glint.position = CGPoint(x: offset.x * step, y: offset.y * step)
            glint.fillColor = StarfallTheme.GrownStar.light
            glint.strokeColor = .white; glint.lineWidth = 0.5
            glint.zPosition = 1
            growthCue.addChild(glint)
        }
    }

    func setGrowthMotion(_ enabled: Bool) {
        growthMotionEnabled = enabled
        refreshGrowthMotion()
    }

    private func refreshGrowthMotion() {
        guard let aura = growthCue.childNode(withName: "sky.growth-aura") else { return }
        guard growthMotionEnabled, !growthCue.isHidden else {
            aura.removeAction(forKey: Self.growthPulseKey)
            aura.alpha = StarfallTheme.GrownStar.auraAlpha
            return
        }
        guard aura.action(forKey: Self.growthPulseKey) == nil else { return }
        // Absolute presentation phase survives scene rebuilds; ID offsets avoid synchronized flashing.
        // Read time once when configuring, never in the per-frame callback or in Core.
        let period = StarfallTheme.GrownStar.pulsePeriod
        let phase = (ProcessInfo.processInfo.systemUptime + Double(gem.id % 7) * 0.23)
            .truncatingRemainder(dividingBy: period)
        aura.alpha = StarfallTheme.GrownStar.auraAlpha + StarfallTheme.GrownStar.pulseAmplitude
            * CGFloat(sin(phase * 2 * .pi / period))
        let pulse = SKAction.customAction(withDuration: period) { node, elapsed in
            node.alpha = StarfallTheme.GrownStar.auraAlpha + StarfallTheme.GrownStar.pulseAmplitude
                * CGFloat(sin((phase + Double(elapsed)) * 2 * .pi / period))
        }
        aura.run(.repeatForever(pulse), withKey: Self.growthPulseKey)
    }

    /// A face change preserves the in-flight/contact deformation owned by this child.
    func showExpression(_ expression: StarCast.Expression, facing: StarCast.Facing = .front) {
        StarCast.setExpression(expression, for: .init(gem), on: character, facing: facing)
    }

    func softenLanding() {
        guard gem.isLight else { return }
        character.removeAction(forKey: Self.responseKey)
        character.warpGeometry = OpalMotion.squashed
        character.run(OpalMotion.rebound(), withKey: Self.responseKey)
    }

    /// Finite, local response. Replacing it resets the local anchor rather than accumulating kicks.
    func acknowledge(from source: CGPoint, impulse: CGVector, step: CGFloat) {
        guard gem.gravityKind != .magnet else { return }
        character.removeAction(forKey: Self.responseKey)
        character.position = .zero; character.zRotation = 0
        character.warpGeometry = gem.isLight ? OpalMotion.round : nil
        let facing: StarCast.Facing = source.x < position.x ? .left : .right
        let expression: StarCast.Expression = gem.grown ? .grown : .idle
        showExpression(.landing, facing: facing)
        let kick = SKAction.move(to: CGPoint(x: impulse.dx * step, y: impulse.dy * step), duration: 0.055)
        kick.timingMode = .easeOut
        let back = SKAction.move(to: .zero, duration: 0.19)
        back.timingMode = .easeInEaseOut
        let softness: SKAction = gem.isLight ? OpalMotion.contact() : .wait(forDuration: 0)
        character.run(.sequence([
            .group([softness, .sequence([kick, back]),
                    .sequence([.rotate(toAngle: impulse.dx * 0.65, duration: 0.055),
                               .rotate(toAngle: 0, duration: 0.19)])]),
            .run { [weak self] in
                guard let self else { return }
                self.showExpression(expression)
            }
        ]), withKey: Self.responseKey)
    }
}

/// Presentation in cell units; no RNG, rule, save, or clock ownership.
enum StarfallMotion {
    static let arrivalStagger: TimeInterval = 0.09
    static let flightDuration: TimeInterval = 0.48
    static let contactFraction: CGFloat = 0.80
    static let receiverResponseDelay: TimeInterval = 0.38
    static let landingDuration: TimeInterval = 0.34
    static let gatherDuration: TimeInterval = 0.06
    static let gravityStart: TimeInterval = 0.32
    static let clearDuration: TimeInterval = 0.56
    static let exchangeSlideDuration: TimeInterval = 0.14

    /// Only the airborne approach overlaps. A small clearance keeps first
    /// response after every preceding committed gravity phase has settled.
    struct PhaseTimeline {
        let phaseDurations: [TimeInterval]
        let phaseEnd: TimeInterval
        let flightStart: TimeInterval
        let completion: TimeInterval

        init(phases: [SkyPresentationPhase.Event], arrivals: Int) {
            precondition(arrivals >= 0 && arrivals <= FallingSky.maximumShowerSize)
            phaseDurations = phases.map { event -> TimeInterval in
                switch event {
                case .rotation: return 0.5
                case .collision: return 0.32
                default: return 0.20
                }
            }
            phaseEnd = phaseDurations.reduce(0, +)
            guard arrivals > 0 else {
                flightStart = phaseEnd; completion = phaseEnd; return
            }
            let landingClearance: TimeInterval = 0.04
            flightStart = max(0, phaseEnd + landingClearance - StarfallMotion.receiverResponseDelay)
            let lastLanding = flightStart + StarfallMotion.flightDuration
                + Double(arrivals - 1) * StarfallMotion.arrivalStagger
            completion = max(phaseEnd, lastLanding) + StarfallMotion.landingDuration
        }
    }

    /// Compatibility spelling for historical timing fixtures.
    typealias GravityTimeline = PhaseTimeline

    static func drift(for id: Int, column: Int) -> CGFloat {
        let direction: CGFloat = column == 0 ? 1 : column == 6 ? -1 : id.isMultiple(of: 2) ? 1 : -1
        return direction * (id.isMultiple(of: 3) ? 1.5 : 0.85)
    }
    static func rebound(dark: Bool, grew: Bool) -> CGFloat { dark ? 0.045 : grew ? 0.09 : 0.18 }
    static func resistance(_ gem: StarfallGem) -> CGFloat { gem.isDark ? 0.30 : gem.grown ? 0.55 : 1 }
    static func ripple(distance: CGFloat, collected: Int, heavy: Bool) -> CGFloat {
        guard distance > 0, distance < 3 else { return 0 }
        return (collected >= 5 ? 0.21 : 0.12) * (1 - distance / 3) * (heavy ? 0.55 : 1)
    }

    struct Flight {
        let start: CGPoint
        let destination: CGPoint
        let contact: CGPoint?
        let step: CGFloat

        /// An accelerated approach followed by a short, decaying deflection. Absolute, not integrated.
        func point(at progress: CGFloat) -> CGPoint {
            let t = min(1, max(0, progress))
            guard let contact else { return mix(start, destination, t * t) }
            if t <= contactFraction { return mix(start, contact, pow(t / contactFraction, 2)) }
            let u = (t - contactFraction) / (1 - contactFraction)
            let point = mix(contact, destination, u)
            return CGPoint(x: point.x, y: point.y + sin(u * .pi) * step * 0.13)
        }
        private func mix(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x-a.x)*t, y: a.y + (b.y-a.y)*t)
        }
    }
}

/// Five cached, bounded meshes deform only Opal's artwork. They never move a
/// committed cell, change a touch target, or select a rule/clock outcome.
@MainActor enum OpalMotion {
    private static let source: [SIMD2<Float>] = (0..<12).map {
        SIMD2(Float($0 % 3) / 2, Float($0 / 3) / 3)
    }
    private static func mesh(widths: [Float], heights: [Float]) -> SKWarpGeometryGrid {
        let destination = source.enumerated().map { index, point in
            SIMD2<Float>(0.5 + (point.x - 0.5) * widths[index / 3], heights[index / 3])
        }
        return SKWarpGeometryGrid(columns: 2, rows: 3, sourcePositions: source, destinationPositions: destination)
    }
    static let round = mesh(widths: [1, 1, 1, 1], heights: [0, Float(1)/3, Float(2)/3, 1])
    // A full lower body and narrower upper shoulder give the falling orb a soft tail.
    static let falling = mesh(widths: [0.88, 1.00, 0.78, 0.24], heights: [-0.03, 0.28, 0.70, 1.23])
    static let squashed = mesh(widths: [1.02, 1.24, 1.14, 0.92], heights: [0.10, 0.32, 0.54, 0.76])
    private static let stretched = mesh(widths: [0.94, 0.88, 0.94, 1], heights: [-0.02, 0.33, 0.72, 1.08])
    private static let settling = mesh(widths: [1, 1.06, 1.04, 1], heights: [0.02, 0.34, 0.66, 0.96])

    static func prewarm() { _ = [round, falling, squashed, stretched, settling] }

    static func rebound() -> SKAction {
        // Matching grid topology makes these actions valid; no fallback hides a bad mesh.
        .sequence([SKAction.warp(to: stretched, duration: 0.09)!,
                   SKAction.warp(to: settling, duration: 0.10)!,
                   SKAction.warp(to: round, duration: 0.13)!])
    }
    static func contact() -> SKAction {
        .sequence([SKAction.warp(to: squashed, duration: 0.055)!,
                   SKAction.warp(to: round, duration: 0.19)!])
    }
}


/// Finite child-art responses; Core positions and native hit cells remain fixed.
@MainActor enum GravityMotion {
    static func attraction(direction: CGFloat, step: CGFloat, duration: TimeInterval) -> SKAction {
        let lean = SKAction.moveBy(x: direction * step * 0.08, y: 0, duration: duration * 0.35)
        lean.timingMode = .easeIn
        return .sequence([lean, .move(to: .zero, duration: duration * 0.65)])
    }
    static func ringResponse(duration: TimeInterval) -> SKAction {
        .sequence([.rotate(toAngle: -.pi / 10, duration: duration * 0.5),
                   .rotate(toAngle: 0, duration: duration * 0.5)])
    }
}
