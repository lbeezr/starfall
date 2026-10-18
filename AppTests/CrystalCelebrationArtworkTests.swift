import XCTest
import UIKit
import SwiftUI
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

    @MainActor func testOpalMaterialRendersMultipleFacetColorsAndReadableFamilySheet() async throws {
        let family = try XCTUnwrap(CrystalCelebrationArtwork().family)
        let glyph = try XCTUnwrap(family.glyphs["8"])
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let host = UIHostingController(rootView: AnyView(Color.black))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
        host.rootView = AnyView(CrystalCelebrationMaterial(image: glyph, tint: .white)
            .frame(width: 220, height: 260).frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.black))
        var bins = Set<Int>()
        let deadline = ContinuousClock.now + .seconds(3)
        repeat {
            await Task.yield(); host.view.layoutIfNeeded()
            let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            let cg = try XCTUnwrap(image.cgImage)
            var pixels = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
            let context = try XCTUnwrap(CGContext(data: &pixels, width: cg.width, height: cg.height,
                bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            var counts: [Int: Int] = [:]
            for i in stride(from: 0, to: pixels.count, by: 4) {
                let r = CGFloat(pixels[i]) / 255, g = CGFloat(pixels[i+1]) / 255, b = CGFloat(pixels[i+2]) / 255
                guard max(r, g, b) > 0.35, max(r, g, b) - min(r, g, b) > 0.12 else { continue }
                var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = 0, a: CGFloat = 0
                UIColor(red: r, green: g, blue: b, alpha: 1).getHue(&h, saturation: &s, brightness: &v, alpha: &a)
                counts[min(5, Int(h * 6)), default: 0] += 1
            }
            bins = Set(counts.filter { $0.value > 100 }.keys)
            if bins.count < 3 { try await Task.sleep(for: .milliseconds(20)) }
        } while bins.count < 3 && ContinuousClock.now < deadline
        XCTAssertGreaterThanOrEqual(bins.count, 3, "A pearl glyph needs warm and cool refracted faces, not a uniform tint")

        let colors = [Jewel.aqua, .amber, .mint, .rose, .violet].map { Color($0.color) } + [.white]
        let names = ["Aqua", "Amber", "Mint", "Rose", "Violet", "Pearl"]
        host.rootView = AnyView(VStack(spacing: 16) {
            Text("STARFALL · NATIVE MATERIAL STUDY").font(.caption).foregroundStyle(.white)
            Text("Earlier tint").font(.headline).foregroundStyle(.white)
            swatches(false)
            Text("Opalescent facet light").font(.headline).foregroundStyle(.white)
            swatches(true)
            HStack(spacing: 3) {
                ForEach(Array("0123456789"), id: \.self) { character in
                    CrystalCelebrationMaterial(image: family.glyphs[character]!, tint: .white)
                        .frame(width: 30, height: 42)
                }
            }
            CrystalCelebrationMaterial(image: family.titles[.brilliant]!, tint: colors[1])
                .frame(width: 330, height: 76)
            CrystalCelebrationMaterial(image: family.titles[.constellation]!, tint: colors[0])
                .frame(width: 330, height: 76)
        }.padding(.vertical, 35).frame(width: 390, height: 844).background(StarfallTheme.Colors.skyTop))
        func swatches(_ opal: Bool) -> some View {
            VStack(spacing: 10) {
                ForEach(0..<2) { row in
                    HStack(spacing: 16) {
                        ForEach(0..<3) { column in
                            let tint = colors[row * 3 + column]
                            VStack(spacing: 2) {
                              HStack(spacing: 2) {
                                ForEach(Array("+8"), id: \.self) { c in
                                    let image = family.glyphs[c]!
                                    if opal {
                                        CrystalCelebrationMaterial(image: image, tint: tint).frame(width: 42, height: 64)
                                    } else {
                                        ZStack {
                                            Image(uiImage: image).resizable().scaledToFit().colorMultiply(tint)
                                            Image(uiImage: image).resizable().scaledToFit().blendMode(.screen).opacity(0.55)
                                        }.compositingGroup().frame(width: 42, height: 64)
                                    }
                                }
                              }
                              Text(names[row * 3 + column]).font(.caption2).foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
        }
        host.view.layoutIfNeeded()
        let rendered = expectation(description: "Material sheet reached the native display")
        DispatchQueue.main.async { rendered.fulfill() }
        await fulfillment(of: [rendered], timeout: 3)
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = "opal-material-six-family-comparison"; attachment.lifetime = .keepAlways; add(attachment)
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
