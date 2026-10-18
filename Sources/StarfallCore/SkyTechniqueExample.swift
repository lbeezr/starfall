import Foundation

#if DEBUG
/// Authored review boards, never normal saved skies or alternate shower generators.
public enum SkyTechniqueExample: String, CaseIterable, Sendable {
    case trim, dropIn, bank, fork, relay, doubleSetup, rescue, nudge, trace
    public var title: String {
        switch self {
        case .trim: "Trim"; case .dropIn: "Drop-in"; case .bank: "Bank"; case .fork: "Fork"
        case .relay: "Relay"; case .doubleSetup: "Double setup"; case .rescue: "Rescue"; case .nudge: "Nudge"
        case .trace: "Selected constellation"
        }
    }
    public var rows: [String] {
        switch self {
        case .trim: ["ASPPA..","SSAAP..","SSA.S..","AA.....",".S....."]
        case .dropIn: ["AAS....","ASS....",".A....."]
        case .bank: ["PPAAA..","PPPSP..","SPPP...","PSPS..."]
        case .fork: ["PPAPP..","SSSSP..","SSS.A..","SSP....","PPP...."]
        case .relay: ["SSA....","SSA....",".A.....",".A....."]
        case .doubleSetup: ["PSAPP..","SSSAP..","ASAPA..","PAPPP..","PAPS..."]
        case .rescue: ["AAAD.PP","SP...PP","PS.....","SP.....","PS.....","SP....."]
        case .nudge: ["AAP....","APA...."]
        case .trace: ["AAAAAA."]
        }
    }
    public func game() -> FallingSky {
        let kinds: [Character: Jewel] = ["A": .aqua, "S": .amber, "P": .mint]
        var board: [StarfallGem?] = Array(repeating: nil, count: 49)
        var id = 0
        for (row,text) in rows.enumerated() {
            for (column,key) in text.enumerated() where key != "." {
                board[row*7+column] = .init(id:id,kind:kinds[key]); id += 1
            }
        }
        return FallingSky(board:board,incoming:[.init(id:100,kind:.rose,column:6)])
    }
}
#endif
