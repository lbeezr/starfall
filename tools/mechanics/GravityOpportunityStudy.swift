// Appended to the existing study source for its canonical private action helpers.
private struct GravitySupplyRound: Codable {
    let seed: UInt64
    let showers: Int
    let score: Int
    let overflow: Bool
    let pairOffers: Int
    let fieldsCreated: Int
}
private struct GravitySupplyMove: Codable { let shower: Int; let action: Action }
private struct GravitySupplyExample: Codable {
    let seed: UInt64
    let policy: String
    let generation: SkyGeneration
    let initial: FallingSky
    let history: [GravitySupplyMove]
    let offeredOnExtraWindow: Bool
    let actions: [Action]
    let immediateTotals: [Int]
}
private struct GravitySupplySummary: Codable {
    let generation: SkyGeneration
    let policy: String
    var counts: [String: Int] = [:]
    var rounds: [GravitySupplyRound] = []
    var example: GravitySupplyExample?
}
private func gravityOpportunityStudy() throws {
    let start=UInt64(CommandLine.arguments[2])!, count=Int(CommandLine.arguments[3])!, limit=Int(CommandLine.arguments[4])!
    var reports:[GravitySupplySummary]=[]
    for generation in [SkyGeneration.gravityOrbits,.gravityOpportunities] {
        for collisionFirst in [false,true] {
            let policy=collisionFirst ? "collision-first-then-visible-reward" : "largest-immediate"
            var report=GravitySupplySummary(generation:generation,policy:policy)
            for seed in start..<(start+UInt64(count)) {
                var game=FallingSky(seed:seed,generation:generation), offers=0, created=0, dry=0
                var history:[GravitySupplyMove]=[], lastPairOffer=0, cycles:Set<Int>=[]
                while game.turns<limit && !game.isOver {
                    if game.incoming.contains(where:{$0.gravityKind == .magnet}) {
                        offers += 1;lastPairOffer=game.turns+1
                        precondition(cycles.insert(game.turns/12).inserted,"More than one magnetic offer in a cycle")
                    }
                    game.letStarsFall();precondition(game.isValidSave)
                    if game.isOver {break}
                    let source=game
                    let alternatives=choices(game,subsets:game.board.contains{$0?.isLight==true})
                    report.counts["decisionStates",default:0] += 1
                    if !alternatives.complete {report.counts["cappedStates",default:0] += 1}
                    if alternatives.actions.isEmpty {dry += 1;report.counts["noClearStates",default:0] += 1}
                    report.counts["maximumConsecutiveNoClear",default:0]=max(report.counts["maximumConsecutiveNoClear",default:0],dry)
                    if !alternatives.actions.isEmpty {dry=0}
                    let evaluated=alternatives.actions.map { action -> (Action,FallingSky,Int) in
                        var result=source
                        commit(action,&result)
                        let total=action.light+(bestClear(result)?.light ?? 0)
                        precondition(result.turns==source.turns && result.incoming==source.incoming)
                        return (action,result,total)
                    }
                    let hasField=game.orbit != nil
                    let extraWindow=lastPairOffer%12 == 7
                    if hasField {
                        report.counts["activeFieldStates",default:0] += 1
                        if extraWindow {report.counts["fieldStatesFromExtraWindow",default:0] += 1}
                    }
                    let collisionOptions=evaluated.filter{!hasField && $0.1.orbit != nil}
                    if !collisionOptions.isEmpty {report.counts["statesWithLegalCollision",default:0] += 1}
                    if hasField && alternatives.actions.count>1 {
                        report.counts["fieldStatesWithMultipleSelections",default:0] += 1
                        if Set(evaluated.map{$0.2}).count>1 {
                            report.counts["fieldStatesWithDifferentImmediateTotals",default:0] += 1
                            let byReward=Dictionary(grouping:evaluated,by:{$0.0.light})
                            let cohorts=byReward.keys.sorted().compactMap{byReward[$0]}.filter {Set($0.map{$0.2}).count>1}
                            if !cohorts.isEmpty {
                                report.counts["fieldStatesWithEqualRewardFollowupChoice",default:0] += 1
                                if extraWindow {report.counts["extraWindowEqualRewardFollowupChoices",default:0] += 1}
                            }
                            if alternatives.complete && (report.example == nil || (extraWindow && !report.example!.offeredOnExtraWindow)) {
                                let pool=cohorts.first ?? evaluated
                                let sorted=pool.sorted{$0.2 == $1.2 ? $0.0.selected<$1.0.selected : $0.2>$1.2}
                                report.example = .init(seed:seed,policy:policy,generation:generation,initial:source,history:history,
                                    offeredOnExtraWindow:extraWindow,actions:[sorted.first!.0,sorted.last!.0],
                                    immediateTotals:[sorted.first!.2,sorted.last!.2])
                            }
                        }
                    }
                    let preferred=collisionFirst && !collisionOptions.isEmpty ? collisionOptions.map{$0.0} : alternatives.actions
                    if let selected=select(preferred,preserveTies:false) {
                        let before=game.orbit
                        commit(selected,&game)
                        history.append(.init(shower:game.turns,action:selected))
                        if before == nil && game.orbit != nil {created += 1}
                    }
                    precondition(game.isValidSave)
                    let restored=try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game))
                    precondition(restored==game)
                }
                report.rounds.append(.init(seed:seed,showers:game.turns,score:game.score,overflow:game.isOver,pairOffers:offers,fieldsCreated:created))
            }
            reports.append(report)
        }
    }
    struct Report:Codable {let seedStart:UInt64;let seeds:Int;let showerLimit:Int;let summaries:[GravitySupplySummary]}
    let encoder=JSONEncoder();encoder.outputFormatting=[.prettyPrinted,.sortedKeys]
    FileHandle.standardOutput.write(try encoder.encode(Report(seedStart:start,seeds:count,showerLimit:limit,summaries:reports)))
}
