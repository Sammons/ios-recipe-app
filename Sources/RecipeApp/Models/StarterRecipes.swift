import Foundation
import SwiftData

struct StarterRecipes {
    /// Seeds starter recipes if none exist yet. Safe to call multiple times.
    static func seedIfEmpty(context: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>(
            predicate: #Predicate<Recipe> { $0.isStarterRecipe }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let ingredients = createIngredients(context: context)

        for def in allRecipes {
            let recipe = Recipe(
                title: def.title,
                summary: def.summary,
                prepTimeMinutes: def.prepMinutes,
                cookTimeMinutes: def.cookMinutes,
                servings: def.servings,
                recipeType: def.recipeType,
                instructions: def.instructions,
                isStarterRecipe: true
            )
            applyNutrition(to: recipe, from: def)
            context.insert(recipe)

            var recipeIngredients: [RecipeIngredient] = []
            for (name, qty, unit) in def.ingredients {
                let ingredient = ingredients[name.lowercased()] ?? createIngredient(
                    name: name, context: context)
                let ri = RecipeIngredient(
                    quantity: qty,
                    unit: unit,
                    recipe: recipe,
                    ingredient: ingredient
                )
                context.insert(ri)
                recipeIngredients.append(ri)
            }
            recipe.recipeIngredients = recipeIngredients
        }

        try? context.save()
    }

    // MARK: - Recipe Definitions

    private struct RecipeDef {
        let title: String
        let summary: String
        let recipeType: String
        let prepMinutes: Int
        let cookMinutes: Int
        let servings: Int
        let instructions: [String]
        let ingredients: [(String, Double, String)]
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let fiber: Int
        let sugar: Int
        let sodium: Int
        let allergens: String
    }

    // MARK: - Breakfast

    private static let allRecipes: [RecipeDef] = [
        // ── Breakfast ──────────────────────────────
        RecipeDef(
            title: "Scrambled Eggs",
            summary: "Soft, creamy scrambled eggs in under 5 minutes",
            recipeType: RecipeType.breakfast, prepMinutes: 2, cookMinutes: 3, servings: 2,
            instructions: [
                "Crack eggs into a bowl, add a splash of milk, and whisk until smooth",
                "Melt butter in a non-stick pan over medium-low heat",
                "Pour in eggs and stir gently with a spatula, pushing curds from edges to center",
                "Remove from heat while still slightly wet — they finish cooking off the heat",
            ],
            ingredients: [
                ("eggs", 4, "large"), ("butter", 1, "tbsp"), ("milk", 1, "tbsp"),
            ],
            calories: 220, protein: 14, carbs: 1, fat: 17, fiber: 0, sugar: 1, sodium: 350,
            allergens: "Egg, Milk"
        ),
        RecipeDef(
            title: "Fried Eggs",
            summary: "Crispy-edged fried eggs, sunny-side up",
            recipeType: RecipeType.breakfast, prepMinutes: 1, cookMinutes: 4, servings: 1,
            instructions: [
                "Heat butter or oil in a non-stick skillet over medium heat",
                "Crack eggs into the pan, keeping yolks intact",
                "Cook until whites are set and edges are lightly golden, about 3-4 minutes",
                "Season with salt and pepper, serve immediately",
            ],
            ingredients: [
                ("eggs", 2, "large"), ("butter", 1, "tsp"),
            ],
            calories: 180, protein: 12, carbs: 1, fat: 14, fiber: 0, sugar: 0, sodium: 300,
            allergens: "Egg, Milk"
        ),
        RecipeDef(
            title: "Oatmeal with Honey",
            summary: "Warm oatmeal topped with honey and fruit",
            recipeType: RecipeType.breakfast, prepMinutes: 2, cookMinutes: 5, servings: 1,
            instructions: [
                "Bring water or milk to a boil in a small saucepan",
                "Stir in oats, reduce heat to medium-low",
                "Cook 4-5 minutes, stirring occasionally, until thick and creamy",
                "Transfer to a bowl and drizzle with honey",
            ],
            ingredients: [
                ("rolled oats", 0.5, "cup"), ("milk", 1, "cup"), ("honey", 1, "tbsp"),
            ],
            calories: 260, protein: 9, carbs: 45, fat: 5, fiber: 4, sugar: 18, sodium: 110,
            allergens: "Milk"
        ),
        RecipeDef(
            title: "Greek Yogurt Bowl",
            summary: "Thick yogurt with honey and granola",
            recipeType: RecipeType.breakfast, prepMinutes: 3, cookMinutes: 0, servings: 1,
            instructions: [
                "Scoop yogurt into a bowl",
                "Drizzle with honey",
                "Top with granola and fresh berries if desired",
            ],
            ingredients: [
                ("yogurt greek plain", 1, "cup"), ("honey", 1, "tbsp"),
                ("granola", 0.25, "cup"),
            ],
            calories: 290, protein: 18, carbs: 38, fat: 7, fiber: 2, sugar: 24, sodium: 80,
            allergens: "Milk"
        ),
        RecipeDef(
            title: "Berry Smoothie",
            summary: "Quick blended smoothie with mixed berries and banana",
            recipeType: RecipeType.breakfast, prepMinutes: 5, cookMinutes: 0, servings: 1,
            instructions: [
                "Add frozen berries, banana, yogurt, and milk to a blender",
                "Blend on high until smooth, about 30 seconds",
                "Pour into a glass and serve immediately",
            ],
            ingredients: [
                ("strawberries", 0.5, "cup"), ("blueberries", 0.5, "cup"),
                ("bananas", 1, "medium"), ("yogurt greek plain", 0.5, "cup"),
                ("milk", 0.5, "cup"),
            ],
            calories: 240, protein: 12, carbs: 46, fat: 3, fiber: 5, sugar: 30, sodium: 70,
            allergens: "Milk"
        ),
        RecipeDef(
            title: "Buttered Toast",
            summary: "Simple toasted bread with butter",
            recipeType: RecipeType.breakfast, prepMinutes: 1, cookMinutes: 2, servings: 1,
            instructions: [
                "Toast bread slices until golden brown",
                "Spread butter while still warm",
            ],
            ingredients: [
                ("white bread", 2, "slice"), ("butter salted", 1, "tbsp"),
            ],
            calories: 210, protein: 4, carbs: 26, fat: 10, fiber: 1, sugar: 2, sodium: 310,
            allergens: "Milk, Wheat"
        ),
        RecipeDef(
            title: "Latte",
            summary: "Espresso with steamed milk",
            recipeType: RecipeType.breakfast, prepMinutes: 2, cookMinutes: 3, servings: 1,
            instructions: [
                "Brew a double shot of espresso or strong coffee",
                "Heat milk in a saucepan until steaming, then froth with a whisk or frother",
                "Pour espresso into a mug, top with steamed milk",
            ],
            ingredients: [
                ("milk whole", 1, "cup"),
            ],
            calories: 150, protein: 8, carbs: 12, fat: 8, fiber: 0, sugar: 12, sodium: 105,
            allergens: "Milk"
        ),

        // ── Lunch ──────────────────────────────────
        RecipeDef(
            title: "Ham & Cheese Sandwich",
            summary: "Classic deli sandwich with ham and sharp cheddar",
            recipeType: RecipeType.lunch, prepMinutes: 5, cookMinutes: 0, servings: 1,
            instructions: [
                "Lay out two slices of bread",
                "Layer ham, cheese, lettuce, and tomato",
                "Add mustard or mayo to taste, close the sandwich",
            ],
            ingredients: [
                ("white bread", 2, "slice"), ("ham", 4, "oz"),
                ("cheddar sharp", 1, "oz"), ("lettuce romaine", 2, "leaf"),
                ("tomatoes roma", 2, "slice"),
            ],
            calories: 380, protein: 24, carbs: 30, fat: 16, fiber: 2, sugar: 4, sodium: 1100,
            allergens: "Milk, Wheat"
        ),
        RecipeDef(
            title: "Grilled Cheese",
            summary: "Golden crispy grilled cheese sandwich",
            recipeType: RecipeType.lunch, prepMinutes: 3, cookMinutes: 6, servings: 1,
            instructions: [
                "Butter one side of each bread slice",
                "Place one slice butter-side down in a skillet over medium heat",
                "Add cheese slices, top with second bread slice butter-side up",
                "Cook 3 minutes per side until golden and cheese is melted",
            ],
            ingredients: [
                ("white bread", 2, "slice"), ("cheddar sharp", 2, "oz"),
                ("butter salted", 1, "tbsp"),
            ],
            calories: 420, protein: 16, carbs: 28, fat: 26, fiber: 1, sugar: 3, sodium: 740,
            allergens: "Milk, Wheat"
        ),
        RecipeDef(
            title: "Garden Salad",
            summary: "Fresh mixed greens with simple vinaigrette",
            recipeType: RecipeType.lunch, prepMinutes: 10, cookMinutes: 0, servings: 2,
            instructions: [
                "Wash and tear lettuce into bite-sized pieces",
                "Slice cucumber, tomatoes, and red onion",
                "Toss everything together in a large bowl",
                "Whisk olive oil, vinegar, salt, and pepper for dressing",
                "Drizzle dressing over salad and toss to coat",
            ],
            ingredients: [
                ("lettuce romaine", 1, "head"), ("cucumber", 1, "medium"),
                ("tomatoes cherry", 1, "cup"), ("onions red", 0.25, "medium"),
                ("olive oil", 2, "tbsp"), ("red wine vinegar", 1, "tbsp"),
            ],
            calories: 160, protein: 3, carbs: 10, fat: 14, fiber: 4, sugar: 5, sodium: 150,
            allergens: ""
        ),
        RecipeDef(
            title: "Chicken Noodle Soup",
            summary: "Comforting homestyle soup with tender chicken and egg noodles",
            recipeType: RecipeType.lunch, prepMinutes: 15, cookMinutes: 25, servings: 4,
            instructions: [
                "Dice onion, carrots, and celery",
                "Heat olive oil in a large pot, saut\u{00e9} vegetables until softened, about 5 minutes",
                "Add chicken broth and bring to a boil",
                "Add chicken breast and simmer until cooked through, about 15 minutes",
                "Remove chicken, shred with two forks, return to pot",
                "Add egg noodles and cook until tender, about 8 minutes",
                "Season with salt and pepper",
            ],
            ingredients: [
                ("chicken breast", 1, "lb"), ("chicken broth", 6, "cup"),
                ("egg noodles", 2, "cup"), ("carrots", 2, "medium"),
                ("celery", 2, "stalk"), ("onions yellow", 1, "medium"),
                ("olive oil", 1, "tbsp"),
            ],
            calories: 310, protein: 30, carbs: 28, fat: 8, fiber: 3, sugar: 4, sodium: 880,
            allergens: "Egg, Wheat"
        ),
        RecipeDef(
            title: "BLT Sandwich",
            summary: "Bacon, lettuce, and tomato on toasted bread",
            recipeType: RecipeType.lunch, prepMinutes: 5, cookMinutes: 8, servings: 1,
            instructions: [
                "Cook bacon in a skillet until crispy, drain on paper towels",
                "Toast bread slices",
                "Spread mayo on one slice",
                "Layer bacon, lettuce, and tomato slices, close sandwich",
            ],
            ingredients: [
                ("white bread", 2, "slice"), ("bacon", 4, "slice"),
                ("lettuce romaine", 2, "leaf"), ("tomatoes roma", 3, "slice"),
                ("mayonnaise", 1, "tbsp"),
            ],
            calories: 430, protein: 16, carbs: 28, fat: 28, fiber: 2, sugar: 4, sodium: 960,
            allergens: "Egg, Wheat"
        ),
        RecipeDef(
            title: "Quesadilla",
            summary: "Cheesy tortilla with optional chicken filling",
            recipeType: RecipeType.lunch, prepMinutes: 5, cookMinutes: 6, servings: 1,
            instructions: [
                "Place a flour tortilla in a dry skillet over medium heat",
                "Sprinkle cheese evenly over one half",
                "Fold tortilla in half and press gently with a spatula",
                "Cook 3 minutes per side until golden and cheese is melted",
                "Cut into wedges and serve with salsa",
            ],
            ingredients: [
                ("flour tortillas", 1, "large"), ("monterey jack", 2, "oz"),
                ("salsa roja", 2, "tbsp"),
            ],
            calories: 350, protein: 14, carbs: 30, fat: 18, fiber: 1, sugar: 2, sodium: 620,
            allergens: "Milk, Wheat"
        ),

        // ── Dinner ─────────────────────────────────
        RecipeDef(
            title: "Classic Chili",
            summary: "Hearty ground beef chili with beans and tomatoes",
            recipeType: RecipeType.dinner, prepMinutes: 15, cookMinutes: 45, servings: 6,
            instructions: [
                "Brown ground beef in a large pot over medium-high heat, drain fat",
                "Add diced onion and bell pepper, cook until soft, about 5 minutes",
                "Stir in garlic, chili powder, cumin, and paprika, cook 1 minute",
                "Add canned diced tomatoes, tomato paste, and kidney beans",
                "Bring to a boil, then reduce heat and simmer 35-40 minutes",
                "Season with salt and pepper to taste",
                "Serve topped with shredded cheese and sour cream if desired",
            ],
            ingredients: [
                ("ground beef", 1.5, "lb"), ("kidney beans", 2, "can"),
                ("canned diced tomatoes", 1, "can"), ("tomato paste", 2, "tbsp"),
                ("onions yellow", 1, "large"), ("bell peppers red", 1, "medium"),
                ("garlic", 3, "clove"), ("chili powder", 2, "tbsp"),
                ("cumin ground", 1, "tsp"), ("paprika smoked", 1, "tsp"),
            ],
            calories: 420, protein: 32, carbs: 30, fat: 18, fiber: 9, sugar: 6, sodium: 780,
            allergens: ""
        ),
        RecipeDef(
            title: "Southern Cheesecake",
            summary: "Rich, creamy cheesecake with a buttery graham cracker crust",
            recipeType: RecipeType.dessert, prepMinutes: 25, cookMinutes: 55, servings: 10,
            instructions: [
                "Preheat oven to 325\u{00b0}F",
                "Mix graham cracker crumbs with melted butter and sugar, press into a springform pan",
                "Beat cream cheese until smooth, then beat in sugar and vanilla",
                "Add eggs one at a time, mixing just until incorporated after each",
                "Mix in sour cream until smooth — do not over-beat",
                "Pour filling over crust",
                "Bake 50-55 minutes until edges are set but center still jiggles slightly",
                "Turn oven off, crack the door, and let cheesecake cool inside for 1 hour",
                "Refrigerate at least 4 hours before serving",
            ],
            ingredients: [
                ("cream cheese", 32, "oz"), ("granulated sugar", 0.75, "cup"),
                ("eggs", 4, "large"), ("sour cream", 1, "cup"),
                ("vanilla extract", 2, "tsp"), ("butter unsalted", 6, "tbsp"),
            ],
            calories: 450, protein: 8, carbs: 32, fat: 34, fiber: 0, sugar: 24, sodium: 340,
            allergens: "Egg, Milk, Wheat"
        ),
        RecipeDef(
            title: "Cinnamon Rolls",
            summary: "Soft, gooey homemade cinnamon rolls with cream cheese glaze",
            recipeType: RecipeType.dessert, prepMinutes: 30, cookMinutes: 25, servings: 12,
            instructions: [
                "Warm milk to 110\u{00b0}F, stir in yeast and a pinch of sugar, let stand 5 minutes",
                "Mix flour, sugar, salt, melted butter, and egg into the yeast mixture to form a soft dough",
                "Knead 5-7 minutes until smooth and elastic",
                "Let dough rise in a warm spot for 1 hour until doubled",
                "Roll dough into a large rectangle on a floured surface",
                "Spread softened butter over dough, sprinkle generously with cinnamon-sugar mixture",
                "Roll up tightly from the long edge, cut into 12 even pieces",
                "Place rolls in a greased baking pan, let rise 30 minutes",
                "Bake at 375\u{00b0}F for 22-25 minutes until golden brown",
                "Mix cream cheese, powdered sugar, and vanilla for the glaze, spread over warm rolls",
            ],
            ingredients: [
                ("all-purpose flour", 3.5, "cup"), ("milk whole", 0.75, "cup"),
                ("active dry yeast", 1, "package"), ("butter unsalted", 0.5, "cup"),
                ("eggs", 1, "large"), ("granulated sugar", 0.5, "cup"),
                ("cinnamon ground", 2, "tbsp"), ("cream cheese", 4, "oz"),
                ("powdered sugar", 1, "cup"), ("vanilla extract", 1, "tsp"),
            ],
            calories: 380, protein: 6, carbs: 52, fat: 16, fiber: 1, sugar: 28, sodium: 220,
            allergens: "Egg, Milk, Wheat"
        ),
        RecipeDef(
            title: "BBQ Chicken",
            summary: "Smoky grilled or baked chicken with barbecue glaze",
            recipeType: RecipeType.dinner, prepMinutes: 10, cookMinutes: 35, servings: 4,
            instructions: [
                "Season chicken thighs with salt, pepper, and garlic powder",
                "Preheat grill or oven to 400\u{00b0}F",
                "Cook chicken 25 minutes, turning once",
                "Brush generously with barbecue sauce on both sides",
                "Continue cooking 8-10 minutes until sauce is caramelized and chicken reaches 165\u{00b0}F",
            ],
            ingredients: [
                ("chicken thighs", 2, "lb"), ("barbecue sauce", 0.5, "cup"),
                ("garlic powder", 1, "tsp"),
            ],
            calories: 380, protein: 34, carbs: 16, fat: 18, fiber: 0, sugar: 12, sodium: 680,
            allergens: ""
        ),
        RecipeDef(
            title: "Pan-Seared Steak",
            summary: "Restaurant-quality steak with a golden crust",
            recipeType: RecipeType.dinner, prepMinutes: 5, cookMinutes: 12, servings: 2,
            instructions: [
                "Remove steaks from fridge 30 minutes before cooking, pat dry",
                "Season generously with salt and pepper on both sides",
                "Heat a cast-iron skillet over high heat until smoking",
                "Add oil, then sear steaks 4 minutes per side for medium-rare",
                "Add butter, garlic, and rosemary to the pan, baste steaks for 1 minute",
                "Rest 5 minutes before slicing",
            ],
            ingredients: [
                ("beef sirloin", 1, "lb"), ("butter unsalted", 2, "tbsp"),
                ("garlic", 2, "clove"), ("olive oil", 1, "tbsp"),
                ("rosemary dried", 1, "tsp"),
            ],
            calories: 480, protein: 42, carbs: 1, fat: 34, fiber: 0, sugar: 0, sodium: 420,
            allergens: "Milk"
        ),
        RecipeDef(
            title: "Quinoa Dinner Bowl",
            summary: "Colorful grain bowl with roasted vegetables and tahini dressing",
            recipeType: RecipeType.dinner, prepMinutes: 15, cookMinutes: 25, servings: 2,
            instructions: [
                "Rinse quinoa, cook in 2 cups water until fluffy, about 15 minutes",
                "Toss sweet potato cubes and chickpeas with olive oil, season with cumin and paprika",
                "Roast vegetables at 425\u{00b0}F for 20-25 minutes until golden",
                "Whisk tahini with lemon juice and a splash of water for dressing",
                "Assemble bowls: quinoa base, roasted vegetables, fresh spinach",
                "Drizzle with tahini dressing",
            ],
            ingredients: [
                ("quinoa", 1, "cup"), ("sweet potatoes", 1, "large"),
                ("chickpeas", 1, "can"), ("spinach", 2, "cup"),
                ("tahini", 2, "tbsp"), ("lemons", 1, "medium"),
                ("olive oil", 2, "tbsp"), ("cumin ground", 1, "tsp"),
            ],
            calories: 480, protein: 18, carbs: 62, fat: 18, fiber: 10, sugar: 6, sodium: 320,
            allergens: "Sesame"
        ),
        RecipeDef(
            title: "Pesto Chickpea Pasta",
            summary: "Quick pasta tossed with pesto and roasted chickpeas",
            recipeType: RecipeType.dinner, prepMinutes: 10, cookMinutes: 20, servings: 4,
            instructions: [
                "Preheat oven to 400\u{00b0}F",
                "Drain and pat dry chickpeas, toss with olive oil, salt, and pepper",
                "Roast chickpeas on a baking sheet for 20 minutes until crispy",
                "Meanwhile, cook penne according to package directions",
                "Drain pasta, toss with pesto and a splash of pasta water",
                "Top with roasted chickpeas and parmesan",
            ],
            ingredients: [
                ("penne", 1, "lb"), ("chickpeas", 1, "can"),
                ("olive oil", 2, "tbsp"), ("parmesan", 0.5, "cup"),
            ],
            calories: 520, protein: 22, carbs: 72, fat: 16, fiber: 8, sugar: 3, sodium: 540,
            allergens: "Milk, Wheat"
        ),
        RecipeDef(
            title: "Spaghetti & Meat Sauce",
            summary: "Classic pasta with a rich slow-simmered tomato meat sauce",
            recipeType: RecipeType.dinner, prepMinutes: 10, cookMinutes: 35, servings: 4,
            instructions: [
                "Brown ground beef in a large skillet, drain fat",
                "Add diced onion and garlic, cook until softened",
                "Pour in crushed tomatoes and tomato paste, stir to combine",
                "Season with Italian seasoning, salt, and pepper",
                "Simmer on low 25-30 minutes, stirring occasionally",
                "Cook spaghetti according to package directions, drain",
                "Serve sauce over hot spaghetti, top with parmesan",
            ],
            ingredients: [
                ("spaghetti", 1, "lb"), ("ground beef", 1, "lb"),
                ("canned crushed tomatoes", 1, "can"), ("tomato paste", 2, "tbsp"),
                ("onions yellow", 1, "medium"), ("garlic", 3, "clove"),
                ("italian seasoning", 1, "tbsp"), ("parmesan", 0.25, "cup"),
            ],
            calories: 560, protein: 32, carbs: 64, fat: 18, fiber: 4, sugar: 8, sodium: 720,
            allergens: "Milk, Wheat"
        ),
        RecipeDef(
            title: "Sheet Pan Chicken & Vegetables",
            summary: "Easy one-pan dinner with roasted chicken and seasonal vegetables",
            recipeType: RecipeType.dinner, prepMinutes: 15, cookMinutes: 30, servings: 4,
            instructions: [
                "Preheat oven to 425\u{00b0}F",
                "Cut chicken thighs, broccoli, and bell peppers into even pieces",
                "Toss everything with olive oil, garlic powder, and Italian seasoning",
                "Spread in a single layer on a sheet pan",
                "Roast 25-30 minutes until chicken reaches 165\u{00b0}F and vegetables are tender",
            ],
            ingredients: [
                ("chicken thighs", 1.5, "lb"), ("broccoli", 2, "cup"),
                ("bell peppers red", 2, "medium"), ("olive oil", 2, "tbsp"),
                ("garlic powder", 1, "tsp"), ("italian seasoning", 1, "tsp"),
            ],
            calories: 350, protein: 32, carbs: 10, fat: 20, fiber: 3, sugar: 4, sodium: 420,
            allergens: ""
        ),
        RecipeDef(
            title: "Tacos",
            summary: "Seasoned ground beef tacos with all the fixings",
            recipeType: RecipeType.dinner, prepMinutes: 10, cookMinutes: 12, servings: 4,
            instructions: [
                "Brown ground beef in a skillet over medium-high heat, drain fat",
                "Add taco seasoning and water, simmer 5 minutes until thickened",
                "Warm corn tortillas in a dry skillet or microwave",
                "Fill tortillas with seasoned beef",
                "Top with shredded cheese, lettuce, tomato, and salsa",
            ],
            ingredients: [
                ("ground beef", 1, "lb"), ("corn tortillas", 8, "each"),
                ("taco seasoning", 2, "tbsp"), ("cheddar sharp", 0.5, "cup"),
                ("lettuce romaine", 1, "cup"), ("tomatoes roma", 2, "medium"),
                ("salsa roja", 0.5, "cup"),
            ],
            calories: 420, protein: 28, carbs: 32, fat: 20, fiber: 4, sugar: 3, sodium: 820,
            allergens: "Milk"
        ),
        RecipeDef(
            title: "Baked Salmon",
            summary: "Simple oven-baked salmon with lemon and herbs",
            recipeType: RecipeType.dinner, prepMinutes: 5, cookMinutes: 15, servings: 2,
            instructions: [
                "Preheat oven to 400\u{00b0}F",
                "Place salmon fillets on a lined baking sheet",
                "Drizzle with olive oil, squeeze lemon juice over top",
                "Season with salt, pepper, and dried dill",
                "Bake 12-15 minutes until salmon flakes easily with a fork",
            ],
            ingredients: [
                ("salmon fillet", 1, "lb"), ("lemons", 1, "medium"),
                ("olive oil", 1, "tbsp"), ("dill dried", 1, "tsp"),
            ],
            calories: 360, protein: 40, carbs: 1, fat: 22, fiber: 0, sugar: 0, sodium: 380,
            allergens: "Fish"
        ),

        // ── Snack ──────────────────────────────────
        RecipeDef(
            title: "Ants on a Log",
            summary: "Celery sticks with peanut butter and raisins",
            recipeType: RecipeType.snack, prepMinutes: 5, cookMinutes: 0, servings: 2,
            instructions: [
                "Wash celery and cut into 4-inch sticks",
                "Fill the groove of each stick with peanut butter",
                "Press raisins into the peanut butter",
            ],
            ingredients: [
                ("celery", 4, "stalk"), ("peanut butter", 3, "tbsp"),
                ("raisins", 2, "tbsp"),
            ],
            calories: 180, protein: 6, carbs: 14, fat: 12, fiber: 3, sugar: 8, sodium: 150,
            allergens: "Peanut"
        ),
    ]

    // MARK: - Helpers

    private static func applyNutrition(to recipe: Recipe, from def: RecipeDef) {
        recipe.caloriesPerServing = def.calories
        recipe.proteinGramsPerServing = def.protein
        recipe.carbsGramsPerServing = def.carbs
        recipe.fatGramsPerServing = def.fat
        recipe.fiberGramsPerServing = def.fiber
        recipe.sugarGramsPerServing = def.sugar
        recipe.sodiumMgPerServing = def.sodium
        recipe.allergenInfo = def.allergens
    }

    private static func createIngredients(context: ModelContext) -> [String: Ingredient] {
        // Collect all unique ingredient names from starter recipes
        var allNames: Set<String> = []
        for def in allRecipes {
            for (name, _, _) in def.ingredients {
                allNames.insert(name.lowercased())
            }
        }

        // Check which already exist in the database
        var map: [String: Ingredient] = [:]
        for name in allNames {
            let lowered = name.lowercased()
            let descriptor = FetchDescriptor<Ingredient>(
                predicate: #Predicate<Ingredient> { $0.name == lowered }
            )
            if let existing = try? context.fetch(descriptor).first {
                map[lowered] = existing
            }
        }
        return map
    }

    private static func createIngredient(name: String, context: ModelContext) -> Ingredient {
        let ingredient = Ingredient(name: name)
        context.insert(ingredient)
        return ingredient
    }
}
