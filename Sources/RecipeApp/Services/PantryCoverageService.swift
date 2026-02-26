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

    // MARK: - Inventory snapshot key
    //
    // Keyed by (ingredientName, aggKey) where aggKey is "weight" or "volume" for
    // measurable units (enabling cross-unit same-dimension matching: oz vs lb,
    // fl oz vs gallon), or the canonical unit string for count/other.
    // Values are stored in base units: g (weight) or tsp (volume).
    //
    // When an ingredient has a known density, volume and weight quantities are
    // normalized to grams so cross-dimension pairs (oz vs gallon of milk) merge.

    private struct InventoryKey: Hashable {
        let ingredientName: String
        let aggKey: String
    }

    // MARK: - Public API

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
                let inventoryItem = ingredient.inventoryItem
            else { return false }
            let density = ingredient.density
            let required = requiredQuantity(recipeIngredient, for: entry)
            return hasSufficientInventory(
                required: required,
                recipeUnit: recipeIngredient.unit,
                inventoryQty: inventoryItem.quantity,
                inventoryUnit: inventoryItem.unit,
                density: density
            )
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

        let mealCoverages = plannedEntries.map(mealCoverage(for:))
        let readyMeals = mealCoverages.filter { $0.level == .full }.count
        let coveredIngredients = mealCoverages.reduce(0) { $0 + $1.coveredIngredients }
        let totalIngredients = mealCoverages.reduce(0) { $0 + $1.totalIngredients }

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

    // MARK: - Private helpers

    /// Returns true if the inventory holds at least the required amount,
    /// using dimension-aware unit conversion (same-unit, same-dim, cross-dim with density).
    private static func hasSufficientInventory(
        required: Double,
        recipeUnit: String,
        inventoryQty: Double,
        inventoryUnit: String,
        density: Double?
    ) -> Bool {
        if UnitConverter.normalize(recipeUnit) == UnitConverter.normalize(inventoryUnit) {
            return inventoryQty >= required
        }
        guard UnitConverter.areCompatible(recipeUnit, inventoryUnit, density: density) else {
            return false
        }
        guard let converted = UnitConverter.convert(
            quantity: required, from: recipeUnit, to: inventoryUnit, density: density
        ) else { return false }
        return inventoryQty >= converted
    }

    private static func requiredQuantity(_ recipeIngredient: RecipeIngredient, for entry: MealPlanEntry) -> Double {
        guard let recipe = entry.recipe else { return recipeIngredient.quantity }
        let baseServings = max(recipe.servings, 1)
        let targetServings = max(entry.servings, 1)
        let scale = Double(targetServings) / Double(baseServings)
        return recipeIngredient.quantity * scale
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

    /// Builds an inventory snapshot for forecasting, storing base-unit quantities.
    ///
    /// Key: (ingredientName, aggKey) — matches ShoppingListGenerator's NeedKey pattern.
    /// Value: quantity in base units (g for weight, tsp for volume, raw for count/other).
    ///
    /// When an ingredient has known density, the inventory is normalized to grams
    /// so cross-dimension matches (e.g. gallon of milk vs oz in recipe) work correctly.
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

                let density = ingredient.density
                let dim = UnitConverter.dimension(of: inventoryItem.unit)

                let effectiveAggKey: String
                let effectiveBaseQty: Double

                if let d = density, (dim == .volume || dim == .weight),
                   let grams = UnitConverter.convert(
                       quantity: inventoryItem.quantity, from: inventoryItem.unit, to: "g", density: d
                   ) {
                    effectiveAggKey = "weight"
                    effectiveBaseQty = grams
                } else {
                    effectiveAggKey = UnitConverter.aggregationKey(for: inventoryItem.unit)
                    effectiveBaseQty = UnitConverter.toBaseUnit(
                        quantity: inventoryItem.quantity, unit: inventoryItem.unit
                    ) ?? inventoryItem.quantity
                }

                let key = InventoryKey(ingredientName: ingredient.name, aggKey: effectiveAggKey)
                snapshot[key, default: 0] += effectiveBaseQty
            }
        }

        return snapshot
    }

    /// Simulates meal coverage day-by-day, deducting from the base-unit inventory
    /// snapshot as ingredients are "consumed".
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
            let density = ingredient.density
            let dim = UnitConverter.dimension(of: recipeIngredient.unit)

            // Convert required quantity to base units using the same aggKey logic
            // as inventorySnapshot so the keys align for same-dim and cross-dim cases.
            let effectiveAggKey: String
            let effectiveBaseRequired: Double

            if let d = density, (dim == .volume || dim == .weight),
               let grams = UnitConverter.convert(
                   quantity: required, from: recipeIngredient.unit, to: "g", density: d
               ) {
                effectiveAggKey = "weight"
                effectiveBaseRequired = grams
            } else {
                effectiveAggKey = UnitConverter.aggregationKey(for: recipeIngredient.unit)
                effectiveBaseRequired = UnitConverter.toBaseUnit(
                    quantity: required, unit: recipeIngredient.unit
                ) ?? required
            }

            let key = InventoryKey(ingredientName: ingredient.name, aggKey: effectiveAggKey)
            let available = inventoryByKey[key, default: 0]

            if available >= effectiveBaseRequired {
                coveredIngredients += 1
                inventoryByKey[key] = max(0, available - effectiveBaseRequired)
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
