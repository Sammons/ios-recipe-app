import Foundation
import SwiftData

@MainActor
struct MealCompletionService {
    static func overdueEntries(context: ModelContext) -> [MealPlanEntry] {
        let now = Date()
        let descriptor = FetchDescriptor<MealPlanEntry>(
            predicate: #Predicate {
                $0.date < now && $0.status == "planned"
            },
            sortBy: [SortDescriptor(\MealPlanEntry.date)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func markCompleted(_ entry: MealPlanEntry, context: ModelContext) {
        entry.status = MealStatus.completed
        entry.completedAt = Date()
        deductIngredients(entry: entry, context: context)
    }

    static func markSkipped(_ entry: MealPlanEntry) {
        entry.status = MealStatus.skipped
        entry.completedAt = Date()
    }

    private static func deductIngredients(entry: MealPlanEntry, context: ModelContext) {
        guard let recipe = entry.recipe else { return }
        let servingMultiplier =
            recipe.servings > 0 ? Double(entry.servings) / Double(recipe.servings) : 1.0

        for ri in recipe.recipeIngredients {
            guard let ingredient = ri.ingredient,
                let inventoryItem = ingredient.inventoryItem
            else { continue }

            let used = ri.quantity * servingMultiplier
            inventoryItem.quantity = max(0, inventoryItem.quantity - used)
            inventoryItem.lastUpdated = Date()

            if inventoryItem.quantity <= 0 {
                context.delete(inventoryItem)
            }
        }
    }
}
