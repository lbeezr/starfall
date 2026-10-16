import SpriteKit
import UIKit
import StarfallCore

/// Bounded SpriteKit refill presentation. Called after the existing 200 ms clear.
/// Receives final-shape nodes from JewelScene's material factory; never draws jewels.
/// All coordinates use the same parent space as those nodes and `boardBounds`.
@MainActor final class StarfallArrivalEffects {
    static let refillDuration: TimeInterval = 0.28 // 0.20 clear + 0.28 refill = 0.48 total.
    static let maximumTrails = Game.side
    private static let actionKey = "starfall.arrival"
    private struct Placement {
        let node: SKNode
        let destination: CGPoint
    }
    private var placements: [Placement] = []
    private var trails: [SKNode] = []
    private var clock: SKNode?
    private var completion: (() -> Void)?
    private var generation: UInt64 = 0

    /// Drops the completion and settles every tracked node. Safe to call repeatedly.
    /// Call before render/restart/resize, removal from the scene, or a motion-setting change.
    func cancel() {
        generation &+= 1
        clock?.removeAllActions()
        clock?.removeFromParent()
        clock = nil
        for placement in placements {
            placement.node.removeAction(forKey: Self.actionKey)
            placement.node.position = placement.destination
            placement.node.alpha = 1
        }
        for trail in trails {
            trail.removeAllActions()
            trail.removeFromParent()
        }
        placements.removeAll()
        trails.removeAll()
        completion = nil
    }

    /// Nodes must already show `mapping.pieces`' final jewel kinds, keyed by destination.
    /// This schedules only the refill phase; it never unlocks input or changes GameStore.
    func play(mapping: RefillMapping, nodes: [Cell: SKNode], boardBounds: CGRect,
              step: CGFloat, in effectParent: SKNode, calmEffects: Bool,
              reduceMotion: Bool, point: (Cell) -> CGPoint,
              completion: @escaping () -> Void) {
        cancel()
        let token = generation
        self.completion = completion
        for piece in mapping.pieces {
            guard let node = nodes[piece.destination] else { continue }
            let destination = point(piece.destination)
            node.position = destination
            node.alpha = 1
            placements.append(Placement(node: node, destination: destination))
        }
        // Settled, synchronous alternative: no trails, motion or pending completion.
        guard !calmEffects, !reduceMotion, !UIAccessibility.isReduceMotionEnabled,
              !UIAccessibility.isVoiceOverRunning, effectParent.scene?.view != nil,
              step.isFinite, step > 0, boardBounds.origin.x.isFinite, boardBounds.origin.y.isFinite,
              boardBounds.width.isFinite, boardBounds.height.isFinite,
              !boardBounds.isEmpty, !boardBounds.isInfinite, !boardBounds.isNull else {
            finish(token: token)
            return
        }

        let clock = SKNode()
        effectParent.addChild(clock)
        self.clock = clock
        var arrivalIndex = 0
        var trailColumns: Set<Int> = []
        for piece in mapping.pieces {
            guard let node = nodes[piece.destination] else { continue }
            let destination = point(piece.destination)
            switch piece.origin {
            case let .survivor(source):
                // Never send a survivor diagonally, including unchanged pieces.
                guard source != piece.destination else { continue }
                node.position = CGPoint(x: destination.x, y: point(source).y)
                let move = SKAction.move(to: destination, duration: 0.08)
                move.timingMode = .easeOut
                node.run(move, withKey: Self.actionKey)
            case .recovery:
                // Recovery can replace an otherwise surviving bottom-row piece.
                // Reveal the final replacement in place; do not invent a source identity.
                node.alpha = 0
                node.run(.sequence([.wait(forDuration: 0.08), .fadeIn(withDuration: 0.08)]),
                         withKey: Self.actionKey)
            case .refill:
                // Parallel down-left paths start just beyond the nearest top/right edge.
                // The existing clipped SpriteView cannot show the off-board sky segment.
                let distance = max(0, min(boardBounds.maxX - destination.x,
                                          boardBounds.maxY - destination.y)) + step * 0.65
                node.position = CGPoint(x: destination.x + distance, y: destination.y + distance)
                node.alpha = 0
                let delay = 0.08 + Double(arrivalIndex % 4) * 0.008
                arrivalIndex += 1
                let move = SKAction.move(to: destination, duration: 0.15)
                move.timingMode = .easeOut
                node.run(.sequence([.wait(forDuration: delay), .fadeIn(withDuration: 0), move]),
                         withKey: Self.actionKey)
                // One short stroke per affected column, at most seven for the whole turn.
                if trails.count < Self.maximumTrails,
                   trailColumns.insert(piece.destination.column).inserted {
                    let path = CGMutablePath()
                    path.move(to: .zero)
                    path.addLine(to: CGPoint(x: step * 0.34, y: step * 0.34))
                    let trail = SKShapeNode(path: path)
                    trail.strokeColor = UIColor.white.withAlphaComponent(0.18)
                    trail.lineWidth = max(1, step * 0.035)
                    trail.lineCap = .round
                    trail.zPosition = -1
                    node.addChild(trail)
                    trails.append(trail)
                    trail.run(.sequence([.wait(forDuration: delay + 0.11),
                                         .fadeOut(withDuration: 0.04), .removeFromParent()]))
                }
            }
        }
        // Latest arrival ends at 254 ms, leaving 26 ms settled before the 280 ms finish.
        clock.run(.sequence([.wait(forDuration: Self.refillDuration), .run { [weak self] in
            self?.finish(token: token)
        }]))
    }

    private func finish(token: UInt64) {
        guard generation == token else { return }
        let callback = completion
        cancel()
        callback?()
    }
}
