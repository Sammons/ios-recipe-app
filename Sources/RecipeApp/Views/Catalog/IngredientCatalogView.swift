import SwiftData
import SwiftUI

struct IngredientCatalogView: View {
    @Query(sort: \Ingredient.displayName) private var ingredients: [Ingredient]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var seededCount = 0

    private var categoryOptions: [String] {
        ["All"] + IngredientCategory.allCategories
    }

    private var filteredIngredients: [Ingredient] {
        ingredients.filter { ingredient in
            let categoryMatch = selectedCategory == "All" || ingredient.category == selectedCategory
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return categoryMatch }

            let searchMatch = ingredient.displayName.localizedCaseInsensitiveContains(query)
                || ingredient.name.localizedCaseInsensitiveContains(query)
            return categoryMatch && searchMatch
        }
    }

    private var groupedIngredients: [(String, [Ingredient])] {
        let grouped = Dictionary(grouping: filteredIngredients) { $0.category }
        return categoryOptions.compactMap { category in
            guard category != "All", let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Catalog") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Autocomplete uses this catalog for manual ingredient entry.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("\(ingredients.count) ingredients available")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categoryOptions, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("ingredient-catalog-category")
                }

                if groupedIngredients.isEmpty {
                    ContentUnavailableView(
                        "No Matches",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different ingredient name or category.")
                    )
                } else {
                    ForEach(groupedIngredients, id: \.0) { category, items in
                        Section("\(category) (\(items.count))") {
                            ForEach(items) { ingredient in
                                HStack {
                                    Text(ingredient.displayName)
                                    Spacer()
                                    Text(ingredient.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ingredient Catalog")
            .searchable(text: $searchText, prompt: "Search ingredients")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        seededCount = IngredientCatalogSeeder.seedMissing(context: modelContext)
                    }
                    .accessibilityIdentifier("ingredient-catalog-refresh")
                }
            }
            .overlay(alignment: .bottom) {
                if seededCount > 0 {
                    Text("Added \(seededCount) missing ingredients")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 8)
                }
            }
            .onAppear {
                seededCount = IngredientCatalogSeeder.seedMissing(context: modelContext)
            }
        }
    }
}
