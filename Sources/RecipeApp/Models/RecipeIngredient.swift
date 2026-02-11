import Foundation
import SwiftData

@Model
final class RecipeIngredient {
    var quantity: Double
    var unit: String
    var notes: String

    var recipe: Recipe?
    var ingredient: Ingredient?

    init(
        quantity: Double = 0,
        unit: String = "",
        notes: String = "",
        recipe: Recipe? = nil,
        ingredient: Ingredient? = nil
    ) {
        self.quantity = quantity
        self.unit = unit
        self.notes = notes
        self.recipe = recipe
        self.ingredient = ingredient
    }
}
