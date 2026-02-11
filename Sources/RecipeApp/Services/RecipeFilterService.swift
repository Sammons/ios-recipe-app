import Foundation
import SwiftData

@MainActor
struct RecipeFilterService {
    enum FilterMode {
        case all
        case canCookNow
        case partialMatch
    }

    static func filter(
        recipes: [Recipe],
        mode: FilterMode,
        context: ModelContext
    ) -> [Recipe] {
        switch mode {
        case .all:
            return recipes
        case .canCookNow:
            return recipes.filter { canCook($0, context: context) }
        case .partialMatch:
            return recipes.sorted { a, b in
                ingredientMatchPercent(a, context: context)
                    > ingredientMatchPercent(b, context: context)
            }
        }
    }

    static func canCook(_ recipe: Recipe, context: ModelContext) -> Bool {
        for ri in recipe.recipeIngredients {
            guard let ingredient = ri.ingredient,
                let inventoryItem = ingredient.inventoryItem,
                inventoryItem.quantity >= ri.quantity
            else {
                return false
            }
        }
        return true
    }

    static func ingredientMatchPercent(_ recipe: Recipe, context: ModelContext) -> Double {
        let total = recipe.recipeIngredients.count
        guard total > 0 else { return 1.0 }
        let available = recipe.recipeIngredients.filter { ri in
            guard let ingredient = ri.ingredient,
                let inventoryItem = ingredient.inventoryItem
            else { return false }
            return inventoryItem.quantity >= ri.quantity
        }.count
        return Double(available) / Double(total)
    }
}
