import SwiftUI
import UIKit
import XCTest
@testable import Starfall

final class ObservatoryArtworkTests: XCTestCase {
    @MainActor func testEveryRenderedGlyphLoadsAsRegisteredOriginalArtwork() throws {
        XCTAssertEqual(ObservatoryGlyph.allCases.count, 20)
        for glyph in ObservatoryGlyph.allCases {
            let image = try XCTUnwrap(UIImage(named: glyph.assetName), glyph.assetName)
            XCTAssertEqual(image.size, CGSize(width: 24, height: 24), glyph.assetName)
            XCTAssertEqual(image.renderingMode, .alwaysOriginal, glyph.assetName)
            try assertTransparentFrameAndVisibleInk(image, name: glyph.assetName)
        }
    }

    @MainActor func testRasterDensitySelectionPreservesPointRegistration() throws {
        let assets = ObservatoryGlyph.allCases.map { ($0.assetName, CGSize(width: 24, height: 24)) }
            + ObservatoryMode.allCases.map { ($0.assetName, CGSize(width: 48, height: 48)) }
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
        func size(_ title: String, textSize: DynamicTypeSize,
                  role: StarfallButtonStyle.Role = .primary, enabled: Bool = true) -> CGSize {
            let view = Button(title) { }
                .buttonStyle(StarfallButtonStyle(role: role, expands: true))
                .disabled(!enabled)
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

        for role in [StarfallButtonStyle.Role.primary, .compact, .secondary] {
            let ordinary = role == .primary ? regular : size("Resume", textSize: .large, role: role)
            let accessible = size("Resume", textSize: .accessibility5, role: role)
            let longTitle = "Continue exploring the Observatory"
            let longAccessible = role == .primary ? wrapped : size(longTitle, textSize: .accessibility5, role: role)
            XCTAssertGreaterThan(accessible.height, ordinary.height, "\(role) must honor larger text")
            XCTAssertGreaterThan(longAccessible.height, accessible.height,
                                 "\(role) must wrap a long label at the same text size")

            let variants: [(String, DynamicTypeSize, CGSize)] = [
                ("Resume", .large, ordinary),
                ("Resume", .accessibility5, accessible),
                (longTitle, .accessibility5, longAccessible)
            ]
            for (title, textSize, enabledSize) in variants {
                let context = "\(role), \(textSize), \(title)"
                XCTAssertEqual(enabledSize.width, 240, accuracy: 1, context)
                XCTAssertGreaterThanOrEqual(enabledSize.height, 48, context)
                XCTAssertEqual(size(title, textSize: textSize, role: role, enabled: false), enabledSize,
                               "Disabling an action must preserve its geometry: \(context)")
                if role != .primary {
                    let pair = HStack(alignment: .top, spacing: 12) {
                        ForEach([true, false], id: \.self) { enabled in
                            VStack(spacing: 8) {
                                Text(enabled ? "Enabled" : "Disabled")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                                Button(title) { }
                                    .buttonStyle(StarfallButtonStyle(role: role, expands: true))
                                    .disabled(!enabled)
                            }
                            .frame(width: 240)
                        }
                    }
                    .padding(12)
                    .background(StarfallTheme.Colors.skyTop)
                    .environment(\.dynamicTypeSize, textSize)
                    .environment(\.colorScheme, .dark)
                    let renderer = ImageRenderer(content: pair)
                    renderer.scale = 2
                    guard let image = renderer.uiImage else {
                        XCTFail("Could not render production action states: \(context)")
                        continue
                    }
                    let attachment = XCTAttachment(image: image)
                    let category = textSize == .large ? "default" : "AX5"
                    let length = title == "Resume" ? "short" : "long"
                    attachment.name = "observatory-action-\(role)-\(category)-\(length)-enabled-disabled"
                    attachment.lifetime = .keepAlways
                    add(attachment)
                }
            }
        }

        func fitted<Content: View>(_ content: Content, textSize: DynamicTypeSize) -> CGSize {
            let host = UIHostingController(rootView: content.environment(\.dynamicTypeSize, textSize))
            host.safeAreaRegions = []
            let result = host.sizeThatFits(in: CGSize(width: 240, height: 2_000))
            XCTAssertTrue(result.width.isFinite && result.height.isFinite && result.width > 0 && result.height > 0,
                          "A component measurement must be positive and finite: \(result)")
            return result
        }
        func utility(_ glyph: ObservatoryGlyph, backdrop: StarfallUtilityButtonStyle.Backdrop,
                     enabled: Bool) -> some View {
            Button { } label: {
                // These are the actual forecast Help and viewport Pause call sizes.
                ObservatoryIcon(glyph, size: glyph == .help ? 24 : 20)
            }
            .buttonStyle(StarfallUtilityButtonStyle(backdrop: backdrop))
            .disabled(!enabled)
        }
        func digit(_ column: Int) -> some View {
            Text(String(column)).font(StarfallTheme.Typography.instrumentNumber)
                .monospacedDigit().fixedSize(horizontal: true, vertical: false)
        }
        func forecast(_ column: Int, selected: Bool, enabled: Bool) -> some View {
            Button { } label: { digit(column) }
                .buttonStyle(StarfallGameButtonStyle(role: .forecast(selected: selected)))
                .fixedSize(horizontal: true, vertical: false)
                .disabled(!enabled)
        }
        func specimen<Content: View>(_ content: Content, textSize: DynamicTypeSize, name: String) {
            for scale in [CGFloat(2), 3] {
                let renderer = ImageRenderer(content: content.padding(16)
                    .background(StarfallTheme.Colors.skyTop)
                    .environment(\.dynamicTypeSize, textSize).environment(\.colorScheme, .dark))
                renderer.scale = scale
                guard let image = renderer.uiImage else {
                    XCTFail("Could not render production HUD control states: \(name), \(scale)x")
                    continue
                }
                let attachment = XCTAttachment(image: image)
                attachment.name = "observatory-hud-\(name)-\(textSize == .large ? "default" : "AX5")-\(Int(scale))x"
                attachment.lifetime = .keepAlways; add(attachment)
            }
        }
        for textSize in [DynamicTypeSize.large, .accessibility5] {
            for glyph in [ObservatoryGlyph.help, .pause] {
                for backdrop in [StarfallUtilityButtonStyle.Backdrop.clear, .scenery] {
                    for enabled in [true, false] {
                        let measured = fitted(utility(glyph, backdrop: backdrop, enabled: enabled), textSize: textSize)
                        XCTAssertEqual(measured, CGSize(width: 48, height: 48),
                                       "\(glyph), \(backdrop), enabled=\(enabled), \(textSize): the visual and its state cannot change the full target")
                    }
                }
            }
            for column in 1...7 {
                let nativeDigit = fitted(digit(column), textSize: textSize)
                let resting = fitted(forecast(column, selected: false, enabled: true), textSize: textSize)
                for selected in [false, true] {
                    for enabled in [true, false] {
                        let actual = fitted(forecast(column, selected: selected, enabled: enabled), textSize: textSize)
                        let context = "column=\(column), selected=\(selected), enabled=\(enabled), \(textSize)"
                        XCTAssertGreaterThanOrEqual(actual.width, 44, context)
                        XCTAssertGreaterThanOrEqual(actual.height, 44, context)
                        XCTAssertGreaterThanOrEqual(actual.width, nativeDigit.width, "The complete native digit must fit: \(context)")
                        XCTAssertGreaterThanOrEqual(actual.height, nativeDigit.height, "The complete native digit must fit: \(context)")
                        XCTAssertEqual(actual, resting, "Selection and disabled state preserve geometry: \(context)")
                    }
                }
            }
            let utilities = VStack(alignment: .leading, spacing: 16) {
                ForEach([false, true], id: \.self) { scenic in
                    HStack(alignment: .top, spacing: 24) {
                        Text(scenic ? "Scenery" : "Clear").font(.system(size: 12)).frame(width: 48)
                        ForEach([ObservatoryGlyph.help, .pause], id: \.self) { glyph in
                            VStack(spacing: 8) {
                                Text(glyph == .help ? "Help 24 pt" : "Pause 20 pt").font(.system(size: 12))
                                HStack(alignment: .top, spacing: 12) {
                                    ForEach([true, false], id: \.self) { enabled in
                                        VStack(spacing: 8) {
                                            Text(enabled ? "Enabled" : "Disabled").font(.system(size: 12))
                                            utility(glyph, backdrop: scenic ? .scenery : .clear, enabled: enabled)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }.foregroundStyle(StarfallTheme.Colors.textPrimary)
            specimen(utilities, textSize: textSize, name: "utilities-resting-disabled")
            let forecasts = VStack(alignment: .leading, spacing: 16) {
                ForEach([false, true], id: \.self) { selected in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selected ? "Selected" : "Unselected").font(.system(size: 12))
                        HStack(alignment: .top, spacing: 24) {
                            ForEach([true, false], id: \.self) { enabled in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(enabled ? "Enabled" : "Disabled").font(.system(size: 12))
                                    HStack(alignment: .top, spacing: 8) {
                                        ForEach(1...7, id: \.self) { column in
                                            forecast(column, selected: selected, enabled: enabled)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }.foregroundStyle(StarfallTheme.Colors.textPrimary)
            specimen(forecasts, textSize: textSize, name: "forecast-style-native-digits-resting-disabled")
        }
        let scope = XCTAttachment(string: "Production component specimens: resting and disabled visual geometry only. "
            + "Utility call sizes are Help 24 pt and Pause 20 pt; caption labels are test annotations. "
            + "Forecast style specimens use complete official native digits, not the full five-star forecast composition. "
            + "Supplied disabled environments do not establish genuine busy admission. "
            + "Pressed/cancelled and platform-focused appearance require separate native contact/focus evidence.")
        scope.name = "observatory-hud-control-specimen-scope"; scope.lifetime = .keepAlways; add(scope)
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
