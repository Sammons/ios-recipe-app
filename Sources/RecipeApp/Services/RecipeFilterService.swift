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
                hasSufficientInventory(ri: ri, inventoryItem: inventoryItem)
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
            return hasSufficientInventory(ri: ri, inventoryItem: inventoryItem)
        }.count
        return Double(available) / Double(total)
    }

    /// Returns true if the inventory item has at least as much as the recipe needs,
    /// accounting for unit conversion when units are compatible.
    private static func hasSufficientInventory(
        ri: RecipeIngredient,
        inventoryItem: InventoryItem
    ) -> Bool {
        let recipeUnit = ri.unit
        let inventoryUnit = inventoryItem.unit

        if UnitConverter.normalize(recipeUnit) == UnitConverter.normalize(inventoryUnit) {
            // Same unit — compare directly
            return inventoryItem.quantity >= ri.quantity
        } else if UnitConverter.areCompatible(recipeUnit, inventoryUnit) {
            // Compatible units (e.g., tbsp vs cup) — convert recipe requirement to inventory unit
            guard let convertedRequired = UnitConverter.convert(
                quantity: ri.quantity, from: recipeUnit, to: inventoryUnit
            ) else { return false }
            return inventoryItem.quantity >= convertedRequired
        } else {
            // Incompatible dimensions (e.g., g vs cup) — cannot confirm sufficiency
            return false
        }
    }
}
