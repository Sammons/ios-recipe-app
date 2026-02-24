import Foundation
import SwiftData

@Model
final class Recipe {
    var title: String
    var summary: String
    var prepTimeMinutes: Int
    var cookTimeMinutes: Int
    var servings: Int
    var caloriesPerServing: Int
    var proteinGramsPerServing: Int
    var carbsGramsPerServing: Int
    var fatGramsPerServing: Int
    var fiberGramsPerServing: Int
    var sugarGramsPerServing: Int
    var sodiumMgPerServing: Int
    var allergenInfo: String
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
        caloriesPerServing: Int = 0,
        proteinGramsPerServing: Int = 0,
        carbsGramsPerServing: Int = 0,
        fatGramsPerServing: Int = 0,
        fiberGramsPerServing: Int = 0,
        sugarGramsPerServing: Int = 0,
        sodiumMgPerServing: Int = 0,
        allergenInfo: String = "",
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
        self.caloriesPerServing = max(0, caloriesPerServing)
        self.proteinGramsPerServing = max(0, proteinGramsPerServing)
        self.carbsGramsPerServing = max(0, carbsGramsPerServing)
        self.fatGramsPerServing = max(0, fatGramsPerServing)
        self.fiberGramsPerServing = max(0, fiberGramsPerServing)
        self.sugarGramsPerServing = max(0, sugarGramsPerServing)
        self.sodiumMgPerServing = max(0, sodiumMgPerServing)
        self.allergenInfo = allergenInfo.trimmingCharacters(in: .whitespacesAndNewlines)
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

    var allergens: [String] {
        allergenInfo
            .split(whereSeparator: { $0 == "," || $0 == "\n" || $0 == ";" })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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
