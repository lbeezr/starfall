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
    private var pieceMotionEnabled = true
    private static let growthPulseKey = "sky.growth-pulse"

    init(gem: StarfallGem, step: CGFloat) {
        self.gem = gem
        character = SkyPiece.makeNode(for: .init(gem), radius: step * StarfallMotion.pieceRadius)
        smallSize = character.size
        super.init()
        name = "sky.star.\(gem.id)"
        addChild(character)
        makeGrowthCue(identity: .init(gem))
        update(gem, expression: gem.grown ? .grown : .idle)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(_ gem: StarfallGem, expression: StarCast.Expression) {
        self.gem = gem
        character.removeAllActions()
        cancelLocalMotion()
        let growth = Self.bodyScale(for: gem)
        character.size = CGSize(width: smallSize.width * growth, height: smallSize.height * growth)
        showExpression(expression)
        growthCue.isHidden = gem.value != 2
        if let aura = growthCue.children.first as? SKSpriteNode {
            aura.color = StarCast.Identity(gem).color
            aura.size = CGSize(width: character.size.width * 1.28, height: character.size.height * 1.28)
        }
        refreshGrowthMotion()
    }

    static func bodyScale(for gem: StarfallGem) -> CGFloat {
        // massStage also includes the raw grown flag. Aging and collected value
        // need separate gates so a special role cannot inherit a double-value size.
        let age = !gem.isDark && gem.gravityKind == nil ? gem.stellarAge : 0
        if age >= CriticalMassRule.showersPerStage * 2 { return 1.34 }
        if gem.value == 2 { return StarfallMotion.grownPieceRadius / StarfallMotion.pieceRadius }
        return age >= CriticalMassRule.showersPerStage ? 1.10 : 1
    }

    func setDrainDecoration(_ drained: Bool) {
        growthCue.alpha = drained ? 0.16 : 1
    }

    /// One cached soft light field, never a second copy of the piece or a value badge.
    /// It follows the child artwork's finite bank/contact pose around the same pivot.
    private func makeGrowthCue(identity: StarCast.Identity) {
        growthCue.name = "sky.growth-cue"
        character.addChild(growthCue)
        let aura = SKSpriteNode(texture: SkyPieceMotion.auraTexture)
        aura.name = "sky.growth-aura"
        aura.color = identity.color; aura.colorBlendFactor = 1
        aura.alpha = StarfallTheme.GrownStar.auraAlpha
        // Piece roots occupy z=1...7; every aura stays behind every opaque body.
        aura.blendMode = .add; aura.zPosition = -8
        growthCue.addChild(aura)
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

    /// Existing presentation callers may request expressions; gameplay pieces stay faceless.
    /// A committed material refresh preserves the in-flight/contact deformation.
    func showExpression(_ expression: StarCast.Expression, facing: StarCast.Facing = .front) {
        SkyPiece.setMaterial(for: .init(gem), on: character)
    }

    func setPieceMotion(_ enabled: Bool) {
        pieceMotionEnabled = enabled
        if !enabled { cancelLocalMotion() }
    }

    func cancelLocalMotion() {
        SkyPieceMotion.reset(character)
    }

    func land(direction: CGFloat, step: CGFloat) {
        guard pieceMotionEnabled else { return }
        SkyPieceMotion.land(character, identity: .init(gem), direction: direction,
                            step: step, grown: gem.grown)
    }

    /// Retained for focused Opal presentation tooling.
    func softenLanding() {
        guard pieceMotionEnabled, gem.isLight else { return }
        cancelLocalMotion()
        character.warpGeometry = OpalMotion.squashed
        character.run(OpalMotion.rebound(), withKey: SkyPieceMotion.responseKey)
    }

    /// Finite, local response. Replacing it resets the local anchor rather than accumulating kicks.
    func acknowledge(from source: CGPoint, impulse: CGVector, step: CGFloat) {
        guard pieceMotionEnabled, gem.gravityKind == nil else { return }
        SkyPieceMotion.respond(character, identity: .init(gem), direction: source.x < position.x ? -1 : 1,
                               impulse: impulse, step: step)
    }
}

/// Presentation in cell units; no RNG, rule, save, or clock ownership.
enum StarfallMotion {
    static let pieceRadius: CGFloat = 0.35
    // About .90 cell-step visible extent: 1.314× the normal body, without overlapping neighbors.
    // Literal 2× at the current normal size would occupy about 1.38 cells.
    static let grownPieceRadius: CGFloat = 0.46
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

/// Shallow yaw/pitch use prewarmed perspective meshes, not a simulated 3D body.
/// All responses are finite child-art actions; the scene keeps committed cell movement.
@MainActor enum SkyPieceMotion {
    static let responseKey = "sky.character-response"
    static let flightKey = "sky.piece-flight"

    struct Profile: Equatable {
        let flightRoll: CGFloat
        let yaw: CGFloat
        let pitch: CGFloat
        let impactWidth: CGFloat
        let impactHeight: CGFloat
        let rebound: CGFloat
        let response: CGFloat
    }

    static func profile(for identity: StarCast.Identity) -> Profile {
        switch identity {
        case .colored(.aqua):
            .init(flightRoll: 0.40, yaw: 0.42, pitch: 0.24, impactWidth: 1.10, impactHeight: 0.84, rebound: 0.14, response: 0.95)
        case .colored(.amber):
            .init(flightRoll: 0.16, yaw: 0.30, pitch: 0.44, impactWidth: 1.09, impactHeight: 0.89, rebound: 0.065, response: 0.52)
        case .colored(.mint):
            .init(flightRoll: 0.28, yaw: 0.48, pitch: 0.26, impactWidth: 1.04, impactHeight: 0.94, rebound: 0.035, response: 0.70)
        case .colored(.rose):
            .init(flightRoll: 0.22, yaw: 0.22, pitch: 0.30, impactWidth: 1.04, impactHeight: 0.88, rebound: 0.12, response: 1)
        case .colored(.violet):
            .init(flightRoll: 0.12, yaw: 0.32, pitch: 0.14, impactWidth: 1.05, impactHeight: 0.94, rebound: 0.05, response: 0.65)
        case .dusk:
            .init(flightRoll: -0.20, yaw: -0.36, pitch: 0.20, impactWidth: 1.03, impactHeight: 0.92, rebound: 0.04, response: 0.45)
        case .opal:
            .init(flightRoll: 0.07, yaw: 0, pitch: 0, impactWidth: 1, impactHeight: 1, rebound: 0.12, response: 1)
        case .magnet, .hole:
            .init(flightRoll: 0, yaw: 0, pitch: 0, impactWidth: 1, impactHeight: 1, rebound: 0, response: 0)
        }
    }

    private static let source: [SIMD2<Float>] = [
        SIMD2(0, 0), SIMD2(1, 0), SIMD2(0, 1), SIMD2(1, 1)
    ]

    /// Pure corner projection is also the testable bound on the shallow 2.5D pose.
    static func perspectiveVertices(yaw: CGFloat, pitch: CGFloat) -> [SIMD2<Float>] {
        source.map { point in
            let x = CGFloat(point.x) - 0.5, y = CGFloat(point.y) - 0.5
            let depth = x * sin(yaw) + y * sin(pitch)
            let perspective = 1 / (1 + depth * 0.55)
            return SIMD2(Float(0.5 + x * cos(yaw) * perspective),
                         Float(0.5 + y * cos(pitch) * perspective))
        }
    }

    private static func mesh(yaw: CGFloat, pitch: CGFloat) -> SKWarpGeometryGrid {
        SKWarpGeometryGrid(columns: 1, rows: 1, sourcePositions: source,
                           destinationPositions: perspectiveVertices(yaw: yaw, pitch: pitch))
    }

    private struct Poses {
        let left: SKWarpGeometryGrid
        let right: SKWarpGeometryGrid
        let impact: SKWarpGeometryGrid
        let responseLeft: SKWarpGeometryGrid
        let responseRight: SKWarpGeometryGrid
    }
    private static let round = mesh(yaw: 0, pitch: 0)
    private static var poses: [StarCast.Identity: Poses] = [:]

    private static func poses(for identity: StarCast.Identity) -> Poses {
        if let cached = poses[identity] { return cached }
        let profile = profile(for: identity)
        let value = Poses(
            left: mesh(yaw: -profile.yaw, pitch: profile.pitch),
            right: mesh(yaw: profile.yaw, pitch: profile.pitch),
            impact: mesh(yaw: 0, pitch: -profile.pitch * 0.7),
            responseLeft: mesh(yaw: -profile.yaw * 0.5, pitch: profile.pitch * 0.3),
            responseRight: mesh(yaw: profile.yaw * 0.5, pitch: profile.pitch * 0.3))
        poses[identity] = value
        return value
    }

    /// One 128px alpha field shared by every family; no art duplication, IO or drawing per frame.
    static let auraTexture: SKTexture = {
        let side: CGFloat = 128
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1; format.opaque = false; format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0.50).cgColor,
                          UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                      locations: [0, 0.45, 1])!
            context.cgContext.drawRadialGradient(gradient, startCenter: CGPoint(x: side / 2, y: side / 2),
                startRadius: 0, endCenter: CGPoint(x: side / 2, y: side / 2), endRadius: side / 2, options: [])
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear; texture.usesMipmaps = false
        return texture
    }()

    static func prewarm() {
        _ = auraTexture
        for identity in StarCast.Identity.allCases { _ = poses(for: identity) }
        OpalMotion.prewarm()
    }

    static func reset(_ node: SKSpriteNode) {
        node.removeAction(forKey: responseKey); node.removeAction(forKey: flightKey)
        restorePose(node)
    }

    private static func restorePose(_ node: SKSpriteNode) {
        node.position = .zero; node.zRotation = 0; node.setScale(1); node.warpGeometry = nil
    }

    static func prepareFlight(_ node: SKSpriteNode, identity: StarCast.Identity, direction: CGFloat) {
        reset(node)
        guard identity != .magnet && identity != .hole else { return }
        let profile = profile(for: identity), poses = poses(for: identity)
        let roll = profile.flightRoll * direction
        node.subdivisionLevels = 2
        node.zRotation = -roll
        node.warpGeometry = identity == .opal ? OpalMotion.falling : direction < 0 ? poses.left : poses.right
        let shape: SKAction = identity == .opal ? .wait(forDuration: StarfallMotion.flightDuration)
            : .sequence([.warp(to: direction < 0 ? poses.right : poses.left, duration: 0.28)!,
                         .warp(to: round, duration: 0.20)!])
        node.run(.sequence([.group([shape, .sequence([
            .rotate(toAngle: roll * 0.35, duration: 0.29),
            .rotate(toAngle: 0, duration: 0.19)
        ])]), .run { [weak node] in if let node { restorePose(node) } }]), withKey: flightKey)
    }

    static func land(_ node: SKSpriteNode, identity: StarCast.Identity, direction: CGFloat,
                     step: CGFloat, grown: Bool) {
        reset(node)
        guard identity != .magnet && identity != .hole else { return }
        let profile = profile(for: identity), poses = poses(for: identity)
        node.subdivisionLevels = 2
        node.warpGeometry = identity == .opal ? OpalMotion.squashed : poses.impact
        node.xScale = profile.impactWidth; node.yScale = profile.impactHeight
        node.zRotation = profile.flightRoll * direction * 0.28
        let rebound = profile.rebound * (grown ? 0.55 : 1) * step
        let rise = SKAction.move(to: CGPoint(x: direction * rebound * 0.24, y: rebound), duration: 0.10)
        rise.timingMode = .easeOut
        let settle = SKAction.move(to: .zero, duration: 0.18); settle.timingMode = .easeInEaseOut
        let shape: SKAction = identity == .opal ? OpalMotion.rebound() : .warp(to: round, duration: 0.28)!
        let scale: SKAction = identity == .opal ? .wait(forDuration: 0)
            : .sequence([.scaleX(to: 0.98, y: 1.03, duration: 0.10), .scaleX(to: 1, y: 1, duration: 0.18)])
        node.run(.sequence([.group([
            shape, .sequence([rise, settle]),
            scale,
            .sequence([.rotate(toAngle: -node.zRotation * 0.5, duration: 0.11), .rotate(toAngle: 0, duration: 0.17)])
        ]), .run { [weak node] in if let node { restorePose(node) } }]), withKey: responseKey)
    }

    static func respond(_ node: SKSpriteNode, identity: StarCast.Identity, direction: CGFloat,
                        impulse: CGVector, step: CGFloat) {
        reset(node)
        let profile = profile(for: identity), poses = poses(for: identity)
        node.subdivisionLevels = 2
        node.warpGeometry = identity == .opal ? OpalMotion.round : round
        let kick = SKAction.move(to: CGPoint(x: impulse.dx * step * profile.response,
                                             y: impulse.dy * step * profile.response), duration: 0.055)
        kick.timingMode = .easeOut
        let back = SKAction.move(to: .zero, duration: 0.19); back.timingMode = .easeInEaseOut
        let shape: SKAction = identity == .opal ? OpalMotion.contact() : .sequence([
            .warp(to: direction < 0 ? poses.responseLeft : poses.responseRight, duration: 0.055)!,
            .warp(to: round, duration: 0.19)!
        ])
        let angle = (profile.flightRoll * direction * 0.25 + impulse.dx * 0.65) * profile.response
        node.run(.sequence([.group([shape, .sequence([kick, back]),
            .sequence([.rotate(toAngle: angle, duration: 0.055), .rotate(toAngle: 0, duration: 0.19)])
        ]), .run { [weak node] in if let node { restorePose(node) } }]), withKey: responseKey)
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
