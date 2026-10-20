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
        XCTAssertEqual(store.game, game.disablingAutomaticAging())
        XCTAssertTrue(try XCTUnwrap(CriticalMassPresentation.warning(game: game)).contains("1 shower"))
        XCTAssertTrue(CriticalMassPresentation.consequence(game: game, cell: Cell(0,2)).contains("Stage 3"))
        XCTAssertNil(CriticalMassPresentation.warning(game: store.game))
        XCTAssertEqual(CriticalMassPresentation.consequence(game: store.game, cell: Cell(0,2)), "")
        let gem = try XCTUnwrap(store.game.gem(at: Cell(0,2)))
        let node = FallingSkyCharacter(gem: gem, step: 44)
        CriticalMassPresentation.configure(node, game: store.game, cell: Cell(0,2), step: 44)
        XCTAssertEqual(LivingLight.pressure(on: node.character), 0)
        XCTAssertNotNil(node.character.value(forAttributeNamed: "a_light"))
        XCTAssertNil(node.childNode(withName: "sky.critical-mass"))
        let before = store.game
        store.setSuspended(true); clock.advance(100); XCTAssertEqual(store.game, before)
        store.setSuspended(false); store.callShower()
        let committed = store.game
        XCTAssertTrue(try XCTUnwrap(store.pending).stellarCollapses.isEmpty)
        XCTAssertEqual(store.changingColumns, [6], "Only the arriving column is busy after retiring the collapse")
        XCTAssertFalse(store.message.contains("implosion swallowed"))
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), committed)
        store.setSuspended(true); presenter.finish()
        XCTAssertEqual(store.game, committed)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder())
        XCTAssertEqual(restored.game, committed); XCTAssertTrue(restored.isPaused)
        store.restart(sameSky: true); presenter.finish()
        XCTAssertFalse(store.game.hasCriticalMass); XCTAssertEqual(store.game.lostStarlight, 0)
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

    @MainActor func testNewSkiesAndReplayDisablePressure() {
        let suite = "CriticalMass.New.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset"], presenter: FallingSkyRecorder())
        XCTAssertFalse(store.game.hasCriticalMass)
        XCTAssertEqual(store.game.cadenceID, .announcedCycleV1)
        XCTAssertEqual(store.game.adoptingFeedingDusk(), store.game)
        store.startFirstLight(); XCTAssertFalse(store.game.hasCriticalMass)
        store.restart(sameSky: true); XCTAssertFalse(store.game.hasCriticalMass)
        store.restart(sameSky: false); XCTAssertFalse(store.game.hasCriticalMass)
        XCTAssertEqual(store.game.cadenceID, .announcedCycleV1)
    }

    @MainActor func testRetainedCriticalCadenceRestoresReplaysAndOnlyFreshSwitches() throws {
        for cadence: SkyCadenceID in [.announcedCycleV1, .announcedCycleV2] {
            let suite = "CriticalCadence.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let initial = FallingSky(seed: 64, generation: .current, cadence: cadence, criticalMass: true)
            var saved = initial
            for _ in 0..<8 { XCTAssertNotNil(saved.letStarsFall()) }
            defaults.set(try SkySaveArchive.encode(saved), forKey: SkySaveArchive.key)
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder())
            XCTAssertEqual(store.game, saved.disablingAutomaticAging())
            XCTAssertEqual(store.game.cadenceID, cadence)
            store.restart(sameSky: true)
            XCTAssertEqual(store.game, initial.disablingAutomaticAging())
            XCTAssertEqual(store.game.cadenceID, cadence)
            store.restart(sameSky: false)
            XCTAssertEqual(store.game.cadenceID, .announcedCycleV1)
            XCTAssertFalse(store.game.hasCriticalMass)
        }
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
    /// Native SpriteKit sheet: columns are families, rows are survived showers 0/3/6/7/8.
    @MainActor func testEvolutionRetainsIdentityAndShowsCommittedAgeInQuietMotion() throws {
        let game = CriticalMassFixture.game()
        let ages = [0, 3, 6, 7, 8]
        let kinds: [Jewel?] = [.amber, .rose, .mint, .aqua, .violet, nil]
        let scene = SKScene(size: CGSize(width: 420, height: 400))
        scene.backgroundColor = UIColor(red: 0.08, green: 0.07, blue: 0.18, alpha: 1)
        let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
        view.presentScene(scene)
        defer { view.presentScene(nil) }
        for (row, age) in ages.enumerated() {
            for (column, kind) in kinds.enumerated() {
                let fresh = StarfallGem(id: column, kind: kind, light: kind == nil)
                var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(fresh)) as? [String: Any])
                if age > 0 { object["savedStellarAge"] = age }
                let gem = try JSONDecoder().decode(StarfallGem.self, from: JSONSerialization.data(withJSONObject: object))
                let node = FallingSkyCharacter(gem: gem, step: 44)
                CriticalMassPresentation.configure(node, game: game, cell: Cell(0, column), step: 44)
                node.setGrowthMotion(false)
                XCTAssertEqual(node.gem, gem)
                XCTAssertEqual(node.gem.value, fresh.value)
                if age >= 3 {
                    XCTAssertEqual(LivingLight.pressure(on: node.character),
                                   Float(age) / Float(CriticalMassRule.collapseAge), accuracy: 0.001)
                } else {
                    XCTAssertEqual(LivingLight.pressure(on: node.character), 0)
                    XCTAssertNotNil(node.character.value(forAttributeNamed: "a_light"))
                }
                let cue = node.childNode(withName: "sky.critical-mass")
                XCTAssertEqual(cue != nil, age >= 6)
                XCTAssertEqual(cue?.children.count ?? 0, age >= 6 ? 1 : 0,
                               "Compression uses one path, with no extra facial core")
                node.position = CGPoint(x: 42 + column * 67, y: 355 - row * 75)
                scene.addChild(node)
            }
        }
        let attachment = XCTAttachment(image: UIImage(cgImage: try XCTUnwrap(view.texture(from: scene)).cgImage()))
        attachment.name = "stellar-evolution-six-families-ages-0-3-6-7-8"
        attachment.lifetime = .keepAlways; add(attachment)
    }

}
