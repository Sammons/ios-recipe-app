import Foundation
import SwiftData

@MainActor
struct MealCompletionService {
    /// Returns overdue meal plan entries from the last 3 days.
    /// Capped to prevent unbounded accumulation for users who don't complete meals.
    static func overdueEntries(context: ModelContext) -> [MealPlanEntry] {
        let now = Date()
        let startOfToday = DateHelpers.startOfDay(now)
        let cutoff = Calendar.current.date(byAdding: .day, value: -3, to: startOfToday) ?? startOfToday
        let descriptor = FetchDescriptor<MealPlanEntry>(
            predicate: #Predicate {
                $0.date < startOfToday && $0.date >= cutoff && $0.status == "planned"
            },
            sortBy: [SortDescriptor(\MealPlanEntry.date)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func markCompleted(_ entry: MealPlanEntry, context: ModelContext) {
        entry.status = MealStatus.completed
        entry.completedAt = Date()
        deductIngredients(entry: entry, context: context)
        try? context.save()
    }

    static func markSkipped(_ entry: MealPlanEntry, context: ModelContext? = nil) {
        entry.status = MealStatus.skipped
        entry.completedAt = Date()
        if let context {
            try? context.save()
        }
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

            // Determine how much to deduct from inventory, handling unit mismatches.
            // If units are identical (or both normalize to the same string) deduct directly.
            // If units are compatible (same dimension, e.g. tbsp vs cups), convert first.
            // Cross-dimension (e.g. cups vs g) is supported when density is known.
            // If units are incompatible and no density bridge exists, skip this item.
            let deductAmount: Double?
            let recipeUnit = ri.unit
            let inventoryUnit = inventoryItem.unit
            let density = ingredient.density

            if UnitConverter.normalize(recipeUnit) == UnitConverter.normalize(inventoryUnit) {
                deductAmount = used
            } else if UnitConverter.areCompatible(recipeUnit, inventoryUnit, density: density) {
                deductAmount = UnitConverter.convert(
                    quantity: used, from: recipeUnit, to: inventoryUnit, density: density
                )
            } else {
                deductAmount = nil
            }

            guard let amount = deductAmount else { continue }

            inventoryItem.quantity = max(0, inventoryItem.quantity - amount)
            inventoryItem.lastUpdated = Date()

            if inventoryItem.quantity <= 0 {
                context.delete(inventoryItem)
            }
        }
    }
}
