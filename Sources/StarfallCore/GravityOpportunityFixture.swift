#if DEBUG
/// Natural candidate seed 421, collision-first policy, before the shower-10 clear.
/// Replays seven real clears; no authored board, counters, forecasts or RNG injection.
public enum GravityOpportunityFixture {
    public static func game(through target:Int = 10) -> FallingSky {
        precondition((1...10).contains(target))
        let history:[Int:(Cell,Int)] = [
            1:(Cell(0,2),3),3:(Cell(0,0),3),4:(Cell(0,0),4),5:(Cell(0,4),5),
            6:(Cell(0,3),3),8:(Cell(0,0),3),9:(Cell(0,3),3)
        ]
        var game=FallingSky(seed:421,generation:.gravityOpportunities)
        for shower in 1...target {
            let turn=game.letStarsFall()
            precondition(turn != nil && !game.isOver)
            if let (cell,reward)=history[shower] {precondition(game.clear(cell)?.collected==reward)}
            precondition(game.isValidSave)
        }
        if target==10 {precondition(game.score==24 && game.orbit?.windowsRemaining==2)}
        return game
    }
}
#endif
