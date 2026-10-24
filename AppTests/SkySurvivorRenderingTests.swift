import XCTest
import SwiftUI
import UIKit
@testable import StarfallCore
@testable import Starfall

final class SkySurvivorRenderingTests: XCTestCase {
    private let board = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let header = CGRect(x: 20, y: 20, width: 350, height: 96)
    private let band = CGRect(x: 20, y: 124, width: 350, height: 80)
    private let offRouteScore = CGRect(x: 330, y: 780, width: 40, height: 36)

    private func phases(_ opening: FallingSky) throws -> [SkyResolutionPhase] {
        var game = opening
        return try XCTUnwrap(game.nudge(from: Cell(1,1), to: Cell(1,2))).resolutionPhases
    }

    private func event(_ phases: [SkyResolutionPhase], index: Int) -> StarlightCelebration {
        let total = phases.prefix(index + 1).reduce(0) { $0 + $1.award.displayPoints }
        return StarlightCelebration(id: UInt64(index + 1), phase: phases[index], cumulativeAward: total,
            total: total, precedingPhases: Array(phases.prefix(index)))
    }

    private func cascade(_ event: StarlightCelebration) throws -> CascadeReturnLayout {
        try XCTUnwrap(CascadeReturnLayout(event: event, board: board, header: header,
                                         award: band, protectedSky: band))
    }

    func testActualTwoAndThreePhaseReceiptsMarkOnlyTheirCurrentMovedOriginals() throws {
        for opening in [FallingSky.fullBoardLantern(), .fullBoardRibbon()] {
            let actual = try phases(opening)
            XCTAssertTrue((2...3).contains(actual.count))
            XCTAssertNil(event(actual, index: 0).survivorIngredients)
            for index in actual.indices.dropFirst() {
                let receipt = event(actual, index: index)
                let ingredients = try XCTUnwrap(receipt.survivorIngredients)
                XCTAssertEqual(ingredients, SkySurvivorIngredients(phases: actual, currentIndex: index))
                let strip = try cascade(receipt)
                XCTAssertEqual(strip.current.patterns, receipt.patterns)
                XCTAssertEqual(strip.preceding.count, index)
                let markers = try XCTUnwrap(SkySurvivorMarkerLayout(ingredients: ingredients,
                    layout: strip.current, age: 0.98, quiet: false))
                XCTAssertEqual(markers.markers.map(\.cell), ingredients.movements.map(\.to))
                XCTAssertEqual(Set(markers.markers.map(\.cell)).count, ingredients.movements.count)
                XCTAssertEqual(ingredients.patterns.map { StarlightCelebration.Pattern(recipe: $0) },
                               strip.current.patterns)
                XCTAssertLessThanOrEqual(markers.markers.count, 49)
                XCTAssertEqual(receipt.packets.count, min(6, receipt.contributors.count))
                XCTAssertEqual(StarlightCelebration.duration, 1.4)
                for marker in markers.markers {
                    XCTAssertTrue(marker.diamond.allSatisfy(strip.current.skyBounds.contains))
                    XCTAssertFalse(strip.labelBounds.contains(marker.center))
                    XCTAssertFalse(header.contains(marker.center))
                }
            }
        }
    }

    func testDiamondsFollowTheSharedCurrentAffineFlightAndQuietUsesTheSameDestination() throws {
        let actual = try phases(.fullBoardRibbon()), receipt = event(actual, index: 2)
        let ingredients = try XCTUnwrap(receipt.survivorIngredients), strip = try cascade(receipt)
        let sourcePaths = strip.current.sourcePaths
        let destinationPaths = strip.current.destinationPaths
        for age in [0.0, 0.32, 0.67, 0.98] {
            let markers = try XCTUnwrap(SkySurvivorMarkerLayout(ingredients: ingredients,
                layout: strip.current, age: age, quiet: false))
            let progress = ConstellationReturnLayout.returnProgress(at: age, quiet: false)
            for marker in markers.markers {
                let recipe = try XCTUnwrap(strip.current.patterns.firstIndex { $0.path.contains(marker.cell) })
                let point = try XCTUnwrap(strip.current.patterns[recipe].path.firstIndex(of: marker.cell))
                let from = sourcePaths[recipe][point], to = destinationPaths[recipe][point]
                XCTAssertEqual(marker.center.x, from.x + (to.x - from.x) * progress, accuracy: 0.000001)
                XCTAssertEqual(marker.center.y, from.y + (to.y - from.y) * progress, accuracy: 0.000001)
                XCTAssertEqual(marker.diamond.count, 5)
                XCTAssertEqual(marker.diamond.first, marker.diamond.last)
                XCTAssertEqual(marker.diamond[0].x, marker.center.x)
                XCTAssertEqual(marker.diamond[1].y, marker.center.y)
                XCTAssertEqual(marker.diamond[2].y - marker.center.y, marker.radius, accuracy: 0.000001)
                XCTAssertEqual(marker.center.x - marker.diamond[3].x, marker.radius, accuracy: 0.000001)
            }
        }
        let normal = try XCTUnwrap(SkySurvivorMarkerLayout(ingredients: ingredients,
            layout: strip.current, age: 0.98, quiet: false))
        let quiet = try XCTUnwrap(SkySurvivorMarkerLayout(ingredients: ingredients,
            layout: strip.current, age: 0, quiet: true))
        XCTAssertEqual(normal.markers.map(\.center), quiet.markers.map(\.center))
        XCTAssertEqual(normal.markers.map(\.diamond), quiet.markers.map(\.diamond))
    }

    /// This is a resolver geometry fixture, not a reachable saved campaign.
    /// One manual bottom-row clear makes all42 original survivors fall, then
    /// the resolver discovers every simultaneous overlapping current recipe.
    func testDenseOverlapsKeepEveryEligibleDiamondOnceAndFitSmallSlotsWithoutTruncation() throws {
        let dense: [StarfallGem?] = (0..<49).map { .init(id: $0, kind: .aqua) }
        let actual = SkyRecipeResolution.resolve(dense, manualClear: Set((0..<7).map { Cell(0,$0) }),
                                                 lineLength: 4)
        XCTAssertEqual(actual.count, 2)
        let receipt = event(actual, index: 1), ingredients = try XCTUnwrap(receipt.survivorIngredients)
        XCTAssertEqual(ingredients.movements.count, 42)
        XCTAssertTrue(ingredients.movements.allSatisfy { $0.recipeIndices.count > 1 })
        let original = try XCTUnwrap(PatternReturnLayout(patterns: receipt.patterns, board: board,
            header: header, award: band, protectedSky: band))
        for width: CGFloat in [24, 60, 112] {
            let slot = CGRect(x: 30, y: 128, width: width, height: 72)
            let layout = try XCTUnwrap(original.fitted(to: slot))
            let markers = try XCTUnwrap(SkySurvivorMarkerLayout(ingredients: ingredients,
                layout: layout, age: 0, quiet: true))
            XCTAssertEqual(markers.markers.count, 42)
            XCTAssertEqual(Set(markers.markers.map(\.cell)).count, 42)
            XCTAssertEqual(layout.patterns.count, receipt.patterns.count)
            for marker in markers.markers {
                XCTAssertTrue(marker.diamond.allSatisfy(slot.contains))
                XCTAssertGreaterThan(marker.radius, 0)
                XCTAssertLessThanOrEqual(marker.radius, 6)
                for other in markers.markers where other.cell != marker.cell {
                    let separation = hypot(other.center.x - marker.center.x, other.center.y - marker.center.y)
                    XCTAssertLessThan(marker.radius + marker.strokeWidth / 2, separation / 2)
                }
            }
        }
    }

    func testMarkersRejectOtherFiguresInvalidAgesAndNeverAppearForAManualWalk() throws {
        let actual = try phases(.fullBoardLantern()), receipt = event(actual, index: 1)
        let ingredients = try XCTUnwrap(receipt.survivorIngredients), layout = try cascade(receipt).current
        for age in [-1, Double.nan, Double.infinity, StarlightCelebration.duration] {
            for quiet in [false, true] {
                XCTAssertNil(SkySurvivorMarkerLayout(ingredients: ingredients, layout: layout,
                                                     age: age, quiet: quiet))
            }
        }
        let earlier = try cascade(event(actual, index: 0)).current
        XCTAssertNil(SkySurvivorMarkerLayout(ingredients: ingredients, layout: earlier, age: 0.5, quiet: false))
        let old = ConstellationFixture.horizontalFive.game(), walk = (0..<5).map { Cell(0,$0) }
        var game = old
        let turn = try XCTUnwrap(game.clearConstellation(walk))
        let manual = try XCTUnwrap(StarlightCelebration(id: 4, turn: turn, from: old,
                                                       total: game.displayScore, path: walk))
        XCTAssertNil(manual.survivorIngredients)
        XCTAssertEqual(manual.constellationPath, walk)
        XCTAssertTrue(manual.patterns.isEmpty)
    }

    @MainActor func testProductionDiamondPassIsUnfilledQuietEquivalentAndClipsMeasuredHUD() throws {
        let actual = try phases(.fullBoardLantern()), receipt = event(actual, index: 1)
        let ingredients = try XCTUnwrap(receipt.survivorIngredients), layout = try cascade(receipt).current
        let marks = try XCTUnwrap(SkySurvivorMarkerLayout(ingredients: ingredients, layout: layout,
                                                       age: 0, quiet: true))
        let normal = try render(receipt, layout: layout, age: 0.98, quiet: false)
        let quiet = try render(receipt, layout: layout, age: 0, quiet: true)
        XCTAssertEqual(normal.pngData(), quiet.pngData(), "Static geometry and ink are identical after arrival")
        XCTAssertGreaterThan(try ink(quiet, in: board), 10)
        for marker in marks.markers {
            let center = CGRect(x: marker.center.x - 0.5, y: marker.center.y - 0.5, width: 1, height: 1)
            XCTAssertEqual(try ink(quiet, in: center), 0, "A diamond ring adds no center fill")
            let bounds = CGRect(x: marker.center.x - marker.radius - 2, y: marker.center.y - marker.radius - 2,
                                width: marker.radius * 2 + 4, height: marker.radius * 2 + 4)
            XCTAssertGreaterThan(try ink(quiet, in: bounds), 0)
        }
        for excluded in [header, layout.labelBounds, offRouteScore] {
            XCTAssertEqual(try ink(quiet, in: excluded), 0)
        }
        let first = try XCTUnwrap(marks.markers.first)
        let coveringScore = CGRect(x: first.center.x - 10, y: first.center.y - 10, width: 20, height: 20)
        let masked = try render(receipt, layout: layout, age: 0, quiet: true, score: coveringScore)
        XCTAssertEqual(try ink(masked, in: coveringScore), 0)
        let expired = try render(receipt, layout: layout, age: 1.4, quiet: false)
        XCTAssertEqual(try ink(expired, in: board), 0)
        for (name, image) in [("normal-arrived-diamonds", normal), ("quiet-same-diamonds", quiet),
                              ("diamonds-hud-exclusion", masked)] {
            let attachment = XCTAttachment(image: image)
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
    }

    @MainActor private func render(_ event: StarlightCelebration, layout: PatternReturnLayout,
                                  age: Double, quiet: Bool, score: CGRect? = nil) throws -> UIImage {
        let overlay = StarlightCelebrationOverlay(event: event, board: board,
            score: score ?? offRouteScore, header: header, quiet: quiet)
        let content = Canvas { context, size in
            overlay.drawSurvivorMarkers(in: &context, layout: layout, age: age, canvasSize: size)
        }.frame(width: board.width, height: board.height).background(Color.black)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        return try XCTUnwrap(renderer.uiImage)
    }

    private func ink(_ image: UIImage, in region: CGRect) throws -> Int {
        let cg = try XCTUnwrap(image.cgImage)
        let pixels = region.applying(CGAffineTransform(scaleX: image.scale, y: image.scale))
        let crop = try XCTUnwrap(cg.cropping(to: pixels))
        var bytes = [UInt8](repeating: 0, count: crop.width * crop.height * 4)
        let context = try XCTUnwrap(CGContext(data: &bytes, width: crop.width, height: crop.height,
            bitsPerComponent: 8, bytesPerRow: crop.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(crop, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
        return stride(from: 0, to: bytes.count, by: 4).filter {
            max(bytes[$0], bytes[$0 + 1], bytes[$0 + 2]) > 2
        }.count
    }
}
