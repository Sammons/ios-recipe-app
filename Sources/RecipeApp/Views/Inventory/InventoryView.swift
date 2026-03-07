import SwiftData
import SwiftUI

struct InventoryView: View {
    @Query(sort: \InventoryItem.lastUpdated, order: .reverse) private var items: [InventoryItem]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var itemToDelete: InventoryItem?

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
                        )
                        .overlay(alignment: .bottom) {
                            Button("Add First Ingredient", systemImage: "plus") {
                                showingAddItem = true
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom, 12)
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
                                if let index = offsets.first {
                                    itemToDelete = items[index]
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
            .alert("Delete Item?", isPresented: Binding(
                get: { itemToDelete != nil },
                set: { if !$0 { itemToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        modelContext.delete(item)
                    }
                    itemToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
            } message: {
                Text("Remove \(itemToDelete?.ingredient?.displayName ?? "this item") from your inventory?")
            }
        }
    }
}
