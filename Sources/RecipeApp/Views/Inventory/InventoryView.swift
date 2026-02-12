import SwiftData
import SwiftUI

struct InventoryView: View {
    @Query(sort: \InventoryItem.lastUpdated, order: .reverse) private var items: [InventoryItem]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showingAddItem = false

    private var filteredItems: [InventoryItem] {
        if searchText.isEmpty { return items }
        return items.filter {
            $0.ingredient?.displayName.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    private var groupedItems: [(String, [InventoryItem])] {
        let grouped = Dictionary(grouping: filteredItems) { item in
            item.ingredient?.category ?? IngredientCategory.other
        }
        return IngredientCategory.allCategories.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items.sorted { ($0.ingredient?.displayName ?? "") < ($1.ingredient?.displayName ?? "") })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredItems.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "No Inventory",
                            systemImage: "refrigerator",
                            description: Text("Track what ingredients you have on hand.")
                        ) {
                            Button("Add First Ingredient", systemImage: "plus") {
                                showingAddItem = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        ContentUnavailableView(
                            "No Results",
                            systemImage: "magnifyingglass",
                            description: Text("No items match your search.")
                        )
                    }
                } else {
                    ForEach(groupedItems, id: \.0) { category, items in
                        Section(category) {
                            ForEach(items) { item in
                                HStack {
                                    Text(item.ingredient?.displayName ?? "Unknown")
                                    Spacer()
                                    Text("\(item.quantity.formatted()) \(item.unit)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    modelContext.delete(items[index])
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search inventory")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Item", systemImage: "plus") {
                        showingAddItem = true
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                InventoryFormView()
            }
        }
    }
}
