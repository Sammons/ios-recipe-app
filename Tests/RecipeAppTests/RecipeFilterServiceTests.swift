import Testing
import SwiftData
import Foundation
@testable import RecipeApp

@Suite("RecipeFilterService", .serialized)
struct RecipeFilterServiceTests {
    @Test @MainActor func allReturnsAllRecipes() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let r1 = Recipe(title: "A")
        let r2 = Recipe(title: "B")
        context.insert(r1)
        context.insert(r2)
        try context.save()

        let result = RecipeFilterService.filter(recipes: [r1, r2], mode: .all, context: context)
        #expect(result.count == 2)
    }

    @Test @MainActor func canCookNowReturnsRecipesWithAllIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        let sugar = Ingredient(name: "sugar")
        context.insert(flour)
        context.insert(sugar)

        let inv1 = InventoryItem(quantity: 500, unit: "g", ingredient: flour)
        let inv2 = InventoryItem(quantity: 200, unit: "g", ingredient: sugar)
        context.insert(inv1)
        context.insert(inv2)

        let recipe = Recipe(title: "Cake", servings: 1)
        context.insert(recipe)

        let ri1 = RecipeIngredient(quantity: 300, unit: "g", recipe: recipe, ingredient: flour)
        let ri2 = RecipeIngredient(quantity: 100, unit: "g", recipe: recipe, ingredient: sugar)
        context.insert(ri1)
        context.insert(ri2)

        try context.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: context)
        #expect(result.count == 1)
    }

    @Test @MainActor func canCookNowExcludesRecipesMissingIngredient() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        let sugar = Ingredient(name: "sugar")
        context.insert(flour)
        context.insert(sugar)

        // Only flour in inventory
        let inv = InventoryItem(quantity: 500, unit: "g", ingredient: flour)
        context.insert(inv)

        let recipe = Recipe(title: "Cake", servings: 1)
        context.insert(recipe)

        let ri1 = RecipeIngredient(quantity: 300, unit: "g", recipe: recipe, ingredient: flour)
        let ri2 = RecipeIngredient(quantity: 100, unit: "g", recipe: recipe, ingredient: sugar)
        context.insert(ri1)
        context.insert(ri2)

        try context.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: context)
        #expect(result.count == 0)
    }

    @Test @MainActor func canCookNowExcludesInsufficientQuantity() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        context.insert(flour)

        // Only 100g, recipe needs 300g
        let inv = InventoryItem(quantity: 100, unit: "g", ingredient: flour)
        context.insert(inv)

        let recipe = Recipe(title: "Bread", servings: 1)
        context.insert(recipe)

        let ri = RecipeIngredient(quantity: 300, unit: "g", recipe: recipe, ingredient: flour)
        context.insert(ri)

        try context.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: context)
        #expect(result.count == 0)
    }

    @Test @MainActor func partialMatchSortsByPercentDescending() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        let sugar = Ingredient(name: "sugar")
        let butter = Ingredient(name: "butter")
        context.insert(flour)
        context.insert(sugar)
        context.insert(butter)

        // Only flour in inventory
        let inv = InventoryItem(quantity: 1000, unit: "g", ingredient: flour)
        context.insert(inv)

        // Recipe A: needs flour only (100% match)
        let recipeA = Recipe(title: "Simple Bread", servings: 1)
        context.insert(recipeA)
        let riA = RecipeIngredient(quantity: 300, unit: "g", recipe: recipeA, ingredient: flour)
        context.insert(riA)

        // Recipe B: needs flour + sugar (50% match)
        let recipeB = Recipe(title: "Sweet Bread", servings: 1)
        context.insert(recipeB)
        let riB1 = RecipeIngredient(quantity: 300, unit: "g", recipe: recipeB, ingredient: flour)
        let riB2 = RecipeIngredient(quantity: 100, unit: "g", recipe: recipeB, ingredient: sugar)
        context.insert(riB1)
        context.insert(riB2)

        // Recipe C: needs flour + sugar + butter (33% match)
        let recipeC = Recipe(title: "Cake", servings: 1)
        context.insert(recipeC)
        let riC1 = RecipeIngredient(quantity: 200, unit: "g", recipe: recipeC, ingredient: flour)
        let riC2 = RecipeIngredient(quantity: 100, unit: "g", recipe: recipeC, ingredient: sugar)
        let riC3 = RecipeIngredient(quantity: 100, unit: "g", recipe: recipeC, ingredient: butter)
        context.insert(riC1)
        context.insert(riC2)
        context.insert(riC3)

        try context.save()

        let result = RecipeFilterService.filter(
            recipes: [recipeC, recipeA, recipeB], mode: .partialMatch, context: context
        )
        #expect(result.count == 3)
        #expect(result[0].title == "Simple Bread") // 100%
        #expect(result[1].title == "Sweet Bread")  // 50%
        #expect(result[2].title == "Cake")          // 33%
    }

    @Test @MainActor func emptyInventoryCanCookNowReturnsEmpty() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        context.insert(flour)

        let recipe = Recipe(title: "Bread", servings: 1)
        context.insert(recipe)

        let ri = RecipeIngredient(quantity: 300, unit: "g", recipe: recipe, ingredient: flour)
        context.insert(ri)

        try context.save()

        let result = RecipeFilterService.filter(recipes: [recipe], mode: .canCookNow, context: context)
        #expect(result.count == 0)
    }

    @Test @MainActor func emptyInventoryPartialMatchPutsZeroPercentLast() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let flour = Ingredient(name: "flour")
        context.insert(flour)

        // Recipe with no ingredients (100% by default)
        let emptyRecipe = Recipe(title: "No Ingredients")
        context.insert(emptyRecipe)

        // Recipe needing flour (0% with no inventory)
        let recipe = Recipe(title: "Bread", servings: 1)
        context.insert(recipe)
        let ri = RecipeIngredient(quantity: 300, unit: "g", recipe: recipe, ingredient: flour)
        context.insert(ri)

        try context.save()

        let result = RecipeFilterService.filter(
            recipes: [recipe, emptyRecipe], mode: .partialMatch, context: context
        )
        #expect(result[0].title == "No Ingredients") // 100%
        #expect(result[1].title == "Bread")           // 0%
    }
}
