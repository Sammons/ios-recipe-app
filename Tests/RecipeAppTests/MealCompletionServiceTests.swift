import Testing
import SwiftData
import Foundation
@testable import RecipeApp

@Suite("MealCompletionService", .serialized)
struct MealCompletionServiceTests {
    @Test @MainActor func overdueEntriesReturnsPastPlannedEntries() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let recipe = Recipe(title: "Test")
        context.insert(recipe)

        let yesterday = DateHelpers.addDays(-1, to: Date())
        let entry = MealPlanEntry(date: yesterday, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)

        try context.save()

        let overdue = MealCompletionService.overdueEntries(context: context)
        #expect(overdue.count == 1)
    }

    @Test @MainActor func overdueEntriesExcludesFutureMeals() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let recipe = Recipe(title: "Test")
        context.insert(recipe)

        let tomorrow = DateHelpers.addDays(1, to: Date())
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)

        try context.save()

        let overdue = MealCompletionService.overdueEntries(context: context)
        #expect(overdue.count == 0)
    }

    @Test @MainActor func overdueEntriesSortedByDate() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let recipe = Recipe(title: "Test")
        context.insert(recipe)

        let twoDaysAgo = DateHelpers.addDays(-2, to: Date())
        let yesterday = DateHelpers.addDays(-1, to: Date())

        let older = MealPlanEntry(date: twoDaysAgo, mealSlot: MealSlot.lunch, servings: 1, recipe: recipe)
        let newer = MealPlanEntry(date: yesterday, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(newer)
        context.insert(older)

        try context.save()

        let overdue = MealCompletionService.overdueEntries(context: context)
        #expect(overdue.count == 2)
        #expect(overdue[0].date < overdue[1].date)
    }

    @Test @MainActor func markCompletedSetsStatusAndTimestamp() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let recipe = Recipe(title: "Test")
        context.insert(recipe)

        let entry = MealPlanEntry(date: Date(), mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)

        try context.save()

        MealCompletionService.markCompleted(entry, context: context)

        #expect(entry.status == MealStatus.completed)
        #expect(entry.completedAt != nil)
    }

    @Test @MainActor func markCompletedDeductsInventory() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let ingredient = Ingredient(name: "chicken")
        context.insert(ingredient)

        let inventory = InventoryItem(quantity: 500, unit: "g", ingredient: ingredient)
        context.insert(inventory)

        let recipe = Recipe(title: "Chicken", servings: 2)
        context.insert(recipe)

        let ri = RecipeIngredient(quantity: 200, unit: "g", recipe: recipe, ingredient: ingredient)
        context.insert(ri)

        let entry = MealPlanEntry(date: Date(), mealSlot: MealSlot.dinner, servings: 2, recipe: recipe)
        context.insert(entry)

        try context.save()

        MealCompletionService.markCompleted(entry, context: context)

        #expect(inventory.quantity == 300) // 500 - 200
    }

    @Test @MainActor func markCompletedRespectsServingMultiplier() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let ingredient = Ingredient(name: "rice")
        context.insert(ingredient)

        let inventory = InventoryItem(quantity: 1000, unit: "g", ingredient: ingredient)
        context.insert(inventory)

        let recipe = Recipe(title: "Rice", servings: 4)
        context.insert(recipe)

        let ri = RecipeIngredient(quantity: 400, unit: "g", recipe: recipe, ingredient: ingredient)
        context.insert(ri)

        // 2 servings of a 4-serving recipe = half quantities
        let entry = MealPlanEntry(date: Date(), mealSlot: MealSlot.dinner, servings: 2, recipe: recipe)
        context.insert(entry)

        try context.save()

        MealCompletionService.markCompleted(entry, context: context)

        // 400 * (2/4) = 200 used, 1000 - 200 = 800
        #expect(inventory.quantity == 800)
    }

    @Test @MainActor func inventoryDeletedWhenQuantityReachesZero() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let ingredient = Ingredient(name: "butter")
        context.insert(ingredient)

        let inventory = InventoryItem(quantity: 100, unit: "g", ingredient: ingredient)
        context.insert(inventory)

        let recipe = Recipe(title: "Toast", servings: 1)
        context.insert(recipe)

        let ri = RecipeIngredient(quantity: 100, unit: "g", recipe: recipe, ingredient: ingredient)
        context.insert(ri)

        let entry = MealPlanEntry(date: Date(), mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe)
        context.insert(entry)

        try context.save()

        MealCompletionService.markCompleted(entry, context: context)

        let remaining = try context.fetch(FetchDescriptor<InventoryItem>())
        #expect(remaining.count == 0)
    }

    @Test @MainActor func markSkippedSetsStatusWithoutDeduction() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let ingredient = Ingredient(name: "eggs")
        context.insert(ingredient)

        let inventory = InventoryItem(quantity: 12, unit: "large", ingredient: ingredient)
        context.insert(inventory)

        let recipe = Recipe(title: "Omelet", servings: 1)
        context.insert(recipe)

        let ri = RecipeIngredient(quantity: 3, unit: "large", recipe: recipe, ingredient: ingredient)
        context.insert(ri)

        let entry = MealPlanEntry(date: Date(), mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe)
        context.insert(entry)

        try context.save()

        MealCompletionService.markSkipped(entry)

        #expect(entry.status == MealStatus.skipped)
        #expect(entry.completedAt != nil)
        #expect(inventory.quantity == 12) // unchanged
    }

    @Test @MainActor func noCrashWhenRecipeHasNoInventory() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let ingredient = Ingredient(name: "truffle")
        context.insert(ingredient)
        // No inventory item for this ingredient

        let recipe = Recipe(title: "Truffle Pasta", servings: 1)
        context.insert(recipe)

        let ri = RecipeIngredient(quantity: 10, unit: "g", recipe: recipe, ingredient: ingredient)
        context.insert(ri)

        let entry = MealPlanEntry(date: Date(), mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)

        try context.save()

        MealCompletionService.markCompleted(entry, context: context)

        #expect(entry.status == MealStatus.completed)
    }
}
