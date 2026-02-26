import Foundation
import SwiftData
import Testing
@testable import RecipeApp

@Suite("PantryCoverageService", .serialized)
struct PantryCoverageServiceTests {
    @Test @MainActor func mealCoverageUsesServingsAndUnitMatching() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        context.insert(flour)
        context.insert(InventoryItem(quantity: 250, unit: "g", ingredient: flour))

        let bread = Recipe(title: "Bread", servings: 4)
        context.insert(bread)
        context.insert(RecipeIngredient(quantity: 500, unit: "g", recipe: bread, ingredient: flour))

        let entry = MealPlanEntry(
            date: DateHelpers.startOfDay(Date()),
            mealSlot: MealSlot.dinner,
            servings: 2,
            recipe: bread
        )
        context.insert(entry)

        let coverage = PantryCoverageService.mealCoverage(for: entry)
        #expect(coverage.level == .full)
        #expect(coverage.coveredIngredients == 1)
        #expect(coverage.totalIngredients == 1)
    }

    @Test @MainActor func mealCoverageCanBePartialWhenQuantityInsufficient() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        let milk = Ingredient(name: "milk")
        context.insert(flour)
        context.insert(milk)
        context.insert(InventoryItem(quantity: 100, unit: "g", ingredient: flour))
        // 50 ml on hand, recipe needs 200 ml — insufficient
        context.insert(InventoryItem(quantity: 50, unit: "ml", ingredient: milk))

        let pancakes = Recipe(title: "Pancakes", servings: 1)
        context.insert(pancakes)
        context.insert(RecipeIngredient(quantity: 100, unit: "g", recipe: pancakes, ingredient: flour))
        context.insert(RecipeIngredient(quantity: 200, unit: "ml", recipe: pancakes, ingredient: milk))

        let entry = MealPlanEntry(
            date: DateHelpers.startOfDay(Date()),
            mealSlot: MealSlot.breakfast,
            servings: 1,
            recipe: pancakes
        )
        context.insert(entry)

        let coverage = PantryCoverageService.mealCoverage(for: entry)
        #expect(coverage.level == .partial)
        #expect(coverage.coveredIngredients == 1)
        #expect(coverage.totalIngredients == 2)
    }

    // MARK: - Cross-unit matching tests

    @Test @MainActor func mealCoverageMatchesSameDimDifferentUnits() throws {
        // Recipe calls for oz; pantry has lb — both weight, should be covered.
        let container = try makeTestContainer()
        let context = container.mainContext

        let coffeeBeans = Ingredient(name: "coffee beans")
        context.insert(coffeeBeans)
        // 1 lb = 453.6g; recipe needs 2 oz = 56.7g — plenty on hand
        context.insert(InventoryItem(quantity: 1, unit: "lb", ingredient: coffeeBeans))

        let latte = Recipe(title: "Latte", servings: 1)
        context.insert(latte)
        context.insert(RecipeIngredient(quantity: 2, unit: "oz", recipe: latte, ingredient: coffeeBeans))

        let entry = MealPlanEntry(
            date: DateHelpers.startOfDay(Date()),
            mealSlot: MealSlot.breakfast,
            servings: 1,
            recipe: latte
        )
        context.insert(entry)

        let coverage = PantryCoverageService.mealCoverage(for: entry)
        #expect(coverage.level == .full)
        #expect(coverage.coveredIngredients == 1)
    }

    @Test @MainActor func mealCoverageMatchesCrossDimWithDensity() throws {
        // Recipe calls for oz (weight); pantry has gallon (volume).
        // Milk density (1.030 g/ml) bridges the dimensions.
        let container = try makeTestContainer()
        let context = container.mainContext

        let milk = Ingredient(name: "milk", density: 1.030)
        context.insert(milk)
        // 1 gallon ≈ 3877g; recipe needs 8 oz = 226.8g — plenty on hand
        context.insert(InventoryItem(quantity: 1, unit: "gallon", ingredient: milk))

        let latte = Recipe(title: "Latte", servings: 1)
        context.insert(latte)
        context.insert(RecipeIngredient(quantity: 8, unit: "oz", recipe: latte, ingredient: milk))

        let entry = MealPlanEntry(
            date: DateHelpers.startOfDay(Date()),
            mealSlot: MealSlot.breakfast,
            servings: 1,
            recipe: latte
        )
        context.insert(entry)

        let coverage = PantryCoverageService.mealCoverage(for: entry)
        #expect(coverage.level == .full)
        #expect(coverage.coveredIngredients == 1)
    }

    @Test @MainActor func mealCoverageMatchesSameDimVolumeDifferentUnits() throws {
        // Recipe calls for fl oz (volume); pantry has gallon (volume) — same dimension.
        let container = try makeTestContainer()
        let context = container.mainContext

        let milk = Ingredient(name: "milk")
        context.insert(milk)
        // 1 gallon = 128 fl oz; recipe needs 8 fl oz — plenty on hand
        context.insert(InventoryItem(quantity: 1, unit: "gallon", ingredient: milk))

        let latte = Recipe(title: "Latte", servings: 1)
        context.insert(latte)
        context.insert(RecipeIngredient(quantity: 8, unit: "fl oz", recipe: latte, ingredient: milk))

        let entry = MealPlanEntry(
            date: DateHelpers.startOfDay(Date()),
            mealSlot: MealSlot.breakfast,
            servings: 1,
            recipe: latte
        )
        context.insert(entry)

        let coverage = PantryCoverageService.mealCoverage(for: entry)
        #expect(coverage.level == .full)
        #expect(coverage.coveredIngredients == 1)
    }

    @Test @MainActor func forecastCoverageMatchesCrossUnitIngredients() throws {
        // Full latte scenario: coffee beans (oz recipe, lb pantry) + milk (fl oz recipe, gallon pantry).
        // Week of 7 lattes. Pantry: 1 lb coffee, 1 gallon milk.
        // Need: 7×2 oz coffee = 14 oz = 396.9g; have 453.6g (1 lb) — OK.
        // Need: 7×8 fl oz milk = 56 fl oz = 336 tsp; have 768 tsp (1 gal) — OK.
        let container = try makeTestContainer()
        let context = container.mainContext

        let coffeeBeans = Ingredient(name: "coffee beans")
        let milk = Ingredient(name: "milk")
        context.insert(coffeeBeans)
        context.insert(milk)
        context.insert(InventoryItem(quantity: 1, unit: "lb", ingredient: coffeeBeans))
        context.insert(InventoryItem(quantity: 1, unit: "gallon", ingredient: milk))

        let latte = Recipe(title: "Latte", servings: 1)
        context.insert(latte)
        context.insert(RecipeIngredient(quantity: 2, unit: "oz", recipe: latte, ingredient: coffeeBeans))
        context.insert(RecipeIngredient(quantity: 8, unit: "fl oz", recipe: latte, ingredient: milk))

        let today = DateHelpers.startOfDay(Date())
        var weekDays: [Date] = []
        var entries: [MealPlanEntry] = []
        for i in 0..<7 {
            let day = DateHelpers.addDays(i, to: today)
            weekDays.append(day)
            let e = MealPlanEntry(date: day, mealSlot: MealSlot.breakfast, servings: 1, recipe: latte)
            context.insert(e)
            entries.append(e)
        }

        let forecast = PantryCoverageService.forecastDayCoverage(for: weekDays, entries: entries)

        for day in weekDays {
            let key = DateHelpers.startOfDay(day)
            #expect(forecast[key]?.level == .full, "Expected full coverage on day \(day)")
            #expect(forecast[key]?.readyMeals == 1)
        }
    }

    @Test @MainActor func dayCoverageCountsReadyPlannedMeals() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let eggs = Ingredient(name: "eggs")
        context.insert(eggs)
        context.insert(InventoryItem(quantity: 2, unit: "large", ingredient: eggs))

        let omelet = Recipe(title: "Omelet", servings: 1)
        context.insert(omelet)
        context.insert(RecipeIngredient(quantity: 2, unit: "large", recipe: omelet, ingredient: eggs))

        let frittata = Recipe(title: "Frittata", servings: 1)
        context.insert(frittata)
        context.insert(RecipeIngredient(quantity: 6, unit: "large", recipe: frittata, ingredient: eggs))

        let day = DateHelpers.startOfDay(Date())
        let readyEntry = MealPlanEntry(
            date: day,
            mealSlot: MealSlot.breakfast,
            servings: 1,
            recipe: omelet
        )
        let missingEntry = MealPlanEntry(
            date: day,
            mealSlot: MealSlot.dinner,
            servings: 1,
            recipe: frittata
        )
        let completedEntry = MealPlanEntry(
            date: day,
            mealSlot: MealSlot.lunch,
            servings: 1,
            status: MealStatus.completed,
            recipe: omelet
        )
        context.insert(readyEntry)
        context.insert(missingEntry)
        context.insert(completedEntry)

        let coverage = PantryCoverageService.dayCoverage(for: [readyEntry, missingEntry, completedEntry])
        #expect(coverage.level == .partial)
        #expect(coverage.totalMeals == 2)
        #expect(coverage.readyMeals == 1)
    }

    @Test @MainActor func forecastDayCoverageConsumesInventoryAcrossDays() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let trout = Ingredient(name: "trout")
        context.insert(trout)
        context.insert(InventoryItem(quantity: 2, unit: "filets", ingredient: trout))

        let troutDinner = Recipe(title: "Trout Dinner", servings: 1)
        context.insert(troutDinner)
        context.insert(RecipeIngredient(quantity: 2, unit: "filet", recipe: troutDinner, ingredient: trout))

        let dayOne = DateHelpers.startOfDay(Date())
        let dayTwo = DateHelpers.addDays(2, to: dayOne)

        let firstEntry = MealPlanEntry(
            date: dayOne,
            mealSlot: MealSlot.dinner,
            servings: 1,
            recipe: troutDinner
        )
        let secondEntry = MealPlanEntry(
            date: dayTwo,
            mealSlot: MealSlot.dinner,
            servings: 1,
            recipe: troutDinner
        )
        context.insert(firstEntry)
        context.insert(secondEntry)

        let forecast = PantryCoverageService.forecastDayCoverage(
            for: [dayOne, dayTwo],
            entries: [firstEntry, secondEntry]
        )

        #expect(forecast[dayOne]?.readyMeals == 1)
        #expect(forecast[dayOne]?.level == .full)
        #expect(forecast[dayTwo]?.readyMeals == 0)
        #expect(forecast[dayTwo]?.level == .missing)
    }

    @Test @MainActor func forecastDayCoverageReservesSharedIngredientsFromEarlierPartialMeals() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let trout = Ingredient(name: "trout")
        let lemon = Ingredient(name: "lemon")
        context.insert(trout)
        context.insert(lemon)
        context.insert(InventoryItem(quantity: 2, unit: "filets", ingredient: trout))

        let lemonTrout = Recipe(title: "Lemon Trout", servings: 1)
        let plainTrout = Recipe(title: "Plain Trout", servings: 1)
        context.insert(lemonTrout)
        context.insert(plainTrout)

        context.insert(RecipeIngredient(quantity: 2, unit: "filet", recipe: lemonTrout, ingredient: trout))
        context.insert(RecipeIngredient(quantity: 1, unit: "whole", recipe: lemonTrout, ingredient: lemon))
        context.insert(RecipeIngredient(quantity: 2, unit: "filet", recipe: plainTrout, ingredient: trout))

        let dayOne = DateHelpers.startOfDay(Date())
        let dayTwo = DateHelpers.addDays(2, to: dayOne)
        let firstEntry = MealPlanEntry(
            date: dayOne,
            mealSlot: MealSlot.dinner,
            servings: 1,
            recipe: lemonTrout
        )
        let secondEntry = MealPlanEntry(
            date: dayTwo,
            mealSlot: MealSlot.dinner,
            servings: 1,
            recipe: plainTrout
        )
        context.insert(firstEntry)
        context.insert(secondEntry)

        let forecast = PantryCoverageService.forecastDayCoverage(
            for: [dayOne, dayTwo],
            entries: [firstEntry, secondEntry]
        )

        #expect(forecast[dayOne]?.readyMeals == 0)
        #expect(forecast[dayOne]?.level == .partial)
        #expect(forecast[dayTwo]?.readyMeals == 0)
        #expect(forecast[dayTwo]?.level == .missing)
    }
}
