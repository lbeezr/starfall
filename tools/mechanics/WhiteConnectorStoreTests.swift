import UIKit

extension FallingSkyStoreTests {
    @MainActor func testWhiteMaterialRetainsNeutralSilhouetteAcrossExpressions() throws {
        let node = FallingSkyCharacter(gem: .init(id: 0, kind: nil, light: true), step: 40)
        for expression: StarCast.Expression in [.idle, .landing, .clearing] {
            node.update(node.gem, expression: expression)
            let image = try XCTUnwrap(node.character.texture).cgImage()
            var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
            let context = try XCTUnwrap(CGContext(data: &bytes, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            var opaque = 0
            for index in stride(from: 0, to: bytes.count, by: 4) where bytes[index+3] > 250 {
                opaque += 1
                XCTAssertLessThanOrEqual(Int(max(bytes[index], bytes[index+1], bytes[index+2])) - Int(min(bytes[index], bytes[index+1], bytes[index+2])), 2)
            }
            XCTAssertGreaterThan(opaque, image.width * image.height / 20)
            XCTAssertEqual(node.character.children.count, 2)
        }
    }
    @MainActor func testWhiteConnectorCommitRapidInputAndVersionedRestore() throws {
        let (store, presenter, _, defaults) = makeStore()
        store.loadWhiteFixture(.connection)
        let original = store.game
        store.clear(Cell(1,1))
        XCTAssertEqual(store.game, original)
        XCTAssertTrue(store.message.contains("colored neighbor"))
        store.clear(Cell(0,1))
        XCTAssertEqual(store.game.score, 3); XCTAssertTrue(store.busy)
        let committed = store.game
        store.clear(Cell(1,0)); XCTAssertEqual(store.game, committed)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, committed)
        XCTAssertTrue(restored.isPaused && restored.game.isValidSave)
        XCTAssertNil(defaults.data(forKey: "starfall.accumulation.v3"))
        presenter.finish(); XCTAssertFalse(store.busy)
    }

    @MainActor func testWhiteFixtureReplacementAndInterruptionsRejectStaleCompletion() throws {
        for interruption in ["background", "pause", "motion", "example", "restart"] {
            let (store, presenter, clock, _) = makeStore()
            store.loadWhiteFixture(.pressure)
            store.togglePause()
            let staleClock = clock.action
            store.clear(Cell(0,0))
            let staleCompletion = try XCTUnwrap(presenter.completions.last)
            switch interruption {
            case "background": store.setSuspended(true)
            case "pause": store.togglePause()
            case "motion": store.setReducedMotion(true)
            case "example": store.loadWhiteFixture(.connection)
            default: store.restart(sameSky: true)
            }
            let committed = store.game
            staleCompletion()
            // Motion settles a clear but preserves the active shower deadline.
            // Background/pause/example/restart invalidate that deadline instead.
            if interruption == "motion" { XCTAssertNotNil(clock.deadline) }
            else { staleClock?() }
            XCTAssertEqual(store.game, committed, interruption)
            XCTAssertFalse(store.busy, interruption)
            XCTAssertTrue(store.game.isValidSave)
        }
    }

    @MainActor func testWhitePressureSmallerSurvivesAndLargerOverflows() {
        let (store, presenter, _, _) = makeStore()
        store.loadWhiteFixture(.pressure)
        store.clear(Cell(0,0)); presenter.finish(); store.callShower(); presenter.finish()
        XCTAssertFalse(store.game.isOver); XCTAssertEqual(store.game.score, 3)
        store.loadWhiteFixture(.pressure)
        store.clear(Cell(0,2)); presenter.finish(); store.callShower(); presenter.finish()
        XCTAssertTrue(store.game.isOver); XCTAssertEqual(store.game.score, 4)
        XCTAssertEqual(store.game.blockedColumn, 0)
    }
}
