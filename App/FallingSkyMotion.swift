import SpriteKit
import UIKit
import StarfallCore

/// The parent owns committed cell movement; only this child owns a local contact/look response.
@MainActor final class FallingSkyCharacter: SKNode {
    private(set) var gem: StarfallGem
    let character: SKSpriteNode
    private let smallSize: CGSize
    private static let responseKey = "sky.character-response"

    init(gem: StarfallGem, step: CGFloat) {
        self.gem = gem
        character = JewelScene.makeStarCharacter(gem.kind, expression: gem.grown ? .grown : .idle,
                                                  radius: step * 0.35)
        smallSize = character.size
        super.init()
        name = "sky.star.\(gem.id)"
        addChild(character)
        update(gem, expression: gem.grown ? .grown : .idle)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(_ gem: StarfallGem, expression: StarCast.Expression) {
        self.gem = gem
        character.removeAllActions()
        character.position = .zero; character.zRotation = 0; character.setScale(1)
        let growth: CGFloat = gem.grown ? 0.43 / 0.35 : 1
        character.size = CGSize(width: smallSize.width * growth, height: smallSize.height * growth)
        StarCast.setExpression(expression, for: gem.kind, on: character)
    }

    /// Finite, local response. Replacing it resets the local anchor rather than accumulating kicks.
    func acknowledge(from source: CGPoint, impulse: CGVector, step: CGFloat) {
        character.removeAction(forKey: Self.responseKey)
        character.position = .zero; character.zRotation = 0
        let facing: StarCast.Facing = source.x < position.x ? .left : .right
        let expression: StarCast.Expression = gem.grown ? .grown : .idle
        StarCast.setExpression(.landing, for: gem.kind, on: character, facing: facing)
        let kick = SKAction.move(to: CGPoint(x: impulse.dx * step, y: impulse.dy * step), duration: 0.055)
        kick.timingMode = .easeOut
        let back = SKAction.move(to: .zero, duration: 0.19)
        back.timingMode = .easeInEaseOut
        character.run(.sequence([
            .group([.sequence([kick, back]),
                    .sequence([.rotate(toAngle: impulse.dx * 0.65, duration: 0.055),
                               .rotate(toAngle: 0, duration: 0.19)])]),
            .run { [weak self] in
                guard let self else { return }
                StarCast.setExpression(expression, for: self.gem.kind, on: self.character)
            }
        ]), withKey: Self.responseKey)
    }
}

/// Presentation in cell units; no RNG, rule, save, or clock ownership.
enum StarfallMotion {
    static let flightDuration: TimeInterval = 0.48
    static let contactFraction: CGFloat = 0.80
    static let landingDuration: TimeInterval = 0.34
    static let gatherDuration: TimeInterval = 0.06
    static let gravityStart: TimeInterval = 0.32
    static let clearDuration: TimeInterval = 0.56

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
