import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let recipeID: PersistentIdentifier
    @State private var showingEdit = false

    private var recipe: Recipe? {
        modelContext.model(for: recipeID) as? Recipe
    }

    var body: some View {
        Group {
            if let recipe {
                recipeContent(recipe)
            } else {
                ContentUnavailableView("Recipe Not Found", systemImage: "book")
            }
        }
        .navigationTitle(recipe?.title ?? "Recipe")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if recipe != nil {
                Button("Edit", systemImage: "pencil") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let recipe {
                RecipeFormView(mode: .edit(recipe))
            }
        }
    }

    @ViewBuilder
    private func recipeContent(_ recipe: Recipe) -> some View {
        List {
            Section {
                if !recipe.summary.isEmpty {
                    Text(recipe.summary)
                        .font(.body)
                }
                HStack(spacing: 16) {
                    InfoBadge(icon: "fork.knife", label: recipe.recipeType)
                    if recipe.prepTimeMinutes > 0 {
                        InfoBadge(icon: "timer", label: "Prep \(recipe.prepTimeMinutes)m")
                    }
                    if recipe.cookTimeMinutes > 0 {
                        InfoBadge(icon: "flame", label: "Cook \(recipe.cookTimeMinutes)m")
                    }
                    InfoBadge(icon: "person.2", label: "\(recipe.servings) servings")
                }
            }

            if !recipe.recipeIngredients.isEmpty {
                Section("Ingredients") {
                    ForEach(recipe.recipeIngredients) { ri in
                        HStack {
                            Text(ri.ingredient?.displayName ?? "Unknown")
                            Spacer()
                            Text(ri.formattedQuantity)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !recipe.instructions.isEmpty {
                Section("Instructions") {
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) {
                        index,
                        step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundStyle(.accent)
                                .frame(width: 28)
                            Text(step)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}

struct InfoBadge: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
            Text(label)
                .font(.caption2)
        }
        .frame(maxWidth: .infinity)
    }
}

extension RecipeIngredient {
    var formattedQuantity: String {
        let qty = quantity > 0 ? "\(quantity.formatted()) " : ""
        return "\(qty)\(unit)"
    }
}
