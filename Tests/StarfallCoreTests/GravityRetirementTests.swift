import XCTest
@testable import StarfallCore

final class GravityRetirementTests: XCTestCase {
    private func verifyRetirement(_ original: FallingSky) throws {
        XCTAssertTrue(original.isValidSave)
        let game = original.removingGravity()
        XCTAssertEqual(game.generation, .standardSky)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.removingGravity(), game)
        XCTAssertNil(game.orbit)
        XCTAssertFalse(game.board.contains { $0?.gravityKind != nil })
        XCTAssertFalse(game.incoming.contains { $0.gravityKind != nil })
        XCTAssertEqual(game.score, original.score)
        XCTAssertEqual(game.seed, original.seed)
        XCTAssertEqual(game.turns, original.turns)
        XCTAssertEqual(game.starsLanded, original.starsLanded)
        XCTAssertEqual(game.darkStarsCleared, original.darkStarsCleared)
        XCTAssertEqual(game.outcome, original.outcome)
        XCTAssertEqual(game.blockedColumn, original.blockedColumn)
        XCTAssertEqual(game.balance, original.balance)
        XCTAssertEqual(game.cadenceID, original.cadenceID)
        XCTAssertEqual(game.automaticShowerDelay, original.automaticShowerDelay)
        let survivors = original.board.compactMap { $0 }.filter { $0.gravityKind == nil }
        XCTAssertEqual(Set(game.board.compactMap { $0?.id }), Set(survivors.map(\.id)))
        for gem in survivors { XCTAssertEqual(game.board.compactMap { $0 }.first { $0.id == gem.id }, gem) }
        XCTAssertEqual(game.board, GravityFieldRules.settle(original.board.map { $0?.gravityKind == nil ? $0 : nil }, field: nil))
        XCTAssertEqual(game.incoming.map(\.id), original.incoming.map(\.id))
        XCTAssertEqual(game.incoming.map(\.column), original.incoming.map(\.column))
        for (old, new) in zip(original.incoming, game.incoming) where old.gravityKind == nil { XCTAssertEqual(new, old) }
        var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        var continued = game
        for _ in 0..<24 where !continued.isOver {
            XCTAssertEqual(continued.letStarsFall()?.collected, restored.letStarsFall()?.collected)
            XCTAssertEqual(continued, restored)
            XCTAssertTrue(continued.isValidSave)
            XCTAssertNil(continued.orbit)
            XCTAssertFalse(continued.incoming.contains { $0.gravityKind != nil })
            if let cell = continued.legalGroups.first?.first {
                continued.clear(cell); restored.clear(cell)
                XCTAssertEqual(continued, restored)
            }
        }
    }

    func testRetiresFieldsOrbitWindowsSuspendedSupportsAndHistoricalAccounting() throws {
        for fixture in GravityFixture.allCases {
            var game = fixture.game()
            try verifyRetirement(game)
            if fixture == .opportunity || fixture == .takeNow || fixture == .supports || fixture == .trace {
                let middle = fixture == .supports ? Cell(1, 3) : Cell(0, 3)
                XCTAssertNotNil(game.clear(middle))
                try verifyRetirement(game)
                for _ in 0..<3 { game.letStarsFall(); try verifyRetirement(game) }
            }
        }
    }

    func testAnnouncedMagneticPairBecomesOrdinaryWithoutChangingRNG() throws {
        var old = GravityFixture.naturalOffer.game()
        // This fixture is after the pair lands; replay its seed to capture the committed offer.
        old = old.replay()
        for _ in 0..<36 where !old.isOver {
            if old.incoming.contains(where: { $0.gravityKind != nil }) {
                try verifyRetirement(old)
                let migrated = old.removingGravity()
                var a = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
                var b = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(migrated)) as? [String: Any])
                for key in ["savedGeneration", "incoming"] { a.removeValue(forKey: key); b.removeValue(forKey: key) }
                XCTAssertEqual(try JSONSerialization.data(withJSONObject: a, options: .sortedKeys), try JSONSerialization.data(withJSONObject: b, options: .sortedKeys))
                return
            }
            old.letStarsFall()
            if let cell = old.legalGroups.first?.first { old.clear(cell) }
        }
        XCTFail("The deterministic history must reach an announced magnetic pair")
    }

    func testCurrentSupplyAndReplayNeverProduceGravityButKeepOpalAndStorms() {
        XCTAssertFalse(SkyGeneration.current.supportsGravity)
        var sawOpal = false, sawStorm = false
        for seed in UInt64(0)..<40 {
            var game = FallingSky(seed: seed, generation: .current)
            for _ in 0..<48 where !game.isOver {
                XCTAssertFalse(game.incoming.contains { $0.gravityKind != nil })
                sawOpal = sawOpal || game.incoming.contains(where: \.isLight)
                sawStorm = sawStorm || game.forecastPhase?.isStorm == true
                game.letStarsFall()
                while !game.isOver, let cell = game.legalGroups.first?.first { game.clear(cell) }
                XCTAssertTrue(game.isValidSave)
            }
            XCTAssertEqual(game.replay(), FallingSky(seed: seed, generation: .current))
        }
        XCTAssertTrue(sawOpal); XCTAssertTrue(sawStorm)
        for game in [FallingSky(seed: 1), FallingSky(seed: 1, generation: .opalStorms), FallingSky(challenge: .firstLight)] {
            XCTAssertEqual(game.removingGravity(), game)
        }
    }

    func testRetirementDoesNotReopenAnOverflowedHistoricalSky() throws {
        var game = GravityFixture.opportunity.game()
        game.clear(Cell(0, 3))
        for _ in 0..<100 where !game.isOver { game.letStarsFall() }
        XCTAssertEqual(game.outcome, .lost)
        try verifyRetirement(game)
        XCTAssertEqual(game.removingGravity().outcome, .lost)
    }

    func testGeneratedTerminalRetirementKeepsOutcomeWhenOverflowColumnShrinks() throws {
        var shrinking = 0
        for generation in [SkyGeneration.gravityOrbits, .gravityOpportunities] {
            for seed: UInt64 in 0..<64 {
                var game = FallingSky(seed: seed, generation: generation)
                for _ in 0..<100 where !game.isOver { game.letStarsFall() }
                XCTAssertEqual(game.outcome, .lost)
                let column = try XCTUnwrap(game.blockedColumn)
                let retired = game.removingGravity()
                if SkyBoardSettling.height(retired.board, column: column) < 7 { shrinking += 1 }
                try verifyRetirement(game)
                let bytes = try JSONEncoder().encode(retired)
                var restored = try JSONDecoder().decode(FallingSky.self, from: bytes)
                XCTAssertTrue(restored.isValidSave)
                XCTAssertEqual(restored.outcome, .lost)
                XCTAssertNil(restored.clear(Cell(0, column)))
                XCTAssertNil(restored.letStarsFall())
                XCTAssertFalse(restored.replay().isOver)
                XCTAssertTrue(restored.replay().isValidSave)
            }
        }
        XCTAssertGreaterThan(shrinking, 0, "Exercise a lost column whose retired supports shrink it")
    }

    func testRetiredGenerationCannotSmuggleLiveGravityThroughValidation() throws {
        var old = GravityFixture.opportunity.game(); old.clear(Cell(0, 3))
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as? [String: Any])
        fields["savedGeneration"] = SkyGeneration.standardSky.rawValue
        let forged = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
        XCTAssertFalse(forged.isValidSave)
        XCTAssertTrue(old.removingGravity().isValidSave)
    }

}
