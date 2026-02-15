import SwiftData
import SwiftUI

struct RecipeBuilderView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var editorMinimized = false
    @State private var tipsMinimized = true

    var body: some View {
        NavigationStack {
            Group {
                if sizeClass == .regular {
                    HStack(spacing: 0) {
                        panes
                    }
                } else {
                    RecipeEditorPane()
                }
            }
            .navigationTitle("Recipe Builder")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    @ViewBuilder
    private var panes: some View {
        MinimizablePane(
            title: "Editor",
            icon: "pencil",
            isMinimized: $editorMinimized
        ) {
            RecipeEditorPane()
        }

        Divider()

        MinimizablePane(
            title: "Tips",
            icon: "lightbulb",
            isMinimized: $tipsMinimized
        ) {
            RecipeTipsPane()
        }
    }
}

struct MinimizablePane<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isMinimized: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isMinimized {
            Button {
                withAnimation { isMinimized = false }
            } label: {
                Label(title, systemImage: icon)
                    .font(.caption)
                    .padding(8)
            }
        } else {
            VStack(spacing: 0) {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.subheadline.bold())
                    Spacer()
                    Button {
                        withAnimation { isMinimized = true }
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.bar)

                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct RecipeEditorPane: View {
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var summary = ""
    @State private var recipeType = RecipeType.dinner
    @State private var prepTimeMinutes = 0
    @State private var cookTimeMinutes = 0
    @State private var servings = 1
    @State private var ingredientRows: [IngredientRowData] = []
    @State private var instructions: [String] = [""]

    var body: some View {
        Form {
            Section("Details") {
                TextField("Recipe Title", text: $title)
                TextField("Summary", text: $summary, axis: .vertical)
                    .lineLimit(2...4)
                Picker("Type", selection: $recipeType) {
                    ForEach(RecipeType.allTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            }

            Section("Timing") {
                Stepper("Prep: \(prepTimeMinutes) min", value: $prepTimeMinutes, in: 0...480, step: 5)
                Stepper("Cook: \(cookTimeMinutes) min", value: $cookTimeMinutes, in: 0...480, step: 5)
                Stepper("Servings: \(servings)", value: $servings, in: 1...50)
            }

            Section("Ingredients") {
                ForEach($ingredientRows) { $row in
                    IngredientRowEditor(row: $row, modelContext: modelContext)
                }
                .onDelete { ingredientRows.remove(atOffsets: $0) }
                Button("Add Ingredient", systemImage: "plus.circle") {
                    ingredientRows.append(IngredientRowData())
                }
            }

            Section("Instructions") {
                ForEach($instructions.indices, id: \.self) { index in
                    InstructionStepEditor(stepNumber: index + 1, text: $instructions[index])
                }
                .onDelete { instructions.remove(atOffsets: $0) }
                .onMove { instructions.move(fromOffsets: $0, toOffset: $1) }
                Button("Add Step", systemImage: "plus.circle") {
                    instructions.append("")
                }
            }

            Section {
                Button("Save Recipe", systemImage: "checkmark") {
                    saveRecipe()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func saveRecipe() {
        let recipe = Recipe(
            title: title.trimmingCharacters(in: .whitespaces),
            summary: summary.trimmingCharacters(in: .whitespaces),
            prepTimeMinutes: prepTimeMinutes,
            cookTimeMinutes: cookTimeMinutes,
            servings: servings,
            recipeType: recipeType,
            instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        )
        modelContext.insert(recipe)

        for row in ingredientRows where !row.name.trimmingCharacters(in: .whitespaces).isEmpty {
            let ingredient = row.existingIngredient ?? findOrCreateIngredient(name: row.name)
            let ri = RecipeIngredient(
                quantity: row.quantity,
                unit: row.unit,
                notes: row.notes,
                recipe: recipe,
                ingredient: ingredient
            )
            modelContext.insert(ri)
        }

        try? modelContext.save()
        resetForm()
    }

    private func findOrCreateIngredient(name: String) -> Ingredient {
        let lowered = name.lowercased()
        let descriptor = FetchDescriptor<Ingredient>(
            predicate: #Predicate { $0.name == lowered }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let ingredient = Ingredient(name: name)
        modelContext.insert(ingredient)
        return ingredient
    }

    private func resetForm() {
        title = ""
        summary = ""
        recipeType = RecipeType.dinner
        prepTimeMinutes = 0
        cookTimeMinutes = 0
        servings = 1
        ingredientRows = []
        instructions = [""]
    }
}

struct RecipeTipsPane: View {
    private let tips = [
        (icon: "star", title: "Start Simple", detail: "Name your recipe and pick a type before adding ingredients."),
        (icon: "scalemass", title: "Consistent Units", detail: "Use the same units across recipes (e.g., always grams or always cups) for accurate shopping lists."),
        (icon: "person.2", title: "Servings Matter", detail: "Set accurate serving counts so meal plan scaling works correctly."),
        (icon: "clock", title: "Prep vs Cook Time", detail: "Separate prep and cook times help with meal planning around your schedule."),
        (icon: "list.number", title: "Clear Steps", detail: "Write each instruction as a single action. Short steps are easier to follow while cooking."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(tips, id: \.title) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: tip.icon)
                            .font(.title3)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tip.title)
                                .font(.subheadline.bold())
                            Text(tip.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }
}
