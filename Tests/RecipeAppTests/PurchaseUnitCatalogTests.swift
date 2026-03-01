import Testing
import SwiftData
import Foundation
@testable import RecipeApp

// MARK: - PurchaseUnitCatalog unit tests

@Suite("PurchaseUnitCatalog")
struct PurchaseUnitCatalogTests {

    // MARK: Protein — weight → lb, 0.5 lb increments

    @Test func proteinWeightSnapsToLb() {
        // 340 g chicken ≈ 0.75 lb → snap up to 1 lb (0.5 lb increments)
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 340, dimension: .weight, category: IngredientCategory.protein
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 1.0) < 0.01)
    }

    @Test func proteinSmallAmountSnapsToHalfLb() {
        // 50 g chicken ≈ 0.11 lb → snap up to 0.5 lb
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 50, dimension: .weight, category: IngredientCategory.protein
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 0.5) < 0.01)
    }

    @Test func proteinExactPoundStaysExact() {
        // 453.59237 g = exactly 1 lb
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 453.59237, dimension: .weight, category: IngredientCategory.protein
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 1.0) < 0.01)
    }

    @Test func proteinLargeAmountSnapsCorrectly() {
        // 1000 g ≈ 2.205 lb → snap up to 2.5 lb
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 1000, dimension: .weight, category: IngredientCategory.protein
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 2.5) < 0.01)
    }

    @Test func proteinVolumeReturnsNil() {
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 48, dimension: .volume, category: IngredientCategory.protein
        )
        #expect(result == nil)
    }

    // MARK: Spice — weight/volume → jar (1 oz)

    @Test func spiceWeightSnapsToJar() {
        // 10 g spice ≈ 0.35 oz → need 0.35 jars → snap to 1 jar
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 10, dimension: .weight, category: IngredientCategory.spice
        )
        #expect(result != nil)
        #expect(result!.unit == "jar")
        #expect(abs(result!.quantity - 1.0) < 0.01)
    }

    @Test func spiceVolumeSnapsToJar() {
        // 0.6 tsp spice → need to figure out fraction of jar → snap to 1 jar
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 0.6, dimension: .volume, category: IngredientCategory.spice
        )
        #expect(result != nil)
        #expect(result!.unit == "jar")
        #expect(result!.quantity >= 1.0)
    }

    @Test func spiceLargeVolumeSnapsToMultipleJars() {
        // 12 tsp = 0.25 cup of a spice → about 2 oz → 2 jars
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 12, dimension: .volume, category: IngredientCategory.spice
        )
        #expect(result != nil)
        #expect(result!.unit == "jar")
        #expect(result!.quantity >= 1.0)
    }

    @Test func spiceFullResultHasSizeLabel() {
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 10, dimension: .weight, category: IngredientCategory.spice
        )
        #expect(result != nil)
        #expect(result!.displayText.contains("1 oz"))
    }

    // MARK: Dairy — weight → oz (4 oz increments), volume → cup (0.5 cup increments)

    @Test func dairyWeightSnapsTo4OzIncrements() {
        // 100 g cheese ≈ 3.53 oz → snap up to 4 oz
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 100, dimension: .weight, category: IngredientCategory.dairy
        )
        #expect(result != nil)
        #expect(result!.unit == "oz")
        #expect(abs(result!.quantity - 4.0) < 0.01)
    }

    @Test func dairyVolumeSnapsToHalfCup() {
        // 60 tsp = 1.25 cups → snap to 1.5 cup
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 60, dimension: .volume, category: IngredientCategory.dairy
        )
        #expect(result != nil)
        #expect(result!.unit == "cup")
        #expect(abs(result!.quantity - 1.5) < 0.01)
    }

    // MARK: Grain — weight → lb (1 lb increments)

    @Test func grainWeightSnapsToLb() {
        // 500 g flour ≈ 1.10 lb → snap up to 2 lb (1 lb increments)
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 500, dimension: .weight, category: IngredientCategory.grain
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 2.0) < 0.01)
    }

    @Test func grainVolumeToCup() {
        // 96 tsp = 2 cups → exact
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 96, dimension: .volume, category: IngredientCategory.grain
        )
        #expect(result != nil)
        #expect(result!.unit == "cup")
        #expect(abs(result!.quantity - 2.0) < 0.01)
    }

    // MARK: Vegetable — weight → lb (0.5 lb increments)

    @Test func vegetableWeightSnapsToLb() {
        // 200 g carrots ≈ 0.44 lb → snap up to 0.5 lb
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 200, dimension: .weight, category: IngredientCategory.vegetable
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
        #expect(abs(result!.quantity - 0.5) < 0.01)
    }

    // MARK: Other — weight → oz (4 oz increments)

    @Test func otherWeightSnapsToOz() {
        // 50 g → 1.76 oz → snap to 4 oz (4 oz increments)
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 50, dimension: .weight, category: IngredientCategory.other
        )
        #expect(result != nil)
        #expect(result!.unit == "oz")
        #expect(abs(result!.quantity - 4.0) < 0.01)
    }

    // MARK: Count/other dimensions return nil

    @Test func countDimensionReturnsNil() {
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 3, dimension: .count, category: IngredientCategory.protein
        )
        #expect(result == nil)
    }

    @Test func otherDimensionReturnsNil() {
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 1, dimension: .other, category: IngredientCategory.spice
        )
        #expect(result == nil)
    }

    // MARK: Ingredient-specific overrides

    @Test func chickenBrothUsesCartons() {
        // 6 cups chicken broth = 288 tsp → should map to cartons (32 oz = 192 tsp)
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 288, dimension: .volume, category: IngredientCategory.other,
            ingredientName: "chicken broth"
        )
        #expect(result != nil)
        #expect(result!.unit == "carton")
        // 288 tsp / 192 tsp per carton = 1.5 → snap to 2 cartons
        #expect(abs(result!.quantity - 2.0) < 0.01)
        #expect(result!.displayText.contains("32 oz"))
    }

    @Test func milkUsesHalfGallons() {
        // 9 oz milk = 255.15 g → in weight dimension
        // half gallon ≈ 1892.7g, so 255.15g / 1892.7g ≈ 0.135 half gallons → snap to 0.5
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 255.15, dimension: .weight, category: IngredientCategory.dairy,
            ingredientName: "milk"
        )
        #expect(result != nil)
        #expect(result!.unit == "half gallon")
        #expect(result!.quantity == 0.5)
    }

    @Test func milkVolumeUsesHalfGallons() {
        // 96 tsp = 2 cups = 16 fl oz → half gallon = 384 tsp
        // 96 / 384 = 0.25 → snap to 0.5 half gallon
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 96, dimension: .volume, category: IngredientCategory.dairy,
            ingredientName: "milk"
        )
        #expect(result != nil)
        #expect(result!.unit == "half gallon")
        #expect(result!.quantity == 0.5)
    }

    @Test func heavyCreamUsesPint() {
        // 48 tsp = 1 cup heavy cream → pint = 96 tsp → 0.5 pints → snap to 1 pint
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 48, dimension: .volume, category: IngredientCategory.dairy,
            ingredientName: "heavy cream"
        )
        #expect(result != nil)
        #expect(result!.unit == "pint")
        #expect(abs(result!.quantity - 1.0) < 0.01)
    }

    @Test func blackBeansUseCans() {
        // 425 g black beans → 15 oz can = 425.24 g → 1 can
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 425, dimension: .weight, category: IngredientCategory.other,
            ingredientName: "black beans"
        )
        #expect(result != nil)
        #expect(result!.unit == "can")
        #expect(abs(result!.quantity - 1.0) < 0.01)
        #expect(result!.displayText.contains("15 oz"))
    }

    @Test func tomatoPasteUsesSmallCans() {
        // 85 g tomato paste → 6 oz can = 170.1 g → 0.5 cans → snap to 1 can
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 85, dimension: .weight, category: IngredientCategory.other,
            ingredientName: "tomato paste"
        )
        #expect(result != nil)
        #expect(result!.unit == "can")
        #expect(abs(result!.quantity - 1.0) < 0.01)
        #expect(result!.displayText.contains("6 oz"))
    }

    @Test func unknownIngredientFallsBackToCategory() {
        // "mystery protein" not in overrides → falls back to protein category (lb, 0.5 inc)
        let result = PurchaseUnitCatalog.purchaseQuantitySimple(
            baseQty: 340, dimension: .weight, category: IngredientCategory.protein,
            ingredientName: "mystery protein"
        )
        #expect(result != nil)
        #expect(result!.unit == "lb")
    }

    @Test func coconutMilkUsesCans() {
        // 400 g coconut milk → 13.5 oz can ≈ 382.72 g → 1.045 cans → snap to 2 cans? No, 1 increment
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 400, dimension: .weight, category: IngredientCategory.other,
            ingredientName: "coconut milk"
        )
        #expect(result != nil)
        #expect(result!.unit == "can")
        #expect(result!.quantity >= 1.0)
        #expect(result!.displayText.contains("13.5 oz"))
    }

    @Test func sourCreamUsesContainers() {
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 300, dimension: .weight, category: IngredientCategory.dairy,
            ingredientName: "sour cream"
        )
        #expect(result != nil)
        #expect(result!.unit == "container")
        #expect(result!.displayText.contains("16 oz"))
    }

    @Test func creamCheeseUsesBlocks() {
        let result = PurchaseUnitCatalog.purchaseQuantity(
            baseQty: 200, dimension: .weight, category: IngredientCategory.dairy,
            ingredientName: "cream cheese"
        )
        #expect(result != nil)
        #expect(result!.unit == "block")
        #expect(result!.displayText.contains("8 oz"))
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
        // 500 g ≈ 1.10 lb → snap up to 1.5 lb (0.5 lb increments)
        #expect(abs(items[0].quantity - 1.5) < 0.01)
        // Recipe amount preserved
        #expect(items[0].recipeQuantity > 0)
        #expect(!items[0].recipeUnit.isEmpty)
    }

    @Test @MainActor func dairyVolumeShowsCup() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let milk = Ingredient(
            name: "cheese", displayName: "Cheese",
            category: IngredientCategory.dairy
        )
        context.insert(milk)

        // 10 tbsp cheese = 30 tsp = 0.625 cup → snap to 1 cup (0.5 cup increments)
        let recipe = Recipe(title: "Mac and Cheese", servings: 1)
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
        #expect(abs(items[0].quantity - 1.0) < 0.01)
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
        // 300 g ≈ 0.661 lb → snap up to 1 lb (1 lb increments)
        #expect(abs(items[0].quantity - 1.0) < 0.01)
    }

    @Test @MainActor func spiceVolumeShowsJar() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let cumin = Ingredient(
            name: "cumin", displayName: "Cumin",
            category: IngredientCategory.spice
        )
        context.insert(cumin)

        // 2 tsp cumin → convert to jar units
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
        #expect(items[0].unit == "jar")
        #expect(items[0].quantity >= 1.0)
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
        // 600 g ≈ 1.323 lb → snap up to 1.5 lb (0.5 lb increments)
        #expect(abs(items[0].quantity - 1.5) < 0.01)
    }

    @Test @MainActor func chickenBrothShowsCartons() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let broth = Ingredient(
            name: "chicken broth", displayName: "Chicken Broth",
            category: IngredientCategory.other
        )
        context.insert(broth)

        // 6 cups chicken broth = 288 tsp
        let recipe = Recipe(title: "Soup", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 6, unit: "cup", recipe: recipe, ingredient: broth)
        context.insert(ri)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        #expect(items[0].unit == "carton")
        // 288 tsp / 192 tsp per carton = 1.5 → snap to 2 cartons
        #expect(abs(items[0].quantity - 2.0) < 0.01)
    }

    @Test @MainActor func milkShowsHalfGallons() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let milk = Ingredient(
            name: "milk", displayName: "Milk",
            category: IngredientCategory.dairy
        )
        context.insert(milk)

        // 2 cups milk = 96 tsp
        let recipe = Recipe(title: "Oatmeal", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "cup", recipe: recipe, ingredient: milk)
        context.insert(ri)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        #expect(items[0].unit == "half gallon")
        // 96 tsp / 384 tsp per half gallon = 0.25 → snap to 0.5
        #expect(abs(items[0].quantity - 0.5) < 0.01)
    }

    @Test @MainActor func recipeQuantityIsPreserved() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let chicken = Ingredient(
            name: "chicken breast", displayName: "Chicken Breast",
            category: IngredientCategory.protein
        )
        context.insert(chicken)

        // 500 g chicken breast
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
        // Shelf unit (primary display)
        #expect(items[0].unit == "lb")
        #expect(items[0].quantity > 0)
        // Precise recipe amount (detail tap)
        #expect(items[0].recipeQuantity > 0)
        #expect(!items[0].recipeUnit.isEmpty)
    }
}
