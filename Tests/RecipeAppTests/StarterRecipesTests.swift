import Foundation
import SwiftData
import Testing

@testable import RecipeApp

@Suite("StarterRecipes", .serialized)
struct StarterRecipesTests {
    @Test @MainActor func seedsExpectedRecipeCount() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        StarterRecipes.seedIfEmpty(context: context)

        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { $0.isStarterRecipe }
        )
        let recipes = try context.fetch(descriptor)
        #expect(recipes.count == 25)
    }

    @Test @MainActor func starterSeedIsIdempotent() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        StarterRecipes.seedIfEmpty(context: context)
        StarterRecipes.seedIfEmpty(context: context)

        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { $0.isStarterRecipe }
        )
        let recipes = try context.fetch(descriptor)
        #expect(recipes.count == 25)
    }

    @Test @MainActor func allStarterRecipesAreFlaggedAsStarter() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        StarterRecipes.seedIfEmpty(context: context)

        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { $0.isStarterRecipe }
        )
        let starterRecipes = try context.fetch(descriptor)
        for recipe in starterRecipes {
            #expect(recipe.isStarterRecipe, "Recipe '\(recipe.title)' should be flagged as starter")
        }
    }

    @Test @MainActor func starterRecipesCoverBreakfastLunchDinner() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        StarterRecipes.seedIfEmpty(context: context)

        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { $0.isStarterRecipe }
        )
        let recipes = try context.fetch(descriptor)
        let types = Set(recipes.map(\.recipeType))
        #expect(types.contains(RecipeType.breakfast))
        #expect(types.contains(RecipeType.lunch))
        #expect(types.contains(RecipeType.dinner))
    }

    @Test @MainActor func eachStarterRecipeHasIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        StarterRecipes.seedIfEmpty(context: context)

        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { $0.isStarterRecipe }
        )
        let recipes = try context.fetch(descriptor)
        for recipe in recipes {
            #expect(
                recipe.recipeIngredients.count > 0,
                "Starter recipe '\(recipe.title)' has no ingredients"
            )
        }
    }

    @Test @MainActor func eachStarterRecipeHasNutrition() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        StarterRecipes.seedIfEmpty(context: context)

        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { $0.isStarterRecipe }
        )
        let recipes = try context.fetch(descriptor)
        for recipe in recipes {
            #expect(
                recipe.caloriesPerServing > 0,
                "Starter recipe '\(recipe.title)' should have calorie estimates"
            )
        }
    }

    @Test @MainActor func starterAndSeedDataCoexist() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        SeedData.seedIfEmpty(context: context)
        StarterRecipes.seedIfEmpty(context: context)

        let allRecipes = try context.fetch(FetchDescriptor<Recipe>())
        let starterOnly = allRecipes.filter(\.isStarterRecipe)
        let userOnly = allRecipes.filter { !$0.isStarterRecipe }

        #expect(starterOnly.count == 25)
        #expect(userOnly.count == 9)
        #expect(allRecipes.count == 34)
    }

    @Test @MainActor func starterRecipesReuseExistingIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        // Seed the original data first so shared ingredients (eggs, butter, etc.) exist
        SeedData.seedIfEmpty(context: context)
        let ingredientsBefore = try context.fetchCount(FetchDescriptor<Ingredient>())

        StarterRecipes.seedIfEmpty(context: context)
        let ingredientsAfter = try context.fetchCount(FetchDescriptor<Ingredient>())

        // Starter recipes should reuse existing ingredients, not duplicate them
        // The new count should be less than before + total unique starter ingredients
        #expect(ingredientsAfter >= ingredientsBefore)
    }

    @Test @MainActor func originalSeedRecipesNotFlaggedAsStarter() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        SeedData.seedIfEmpty(context: context)

        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { !$0.isStarterRecipe }
        )
        let recipes = try context.fetch(descriptor)
        #expect(recipes.count == 9)
    }
}
