import SwiftUI

@Observable
final class RecipeListViewModel {
    var recipes: [Recipe] = []

    func loadSampleRecipes() {
        recipes = [
            Recipe(
                title: "Spaghetti Carbonara",
                description: "Classic Italian pasta dish",
                ingredients: ["Spaghetti", "Eggs", "Pecorino Romano", "Guanciale", "Black Pepper"],
                instructions: ["Cook pasta", "Fry guanciale", "Mix eggs and cheese", "Combine"],
                prepTime: 10 * 60,
                cookTime: 20 * 60
            ),
            Recipe(
                title: "Chicken Tikka Masala",
                description: "Creamy spiced chicken curry",
                ingredients: ["Chicken", "Yogurt", "Tomatoes", "Cream", "Spices"],
                instructions: ["Marinate chicken", "Grill chicken", "Make sauce", "Combine"],
                prepTime: 30 * 60,
                cookTime: 25 * 60
            ),
        ]
    }
}
