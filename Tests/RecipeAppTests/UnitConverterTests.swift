import Testing
import SwiftData
import Foundation
@testable import RecipeApp

// MARK: - UnitConverter unit tests

@Suite("UnitConverter")
struct UnitConverterTests {

    // MARK: Normalization

    @Test func normalizesTablespoonVariants() {
        #expect(UnitConverter.normalize("tbsp") == "tbsp")
        #expect(UnitConverter.normalize("TBSP") == "tbsp")
        #expect(UnitConverter.normalize("Tbsp") == "tbsp")
        #expect(UnitConverter.normalize("tablespoon") == "tbsp")
        #expect(UnitConverter.normalize("Tablespoon") == "tbsp")
        #expect(UnitConverter.normalize("tablespoons") == "tbsp")
        #expect(UnitConverter.normalize("TABLESPOONS") == "tbsp")
        #expect(UnitConverter.normalize("tbs") == "tbsp")
        #expect(UnitConverter.normalize("TBS") == "tbsp")
    }

    @Test func normalizesCupVariants() {
        #expect(UnitConverter.normalize("cup") == "cup")
        #expect(UnitConverter.normalize("cups") == "cup")
        #expect(UnitConverter.normalize("Cup") == "cup")
        #expect(UnitConverter.normalize("CUPS") == "cup")
        #expect(UnitConverter.normalize("c") == "cup")
        #expect(UnitConverter.normalize("C") == "cup")
    }

    @Test func normalizesOunceVariants() {
        // Weight oz (default)
        #expect(UnitConverter.normalize("oz") == "oz")
        #expect(UnitConverter.normalize("OZ") == "oz")
        #expect(UnitConverter.normalize("Oz") == "oz")
        #expect(UnitConverter.normalize("ounce") == "oz")
        #expect(UnitConverter.normalize("ounces") == "oz")
        // Fluid oz
        #expect(UnitConverter.normalize("fl oz") == "fl oz")
        #expect(UnitConverter.normalize("FL OZ") == "fl oz")
        #expect(UnitConverter.normalize("fluid oz") == "fl oz")
        #expect(UnitConverter.normalize("fluid ounce") == "fl oz")
        #expect(UnitConverter.normalize("fluid ounces") == "fl oz")
    }

    @Test func normalizesGallonVariants() {
        #expect(UnitConverter.normalize("gallon") == "gallon")
        #expect(UnitConverter.normalize("gallons") == "gallon")
        #expect(UnitConverter.normalize("GALLON") == "gallon")
        #expect(UnitConverter.normalize("gal") == "gallon")
        #expect(UnitConverter.normalize("GAL") == "gallon")
    }

    @Test func normalizesTeaspoonVariants() {
        #expect(UnitConverter.normalize("tsp") == "tsp")
        #expect(UnitConverter.normalize("TSP") == "tsp")
        #expect(UnitConverter.normalize("teaspoon") == "tsp")
        #expect(UnitConverter.normalize("teaspoons") == "tsp")
        #expect(UnitConverter.normalize("Teaspoon") == "tsp")
    }

    @Test func normalizesWeightVariants() {
        #expect(UnitConverter.normalize("g") == "g")
        #expect(UnitConverter.normalize("gram") == "g")
        #expect(UnitConverter.normalize("grams") == "g")
        #expect(UnitConverter.normalize("kg") == "kg")
        #expect(UnitConverter.normalize("kilogram") == "kg")
        #expect(UnitConverter.normalize("kilograms") == "kg")
        #expect(UnitConverter.normalize("lb") == "lb")
        #expect(UnitConverter.normalize("lbs") == "lb")
        #expect(UnitConverter.normalize("pound") == "lb")
        #expect(UnitConverter.normalize("pounds") == "lb")
    }

    @Test func normalizesCountVariants() {
        #expect(UnitConverter.normalize("large") == "large")
        #expect(UnitConverter.normalize("LARGE") == "large")
        #expect(UnitConverter.normalize("medium") == "medium")
        #expect(UnitConverter.normalize("MEDIUM") == "medium")
        #expect(UnitConverter.normalize("clove") == "clove")
        #expect(UnitConverter.normalize("cloves") == "clove")
        #expect(UnitConverter.normalize("each") == "each")
        #expect(UnitConverter.normalize("pieces") == "each")
        #expect(UnitConverter.normalize("whole") == "each")
    }

    @Test func unknownUnitReturnsTrimmedLowercase() {
        #expect(UnitConverter.normalize("pinch") == "pinch")
        #expect(UnitConverter.normalize("  Pinch  ") == "pinch")
    }

    // MARK: Dimension detection

    @Test func detectsVolumeDimension() {
        #expect(UnitConverter.dimension(of: "tsp") == .volume)
        #expect(UnitConverter.dimension(of: "TBSP") == .volume)
        #expect(UnitConverter.dimension(of: "cups") == .volume)
        #expect(UnitConverter.dimension(of: "fluid ounces") == .volume)
        #expect(UnitConverter.dimension(of: "gallon") == .volume)
        #expect(UnitConverter.dimension(of: "ml") == .volume)
        #expect(UnitConverter.dimension(of: "l") == .volume)
    }

    @Test func detectsWeightDimension() {
        #expect(UnitConverter.dimension(of: "g") == .weight)
        #expect(UnitConverter.dimension(of: "kg") == .weight)
        #expect(UnitConverter.dimension(of: "oz") == .weight)
        #expect(UnitConverter.dimension(of: "lbs") == .weight)
    }

    @Test func detectsCountDimension() {
        #expect(UnitConverter.dimension(of: "large") == .count)
        #expect(UnitConverter.dimension(of: "medium") == .count)
        #expect(UnitConverter.dimension(of: "cloves") == .count)
        #expect(UnitConverter.dimension(of: "each") == .count)
    }

    @Test func detectsOtherDimension() {
        #expect(UnitConverter.dimension(of: "pinch") == .other)
        #expect(UnitConverter.dimension(of: "dash") == .other)
    }

    // MARK: Aggregation keys

    @Test func volumeUnitsShareAggregationKey() {
        let keys = ["tsp", "TBSP", "cups", "gallon", "ml", "fl oz"].map {
            UnitConverter.aggregationKey(for: $0)
        }
        #expect(Set(keys) == ["volume"])
    }

    @Test func weightUnitsShareAggregationKey() {
        let keys = ["g", "kg", "oz", "pounds"].map {
            UnitConverter.aggregationKey(for: $0)
        }
        #expect(Set(keys) == ["weight"])
    }

    @Test func countUnitsHaveDistinctAggregationKeys() {
        let keyLarge = UnitConverter.aggregationKey(for: "large")
        let keyMedium = UnitConverter.aggregationKey(for: "medium")
        let keyClove = UnitConverter.aggregationKey(for: "cloves")
        #expect(keyLarge != keyMedium)
        #expect(keyLarge != keyClove)
        // All normalized: large/medium/clove remain themselves
        #expect(keyLarge == "large")
        #expect(keyMedium == "medium")
        #expect(keyClove == "clove")
    }

    // MARK: Base unit conversion

    @Test func volumeToBaseUnit() {
        // 1 tbsp = 3 tsp
        let base = UnitConverter.toBaseUnit(quantity: 1, unit: "tbsp")
        #expect(base == 3.0)

        // 1 cup = 48 tsp
        let cup = UnitConverter.toBaseUnit(quantity: 1, unit: "cup")
        #expect(cup == 48.0)

        // 1 gallon = 768 tsp
        let gallon = UnitConverter.toBaseUnit(quantity: 1, unit: "gallon")
        #expect(gallon == 768.0)
    }

    @Test func weightToBaseUnit() {
        // 1 kg = 1000 g
        let kg = UnitConverter.toBaseUnit(quantity: 1, unit: "kg")
        #expect(kg == 1000.0)

        // 1 lb = 453.59237 g
        let lb = UnitConverter.toBaseUnit(quantity: 1, unit: "lb")
        #expect(abs(lb! - 453.592) < 0.01)
    }

    @Test func countUnitReturnsNil() {
        #expect(UnitConverter.toBaseUnit(quantity: 3, unit: "large") == nil)
        #expect(UnitConverter.toBaseUnit(quantity: 1, unit: "clove") == nil)
    }

    @Test func unknownUnitReturnsNil() {
        #expect(UnitConverter.toBaseUnit(quantity: 1, unit: "pinch") == nil)
    }

    // MARK: Cross-unit conversion

    @Test func convertsTbspToCups() {
        // 16 tbsp = 1 cup
        let result = UnitConverter.convert(quantity: 16, from: "tbsp", to: "cup")
        #expect(result != nil)
        #expect(abs(result! - 1.0) < 0.001)
    }

    @Test func convertsCupsToTbsp() {
        // 1 cup = 16 tbsp
        let result = UnitConverter.convert(quantity: 1, from: "cup", to: "tbsp")
        #expect(result != nil)
        #expect(abs(result! - 16.0) < 0.001)
    }

    @Test func convertsTspToTbsp() {
        // 3 tsp = 1 tbsp
        let result = UnitConverter.convert(quantity: 3, from: "tsp", to: "tbsp")
        #expect(result != nil)
        #expect(abs(result! - 1.0) < 0.001)
    }

    @Test func convertsCaseSensitive() {
        // Case-insensitive input
        let result = UnitConverter.convert(quantity: 1, from: "TBSP", to: "Cups")
        #expect(result != nil)
        #expect(abs(result! - (1.0 / 16.0)) < 0.001)
    }

    @Test func convertsGramsToKg() {
        let result = UnitConverter.convert(quantity: 1000, from: "g", to: "kg")
        #expect(result != nil)
        #expect(abs(result! - 1.0) < 0.001)
    }

    @Test func convertsOzToLb() {
        // 16 oz = 1 lb
        let result = UnitConverter.convert(quantity: 16, from: "oz", to: "lb")
        #expect(result != nil)
        #expect(abs(result! - 1.0) < 0.01)
    }

    @Test func incompatibleDimensionsReturnNil() {
        // Volume ↔ Weight: not convertible
        #expect(UnitConverter.convert(quantity: 1, from: "cup", to: "g") == nil)
        #expect(UnitConverter.convert(quantity: 100, from: "g", to: "tbsp") == nil)
        // Count ↔ Volume: not convertible
        #expect(UnitConverter.convert(quantity: 1, from: "large", to: "cup") == nil)
    }

    // MARK: Compatibility check

    @Test func volumeUnitsAreCompatible() {
        #expect(UnitConverter.areCompatible("tbsp", "cup") == true)
        #expect(UnitConverter.areCompatible("CUPS", "gallon") == true)
        #expect(UnitConverter.areCompatible("teaspoons", "tablespoon") == true)
        #expect(UnitConverter.areCompatible("ml", "l") == true)
    }

    @Test func weightUnitsAreCompatible() {
        #expect(UnitConverter.areCompatible("g", "kg") == true)
        #expect(UnitConverter.areCompatible("oz", "lb") == true)
        #expect(UnitConverter.areCompatible("grams", "pounds") == true)
    }

    @Test func crossDimensionUnitsAreNotCompatible() {
        #expect(UnitConverter.areCompatible("cup", "g") == false)
        #expect(UnitConverter.areCompatible("oz", "fl oz") == false)  // weight vs volume
        #expect(UnitConverter.areCompatible("large", "cup") == false)
        #expect(UnitConverter.areCompatible("tbsp", "lb") == false)
    }

    // MARK: Density-aware cross-dimension conversion

    @Test func convertsCupToGramsWithDensity() {
        // 1 cup flour (density 0.529 g/ml):
        // 1 cup = 48 tsp × 4.92892 ml/tsp = 236.59 ml × 0.529 g/ml ≈ 125.1 g
        let result = UnitConverter.convert(quantity: 1, from: "cup", to: "g", density: 0.529)
        #expect(result != nil)
        #expect(abs(result! - 125.1) < 1.0)
    }

    @Test func convertsGramsToCupWithDensity() {
        // 125 g flour (density 0.529 g/ml) ≈ 1 cup (round-trip)
        let result = UnitConverter.convert(quantity: 125, from: "g", to: "cup", density: 0.529)
        #expect(result != nil)
        #expect(abs(result! - 1.0) < 0.05)
    }

    @Test func convertsTbspToOzWithDensity() {
        // 1 tbsp butter (density 0.911 g/ml):
        // 3 tsp × 4.92892 ml/tsp = 14.787 ml × 0.911 = 13.471 g / 28.34952 g/oz ≈ 0.475 oz
        let result = UnitConverter.convert(quantity: 1, from: "tbsp", to: "oz", density: 0.911)
        #expect(result != nil)
        #expect(abs(result! - 0.475) < 0.01)
    }

    @Test func crossDimConvertWithNilDensityReturnsNil() {
        // No density → cross-dimension still returns nil (same as before)
        #expect(UnitConverter.convert(quantity: 1, from: "cup", to: "g", density: nil) == nil)
        #expect(UnitConverter.convert(quantity: 100, from: "g", to: "tbsp", density: nil) == nil)
    }

    @Test func crossDimConvertWithNonPositiveDensityReturnsNil() {
        #expect(UnitConverter.convert(quantity: 1, from: "cup", to: "g", density: 0) == nil)
        #expect(UnitConverter.convert(quantity: 100, from: "g", to: "tbsp", density: -0.5) == nil)
    }

    @Test func crossDimConvertWithNonFiniteDensityReturnsNil() {
        #expect(UnitConverter.convert(quantity: 1, from: "cup", to: "g", density: .infinity) == nil)
        #expect(UnitConverter.convert(quantity: 100, from: "g", to: "tbsp", density: -.infinity) == nil)
        #expect(UnitConverter.convert(quantity: 2, from: "tbsp", to: "oz", density: .nan) == nil)
    }

    @Test func crossDimConvertRoundTrip() {
        // Convert 1 cup honey → g → back to cup; should recover ≈ 1 cup
        let density = 1.420
        let grams = UnitConverter.convert(quantity: 1, from: "cup", to: "g", density: density)
        #expect(grams != nil)
        let cups = UnitConverter.convert(quantity: grams!, from: "g", to: "cup", density: density)
        #expect(cups != nil)
        #expect(abs(cups! - 1.0) < 0.001)
    }

    @Test func areCompatibleCrossDimWithDensity() {
        #expect(UnitConverter.areCompatible("cup", "g", density: 0.529) == true)
        #expect(UnitConverter.areCompatible("oz", "cup", density: 0.911) == true)
        #expect(UnitConverter.areCompatible("tbsp", "oz", density: 0.900) == true)
    }

    @Test func areCompatibleCrossDimWithoutDensityReturnsFalse() {
        // Existing behaviour preserved with nil density
        #expect(UnitConverter.areCompatible("cup", "g", density: nil) == false)
        #expect(UnitConverter.areCompatible("oz", "fl oz", density: nil) == false)
    }

    @Test func areCompatibleCrossDimWithInvalidDensityReturnsFalse() {
        #expect(UnitConverter.areCompatible("cup", "g", density: 0) == false)
        #expect(UnitConverter.areCompatible("cup", "g", density: -1.0) == false)
        #expect(UnitConverter.areCompatible("cup", "g", density: .infinity) == false)
        #expect(UnitConverter.areCompatible("cup", "g", density: .nan) == false)
    }

    // MARK: Pretty display

    @Test func prettyDisplayVolume() {
        // < 3 tsp → tsp
        let (qty1, unit1) = UnitConverter.prettyDisplay(baseQuantity: 1.0, dimension: .volume)
        #expect(unit1 == "tsp")
        #expect(abs(qty1 - 1.0) < 0.001)

        // 3-47 tsp → tbsp (e.g. 6 tsp = 2 tbsp)
        let (qty2, unit2) = UnitConverter.prettyDisplay(baseQuantity: 6.0, dimension: .volume)
        #expect(unit2 == "tbsp")
        #expect(abs(qty2 - 2.0) < 0.001)

        // 48+ tsp → cups (e.g. 96 tsp = 2 cups)
        let (qty3, unit3) = UnitConverter.prettyDisplay(baseQuantity: 96.0, dimension: .volume)
        #expect(unit3 == "cup")
        #expect(abs(qty3 - 2.0) < 0.001)

        // 768+ tsp → gallons (e.g. 1536 tsp = 2 gallons)
        let (qty4, unit4) = UnitConverter.prettyDisplay(baseQuantity: 1536.0, dimension: .volume)
        #expect(unit4 == "gallon")
        #expect(abs(qty4 - 2.0) < 0.001)
    }

    @Test func prettyDisplayWeight() {
        // < 1000 g → g
        let (qty1, unit1) = UnitConverter.prettyDisplay(baseQuantity: 500.0, dimension: .weight)
        #expect(unit1 == "g")
        #expect(abs(qty1 - 500.0) < 0.001)

        // ≥ 1000 g → kg
        let (qty2, unit2) = UnitConverter.prettyDisplay(baseQuantity: 2000.0, dimension: .weight)
        #expect(unit2 == "kg")
        #expect(abs(qty2 - 2.0) < 0.001)
    }
}

// MARK: - Integration tests: ShoppingListGenerator with unit conversion

@Suite("ShoppingListGenerator.UnitConversion", .serialized)
struct ShoppingListGeneratorUnitConversionTests {

    @Test @MainActor func aggregatesCompatibleVolumeUnits() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour", displayName: "Flour", category: IngredientCategory.grain)
        context.insert(flour)

        // Recipe 1 needs 1 cup flour
        let recipe1 = Recipe(title: "Cake", servings: 1)
        context.insert(recipe1)
        let ri1 = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe1, ingredient: flour)
        context.insert(ri1)

        // Recipe 2 needs 4 tbsp flour (= 1/4 cup = 12 tsp)
        let recipe2 = Recipe(title: "Cookies", servings: 1)
        context.insert(recipe2)
        let ri2 = RecipeIngredient(quantity: 4, unit: "tbsp", recipe: recipe2, ingredient: flour)
        context.insert(ri2)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry1 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.lunch, servings: 1, recipe: recipe1)
        let entry2 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe2)
        context.insert(entry1)
        context.insert(entry2)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        // Should aggregate into a single item (1 cup + 4 tbsp = 1.25 cups)
        #expect(items.count == 1)
        #expect(items[0].unit == "cup")
        // 1 cup + 4 tbsp = 48 tsp + 12 tsp = 60 tsp = 1.25 cups
        #expect(abs(items[0].quantity - 1.25) < 0.01)
    }

    @Test @MainActor func aggregatesCompatibleWeightUnits() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let chicken = Ingredient(name: "chicken", displayName: "Chicken", category: IngredientCategory.protein)
        context.insert(chicken)

        // Recipe 1 needs 500 g chicken
        let recipe1 = Recipe(title: "Grilled Chicken", servings: 1)
        context.insert(recipe1)
        let ri1 = RecipeIngredient(quantity: 500, unit: "g", recipe: recipe1, ingredient: chicken)
        context.insert(ri1)

        // Recipe 2 needs 0.5 kg chicken
        let recipe2 = Recipe(title: "Chicken Soup", servings: 1)
        context.insert(recipe2)
        let ri2 = RecipeIngredient(quantity: 0.5, unit: "kg", recipe: recipe2, ingredient: chicken)
        context.insert(ri2)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry1 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.lunch, servings: 1, recipe: recipe1)
        let entry2 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe2)
        context.insert(entry1)
        context.insert(entry2)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        // 500 g + 0.5 kg = 1000 g = 1 kg → should produce one item
        #expect(items.count == 1)
        #expect(items[0].unit == "kg")
        #expect(abs(items[0].quantity - 1.0) < 0.01)
    }

    @Test @MainActor func deductsInventoryAcrossCompatibleVolumeUnits() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let milk = Ingredient(name: "milk", displayName: "Milk", category: IngredientCategory.dairy)
        context.insert(milk)

        // Recipe needs 1 cup milk
        let recipe = Recipe(title: "Oatmeal", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe, ingredient: milk)
        context.insert(ri)

        // Inventory: 8 tbsp milk (= 0.5 cup)
        let inventory = InventoryItem(quantity: 8, unit: "tbsp", ingredient: milk)
        context.insert(inventory)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        // 1 cup needed − 8 tbsp (0.5 cup) on hand = 0.5 cup needed
        #expect(items.count == 1)
        #expect(items[0].unit == "tbsp")
        #expect(abs(items[0].quantity - 8.0) < 0.01)
    }

    @Test @MainActor func doesNotCrossDeductIncompatibleDimensions() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour", displayName: "Flour", category: IngredientCategory.grain)
        context.insert(flour)

        // Recipe needs 500 g flour (weight)
        let recipe = Recipe(title: "Bread", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 500, unit: "g", recipe: recipe, ingredient: flour)
        context.insert(ri)

        // Inventory: 2 cups flour (volume — incompatible dimension)
        let inventory = InventoryItem(quantity: 2, unit: "cup", ingredient: flour)
        context.insert(inventory)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        // No deduction across incompatible dimensions
        #expect(items.count == 1)
        #expect(abs(items[0].quantity - 500.0) < 0.01)
        #expect(items[0].unit == "g")
    }

    @Test @MainActor func countUnitsAggregateWithSameNormalizedUnit() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let eggs = Ingredient(name: "eggs", displayName: "Eggs", category: IngredientCategory.protein)
        context.insert(eggs)

        // Two recipes both need "large" eggs
        let recipe1 = Recipe(title: "Omelette", servings: 1)
        let recipe2 = Recipe(title: "Scrambled", servings: 1)
        context.insert(recipe1)
        context.insert(recipe2)

        // Case-insensitive: "Large" and "large" should aggregate
        let ri1 = RecipeIngredient(quantity: 2, unit: "Large", recipe: recipe1, ingredient: eggs)
        let ri2 = RecipeIngredient(quantity: 3, unit: "large", recipe: recipe2, ingredient: eggs)
        context.insert(ri1)
        context.insert(ri2)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry1 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe1)
        let entry2 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.lunch, servings: 1, recipe: recipe2)
        context.insert(entry1)
        context.insert(entry2)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 1)
        #expect(items[0].unit == "large")
        #expect(abs(items[0].quantity - 5.0) < 0.001)
    }
}

// MARK: - Integration tests: RecipeFilterService with unit conversion

@Suite("RecipeFilterService.UnitConversion", .serialized)
struct RecipeFilterUnitConversionTests {

    @Test @MainActor func canCookWithCompatibleUnits() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        context.insert(flour)

        // Recipe needs 1 cup flour
        let recipe = Recipe(title: "Pancakes", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe, ingredient: flour)
        context.insert(ri)

        // Inventory: 16 tbsp flour = 1 cup
        let inventory = InventoryItem(quantity: 16, unit: "tbsp", ingredient: flour)
        context.insert(inventory)

        try context.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: context)
        #expect(result.count == 1)
    }

    @Test @MainActor func cannotCookWithInsufficientCompatibleUnits() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        context.insert(flour)

        // Recipe needs 1 cup flour
        let recipe = Recipe(title: "Cake", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe, ingredient: flour)
        context.insert(ri)

        // Inventory: only 8 tbsp = 0.5 cup (not enough)
        let inventory = InventoryItem(quantity: 8, unit: "tbsp", ingredient: flour)
        context.insert(inventory)

        try context.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: context)
        #expect(result.count == 0)
    }

    @Test @MainActor func cannotCookWithIncompatibleUnits() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        context.insert(flour)

        // Recipe needs 1 cup (volume), inventory is in g (weight)
        let recipe = Recipe(title: "Bread", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe, ingredient: flour)
        context.insert(ri)

        let inventory = InventoryItem(quantity: 200, unit: "g", ingredient: flour)
        context.insert(inventory)

        try context.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: context)
        #expect(result.count == 0)
    }
}

// MARK: - Integration tests: MealCompletionService with unit conversion

@Suite("MealCompletionService.UnitConversion", .serialized)
struct MealCompletionUnitConversionTests {

    @Test @MainActor func deductsAcrossCompatibleUnits() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let sugar = Ingredient(name: "sugar")
        context.insert(sugar)

        // Recipe uses 8 tbsp sugar
        let recipe = Recipe(title: "Lemonade", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 8, unit: "tbsp", recipe: recipe, ingredient: sugar)
        context.insert(ri)

        // Inventory: 2 cups sugar (= 32 tbsp)
        let inventory = InventoryItem(quantity: 2, unit: "cup", ingredient: sugar)
        context.insert(inventory)

        let yesterday = DateHelpers.addDays(-1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: yesterday, mealSlot: MealSlot.lunch, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        MealCompletionService.markCompleted(entry, context: context)

        // 8 tbsp used = 8/16 = 0.5 cup deducted from 2 cups
        let items = try context.fetch(FetchDescriptor<InventoryItem>())
        #expect(items.count == 1)
        #expect(abs(items[0].quantity - 1.5) < 0.01)
        #expect(items[0].unit == "cup")
    }

    @Test @MainActor func doesNotDeductAcrossIncompatibleUnits() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let butter = Ingredient(name: "butter")
        context.insert(butter)

        // Recipe needs 4 tbsp butter (volume)
        let recipe = Recipe(title: "Toast", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 4, unit: "tbsp", recipe: recipe, ingredient: butter)
        context.insert(ri)

        // Inventory: 100g butter (weight — incompatible)
        let inventory = InventoryItem(quantity: 100, unit: "g", ingredient: butter)
        context.insert(inventory)

        let yesterday = DateHelpers.addDays(-1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: yesterday, mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        MealCompletionService.markCompleted(entry, context: context)

        // Should not deduct — units incompatible (no density set)
        let items = try context.fetch(FetchDescriptor<InventoryItem>())
        #expect(items.count == 1)
        #expect(abs(items[0].quantity - 100.0) < 0.01)
    }
}

// MARK: - Integration tests: cross-dimension with density (RecipeFilterService)

@Suite("RecipeFilterService.CrossDimConversion", .serialized)
struct RecipeFilterCrossDimConversionTests {

    @Test @MainActor func canCookWithCrossDimUnitAndDensity() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(
            name: "flour", displayName: "Flour",
            category: IngredientCategory.grain, density: 0.529
        )
        context.insert(flour)

        // Recipe needs 1 cup flour (volume); 1 cup ≈ 125 g
        let recipe = Recipe(title: "Pancakes", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe, ingredient: flour)
        context.insert(ri)

        // Inventory: 150 g flour (weight) — sufficient
        let inventory = InventoryItem(quantity: 150, unit: "g", ingredient: flour)
        context.insert(inventory)

        try context.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: context)
        #expect(result.count == 1)
    }

    @Test @MainActor func cannotCookWithInsufficientCrossDimInventory() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(
            name: "flour", displayName: "Flour",
            category: IngredientCategory.grain, density: 0.529
        )
        context.insert(flour)

        // Recipe needs 2 cups flour ≈ 250 g
        let recipe = Recipe(title: "Cake", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "cup", recipe: recipe, ingredient: flour)
        context.insert(ri)

        // Inventory: only 100 g — not enough
        let inventory = InventoryItem(quantity: 100, unit: "g", ingredient: flour)
        context.insert(inventory)

        try context.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: context)
        #expect(result.count == 0)
    }
}

// MARK: - Integration tests: cross-dimension with density (MealCompletionService)

@Suite("MealCompletionService.CrossDimConversion", .serialized)
struct MealCompletionCrossDimConversionTests {

    @Test @MainActor func deductsCrossDimWithDensity() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // Butter with density 0.911 g/ml
        let butter = Ingredient(
            name: "butter", displayName: "Butter",
            category: IngredientCategory.dairy, density: 0.911
        )
        context.insert(butter)

        // Recipe uses 4 tbsp butter (volume):
        // 4 tbsp = 12 tsp × 4.92892 ml/tsp = 59.15 ml × 0.911 = 53.88 g
        let recipe = Recipe(title: "Toast", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 4, unit: "tbsp", recipe: recipe, ingredient: butter)
        context.insert(ri)

        // Inventory: 100 g butter
        let inventory = InventoryItem(quantity: 100, unit: "g", ingredient: butter)
        context.insert(inventory)

        let yesterday = DateHelpers.addDays(-1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: yesterday, mealSlot: MealSlot.breakfast, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        MealCompletionService.markCompleted(entry, context: context)

        let items = try context.fetch(FetchDescriptor<InventoryItem>())
        #expect(items.count == 1)
        // 100 g − 53.88 g ≈ 46.12 g remaining
        #expect(abs(items[0].quantity - 46.12) < 1.0)
        #expect(items[0].unit == "g")
    }
}

// MARK: - Integration tests: cross-dimension with density (ShoppingListGenerator)

@Suite("ShoppingListGenerator.CrossDimConversion", .serialized)
struct ShoppingListCrossDimConversionTests {

    @Test @MainActor func aggregatesCrossDimUnitsWithDensity() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(
            name: "flour", displayName: "Flour",
            category: IngredientCategory.grain, density: 0.529
        )
        context.insert(flour)

        // Recipe 1: 1 cup flour (volume) ≈ 125.15 g
        let recipe1 = Recipe(title: "Cake", servings: 1)
        context.insert(recipe1)
        let ri1 = RecipeIngredient(quantity: 1, unit: "cup", recipe: recipe1, ingredient: flour)
        context.insert(ri1)

        // Recipe 2: 100 g flour (weight)
        let recipe2 = Recipe(title: "Cookies", servings: 1)
        context.insert(recipe2)
        let ri2 = RecipeIngredient(quantity: 100, unit: "g", recipe: recipe2, ingredient: flour)
        context.insert(ri2)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry1 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.lunch, servings: 1, recipe: recipe1)
        let entry2 = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe2)
        context.insert(entry1)
        context.insert(entry2)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        // Both recipes normalized to grams → single shopping list item
        #expect(items.count == 1)
        // 125.15 g + 100 g ≈ 225.15 g (displayed as g since < 1000)
        #expect(items[0].unit == "g")
        #expect(abs(items[0].quantity - 225.15) < 2.0)
    }

    @Test @MainActor func crossDeductsInventoryWithDensity() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(
            name: "flour", displayName: "Flour",
            category: IngredientCategory.grain, density: 0.529
        )
        context.insert(flour)

        // Recipe needs 2 cups flour ≈ 250.3 g
        let recipe = Recipe(title: "Bread", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 2, unit: "cup", recipe: recipe, ingredient: flour)
        context.insert(ri)

        // Inventory: 200 g flour (weight) — partially covers the volume need
        let inventory = InventoryItem(quantity: 200, unit: "g", ingredient: flour)
        context.insert(inventory)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        // 2 cups ≈ 250.3 g needed − 200 g on hand = 50.3 g to buy
        #expect(items.count == 1)
        #expect(items[0].unit == "g")
        #expect(abs(items[0].quantity - 50.3) < 2.0)
    }

    @Test @MainActor func crossDeductsInventoryWithDensityReverseDirection() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(
            name: "flour", displayName: "Flour",
            category: IngredientCategory.grain, density: 0.529
        )
        context.insert(flour)

        // Recipe needs 200 g flour (weight)
        let recipe = Recipe(title: "Muffins", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 200, unit: "g", recipe: recipe, ingredient: flour)
        context.insert(ri)

        // Inventory: 2 cups flour ≈ 250.3 g with density 0.529 (1 cup ≈ 125.15 g)
        // 2 cups covers the 200 g need, so no shopping item needed.
        let inventory = InventoryItem(quantity: 2, unit: "cup", ingredient: flour)
        context.insert(inventory)

        let tomorrow = DateHelpers.addDays(1, to: DateHelpers.startOfDay(Date()))
        let entry = MealPlanEntry(date: tomorrow, mealSlot: MealSlot.dinner, servings: 1, recipe: recipe)
        context.insert(entry)
        try context.save()

        ShoppingListGenerator.generate(context: context)

        let items = try context.fetch(FetchDescriptor<ShoppingListItem>())
        #expect(items.count == 0)
    }
}
