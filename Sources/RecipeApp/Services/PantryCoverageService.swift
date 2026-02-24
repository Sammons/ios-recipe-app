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
    private struct InventoryKey: Hashable {
        let ingredientName: String
        let unit: String
    }

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

    static func forecastDayCoverage(
        for dates: [Date],
        entries allEntries: [MealPlanEntry]
    ) -> [Date: PantryDayCoverage] {
        var inventoryByKey = inventorySnapshot(from: allEntries)
        var result: [Date: PantryDayCoverage] = [:]

        let orderedDays = dates
            .map(DateHelpers.startOfDay)
            .sorted()

        for day in orderedDays {
            let dayStart = DateHelpers.startOfDay(day)
            let dayEnd = DateHelpers.endOfDay(dayStart)
            let plannedEntries = allEntries
                .filter {
                    $0.status == MealStatus.planned
                        && $0.date >= dayStart
                        && $0.date < dayEnd
                }
                .sorted(by: mealEntryOrder)

            if plannedEntries.isEmpty {
                result[dayStart] = PantryDayCoverage(
                    readyMeals: 0,
                    totalMeals: 0,
                    coveredIngredients: 0,
                    totalIngredients: 0,
                    level: .missing
                )
                continue
            }

            var readyMeals = 0
            var coveredIngredients = 0
            var totalIngredients = 0

            for entry in plannedEntries {
                let mealCoverage = simulatedMealCoverage(
                    for: entry,
                    inventoryByKey: &inventoryByKey
                )
                totalIngredients += mealCoverage.totalIngredients
                coveredIngredients += mealCoverage.coveredIngredients
                if mealCoverage.level == .full {
                    readyMeals += 1
                }
            }

            let dayLevel: PantryCoverageLevel
            if readyMeals == plannedEntries.count {
                dayLevel = .full
            } else if readyMeals > 0 || coveredIngredients > 0 {
                dayLevel = .partial
            } else {
                dayLevel = .missing
            }

            result[dayStart] = PantryDayCoverage(
                readyMeals: readyMeals,
                totalMeals: plannedEntries.count,
                coveredIngredients: coveredIngredients,
                totalIngredients: totalIngredients,
                level: dayLevel
            )
        }

        return result
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
        UnitTextNormalizer.normalize(inventory) == UnitTextNormalizer.normalize(needed)
    }

    private static func coverageLevel(covered: Int, total: Int) -> PantryCoverageLevel {
        guard total > 0 else { return .full }
        if covered == total { return .full }
        if covered > 0 { return .partial }
        return .missing
    }

    private static func mealEntryOrder(_ lhs: MealPlanEntry, _ rhs: MealPlanEntry) -> Bool {
        if lhs.date != rhs.date {
            return lhs.date < rhs.date
        }
        let lhsIndex = MealSlot.allSlots.firstIndex(of: lhs.mealSlot) ?? Int.max
        let rhsIndex = MealSlot.allSlots.firstIndex(of: rhs.mealSlot) ?? Int.max
        return lhsIndex < rhsIndex
    }

    private static func inventorySnapshot(from allEntries: [MealPlanEntry]) -> [InventoryKey: Double] {
        var snapshot: [InventoryKey: Double] = [:]
        var seenIngredients: Set<ObjectIdentifier> = []

        for entry in allEntries {
            guard let recipe = entry.recipe else { continue }
            for recipeIngredient in recipe.recipeIngredients {
                guard let ingredient = recipeIngredient.ingredient else { continue }
                let ingredientId = ObjectIdentifier(ingredient)
                guard seenIngredients.insert(ingredientId).inserted else { continue }
                guard let inventoryItem = ingredient.inventoryItem else { continue }
                let key = InventoryKey(
                    ingredientName: ingredient.name,
                    unit: UnitTextNormalizer.normalize(inventoryItem.unit)
                )
                snapshot[key, default: 0] += inventoryItem.quantity
            }
        }

        return snapshot
    }

    private static func simulatedMealCoverage(
        for entry: MealPlanEntry,
        inventoryByKey: inout [InventoryKey: Double]
    ) -> PantryMealCoverage {
        guard let recipe = entry.recipe else {
            return PantryMealCoverage(coveredIngredients: 0, totalIngredients: 0, level: .missing)
        }

        let ingredients = recipe.recipeIngredients
        let totalIngredients = ingredients.count
        guard totalIngredients > 0 else {
            return PantryMealCoverage(coveredIngredients: 0, totalIngredients: 0, level: .full)
        }

        var coveredIngredients = 0

        for recipeIngredient in ingredients {
            guard let ingredient = recipeIngredient.ingredient else { continue }
            let required = requiredQuantity(recipeIngredient, for: entry)
            let key = InventoryKey(
                ingredientName: ingredient.name,
                unit: UnitTextNormalizer.normalize(recipeIngredient.unit)
            )

            let available = inventoryByKey[key, default: 0]
            if available >= required {
                coveredIngredients += 1
                inventoryByKey[key] = max(0, available - required)
            }
        }

        let level = coverageLevel(covered: coveredIngredients, total: totalIngredients)

        return PantryMealCoverage(
            coveredIngredients: coveredIngredients,
            totalIngredients: totalIngredients,
            level: level
        )
    }
}
