import Foundation

public enum StoryMasteryGoal: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case grownCollection, cascade, largeClear
}

/// Content and goal meanings remain distinct from ordinary repaired/access state.
public struct StoryMasteryIdentity: Codable, Equatable, Sendable {
    public let challenge: StarfallChallenge
    public let contentRevision: Int
    public let goalSetRevision: Int

    public init(challenge: StarfallChallenge, contentRevision: Int, goalSetRevision: Int) {
        self.challenge = challenge
        self.contentRevision = contentRevision
        self.goalSetRevision = goalSetRevision
    }

    public var isValid: Bool {
        challenge == .firstLight && [4,6].contains(contentRevision) && goalSetRevision == 1
    }

    public var goals: [StoryMasteryGoal] {
        guard isValid else { return [] }
        return contentRevision == 4 ? [.grownCollection,.cascade] : [.cascade,.largeClear]
    }

    /// Availability names a supported contract; it does not enroll a saved run.
    public static func available(for game: FallingSky) -> Self? {
        guard game.challenge == .firstLight, [4,6].contains(game.challengeRevision) else { return nil }
        return Self(challenge: .firstLight, contentRevision: game.challengeRevision, goalSetRevision: 1)
    }
}

public struct StoryMasteryEnrollment: Codable, Equatable, Sendable {
    public let identity: StoryMasteryIdentity
    public let runID: UUID

    public init(identity: StoryMasteryIdentity, runID: UUID) {
        self.identity = identity
        self.runID = runID
    }
}

public struct StoryMasteryProgress: Equatable, Sendable {
    public let identity: StoryMasteryIdentity
    public let earned: Set<StoryMasteryGoal>
    public var goals: [StoryMasteryGoal] { identity.goals }

    init(identity: StoryMasteryIdentity, earned: Set<StoryMasteryGoal>) {
        self.identity = identity
        self.earned = earned
    }
}

/// A bounded, validated winning proof. Rank and goals always derive from the
/// committed round, rather than trusting separately encoded presentation flags.
public struct StoryMasteryRecord: Codable, Equatable, Sendable {
    private let game: FallingSky

    public init?(game: FallingSky) {
        guard game.isValidSave, game.outcome == .won, game.masteryEnrollment != nil else { return nil }
        self.game = game
    }

    public var identity: StoryMasteryIdentity { game.masteryEnrollment!.identity }
    public var runID: UUID { game.masteryEnrollment!.runID }
    public var earned: Set<StoryMasteryGoal> { game.masteryProgress!.earned }
    public var rank: Int { 1 + earned.count }
    public var isValid: Bool { game.isValidSave && game.outcome == .won && game.masteryEnrollment != nil }

    private enum CodingKeys: String, CodingKey { case game }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try values.decode(FallingSky.self, forKey: .game)
        guard let valid = Self(game: decoded) else {
            throw DecodingError.dataCorruptedError(forKey: .game, in: values,
                                                   debugDescription: "Unsupported or invalid completed mastery round")
        }
        self = valid
    }
}
