import XCTest
import SpriteKit
import StarfallCore
@testable import Starfall

final class CriticalMassProductionTests: XCTestCase {
    @MainActor func testCommitRestoreInterruptionRestartAndWarnings() throws {
        let suite = "CriticalMass.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let game = CriticalMassFixture.game()
        defaults.set(try SkySaveArchive.encode(game), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.setSuspended(false)
        XCTAssertEqual(store.game, game)
        XCTAssertTrue(try XCTUnwrap(CriticalMassPresentation.warning(game: game)).contains("1 shower"))
        XCTAssertTrue(CriticalMassPresentation.consequence(game: game, cell: Cell(0,2)).contains("Stage 3"))
        let before = store.game
        store.setSuspended(true); clock.advance(100); XCTAssertEqual(store.game, before)
        store.setSuspended(false); store.callShower()
        let committed = store.game
        XCTAssertFalse(try XCTUnwrap(store.pending).stellarCollapses.isEmpty)
        XCTAssertEqual(store.changingColumns, Set(0..<7))
        XCTAssertTrue(store.message.contains("implosion swallowed"))
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), committed)
        store.setSuspended(true); presenter.finish()
        XCTAssertEqual(store.game, committed)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder())
        XCTAssertEqual(restored.game, committed); XCTAssertTrue(restored.isPaused)
        store.restart(sameSky: true); presenter.finish()
        XCTAssertTrue(store.game.hasCriticalMass); XCTAssertEqual(store.game.lostStarlight, 0)
        XCTAssertTrue(store.game.board.allSatisfy { $0 == nil })
    }

    @MainActor func testV7IsPreservedAndMalformedV8DoesNotResurrectIt() throws {
        let suite = "CriticalMass.Archive.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let old = DuskFixture.imminent.game(rule: .patientFeeding)
        let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(old))
        let bytes = try JSONSerialization.data(withJSONObject: ["schemaVersion": 7, "game": object])
        defaults.set(bytes, forKey: SkySaveArchive.patientFeedingKey)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder())
        XCTAssertEqual(store.game, old); XCTAssertFalse(store.game.hasCriticalMass)
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        store.setSuspended(false)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.patientFeedingKey), bytes)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), old)
        defaults.set(Data("invalid".utf8), forKey: SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from: defaults))
        defaults.removeObject(forKey: SkySaveArchive.key)
        let newObject = try JSONSerialization.jsonObject(with: JSONEncoder().encode(CriticalMassFixture.game()))
        defaults.set(try JSONSerialization.data(withJSONObject: ["schemaVersion": 7, "game": newObject]), forKey: SkySaveArchive.patientFeedingKey)
        XCTAssertNil(SkySaveArchive.load(from: defaults), "Old envelopes cannot smuggle an aging rule")
    }

    @MainActor func testNewSkiesUsePressureWhileFirstLightAndRetainedReplayDoNot() {
        let suite = "CriticalMass.New.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset"], presenter: FallingSkyRecorder())
        XCTAssertTrue(store.game.hasCriticalMass)
        XCTAssertEqual(store.game.adoptingFeedingDusk(), store.game)
        store.startFirstLight(); XCTAssertFalse(store.game.hasCriticalMass)
        store.restart(sameSky: true); XCTAssertFalse(store.game.hasCriticalMass)
        store.restart(sameSky: false); XCTAssertTrue(store.game.hasCriticalMass)
    }

    @MainActor func testPurpleKeepsSilhouetteAndStaticNonColorMarkerInQuietMotion() throws {
        let game = CriticalMassFixture.game()
        let gem = try XCTUnwrap(game.gem(at: Cell(0,2)))
        let node = FallingSkyCharacter(gem: gem, step: 44)
        CriticalMassPresentation.configure(node, game: game, cell: Cell(0,2), step: 44)
        XCTAssertEqual(node.gem.id, gem.id)
        XCTAssertNotNil(node.character.shader?.uniformNamed("u_corruption"))
        XCTAssertNotNil(node.childNode(withName: "sky.critical-mass"))
        node.setGrowthMotion(false)
        XCTAssertNotNil(node.childNode(withName: "sky.critical-mass"))
    }
}
