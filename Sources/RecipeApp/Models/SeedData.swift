import Foundation
import SwiftData

@MainActor
struct SeedData {
    static func seedIfEmpty(context: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // Common ingredients
        let ingredients = createIngredients(context: context)

        // Recipes
        let recipes: [(String, String, String, Int, Int, Int, [String], [(String, Double, String)])]
            = [
                (
                    "Spaghetti Carbonara",
                    "Classic Italian pasta with eggs and cured pork",
                    RecipeType.dinner, 10, 20, 4,
                    [
                        "Bring a large pot of salted water to boil and cook spaghetti until al dente",
                        "Cut guanciale into small pieces and fry until crispy",
                        "Whisk eggs with grated pecorino and black pepper",
                        "Drain pasta, reserving some cooking water",
                        "Toss hot pasta with guanciale, then quickly mix in egg mixture",
                        "Add cooking water as needed for a creamy sauce",
                    ],
                    [
                        ("spaghetti", 400, "g"), ("eggs", 4, "large"),
                        ("pecorino romano", 100, "g"),
                        ("guanciale", 150, "g"), ("black pepper", 1, "tsp"),
                    ]
                ),
                (
                    "Chicken Tikka Masala",
                    "Creamy spiced chicken curry",
                    RecipeType.dinner, 30, 25, 4,
                    [
                        "Cut chicken into bite-sized pieces and marinate in yogurt and spices",
                        "Grill or pan-fry chicken until charred",
                        "Saut\u{00e9} onion, garlic, and ginger, then add tomatoes",
                        "Simmer sauce with cream and spices",
                        "Add chicken to sauce and simmer 10 minutes",
                    ],
                    [
                        ("chicken breast", 600, "g"), ("yogurt", 200, "g"),
                        ("tomatoes", 400, "g"),
                        ("heavy cream", 150, "ml"), ("onion", 2, "medium"),
                        ("garlic", 4, "cloves"),
                        ("ginger", 1, "tbsp"), ("garam masala", 2, "tsp"),
                    ]
                ),
                (
                    "Greek Salad",
                    "Fresh Mediterranean salad with feta and olives",
                    RecipeType.lunch, 15, 0, 2,
                    [
                        "Chop tomatoes, cucumber, and red onion into chunks",
                        "Add kalamata olives and crumbled feta",
                        "Dress with olive oil, red wine vinegar, and oregano",
                        "Season with salt and pepper, toss gently",
                    ],
                    [
                        ("tomatoes", 3, "medium"), ("cucumber", 1, "large"),
                        ("red onion", 0.5, "medium"),
                        ("feta cheese", 100, "g"), ("kalamata olives", 50, "g"),
                        ("olive oil", 3, "tbsp"),
                    ]
                ),
                (
                    "Banana Pancakes",
                    "Fluffy weekend breakfast pancakes",
                    RecipeType.breakfast, 10, 15, 4,
                    [
                        "Mash bananas in a large bowl",
                        "Mix in eggs, milk, and vanilla extract",
                        "Combine flour, baking powder, and a pinch of salt",
                        "Fold dry ingredients into wet mixture until just combined",
                        "Cook on a buttered griddle until bubbles form, then flip",
                    ],
                    [
                        ("banana", 2, "medium"), ("eggs", 2, "large"),
                        ("all-purpose flour", 200, "g"),
                        ("milk", 150, "ml"), ("baking powder", 2, "tsp"),
                        ("butter", 20, "g"),
                    ]
                ),
                (
                    "Vegetable Stir Fry",
                    "Quick and healthy wok-fried vegetables with soy sauce",
                    RecipeType.dinner, 15, 10, 2,
                    [
                        "Prepare all vegetables: slice bell peppers, broccoli florets, snap peas, and carrots",
                        "Heat oil in a wok over high heat",
                        "Stir fry vegetables in batches, starting with carrots",
                        "Add soy sauce, sesame oil, and a pinch of sugar",
                        "Serve over steamed rice",
                    ],
                    [
                        ("bell pepper", 2, "medium"), ("broccoli", 200, "g"),
                        ("carrot", 2, "medium"),
                        ("soy sauce", 3, "tbsp"), ("sesame oil", 1, "tsp"),
                        ("rice", 200, "g"),
                    ]
                ),
                (
                    "Avocado Toast",
                    "Simple and satisfying breakfast or snack",
                    RecipeType.breakfast, 5, 3, 2,
                    [
                        "Toast bread until golden and crispy",
                        "Mash avocado with a fork, adding lime juice and salt",
                        "Spread avocado mixture on toast",
                        "Top with red pepper flakes and a drizzle of olive oil",
                    ],
                    [
                        ("avocado", 1, "large"), ("bread", 2, "slices"),
                        ("lime", 0.5, "medium"),
                        ("red pepper flakes", 0.25, "tsp"), ("olive oil", 1, "tsp"),
                    ]
                ),
                (
                    "Chocolate Chip Cookies",
                    "Classic chewy cookies with melted chocolate chips",
                    RecipeType.dessert, 15, 12, 24,
                    [
                        "Cream butter and sugars until fluffy",
                        "Beat in eggs and vanilla extract",
                        "Mix flour, baking soda, and salt in a separate bowl",
                        "Combine wet and dry ingredients",
                        "Fold in chocolate chips",
                        "Scoop onto baking sheet and bake at 375\u{00b0}F until edges are golden",
                    ],
                    [
                        ("butter", 225, "g"), ("sugar", 150, "g"),
                        ("all-purpose flour", 280, "g"),
                        ("eggs", 2, "large"), ("chocolate chips", 200, "g"),
                        ("baking soda", 1, "tsp"),
                        ("vanilla extract", 1, "tsp"),
                    ]
                ),
                (
                    "Hummus Wrap",
                    "Quick lunch wrap with hummus and fresh veggies",
                    RecipeType.lunch, 10, 0, 2,
                    [
                        "Spread hummus evenly across tortilla",
                        "Layer spinach, sliced cucumber, tomato, and red onion",
                        "Sprinkle with crumbled feta and a squeeze of lemon",
                        "Roll tightly, tucking in the sides",
                        "Cut in half diagonally",
                    ],
                    [
                        ("tortilla", 2, "large"), ("hummus", 100, "g"),
                        ("spinach", 50, "g"),
                        ("cucumber", 0.5, "medium"), ("tomatoes", 1, "medium"),
                    ]
                ),
                (
                    "Trail Mix Energy Bites",
                    "No-bake snack balls with oats and peanut butter",
                    RecipeType.snack, 15, 0, 12,
                    [
                        "Combine oats, peanut butter, honey, and chocolate chips",
                        "Mix in flaxseed and vanilla extract",
                        "Refrigerate mixture for 30 minutes",
                        "Roll into tablespoon-sized balls",
                        "Store in refrigerator for up to a week",
                    ],
                    [
                        ("oats", 150, "g"), ("peanut butter", 100, "g"),
                        ("honey", 60, "ml"),
                        ("chocolate chips", 50, "g"), ("flaxseed", 2, "tbsp"),
                    ]
                ),
            ]

        for (title, summary, type, prep, cook, servings, steps, ings) in recipes {
            let recipe = Recipe(
                title: title,
                summary: summary,
                prepTimeMinutes: prep,
                cookTimeMinutes: cook,
                servings: servings,
                recipeType: type,
                instructions: steps
            )
            context.insert(recipe)

            for (name, qty, unit) in ings {
                let ingredient = ingredients[name.lowercased()] ?? createIngredient(
                    name: name, context: context)
                let ri = RecipeIngredient(
                    quantity: qty,
                    unit: unit,
                    recipe: recipe,
                    ingredient: ingredient
                )
                context.insert(ri)
            }
        }

        try? context.save()
    }

    private static func createIngredients(context: ModelContext) -> [String: Ingredient] {
        let defs: [(String, String, String)] = [
            ("spaghetti", "Spaghetti", IngredientCategory.grain),
            ("eggs", "Eggs", IngredientCategory.protein),
            ("pecorino romano", "Pecorino Romano", IngredientCategory.dairy),
            ("guanciale", "Guanciale", IngredientCategory.protein),
            ("black pepper", "Black Pepper", IngredientCategory.spice),
            ("chicken breast", "Chicken Breast", IngredientCategory.protein),
            ("yogurt", "Yogurt", IngredientCategory.dairy),
            ("tomatoes", "Tomatoes", IngredientCategory.vegetable),
            ("heavy cream", "Heavy Cream", IngredientCategory.dairy),
            ("onion", "Onion", IngredientCategory.vegetable),
            ("garlic", "Garlic", IngredientCategory.vegetable),
            ("ginger", "Ginger", IngredientCategory.spice),
            ("garam masala", "Garam Masala", IngredientCategory.spice),
            ("cucumber", "Cucumber", IngredientCategory.vegetable),
            ("red onion", "Red Onion", IngredientCategory.vegetable),
            ("feta cheese", "Feta Cheese", IngredientCategory.dairy),
            ("kalamata olives", "Kalamata Olives", IngredientCategory.vegetable),
            ("olive oil", "Olive Oil", IngredientCategory.other),
            ("banana", "Banana", IngredientCategory.other),
            ("all-purpose flour", "All-Purpose Flour", IngredientCategory.grain),
            ("milk", "Milk", IngredientCategory.dairy),
            ("baking powder", "Baking Powder", IngredientCategory.other),
            ("butter", "Butter", IngredientCategory.dairy),
            ("bell pepper", "Bell Pepper", IngredientCategory.vegetable),
            ("broccoli", "Broccoli", IngredientCategory.vegetable),
            ("carrot", "Carrot", IngredientCategory.vegetable),
            ("soy sauce", "Soy Sauce", IngredientCategory.other),
            ("sesame oil", "Sesame Oil", IngredientCategory.other),
            ("rice", "Rice", IngredientCategory.grain),
            ("avocado", "Avocado", IngredientCategory.vegetable),
            ("bread", "Bread", IngredientCategory.grain),
            ("lime", "Lime", IngredientCategory.other),
            ("red pepper flakes", "Red Pepper Flakes", IngredientCategory.spice),
            ("sugar", "Sugar", IngredientCategory.other),
            ("chocolate chips", "Chocolate Chips", IngredientCategory.other),
            ("baking soda", "Baking Soda", IngredientCategory.other),
            ("vanilla extract", "Vanilla Extract", IngredientCategory.spice),
            ("tortilla", "Tortilla", IngredientCategory.grain),
            ("hummus", "Hummus", IngredientCategory.other),
            ("spinach", "Spinach", IngredientCategory.vegetable),
            ("oats", "Oats", IngredientCategory.grain),
            ("peanut butter", "Peanut Butter", IngredientCategory.protein),
            ("honey", "Honey", IngredientCategory.other),
            ("flaxseed", "Flaxseed", IngredientCategory.grain),
        ]

        var map: [String: Ingredient] = [:]
        for (name, display, category) in defs {
            let ingredient = Ingredient(name: name, displayName: display, category: category)
            context.insert(ingredient)
            map[name] = ingredient
        }
        return map
    }

    private static func createIngredient(name: String, context: ModelContext) -> Ingredient {
        let ingredient = Ingredient(name: name)
        context.insert(ingredient)
        return ingredient
    }
}
