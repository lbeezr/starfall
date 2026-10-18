// Appended to the isolated Core owner, so private setters stay inside their boundary.
public enum WhiteConnectorFixture: String, CaseIterable {
    case connection, pressure
    public var title: String { self == .connection ? "Shared connection" : "Crowded column" }
    public static let guide = "White joins one family and counts as 1. Tap a colored star; clearing spends white."
    public var message: String { Self.guide }
    public func game() -> FallingSky { FallingSky.whiteConnectorFixture(self) }
}

extension FallingSky {
    fileprivate static func whiteConnectorFixture(_ fixture: WhiteConnectorFixture) -> FallingSky {
        // Every board value, identity and counter comes from real committed arrivals.
        // Only the scripted previews are authored; no decoder bypass or invented history.
        var game = FallingSky(seed: 17)
        let arrivals: [(Jewel?, Int, Bool)]
        let next: (Jewel, Int)
        switch fixture {
        case .connection:
            arrivals = [(.rose,0,false), (.amber,0,false), (.aqua,1,false), (nil,1,true),
                        (.aqua,2,false), (.amber,2,false)]
            next = (.amber,2)
        case .pressure:
            arrivals = [(.aqua,0,false), (.aqua,0,false), (.mint,0,false), (.amber,0,false),
                        (.violet,0,false), (.mint,0,false), (.amber,0,false), (.violet,0,false),
                        (nil,1,true), (.rose,2,false), (.rose,2,false), (.rose,2,false)]
            next = (.rose,0)
        }
        for (kind, column, light) in arrivals {
            game.incoming = [.init(id: 0, kind: kind, column: column, light: light)]
            game.letStarsFall()
            precondition(game.isValidSave && !game.isOver)
        }
        game.incoming = [.init(id: 0, kind: next.0, column: next.1)]
        precondition(game.isValidSave)
        return game
    }
}
