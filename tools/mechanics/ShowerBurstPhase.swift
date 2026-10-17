// Appended only to the isolated burst candidate's existing core target member.
extension StarfallExperiment {
    public enum ShowerPhase: Equatable {
        case preparation(remaining: Int)
        case pressure(remaining: Int)
    }

    public static func showerPhase(for number: Int) -> ShowerPhase {
        let position = max(0, number - 1) % 12
        return position < 9 ? .preparation(remaining: 9 - position)
            : .pressure(remaining: 12 - position)
    }

    static func isPressureShower(_ number: Int) -> Bool {
        guard number > 0 else { return false }
        if case .pressure = showerPhase(for: number) { return true }
        return false
    }
}
