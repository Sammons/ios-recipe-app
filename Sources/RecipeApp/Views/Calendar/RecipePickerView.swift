import SwiftData
import SwiftUI

struct RecipePickerView: View {
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showingAddRecipe = false
    let onSelect: (Recipe) -> Void

    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty { return recipes }
        return recipes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Add Recipe", systemImage: "plus.circle.fill") {
                        showingAddRecipe = true
                    }
                    .accessibilityIdentifier("picker-add-recipe")
                }

                Section {
                    if filteredRecipes.isEmpty {
                        ContentUnavailableView(
                            "No Recipes",
                            systemImage: "book",
                            description: Text("Add a recipe or adjust your search.")
                        )
                    } else {
                        ForEach(filteredRecipes) { recipe in
                            Button {
                                onSelect(recipe)
                                dismiss()
                            } label: {
                                RecipeRowView(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Choose Recipe")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .searchable(text: $searchText, prompt: "Search recipes")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddRecipe) {
                RecipeFormView(mode: .create)
            }
        }
    }
}
