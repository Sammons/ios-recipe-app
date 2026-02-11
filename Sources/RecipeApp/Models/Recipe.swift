import Foundation
import SwiftData

@Model
final class Recipe {
    var title: String
    var summary: String
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var servings: Int
    var recipeType: String
    var instructions: [String]
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var recipeIngredients: [RecipeIngredient]

    @Relationship(deleteRule: .nullify, inverse: \MealPlanEntry.recipe)
    var mealPlanEntries: [MealPlanEntry]

    init(
        title: String,
        summary: String = "",
        prepTimeMinutes: Int = 0,
        cookTimeMinutes: Int = 0,
        servings: Int = 1,
        recipeType: String = RecipeType.dinner,
        instructions: [String] = [],
        recipeIngredients: [RecipeIngredient] = [],
        mealPlanEntries: [MealPlanEntry] = []
    ) {
        self.title = title
        self.summary = summary
        self.prepTimeMinutes = prepTimeMinutes
        self.cookTimeMinutes = cookTimeMinutes
        self.servings = servings
        self.recipeType = recipeType
        self.instructions = instructions
        self.createdAt = Date()
        self.updatedAt = Date()
        self.recipeIngredients = recipeIngredients
        self.mealPlanEntries = mealPlanEntries
    }

    var totalTimeMinutes: Int {
        prepTimeMinutes + cookTimeMinutes
    }
}

enum RecipeType {
    static let breakfast = "Breakfast"
    static let lunch = "Lunch"
    static let dinner = "Dinner"
    static let snack = "Snack"
    static let dessert = "Dessert"

    static let allTypes = [breakfast, lunch, dinner, snack, dessert]
}
