import SwiftUI
import StarfallCore

/// Optional goals read committed Core qualifications. A best always belongs to
/// one completed run under this exact contract; this view never combines runs.
struct SkyMasterySnapshot: Equatable {
    enum Context: String { case entry, progress, result }

    let identity: StoryMasteryIdentity
    let earned: Set<StoryMasteryGoal>
    let completedRecord: StoryMasteryRecord?
    let bestRecord: StoryMasteryRecord?
    let context: Context

    init(identity: StoryMasteryIdentity, earned: Set<StoryMasteryGoal> = [],
         completedRecord: StoryMasteryRecord? = nil, bestRecord: StoryMasteryRecord? = nil,
         context: Context) {
        self.identity = identity
        let validCompleted = completedRecord.flatMap { $0.isValid && $0.identity == identity ? $0 : nil }
        self.earned = context == .entry ? [] : context == .result ? validCompleted?.earned ?? []
            : earned.intersection(Set(identity.goals))
        self.completedRecord = validCompleted
        self.bestRecord = bestRecord.flatMap { $0.isValid && $0.identity == identity ? $0 : nil }
        self.context = context
    }

    static func entry(request: SkyEntryRequest?, retainedRound: FallingSky,
                      bestRecords: [StoryMasteryRecord] = []) -> Self? {
        let identity: StoryMasteryIdentity?
        switch request {
        case .firstLight: identity = .available(for: .freshChallenge(.firstLight))
        case .fullBoardLantern: identity = .available(for: .fullBoardLantern())
        case .replay: identity = retainedRound.masteryEnrollment?.identity
        default: identity = nil
        }
        guard let identity else { return nil }
        return Self(identity: identity, bestRecord: best(in: bestRecords, for: identity), context: .entry)
    }

    static func current(game: FallingSky, bestRecords: [StoryMasteryRecord] = [],
                        context: Context) -> Self? {
        guard let progress = game.masteryProgress,
              context != .result || game.completedMasteryRun != nil else { return nil }
        return Self(identity: progress.identity, earned: progress.earned,
                    completedRecord: game.completedMasteryRun,
                    bestRecord: best(in: bestRecords, for: progress.identity), context: context)
    }

    static func best(in records: [StoryMasteryRecord], for identity: StoryMasteryIdentity) -> StoryMasteryRecord? {
        records.reduce(nil) { best, candidate in
            guard candidate.isValid, candidate.identity == identity else { return best }
            guard let best else { return candidate }
            return candidate.rank > best.rank ? candidate : best
        }
    }

    var identifier: String { "sky.mastery.\(context.rawValue)" }
    var title: String { SkyCopy.text(context == .result ? .masteryResultTitle : .masteryTitle) }
    var explanation: String { SkyCopy.text(context == .result ? .masteryResultExplanation : .masteryExplanation) }
    var rank: Int? { context == .result ? completedRecord?.rank : nil }
    var ratingLabel: String? { rank.map { SkyCopy.text(.masteryRating, values: ["count": String($0)]) } }
    var bestLabel: String? {
        bestRecord.map { SkyCopy.text(.masteryBest, values: ["count": String($0.rank)]) }
    }
    var modeTitle: String { Self.modeTitle(for: identity) }

    static func modeTitle(for identity: StoryMasteryIdentity) -> String {
        SkyCopy.text(identity.goals.contains(.largeClear) ? .fullBoardMode : .fallingSkyMode)
    }

    func goalLabel(_ goal: StoryMasteryGoal) -> String {
        switch goal {
        case .grownCollection: SkyCopy.text(.masteryGrownGoal)
        case .cascade: SkyCopy.text(.masteryCascadeGoal)
        case .largeClear: SkyCopy.text(.masteryLargeClearGoal)
        }
    }

    func goalDetail(_ goal: StoryMasteryGoal) -> String {
        switch goal {
        case .grownCollection: SkyCopy.text(.masteryGrownDetail)
        case .cascade: SkyCopy.text(identity.goals.contains(.largeClear) ? .masteryRefillCascadeDetail : .masteryCascadeDetail)
        case .largeClear: SkyCopy.text(.masteryLargeClearDetail)
        }
    }

    func goalState(_ goal: StoryMasteryGoal) -> String {
        SkyCopy.text(earned.contains(goal) ? .masteryEarned : context == .result ? .masteryNotEarned : .masteryNotYet)
    }
}

/// Native text and existing glyphs remain readable at large text sizes. These
/// rows have no input, timers, animation or persistence capabilities.
struct SkyMasteryView: View {
    let snapshot: SkyMasterySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.medium) {
            Text(snapshot.title)
                .font(StarfallTheme.Typography.skyHeading)
                .accessibilityAddTraits(.isHeader)
            if let rating = snapshot.ratingLabel {
                Label { Text(rating) } icon: { ObservatoryIcon(.freePlay, size: 20) }
                    .foregroundStyle(StarfallTheme.Ceremony.gold)
                    .accessibilityIdentifier(snapshot.identifier + ".rating")
            }
            ForEach(snapshot.identity.goals, id: \.self) { goal in
                goalRow(goal)
            }
            Text(snapshot.explanation)
                .font(StarfallTheme.Typography.supporting)
                .foregroundStyle(StarfallTheme.Colors.textSecondary)
            if let best = snapshot.bestLabel {
                Text(best)
                    .font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                    .accessibilityIdentifier(snapshot.identifier + ".best")
            }
        }
        .foregroundStyle(StarfallTheme.Colors.textPrimary)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(snapshot.identifier)
    }

    private func goalRow(_ goal: StoryMasteryGoal) -> some View {
        HStack(alignment: .top, spacing: StarfallTheme.Spacing.small) {
            ObservatoryIcon(snapshot.earned.contains(goal) ? .check : .freePlay, size: 18)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
                Text(snapshot.goalLabel(goal)).font(StarfallTheme.Typography.supporting)
                Text(snapshot.goalDetail(goal))
                    .font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                if snapshot.context != .entry {
                    Text(snapshot.goalState(goal))
                        .font(StarfallTheme.Typography.skyCaption)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(snapshot.goalLabel(goal) + ". " + snapshot.goalDetail(goal))
        .accessibilityValue(snapshot.goalState(goal))
        .accessibilityIdentifier(snapshot.identifier + ".goal." + goalIdentifier(goal))
    }

    private func goalIdentifier(_ goal: StoryMasteryGoal) -> String {
        switch goal {
        case .grownCollection: "grownCollection"
        case .cascade: "cascade"
        case .largeClear: "largeClear"
        }
    }
}

struct SkyMasteryBestSnapshot: Equatable, Identifiable {
    let identity: StoryMasteryIdentity
    let record: StoryMasteryRecord?

    var id: String { identity.goals.contains(.largeClear) ? "fullBoard" : "fallingSky" }
    var label: String {
        let mode = SkyMasterySnapshot.modeTitle(for: identity)
        return record.map {
            SkyCopy.text(.masteryModeBest, values: ["mode": mode, "count": String($0.rank)])
        } ?? SkyCopy.text(.masteryModeNoResult, values: ["mode": mode])
    }

    static func lantern(records: [StoryMasteryRecord]) -> [Self] {
        [FallingSky.freshChallenge(.firstLight), .fullBoardLantern()].compactMap { game in
            guard let identity = StoryMasteryIdentity.available(for: game) else { return nil }
            return Self(identity: identity, record: SkyMasterySnapshot.best(in: records, for: identity))
        }
    }
}
