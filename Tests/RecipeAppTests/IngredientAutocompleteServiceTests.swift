import SwiftData
import Testing
@testable import RecipeApp

@Suite("IngredientAutocompleteService", .serialized)
struct IngredientAutocompleteServiceTests {
    @Test @MainActor func aliasQueriesReturnCanonicalCatalogIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        IngredientCatalogSeeder.seedMissing(context: context)

        let scallionResults = IngredientAutocompleteService.suggestions(context: context, query: "scallion")
        #expect(scallionResults.contains(where: { $0.name == "green onions" }))

        let aubergineResults = IngredientAutocompleteService.suggestions(context: context, query: "aubergine")
        #expect(aubergineResults.contains(where: { $0.name == "eggplant" }))

        let icingSugarResults = IngredientAutocompleteService.suggestions(context: context, query: "icing sugar")
        #expect(icingSugarResults.contains(where: { $0.name == "powdered sugar" }))
    }

    @Test @MainActor func directQueriesStillWorkWithAliasSupport() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        IngredientCatalogSeeder.seedMissing(context: context)

        let directResults = IngredientAutocompleteService.suggestions(context: context, query: "aspar")
        #expect(directResults.contains(where: { $0.name == "asparagus" }))
    }

    @Test @MainActor func shortQueriesReturnNoSuggestionsAndLimitIsRespected() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        IngredientCatalogSeeder.seedMissing(context: context)

        let shortResults = IngredientAutocompleteService.suggestions(context: context, query: "a")
        #expect(shortResults.isEmpty)

        let broadResults = IngredientAutocompleteService.suggestions(context: context, query: "on", limit: 5)
        #expect(broadResults.count <= 5)
    }
}
