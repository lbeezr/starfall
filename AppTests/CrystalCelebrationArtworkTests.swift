import XCTest
import UIKit
import StarfallCore
@testable import Starfall

final class CrystalCelebrationArtworkTests: XCTestCase {
    @MainActor func testPackagedFamilyHasAllWordsAndTwelveSeparateGlyphs() throws {
        let artwork = CrystalCelebrationArtwork()
        let family = try XCTUnwrap(artwork.family)
        XCTAssertEqual(Set(family.titles.keys), Set(CrystalCelebrationArtwork.Title.allCases))
        XCTAssertEqual(Set(family.glyphs.keys), Set("0123456789+-"))
        XCTAssertEqual(artwork.loadAttempts, 1)
        artwork.prewarm(); artwork.prewarm()
        XCTAssertEqual(artwork.loadAttempts, 1)
        for title in CrystalCelebrationArtwork.Title.allCases {
            let image = try XCTUnwrap(family.titles[title]?.cgImage)
            XCTAssertGreaterThan(image.width, image.height)
            XCTAssertGreaterThan(image.height, 100)
            XCTAssertNotNil(ArtworkRaster.alphaBounds(in: image, threshold: 160))
        }
        for symbol in CrystalCelebrationArtwork.glyphOrder {
            let glyph = try XCTUnwrap(family.glyphs[symbol]?.cgImage)
            XCTAssertGreaterThan(glyph.width, 40)
            XCTAssertGreaterThan(glyph.height, 40)
            XCTAssertLessThan(glyph.width, 362, "\(symbol): registration must not include a neighboring glyph")
            XCTAssertLessThan(glyph.height, 400)
        }
    }

    @MainActor func testMissingOrMalformedArtFallsBackAsOneFamilyAndCachesFailure() {
        for missing in ["CelebrationSquare", "CelebrationGlyphs"] {
            var requests: [String] = []
            let artwork = CrystalCelebrationArtwork { name in
                requests.append(name)
                return name == missing ? nil : UIImage(named: name)?.cgImage
            }
            XCTAssertNil(artwork.family)
            let initial = requests
            artwork.prewarm(); XCTAssertNil(artwork.family)
            XCTAssertEqual(requests, initial)
            XCTAssertEqual(artwork.loadAttempts, 1)
        }
        let tiny = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        XCTAssertNil(CrystalCelebrationArtwork(imageProvider: { _ in tiny.cgImage }).family)
    }

    @MainActor func testAwardCompositionPreservesEveryDigitAndRepeatedGlyphIdentity() throws {
        let family = try XCTUnwrap(CrystalCelebrationArtwork().family)
        for value in [1, 3, 12, 21, 111, 999999] {
            let glyphs = try XCTUnwrap(family.award(value))
            XCTAssertEqual(glyphs.count, "+\(value)".count)
            XCTAssertEqual(Set(glyphs.map(\.id)).count, glyphs.count)
            XCTAssertEqual(glyphs.map(\.id), family.award(value)?.map(\.id))
        }
        XCTAssertNil(family.award(0)); XCTAssertNil(family.award(-1))
        XCTAssertNil(family.award(Int.max), "Very long awards use exact native text rather than truncated art")
    }

    @MainActor func testRasterBoundsUseSourceCoordinatesAndIgnoreTransparentFringe() throws {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 16), format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 3, y: 2, width: 7, height: 5))
            UIColor.white.withAlphaComponent(0.01).setFill(); context.fill(CGRect(x: 20, y: 13, width: 1, height: 1))
        }
        let cg = try XCTUnwrap(image.cgImage)
        XCTAssertEqual(ArtworkRaster.alphaBounds(in: cg, threshold: 160), CGRect(x: 3, y: 2, width: 7, height: 5))
        XCTAssertEqual(ArtworkRaster.alphaBounds(in: cg), CGRect(x: 3, y: 2, width: 18, height: 12))
    }
}
