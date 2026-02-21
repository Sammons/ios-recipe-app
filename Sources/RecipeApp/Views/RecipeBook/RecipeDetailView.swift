import SwiftData
import SwiftUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @State private var showingEdit = false

    var body: some View {
        recipeContent(recipe)
            .navigationTitle(recipe.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                Button("Edit", systemImage: "pencil") {
                    showingEdit = true
                }
            }
            .sheet(isPresented: $showingEdit) {
                RecipeFormView(mode: .edit(recipe))
            }
    }

    @ViewBuilder
    private func recipeContent(_ recipe: Recipe) -> some View {
        List {
            Section {
                if !recipe.summary.isEmpty {
                    Text(recipe.summary)
                        .font(.body)
                        .foregroundStyle(.primary)
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
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 28)
                            Text(step)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 8)
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
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
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
