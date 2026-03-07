import SwiftData
import SwiftUI

struct RecipeBookView: View {
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Query private var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedType: String? = nil
    @State private var filterMode: RecipeFilterService.FilterMode = .all
    @State private var showingAddRecipe = false
    @State private var recipeToDelete: Recipe?
    @State private var showStarterProtection = false

    private var showStarter: Bool {
        preferences.first?.showStarterRecipes ?? true
    }

    private var filteredRecipes: [Recipe] {
        var result = recipes
        if !showStarter {
            result = result.filter { !$0.isStarterRecipe }
        }
        if let type = selectedType {
            result = result.filter { $0.recipeType == type }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
                    || $0.summary.localizedCaseInsensitiveContains(searchText)
            }
        }
        result = RecipeFilterService.filter(recipes: result, mode: filterMode, context: modelContext)
        return result
    }

    private var groupedRecipes: [(String, [Recipe])] {
        let grouped = Dictionary(grouping: filteredRecipes) { recipe in
            String(recipe.title.prefix(1)).uppercased()
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredRecipes.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Recipes" : "No Results",
                        systemImage: searchText.isEmpty ? "book" : "magnifyingglass",
                        description: Text(
                            searchText.isEmpty
                                ? "Add your first recipe to get started."
                                : "No recipes match your search."
                        )
                    )
                } else {
                    ForEach(groupedRecipes, id: \.0) { letter, recipes in
                        Section(letter) {
                            ForEach(recipes) { recipe in
                                NavigationLink(value: recipe) {
                                    RecipeRowView(recipe: recipe)
                                }
                            }
                            .onDelete { offsets in
                                if let index = offsets.first {
                                    let recipe = recipes[index]
                                    if recipe.isStarterRecipe {
                                        showStarterProtection = true
                                    } else {
                                        recipeToDelete = recipe
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recipe Book")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .searchable(text: $searchText, prompt: "Search recipes")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Recipe", systemImage: "plus") {
                        showingAddRecipe = true
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        Section("Meal Type") {
                            Button("All Types") { selectedType = nil }
                            ForEach(RecipeType.allTypes, id: \.self) { type in
                                Button(type) { selectedType = type }
                            }
                        }
                        Section("Availability") {
                            Button("All Recipes") { filterMode = .all }
                            Button("Can Cook Now") { filterMode = .canCookNow }
                            Button("By Ingredients Available") { filterMode = .partialMatch }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                RecipeFormView(mode: .create)
            }
            .alert("Delete Recipe?", isPresented: Binding(
                get: { recipeToDelete != nil },
                set: { if !$0 { recipeToDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let recipe = recipeToDelete {
                        modelContext.delete(recipe)
                    }
                    recipeToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    recipeToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete \"\(recipeToDelete?.title ?? "")\"? This cannot be undone.")
            }
            .alert("Built-in Recipe", isPresented: $showStarterProtection) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Starter recipes can't be deleted. You can hide them in Preferences.")
            }
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.title)
                .font(.headline)
            if !recipe.summary.isEmpty {
                Text(recipe.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 8) {
                Label(recipe.recipeType, systemImage: "fork.knife")
                if recipe.totalTimeMinutes > 0 {
                    Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                }
                if recipe.servings > 0 {
                    Label("\(recipe.servings)", systemImage: "person.2")
                }
                if recipe.caloriesPerServing > 0 {
                    Label("\(recipe.caloriesPerServing) cal", systemImage: "bolt.heart")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
