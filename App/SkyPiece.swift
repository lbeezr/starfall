import UIKit
import SpriteKit
import StarfallCore

/// Faceless gameplay materials shared by the forecast, flight and settled board.
/// Story characters remain in StarCast; committed identities and saves are unchanged.
@MainActor enum SkyPiece {
    // Keep the shared centered-canvas sizing contract; packaged shard bodies span at most 208px.
    static let rasterSide = StarCast.rasterSide
    static let silhouetteSide = StarCast.silhouetteSide
    static let maximumMaterials = StarCast.Identity.allCases.count
    static let maximumRasterBytes = maximumMaterials * rasterSide * rasterSide * 4

    private struct Material {
        let image: UIImage
        let texture: SKTexture
    }
    private static var materials: [StarCast.Identity: Material] = [:]
    static var cachedMaterialCount: Int { materials.count }

    static func image(for identity: StarCast.Identity) -> UIImage {
        material(for: identity).image
    }

    static func texture(for identity: StarCast.Identity) -> SKTexture {
        material(for: identity).texture
    }

    static func prewarm() {
        for identity in StarCast.Identity.allCases { _ = material(for: identity) }
    }

    static func makeNode(for identity: StarCast.Identity, radius: CGFloat) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture(for: identity))
        let side = max(0, radius.isFinite ? radius : 0) * 2 * CGFloat(rasterSide) / silhouetteSide
        node.size = CGSize(width: side, height: side)
        node.name = "sky-piece.\(StarCast.character(for: identity).name)"
        return node
    }

    /// Material changes cannot reset an in-flight scale, pivot, rotation or soft-body deformation.
    /// Gameplay states reuse the same faceless image; motion belongs to the scene/character owner.
    static func setMaterial(for identity: StarCast.Identity, on node: SKSpriteNode) {
        let size = node.size
        let anchor = node.anchorPoint
        node.texture = texture(for: identity)
        node.size = size
        node.anchorPoint = anchor
    }

    /// Keep the familiar family name while describing the actual playable silhouette.
    static func description(for identity: StarCast.Identity) -> String {
        let key: SkyCopy.Key
        switch identity {
        case .colored(.aqua): key = .pieceSpark
        case .colored(.amber): key = .pieceSunny
        case .colored(.mint): key = .piecePip
        case .colored(.rose): key = .pieceTwinkle
        case .colored(.violet): key = .pieceNova
        case .dusk: key = .pieceDusk
        case .opal: return SkyCopy.text(.pieceOpal)
        case .magnet: return SkyCopy.text(.castField)
        case .hole: return SkyCopy.text(.castHole)
        }
        return SkyCopy.text(key) + ", " + StarCast.character(for: identity).name
    }

    private static func material(for identity: StarCast.Identity) -> Material {
        if let cached = materials[identity] { return cached }
        let result: Material
        if identity == .magnet || identity == .hole {
            // Retained historical objects share their original faceless material, not another raster.
            result = Material(image: StarCast.image(for: identity),
                              texture: StarCast.texture(for: identity, expression: .idle))
        } else {
            let assetName = "SkyPiece" + StarCast.character(for: identity).name
            guard let image = UIImage(named: assetName) else {
                preconditionFailure("Missing gameplay piece: " + assetName)
            }
            let texture = SKTexture(image: image)
            texture.filteringMode = .linear
            texture.usesMipmaps = false
            result = Material(image: image, texture: texture)
        }
        materials[identity] = result
        return result
    }
}
