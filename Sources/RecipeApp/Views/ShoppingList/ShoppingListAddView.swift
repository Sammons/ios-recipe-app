import SwiftData
import SwiftUI

struct ShoppingListAddView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var ingredientName = ""
    @State private var quantity: Double = 1
    @State private var unit = ""
    @State private var selectedIngredient: Ingredient?

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    IngredientSearchField(
                        text: $ingredientName,
                        modelContext: modelContext
                    ) { ingredient in
                        ingredientName = ingredient.displayName
                        selectedIngredient = ingredient
                    }
                }

                Section("Amount") {
                    HStack {
                        TextField("Quantity", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                        TextField("Unit", text: $unit)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(ingredientName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let ingredient = selectedIngredient ?? findOrCreateIngredient(name: ingredientName)
        let item = ShoppingListItem(
            quantity: quantity,
            unit: unit,
            ingredient: ingredient
        )
        modelContext.insert(item)
        try? modelContext.save()
        dismiss()
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
