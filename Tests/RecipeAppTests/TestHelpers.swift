import Foundation
import SwiftData
@testable import RecipeApp

@MainActor func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Recipe.self, Ingredient.self, RecipeIngredient.self,
        MealPlanEntry.self, InventoryItem.self, ShoppingListItem.self,
        UserPreferences.self,
        configurations: config
    )
}
