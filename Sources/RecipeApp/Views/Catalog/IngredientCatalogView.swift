import SwiftData
import SwiftUI

struct IngredientCatalogView: View {
    @Query(sort: \Ingredient.displayName) private var ingredients: [Ingredient]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var seededCount = 0
    @State private var editingIngredient: Ingredient?

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
                                    if let density = ingredient.density {
                                        Text(String(format: "%.3g g/mL", density))
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.quaternary, in: Capsule())
                                    }
                                    Text(ingredient.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingIngredient = ingredient
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
            .sheet(item: $editingIngredient) { ingredient in
                IngredientDensitySheet(ingredient: ingredient)
                    .presentationDetents([.medium])
            }
        }
    }
}

// MARK: - Density edit sheet

private struct IngredientDensitySheet: View {
    let ingredient: Ingredient
    @State private var densityText: String
    @State private var densityError: String?
    @Environment(\.dismiss) private var dismiss

    init(ingredient: Ingredient) {
        self.ingredient = ingredient
        self._densityText = State(
            initialValue: ingredient.density.map { String($0) } ?? ""
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    LabeledContent("Name", value: ingredient.displayName)
                    LabeledContent("Category", value: ingredient.category)
                }

                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("e.g. 0.53 for flour, 1.0 for water", text: $densityText)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .accessibilityIdentifier("ingredient-density-field")
                            .onChange(of: densityText) { _, _ in
                                densityError = nil
                            }

                        if let densityError {
                            Text(densityError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Density (g/mL)")
                } footer: {
                    Text(
                        "Enables automatic conversion between volume (cups, tbsp) and weight (g, oz). "
                        + "Leave blank if unknown."
                    )
                }
            }
            .navigationTitle("Edit Ingredient")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let trimmed = densityText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            ingredient.density = nil
                            dismiss()
                            return
                        }

                        guard let parsed = Double(trimmed), parsed > 0, parsed.isFinite else {
                            densityError = "Enter a positive number."
                            return
                        }

                        ingredient.density = parsed
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
