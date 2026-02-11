import Foundation
import SwiftData

@Model
final class Ingredient {
    @Attribute(.unique) var name: String
    var displayName: String
    var category: String

    @Relationship(inverse: \RecipeIngredient.ingredient)
    var recipeIngredients: [RecipeIngredient]

    @Relationship(inverse: \InventoryItem.ingredient)
    var inventoryItem: InventoryItem?

    @Relationship(inverse: \ShoppingListItem.ingredient)
    var shoppingListItems: [ShoppingListItem]

    init(
        name: String,
        displayName: String? = nil,
        category: String = IngredientCategory.other
    ) {
        self.name = name.lowercased()
        self.displayName = displayName ?? name
        self.category = category
        self.recipeIngredients = []
        self.shoppingListItems = []
    }
}

enum IngredientCategory {
    static let protein = "Protein"
    static let vegetable = "Vegetable"
    static let dairy = "Dairy"
    static let spice = "Spice"
    static let grain = "Grain"
    static let other = "Other"

    static let allCategories = [protein, vegetable, dairy, spice, grain, other]
}
