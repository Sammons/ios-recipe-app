import Testing
import SwiftData
@testable import RecipeApp

@Suite("SeedData", .serialized)
struct SeedDataTests {
    @Test @MainActor func seedsNineRecipesAndFortyFourIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        SeedData.seedIfEmpty(context: context)

        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 9)

        let ingredients = try context.fetch(FetchDescriptor<Ingredient>())
        #expect(ingredients.count == 44)
    }

    @Test @MainActor func seedIsIdempotent() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        SeedData.seedIfEmpty(context: context)
        SeedData.seedIfEmpty(context: context)

        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(recipes.count == 9)
    }

    @Test @MainActor func allRecipeTypesRepresented() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        SeedData.seedIfEmpty(context: context)

        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        let types = Set(recipes.map(\.recipeType))
        #expect(types.contains(RecipeType.breakfast))
        #expect(types.contains(RecipeType.lunch))
        #expect(types.contains(RecipeType.dinner))
        #expect(types.contains(RecipeType.snack))
        #expect(types.contains(RecipeType.dessert))
    }

    @Test @MainActor func ingredientNamesAreLowercased() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        SeedData.seedIfEmpty(context: context)

        let ingredients = try context.fetch(FetchDescriptor<Ingredient>())
        for ingredient in ingredients {
            #expect(ingredient.name == ingredient.name.lowercased())
        }
    }

    @Test @MainActor func ingredientsHaveValidCategories() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        SeedData.seedIfEmpty(context: context)

        let ingredients = try context.fetch(FetchDescriptor<Ingredient>())
        for ingredient in ingredients {
            #expect(IngredientCategory.allCategories.contains(ingredient.category))
        }
    }

    @Test @MainActor func eachRecipeHasIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        SeedData.seedIfEmpty(context: context)

        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        for recipe in recipes {
            #expect(
                recipe.recipeIngredients.count > 0,
                "Recipe '\(recipe.title)' has no ingredients"
            )
        }
    }
}
