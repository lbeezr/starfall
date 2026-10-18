public enum GravityFixture: String, CaseIterable, Sendable {
    case opportunity, takeNow, stranded, supports, trace
    public var title: String { if self == .trace { return "Trace a captive" }; if self == .supports { return "Release suspended stars" }; if self == .stranded { return "Release a lone magnet" }; return self == .opportunity ? "Wait for the connection" : "Take the connection now" }
    public var message: String {
        if self == .trace { return "Clear the pink middle, then trace five aqua stars including the captive to release the orbit." }
        if self == .supports { return "Clear the pink middle, then the front aqua group. Captives hold their positions until the hole closes." }
        if self == .stranded { return "Clear the aqua group beside the lone magnet. No partner is required to remove it." }
        return self == .opportunity
        ? "Clear the pink middle. A hole catches the two survivors. Next shower swaps them into matching neighbors."
        : "Clear the pink middle. The captured stars already have matching neighbors; another rotation breaks those connections."
    }
    public func game() -> FallingSky {
        var game = FallingSky(seed: 5, balance: .init(pace: .gentle, darkStars: .none), openingCascade: false)
        if self == .trace {
            game = GravityFixture.takeNow.game()
            for _ in 0..<10 { game.scriptGravityShower([(.colored(.aqua),2)]) }
            game.setGravityForecast([(.colored(.violet),6)])
            return game
        }
        if self == .supports {
            game.scriptGravityShower([(.colored(.aqua),0),(.colored(.aqua),1),(.colored(.aqua),2),(.colored(.mint),3),(.colored(.mint),4)])
            game.scriptGravityShower([(.magnet,2),(.magnet,4),(.colored(.rose),3)])
            game.scriptGravityShower([(.colored(.amber),2),(.colored(.violet),4),(.colored(.rose),3)])
            game.scriptGravityShower([(.colored(.rose),3)])
            game.scriptGravityShower([(.colored(.amber),3)])
            game.setGravityForecast([(.colored(.violet),2)])
            return game
        }
        if self == .stranded {
            game.scriptGravityShower([(.colored(.aqua),1),(.colored(.aqua),2),(.magnet,3)])
            game.scriptGravityShower([(.colored(.aqua),1)])
            return game
        }
        // All fixture pieces arrive through normal committed showers, including growth.
        game.scriptGravityShower([(.magnet,2),(.magnet,4),(.colored(.rose),3)])
        game.scriptGravityShower([(.colored(.aqua),2),(.colored(.amber),4),(.colored(.rose),3)])
        game.scriptGravityShower([(.colored(.rose),3)])
        let left: Jewel = self == .opportunity ? .amber : .aqua
        let right: Jewel = self == .opportunity ? .aqua : .amber
        game.scriptGravityShower([(.colored(left),1),(.colored(right),5)])
        game.scriptGravityShower([(.colored(left),1),(.colored(right),5)])
        // Explicit local future: normal generated arrivals resume after this forecast.
        game.setGravityForecast([(.colored(.violet),6)])
        precondition(game.isValidSave)
        return game
    }
}
extension FallingSky {
    fileprivate mutating func setGravityForecast(_ items: [(SkyIdentity,Int)]) {
        incoming = items.enumerated().map { index, item in
            let kind: Jewel?
            let gravity: GravityKind?
            switch item.0 {
            case .colored(let family): kind = family; gravity = nil
            case .dusk: kind = nil; gravity = nil
            case .magnet: kind = nil; gravity = .magnet
            case .white: preconditionFailure("White/gravity fixtures are outside this comparison")
            case .hole: preconditionFailure("Holes form only by collision")
            }
            return IncomingStar(id: turns*5+index, kind: kind, column: item.1, gravity: gravity)
        }
    }
    fileprivate mutating func scriptGravityShower(_ items: [(SkyIdentity,Int)]) {
        setGravityForecast(items)
        precondition(letStarsFall() != nil && isValidSave)
    }
}

extension GravityFixture {
    static func duskBoundaryGame() -> FallingSky {
        var game=FallingSky(seed:5,balance:.init(pace:.gentle,darkStars:.none),openingCascade:false)
        game.scriptGravityShower([(.magnet,3),(.dusk,2),(.colored(.mint),1)])
        game.scriptGravityShower([(.colored(.mint),1)])
        game.scriptGravityShower([(.colored(.mint),1)])
        return game
    }
    /// Committed sparse histories for bounded zero/one/three-captive edge checks.
    static func sparse(captives: Int) -> FallingSky {
        precondition((0...3).contains(captives))
        var game=FallingSky(seed:5,balance:.init(pace:.gentle,darkStars:.none),openingCascade:false)
        game.scriptGravityShower([(.magnet,2),(.magnet,4),(.colored(.rose),3)])
        game.scriptGravityShower([(.colored(.rose),3)])
        game.scriptGravityShower([(.colored(.rose),3)])
        if captives > 0 { game.scriptGravityShower([(.colored(.aqua),2)]) }
        if captives > 1 { game.scriptGravityShower([(.colored(.amber),4)]) }
        if captives > 2 { game.scriptGravityShower([(.colored(.violet),3)]) }
        return game
    }
}
