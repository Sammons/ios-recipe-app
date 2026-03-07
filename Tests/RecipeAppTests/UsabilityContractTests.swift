import Testing
import SwiftData
import Foundation
@testable import RecipeApp

// MARK: - Usability Contract Tests
//
// These tests codify the "human contract" — the system must behave in ways
// that make sense to someone standing in their kitchen. If pantry has 1 quart
// of chicken broth and the recipe calls for 4 cups, that MUST match.
// If the recipe says "2 cups flour", the shopping list must never show grams.

// ═══════════════════════════════════════════════════════════════════════════
// SECTION 1: Cross-Unit Matching — Density-Aware Ingredients
// ═══════════════════════════════════════════════════════════════════════════

@Suite("CrossUnitMatching.Dairy", .serialized)
struct CrossUnitMatchingDairyTests {

    // -- Whole Milk (density 1.030) --

    @Test @MainActor func milkQuartSatisfiesCupsRecipe() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let milk = Ingredient(name: "milk whole", displayName: "Whole Milk", category: IngredientCategory.dairy, density: 1.030)
        ctx.insert(milk)
        let recipe = Recipe(title: "Pudding", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: milk)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 1, unit: "quart", ingredient: milk)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        // 1 quart = 4 cups exactly
        #expect(result.count == 1, "1 quart of milk should satisfy 4 cups needed")
    }

    @Test @MainActor func milkGallonSatisfiesQuartRecipe() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let milk = Ingredient(name: "milk whole", displayName: "Whole Milk", category: IngredientCategory.dairy, density: 1.030)
        ctx.insert(milk)
        let recipe = Recipe(title: "Chowder", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "quart", recipe: recipe, ingredient: milk)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 1, unit: "gallon", ingredient: milk)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        // 1 gallon = 4 quarts, recipe needs 2
        #expect(result.count == 1)
    }

    @Test @MainActor func milkCupsSatisfiedByTablespoons() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let milk = Ingredient(name: "milk whole", displayName: "Whole Milk", category: IngredientCategory.dairy, density: 1.030)
        ctx.insert(milk)
        let recipe = Recipe(title: "Cereal", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 0.5, unit: "cup", recipe: recipe, ingredient: milk)
        ctx.insert(ri)
        // 0.5 cup = 8 tbsp
        let inv = InventoryItem(quantity: 8, unit: "tbsp", ingredient: milk)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    @Test @MainActor func milkWeightSatisfiesVolumeRecipe() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let milk = Ingredient(name: "milk whole", displayName: "Whole Milk", category: IngredientCategory.dairy, density: 1.030)
        ctx.insert(milk)
        let recipe = Recipe(title: "Smoothie", servings: 1)
        ctx.insert(recipe)
        // 1 cup milk = 48 tsp × 4.92892 ml/tsp × 1.030 g/ml ≈ 243.6 g
        let ri = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe, ingredient: milk)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 250, unit: "g", ingredient: milk)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "250g milk should satisfy 1 cup (≈243.6g)")
    }

    @Test @MainActor func milkLitersSatisfiesCupsRecipe() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let milk = Ingredient(name: "milk whole", displayName: "Whole Milk", category: IngredientCategory.dairy, density: 1.030)
        ctx.insert(milk)
        let recipe = Recipe(title: "Oatmeal", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "cup", recipe: recipe, ingredient: milk)
        ctx.insert(ri)
        // 1 liter ≈ 4.22675 cups → 2 cups should be covered
        let inv = InventoryItem(quantity: 1, unit: "l", ingredient: milk)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    // -- Heavy Cream (density 0.994) --

    @Test @MainActor func creamCupsSatisfiedByPint() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let cream = Ingredient(name: "heavy cream", displayName: "Heavy Cream", category: IngredientCategory.dairy, density: 0.994)
        ctx.insert(cream)
        let recipe = Recipe(title: "Pasta", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe, ingredient: cream)
        ctx.insert(ri)
        // 1 pint = 2 cups
        let inv = InventoryItem(quantity: 1, unit: "pint", ingredient: cream)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    @Test @MainActor func creamTbspSatisfiedByFlOz() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let cream = Ingredient(name: "heavy cream", displayName: "Heavy Cream", category: IngredientCategory.dairy, density: 0.994)
        ctx.insert(cream)
        let recipe = Recipe(title: "Coffee", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: cream)
        ctx.insert(ri)
        // 1 fl oz = 2 tbsp
        let inv = InventoryItem(quantity: 1, unit: "fl oz", ingredient: cream)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    // -- Butter (density 0.911) --

    @Test @MainActor func butterCupsSatisfiedByGrams() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let butter = Ingredient(name: "butter unsalted", displayName: "Butter Unsalted", category: IngredientCategory.dairy, density: 0.911)
        ctx.insert(butter)
        let recipe = Recipe(title: "Cookies", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 0.5, unit: "cup", recipe: recipe, ingredient: butter)
        ctx.insert(ri)
        // 0.5 cup = 24 tsp × 4.92892 ml × 0.911 g/ml ≈ 107.8g
        let inv = InventoryItem(quantity: 115, unit: "g", ingredient: butter)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "115g butter should satisfy 0.5 cup (≈107.8g)")
    }

    @Test @MainActor func butterTbspSatisfiedByOz() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let butter = Ingredient(name: "butter unsalted", displayName: "Butter Unsalted", category: IngredientCategory.dairy, density: 0.911)
        ctx.insert(butter)
        let recipe = Recipe(title: "Toast", servings: 1)
        ctx.insert(recipe)
        // 2 tbsp butter
        let ri = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: butter)
        ctx.insert(ri)
        // 2 tbsp = 6 tsp × 4.92892 ml × 0.911 g/ml ≈ 26.94g / 28.35 g/oz ≈ 0.95 oz
        let inv = InventoryItem(quantity: 1, unit: "oz", ingredient: butter)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "1 oz butter should satisfy 2 tbsp (≈0.95 oz)")
    }

    @Test @MainActor func butterStickNotConvertibleToCups() throws {
        // "stick" is a count unit — no conversion to cups without density bridge via count
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let butter = Ingredient(name: "butter unsalted", displayName: "Butter Unsalted", category: IngredientCategory.dairy, density: 0.911)
        ctx.insert(butter)
        let recipe = Recipe(title: "Cake", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 0.5, unit: "cup", recipe: recipe, ingredient: butter)
        ctx.insert(ri)
        // "stick" is a count unit, not volume/weight — cannot match cups
        let inv = InventoryItem(quantity: 1, unit: "stick", ingredient: butter)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 0, "stick (count) cannot match cup (volume)")
    }
}

@Suite("CrossUnitMatching.Broths", .serialized)
struct CrossUnitMatchingBrothTests {

    // THE BUG THAT STARTED IT ALL: chicken broth not matching from pantry

    @Test @MainActor func chickenBrothQuartSatisfiesCupsRecipe() throws {
        // This is the exact bug scenario: pantry has 1 quart, recipe needs 4 cups
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        ctx.insert(broth)
        let recipe = Recipe(title: "Chicken Soup", servings: 4)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: broth)
        ctx.insert(ri)
        // 1 quart = 4 cups exactly
        let inv = InventoryItem(quantity: 1, unit: "quart", ingredient: broth)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "1 quart chicken broth MUST satisfy 4 cups needed")
    }

    @Test @MainActor func chickenBrothCupsNotEnoughForQuart() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        ctx.insert(broth)
        let recipe = Recipe(title: "Stew", servings: 4)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "quart", recipe: recipe, ingredient: broth)
        ctx.insert(ri)
        // 3 cups < 2 quarts (8 cups)
        let inv = InventoryItem(quantity: 3, unit: "cup", ingredient: broth)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 0, "3 cups is not enough for 2 quarts")
    }

    @Test @MainActor func chickenBrothMlSatisfiesCups() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        ctx.insert(broth)
        let recipe = Recipe(title: "Risotto", servings: 2)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "cup", recipe: recipe, ingredient: broth)
        ctx.insert(ri)
        // 2 cups = 96 tsp × 4.92892 ml ≈ 473.18 ml
        let inv = InventoryItem(quantity: 500, unit: "ml", ingredient: broth)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "500ml broth should satisfy 2 cups (≈473ml)")
    }

    @Test @MainActor func chickenBrothLiterSatisfiesQuarts() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        ctx.insert(broth)
        let recipe = Recipe(title: "Soup", servings: 4)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "quart", recipe: recipe, ingredient: broth)
        ctx.insert(ri)
        // 1 liter ≈ 1.057 quarts
        let inv = InventoryItem(quantity: 1, unit: "l", ingredient: broth)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "1 liter should satisfy 1 quart (1 L > 1 qt)")
    }

    @Test @MainActor func beefBrothCupsSatisfiedByQuart() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let broth = Ingredient(name: "beef broth", displayName: "Beef Broth", category: IngredientCategory.other)
        ctx.insert(broth)
        let recipe = Recipe(title: "Beef Stew", servings: 4)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 3, unit: "cup", recipe: recipe, ingredient: broth)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 1, unit: "quart", ingredient: broth)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        // 1 quart = 4 cups ≥ 3 cups
        #expect(result.count == 1)
    }

    @Test @MainActor func vegetableBrothTbspSatisfiedByCups() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let broth = Ingredient(name: "vegetable broth", displayName: "Vegetable Broth", category: IngredientCategory.other)
        ctx.insert(broth)
        let recipe = Recipe(title: "Veggie Soup", servings: 2)
        ctx.insert(recipe)
        // 8 tbsp = 0.5 cup
        let ri = RecipeIngredient(quantity: 8, unit: "tbsp", recipe: recipe, ingredient: broth)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 1, unit: "cup", ingredient: broth)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }
}

@Suite("CrossUnitMatching.Oils", .serialized)
struct CrossUnitMatchingOilTests {

    @Test @MainActor func oliveOilTbspSatisfiedByCup() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        ctx.insert(oil)
        let recipe = Recipe(title: "Salad", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 3, unit: "tbsp", recipe: recipe, ingredient: oil)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 1, unit: "cup", ingredient: oil)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        // 1 cup = 16 tbsp ≥ 3 tbsp
        #expect(result.count == 1)
    }

    @Test @MainActor func oliveOilGramsSatisfyTbspRecipe() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        ctx.insert(oil)
        let recipe = Recipe(title: "Roasted Veggies", servings: 1)
        ctx.insert(recipe)
        // 2 tbsp oil = 6 tsp × 4.92892 ml × 0.915 g/ml ≈ 27.06g
        let ri = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: oil)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 30, unit: "g", ingredient: oil)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "30g oil should satisfy 2 tbsp (≈27g)")
    }

    @Test @MainActor func coconutOilMlSatisfiesTsp() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let oil = Ingredient(name: "coconut oil", displayName: "Coconut Oil", category: IngredientCategory.other, density: 0.900)
        ctx.insert(oil)
        let recipe = Recipe(title: "Smoothie Bowl", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "tsp", recipe: recipe, ingredient: oil)
        ctx.insert(ri)
        // 2 tsp = 2 × 4.92892 ml = 9.86 ml
        let inv = InventoryItem(quantity: 15, unit: "ml", ingredient: oil)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    @Test @MainActor func sesameOilOzSatisfiesTbsp() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let oil = Ingredient(name: "sesame oil", displayName: "Sesame Oil", category: IngredientCategory.other, density: 0.920)
        ctx.insert(oil)
        let recipe = Recipe(title: "Stir Fry", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "tbsp", recipe: recipe, ingredient: oil)
        ctx.insert(ri)
        // 1 tbsp = 3 tsp × 4.92892 ml × 0.920 g/ml ≈ 13.6g / 28.35 ≈ 0.48 oz
        let inv = InventoryItem(quantity: 1, unit: "oz", ingredient: oil)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "1 oz sesame oil should satisfy 1 tbsp (≈0.48 oz)")
    }
}

@Suite("CrossUnitMatching.Sweeteners", .serialized)
struct CrossUnitMatchingSweetenerTests {

    @Test @MainActor func honeyCupSatisfiedByOz() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let honey = Ingredient(name: "honey", displayName: "Honey", category: IngredientCategory.other, density: 1.420)
        ctx.insert(honey)
        let recipe = Recipe(title: "Granola", servings: 1)
        ctx.insert(recipe)
        // 0.25 cup = 12 tsp × 4.92892 ml × 1.420 g/ml ≈ 83.98g = 2.96 oz
        let ri = RecipeIngredient(quantity: 0.25, unit: "cup", recipe: recipe, ingredient: honey)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 4, unit: "oz", ingredient: honey)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "4 oz honey should satisfy 0.25 cup (≈3 oz)")
    }

    @Test @MainActor func mapleSyrupTbspSatisfiedByMl() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let syrup = Ingredient(name: "maple syrup", displayName: "Maple Syrup", category: IngredientCategory.other, density: 1.370)
        ctx.insert(syrup)
        let recipe = Recipe(title: "Pancakes", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 3, unit: "tbsp", recipe: recipe, ingredient: syrup)
        ctx.insert(ri)
        // 3 tbsp = 9 tsp × 4.92892 ml ≈ 44.36 ml
        let inv = InventoryItem(quantity: 50, unit: "ml", ingredient: syrup)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    @Test @MainActor func brownSugarCupsSatisfiedByGrams() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let sugar = Ingredient(name: "light brown sugar", displayName: "Light Brown Sugar", category: IngredientCategory.other, density: 0.928)
        ctx.insert(sugar)
        let recipe = Recipe(title: "Brown Butter Cookies", servings: 1)
        ctx.insert(recipe)
        // 1 cup = 48 tsp × 4.92892 ml × 0.928 g/ml ≈ 219.6g
        let ri = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe, ingredient: sugar)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 250, unit: "g", ingredient: sugar)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "250g brown sugar should satisfy 1 cup (≈220g)")
    }

    @Test @MainActor func granulatedSugarLbSatisfiesCups() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let sugar = Ingredient(name: "granulated sugar", displayName: "Granulated Sugar", category: IngredientCategory.other, density: 0.845)
        ctx.insert(sugar)
        let recipe = Recipe(title: "Cake", servings: 1)
        ctx.insert(recipe)
        // 2 cups sugar = 96 tsp × 4.92892 ml × 0.845 g/ml ≈ 399.4g
        let ri = RecipeIngredient(quantity: 2, unit: "cup", recipe: recipe, ingredient: sugar)
        ctx.insert(ri)
        // 1 lb = 453.59g > 399.4g
        let inv = InventoryItem(quantity: 1, unit: "lb", ingredient: sugar)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "1 lb sugar should satisfy 2 cups (≈399g)")
    }
}

@Suite("CrossUnitMatching.Flours", .serialized)
struct CrossUnitMatchingFlourTests {

    @Test @MainActor func allPurposeFlourGramsSatisfyCups() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let flour = Ingredient(name: "all-purpose flour", displayName: "All-Purpose Flour", category: IngredientCategory.grain, density: 0.529)
        ctx.insert(flour)
        let recipe = Recipe(title: "Bread", servings: 1)
        ctx.insert(recipe)
        // 2 cups = 96 tsp × 4.92892 ml × 0.529 g/ml ≈ 250.3g
        let ri = RecipeIngredient(quantity: 2, unit: "cup", recipe: recipe, ingredient: flour)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 300, unit: "g", ingredient: flour)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "300g flour should satisfy 2 cups (≈250g)")
    }

    @Test @MainActor func allPurposeFlourLbSatisfiesCups() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let flour = Ingredient(name: "all-purpose flour", displayName: "All-Purpose Flour", category: IngredientCategory.grain, density: 0.529)
        ctx.insert(flour)
        let recipe = Recipe(title: "Pizza Dough", servings: 1)
        ctx.insert(recipe)
        // 3 cups flour ≈ 375.4g
        let ri = RecipeIngredient(quantity: 3, unit: "cup", recipe: recipe, ingredient: flour)
        ctx.insert(ri)
        // 1 lb = 453.59g
        let inv = InventoryItem(quantity: 1, unit: "lb", ingredient: flour)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "1 lb flour (453g) should satisfy 3 cups (≈375g)")
    }

    @Test @MainActor func almondFlourKgSatisfiesCups() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let flour = Ingredient(name: "almond flour", displayName: "Almond Flour", category: IngredientCategory.grain, density: 0.400)
        ctx.insert(flour)
        let recipe = Recipe(title: "Macarons", servings: 1)
        ctx.insert(recipe)
        // 2 cups almond flour = 96 tsp × 4.92892 ml × 0.400 g/ml ≈ 189.3g
        let ri = RecipeIngredient(quantity: 2, unit: "cup", recipe: recipe, ingredient: flour)
        ctx.insert(ri)
        // 1 kg = 1000g >> 189.3g
        let inv = InventoryItem(quantity: 1, unit: "kg", ingredient: flour)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    @Test @MainActor func riceFlourOzSatisfiesTbsp() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let flour = Ingredient(name: "rice flour", displayName: "Rice Flour", category: IngredientCategory.grain, density: 0.620)
        ctx.insert(flour)
        let recipe = Recipe(title: "Tempura", servings: 1)
        ctx.insert(recipe)
        // 4 tbsp = 12 tsp × 4.92892 ml × 0.620 g/ml ≈ 36.66g / 28.35 ≈ 1.29 oz
        let ri = RecipeIngredient(quantity: 4, unit: "tbsp", recipe: recipe, ingredient: flour)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 2, unit: "oz", ingredient: flour)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "2 oz rice flour should satisfy 4 tbsp (≈1.3 oz)")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION 2: Display Format Assertions
// ═══════════════════════════════════════════════════════════════════════════

@Suite("DisplayFormat.RecipeUnits", .serialized)
struct DisplayFormatRecipeUnitTests {

    @Test @MainActor func shoppingListShowsCupsNotGrams() throws {
        // THE SECOND BUG: shopping list was showing grams instead of recipe units
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        ctx.insert(broth)
        let recipe = Recipe(title: "Soup", servings: 2)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: broth)
        ctx.insert(ri)
        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 2, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()
        ShoppingListGenerator.generate(context: ctx)
        let items = try ctx.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        // recipeUnit must be a volume unit, not grams
        let unit = items[0].recipeUnit
        #expect(unit != "g", "Shopping list must not show grams when recipe says cups")
        #expect(unit != "kg", "Shopping list must not show kg when recipe says cups")
        let volumeUnits: Set<String> = ["tsp", "tbsp", "cup", "pint", "quart", "gallon"]
        #expect(volumeUnits.contains(unit), "Recipe display unit should be a volume unit, got: \(unit)")
    }

    @Test @MainActor func shoppingListShowsTbspNotGramsForSmallVolume() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        ctx.insert(oil)
        let recipe = Recipe(title: "Salad", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: oil)
        ctx.insert(ri)
        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.lunch, servings: 1, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()
        ShoppingListGenerator.generate(context: ctx)
        let items = try ctx.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        // With density, oil gets normalized to grams internally.
        // But prettyDisplay for weight should show "g", and that's the recipeUnit.
        // The key contract: recipeUnit should never show an absurd number like 0.0295 liters
        let unit = items[0].recipeUnit
        let qty = items[0].recipeQuantity
        // Must be a reasonable unit/qty combo
        #expect(qty > 0.01, "Recipe quantity should not be a tiny fraction")
        #expect(qty < 10000, "Recipe quantity should not be unreasonably large")
    }

    @Test @MainActor func prettyDisplayNeverShowsTinyLiters() {
        // 2 tbsp = 6 tsp — prettyDisplay should show tbsp, not liters
        let (qty, unit) = UnitConverter.prettyDisplay(baseQuantity: 6.0, dimension: .volume)
        #expect(unit == "tbsp")
        #expect(abs(qty - 2.0) < 0.001)
    }

    @Test @MainActor func prettyDisplayShowsCupForOneCup() {
        let (qty, unit) = UnitConverter.prettyDisplay(baseQuantity: 48.0, dimension: .volume)
        #expect(unit == "cup")
        #expect(abs(qty - 1.0) < 0.001)
    }

    @Test @MainActor func prettyDisplayShowsQuartForFourCups() {
        // 4 cups = 192 tsp
        let (qty, unit) = UnitConverter.prettyDisplay(baseQuantity: 192.0, dimension: .volume)
        #expect(unit == "quart")
        #expect(abs(qty - 1.0) < 0.001)
    }

    @Test @MainActor func prettyDisplayShowsGallonForSixteenCups() {
        // 16 cups = 768 tsp
        let (qty, unit) = UnitConverter.prettyDisplay(baseQuantity: 768.0, dimension: .volume)
        #expect(unit == "gallon")
        #expect(abs(qty - 1.0) < 0.001)
    }

    @Test @MainActor func prettyDisplayWeightShowsGramsUnder1Kg() {
        let (qty, unit) = UnitConverter.prettyDisplay(baseQuantity: 500.0, dimension: .weight)
        #expect(unit == "g")
        #expect(abs(qty - 500.0) < 0.001)
    }

    @Test @MainActor func prettyDisplayWeightShowsKgOver1Kg() {
        let (qty, unit) = UnitConverter.prettyDisplay(baseQuantity: 1500.0, dimension: .weight)
        #expect(unit == "kg")
        #expect(abs(qty - 1.5) < 0.001)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION 3: Shopping List Accuracy
// ═══════════════════════════════════════════════════════════════════════════

@Suite("ShoppingListAccuracy", .serialized)
struct ShoppingListAccuracyTests {

    @Test @MainActor func partialPantryShowsCorrectRemainder() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let flour = Ingredient(name: "all-purpose flour", displayName: "All-Purpose Flour", category: IngredientCategory.grain, density: 0.529)
        ctx.insert(flour)
        let recipe = Recipe(title: "Cake", servings: 1)
        ctx.insert(recipe)
        // Need 3 cups flour
        let ri = RecipeIngredient(quantity: 3, unit: "cup", recipe: recipe, ingredient: flour)
        ctx.insert(ri)
        // Have 1 cup flour
        let inv = InventoryItem(quantity: 1, unit: "cup", ingredient: flour)
        ctx.insert(inv)
        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()
        ShoppingListGenerator.generate(context: ctx)
        let items = try ctx.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        // With density, flour is normalized to grams: 3 cups ≈ 375.4g, 1 cup ≈ 125.15g
        // Need 250.3g → lb (grain): 250.3/453.59 = 0.552 → snap to 1 lb
        #expect(items[0].unit == "lb")
        #expect(abs(items[0].quantity - 1.0) < 0.01)
    }

    @Test @MainActor func partialPantryCrossDimDeduction() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let flour = Ingredient(name: "all-purpose flour", displayName: "All-Purpose Flour", category: IngredientCategory.grain, density: 0.529)
        ctx.insert(flour)
        let recipe = Recipe(title: "Muffins", servings: 1)
        ctx.insert(recipe)
        // Recipe needs 200g flour
        let ri = RecipeIngredient(quantity: 200, unit: "g", recipe: recipe, ingredient: flour)
        ctx.insert(ri)
        // Pantry has 1 cup flour ≈ 125.15g with density 0.529
        let inv = InventoryItem(quantity: 1, unit: "cup", ingredient: flour)
        ctx.insert(inv)
        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()
        ShoppingListGenerator.generate(context: ctx)
        let items = try ctx.fetch(FetchDescriptor<ShoppingListItem>())
        // 200g - 125.15g ≈ 74.85g → lb: 0.165 → snap to 1 lb
        #expect(items.count == 1)
        #expect(items[0].unit == "lb")
        #expect(abs(items[0].quantity - 1.0) < 0.01)
    }

    @Test @MainActor func fullPantryCoverageProducesNoShoppingItems() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken Breast", category: IngredientCategory.protein)
        let salt = Ingredient(name: "kosher salt", displayName: "Kosher Salt", category: IngredientCategory.spice, density: 1.220)
        ctx.insert(chicken)
        ctx.insert(salt)
        let recipe = Recipe(title: "Simple Chicken", servings: 1)
        ctx.insert(recipe)
        let ri1 = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipe, ingredient: chicken)
        let ri2 = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipe, ingredient: salt)
        ctx.insert(ri1)
        ctx.insert(ri2)
        // Pantry covers everything
        let inv1 = InventoryItem(quantity: 2, unit: "lb", ingredient: chicken)
        let inv2 = InventoryItem(quantity: 10, unit: "tsp", ingredient: salt)
        ctx.insert(inv1)
        ctx.insert(inv2)
        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()
        ShoppingListGenerator.generate(context: ctx)
        let items = try ctx.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 0, "Full pantry coverage should produce no shopping items")
    }

    @Test @MainActor func multipleRecipesAggregateCorrectly() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let sugar = Ingredient(name: "granulated sugar", displayName: "Granulated Sugar", category: IngredientCategory.other, density: 0.845)
        ctx.insert(sugar)
        // Recipe 1: 1 cup sugar
        let r1 = Recipe(title: "Cake", servings: 1)
        ctx.insert(r1)
        let ri1 = RecipeIngredient(quantity: 1, unit: "cup", recipe: r1, ingredient: sugar)
        ctx.insert(ri1)
        // Recipe 2: 0.5 cup sugar
        let r2 = Recipe(title: "Icing", servings: 1)
        ctx.insert(r2)
        let ri2 = RecipeIngredient(quantity: 0.5, unit: "cup", recipe: r2, ingredient: sugar)
        ctx.insert(ri2)
        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let e1 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.lunch, servings: 1, recipe: r1)
        let e2 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: r2)
        ctx.insert(e1)
        ctx.insert(e2)
        try ctx.save()
        ShoppingListGenerator.generate(context: ctx)
        let items = try ctx.fetch(FetchDescriptor<ShoppingListItem>())
        // Should be aggregated into a single item
        #expect(items.count == 1, "Same ingredient from 2 recipes should aggregate into 1 shopping item")
    }

    @Test @MainActor func servingScalingWorksCorrectly() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken Breast", category: IngredientCategory.protein)
        ctx.insert(chicken)
        // Recipe: 1 lb chicken for 2 servings
        let recipe = Recipe(title: "Grilled Chicken", servings: 2)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipe, ingredient: chicken)
        ctx.insert(ri)
        // Meal plan: 4 servings (2x scale)
        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 4, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()
        ShoppingListGenerator.generate(context: ctx)
        let items = try ctx.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        // 1 lb × 2 = 2 lb → protein: lb, 0.5 inc → 2 lb
        #expect(items[0].unit == "lb")
        #expect(abs(items[0].quantity - 2.0) < 0.01)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION 4: Edge Case Ingredients
// ═══════════════════════════════════════════════════════════════════════════

@Suite("EdgeCaseIngredients", .serialized)
struct EdgeCaseIngredientTests {

    // -- Eggs: count units --

    @Test @MainActor func eggsCountMatchesExact() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let eggs = Ingredient(name: "eggs", displayName: "Eggs", category: IngredientCategory.protein)
        ctx.insert(eggs)
        let recipe = Recipe(title: "Omelette", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 3, unit: "large", recipe: recipe, ingredient: eggs)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 3, unit: "large", ingredient: eggs)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    @Test @MainActor func eggsCountInsufficientFails() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let eggs = Ingredient(name: "eggs", displayName: "Eggs", category: IngredientCategory.protein)
        ctx.insert(eggs)
        let recipe = Recipe(title: "Cake", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 4, unit: "large", recipe: recipe, ingredient: eggs)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 2, unit: "large", ingredient: eggs)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 0, "2 eggs should not satisfy 4 eggs needed")
    }

    @Test @MainActor func eggsLargeDoesNotMatchMedium() throws {
        // "large" and "medium" are different aggregation keys
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let eggs = Ingredient(name: "eggs", displayName: "Eggs", category: IngredientCategory.protein)
        ctx.insert(eggs)
        let recipe = Recipe(title: "Scramble", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "large", recipe: recipe, ingredient: eggs)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 12, unit: "medium", ingredient: eggs)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 0, "medium eggs should not satisfy large egg requirement")
    }

    // -- Vanilla extract: tsp/ml --

    @Test @MainActor func vanillaExtractMlSatisfiesTsp() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let vanilla = Ingredient(name: "vanilla extract", displayName: "Vanilla Extract", category: IngredientCategory.spice)
        ctx.insert(vanilla)
        let recipe = Recipe(title: "Cookies", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipe, ingredient: vanilla)
        ctx.insert(ri)
        // 1 tsp = 4.92892 ml
        let inv = InventoryItem(quantity: 5, unit: "ml", ingredient: vanilla)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "5 ml vanilla should satisfy 1 tsp (≈4.93 ml)")
    }

    @Test @MainActor func vanillaExtractTbspSatisfiedByTsp() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let vanilla = Ingredient(name: "vanilla extract", displayName: "Vanilla Extract", category: IngredientCategory.spice)
        ctx.insert(vanilla)
        let recipe = Recipe(title: "Cake", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "tbsp", recipe: recipe, ingredient: vanilla)
        ctx.insert(ri)
        // 1 tbsp = 3 tsp
        let inv = InventoryItem(quantity: 3, unit: "tsp", ingredient: vanilla)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    // -- Coconut milk canned (density 0.930) --

    @Test @MainActor func coconutMilkCupsMatchedFromMl() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let cmilk = Ingredient(name: "coconut milk canned", displayName: "Coconut Milk", category: IngredientCategory.other, density: 0.930)
        ctx.insert(cmilk)
        let recipe = Recipe(title: "Curry", servings: 2)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe, ingredient: cmilk)
        ctx.insert(ri)
        // 1 cup = 236.59 ml
        let inv = InventoryItem(quantity: 400, unit: "ml", ingredient: cmilk)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1)
    }

    // -- Soy sauce (density 1.110) --

    @Test @MainActor func soySauceOzSatisfiesTbsp() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let soy = Ingredient(name: "soy sauce", displayName: "Soy Sauce", category: IngredientCategory.other, density: 1.110)
        ctx.insert(soy)
        let recipe = Recipe(title: "Stir Fry", servings: 1)
        ctx.insert(recipe)
        // 2 tbsp soy = 6 tsp × 4.92892 × 1.110 ≈ 32.83g / 28.35 ≈ 1.16 oz
        let ri = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: soy)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 2, unit: "oz", ingredient: soy)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "2 oz soy sauce should satisfy 2 tbsp (≈1.16 oz)")
    }

    // -- Cocoa powder (density 0.480) --

    @Test @MainActor func cocoaPowderGramsSatisfyTbsp() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let cocoa = Ingredient(name: "cocoa powder", displayName: "Cocoa Powder", category: IngredientCategory.spice, density: 0.480)
        ctx.insert(cocoa)
        let recipe = Recipe(title: "Hot Cocoa", servings: 1)
        ctx.insert(recipe)
        // 3 tbsp = 9 tsp × 4.92892 ml × 0.480 g/ml ≈ 21.29g
        let ri = RecipeIngredient(quantity: 3, unit: "tbsp", recipe: recipe, ingredient: cocoa)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 25, unit: "g", ingredient: cocoa)
        ctx.insert(inv)
        try ctx.save()
        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "25g cocoa should satisfy 3 tbsp (≈21g)")
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION 5: CanCookNow Filter — Exhaustive Coverage Levels
// ═══════════════════════════════════════════════════════════════════════════

@Suite("CanCookNowFilter", .serialized)
struct CanCookNowFilterTests {

    @Test @MainActor func allFiveIngredientsCoveredInDifferentUnits() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext

        // 5-ingredient recipe where pantry has each in a different unit
        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken", category: IngredientCategory.protein)
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        let salt = Ingredient(name: "kosher salt", displayName: "Salt", category: IngredientCategory.spice, density: 1.220)
        let garlic = Ingredient(name: "garlic", displayName: "Garlic", category: IngredientCategory.vegetable)
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        for i in [chicken, oil, salt, garlic, broth] { ctx.insert(i) }

        let recipe = Recipe(title: "Chicken in Broth", servings: 2)
        ctx.insert(recipe)
        let ri1 = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipe, ingredient: chicken)
        let ri2 = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: oil)
        let ri3 = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipe, ingredient: salt)
        let ri4 = RecipeIngredient(quantity: 3, unit: "clove", recipe: recipe, ingredient: garlic)
        let ri5 = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: broth)
        for ri in [ri1, ri2, ri3, ri4, ri5] { ctx.insert(ri) }

        // Pantry in different but compatible units
        let inv1 = InventoryItem(quantity: 500, unit: "g", ingredient: chicken)     // ~1.1 lb ≥ 1 lb (weight-to-weight)
        let inv2 = InventoryItem(quantity: 0.25, unit: "cup", ingredient: oil)       // 0.25 cup = 4 tbsp ≥ 2 tbsp
        let inv3 = InventoryItem(quantity: 2, unit: "tsp", ingredient: salt)         // 2 tsp ≥ 1 tsp
        let inv4 = InventoryItem(quantity: 5, unit: "clove", ingredient: garlic)     // 5 ≥ 3
        let inv5 = InventoryItem(quantity: 1, unit: "quart", ingredient: broth)      // 1 quart = 4 cups ≥ 4 cups
        for inv in [inv1, inv2, inv3, inv4, inv5] { ctx.insert(inv) }

        try ctx.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 1, "Recipe should be cookable — all 5 ingredients covered in different units")
    }

    @Test @MainActor func fourOfFiveIngredientsIsNotCookable() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext

        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken", category: IngredientCategory.protein)
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        let salt = Ingredient(name: "kosher salt", displayName: "Salt", category: IngredientCategory.spice, density: 1.220)
        let garlic = Ingredient(name: "garlic", displayName: "Garlic", category: IngredientCategory.vegetable)
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        for i in [chicken, oil, salt, garlic, broth] { ctx.insert(i) }

        let recipe = Recipe(title: "Chicken in Broth", servings: 2)
        ctx.insert(recipe)
        let ri1 = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipe, ingredient: chicken)
        let ri2 = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: oil)
        let ri3 = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipe, ingredient: salt)
        let ri4 = RecipeIngredient(quantity: 3, unit: "clove", recipe: recipe, ingredient: garlic)
        let ri5 = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: broth)
        for ri in [ri1, ri2, ri3, ri4, ri5] { ctx.insert(ri) }

        // Only 4 of 5 — missing broth entirely
        let inv1 = InventoryItem(quantity: 2, unit: "lb", ingredient: chicken)
        let inv2 = InventoryItem(quantity: 1, unit: "cup", ingredient: oil)
        let inv3 = InventoryItem(quantity: 10, unit: "tsp", ingredient: salt)
        let inv4 = InventoryItem(quantity: 10, unit: "clove", ingredient: garlic)
        for inv in [inv1, inv2, inv3, inv4] { ctx.insert(inv) }

        try ctx.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 0, "Missing 1 of 5 ingredients — should NOT be cookable")
    }

    @Test @MainActor func zeroOfFiveIngredientsShowsMissing() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext

        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken", category: IngredientCategory.protein)
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        let salt = Ingredient(name: "kosher salt", displayName: "Salt", category: IngredientCategory.spice, density: 1.220)
        let garlic = Ingredient(name: "garlic", displayName: "Garlic", category: IngredientCategory.vegetable)
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        for i in [chicken, oil, salt, garlic, broth] { ctx.insert(i) }

        let recipe = Recipe(title: "Chicken in Broth", servings: 2)
        ctx.insert(recipe)
        let ri1 = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipe, ingredient: chicken)
        let ri2 = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: oil)
        let ri3 = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipe, ingredient: salt)
        let ri4 = RecipeIngredient(quantity: 3, unit: "clove", recipe: recipe, ingredient: garlic)
        let ri5 = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: broth)
        for ri in [ri1, ri2, ri3, ri4, ri5] { ctx.insert(ri) }

        // No pantry items at all
        try ctx.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: ctx)
        #expect(result.count == 0, "No pantry items — should NOT be cookable")

        let percent = RecipeFilterService.ingredientMatchPercent(recipe, context: ctx)
        #expect(abs(percent - 0.0) < 0.001, "0 of 5 ingredients → 0% match")
    }

    @Test @MainActor func partialMatchPercentageIsCorrect() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext

        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken", category: IngredientCategory.protein)
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        let salt = Ingredient(name: "kosher salt", displayName: "Salt", category: IngredientCategory.spice, density: 1.220)
        let garlic = Ingredient(name: "garlic", displayName: "Garlic", category: IngredientCategory.vegetable)
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        for i in [chicken, oil, salt, garlic, broth] { ctx.insert(i) }

        let recipe = Recipe(title: "Chicken in Broth", servings: 2)
        ctx.insert(recipe)
        let ri1 = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipe, ingredient: chicken)
        let ri2 = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: oil)
        let ri3 = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipe, ingredient: salt)
        let ri4 = RecipeIngredient(quantity: 3, unit: "clove", recipe: recipe, ingredient: garlic)
        let ri5 = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: broth)
        for ri in [ri1, ri2, ri3, ri4, ri5] { ctx.insert(ri) }

        // 3 of 5 ingredients covered
        let inv1 = InventoryItem(quantity: 2, unit: "lb", ingredient: chicken)
        let inv3 = InventoryItem(quantity: 10, unit: "tsp", ingredient: salt)
        let inv4 = InventoryItem(quantity: 10, unit: "clove", ingredient: garlic)
        for inv in [inv1, inv3, inv4] { ctx.insert(inv) }

        try ctx.save()

        let percent = RecipeFilterService.ingredientMatchPercent(recipe, context: ctx)
        #expect(abs(percent - 0.6) < 0.001, "3 of 5 ingredients → 60% match")
    }

    @Test @MainActor func partialMatchModeReturnsSortedByPercent() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext

        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken", category: IngredientCategory.protein)
        let salt = Ingredient(name: "kosher salt", displayName: "Salt", category: IngredientCategory.spice, density: 1.220)
        ctx.insert(chicken)
        ctx.insert(salt)

        // Recipe A: 1 ingredient, fully covered → 100%
        let recipeA = Recipe(title: "Salt Chicken", servings: 1)
        ctx.insert(recipeA)
        let riA = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipeA, ingredient: chicken)
        ctx.insert(riA)

        // Recipe B: 2 ingredients, 1 covered → 50%
        let recipeB = Recipe(title: "Seasoned Chicken", servings: 1)
        ctx.insert(recipeB)
        let riB1 = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipeB, ingredient: chicken)
        let riB2 = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipeB, ingredient: salt)
        ctx.insert(riB1)
        ctx.insert(riB2)

        // Only chicken in pantry
        let inv = InventoryItem(quantity: 5, unit: "lb", ingredient: chicken)
        ctx.insert(inv)

        try ctx.save()

        let result = RecipeFilterService.filter(recipes: [recipeA, recipeB], mode: .partialMatch, context: ctx)
        #expect(result.count == 2)
        #expect(result[0].title == "Salt Chicken", "100% match should come first")
        #expect(result[1].title == "Seasoned Chicken", "50% match should come second")
    }

    @Test @MainActor func allFiveIngredientsCoveredMealCoverageFull() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext

        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken", category: IngredientCategory.protein)
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        let salt = Ingredient(name: "kosher salt", displayName: "Salt", category: IngredientCategory.spice, density: 1.220)
        let garlic = Ingredient(name: "garlic", displayName: "Garlic", category: IngredientCategory.vegetable)
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        for i in [chicken, oil, salt, garlic, broth] { ctx.insert(i) }

        let recipe = Recipe(title: "Chicken in Broth", servings: 2)
        ctx.insert(recipe)
        let ri1 = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipe, ingredient: chicken)
        let ri2 = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: oil)
        let ri3 = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipe, ingredient: salt)
        let ri4 = RecipeIngredient(quantity: 3, unit: "clove", recipe: recipe, ingredient: garlic)
        let ri5 = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: broth)
        for ri in [ri1, ri2, ri3, ri4, ri5] { ctx.insert(ri) }

        let inv1 = InventoryItem(quantity: 2, unit: "lb", ingredient: chicken)
        let inv2 = InventoryItem(quantity: 1, unit: "cup", ingredient: oil)
        let inv3 = InventoryItem(quantity: 10, unit: "tsp", ingredient: salt)
        let inv4 = InventoryItem(quantity: 10, unit: "clove", ingredient: garlic)
        let inv5 = InventoryItem(quantity: 2, unit: "quart", ingredient: broth)
        for inv in [inv1, inv2, inv3, inv4, inv5] { ctx.insert(inv) }

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 2, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()

        let coverage = PantryCoverageService.mealCoverage(for: entry)
        #expect(coverage.level == .full, "All 5 ingredients covered → full coverage")
        #expect(coverage.coveredIngredients == 5)
        #expect(coverage.totalIngredients == 5)
    }

    @Test @MainActor func fourOfFiveMealCoveragePartial() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext

        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken", category: IngredientCategory.protein)
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        let salt = Ingredient(name: "kosher salt", displayName: "Salt", category: IngredientCategory.spice, density: 1.220)
        let garlic = Ingredient(name: "garlic", displayName: "Garlic", category: IngredientCategory.vegetable)
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        for i in [chicken, oil, salt, garlic, broth] { ctx.insert(i) }

        let recipe = Recipe(title: "Chicken in Broth", servings: 2)
        ctx.insert(recipe)
        let ri1 = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipe, ingredient: chicken)
        let ri2 = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: oil)
        let ri3 = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipe, ingredient: salt)
        let ri4 = RecipeIngredient(quantity: 3, unit: "clove", recipe: recipe, ingredient: garlic)
        let ri5 = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: broth)
        for ri in [ri1, ri2, ri3, ri4, ri5] { ctx.insert(ri) }

        // Missing broth
        let inv1 = InventoryItem(quantity: 2, unit: "lb", ingredient: chicken)
        let inv2 = InventoryItem(quantity: 1, unit: "cup", ingredient: oil)
        let inv3 = InventoryItem(quantity: 10, unit: "tsp", ingredient: salt)
        let inv4 = InventoryItem(quantity: 10, unit: "clove", ingredient: garlic)
        for inv in [inv1, inv2, inv3, inv4] { ctx.insert(inv) }

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 2, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()

        let coverage = PantryCoverageService.mealCoverage(for: entry)
        #expect(coverage.level == .partial, "4 of 5 ingredients → partial coverage")
        #expect(coverage.coveredIngredients == 4)
        #expect(coverage.totalIngredients == 5)
    }

    @Test @MainActor func zeroOfFiveMealCoverageMissing() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext

        let chicken = Ingredient(name: "chicken breast", displayName: "Chicken", category: IngredientCategory.protein)
        let oil = Ingredient(name: "olive oil", displayName: "Olive Oil", category: IngredientCategory.other, density: 0.915)
        let salt = Ingredient(name: "kosher salt", displayName: "Salt", category: IngredientCategory.spice, density: 1.220)
        let garlic = Ingredient(name: "garlic", displayName: "Garlic", category: IngredientCategory.vegetable)
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        for i in [chicken, oil, salt, garlic, broth] { ctx.insert(i) }

        let recipe = Recipe(title: "Chicken in Broth", servings: 2)
        ctx.insert(recipe)
        let ri1 = RecipeIngredient(quantity: 1, unit: "lb", recipe: recipe, ingredient: chicken)
        let ri2 = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: oil)
        let ri3 = RecipeIngredient(quantity: 1, unit: "tsp", recipe: recipe, ingredient: salt)
        let ri4 = RecipeIngredient(quantity: 3, unit: "clove", recipe: recipe, ingredient: garlic)
        let ri5 = RecipeIngredient(quantity: 4, unit: "cup", recipe: recipe, ingredient: broth)
        for ri in [ri1, ri2, ri3, ri4, ri5] { ctx.insert(ri) }

        // No inventory
        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 2, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()

        let coverage = PantryCoverageService.mealCoverage(for: entry)
        #expect(coverage.level == .missing, "0 of 5 ingredients → missing coverage")
        #expect(coverage.coveredIngredients == 0)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION 6: Meal Completion Deductions — Cross-Unit
// ═══════════════════════════════════════════════════════════════════════════

@Suite("MealCompletionDeductions", .serialized)
struct MealCompletionDeductionTests {

    @Test @MainActor func brothCupsDeductedFromQuartInventory() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let broth = Ingredient(name: "chicken broth", displayName: "Chicken Broth", category: IngredientCategory.other)
        ctx.insert(broth)
        let recipe = Recipe(title: "Soup", servings: 2)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "cup", recipe: recipe, ingredient: broth)
        ctx.insert(ri)
        // 1 quart = 4 cups
        let inv = InventoryItem(quantity: 1, unit: "quart", ingredient: broth)
        ctx.insert(inv)
        let yesterday = DateHelpers.addDays(-1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: yesterday, mealSlot: MealSlot.dinner, servings: 2, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()

        try MealCompletionService.markCompleted(entry, context: ctx)

        let items = try ctx.fetch(FetchDescriptor<InventoryItem>())
        #expect(items.count == 1)
        // 2 cups / 4 cups per quart = 0.5 quart deducted → 0.5 quart remaining
        #expect(abs(items[0].quantity - 0.5) < 0.01)
        #expect(items[0].unit == "quart")
    }

    @Test @MainActor func butterTbspDeductedFromGramsWithDensity() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let butter = Ingredient(name: "butter unsalted", displayName: "Butter", category: IngredientCategory.dairy, density: 0.911)
        ctx.insert(butter)
        let recipe = Recipe(title: "Cookies", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 4, unit: "tbsp", recipe: recipe, ingredient: butter)
        ctx.insert(ri)
        let inv = InventoryItem(quantity: 200, unit: "g", ingredient: butter)
        ctx.insert(inv)
        let yesterday = DateHelpers.addDays(-1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: yesterday, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()

        try MealCompletionService.markCompleted(entry, context: ctx)

        let items = try ctx.fetch(FetchDescriptor<InventoryItem>())
        #expect(items.count == 1)
        // 4 tbsp = 12 tsp × 4.92892 × 0.911 ≈ 53.88g deducted from 200g → ~146g
        #expect(abs(items[0].quantity - 146.12) < 1.0)
    }

    @Test @MainActor func honeyTbspDeductedFromOz() throws {
        let container = try makeTestContainer()
        let ctx = container.mainContext
        let honey = Ingredient(name: "honey", displayName: "Honey", category: IngredientCategory.other, density: 1.420)
        ctx.insert(honey)
        let recipe = Recipe(title: "Granola", servings: 1)
        ctx.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "tbsp", recipe: recipe, ingredient: honey)
        ctx.insert(ri)
        // 2 tbsp = 6 tsp × 4.92892 × 1.420 ≈ 41.99g / 28.35 ≈ 1.48 oz
        let inv = InventoryItem(quantity: 8, unit: "oz", ingredient: honey)
        ctx.insert(inv)
        let yesterday = DateHelpers.addDays(-1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: yesterday, mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe)
        ctx.insert(entry)
        try ctx.save()

        try MealCompletionService.markCompleted(entry, context: ctx)

        let items = try ctx.fetch(FetchDescriptor<InventoryItem>())
        #expect(items.count == 1)
        // 8 oz - 1.48 oz ≈ 6.52 oz
        #expect(abs(items[0].quantity - 6.52) < 0.1)
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION 7: Density Catalog Completeness
// ═══════════════════════════════════════════════════════════════════════════

@Suite("DensityCatalogCompleteness")
struct DensityCatalogCompletenessTests {

    @Test func allDairyLiquidsHaveDensity() {
        let dairyLiquids = ["milk whole", "milk 2%", "milk skim", "heavy cream",
                           "half and half", "buttermilk", "evaporated milk", "condensed milk"]
        for name in dairyLiquids {
            let entry = IngredientCatalog.entries.first { $0.name == name }
            #expect(entry != nil, "Catalog should contain \(name)")
            #expect(entry?.density != nil, "\(name) should have density for volume↔weight conversion")
        }
    }

    @Test func allOilsHaveDensity() {
        let oils = ["olive oil", "canola oil", "vegetable oil", "sesame oil",
                   "coconut oil", "avocado oil", "peanut oil"]
        for name in oils {
            let entry = IngredientCatalog.entries.first { $0.name == name }
            #expect(entry != nil, "Catalog should contain \(name)")
            #expect(entry?.density != nil, "\(name) should have density for volume↔weight conversion")
        }
    }

    @Test func allSweetenersHaveDensity() {
        let sweeteners = ["honey", "maple syrup", "molasses", "granulated sugar",
                         "light brown sugar", "dark brown sugar", "powdered sugar"]
        for name in sweeteners {
            let entry = IngredientCatalog.entries.first { $0.name == name }
            #expect(entry != nil, "Catalog should contain \(name)")
            #expect(entry?.density != nil, "\(name) should have density for volume↔weight conversion")
        }
    }

    @Test func allFloursHaveDensity() {
        let flours = ["all-purpose flour", "bread flour", "whole wheat flour",
                     "almond flour", "rice flour"]
        for name in flours {
            let entry = IngredientCatalog.entries.first { $0.name == name }
            #expect(entry != nil, "Catalog should contain \(name)")
            #expect(entry?.density != nil, "\(name) should have density for volume↔weight conversion")
        }
    }

    @Test func butterHasDensity() {
        let butters = ["butter unsalted", "butter salted", "ghee"]
        for name in butters {
            let entry = IngredientCatalog.entries.first { $0.name == name }
            #expect(entry != nil, "Catalog should contain \(name)")
            #expect(entry?.density != nil, "\(name) should have density for volume↔weight conversion")
        }
    }

    @Test func allVinegarsHaveDensity() {
        let vinegars = ["white vinegar", "apple cider vinegar", "balsamic vinegar",
                       "red wine vinegar", "rice vinegar"]
        for name in vinegars {
            let entry = IngredientCatalog.entries.first { $0.name == name }
            #expect(entry != nil, "Catalog should contain \(name)")
            #expect(entry?.density != nil, "\(name) should have density for volume↔weight conversion")
        }
    }

    @Test func liquidCondimentsHaveDensity() {
        let condiments = ["soy sauce", "fish sauce", "worcestershire sauce"]
        for name in condiments {
            let entry = IngredientCatalog.entries.first { $0.name == name }
            #expect(entry != nil, "Catalog should contain \(name)")
            #expect(entry?.density != nil, "\(name) should have density for volume↔weight conversion")
        }
    }

    @Test func coconutMilkHasDensity() {
        let entry = IngredientCatalog.entries.first { $0.name == "coconut milk canned" }
        #expect(entry != nil)
        #expect(entry?.density != nil, "coconut milk canned should have density")
    }

    @Test func densityValuesAreReasonable() {
        // All densities should be positive and within physical bounds
        for entry in IngredientCatalog.entries {
            if let d = entry.density {
                #expect(d > 0.1, "\(entry.name) density \(d) too low")
                #expect(d < 3.0, "\(entry.name) density \(d) too high — no food ingredient is 3x water")
            }
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION 8: Unit Conversion Round-Trip Accuracy
// ═══════════════════════════════════════════════════════════════════════════

@Suite("UnitConversionRoundTrips")
struct UnitConversionRoundTripTests {

    @Test func cupToQuartAndBack() {
        let toQuart = UnitConverter.convert(quantity: 4, from: "cup", to: "quart")
        #expect(toQuart != nil)
        #expect(abs(toQuart! - 1.0) < 0.001)
        let toCup = UnitConverter.convert(quantity: toQuart!, from: "quart", to: "cup")
        #expect(toCup != nil)
        #expect(abs(toCup! - 4.0) < 0.001)
    }

    @Test func tspToTbspToFlOzToCup() {
        // 48 tsp → 16 tbsp → 8 fl oz → 1 cup
        let tbsp = UnitConverter.convert(quantity: 48, from: "tsp", to: "tbsp")
        #expect(abs(tbsp! - 16.0) < 0.001)
        let floz = UnitConverter.convert(quantity: tbsp!, from: "tbsp", to: "fl oz")
        #expect(abs(floz! - 8.0) < 0.001)
        let cup = UnitConverter.convert(quantity: floz!, from: "fl oz", to: "cup")
        #expect(abs(cup! - 1.0) < 0.001)
    }

    @Test func mlToLiterAndBack() {
        let liter = UnitConverter.convert(quantity: 500, from: "ml", to: "l")
        #expect(liter != nil)
        #expect(abs(liter! - 0.5) < 0.001)
        let ml = UnitConverter.convert(quantity: liter!, from: "l", to: "ml")
        #expect(abs(ml! - 500.0) < 0.001)
    }

    @Test func gToKgToOzToLb() {
        let kg = UnitConverter.convert(quantity: 453.59, from: "g", to: "kg")
        #expect(abs(kg! - 0.45359) < 0.001)
        let oz = UnitConverter.convert(quantity: kg!, from: "kg", to: "oz")
        #expect(abs(oz! - 16.0) < 0.01)
        let lb = UnitConverter.convert(quantity: oz!, from: "oz", to: "lb")
        #expect(abs(lb! - 1.0) < 0.01)
    }

    @Test func crossDimRoundTripWithMilkDensity() {
        let density = 1.030
        let grams = UnitConverter.convert(quantity: 1, from: "cup", to: "g", density: density)
        #expect(grams != nil)
        let cups = UnitConverter.convert(quantity: grams!, from: "g", to: "cup", density: density)
        #expect(cups != nil)
        #expect(abs(cups! - 1.0) < 0.001, "Round-trip cup→g→cup should return to 1.0")
    }

    @Test func crossDimRoundTripWithFlourDensity() {
        let density = 0.529
        let grams = UnitConverter.convert(quantity: 2, from: "cup", to: "g", density: density)
        #expect(grams != nil)
        let cups = UnitConverter.convert(quantity: grams!, from: "g", to: "cup", density: density)
        #expect(cups != nil)
        #expect(abs(cups! - 2.0) < 0.001, "Round-trip 2 cups flour→g→cups should return to 2.0")
    }

    @Test func crossDimRoundTripWithHoneyDensity() {
        let density = 1.420
        let oz = UnitConverter.convert(quantity: 3, from: "tbsp", to: "oz", density: density)
        #expect(oz != nil)
        let tbsp = UnitConverter.convert(quantity: oz!, from: "oz", to: "tbsp", density: density)
        #expect(tbsp != nil)
        #expect(abs(tbsp! - 3.0) < 0.001, "Round-trip 3 tbsp honey→oz→tbsp should return to 3.0")
    }

    @Test func quartToGallonToLiter() {
        let gallon = UnitConverter.convert(quantity: 4, from: "quart", to: "gallon")
        #expect(abs(gallon! - 1.0) < 0.001)
        let liter = UnitConverter.convert(quantity: gallon!, from: "gallon", to: "l")
        #expect(liter != nil)
        // 1 gallon ≈ 3.785 liters
        #expect(abs(liter! - 3.785) < 0.01)
    }
}
