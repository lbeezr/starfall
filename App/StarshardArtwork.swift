import SpriteKit
import UIKit
import StarfallCore

/// Cached offline artwork, activated only by the scene's DEBUG family pilot.
/// Original crystals are rendered offline; runtime work is bounded decoding/cropping.
@MainActor final class StarshardArtwork {
    static let shared = StarshardArtwork()
    static let frameSide = 256
    static let frameCount = 9
    static let neutralIndex = 4
    static let fragmentCount = 4
    static let fragmentSide = frameSide / 2
    static let maximumShards = 48
    // A short touch response that returns to neutral; never an idle animation.
    static let tiltFrameIndices = [4, 3, 2, 1, 2, 3, 4]
    static let clearTiltFrameIndices = [4, 3, 2, 1]
    static let tiltTimePerFrame: TimeInterval = 0.015
    static let maximumFrameTextureCount = Jewel.allCases.count * frameCount
    static let maximumTextureCount = Jewel.allCases.count * (frameCount + fragmentCount)
    // RGBA8 base levels only; excludes driver copies, UIKit source caches and mipmaps.
    static let maximumDecodedTextureBytes = Jewel.allCases.count
        * (frameCount * frameSide * frameSide + fragmentCount * fragmentSide * fragmentSide) * 4

    static func isFamilyPilotEnabled(arguments: [String]) -> Bool {
        #if DEBUG
        return arguments.contains("--starshard-family-pilot")
        #else
        return false
        #endif
    }

    static func assetName(for kind: Jewel) -> String {
        switch kind {
        case .rose: return "StarshardFamilyRose"
        case .aqua: return "StarshardFamilyAqua"
        case .amber: return "StarshardFamilyAmber"
        case .violet: return "StarshardFamilyViolet"
        case .mint: return "StarshardFamilyMint"
        }
    }

    @MainActor final class FrameSet {
        let textures: [SKTexture]
        let fragments: [SKTexture]
        /// Nonzero-alpha bounds in the untrimmed neutral frame's raster coordinates.
        let neutralAlphaBounds: CGRect
        /// Union of nonzero-alpha bounds across all nine frames, for spacing review.
        let motionAlphaBounds: CGRect
        var neutralFrame: SKTexture { textures[StarshardArtwork.neutralIndex] }

        fileprivate init(textures: [SKTexture], fragments: [SKTexture],
                         neutralAlphaBounds: CGRect, motionAlphaBounds: CGRect) {
            self.textures = textures
            self.fragments = fragments
            self.neutralAlphaBounds = neutralAlphaBounds
            self.motionAlphaBounds = motionAlphaBounds
        }

        /// Normalize each kind's longest neutral silhouette dimension to 2 × radius.
        /// Keep the full canvas and a (0.5, 0.5) sprite anchor throughout the tilt.
        func canvasSide(radius: CGFloat) -> CGFloat {
            guard radius.isFinite, radius > 0 else { return 0 }
            return radius * 2 * CGFloat(StarshardArtwork.frameSide)
                / max(neutralAlphaBounds.width, neutralAlphaBounds.height)
        }

        func maximumVisibleSize(radius: CGFloat) -> CGSize {
            let scale = canvasSide(radius: radius) / CGFloat(StarshardArtwork.frameSide)
            return CGSize(width: motionAlphaBounds.width * scale, height: motionAlphaBounds.height * scale)
        }

        /// Calm effects / Reduce Motion gets the settled frame and no tilt.
        func tiltSequence(reduceMotion: Bool = false) -> [SKTexture] {
            let indices = reduceMotion ? [StarshardArtwork.neutralIndex] : StarshardArtwork.tiltFrameIndices
            return indices.map { textures[$0] }
        }

        func clearTiltSequence() -> [SKTexture] {
            StarshardArtwork.clearTiltFrameIndices.map { textures[$0] }
        }
    }

    private enum Cached {
        case available(FrameSet)
        case unavailable
    }
    private let imageProvider: (String) -> CGImage?
    private var cache: [Jewel: Cached] = [:]

    init(imageProvider: @escaping (String) -> CGImage? = { UIImage(named: $0)?.cgImage }) {
        self.imageProvider = imageProvider
    }

    /// Both success and failure are cached per kind for this loader's lifetime.
    /// Missing or invalid art returns nil so the caller can keep its existing material.
    func frames(for kind: Jewel) -> FrameSet? {
        if let cached = cache[kind] {
            if case .available(let frames) = cached { return frames }
            return nil
        }
        let frames = imageProvider(Self.assetName(for: kind)).flatMap(Self.decode)
        cache[kind] = frames.map(Cached.available) ?? .unavailable
        return frames
    }

    // Read-only diagnostics; there is no eviction/reload loop that can churn textures.
    var cachedKindCount: Int { cache.count }
    var cachedTextureCount: Int {
        cache.values.reduce(0) { count, entry in
            if case .available(let frames) = entry { return count + frames.textures.count + frames.fragments.count }
            return count
        }
    }

    private static func decode(_ atlas: CGImage) -> FrameSet? {
        guard atlas.width == frameSide * frameCount, atlas.height == frameSide else { return nil }
        var crops: [CGImage] = []
        var bounds: [CGRect] = []
        let paddedInterior = CGRect(x: 1, y: 1, width: CGFloat(frameSide - 2), height: CGFloat(frameSide - 2))
        for index in 0..<frameCount {
            let rect = CGRect(x: CGFloat(index * frameSide), y: 0,
                              width: CGFloat(frameSide), height: CGFloat(frameSide))
            guard let crop = atlas.cropping(to: rect),
                  let alpha = alphaBounds(in: crop), paddedInterior.contains(alpha) else { return nil }
            crops.append(crop)
            bounds.append(alpha)
        }
        // Separate textures, never SKTexture(rect:in:): linear filtering cannot sample
        // the neighboring atlas cell. Preserve transparent padding; do not auto-trim.
        var fragmentCrops: [CGImage] = []
        for index in 0..<fragmentCount {
            let rect = CGRect(x: CGFloat((index % 2) * fragmentSide),
                              y: CGFloat((index / 2) * fragmentSide),
                              width: CGFloat(fragmentSide), height: CGFloat(fragmentSide))
            guard let crop = crops[neutralIndex].cropping(to: rect) else { return nil }
            fragmentCrops.append(crop)
        }
        func texture(_ crop: CGImage) -> SKTexture {
            let texture = SKTexture(cgImage: crop)
            texture.filteringMode = .linear
            texture.usesMipmaps = false
            return texture
        }
        return FrameSet(textures: crops.map(texture), fragments: fragmentCrops.map(texture),
                        neutralAlphaBounds: bounds[neutralIndex],
                        motionAlphaBounds: bounds.reduce(CGRect.null) { $0.union($1) })
    }

    private static func alphaBounds(in image: CGImage) -> CGRect? {
        let side = frameSide
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        return pixels.withUnsafeMutableBytes { bytes -> CGRect? in
            guard let context = CGContext(data: bytes.baseAddress, width: side, height: side,
                                          bitsPerComponent: 8, bytesPerRow: side * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue
                                            | CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
            context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(side), height: CGFloat(side)))
            var minX = side, minY = side, maxX = -1, maxY = -1
            for y in 0..<side { for x in 0..<side where bytes[(y * side + x) * 4 + 3] != 0 {
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            } }
            guard maxX >= minX, maxY >= minY else { return nil }
            return CGRect(x: CGFloat(minX), y: CGFloat(minY),
                          width: CGFloat(maxX - minX + 1), height: CGFloat(maxY - minY + 1))
        }
    }
}
