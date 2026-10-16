import XCTest
import SpriteKit
import UIKit
import StarfallCore
@testable import Starfall

/// Hosted Apple tests. Pixel fixtures exercise the loader, not a visual approval.
final class StarshardArtworkTests: XCTestCase {
    @MainActor func testBundledAquaFramesBoundsScaleAndTilt() throws {
        let loader = StarshardArtwork()
        let frames = try XCTUnwrap(loader.frames(for: .aqua))
        XCTAssertEqual(frames.textures.count, 9)
        for texture in frames.textures {
            XCTAssertEqual(texture.size(), CGSize(width: 256, height: 256))
            XCTAssertEqual(texture.filteringMode, .linear)
            XCTAssertFalse(texture.usesMipmaps)
        }
        XCTAssertEqual(frames.fragments.count, 4)
        for texture in frames.fragments {
            XCTAssertEqual(texture.size(), CGSize(width: 128, height: 128))
            XCTAssertEqual(texture.filteringMode, .linear)
            XCTAssertFalse(texture.usesMipmaps)
        }
        XCTAssertEqual(Set(frames.textures.map(ObjectIdentifier.init)).count, 9)
        XCTAssertTrue(frames.neutralFrame === frames.textures[4])
        XCTAssertEqual(frames.neutralAlphaBounds, CGRect(x: 34, y: 34, width: 188, height: 188))
        XCTAssertEqual(frames.motionAlphaBounds, frames.neutralAlphaBounds)
        XCTAssertEqual(frames.canvasSide(radius: 94), 256, accuracy: 0.001)
        XCTAssertEqual(frames.canvasSide(radius: 17) * 188 / 256, 34, accuracy: 0.001)
        XCTAssertEqual(frames.maximumVisibleSize(radius: 17).width, 34, accuracy: 0.001)
        XCTAssertEqual(frames.maximumVisibleSize(radius: 17).height, 34, accuracy: 0.001)
        let tilt = frames.tiltSequence()
        XCTAssertEqual(tilt.count, StarshardArtwork.tiltFrameIndices.count)
        for (texture, index) in zip(tilt, StarshardArtwork.tiltFrameIndices) {
            XCTAssertTrue(texture === frames.textures[index])
        }
        XCTAssertTrue(try XCTUnwrap(tilt.first) === frames.neutralFrame)
        XCTAssertTrue(try XCTUnwrap(tilt.last) === frames.neutralFrame)
        XCTAssertEqual(frames.tiltSequence(reduceMotion: true).count, 1)
        XCTAssertTrue(frames.tiltSequence(reduceMotion: true)[0] === frames.neutralFrame)
        for (texture, index) in zip(frames.clearTiltSequence(), StarshardArtwork.clearTiltFrameIndices) {
            XCTAssertTrue(texture === frames.textures[index])
        }
        for radius in [CGFloat(0), -1, .infinity, .nan] {
            XCTAssertEqual(frames.canvasSide(radius: radius), 0)
        }
    }

    @MainActor func testAllFiveRequiredBundledKindsConform() throws {
        let loader = StarshardArtwork()
        let expectedSizes: [Jewel: CGSize] = [
            .rose: CGSize(width: 183, height: 182), .aqua: CGSize(width: 188, height: 188),
            .amber: CGSize(width: 162, height: 143), .violet: CGSize(width: 176, height: 196),
            .mint: CGSize(width: 144, height: 144)
        ]
        for kind in Jewel.allCases {
            _ = try XCTUnwrap(UIImage(named: StarshardArtwork.assetName(for: kind))?.cgImage,
                              "The family pilot requires the real packaged asset for \(kind)")
            let frames = try XCTUnwrap(loader.frames(for: kind))
            XCTAssertEqual(frames.textures.count, StarshardArtwork.frameCount)
            for texture in frames.textures { XCTAssertEqual(texture.size(), CGSize(width: 256, height: 256)) }
            XCTAssertTrue(frames.motionAlphaBounds.contains(frames.neutralAlphaBounds))
            XCTAssertEqual(frames.neutralAlphaBounds.size, try XCTUnwrap(expectedSizes[kind]))
            XCTAssertEqual(frames.fragments.count, 4)
            for texture in frames.fragments { XCTAssertEqual(texture.size(), CGSize(width: 128, height: 128)) }
            let visibleSide = max(frames.neutralAlphaBounds.width, frames.neutralAlphaBounds.height)
            XCTAssertEqual(frames.canvasSide(radius: 17) * visibleSide / 256, 34, accuracy: 0.001)
            if kind == .amber {
                XCTAssertEqual(abs(frames.neutralAlphaBounds.midY - 128), 19.5, accuracy: 0.001)
            }
        }
        XCTAssertEqual(loader.cachedKindCount, 5)
        XCTAssertEqual(loader.cachedTextureCount, 65)
    }

    @MainActor func testFiveNamesAreDistinctAndAllRequestsStayWithinCacheBudget() throws {
        var images: [String: CGImage] = [:]
        for kind in Jewel.allCases {
            let name = StarshardArtwork.assetName(for: kind)
            images[name] = try XCTUnwrap(UIImage(named: name)?.cgImage)
        }
        var requests: [String] = []
        let loader = StarshardArtwork { name in requests.append(name); return images[name] }
        var first: [Jewel: StarshardArtwork.FrameSet] = [:]
        for kind in Jewel.allCases { first[kind] = try XCTUnwrap(loader.frames(for: kind)) }
        for _ in 0..<49 {
            for kind in Jewel.allCases {
                let frames = try XCTUnwrap(loader.frames(for: kind))
                XCTAssertTrue(frames === first[kind])
                XCTAssertTrue(frames.neutralFrame === first[kind]?.neutralFrame)
                _ = frames.tiltSequence()
            }
        }
        XCTAssertEqual(Set(requests), Set(Jewel.allCases.map(StarshardArtwork.assetName)))
        XCTAssertEqual(requests.count, 5)
        XCTAssertEqual(loader.cachedKindCount, 5)
        XCTAssertEqual(loader.cachedTextureCount, 65)
        XCTAssertEqual(loader.cachedTextureCount, StarshardArtwork.maximumTextureCount)
        XCTAssertEqual(StarshardArtwork.maximumFrameTextureCount, 45)
        XCTAssertEqual(StarshardArtwork.maximumDecodedTextureBytes, 13_107_200)
        let allTextures = first.values.flatMap { $0.textures + $0.fragments }
        XCTAssertEqual(Set(allTextures.map(ObjectIdentifier.init)).count, 65)
    }

    @MainActor func testPilotArgumentIsExplicitAndDebugOnly() {
        XCTAssertFalse(StarshardArtwork.isFamilyPilotEnabled(arguments: []))
        XCTAssertFalse(StarshardArtwork.isFamilyPilotEnabled(arguments: ["--crystal-pilot"]))
        #if DEBUG
        XCTAssertTrue(StarshardArtwork.isFamilyPilotEnabled(arguments: ["--starshard-family-pilot"]))
        #else
        XCTAssertFalse(StarshardArtwork.isFamilyPilotEnabled(arguments: ["--starshard-family-pilot"]))
        #endif
    }

    @MainActor func testMissingArtIsCachedWithoutPlaceholderOrRepeatedReads() {
        var requests = 0
        let loader = StarshardArtwork { _ in requests += 1; return nil }
        for _ in 0..<3 { for kind in Jewel.allCases { XCTAssertNil(loader.frames(for: kind)) } }
        XCTAssertEqual(requests, 5)
        XCTAssertEqual(loader.cachedKindCount, 5)
        XCTAssertEqual(loader.cachedTextureCount, 0)
    }

    @MainActor func testWrongDimensionsFailBeforeCreatingTexturesAndAreCached() throws {
        let aqua = try XCTUnwrap(UIImage(named: "StarshardFamilyAqua")?.cgImage)
        let oneFrame = try XCTUnwrap(aqua.cropping(to: CGRect(x: 0, y: 0, width: 256, height: 256)))
        var requests = 0
        let loader = StarshardArtwork { _ in requests += 1; return oneFrame }
        XCTAssertNil(loader.frames(for: .aqua))
        XCTAssertNil(loader.frames(for: .aqua))
        XCTAssertEqual(requests, 1)
        XCTAssertEqual(loader.cachedTextureCount, 0)
    }

    @MainActor func testEmptyOrEdgeClippedFrameRejectsWholeAtlas() throws {
        for invalidIndex in [0, 4, 8] {
            for clipped in [false, true] {
                let atlas = try pixelFixture(invalidIndex: invalidIndex, clipped: clipped)
                let loader = StarshardArtwork { _ in atlas }
                XCTAssertNil(loader.frames(for: .aqua))
                XCTAssertEqual(loader.cachedTextureCount, 0)
            }
        }
    }

    @MainActor func testScaleUsesNeutralBoundsAndMotionUnionWithoutTrimming() throws {
        let atlas = try pixelFixture()
        let loader = StarshardArtwork { _ in atlas }
        let frames = try XCTUnwrap(loader.frames(for: .aqua))
        XCTAssertEqual(frames.neutralAlphaBounds.size, CGSize(width: 128, height: 128))
        XCTAssertEqual(frames.motionAlphaBounds.size, CGSize(width: 192, height: 192))
        XCTAssertEqual(frames.canvasSide(radius: 17), 68, accuracy: 0.001)
        XCTAssertEqual(frames.maximumVisibleSize(radius: 17), CGSize(width: 51, height: 51))
        XCTAssertEqual(frames.neutralFrame.size(), CGSize(width: 256, height: 256))
    }

    /// Simple alpha rectangles for malformed-atlas/measurement tests, never shipped art.
    private func pixelFixture(invalidIndex: Int? = nil, clipped: Bool = false) throws -> CGImage {
        let side = 256, width = side * 9
        var pixels = [UInt8](repeating: 0, count: width * side * 4)
        for index in 0..<9 {
            if index == invalidIndex && !clipped { continue }
            let inset = index == invalidIndex ? 0 : (index == 4 ? 64 : 32)
            for y in inset..<(side - inset) { for x in inset..<(side - inset) {
                let offset = (y * width + index * side + x) * 4
                pixels[offset] = 255; pixels[offset + 1] = 255
                pixels[offset + 2] = 255; pixels[offset + 3] = 255
            } }
        }
        let provider = try XCTUnwrap(CGDataProvider(data: Data(pixels) as CFData))
        return try XCTUnwrap(CGImage(width: width, height: side, bitsPerComponent: 8, bitsPerPixel: 32,
                                     bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                     bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                     provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent))
    }
}
