import SwiftUI
import StarfallCore

/// Tap and accessibility equivalents for exact recipes and landed-star moves.
@MainActor struct SkyTechniqueControls: View {
    let intent: SkyTechniqueIntent
    let game: FallingSky
    let enabled: Bool
    let message: String
    let perform: (SkyBoardAction, FallingSky, UInt64) -> Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    private var layout: AnyLayout {
        typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: StarfallTheme.Spacing.small))
            : AnyLayout(HStackLayout(spacing: StarfallTheme.Spacing.small))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            if intent.anchor == nil {
                Text("Tap a star to move it or choose a recipe.")
                    .font(StarfallTheme.Typography.supporting)
            }
            if let cell = intent.anchor, let snapshot = intent.snapshot {
                let selectionID = intent.selectionID
                let options = snapshot.recipes(containing: cell)
                if let selected = intent.recipe, !options.isEmpty {
                    Menu {
                        ForEach(options) { recipe in
                            Button(recipeTitle(recipe)) { intent.chooseRecipe(recipe.id,selectionID:selectionID) }
                        }
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: StarfallTheme.Spacing.small) {
                            Text(recipeTitle(selected)).fixedSize(horizontal:false,vertical:true)
                            Image(systemName:"chevron.up.chevron.down").accessibilityHidden(true)
                        }
                        .font(StarfallTheme.Typography.supporting)
                        .frame(maxWidth:.infinity,minHeight:StarfallTheme.Layout.minimumTarget,alignment:.leading)
                    }
                    .buttonStyle(StarfallGameButtonStyle())
                    .accessibilityLabel("Recipe").accessibilityValue(recipeTitle(selected))
                    .accessibilityIdentifier("technique.recipePicker")
                }
                layout {
                    move("Left", from: cell, to: Cell(cell.row,cell.column-1), selectionID: selectionID)
                    move("Right", from: cell, to: Cell(cell.row,cell.column+1), selectionID: selectionID)
                    if let recipe = intent.recipe {
                        Button("Clear \(recipe.shape.rawValue)") { commit(.recipe(recipe),selectionID: selectionID) }
                            .accessibilityIdentifier("technique.activate")
                            .disabled(!enabled)
                    }
                    Button("Cancel") { _ = intent.consumeSelection(selectionID) }.accessibilityIdentifier("technique.cancel")
                }.buttonStyle(StarfallGameButtonStyle())
            }
            if intent.anchor == nil {
                Text(message).font(StarfallTheme.Typography.skyCaption)
                    .accessibilityIdentifier("technique.result")
            }
        }
        .foregroundStyle(StarfallTheme.Colors.textPrimary)
        .padding(StarfallTheme.Spacing.medium)
        .background(StarfallTheme.Colors.surface, in: RoundedRectangle(cornerRadius: StarfallTheme.Radius.panel))
    }

    private func recipeTitle(_ recipe: StarRecipe) -> String {
        "\(recipe.shape.rawValue.capitalized) · \(recipe.cells.count) stars · row \(7-recipe.cells[0].row), column \(recipe.cells[0].column+1)"
    }

    private func move(_ title: String, from: Cell, to: Cell, selectionID: UInt64) -> some View {
        Button(title) { commit(.nudge(from,to),selectionID: selectionID) }
            .accessibilityLabel("Move star \(title.lowercased())")
            .accessibilityIdentifier("technique.move.\(title.lowercased())")
            .disabled(!enabled || !game.canNudge(from: from, to: to))
    }
    private func commit(_ action: SkyBoardAction, selectionID: UInt64) {
        guard let (snapshot,ticket) = intent.consumeSelection(selectionID) else { return }
        _ = perform(action, snapshot, ticket)
    }
}

struct SkyArrangeAccessibilityAction: ViewModifier {
    let enabled: Bool
    let action: () -> Void
    @ViewBuilder func body(content: Content) -> some View {
        if enabled { content.accessibilityAction(named:Text("Arrange this star")) { action() } }
        else { content }
    }
}
