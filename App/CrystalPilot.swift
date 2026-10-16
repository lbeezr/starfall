import SpriteKit
import UIKit

/// Offline-rendered original geometry; no runtime 3D or dynamic background refraction.
@MainActor enum CrystalPilot {
    static func isEnabled(arguments: [String]) -> Bool {
        #if DEBUG
        return arguments.contains("--crystal-pilot")
        #else
        return false
        #endif
    }
    static let neutralIndex = 4
    static let maximumShards = 48
    // Neutral alpha bounds are [34,222) in the approved 256-pixel source.
    static func canvasSide(radius: CGFloat) -> CGFloat { radius * 2 * 256 / 188 }
    static let frames: [SKTexture] = {
        guard let image = UIImage(named: "CrystalPilot")?.cgImage,
              image.width == 2304, image.height == 256 else { return [] }
        return (0..<9).compactMap { index in
            guard let frame = image.cropping(to: CGRect(x: CGFloat(index * 256), y: 0, width: 256, height: 256)) else { return nil }
            let texture = SKTexture(cgImage: frame)
            texture.filteringMode = .linear
            return texture
        }
    }()
    // Independent crops prevent filtering into the adjacent atlas frame.
    static let shards: [SKTexture] = {
        guard let image = UIImage(named: "CrystalPilot")?.cgImage else { return [] }
        return (0..<4).compactMap { index in
            let rect = CGRect(x: CGFloat(neutralIndex * 256 + (index % 2) * 128),
                              y: CGFloat((index / 2) * 128), width: 128, height: 128)
            guard let piece = image.cropping(to: rect) else { return nil }
            let texture = SKTexture(cgImage: piece)
            texture.filteringMode = .linear
            return texture
        }
    }()
    static func tiltAction() -> SKAction {
        .animate(with: [4, 3, 2, 1].map { frames[$0] }, timePerFrame: 0.015,
                 resize: false, restore: false)
    }
}
