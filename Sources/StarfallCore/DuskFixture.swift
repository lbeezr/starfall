#if DEBUG
/// Reset-only native checks use committed showers, not production save injection.
public enum DuskFixture: String, CaseIterable {
    case unfed, feeding, imminent, starved, zeroClear
    public func game() -> FallingSky {
        var game = FallingSky(seed: 5, balance: .init(pace: .gentle, darkStars: .none),
                              openingCascade: false, generation: .current, duskRule: .feeding)
        if self == .starved {
            game.scriptGravityShower([(.dusk,3)])
            game.setGravityForecast([(.colored(.aqua),3)])
            return game
        }
        if self == .zeroClear {
            game.scriptGravityShower([(.dusk,0),(.colored(.mint),1),(.colored(.mint),1),(.colored(.mint),2),(.dusk,2)])
            game.setGravityForecast([(.colored(.rose),6)])
            return game
        }
        game.scriptGravityShower([(.colored(.amber),2),(.colored(.amber),2),(.colored(.amber),2),(.colored(.mint),4),(.dusk,3)])
        if self == .unfed { game.setGravityForecast([(.colored(.rose),3)]); return game }
        game.scriptGravityShower([(.colored(.rose),3)])
        if self == .feeding { game.setGravityForecast([(.colored(.violet),6)]); return game }
        game.scriptGravityShower([(.colored(.violet),6)])
        game.setGravityForecast([(.colored(.aqua),2)])
        precondition(game.isValidSave)
        return game
    }
}
#endif
