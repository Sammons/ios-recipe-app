import SwiftData
import SwiftUI

struct InventoryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingItem: InventoryItem?

    @State private var ingredientName = ""
    @State private var quantity: Double = 0
    @State private var unit = ""
    @State private var selectedIngredient: Ingredient?

    private var isEditing: Bool { existingItem != nil }

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
                    .disabled(isEditing)
                }

                Section("Amount") {
                    HStack {
                        TextField("Quantity", value: $quantity, format: .number)
                            .accessibilityIdentifier("quantity-field")
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                        TextField("Unit (g, oz, cups...)", text: $unit)
                            .accessibilityIdentifier("unit-field")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(ingredientName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    private func loadExisting() {
        guard let item = existingItem else { return }
        ingredientName = item.ingredient?.displayName ?? ""
        quantity = item.quantity
        unit = item.unit
        selectedIngredient = item.ingredient
    }

    private func save() {
        let ingredient = selectedIngredient ?? findOrCreateIngredient(name: ingredientName)

        if let item = existingItem {
            item.quantity = quantity
            item.unit = unit
            item.lastUpdated = Date()
        } else if let existing = ingredient.inventoryItem {
            existing.quantity = quantity
            existing.unit = unit
            existing.lastUpdated = Date()
        } else {
            let item = InventoryItem(
                quantity: quantity,
                unit: unit,
                ingredient: ingredient
            )
            modelContext.insert(item)
        }

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
