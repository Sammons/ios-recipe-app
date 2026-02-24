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
                    if recipe.caloriesPerServing > 0 {
                        InfoBadge(icon: "bolt.heart", label: "\(recipe.caloriesPerServing) cal")
                    }
                }
            }

            if hasNutritionDetails(recipe) {
                Section("Nutrition (per serving)") {
                    if recipe.caloriesPerServing > 0 {
                        nutritionRow(label: "Calories", value: "\(recipe.caloriesPerServing) cal")
                            .accessibilityIdentifier("recipe-nutrition-calories")
                    }
                    if recipe.proteinGramsPerServing > 0 {
                        nutritionRow(label: "Protein", value: "\(recipe.proteinGramsPerServing) g")
                    }
                    if recipe.carbsGramsPerServing > 0 {
                        nutritionRow(label: "Carbs", value: "\(recipe.carbsGramsPerServing) g")
                    }
                    if recipe.fatGramsPerServing > 0 {
                        nutritionRow(label: "Fat", value: "\(recipe.fatGramsPerServing) g")
                    }
                    if recipe.fiberGramsPerServing > 0 {
                        nutritionRow(label: "Fiber", value: "\(recipe.fiberGramsPerServing) g")
                    }
                    if recipe.sugarGramsPerServing > 0 {
                        nutritionRow(label: "Sugar", value: "\(recipe.sugarGramsPerServing) g")
                    }
                    if recipe.sodiumMgPerServing > 0 {
                        nutritionRow(label: "Sodium", value: "\(recipe.sodiumMgPerServing) mg")
                    }
                }
            }

            if !recipe.allergens.isEmpty {
                Section("Allergens") {
                    ForEach(recipe.allergens, id: \.self) { allergen in
                        Text(allergen)
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                            .accessibilityIdentifier("recipe-allergen-chip")
                    }
                }
            }

            if !recipe.recipeIngredients.isEmpty {
                Section("Ingredients") {
                    ForEach(recipe.recipeIngredients) { ri in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ri.ingredient?.displayName ?? "Unknown")
                                if let category = ri.ingredient?.category {
                                    IngredientCategoryBadge(category: category)
                                }
                            }
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

    private func nutritionRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func hasNutritionDetails(_ recipe: Recipe) -> Bool {
        recipe.caloriesPerServing > 0
            || recipe.proteinGramsPerServing > 0
            || recipe.carbsGramsPerServing > 0
            || recipe.fatGramsPerServing > 0
            || recipe.fiberGramsPerServing > 0
            || recipe.sugarGramsPerServing > 0
            || recipe.sodiumMgPerServing > 0
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

private struct IngredientCategoryBadge: View {
    let category: String

    var body: some View {
        Text(category)
            .font(.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
            .accessibilityIdentifier("ingredient-category-badge")
    }

    private var color: Color {
        switch category {
        case IngredientCategory.protein:
            return .red
        case IngredientCategory.vegetable:
            return .green
        case IngredientCategory.dairy:
            return .blue
        case IngredientCategory.grain:
            return .brown
        case IngredientCategory.spice:
            return .orange
        default:
            return .gray
        }
    }
}

extension RecipeIngredient {
    var formattedQuantity: String {
        let qty = quantity > 0 ? "\(quantity.formatted()) " : ""
        return "\(qty)\(unit)"
    }
}
