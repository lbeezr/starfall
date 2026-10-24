import XCTest
import SwiftUI
import UIKit
@testable import StarfallCore
@testable import Starfall

final class FinalLightPresentationTests: XCTestCase {
    private func receipt(_ paths: [[Cell]], identity: SkyIdentity = .colored(.aqua)) -> SkyFinalLightReceipt {
        let cells = Set(paths.flatMap { $0 }).sorted {
            $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
        }
        return SkyFinalLightReceipt(roundGeneration: 7, sequence: 11, paths: paths, cells: cells, identity: identity)
    }

    @MainActor func testAffineSignaturePreservesManualGapsBranchesAndRevisits() throws {
        let walk = [Cell(0,0), Cell(0,2), Cell(2,2), Cell(0,2), Cell(1,3), Cell(2,4)]
        let record = receipt([walk])
        for size in [CGSize(width: 88, height: 56), CGSize(width: 120, height: 64), CGSize(width: 220, height: 96)] {
            let drawing = try XCTUnwrap(SkyFinalLightLayout(receipt: record, size: size))
            XCTAssertEqual(drawing.paths.count, 1)
            XCTAssertEqual(drawing.paths[0].count, walk.count)
            XCTAssertEqual(drawing.paths[0][1], drawing.paths[0][3], "The revisit is retained rather than simplified")
            XCTAssertEqual(drawing.starPoints.count, Set(walk).count)
            for (cell, point) in zip(record.cells, drawing.starPoints) {
                for (other, next) in zip(record.cells, drawing.starPoints) {
                    XCTAssertEqual(next.x - point.x, CGFloat(other.column - cell.column) * drawing.scale, accuracy: 0.000_001)
                    XCTAssertEqual(next.y - point.y, CGFloat(cell.row - other.row) * drawing.scale, accuracy: 0.000_001)
                }
                XCTAssertTrue(CGRect(origin: .zero, size: size).insetBy(dx: 3, dy: 3).contains(point))
            }
        }
    }

    @MainActor func testActualSimultaneousRecipesRemainSeparateWithNoInventedBridge() throws {
        var game = SkyTutorial.fullBoardImmediate.game()
        let turn = try XCTUnwrap(SkyTutorial.fullBoardImmediate.actions.first?.perform(in: &game))
        let phase = try XCTUnwrap(turn.resolutionPhases.first)
        XCTAssertEqual(phase.recipes.count, 2)
        let paths = phase.recipes.map(\.presentationPath)
        let record = receipt(paths)
        let drawing = try XCTUnwrap(SkyFinalLightLayout(receipt: record, size: CGSize(width: 180, height: 100)))
        XCTAssertEqual(drawing.paths.map(\.count), paths.map(\.count))
        XCTAssertEqual(drawing.starPoints.count, phase.cleared.count)
        XCTAssertEqual(drawing.paths[0].first, drawing.paths[0].last)
        XCTAssertEqual(drawing.paths[1].first, drawing.paths[1].last)

        // An explicit separated pair isolates the rendering boundary. It uses
        // two real square paths, not a reachability or player-study claim.
        let separated = receipt([[Cell(0,0), Cell(0,1), Cell(1,1), Cell(1,0), Cell(0,0)],
                                 [Cell(0,5), Cell(0,6), Cell(1,6), Cell(1,5), Cell(0,5)]])
        let fitted = try XCTUnwrap(SkyFinalLightLayout(receipt: separated, size: CGSize(width: 180, height: 100)))
        let image = try renderDrawing(fitted, identity: separated.identity, size: CGSize(width: 180, height: 100))
        XCTAssertGreaterThan(try ink(image, region: CGRect(x: 0, y: 20, width: 44, height: 60)), 40)
        XCTAssertGreaterThan(try ink(image, region: CGRect(x: 136, y: 20, width: 44, height: 60)), 40)
        XCTAssertEqual(try ink(image, region: CGRect(x: 72, y: 20, width: 36, height: 60)), 0,
                       "A cleared union must not become a false line between actual recipes")
        attach(image, name: "final-light-separate-squares")
    }

    @MainActor func testMaximumManualWalkAndDenseFootprintStayBoundedWithoutDroppingLinks() throws {
        let cells = (0..<49).map { Cell($0 / 7, $0 % 7) }
        let walk = Array(repeating: cells, count: 4).flatMap { $0 }
        let drawing = try XCTUnwrap(SkyFinalLightLayout(receipt: receipt([walk]), size: CGSize(width: 120, height: 64)))
        XCTAssertEqual(drawing.paths[0].count, 196)
        XCTAssertEqual(drawing.starPoints.count, 49)
        XCTAssertEqual(Set(drawing.starPoints.map { "\($0.x),\($0.y)" }).count, 49)
        let image = try renderDrawing(drawing, identity: .colored(.violet), size: CGSize(width: 120, height: 64))
        XCTAssertEqual(try ink(image, region: CGRect(x: 0, y: 0, width: 120, height: 3)), 0)
        XCTAssertEqual(try ink(image, region: CGRect(x: 0, y: 61, width: 120, height: 3)), 0)
    }

    @MainActor func testMalformedOrUnboundedSnapshotsCannotInventAVisibleFigure() throws {
        let valid = receipt([Array((0..<5).map { Cell(0,$0) })])
        for size in [CGSize.zero, CGSize(width: CGFloat.nan, height: 56), CGSize(width: 88, height: CGFloat.infinity)] {
            XCTAssertNil(SkyFinalLightLayout(receipt: valid, size: size))
        }
        let invalid = [
            receipt([[Cell(0,0), Cell(7,0)]]),
            SkyFinalLightReceipt(roundGeneration: 1, sequence: 1, paths: [], cells: [], identity: .white),
            SkyFinalLightReceipt(roundGeneration: 1, sequence: 1, paths: valid.paths, cells: [Cell(0,0)], identity: .white),
            receipt(Array(repeating: valid.paths[0], count: PatternReturnLayout.maximumPatterns + 1)),
            receipt([Array(repeating: valid.paths[0], count: 300).flatMap { $0 }])
        ]
        for record in invalid { XCTAssertNil(SkyFinalLightLayout(receipt: record, size: CGSize(width: 120, height: 64))) }
    }

    @MainActor func testStaticNormalQuietInactiveAndResumeHaveOneIdenticalSignature() throws {
        let record = receipt([[Cell(0,0), Cell(1,1), Cell(2,2), Cell(3,3), Cell(4,4)]])
        let size = CGSize(width: 240, height: 110)
        let normal = try render(SkyFinalLightView(receipt: record, active: true, quiet: false), size: size)
        let quiet = try render(SkyFinalLightView(receipt: record, active: true, quiet: true), size: size)
        let inactive = try render(SkyFinalLightView(receipt: record, active: false, quiet: false), size: size)
        let resumed = try render(SkyFinalLightView(receipt: record, active: true, quiet: false), size: size)
        XCTAssertEqual(try pixels(normal), try pixels(quiet), "Quiet keeps exact geometry, material and caption")
        XCTAssertEqual(try pixels(normal), try pixels(resumed), "Resume has no second entrance or reward replay")
        XCTAssertGreaterThan(try ink(normal, region: CGRect(origin: .zero, size: size)), 50)
        XCTAssertEqual(try ink(inactive, region: CGRect(origin: .zero, size: size)), 0)
        XCTAssertEqual(SkyCopy.text(.finalLightCaption), "Last earned light")
        attach(normal, name: "final-light-normal-static-signature")
    }

    @MainActor func testCaptionReflowsAtLargestTextWithoutShrinkingFigureOrText() throws {
        let record = receipt([[Cell(0,0), Cell(0,2), Cell(0,3), Cell(0,4), Cell(0,5)]])
        let ordinary = UIHostingController(rootView: SkyFinalLightView(receipt: record, active: true, quiet: false)
            .environment(\.dynamicTypeSize, .large)).sizeThatFits(in: CGSize(width: 180, height: 1_000))
        let accessible = UIHostingController(rootView: SkyFinalLightView(receipt: record, active: true, quiet: true)
            .environment(\.dynamicTypeSize, .accessibility5)).sizeThatFits(in: CGSize(width: 180, height: 1_000))
        XCTAssertEqual(ordinary.width, 180, accuracy: 1)
        XCTAssertEqual(accessible.width, 180, accuracy: 1)
        XCTAssertGreaterThanOrEqual(ordinary.height, 56)
        XCTAssertGreaterThan(accessible.height, ordinary.height)
        XCTAssertLessThan(accessible.height, 300)
        let image = try render(SkyFinalLightView(receipt: record, active: true, quiet: true)
            .environment(\.dynamicTypeSize, .accessibility5), size: CGSize(width: 180, height: ceil(accessible.height)))
        attach(image, name: "final-light-largest-text-static-signature")
    }

    @MainActor func testOnlyTerminalCurrentResultAdmitsTheSessionSignature() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let a = try XCTUnwrap(game.board.firstIndex { $0?.id == 9 })
        let b = try XCTUnwrap(game.board.firstIndex { $0?.id == 10 })
        let turn = try XCTUnwrap(game.nudge(from: Cell(a / 7, a % 7), to: Cell(b / 7, b % 7)))
        XCTAssertEqual(game.outcome, .won)
        let phase = try XCTUnwrap(turn.resolutionPhases.last)
        let record = receipt(phase.recipes.map(\.presentationPath))
        var calls = 0
        for screen in [SkyFlowScreen.welcome, .entry, .playing, .worldMap, .won, .full] {
            let ceremony = SkyFlowCeremony(screen: screen, challenge: game.challenge, entry: nil,
                result: SkyResultSnapshot(game: game), onward: nil,
                welcome: SkyWelcomeSnapshot(game: game, hasSavedSky: true, paused: true),
                mastery: nil, finalLight: record, active: true, quiet: true, modal: false,
                restoredSceneryBounds: nil, action: { _ in calls += 1 })
            XCTAssertEqual(ceremony.visibleFinalLight, screen == .won || screen == .full ? record : nil)
        }
        let cold = SkyFlowCeremony(screen: .won, challenge: game.challenge, entry: nil,
            result: SkyResultSnapshot(game: game), onward: nil,
            welcome: SkyWelcomeSnapshot(game: game, hasSavedSky: true, paused: true),
            active: true, quiet: true, modal: false, restoredSceneryBounds: nil, action: { _ in calls += 1 })
        XCTAssertNil(cold.visibleFinalLight)
        XCTAssertEqual(calls, 0, "Reading the signature cannot invoke a flow action or reward")
    }

    @MainActor func testPracticeRequiresActualCompletionAndWithdrawsOnRetry() throws {
        var run = SkyTutorialRun(.trace), game = SkyTutorial.trace.game()
        let action = try XCTUnwrap(run.next), before = game
        _ = try XCTUnwrap(action.perform(in: &game))
        run.observe(action, before: before, after: game)
        XCTAssertTrue(run.complete); XCTAssertFalse(run.needsRetry)
        let record = receipt([try XCTUnwrap(SkyTutorial.trace.actions.first).tracePathForFinalLightTest])
        func guide(_ value: SkyTutorialRun, final: SkyFinalLightReceipt?) -> SkyTutorialGuide {
            SkyTutorialGuide(run: value, constrained: false, endingAfter: .trace, finalLight: final,
                             active: true, quiet: true, retry: {}, next: { _ in }, exit: {})
        }
        XCTAssertEqual(guide(run, final: record).visibleFinalLight, record)
        XCTAssertNil(guide(run, final: nil).visibleFinalLight)
        let retried = SkyTutorialRun(.trace)
        XCTAssertNil(guide(retried, final: record).visibleFinalLight)
        var missed = retried, changed = SkyTutorial.trace.game()
        let old = changed
        _ = try XCTUnwrap(changed.clear(Cell(0,0)))
        missed.observe(.tap(Cell(0,0)), before: old, after: changed)
        XCTAssertTrue(missed.needsRetry)
        XCTAssertNil(guide(missed, final: record).visibleFinalLight)
        for category in [DynamicTypeSize.large, .accessibility5] {
            let content = guide(run, final: record).environment(\.dynamicTypeSize, category)
            let host = UIHostingController(rootView: content)
            let measured = host.sizeThatFits(in: CGSize(width: 390, height: 2_000))
            XCTAssertGreaterThan(measured.height, 100)
            XCTAssertLessThan(measured.height, 1_500)
            let image = try render(content, size: CGSize(width: 390, height: ceil(measured.height)))
            attach(image, name: "final-light-completed-practice-\(category)")
        }
    }

    @MainActor private func renderDrawing(_ layout: SkyFinalLightLayout, identity: SkyIdentity, size: CGSize) throws -> UIImage {
        try render(Canvas { context, _ in SkyFinalLightView.draw(in: &context, layout: layout, identity: identity) }, size: size)
    }
    @MainActor private func render<Content: View>(_ content: Content, size: CGSize) throws -> UIImage {
        let renderer = ImageRenderer(content: content.frame(width: size.width, height: size.height).background(Color.black))
        renderer.scale = 1
        return try XCTUnwrap(renderer.uiImage)
    }
    private func pixels(_ image: UIImage) throws -> [UInt8] {
        let cg = try XCTUnwrap(image.cgImage)
        var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let context = try XCTUnwrap(CGContext(data: &bytes, width: cg.width, height: cg.height,
            bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        return bytes
    }
    private func ink(_ image: UIImage, region: CGRect) throws -> Int {
        let cg = try XCTUnwrap(image.cgImage)
        let crop = try XCTUnwrap(cg.cropping(to: region))
        let data = try pixels(UIImage(cgImage: crop))
        return stride(from: 0, to: data.count, by: 4).filter { max(data[$0], data[$0 + 1], data[$0 + 2]) > 8 }.count
    }
    private func attach(_ image: UIImage, name: String) {
        let attachment = XCTAttachment(image: image); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}

private extension SkyTutorial.Action {
    var tracePathForFinalLightTest: [Cell] {
        if case .trace(let path) = self { return path }
        return []
    }
}
