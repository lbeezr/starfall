#if DEBUG
/// A deterministic, reset-only native review history. No normal save or alternate app.
public enum CriticalMassFixture {
    public static func game() -> FallingSky {
        var game = FallingSky(seed: 5, balance: .init(pace: .gentle, darkStars: .none),
                              openingCascade: false, generation: .current, criticalMass: true)
        game.scriptGravityShower([(.colored(.aqua), 2), (.colored(.aqua), 2), (.colored(.aqua), 3), (.white, 4), (.colored(.amber), 5)])
        // Keep a young legal family nearby to demonstrate rescue without a scripted outcome.
        for index in 0..<8 {
            game.scriptGravityShower([(.colored(index.isMultiple(of: 2) ? .rose : .mint), index % 2)])
            if game.isOver { break }
        }
        game.setGravityForecast([(.colored(.violet), 6)])
        precondition(game.isValidSave && !game.isOver)
        return game
    }
}
#endif
