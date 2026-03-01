import Testing
import SwiftData
import Foundation
@testable import RecipeApp

// MARK: - PurchaseUnitCatalog unit tests

@Suite("PurchaseUnitCatalog")
struct PurchaseUnitCatalogTests {

    // MARK: Protein — weight → lb, 0.25 lb increments

    @Test func proteinWeightSnapsToLb() {
        // 340 g chicken ≈ 0.75 lb → snap up to 0.75 lb
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 340, dimension: .weight, category: IngredientCategory.protein
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        // 340 g / 453.59 = 0.7496 lb → ceil to 0.75
        #expect(abs(result!.quantity - 0.75) < 0.01)
    }

    @Test func proteinSmallAmountSnapsToQuarterLb() {
        // 50 g chicken ≈ 0.11 lb → snap up to 0.25 lb
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 50, dimension: .weight, category: IngredientCategory.protein
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 0.25) < 0.01)
    }

    @Test func proteinExactPoundStaysExact() {
        // 453.59237 g = exactly 1 lb
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 453.59237, dimension: .weight, category: IngredientCategory.protein
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 1.0) < 0.01)
    }

    @Test func proteinLargeAmountSnapsCorrectly() {
        // 1000 g ≈ 2.205 lb → snap up to 2.25 lb
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 1000, dimension: .weight, category: IngredientCategory.protein
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 2.25) < 0.01)
    }

    @Test func proteinVolumeReturnsNil() {
        // Protein has no volume parcel defined
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 48, dimension: .volume, category: IngredientCategory.protein
        )
        #expect(result == nil)
    }

    // MARK: Dairy — weight → oz, volume → cup

    @Test func dairyWeightSnapsToOz() {
        // 100 g cheese ≈ 3.53 oz → snap up to 4 oz
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 100, dimension: .weight, category: IngredientCategory.dairy
        )
        #expect(result != nil)
        #expect(result!.unit == "oz")
        #expect(abs(result!.quantity - 4.0) < 0.01)
    }

    @Test func dairyVolumeSnapsToCup() {
        // 60 tsp = 1.25 cups → already on increment boundary
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 60, dimension: .volume, category: IngredientCategory.dairy
        )
        #expect(result != nil)
        #expect(result!.unit == "cup")
        #expect(abs(result!.quantity - 1.25) < 0.01)
    }

    @Test func dairySmallVolumeSnapsToQuarterCup() {
        // 5 tsp ≈ 0.104 cups → snap up to 0.25 cup
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 5, dimension: .volume, category: IngredientCategory.dairy
        )
        #expect(result != nil)
        #expect(result!.unit == "cup")
        #expect(abs(result!.quantity - 0.25) < 0.01)
    }

    // MARK: Grain — weight → lb, volume → cup

    @Test func grainWeightSnapsToLb() {
        // 500 g flour ≈ 1.10 lb → snap up to 1.25 lb
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 500, dimension: .weight, category: IngredientCategory.grain
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 1.25) < 0.01)
    }

    @Test func grainVolumeToCup() {
        // 96 tsp = 2 cups → exact
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 96, dimension: .volume, category: IngredientCategory.grain
        )
        #expect(result != nil)
        #expect(result!.unit == "cup")
        #expect(abs(result!.quantity - 2.0) < 0.01)
    }

    // MARK: Spice — weight → oz, volume → tsp

    @Test func spiceWeightSnapsToHalfOz() {
        // 10 g spice ≈ 0.35 oz → snap up to 0.5 oz
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 10, dimension: .weight, category: IngredientCategory.spice
        )
        #expect(result != nil)
        #expect(result!.unit == "oz")
        #expect(abs(result!.quantity - 0.5) < 0.01)
    }

    @Test func spiceVolumeSnapsToQuarterTsp() {
        // 0.6 tsp → snap up to 0.75 tsp
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 0.6, dimension: .volume, category: IngredientCategory.spice
        )
        #expect(result != nil)
        #expect(result!.unit == "tsp")
        #expect(abs(result!.quantity - 0.75) < 0.01)
    }

    // MARK: Vegetable — weight → lb

    @Test func vegetableWeightSnapsToLb() {
        // 200 g carrots ≈ 0.44 lb → snap up to 0.5 lb
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 200, dimension: .weight, category: IngredientCategory.vegetable
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 0.5) < 0.01)
    }

    // MARK: Other — weight → oz, volume → cup

    @Test func otherWeightSnapsToOz() {
        // 50 g → 1.76 oz → snap to 2 oz
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 50, dimension: .weight, category: IngredientCategory.other
        )
        #expect(result != nil)
        #expect(result!.unit == "oz")
        #expect(abs(result!.quantity - 2.0) < 0.01)
    }

    // MARK: Count/other dimensions return nil

    @Test func countDimensionReturnsNil() {
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 3, dimension: .count, category: IngredientCategory.protein
        )
        #expect(result == nil)
    }

    @Test func otherDimensionReturnsNil() {
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 1, dimension: .other, category: IngredientCategory.spice
        )
        #expect(result == nil)
    }
}

// MARK: - Shopping list integration: purchase units

@Suite("ShoppingListGenerator.PurchaseUnits", .serialized)
struct ShoppingListPurchaseUnitTests {

    @Test @MainActor func proteinShowsLbNotGrams() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let chicken = Ingredient(
            name: "chicken", displayName: "Chicken",
            category: IngredientCategory.protein
        )
        context.insert(chicken)

        let recipe = Recipe(title: "Grilled Chicken", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 500, unit: "g", recipe: recipe, ingredient: chicken)
        context.insert(ri)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        #expect(items[0].unit == "lb")
        // 500 g ≈ 1.10 lb → snap up to 1.25 lb
        #expect(abs(items[0].quantity - 1.25) < 0.01)
    }

    @Test @MainActor func dairyVolumeShowsCupNotTbsp() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let milk = Ingredient(
            name: "milk", displayName: "Milk",
            category: IngredientCategory.dairy
        )
        context.insert(milk)

        // 10 tbsp milk = 30 tsp = 0.625 cup → snap to 0.75 cup
        let recipe = Recipe(title: "Oatmeal", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 10, unit: "tbsp", recipe: recipe, ingredient: milk)
        context.insert(ri)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        #expect(items[0].unit == "cup")
        #expect(abs(items[0].quantity - 0.75) < 0.01)
    }

    @Test @MainActor func grainWeightShowsLb() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(
            name: "flour", displayName: "Flour",
            category: IngredientCategory.grain
        )
        context.insert(flour)

        let recipe = Recipe(title: "Bread", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 300, unit: "g", recipe: recipe, ingredient: flour)
        context.insert(ri)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        #expect(items[0].unit == "lb")
        // 300 g ≈ 0.661 lb → snap up to 0.75 lb
        #expect(abs(items[0].quantity - 0.75) < 0.01)
    }

    @Test @MainActor func spiceVolumeShowsTsp() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let cumin = Ingredient(
            name: "cumin", displayName: "Cumin",
            category: IngredientCategory.spice
        )
        context.insert(cumin)

        // 2 tsp cumin → snap to 2.0 tsp (already on 0.25 boundary)
        let recipe = Recipe(title: "Curry", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "tsp", recipe: recipe, ingredient: cumin)
        context.insert(ri)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        #expect(items[0].unit == "tsp")
        #expect(abs(items[0].quantity - 2.0) < 0.01)
    }

    @Test @MainActor func countUnitsUnaffectedByCatalog() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let eggs = Ingredient(
            name: "eggs", displayName: "Eggs",
            category: IngredientCategory.protein
        )
        context.insert(eggs)

        let recipe = Recipe(title: "Omelette", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 3, unit: "large", recipe: recipe, ingredient: eggs)
        context.insert(ri)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        #expect(items[0].unit == "large")
        #expect(abs(items[0].quantity - 3.0) < 0.01)
    }

    @Test @MainActor func inventoryDeductionThenPurchaseUnitConversion() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let chicken = Ingredient(
            name: "chicken", displayName: "Chicken",
            category: IngredientCategory.protein
        )
        context.insert(chicken)

        // Recipe needs 1 kg chicken = 1000 g
        let recipe = Recipe(title: "Roast Chicken", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "kg", recipe: recipe, ingredient: chicken)
        context.insert(ri)

        // Have 400 g on hand → need 600 g
        let inventory = InventoryItem(quantity: 400, unit: "g", ingredient: chicken)
        context.insert(inventory)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        #expect(items[0].unit == "lb")
        // 600 g ≈ 1.323 lb → snap up to 1.5 lb
        #expect(abs(items[0].quantity - 1.5) < 0.01)
    }
}
