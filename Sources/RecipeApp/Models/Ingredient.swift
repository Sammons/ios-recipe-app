import Foundation
import SwiftData

@Model
final class Ingredient {
    @Attribute(.unique) var name: String
    var displayName: String
    var category: String
    /// Density in g/ml. Nil means unknown; enables volume↔weight conversion when set.
    var density: Double?

    @Relationship(inverse: \RecipeIngredient.ingredient)
    var recipeIngredients: [RecipeIngredient]

    @Relationship(inverse: \InventoryItem.ingredient)
    var inventoryItem: InventoryItem?

    @Relationship(inverse: \ShoppingListItem.ingredient)
    var shoppingListItems: [ShoppingListItem]

    init(
        name: String,
        displayName: String? = nil,
        category: String = IngredientCategory.other,
        density: Double? = nil
    ) {
        self.name = name.lowercased()
        self.displayName = displayName ?? name
        self.category = category
        self.density = density
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
