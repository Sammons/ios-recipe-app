import Foundation

enum PantryCoverageLevel: String {
    case full
    case partial
    case missing
}

struct PantryMealCoverage {
    let coveredIngredients: Int
    let totalIngredients: Int
    let level: PantryCoverageLevel
}

struct PantryDayCoverage {
    let readyMeals: Int
    let totalMeals: Int
    let coveredIngredients: Int
    let totalIngredients: Int
    let level: PantryCoverageLevel
}

@MainActor
struct PantryCoverageService {
    static func mealCoverage(for entry: MealPlanEntry) -> PantryMealCoverage {
        guard let recipe = entry.recipe else {
            return PantryMealCoverage(coveredIngredients: 0, totalIngredients: 0, level: .missing)
        }

        let totalIngredients = recipe.recipeIngredients.count
        guard totalIngredients > 0 else {
            return PantryMealCoverage(coveredIngredients: 0, totalIngredients: 0, level: .full)
        }

        let coveredIngredients = recipe.recipeIngredients.filter { recipeIngredient in
            guard
                let ingredient = recipeIngredient.ingredient,
                let inventoryItem = ingredient.inventoryItem,
                unitsMatch(inventory: inventoryItem.unit, needed: recipeIngredient.unit)
            else {
                return false
            }

            return inventoryItem.quantity >= requiredQuantity(recipeIngredient, for: entry)
        }.count

        return PantryMealCoverage(
            coveredIngredients: coveredIngredients,
            totalIngredients: totalIngredients,
            level: coverageLevel(covered: coveredIngredients, total: totalIngredients)
        )
    }

    static func dayCoverage(for entries: [MealPlanEntry]) -> PantryDayCoverage {
        let plannedEntries = entries.filter { $0.status == MealStatus.planned }
        guard !plannedEntries.isEmpty else {
            return PantryDayCoverage(
                readyMeals: 0,
                totalMeals: 0,
                coveredIngredients: 0,
                totalIngredients: 0,
                level: .missing
            )
        }

        let mealCoverage = plannedEntries.map(mealCoverage(for:))
        let readyMeals = mealCoverage.filter { $0.level == .full }.count
        let coveredIngredients = mealCoverage.reduce(0) { $0 + $1.coveredIngredients }
        let totalIngredients = mealCoverage.reduce(0) { $0 + $1.totalIngredients }

        let level: PantryCoverageLevel
        if readyMeals == plannedEntries.count {
            level = .full
        } else if readyMeals > 0 || coveredIngredients > 0 {
            level = .partial
        } else {
            level = .missing
        }

        return PantryDayCoverage(
            readyMeals: readyMeals,
            totalMeals: plannedEntries.count,
            coveredIngredients: coveredIngredients,
            totalIngredients: totalIngredients,
            level: level
        )
    }

    private static func requiredQuantity(_ recipeIngredient: RecipeIngredient, for entry: MealPlanEntry) -> Double {
        guard let recipe = entry.recipe else { return recipeIngredient.quantity }
        let baseServings = max(recipe.servings, 1)
        let targetServings = max(entry.servings, 1)
        let scale = Double(targetServings) / Double(baseServings)
        return recipeIngredient.quantity * scale
    }

    private static func unitsMatch(inventory: String, needed: String) -> Bool {
        inventory.trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(needed.trimmingCharacters(in: .whitespacesAndNewlines))
            == .orderedSame
    }

    private static func coverageLevel(covered: Int, total: Int) -> PantryCoverageLevel {
        guard total > 0 else { return .full }
        if covered == total { return .full }
        if covered > 0 { return .partial }
        return .missing
    }
}
