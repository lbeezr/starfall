// Isolated prototype material. Reuse Sunny's body; the dark link is a non-color cue.
@MainActor private enum WhiteConnectorMaterial {
    private static let texture: SKTexture = {
        let source = StarCast.image(for: .amber)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: source.size, format: format).image { renderer in
            let rect = CGRect(origin: .zero, size: source.size)
            source.draw(in: rect)
            renderer.cgContext.setBlendMode(.sourceIn)
            UIColor.white.setFill()
            renderer.cgContext.fill(rect)
        }
        return SKTexture(image: image)
    }()
    static func apply(to node: SKSpriteNode) {
        node.texture = texture
        node.colorBlendFactor = 0
    }
    static func decorate(_ node: SKSpriteNode, radius: CGFloat) {
        apply(to: node)
        for direction in [-1.0, 1.0] {
            let link = SKShapeNode(ellipseOf: CGSize(width: radius * 0.70, height: radius * 0.44))
            link.strokeColor = StarfallTheme.Observatory.contactShadow.withAlphaComponent(1)
            link.fillColor = .clear; link.lineWidth = max(2, radius * 0.09)
            link.position.x = radius * 0.20 * direction
            link.zRotation = .pi / 4
            link.zPosition = 1
            node.addChild(link)
        }
    }
}
