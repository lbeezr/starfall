import UIKit
import SpriteKit
import StarfallCore

/// Crystal Glow cutouts with authored expressions. Core Jewel raw values and saves stay unchanged.
/// One material owner supplies SpriteKit and SwiftUI; no per-frame drawing or asset IO.
@MainActor enum StarCast {
    /// A presentation identity distinguishes the two colorless Core roles.
    enum Identity: Hashable, CaseIterable {
        case colored(Jewel), dusk, opal, magnet, hole
        static var allCases: [Self] { Jewel.allCases.map(Self.colored) + [.dusk, .opal, .magnet, .hole] }
        init(kind: Jewel?, isLight: Bool = false) {
            self = isLight ? .opal : kind.map(Self.colored) ?? .dusk
        }
        init(_ identity: SkyIdentity) {
            switch identity {
            case .colored(let family): self = .colored(family)
            case .dusk: self = .dusk
            case .white: self = .opal
            case .magnet: self = .magnet
            case .hole: self = .hole
            }
        }
        init(_ gem: StarfallGem) { self.init(gem.identity) }
        init(_ star: IncomingStar) { self.init(star.identity) }
        var color: UIColor {
            switch self {
            case .colored(let kind): kind.color
            case .dusk: .systemPurple
            case .opal: .white
            case .magnet: StarfallTheme.Gravity.magneticLight
            case .hole: StarfallTheme.Gravity.orbitLight
            }
        }
    }
    enum Expression: Int, CaseIterable { case idle, landing, grown, clearing }
    enum Facing: Int, CaseIterable { case front, left, right }
    struct Character {
        let name: String
        let points: Int
        let description: String
        init(name: String, points: Int, description: String) {
            self.name = name; self.points = points; self.description = description
        }
        init(speaker: SkySpeaker, points: Int, description: String) {
            name = speaker.name; self.points = points; self.description = description + ", " + speaker.name
        }
    }

    static let rasterSide = 256
    static let silhouetteSide: CGFloat = 212 // Existing display-size contract; centered 208px packaged bodies.
    static let maximumMaterials = (Identity.allCases.count - 2) * Expression.allCases.count * Facing.allCases.count + 2
    static let maximumRasterBytes = maximumMaterials * rasterSide * rasterSide * 4
    private static let ink = UIColor(red: 0.08, green: 0.10, blue: 0.22, alpha: 1)
    private struct Key: Hashable { let identity: Identity; let expression: Int; let facing: Int }
    private struct Material { let image: UIImage; let texture: SKTexture }
    private static var materials: [Key: Material] = [:]
    private static var bodies: [String: UIImage] = [:]
    private static var bodyHeights: [String: CGFloat] = [:]
    static var cachedMaterialCount: Int { materials.count }

    /// Shadow placement follows the packaged body and growth, not the square texture canvas.
    static func groundOffset(for identity: Identity, radius: CGFloat) -> CGFloat {
        if identity == .magnet { return 0 }
        let name = character(for: identity).name
        _ = material(for: identity, expression: .idle, facing: .front)
        return radius * (bodyHeights[name] ?? silhouetteSide) / silhouetteSide
    }

    static func character(for identity: Identity) -> Character {
        switch identity {
        case .colored(.aqua):
            Character(speaker: .spark, points: 4, description: "Aqua four-point star")
        case .colored(.amber):
            Character(speaker: .sunny, points: 5, description: "Amber five-point star")
        case .colored(.mint):
            Character(speaker: .pip, points: 6, description: "Mint six-point star")
        case .colored(.rose):
            Character(speaker: .twinkle, points: 8, description: "Rose eight-point star")
        case .colored(.violet):
            Character(speaker: .nova, points: 4, description: "Violet wide four-point star")
        case .dusk:
            Character(speaker: .dusk, points: 5, description: "Dark star")
        case .opal:
            Character(name: "Opal", points: 0, description: "White Opal Orb")
        case .magnet:
            Character(name: "Field", points: 0, description: "Attraction field")
        case .hole:
            Character(name: "Hole", points: 0, description: "Gravity hole")
        }
    }

    static func image(for identity: Identity, expression: Expression = .idle, facing: Facing = .front) -> UIImage {
        material(for: identity, expression: expression, facing: facing).image
    }
    static func texture(for identity: Identity, expression: Expression, facing: Facing = .front) -> SKTexture {
        material(for: identity, expression: expression, facing: facing).texture
    }
    /// SpriteKit texture actions can restore the texture's intrinsic canvas size mid-action.
    /// Expression changes must preserve the caller's authored size, scale and pivot.
    static func setExpression(_ expression: Expression, for identity: Identity, on node: SKSpriteNode, facing: Facing = .front) {
        let size = node.size
        let anchor = node.anchorPoint
        node.texture = texture(for: identity, expression: expression, facing: facing)
        node.size = size
        node.anchorPoint = anchor
    }
    static func prewarm() {
        for identity in Identity.allCases {
            for expression in Expression.allCases {
                for facing in Facing.allCases { _ = material(for: identity, expression: expression, facing: facing) }
            }
        }
    }
    static func makeNode(for identity: Identity, expression: Expression, radius: CGFloat) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture(for: identity, expression: expression))
        let side = max(0, radius.isFinite ? radius : 0) * 2 * CGFloat(rasterSide) / silhouetteSide
        node.size = CGSize(width: side, height: side)
        node.name = "star-cast.\(character(for: identity).name).\(expression.rawValue)"
        return node
    }
    /// Finite pose changes preserve sprite geometry; the scene owns their lifetime.
    static func turnAction(for identity: Identity, expression: Expression,
                           toward facing: Facing, duration: TimeInterval) -> SKAction {
        let opposite: Facing = facing == .left ? .right : .left
        let poses: [Facing] = [.front, facing, .front, opposite, .front]
        return .sequence(poses.map { pose in
            .sequence([.customAction(withDuration: duration / Double(poses.count)) { node, _ in
                guard let sprite = node as? SKSpriteNode else { return }
                // Cached materials only; no drawing or IO in the action callback.
                setExpression(expression, for: identity, on: sprite, facing: pose)
            }])
        })
    }

    private static func material(for identity: Identity, expression: Expression, facing: Facing) -> Material {
        let gravity = identity == .magnet || identity == .hole
        let key = Key(identity: identity, expression: gravity ? Expression.idle.rawValue : expression.rawValue,
                      facing: gravity ? Facing.front.rawValue : facing.rawValue)
        if let cached = materials[key] { return cached }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1; format.opaque = false
        format.preferredRange = .standard
        let character = character(for: identity)
        let body: UIImage
        if let cached = bodies[character.name] { body = cached }
        else {
            guard let packaged = UIImage(named: "StarCast" + character.name) else {
                preconditionFailure("Missing Crystal Glow body: " + character.name)
            }
            body = packaged; bodies[character.name] = packaged
            // One bounded coverage scan per family, before any per-frame presentation.
            var pixels = [UInt8](repeating: 0, count: rasterSide * rasterSide * 4)
            if let cg = packaged.cgImage,
               let context = CGContext(data: &pixels, width: rasterSide, height: rasterSide,
                    bitsPerComponent: 8, bytesPerRow: rasterSide * 4,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                context.draw(cg, in: CGRect(x: 0, y: 0, width: rasterSide, height: rasterSide))
                let rows = (0..<rasterSide).filter { y in
                    (0..<rasterSide).contains { pixels[(y * rasterSide + $0) * 4 + 3] >= 128 }
                }
                if let first = rows.first, let last = rows.last { bodyHeights[character.name] = CGFloat(last - first + 1) }
            }
        }
        if gravity {
            let texture = SKTexture(image: body)
            texture.filteringMode = .linear; texture.usesMipmaps = false
            let result = Material(image: body, texture: texture)
            materials[key] = result
            return result
        }
        let image = UIGraphicsImageRenderer(size: CGSize(width: rasterSide, height: rasterSide), format: format)
            .image { render(character, body: body, dark: identity == .dusk, expression: expression, facing: facing, in: $0.cgContext) }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear; texture.usesMipmaps = false
        let result = Material(image: image, texture: texture)
        materials[key] = result
        return result
    }

    /// One body per family keeps alpha coverage identical across all four expressions.
    /// Shallow presentation yaw preserves the established front/left/right material contract.
    private static func render(_ character: Character, body: UIImage, dark: Bool,
                               expression: Expression, facing: Facing, in ctx: CGContext) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        let direction: CGFloat = facing == .left ? -1 : facing == .right ? 1 : 0
        ctx.translateBy(x: 128, y: 128)
        ctx.scaleBy(x: direction == 0 ? 1 : 0.86, y: 1)
        ctx.translateBy(x: -128, y: -128)
        body.draw(in: CGRect(x: 0, y: 0, width: rasterSide, height: rasterSide))
        // Faces may alter color, never body coverage; translucent alpha and pivots stay stable.
        ctx.setBlendMode(.sourceAtop)
        ctx.translateBy(x: direction * 13, y: 0)
        ctx.setLineCap(.round); ctx.setLineJoin(.round)
        drawFace(character, dark: dark, expression: expression, in: ctx)
    }

    private static func drawFace(_ character: Character, dark: Bool, expression: Expression, in ctx: CGContext) {
        let happy = expression == .clearing
        let sleepy = character.name == "Nova" || dark
        let faceInk = dark ? UIColor(red: 0.90, green: 0.85, blue: 1, alpha: 1) : ink
        func stroke(_ path: CGPath, color: UIColor? = nil, width: CGFloat = 5) {
            ctx.addPath(path); ctx.setStrokeColor((color ?? ink).cgColor); ctx.setLineWidth(width); ctx.strokePath()
        }
        for x in [CGFloat(104), 152] {
            if happy {
                let eye = CGMutablePath(); eye.move(to: CGPoint(x: x - 11, y: 127))
                eye.addQuadCurve(to: CGPoint(x: x + 11, y: 127), control: CGPoint(x: x, y: 108))
                stroke(eye, color: faceInk, width: 6)
            } else {
                let height: CGFloat = expression == .landing ? 44 : sleepy && expression == .idle ? 30 : 40
                let width: CGFloat = 25
                let eye = CGRect(x: x - width / 2, y: 117 - height / 2, width: width, height: height)
                ctx.saveGState()
                ctx.addEllipse(in: eye); ctx.clip()
                let colors = [ink.cgColor, UIColor(red: 0.015, green: 0.04, blue: 0.28, alpha: 1).cgColor,
                              UIColor(red: 0.06, green: 0.43, blue: 0.98, alpha: 1).cgColor] as CFArray
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors,
                                             locations: [0, 0.62, 1]) {
                    ctx.drawLinearGradient(gradient, start: CGPoint(x: x, y: eye.minY),
                                           end: CGPoint(x: x, y: eye.maxY), options: [])
                }
                ctx.setFillColor(ink.cgColor)
                ctx.fillEllipse(in: CGRect(x: x - 7, y: eye.minY + 5, width: 14, height: height * 0.59))
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.fillEllipse(in: CGRect(x: x - 5, y: eye.minY + 4, width: 7, height: 9))
                ctx.setFillColor(UIColor.cyan.withAlphaComponent(0.8).cgColor)
                ctx.fillEllipse(in: CGRect(x: x + 3, y: eye.maxY - 7, width: 3, height: 3))
                ctx.restoreGState()
                if sleepy && expression == .idle {
                    // A clean upper lid makes Nova dreamy and Dusk mischievous at board size.
                    let lid = CGMutablePath()
                    lid.move(to: CGPoint(x: eye.minX - 1, y: eye.minY + 3))
                    lid.addLine(to: CGPoint(x: eye.maxX + 1, y: eye.minY + (dark ? -1 : 3)))
                    stroke(lid, width: 5)
                }
            }
        }
        // Raised eyebrow is Pip's quiet mischief; no idle action is required.
        if (character.name == "Pip" || dark || character.name == "Twinkle") && expression == .idle {
            let brow = CGMutablePath(); brow.move(to: CGPoint(x: 140, y: 88))
            brow.addQuadCurve(to: CGPoint(x: 163, y: dark ? 82 : 88), control: CGPoint(x: 151, y: character.name == "Twinkle" ? 95 : 78))
            stroke(brow, width: 4)
        }
        if expression == .landing {
            ctx.setFillColor(faceInk.cgColor)
            ctx.fillEllipse(in: CGRect(x: 122, y: 139, width: 12, height: 15))
        } else if happy || expression == .grown {
            let mouth = CGMutablePath(); mouth.move(to: CGPoint(x: 116, y: 140))
            mouth.addQuadCurve(to: CGPoint(x: 140, y: 140), control: CGPoint(x: 128, y: 145))
            mouth.addCurve(to: CGPoint(x: 116, y: 140), control1: CGPoint(x: 142, y: 164), control2: CGPoint(x: 114, y: 164))
            ctx.addPath(mouth); ctx.setFillColor(faceInk.cgColor); ctx.fillPath()
            ctx.setFillColor(UIColor(red: 1, green: 0.51, blue: 0.57, alpha: 1).cgColor)
            ctx.fillEllipse(in: CGRect(x: 122, y: 149, width: 13, height: 7))
        } else {
            let smile = CGMutablePath(); smile.move(to: CGPoint(x: 119, y: 142))
            smile.addQuadCurve(to: CGPoint(x: 137, y: 141), control: CGPoint(x: 129, y: 155))
            stroke(smile, color: faceInk, width: 4.5)
        }
        if !dark {
            ctx.setFillColor(UIColor(red: 0.94, green: 0.29, blue: 0.40, alpha: 0.24).cgColor)
            for x in [CGFloat(91), 165] { ctx.fillEllipse(in: CGRect(x: x - 7, y: 134, width: 14, height: 6)) }
        }
    }
}
