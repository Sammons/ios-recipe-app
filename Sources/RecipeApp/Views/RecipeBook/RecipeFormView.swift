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
    @State private var caloriesPerServing = 0
    @State private var proteinGramsPerServing = 0
    @State private var carbsGramsPerServing = 0
    @State private var fatGramsPerServing = 0
    @State private var fiberGramsPerServing = 0
    @State private var sugarGramsPerServing = 0
    @State private var sodiumMgPerServing = 0
    @State private var allergenInfo = ""
    @State private var recipeType = RecipeType.dinner
    @State private var ingredientRows: [IngredientRowData] = []
    @State private var instructions: [String] = []
    @State private var saveError: String?

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

                Section("Nutrition & Allergens") {
                    Stepper(
                        "Calories/serving: \(caloriesPerServing == 0 ? "Unknown" : "\(caloriesPerServing)")",
                        value: $caloriesPerServing,
                        in: 0...5000,
                        step: 10
                    )
                    Stepper("Protein: \(proteinGramsPerServing)g", value: $proteinGramsPerServing, in: 0...500)
                    Stepper("Carbs: \(carbsGramsPerServing)g", value: $carbsGramsPerServing, in: 0...500)
                    Stepper("Fat: \(fatGramsPerServing)g", value: $fatGramsPerServing, in: 0...500)
                    Stepper("Fiber: \(fiberGramsPerServing)g", value: $fiberGramsPerServing, in: 0...200)
                    Stepper("Sugar: \(sugarGramsPerServing)g", value: $sugarGramsPerServing, in: 0...300)
                    Stepper("Sodium: \(sodiumMgPerServing)mg", value: $sodiumMgPerServing, in: 0...10000, step: 25)
                    TextField("Allergens (comma-separated)", text: $allergenInfo, axis: .vertical)
                        .lineLimit(1...3)
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
            .alert(
                "Could Not Save",
                isPresented: Binding(
                    get: { saveError != nil },
                    set: { if !$0 { saveError = nil } }
                )
            ) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "An unknown error occurred.")
            }
        }
    }

    private func loadExisting() {
        guard case .edit(let recipe) = mode else { return }
        title = recipe.title
        summary = recipe.summary
        prepTimeMinutes = recipe.prepTimeMinutes
        cookTimeMinutes = recipe.cookTimeMinutes
        servings = recipe.servings
        caloriesPerServing = recipe.caloriesPerServing
        proteinGramsPerServing = recipe.proteinGramsPerServing
        carbsGramsPerServing = recipe.carbsGramsPerServing
        fatGramsPerServing = recipe.fatGramsPerServing
        fiberGramsPerServing = recipe.fiberGramsPerServing
        sugarGramsPerServing = recipe.sugarGramsPerServing
        sodiumMgPerServing = recipe.sodiumMgPerServing
        allergenInfo = recipe.allergenInfo
        recipeType = recipe.recipeType
        instructions = recipe.instructions
        ingredientRows = recipe.recipeIngredients.map { ri in
            IngredientRowData(
                name: ri.ingredient?.displayName ?? "",
                quantity: ri.quantity,
                unit: ri.unit,
                notes: ri.notes,
                category: ri.ingredient?.category ?? IngredientCategory.other,
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
                caloriesPerServing: caloriesPerServing,
                proteinGramsPerServing: proteinGramsPerServing,
                carbsGramsPerServing: carbsGramsPerServing,
                fatGramsPerServing: fatGramsPerServing,
                fiberGramsPerServing: fiberGramsPerServing,
                sugarGramsPerServing: sugarGramsPerServing,
                sodiumMgPerServing: sodiumMgPerServing,
                allergenInfo: allergenInfo,
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
            recipe.caloriesPerServing = caloriesPerServing
            recipe.proteinGramsPerServing = proteinGramsPerServing
            recipe.carbsGramsPerServing = carbsGramsPerServing
            recipe.fatGramsPerServing = fatGramsPerServing
            recipe.fiberGramsPerServing = fiberGramsPerServing
            recipe.sugarGramsPerServing = sugarGramsPerServing
            recipe.sodiumMgPerServing = sodiumMgPerServing
            recipe.allergenInfo = allergenInfo.trimmingCharacters(in: .whitespacesAndNewlines)
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

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }

    private func saveIngredients(for recipe: Recipe) {
        for row in ingredientRows where !row.name.trimmingCharacters(in: .whitespaces).isEmpty {
            let ingredient = row.existingIngredient ?? findOrCreateIngredient(name: row.name, category: row.category)
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

    private func findOrCreateIngredient(name: String, category: String) -> Ingredient {
        let lowered = name.lowercased()
        let descriptor = FetchDescriptor<Ingredient>(
            predicate: #Predicate { $0.name == lowered }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            if existing.category == IngredientCategory.other && category != IngredientCategory.other {
                existing.category = category
            }
            return existing
        }
        let ingredient = Ingredient(name: name, category: category)
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
    var category = IngredientCategory.other
    var existingIngredient: Ingredient?
}

struct IngredientRowEditor: View {
    @Binding var row: IngredientRowData
    let modelContext: ModelContext

    var body: some View {
        VStack(spacing: 8) {
            IngredientSearchField(text: $row.name, modelContext: modelContext) { ingredient in
                row.name = ingredient.displayName
                row.category = ingredient.category
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
            Picker("Category", selection: $row.category) {
                ForEach(IngredientCategory.allCategories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
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
