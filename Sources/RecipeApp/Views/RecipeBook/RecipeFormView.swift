import SwiftData
import SwiftUI

enum RecipeFormMode {
    case create
    case edit(Recipe)
}

struct RecipeFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: RecipeFormMode

    @State private var title = ""
    @State private var summary = ""
    @State private var prepTimeMinutes = 0
    @State private var cookTimeMinutes = 0
    @State private var servings = 1
    @State private var recipeType = RecipeType.dinner
    @State private var ingredientRows: [IngredientRowData] = []
    @State private var instructions: [String] = []

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Summary", text: $summary, axis: .vertical)
                        .lineLimit(2...4)
                    Picker("Type", selection: $recipeType) {
                        ForEach(RecipeType.allTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                Section("Timing & Servings") {
                    Stepper("Prep: \(prepTimeMinutes) min", value: $prepTimeMinutes, in: 0...480, step: 5)
                    Stepper("Cook: \(cookTimeMinutes) min", value: $cookTimeMinutes, in: 0...480, step: 5)
                    Stepper("Servings: \(servings)", value: $servings, in: 1...50)
                }

                Section("Ingredients") {
                    ForEach($ingredientRows) { $row in
                        IngredientRowEditor(row: $row, modelContext: modelContext)
                    }
                    .onDelete { offsets in
                        ingredientRows.remove(atOffsets: offsets)
                    }
                    Button("Add Ingredient", systemImage: "plus.circle") {
                        ingredientRows.append(IngredientRowData())
                    }
                }

                Section("Instructions") {
                    ForEach($instructions.indices, id: \.self) { index in
                        InstructionStepEditor(
                            stepNumber: index + 1,
                            text: $instructions[index]
                        )
                    }
                    .onDelete { offsets in
                        instructions.remove(atOffsets: offsets)
                    }
                    .onMove { from, to in
                        instructions.move(fromOffsets: from, toOffset: to)
                    }
                    Button("Add Step", systemImage: "plus.circle") {
                        instructions.append("")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Recipe" : "New Recipe")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard case .edit(let recipe) = mode else { return }
        title = recipe.title
        summary = recipe.summary
        prepTimeMinutes = recipe.prepTimeMinutes
        cookTimeMinutes = recipe.cookTimeMinutes
        servings = recipe.servings
        recipeType = recipe.recipeType
        instructions = recipe.instructions
        ingredientRows = recipe.recipeIngredients.map { ri in
            IngredientRowData(
                name: ri.ingredient?.displayName ?? "",
                quantity: ri.quantity,
                unit: ri.unit,
                notes: ri.notes,
                existingIngredient: ri.ingredient
            )
        }
    }

    private func save() {
        switch mode {
        case .create:
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
            saveIngredients(for: recipe)

        case .edit(let recipe):
            recipe.title = title.trimmingCharacters(in: .whitespaces)
            recipe.summary = summary.trimmingCharacters(in: .whitespaces)
            recipe.prepTimeMinutes = prepTimeMinutes
            recipe.cookTimeMinutes = cookTimeMinutes
            recipe.servings = servings
            recipe.recipeType = recipeType
            recipe.instructions = instructions.filter {
                !$0.trimmingCharacters(in: .whitespaces).isEmpty
            }
            recipe.updatedAt = Date()

            for ri in recipe.recipeIngredients {
                modelContext.delete(ri)
            }
            saveIngredients(for: recipe)
        }

        try? modelContext.save()
        dismiss()
    }

    private func saveIngredients(for recipe: Recipe) {
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
}

struct IngredientRowData: Identifiable {
    let id = UUID()
    var name = ""
    var quantity: Double = 0
    var unit = ""
    var notes = ""
    var existingIngredient: Ingredient?
}

struct IngredientRowEditor: View {
    @Binding var row: IngredientRowData
    let modelContext: ModelContext

    var body: some View {
        VStack(spacing: 8) {
            IngredientSearchField(text: $row.name, modelContext: modelContext) { ingredient in
                row.name = ingredient.displayName
                row.existingIngredient = ingredient
            }
            HStack {
                TextField("Qty", value: $row.quantity, format: .number)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                    .frame(width: 60)
                TextField("Unit", text: $row.unit)
                    .frame(width: 60)
                TextField("Notes", text: $row.notes)
            }
            .font(.callout)
        }
    }
}

struct InstructionStepEditor: View {
    let stepNumber: Int
    @Binding var text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(stepNumber).")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(width: 28)
            TextField("Step \(stepNumber)", text: $text, axis: .vertical)
                .lineLimit(2...6)
        }
    }
}
