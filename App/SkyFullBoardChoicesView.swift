import SwiftUI
import StarfallCore

/// A disposable analysis of one immutable board. Navigation cancellation reaches
/// the detached scan; canceled work never becomes an empty-result message.
enum SkyFullBoardChoiceAnalysis {
    static func supports(_ snapshot: FallingSky) -> Bool {
        snapshot.usesFullBoardRefill && !snapshot.isOver
    }

    static func load(_ snapshot: FallingSky) async -> [FullBoardChoice]? {
        guard !Task.isCancelled else { return nil }
        let scan = Task.detached(priority: .userInitiated) { snapshot.fullBoardChoices() }
        let result = await withTaskCancellationHandler {
            await scan.value
        } onCancel: {
            scan.cancel()
        }
        guard !Task.isCancelled else { return nil }
        return result
    }
}

/// Copy derives only from Core's visible first pattern and actual exchanges.
/// The view has no mutable game, score prediction, save or supply capability.
struct SkyFullBoardChoicePresentation {
    let choice: FullBoardChoice

    var isSetup: Bool { choice.exchanges.count > 1 }
    func title(number: Int) -> String {
        SkyCopy.text(isSetup ? .fullBoardChoiceSetupTitle : .fullBoardChoiceDirectTitle,
                     values: ["number": String(number)])
    }
    var pattern: String {
        var shapes = Set<StarRecipe.Shape>()
        let names = choice.recipes.filter { shapes.insert($0.shape).inserted }.map(\.title)
        return SkyCopy.text(.fullBoardChoiceFirstPattern,
                            values: ["patterns": names.joined(separator: ", "), "count": String(choice.cleared.count)])
    }
    var instructions: [String] {
        choice.exchanges.enumerated().map { index, exchange in
            SkyCopy.text(.fullBoardChoiceStep, values: [
                "number": String(index + 1),
                "instruction": SkyTutorial.Action.swap(exchange.from, exchange.to).instruction
            ])
        }
    }
}

struct SkyFullBoardChoicesView: View {
    let game: FallingSky
    let done: () -> Void
    @State private var choices: [FullBoardChoice]?
    @State private var revealed: Set<Int> = []
    var offersPractice: Bool { game.usesFullBoardRefill && game.challenge == .firstLight }

    var body: some View {
        SkyMenuSurface(title: SkyCopy.text(.fullBoardChoicesTitle), glyph: .help, done: done,
                       back: true, footerTitle: SkyCopy.text(.actionReturn)) {
            if offersPractice {
                NavigationLink {
                    SkyTutorialView(initial: .fullBoardSurvivors, returnsAfterLesson: true,
                                    endingAfter: .fullBoardImmediate, done: done)
                } label: {
                    SkyMenuRow(SkyCopy.text(.fullBoardCompareClears), glyph: .tutorial, disclosure: true)
                }
                .buttonStyle(StarfallButtonStyle(role: .quiet, expands: true))
                .accessibilityIdentifier("fullBoard.choices.practice")
            }
            Text(SkyCopy.text(.fullBoardChoicesExplanation))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("fullBoard.choices.explanation")
            if let choices {
                if choices.isEmpty {
                    Text(SkyCopy.text(.fullBoardChoicesEmpty))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("fullBoard.choices.empty")
                }
                ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                    SkyMenuRule()
                    plan(SkyFullBoardChoicePresentation(choice: choice), index: index)
                }
            } else {
                ProgressView(SkyCopy.text(.fullBoardChoicesLoading))
                    .font(StarfallTheme.Typography.supporting)
                    .accessibilityIdentifier("fullBoard.choices.loading")
            }
        }
        .task(id: game) {
            choices = nil
            revealed = []
            guard let result = await SkyFullBoardChoiceAnalysis.load(game), !Task.isCancelled else { return }
            choices = result
        }
    }

    private func plan(_ presentation: SkyFullBoardChoicePresentation, index: Int) -> some View {
        SkyMenuSection(presentation.title(number: index + 1)) {
            Text(presentation.pattern)
                .font(StarfallTheme.Typography.supporting)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("fullBoard.choices.pattern.\(index)")
            if presentation.isSetup {
                Text(SkyCopy.text(.fullBoardChoiceSetupExplanation))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button {
                if !revealed.insert(index).inserted { revealed.remove(index) }
            } label: {
                Label {
                    Text(SkyCopy.text(revealed.contains(index) ? .fullBoardChoiceHideSwipes : .fullBoardChoiceShowSwipes))
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    ObservatoryIcon(.direction, size: 18)
                }
            }
            .buttonStyle(StarfallButtonStyle(role: .compact))
            .accessibilityIdentifier("fullBoard.choices.reveal.\(index)")
            if revealed.contains(index) {
                ForEach(Array(presentation.instructions.enumerated()), id: \.offset) { step, instruction in
                    Text(instruction)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("fullBoard.choices.step.\(index).\(step)")
                }
                Text(SkyCopy.text(.practiceCoordinates))
                    .font(StarfallTheme.Typography.skyCaption)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
