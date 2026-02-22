import SwiftData
import SwiftUI

struct ShoppingListView: View {
    @Query(sort: \ShoppingListItem.addedAt) private var items: [ShoppingListItem]
    @Query private var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddItem = false
    @State private var showChecked = false

    private var uncheckedItems: [ShoppingListItem] {
        items.filter { !$0.isChecked }
    }

    private var checkedItems: [ShoppingListItem] {
        items.filter { $0.isChecked }
    }

    private var groupedUnchecked: [(String, [ShoppingListItem])] {
        let grouped = Dictionary(grouping: uncheckedItems) { item in
            item.ingredient?.category ?? IngredientCategory.other
        }
        return IngredientCategory.allCategories.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Shopping List Empty",
                        systemImage: "cart",
                        description: Text(
                            "Generate a list from your meal plan or add items manually."
                        )
                    )

                    Button("Generate from Meal Plan", systemImage: "wand.and.stars") {
                        generateList()
                    }
                    .accessibilityIdentifier("shopping-generate-empty-state")
                } else {
                    ForEach(groupedUnchecked, id: \.0) { category, categoryItems in
                        Section(category) {
                            ForEach(categoryItems) { item in
                                ShoppingItemRow(item: item) {
                                    checkOff(item)
                                }
                            }
                        }
                    }

                    if !checkedItems.isEmpty {
                        Section {
                            DisclosureGroup(
                                "Purchased (\(checkedItems.count))",
                                isExpanded: $showChecked
                            ) {
                                ForEach(checkedItems) { item in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text(item.ingredient?.displayName ?? "Unknown")
                                            .strikethrough()
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(item.quantity.formatted()) \(item.unit)")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }

                                Button("Clear Purchased", systemImage: "trash", role: .destructive) {
                                    clearChecked()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Generate", systemImage: "wand.and.stars") {
                        generateList()
                    }
                    .accessibilityIdentifier("shopping-generate-toolbar")
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Add", systemImage: "plus") {
                        showingAddItem = true
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                ShoppingListAddView()
            }
        }
    }

    private func checkOff(_ item: ShoppingListItem) {
        item.isChecked = true
        if let ingredient = item.ingredient {
            addToInventory(ingredient: ingredient, quantity: item.quantity, unit: item.unit)
        }
    }

    private func addToInventory(ingredient: Ingredient, quantity: Double, unit: String) {
        if let existing = ingredient.inventoryItem {
            existing.quantity += quantity
            existing.lastUpdated = Date()
        } else {
            let inventoryItem = InventoryItem(
                quantity: quantity,
                unit: unit,
                ingredient: ingredient
            )
            modelContext.insert(inventoryItem)
        }
    }

    private func clearChecked() {
        for item in checkedItems {
            modelContext.delete(item)
        }
    }

    private func generateList() {
        let lookahead = preferences.first?.shoppingLookaheadDays ?? 7
        ShoppingListGenerator.generate(context: modelContext, lookaheadDays: lookahead)
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingListItem
    let onCheck: () -> Void

    var body: some View {
        HStack {
            Button {
                onCheck()
            } label: {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Text(item.ingredient?.displayName ?? "Unknown")
            Spacer()
            Text("\(item.quantity.formatted()) \(item.unit)")
                .foregroundStyle(.secondary)
            if item.isAutoGenerated {
                Image(systemName: "wand.and.stars")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}
