import SwiftUI
import UIKit
import XCTest
@testable import Starfall

final class ObservatoryArtworkTests: XCTestCase {
    @MainActor func testEveryAuthoredGlyphLoadsAsRegisteredTemplate() throws {
        XCTAssertEqual(ObservatoryGlyph.allCases.count, 20)
        for glyph in ObservatoryGlyph.allCases {
            let image = try XCTUnwrap(UIImage(named: glyph.assetName), glyph.assetName)
            XCTAssertEqual(image.size, CGSize(width: 24, height: 24), glyph.assetName)
            XCTAssertEqual(image.renderingMode, .alwaysTemplate, glyph.assetName)
            try assertTransparentFrameAndVisibleInk(image, name: glyph.assetName)
        }
    }

    @MainActor func testRasterDensitySelectionPreservesPointRegistration() throws {
        let assets = ObservatoryMode.allCases.map { ($0.assetName, CGSize(width: 48, height: 48)) }
            + ObservatorySkin.allCases.map { ($0.assetName, $0.pointSize) }
        for (name, size) in assets {
            for scale in [CGFloat(1), 2, 3] {
                let traits = UITraitCollection(displayScale: scale)
                let image = try XCTUnwrap(UIImage(named: name, in: .main, compatibleWith: traits), name)
                XCTAssertEqual(image.size, size, name)
                // Target-specific catalogs may contain only the device's density.
                // A trait request can select that retained rendition; it cannot
                // recreate a thinned 1x/2x source. Verify its real registration.
                XCTAssertTrue([CGFloat(1), 2, 3].contains(image.scale), name)
                let backing = try XCTUnwrap(image.cgImage, name)
                XCTAssertEqual(CGFloat(backing.width), size.width * image.scale, name)
                XCTAssertEqual(CGFloat(backing.height), size.height * image.scale, name)
                XCTAssertNotEqual(image.renderingMode, .alwaysTemplate, name)
                try assertTransparentFrameAndVisibleInk(image, name: name)
            }
        }
    }

    @MainActor func testActionsGrowForLargeTextWithoutShrinkingTheirLabel() {
        func size(_ title: String, textSize: DynamicTypeSize) -> CGSize {
            let view = Button(title) { }
                .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))
                .environment(\.dynamicTypeSize, textSize)
            return UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: 240, height: 2_000))
        }
        let regular = size("Resume", textSize: .large)
        let wrapped = size("Continue exploring the Observatory", textSize: .accessibility5)
        XCTAssertEqual(regular.width, 240, accuracy: 1)
        XCTAssertGreaterThanOrEqual(regular.height, 52)
        XCTAssertEqual(wrapped.width, 240, accuracy: 1)
        XCTAssertGreaterThanOrEqual(wrapped.height, 80)
        XCTAssertGreaterThan(wrapped.height, regular.height)
    }

    @MainActor private func assertTransparentFrameAndVisibleInk(_ image: UIImage, name: String) throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let size = image.size
        let rendered = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.withRenderingMode(.alwaysOriginal).draw(in: CGRect(origin: .zero, size: size))
        }
        let cgImage = try XCTUnwrap(rendered.cgImage, name)
        let width = cgImage.width
        let height = cgImage.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let alpha = CGImageAlphaInfo.premultipliedLast.rawValue
        try pixels.withUnsafeMutableBytes { buffer in
            let context = try XCTUnwrap(CGContext(data: buffer.baseAddress, width: width, height: height,
                                                 bitsPerComponent: 8, bytesPerRow: width * 4,
                                                 space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: alpha), name)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        }
        XCTAssertTrue(stride(from: 3, to: pixels.count, by: 4).contains { pixels[$0] > 0 }, name)
        for x in 0..<width {
            XCTAssertEqual(pixels[x * 4 + 3], 0, "\(name) top")
            XCTAssertEqual(pixels[((height - 1) * width + x) * 4 + 3], 0, "\(name) bottom")
        }
        for y in 0..<height {
            XCTAssertEqual(pixels[(y * width) * 4 + 3], 0, "\(name) left")
            XCTAssertEqual(pixels[(y * width + width - 1) * 4 + 3], 0, "\(name) right")
        }
    }
}
