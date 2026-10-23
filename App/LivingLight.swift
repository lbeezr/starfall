import SpriteKit
import UIKit

/// One light inside an authored shell. All pixels/masks are cached at prewarm;
/// actions change only four shader values and never own gameplay positions or time.
@MainActor enum LivingLight {
    static let actionKey = "sky.living-light"
    static let maximumOffset: CGFloat = 0.12
    static let rasterBytesPerFamily = 3 * 256 * 256 * 4

    struct Material {
        let image: UIImage
        let shell: SKTexture
        let mask: SKTexture
        let shader: SKShader
    }

    struct Emission {
        let family: UIColor
        let center: UIColor
    }

    /// Finite effects share the body's colored surround and pale inner light.
    /// Historical field objects retain their existing single-color emission.
    static func emission(for identity: StarCast.Identity) -> Emission {
        switch identity {
        case .colored(_), .dusk, .opal:
            let family = profile(identity)
            return Emission(
                family: UIColor(red: CGFloat(family.color.x), green: CGFloat(family.color.y),
                                blue: CGFloat(family.color.z), alpha: 1),
                center: UIColor(red: CGFloat(family.warmth.x), green: CGFloat(family.warmth.y),
                                blue: CGFloat(family.warmth.z), alpha: 1))
        case .magnet, .hole:
            return Emission(family: identity.color, center: identity.color)
        }
    }

    private struct Profile {
        let center: SIMD2<Float>
        let color: SIMD3<Float>
        let warmth: SIMD3<Float>
        let response: Float
    }

    private static func profile(_ identity: StarCast.Identity) -> Profile {
        switch identity {
        case .colored(.aqua):
            .init(center: SIMD2(0.60, 0.45), color: SIMD3(0.20, 0.86, 0.96),
                  warmth: SIMD3(0.92, 1, 0.96), response: 1)
        case .colored(.amber):
            .init(center: SIMD2(0.50, 0.50), color: SIMD3(1, 0.64, 0.15),
                  warmth: SIMD3(1, 0.97, 0.82), response: 0.82)
        case .colored(.mint):
            .init(center: SIMD2(0.50, 0.49), color: SIMD3(0.30, 0.94, 0.68),
                  warmth: SIMD3(0.94, 1, 0.86), response: 0.88)
        case .colored(.rose):
            .init(center: SIMD2(0.50, 0.50), color: SIMD3(1, 0.38, 0.66),
                  warmth: SIMD3(1, 0.91, 0.93), response: 0.94)
        case .colored(.violet):
            .init(center: SIMD2(0.50, 0.50), color: SIMD3(0.66, 0.47, 0.98),
                  warmth: SIMD3(0.96, 0.91, 1), response: 0.68)
        case .dusk:
            .init(center: SIMD2(0.57, 0.48), color: SIMD3(0.48, 0.31, 0.88),
                  warmth: SIMD3(0.87, 0.79, 1), response: 0.65)
        default:
            .init(center: SIMD2(0.50, 0.50), color: SIMD3(0.78, 0.78, 0.98),
                  warmth: SIMD3(1, 0.98, 0.89), response: 0.78)
        }
    }

    /// Fill the enclosed translucent center using the authored rim as a boundary.
    /// Exterior flood fill preserves concave notches and the exact generated contour.
    static func material(shell image: UIImage, identity: StarCast.Identity) -> Material {
        let side = 256
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let space = CGColorSpaceCreateDeviceRGB()
        let bitmap = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let source = image.cgImage,
              let context = CGContext(data: &pixels, width: side, height: side, bitsPerComponent: 8,
                                      bytesPerRow: side * 4, space: space, bitmapInfo: bitmap) else {
            preconditionFailure("Living light requires a readable RGBA shell")
        }
        context.draw(source, in: CGRect(x: 0, y: 0, width: side, height: side))
        var outside = [Bool](repeating: false, count: side * side)
        var queue = [Int]()
        func admit(_ index: Int) {
            guard !outside[index], pixels[index * 4 + 3] < 8 else { return }
            outside[index] = true; queue.append(index)
        }
        for index in 0..<side {
            admit(index); admit((side - 1) * side + index)
            admit(index * side); admit(index * side + side - 1)
        }
        var cursor = 0
        while cursor < queue.count {
            let index = queue[cursor]; cursor += 1
            let x = index % side, y = index / side
            if x > 0 { admit(index - 1) }
            if x + 1 < side { admit(index + 1) }
            if y > 0 { admit(index - side) }
            if y + 1 < side { admit(index + side) }
        }
        let family = profile(identity)
        var mask = [UInt8](repeating: 0, count: pixels.count)
        var composed = pixels
        for index in outside.indices {
            let offset = index * 4
            let coverage: Float = outside[index] ? 0 : 1
            for channel in 0..<4 { mask[offset + channel] = coverage == 0 ? 0 : 255 }
            // CGContext rows here follow the source image's top-to-bottom pixel order.
            let uv = SIMD2((Float(index % side) + 0.5) / Float(side),
                           1 - (Float(index / side) + 0.5) / Float(side))
            let delta = uv - family.center
            let d = SIMD2(delta.x + delta.y * 0.18, delta.y * 1.12)
            let energy = exp(-(d.x * d.x + d.y * d.y) * 24)
            let rgb = family.color * (1 - energy * 0.86) + family.warmth * (energy * 0.86)
            let alpha = (0.72 + 0.23 * energy) * coverage
            let shellAlpha = Float(pixels[offset + 3]) / 255
            for channel in 0..<3 {
                let value = Float(pixels[offset + channel]) / 255 + rgb[channel] * alpha * (1 - shellAlpha)
                composed[offset + channel] = UInt8(clamping: Int((value * 255).rounded()))
            }
            composed[offset + 3] = UInt8(clamping: Int(((shellAlpha + alpha * (1 - shellAlpha)) * 255).rounded()))
        }
        func raster(_ bytes: [UInt8]) -> UIImage {
            let provider = CGDataProvider(data: Data(bytes) as CFData)!
            let result = CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32,
                bytesPerRow: side * 4, space: space, bitmapInfo: CGBitmapInfo(rawValue: bitmap),
                provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
            return UIImage(cgImage: result)
        }
        func texture(_ image: UIImage) -> SKTexture {
            let texture = SKTexture(image: image)
            texture.filteringMode = .linear; texture.usesMipmaps = false
            return texture
        }
        let shellTexture = texture(image), maskTexture = texture(raster(mask))
        return Material(image: raster(composed), shell: shellTexture, mask: maskTexture,
                        shader: makeShader(identity: identity, shell: shellTexture, mask: maskTexture))
    }

    private static func makeShader(identity: StarCast.Identity, shell: SKTexture, mask: SKTexture) -> SKShader {
        let family = profile(identity)
        let shader = SKShader(source: shaderSource)
        shader.uniforms = [
            SKUniform(name: "u_shell", texture: shell),
            SKUniform(name: "u_mask", texture: mask),
            SKUniform(name: "u_center", vectorFloat2: family.center),
            SKUniform(name: "u_tint", vectorFloat3: family.color),
            SKUniform(name: "u_warm", vectorFloat3: family.warmth),
            SKUniform(name: "u_corruption", vectorFloat4: StarfallTheme.Dusk.corruption)
        ]
        shader.attributes = [
            SKAttribute(name: "a_light", type: .vectorFloat4),
            SKAttribute(name: "a_drain", type: .float),
            SKAttribute(name: "a_pressure", type: .float)
        ]
        return shader
    }

    static func configure(_ node: SKSpriteNode, identity: StarCast.Identity, material: Material) {
        // Seven shared programs are created during material prewarm. Changing only
        // per-node attributes avoids recompiling programs as board columns rebuild.
        node.shader = material.shader
        setLight(SIMD4(0, 0, 1, 1), on: node)
        setDrain(0, on: node); setPressure(0, on: node)
    }

    private static func setLight(_ value: SIMD4<Float>, on node: SKSpriteNode) {
        let attribute = node.value(forAttributeNamed: "a_light") ?? SKAttributeValue(vectorFloat4: value)
        attribute.vectorFloat4Value = value
        node.setValue(attribute, forAttribute: "a_light")
    }

    static func offset(on node: SKSpriteNode) -> CGPoint {
        let value = node.value(forAttributeNamed: "a_light")?.vectorFloat4Value ?? SIMD4(0, 0, 1, 1)
        return CGPoint(x: CGFloat(value.x), y: CGFloat(value.y))
    }
    static func isResponding(on node: SKSpriteNode) -> Bool { node.action(forKey: actionKey) != nil }
    static func reset(_ node: SKSpriteNode) {
        node.removeAction(forKey: actionKey)
        if node.value(forAttributeNamed: "a_light") != nil { setLight(SIMD4(0, 0, 1, 1), on: node) }
    }
    static func drain(on node: SKSpriteNode) -> Float { node.value(forAttributeNamed: "a_drain")?.floatValue ?? 0 }
    static func pressure(on node: SKSpriteNode) -> Float { node.value(forAttributeNamed: "a_pressure")?.floatValue ?? 0 }
    static func setDrain(_ amount: Float, on node: SKSpriteNode) {
        guard node.shader != nil else { return }
        node.setValue(SKAttributeValue(float: min(1, max(0, amount))), forAttribute: "a_drain")
    }
    static func setPressure(_ amount: Float, on node: SKSpriteNode) {
        guard node.shader != nil else { return }
        node.setValue(SKAttributeValue(float: min(1, max(0, amount))), forAttribute: "a_pressure")
    }

    private static func animate(_ node: SKSpriteNode, duration: TimeInterval,
                                sample: @escaping (Float) -> SIMD4<Float>) {
        reset(node)
        guard node.value(forAttributeNamed: "a_light") != nil else { return }
        node.run(.sequence([
            .customAction(withDuration: duration) { target, elapsed in
                guard let sprite = target as? SKSpriteNode else { return }
                var value = sample(min(1, Float(elapsed / CGFloat(duration))))
                let length = hypot(value.x, value.y)
                if length > Float(maximumOffset) {
                    value.x *= Float(maximumOffset) / length
                    value.y *= Float(maximumOffset) / length
                }
                setLight(value, on: sprite)
            },
            .run { [weak node] in
                if let node { setLight(SIMD4(0, 0, 1, 1), on: node) }
            }
        ]), withKey: actionKey)
    }

    static func prepareFlight(_ node: SKSpriteNode, identity: StarCast.Identity, direction: CGFloat) {
        let response = profile(identity).response, sign = Float(direction)
        animate(node, duration: StarfallMotion.flightDuration) { t in
            let trail = sin(t * .pi)
            return SIMD4(-sign * 0.035 * trail * response, 0.085 * trail * response,
                         1 - 0.12 * trail, 1 + 0.24 * trail)
        }
    }
    static func land(_ node: SKSpriteNode, identity: StarCast.Identity, direction: CGFloat) {
        let response = profile(identity).response, sign = Float(direction)
        animate(node, duration: 0.32) { t in
            let gather = sin(t * .pi * 2) * pow(1 - t, 1.6) * response
            return SIMD4(sign * 0.025 * gather, -0.12 * gather,
                         1 + 0.22 * abs(gather), 1 - 0.15 * abs(gather))
        }
    }
    static func respond(_ node: SKSpriteNode, identity: StarCast.Identity,
                        direction: CGFloat, impulse: CGVector) {
        let response = profile(identity).response
        let dx = Float(abs(impulse.dx) > 0.001 ? -impulse.dx : direction * 0.075)
        let dy = Float(-impulse.dy)
        animate(node, duration: 0.58) { t in
            let gather = sin(t * .pi * 2.2) * pow(1 - t, 1.8) * response
            return SIMD4(dx * gather, dy * gather, 1 + abs(gather) * 0.20, 1 - abs(gather) * 0.08)
        }
    }
    static func attend(_ node: SKSpriteNode, identity: StarCast.Identity, direction: CGFloat) {
        let response = profile(identity).response
        animate(node, duration: 0.62) { t in
            let gather = sin(t * .pi) * response
            return SIMD4(Float(direction) * 0.055 * gather, 0.025 * gather,
                         1 - 0.10 * gather, 1 + 0.12 * gather)
        }
    }

    // Source and mask textures use the same UVs as the sprite's shallow warp, so
    // the light cannot escape a concave rim as the shell turns. No time-based idle loop.
    private static let shaderSource = """
    void main() {
        vec2 uv = v_tex_coord;
        vec4 shell = texture2D(u_shell, uv);
        float mask = texture2D(u_mask, uv).a;
        vec2 delta = (uv - u_center - a_light.xy) / a_light.zw;
        vec2 d = vec2(delta.x + delta.y * 0.18, delta.y * 1.12);
        float energy = exp(-dot(d, d) * 24.0);
        vec3 radiance = mix(u_tint, u_warm, energy * 0.86);
        float alpha = (0.72 + 0.23 * energy) * mask;
        vec4 light = vec4(radiance * alpha, alpha);
        vec4 color = shell + light * (1.0 - shell.a);
        float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
        vec2 edgeStep = vec2(0.009);
        float neighbor = min(min(texture2D(u_mask, uv + vec2(edgeStep.x, 0.0)).a,
                                 texture2D(u_mask, uv - vec2(edgeStep.x, 0.0)).a),
                             min(texture2D(u_mask, uv + vec2(0.0, edgeStep.y)).a,
                                 texture2D(u_mask, uv - vec2(0.0, edgeStep.y)).a));
        float rim = smoothstep(0.08, 0.45, mask - neighbor);
        vec3 drained = mix(vec3(luminance * 0.62 + color.a * 0.06), color.rgb, rim * 0.9);
        color.rgb = mix(color.rgb, drained, a_drain);
        float body = smoothstep(0.10, 0.42, luminance);
        vec3 purple = u_corruption.rgb * (0.35 + luminance * 0.90) * color.a;
        float edge = length((uv - vec2(0.5)) * 2.0);
        float front = smoothstep(0.70 - a_pressure * 0.60, 0.90 - a_pressure * 0.60, edge);
        color.rgb = mix(color.rgb, purple, body * front * 0.88 * step(0.001, a_pressure));
        gl_FragColor = color * v_color_mix;
    }
    """
}
