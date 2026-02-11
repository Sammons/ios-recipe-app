import Foundation
import SwiftData

@Model
final class MealPlanEntry {
    var date: Date
    var mealSlot: String
    var servings: Int
    var status: String
    var completedAt: Date?

    var recipe: Recipe?

    init(
        date: Date,
        mealSlot: String,
        servings: Int = 1,
        status: String = MealStatus.planned,
        recipe: Recipe? = nil
    ) {
        self.date = date
        self.mealSlot = mealSlot
        self.servings = servings
        self.status = status
        self.recipe = recipe
    }
}

enum MealStatus {
    static let planned = "planned"
    static let completed = "completed"
    static let skipped = "skipped"
}

enum MealSlot {
    static let breakfast = "Breakfast"
    static let lunch = "Lunch"
    static let dinner = "Dinner"
    static let snack = "Snack"

    static let allSlots = [breakfast, lunch, dinner, snack]
}
