/// Small, persisted tuning choices shared by the rules and the app's clock.
public struct StarfallBalance: Codable, Equatable, Sendable {
    public enum Pace: Int, Codable, CaseIterable, Sendable {
        case gentle = 6, steady = 4, brisk = 3
    }

    public enum DarkStarFrequency: String, Codable, CaseIterable, Sendable {
        case none, occasional, regular, frequent

        public var showerGap: ClosedRange<Int>? {
            switch self {
            case .none: nil
            case .occasional: 7...9
            case .regular: 4...6
            case .frequent: 2...3
            }
        }
    }

    public var pace: Pace
    public var darkStars: DarkStarFrequency

    public init(pace: Pace = .brisk, darkStars: DarkStarFrequency = .regular) {
        self.pace = pace
        self.darkStars = darkStars
    }
}
