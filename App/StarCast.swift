import UIKit
import SpriteKit
import StarfallCore

/// Authored, resolution-independent cast. Core Jewel raw values and saves stay unchanged.
/// One material owner supplies SpriteKit and SwiftUI; no per-frame drawing or asset IO.
@MainActor enum StarCast {
    enum Expression: Int, CaseIterable { case idle, landing, grown, clearing }
    enum Facing: Int, CaseIterable { case front, left, right }
    struct Character {
        let name: String
        let points: Int
        let innerRadius: CGFloat
        let aspect: CGSize
        let color: UIColor
        let highlight: UIColor
        let shadow: UIColor
        let description: String
    }

    static let rasterSide = 256
    static let silhouetteSide: CGFloat = 212 // Includes the ink outline; fixed centered canvas.
    static let maximumMaterials = 6 * Expression.allCases.count * Facing.allCases.count
    static let maximumRasterBytes = maximumMaterials * rasterSide * rasterSide * 4
    private static let ink = UIColor(red: 0.08, green: 0.10, blue: 0.22, alpha: 1)
    private struct Key: Hashable { let kind: Int; let expression: Int; let facing: Int }
    private struct Material { let image: UIImage; let texture: SKTexture }
    private static var materials: [Key: Material] = [:]
    static var cachedMaterialCount: Int { materials.count }

    static func character(for kind: Jewel?) -> Character {
        switch kind {
        case .aqua:
            Character(name: "Spark", points: 4, innerRadius: 0.38,
                      aspect: CGSize(width: 0.82, height: 1),
                      color: UIColor(red: 0.22, green: 0.80, blue: 0.94, alpha: 1),
                      highlight: UIColor(red: 0.64, green: 0.98, blue: 1, alpha: 1),
                      shadow: UIColor(red: 0.07, green: 0.49, blue: 0.72, alpha: 1),
                      description: "Aqua four-point star, Spark")
        case .amber:
            Character(name: "Sunny", points: 5, innerRadius: 0.54,
                      aspect: CGSize(width: 1, height: 1),
                      color: UIColor(red: 1, green: 0.75, blue: 0.20, alpha: 1),
                      highlight: UIColor(red: 1, green: 0.94, blue: 0.53, alpha: 1),
                      shadow: UIColor(red: 0.92, green: 0.43, blue: 0.08, alpha: 1),
                      description: "Amber five-point star, Sunny")
        case .mint:
            Character(name: "Pip", points: 6, innerRadius: 0.63,
                      aspect: CGSize(width: 1, height: 1),
                      color: UIColor(red: 0.38, green: 0.85, blue: 0.57, alpha: 1),
                      highlight: UIColor(red: 0.80, green: 1, blue: 0.68, alpha: 1),
                      shadow: UIColor(red: 0.12, green: 0.57, blue: 0.42, alpha: 1),
                      description: "Mint six-point star, Pip")
        case .rose:
            Character(name: "Twinkle", points: 8, innerRadius: 0.60,
                      aspect: CGSize(width: 1, height: 1),
                      color: UIColor(red: 1, green: 0.49, blue: 0.64, alpha: 1),
                      highlight: UIColor(red: 1, green: 0.80, blue: 0.81, alpha: 1),
                      shadow: UIColor(red: 0.78, green: 0.24, blue: 0.44, alpha: 1),
                      description: "Rose eight-point star, Twinkle")
        case .violet:
            Character(name: "Nova", points: 4, innerRadius: 0.48,
                      aspect: CGSize(width: 1, height: 0.70),
                      color: UIColor(red: 0.64, green: 0.49, blue: 0.91, alpha: 1),
                      highlight: UIColor(red: 0.85, green: 0.75, blue: 1, alpha: 1),
                      shadow: UIColor(red: 0.40, green: 0.28, blue: 0.69, alpha: 1),
                      description: "Violet wide four-point star, Nova")
        case nil:
            Character(name: "Dusk", points: 5, innerRadius: 0.50,
                      aspect: CGSize(width: 1, height: 1),
                      color: UIColor(red: 0.25, green: 0.23, blue: 0.44, alpha: 1),
                      highlight: UIColor(red: 0.48, green: 0.42, blue: 0.68, alpha: 1),
                      shadow: UIColor(red: 0.12, green: 0.12, blue: 0.27, alpha: 1),
                      description: "Dark star, Dusk")
        }
    }

    static func image(for kind: Jewel?, expression: Expression = .idle, facing: Facing = .front) -> UIImage {
        material(for: kind, expression: expression, facing: facing).image
    }
    static func texture(for kind: Jewel?, expression: Expression, facing: Facing = .front) -> SKTexture {
        material(for: kind, expression: expression, facing: facing).texture
    }
    /// SpriteKit texture actions can restore the texture's intrinsic canvas size mid-action.
    /// Expression changes must preserve the caller's authored size, scale and pivot.
    static func setExpression(_ expression: Expression, for kind: Jewel?, on node: SKSpriteNode, facing: Facing = .front) {
        let size = node.size
        let anchor = node.anchorPoint
        node.texture = texture(for: kind, expression: expression, facing: facing)
        node.size = size
        node.anchorPoint = anchor
    }
    static func prewarm() {
        for kind in Jewel.allCases.map(Optional.some) + [nil] {
            for expression in Expression.allCases {
                for facing in Facing.allCases { _ = material(for: kind, expression: expression, facing: facing) }
            }
        }
    }
    static func makeNode(for kind: Jewel?, expression: Expression, radius: CGFloat) -> SKSpriteNode {
        let node = SKSpriteNode(texture: texture(for: kind, expression: expression))
        let side = max(0, radius.isFinite ? radius : 0) * 2 * CGFloat(rasterSide) / silhouetteSide
        node.size = CGSize(width: side, height: side)
        node.name = "star-cast.\(character(for: kind).name).\(expression.rawValue)"
        return node
    }
    /// Finite pose changes preserve sprite geometry; the scene owns their lifetime.
    static func turnAction(for kind: Jewel?, expression: Expression,
                           toward facing: Facing, duration: TimeInterval) -> SKAction {
        let opposite: Facing = facing == .left ? .right : .left
        let poses: [Facing] = [.front, facing, .front, opposite, .front]
        return .sequence(poses.map { pose in
            .sequence([.customAction(withDuration: duration / Double(poses.count)) { node, _ in
                guard let sprite = node as? SKSpriteNode else { return }
                // Cached materials only; no drawing or IO in the action callback.
                setExpression(expression, for: kind, on: sprite, facing: pose)
            }])
        })
    }

    private static func material(for kind: Jewel?, expression: Expression, facing: Facing) -> Material {
        let key = Key(kind: kind?.rawValue ?? -1, expression: expression.rawValue, facing: facing.rawValue)
        if let cached = materials[key] { return cached }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1; format.opaque = false
        format.preferredRange = .standard
        let image = UIGraphicsImageRenderer(size: CGSize(width: rasterSide, height: rasterSide), format: format)
            .image { render(character(for: kind), dark: kind == nil, expression: expression, facing: facing, in: $0.cgContext) }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear; texture.usesMipmaps = false
        let result = Material(image: image, texture: texture)
        materials[key] = result
        return result
    }

    /// Rounded corners retain the exact authored point count and stable 128/128 pivot.
    private static func outline(_ character: Character) -> CGPath {
        let count = character.points * 2
        let vertices: [CGPoint] = (0..<count).map { index in
            let angle = -CGFloat.pi / 2 + CGFloat(index) * .pi / CGFloat(character.points)
            // Alternate long/short outer rays make Twinkle a celestial twinkle, not a gear.
            let ray: CGFloat = character.points == 8 && index % 4 == 2 ? 0.80 : 1
            let radius: CGFloat = index.isMultiple(of: 2) ? 100 * ray : 100 * character.innerRadius
            return CGPoint(x: 128 + cos(angle) * radius * character.aspect.width,
                           y: 128 + sin(angle) * radius * character.aspect.height)
        }
        func between(_ a: CGPoint, _ b: CGPoint, _ fraction: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * fraction, y: a.y + (b.y - a.y) * fraction)
        }
        let path = CGMutablePath()
        path.move(to: between(vertices[0], vertices[1], 0.07))
        for index in 1...count {
            let vertex = vertices[index % count]
            path.addLine(to: between(vertex, vertices[(index - 1) % count], 0.07))
            path.addQuadCurve(to: between(vertex, vertices[(index + 1) % count], 0.07), control: vertex)
        }
        path.closeSubpath()
        return path
    }

    private static func render(_ character: Character, dark: Bool, expression: Expression, facing: Facing, in ctx: CGContext) {
        ctx.saveGState()
        defer { ctx.restoreGState() }
        let direction: CGFloat = facing == .left ? -1 : facing == .right ? 1 : 0
        // Authored shallow yaw: compressed contour and a face that wraps toward the turn.
        ctx.translateBy(x: 128, y: 128)
        ctx.scaleBy(x: direction == 0 ? 1 : 0.86, y: 1)
        ctx.translateBy(x: -128, y: -128)
        let shape = outline(character)
        ctx.setLineJoin(.round); ctx.setLineCap(.round)
        // Bake a bounded halo into the shared material; no emitters or per-frame work.
        ctx.saveGState()
        ctx.clip(to: CGRect(x: 18, y: 18, width: 220, height: 220))
        ctx.setShadow(offset: .zero, blur: dark ? 8 : 15,
                      color: character.highlight.withAlphaComponent(dark ? 0.30 : 0.72).cgColor)
        ctx.addPath(shape); ctx.setFillColor(character.color.cgColor); ctx.fillPath()
        ctx.restoreGState()
        // A pale rim lets the body read as emitted light rather than a dark-edged token.
        ctx.addPath(shape); ctx.setStrokeColor(character.highlight.withAlphaComponent(dark ? 0.65 : 0.90).cgColor)
        ctx.setLineWidth(7); ctx.strokePath()
        ctx.addPath(shape); ctx.setFillColor(character.color.cgColor); ctx.fillPath()
        ctx.saveGState(); ctx.addPath(shape); ctx.clip()
        let colors = [character.highlight.cgColor, character.color.cgColor, character.shadow.cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1]) {
            ctx.drawLinearGradient(gradient, start: CGPoint(x: 80, y: 38), end: CGPoint(x: 170, y: 223), options: [])
        }
        // A broad inner light keeps the body luminous at board scale without facets.
        if !dark, let light = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [UIColor.white.withAlphaComponent(0.70).cgColor,
                     character.highlight.withAlphaComponent(0.18).cgColor,
                     UIColor.white.withAlphaComponent(0).cgColor] as CFArray,
            locations: [0, 0.52, 1]) {
            ctx.drawRadialGradient(light, startCenter: CGPoint(x: 118, y: 98), startRadius: 0,
                                   endCenter: CGPoint(x: 128, y: 119), endRadius: 100,
                                   options: [.drawsAfterEndLocation])
        }
        ctx.restoreGState()
        ctx.addPath(shape)
        ctx.setStrokeColor(character.highlight.withAlphaComponent(dark ? 0.9 : 0.95).cgColor)
        ctx.setLineWidth(2.5); ctx.strokePath()
        ctx.translateBy(x: direction * 13, y: 0)
        drawFace(character, dark: dark, expression: expression, in: ctx)
    }

    private static func drawFace(_ character: Character, dark: Bool, expression: Expression, in ctx: CGContext) {
        let happy = expression == .clearing
        let sleepy = dark || character.name == "Nova" || character.name == "Twinkle"
        let faceInk = dark ? UIColor(red: 0.96, green: 0.91, blue: 1, alpha: 1) : ink
        func stroke(_ path: CGPath, color: UIColor? = nil, width: CGFloat = 5) {
            ctx.addPath(path); ctx.setStrokeColor((color ?? ink).cgColor); ctx.setLineWidth(width); ctx.strokePath()
        }
        for x in [CGFloat(108), 148] {
            if happy {
                let eye = CGMutablePath(); eye.move(to: CGPoint(x: x - 8, y: 127))
                eye.addQuadCurve(to: CGPoint(x: x + 8, y: 127), control: CGPoint(x: x, y: 108))
                stroke(eye, color: faceInk, width: 6)
            } else {
                // One clear oval per eye, with one catchlight: no tiny sclera/pupil rings.
                let height: CGFloat = expression == .landing ? 30 : sleepy ? 21 : 28
                let width: CGFloat = sleepy ? 13 : 14
                let eye = CGRect(x: x - width / 2, y: 119 - height / 2, width: width, height: height)
                ctx.setFillColor(faceInk.cgColor)
                ctx.fillEllipse(in: eye)
                ctx.setFillColor((dark ? character.shadow : UIColor.white).withAlphaComponent(0.95).cgColor)
                ctx.fillEllipse(in: CGRect(x: eye.minX + 3, y: eye.minY + 3, width: 4, height: 6))
            }
        }
        // Raised eyebrow is Pip's quiet mischief; no idle action is required.
        if character.name == "Pip" && expression == .idle {
            let brow = CGMutablePath(); brow.move(to: CGPoint(x: 139, y: 96))
            brow.addQuadCurve(to: CGPoint(x: 156, y: 99), control: CGPoint(x: 148, y: 90))
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
