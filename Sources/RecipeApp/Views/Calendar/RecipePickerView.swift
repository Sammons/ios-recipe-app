import SwiftData
import SwiftUI

struct RecipePickerView: View {
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    let onSelect: (Recipe) -> Void

    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty { return recipes }
        return recipes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredRecipes) { recipe in
                Button {
                    onSelect(recipe)
                    dismiss()
                } label: {
                    RecipeRowView(recipe: recipe)
                }
                .buttonStyle(.plain)
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
            .overlay {
                if filteredRecipes.isEmpty {
                    ContentUnavailableView(
                        "No Recipes",
                        systemImage: "book",
                        description: Text("Add recipes in the Recipe Book tab first.")
                    )
                }
            }
        }
    }
}
