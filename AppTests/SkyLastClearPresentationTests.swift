import XCTest
import SwiftUI
import UIKit
@testable import StarfallCore
@testable import Starfall

final class SkyLastClearPresentationTests: XCTestCase {
    private func snapshot(_ opening: FallingSky, from: Cell, to: Cell) throws -> SkyLastClearSnapshot {
        var game = opening
        let turn = try XCTUnwrap(game.nudge(from: from, to: to))
        return try XCTUnwrap(SkyLastClearSnapshot(turn: turn, from: opening, to: game, path: [],
                                                recipe: nil, roundGeneration: 3, sequence: 7))
    }

    private func manual(_ fixture: ConstellationFixture, walk: [Cell]) throws -> SkyLastClearSnapshot {
        let old = fixture.game()
        var game = old
        let turn = try XCTUnwrap(game.clearConstellation(walk))
        return try XCTUnwrap(SkyLastClearSnapshot(turn: turn, from: old, to: game, path: walk,
                                                recipe: nil, roundGeneration: 4, sequence: 8))
    }

    func testActualChainFramesKeepSeparatePhaseCoordinatesAndOnlyTheirOwnSurvivorDiamonds() throws {
        let value = try snapshot(.fullBoardRibbon(), from: Cell(1,1), to: Cell(1,2))
        XCTAssertEqual(value.phases.count, 3)
        XCTAssertEqual(value.survivorCount, 4)
        for size in [CGSize(width: 112, height: 112), CGSize(width: 300, height: 300),
                     CGSize(width: 300, height: 240)] {
            for (index, phase) in value.phases.enumerated() {
                let layout = try XCTUnwrap(SkyLastClearDiagramLayout(phase: phase, size: size))
                let shared = try XCTUnwrap(SkyFullBoardChoiceGeometry(size: size))
                XCTAssertEqual(layout.geometry.board, shared.board)
                XCTAssertEqual(layout.paths, phase.paths.map { $0.map(shared.point) })
                XCTAssertEqual(Set(layout.clearedCells), phase.cleared)
                XCTAssertEqual(layout.clearedCells.count, phase.cleared.count)
                XCTAssertEqual(layout.survivorCells, phase.survivors?.movements.map(\.to) ?? [])
                XCTAssertEqual(layout.survivorCells.count, index == 0 ? 0 : 2)
                XCTAssertEqual(layout.survivorPoints, layout.survivorCells.map(shared.point))
                XCTAssertTrue(layout.paths.flatMap { $0 }.allSatisfy(shared.board.contains))
                XCTAssertTrue(layout.clearedPoints.allSatisfy(shared.board.contains))
            }
        }
    }

    func testActualManualGapAndRepeatedBranchStayExactAndNeverBecomeAClearedUnionWalk() throws {
        let examples: [(ConstellationFixture, [Cell])] = [
            (.singleGap, [0,1,2,3,5].map { Cell(0,$0) }),
            (.overlap, [Cell(0,4), Cell(1,3), Cell(2,4), Cell(1,3), Cell(0,4), Cell(1,5), Cell(1,6)])
        ]
        for (fixture, walk) in examples {
            let value = try manual(fixture, walk: walk), phase = try XCTUnwrap(value.phases.first)
            let layout = try XCTUnwrap(SkyLastClearDiagramLayout(phase: phase, size: CGSize(width: 300, height: 300)))
            XCTAssertEqual(phase.paths, [walk])
            XCTAssertEqual(layout.paths, [walk.map(layout.geometry.point)])
            XCTAssertEqual(Set(layout.clearedCells), Set(walk))
            XCTAssertTrue(layout.survivorPoints.isEmpty)
            if fixture == .singleGap {
                let points = try XCTUnwrap(layout.paths.first)
                XCTAssertEqual(points[4].x - points[3].x, layout.geometry.step * 2, accuracy: 0.000001)
                XCTAssertFalse(phase.cleared.contains(Cell(0,4)))
            } else {
                XCTAssertEqual(layout.paths[0][0], layout.paths[0][4])
                XCTAssertEqual(layout.paths[0][1], layout.paths[0][3])
                XCTAssertGreaterThan(layout.paths[0].count, layout.clearedPoints.count)
            }
            XCTAssertEqual(value.score.total, 5)
            XCTAssertFalse(value.score.phases[0].usesStoryPoints)
        }
    }

    /// Production resolver geometry only, not a reachable saved campaign.
    func testDenseSimultaneousOverlapsRetainEverySeparateOutlineAndFortyNineIngredients() throws {
        let board: [StarfallGem?] = (0..<49).map { .init(id: $0, kind: .aqua) }
        let actual = try XCTUnwrap(SkyRecipeResolution.resolve(board, lineLength: 4).first)
        let score = try XCTUnwrap(SkyScoreExplanation(phases: [actual], expectedTotal: actual.award.displayPoints))
        let phase = SkyLastClearSnapshot.Phase(board: actual.before, drained: [], cleared: actual.cleared,
            paths: actual.recipes.map(\.presentationPath), score: score.phases[0], survivors: nil,
            refillCount: 0, occupiedAfter: 0)
        let layout = try XCTUnwrap(SkyLastClearDiagramLayout(phase: phase, size: CGSize(width: 300, height: 300)))
        XCTAssertEqual(layout.paths.count, 75)
        XCTAssertEqual(layout.paths.flatMap { $0 }.count, 478)
        XCTAssertEqual(layout.clearedPoints.count, 49)
        XCTAssertTrue(layout.survivorPoints.isEmpty)
        XCTAssertEqual(layout.paths, phase.paths.map { $0.map(layout.geometry.point) })
        let shared = Cell(0,0)
        let appearances = zip(phase.paths, layout.paths).flatMap { cells, points in
            zip(cells, points).filter { $0.0 == shared }.map(\.1)
        }
        XCTAssertGreaterThan(appearances.count, 2)
        XCTAssertTrue(appearances.allSatisfy { $0 == layout.geometry.point(shared) })
    }

    @MainActor func testSharedMaterialsKeepActualGrownBodySizeAndStaticInkIgnoresParentAnimation() throws {
        let value = try snapshot(.freshChallenge(.seedMoon), from: Cell(0,4), to: Cell(0,3))
        let phase = try XCTUnwrap(value.phases.first)
        let layout = try XCTUnwrap(SkyLastClearDiagramLayout(phase: phase, size: CGSize(width: 300, height: 300)))
        let grown = try XCTUnwrap(phase.board.firstIndex { $0?.grown == true })
        let cell = Cell(grown / 7, grown % 7)
        let small = layout.geometry.imageRect(at: cell, grown: false)
        let large = layout.geometry.imageRect(at: cell, grown: true)
        XCTAssertEqual(large.midX, small.midX)
        XCTAssertEqual(large.midY, small.midY)
        XCTAssertEqual(large.width / small.width, 0.40 / 0.29, accuracy: 0.000001)
        XCTAssertEqual(phase.score.clearedStarCount, 4)
        XCTAssertEqual(phase.score.baseLight, 5)
        XCTAssertEqual(phase.score.points, 6_000)
        let ordinary = try render(phase, suppressAnimations: false)
        let staticParent = try render(phase, suppressAnimations: true)
        XCTAssertEqual(ordinary.pngData(), staticParent.pngData())
        XCTAssertLessThanOrEqual(SkyPiece.cachedMaterialCount, SkyPiece.maximumMaterials)
        let image = try XCTUnwrap(ordinary.cgImage)
        XCTAssertEqual(image.width, 900)
        XCTAssertEqual(image.height, 900)
        let attachment = XCTAttachment(image: ordinary)
        attachment.name = "last-clear-actual-grown-ingredient"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func testDiagramValidationRejectsMalformedCellsAndSizesWithoutInventingMissingPaths() throws {
        let value = try snapshot(.fullBoardLantern(), from: Cell(1,1), to: Cell(1,2))
        let original = value.phases[0]
        for size in [CGSize.zero, CGSize(width: 111, height: 300),
                     CGSize(width: CGFloat.nan, height: 300), CGSize(width: 300, height: CGFloat.infinity)] {
            XCTAssertNil(SkyLastClearDiagramLayout(phase: original, size: size))
        }
        let noWalk = SkyLastClearSnapshot.Phase(board: original.board, drained: original.drained, cleared: original.cleared, paths: [],
            score: original.score, survivors: nil, refillCount: 0, occupiedAfter: original.occupiedAfter)
        let layout = try XCTUnwrap(SkyLastClearDiagramLayout(phase: noWalk, size: CGSize(width: 300, height: 300)))
        XCTAssertTrue(layout.paths.isEmpty, "A direct clear without a known drawing receives only actual ingredient marks")
        XCTAssertEqual(layout.clearedCells.count, original.cleared.count)
        let outside = SkyLastClearSnapshot.Phase(board: original.board, drained: original.drained, cleared: original.cleared,
            paths: [[Cell(7,0), Cell(0,0)]], score: original.score, survivors: nil,
            refillCount: 0, occupiedAfter: original.occupiedAfter)
        XCTAssertNil(SkyLastClearDiagramLayout(phase: outside, size: CGSize(width: 300, height: 300)))
    }

    @MainActor func testHistoricalGrayConventionChangesOnlyExactDrainedMaterialBounds() throws {
        let old = DuskFixture.zeroClear.game(rule: .patientFeeding)
        var game = old
        let turn = try XCTUnwrap(game.clear(Cell(0,1)))
        let value = try XCTUnwrap(SkyLastClearSnapshot(turn: turn, from: old, to: game, path: [],
            recipe: nil, roundGeneration: 5, sequence: 9))
        let actual = try XCTUnwrap(value.phases.first)
        let expectedDrained = Set(old.board.indices.compactMap { index -> Cell? in
            let cell = Cell(index / 7, index % 7)
            return old.isDrained(at: cell) ? cell : nil
        })
        XCTAssertEqual(actual.drained, expectedDrained)
        XCTAssertFalse(actual.drained.isEmpty)
        XCTAssertEqual(actual.score.baseLight, 0)
        let colored = SkyLastClearSnapshot.Phase(board: actual.board, drained: [], cleared: actual.cleared,
            paths: actual.paths, score: actual.score, survivors: actual.survivors,
            refillCount: actual.refillCount, occupiedAfter: actual.occupiedAfter)
        let grayImage = try render(actual, suppressAnimations: true)
        let coloredImage = try render(colored, suppressAnimations: true)
        XCTAssertNotEqual(grayImage.pngData(), coloredImage.pngData())
        let geometry = try XCTUnwrap(SkyFullBoardChoiceGeometry(size: CGSize(width: 300, height: 300)))
        let unchanged = try XCTUnwrap(actual.board.indices.first { index in
            actual.board[index] != nil && !actual.drained.contains(Cell(index / 7, index % 7))
        })
        let cell = Cell(unchanged / 7, unchanged % 7)
        let sameBounds = geometry.imageRect(at: cell, grown: actual.board[unchanged]?.grown == true)
        XCTAssertEqual(try crop(grayImage, to: sameBounds), try crop(coloredImage, to: sameBounds),
                       "Unmarked bodies retain the identical existing material")
        for drained in actual.drained {
            let bounds = geometry.imageRect(at: drained, grown: actual.board[drained.row * 7 + drained.column]?.grown == true)
            XCTAssertNotEqual(try crop(grayImage, to: bounds), try crop(coloredImage, to: bounds))
            XCTAssertTrue(geometry.board.insetBy(dx: -2, dy: -2).contains(bounds),
                          "The existing shared material contour and grown sizing stay in their slot")
        }
        let attachment = XCTAttachment(image: grayImage)
        attachment.name = "last-clear-exact-drained-gray-convention"
        attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor func testNativeCaptionsGrowAtLargestTextAndCompletePageKeepsTheExistingReader() throws {
        let value = try snapshot(.fullBoardRibbon(), from: Cell(1,1), to: Cell(1,2))
        let phase = value.phases[1]
        let text = SkyLastClearCopy.ingredients(phase) + " " + phase.score.explanationText
        func size(_ dynamic: DynamicTypeSize) -> CGSize {
            let host = UIHostingController(rootView: Text(text).font(StarfallTheme.Typography.body)
                .fixedSize(horizontal: false, vertical: true).environment(\.dynamicTypeSize, dynamic))
            return host.sizeThatFits(in: CGSize(width: 260, height: 10_000))
        }
        let normal = size(.large), largest = size(.accessibility5)
        XCTAssertLessThanOrEqual(normal.width, 260)
        XCTAssertLessThanOrEqual(largest.width, 260)
        XCTAssertGreaterThan(largest.height, normal.height)
        var returned = false
        let view = SkyLastClearView(snapshot: value, done: { returned = true })
            .environment(\.dynamicTypeSize, .accessibility5)
            .frame(width: 390, height: 844)
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        host.view.layoutIfNeeded()
        XCTAssertFalse(returned, "Reading and layout have no dismissal or replay callback")
        let measured = host.sizeThatFits(in: CGSize(width: 390, height: 844))
        XCTAssertLessThanOrEqual(measured.width, 390)
        XCTAssertLessThanOrEqual(measured.height, 844)
        XCTAssertEqual(value.phases.count, 3)
        XCTAssertEqual(value.score.total, 30_000)
        XCTAssertEqual(value.totalRefillCount, 12)
    }

    @MainActor private func render(_ phase: SkyLastClearSnapshot.Phase,
                                   suppressAnimations: Bool) throws -> UIImage {
        let content = SkyLastClearDiagramView(phase: phase, number: 1)
            .frame(width: 300, height: 300)
            .transaction { $0.disablesAnimations = suppressAnimations }
            .background(StarfallTheme.Colors.skyTop)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        return try XCTUnwrap(renderer.uiImage)
    }

    private func crop(_ image: UIImage, to region: CGRect) throws -> Data {
        let pixels = region.applying(CGAffineTransform(scaleX: image.scale, y: image.scale))
        let cropped = try XCTUnwrap(image.cgImage?.cropping(to: pixels))
        return try XCTUnwrap(UIImage(cgImage: cropped).pngData())
    }
}
