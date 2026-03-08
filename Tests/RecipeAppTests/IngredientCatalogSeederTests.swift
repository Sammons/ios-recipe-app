import SwiftData
import Testing
@testable import RecipeApp

@Suite("IngredientCatalogSeeder", .serialized)
struct IngredientCatalogSeederTests {
    @Test @MainActor func seedsLargeCommonCatalogAndIsIdempotent() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let firstInsertCount = IngredientCatalogSeeder.seedMissing(context: context)
        #expect(firstInsertCount >= 300)

        let ingredients = try context.fetch(FetchDescriptor<Ingredient>())
        #expect(ingredients.count >= 300)

        let secondInsertCount = IngredientCatalogSeeder.seedMissing(context: context)
        #expect(secondInsertCount == 0)
    }

    @Test @MainActor func seededCatalogContainsSpecificCommonItems() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        IngredientCatalogSeeder.seedMissing(context: context)
        let allIngredients = try context.fetch(FetchDescriptor<Ingredient>())

        func fetch(_ name: String) throws -> Ingredient? {
            allIngredients.first { $0.name == name }
        }

        let asparagus = try fetch("asparagus")
        #expect(asparagus != nil)
        #expect(asparagus?.category == IngredientCategory.vegetable)

        let chickenBreast = try fetch("chicken breast")
        #expect(chickenBreast != nil)
        #expect(chickenBreast?.category == IngredientCategory.protein)

        let cuminGround = try fetch("cumin ground")
        #expect(cuminGround != nil)
        #expect(cuminGround?.category == IngredientCategory.spice)

        let greekYogurt = try fetch("yogurt greek plain")
        #expect(greekYogurt != nil)
        #expect(greekYogurt?.category == IngredientCategory.dairy)
    }

    @Test @MainActor func liquidCondimentsHaveDensityValues() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        IngredientCatalogSeeder.seedMissing(context: context)
        let allIngredients = try context.fetch(FetchDescriptor<Ingredient>())

        let condiments = [
            "hot sauce", "ketchup", "mustard dijon", "mustard yellow",
            "mayonnaise", "barbecue sauce", "salsa roja", "salsa verde",
            "tomato paste", "tomato sauce", "tahini", "miso paste", "tamari",
        ]

        for name in condiments {
            let ingredient = allIngredients.first { $0.name == name }
            #expect(ingredient != nil, "Missing catalog entry: \(name)")
            #expect(ingredient?.density != nil, "Missing density for: \(name)")
            #expect(ingredient!.density! > 0, "Non-positive density for: \(name)")
        }
    }
}
