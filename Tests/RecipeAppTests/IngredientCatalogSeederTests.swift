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

    /// Every ingredient commonly measured by volume must have a density value.
    /// This catches gaps where new catalog entries are added without density.
    @Test @MainActor func allVolumeMeasurableIngredientsHaveDensity() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        IngredientCatalogSeeder.seedMissing(context: context)
        let allIngredients = try context.fetch(FetchDescriptor<Ingredient>())

        // Comprehensive list: every ingredient that appears in recipes measured
        // by volume (tsp, tbsp, cup, etc.) must have a density value.
        let volumeMeasurable = [
            // Proteins measured by volume
            "peanut butter", "almond butter", "egg whites",
            // Dairy measured by volume
            "milk whole", "milk 2%", "milk skim", "milk lactose free",
            "heavy cream", "half and half", "buttermilk",
            "evaporated milk", "condensed milk",
            "yogurt plain", "yogurt greek plain", "yogurt vanilla",
            "kefir", "sour cream", "cream cheese",
            "cottage cheese", "ricotta",
            "butter unsalted", "butter salted", "ghee",
            // Oils
            "olive oil", "canola oil", "vegetable oil", "sesame oil",
            "coconut oil", "avocado oil", "peanut oil",
            // Sweeteners
            "honey", "maple syrup", "molasses",
            "granulated sugar", "light brown sugar", "dark brown sugar", "powdered sugar",
            // Flours
            "all-purpose flour", "bread flour", "whole wheat flour",
            "almond flour", "rice flour", "cornmeal", "masa harina",
            // Dry grains
            "rolled oats", "steel cut oats",
            "white rice", "brown rice", "jasmine rice", "basmati rice",
            "arborio rice", "wild rice", "barley",
            "quinoa", "farro", "bulgur", "couscous", "millet", "amaranth", "polenta",
            "panko breadcrumbs", "italian breadcrumbs", "granola", "pancake mix",
            // Leaveners & starches
            "baking soda", "baking powder", "cornstarch", "arrowroot powder",
            "active dry yeast",
            // Salts
            "kosher salt", "sea salt", "table salt",
            // Ground spices & dried herbs
            "black pepper", "white pepper", "garlic powder", "onion powder",
            "paprika sweet", "paprika smoked", "cayenne pepper", "chili powder",
            "cumin ground", "coriander ground", "turmeric ground", "ginger ground",
            "cinnamon ground", "nutmeg ground", "cardamom ground", "allspice ground",
            "oregano dried", "basil dried", "thyme dried", "rosemary dried",
            "sage dried", "dill dried", "parsley dried", "red pepper flakes",
            "curry powder", "garam masala", "italian seasoning",
            "taco seasoning", "poultry seasoning", "mustard powder",
            "chipotle powder", "cajun seasoning", "old bay seasoning",
            "ground mace", "dried mint",
            "chinese five spice", "herbes de provence", "smoked salt",
            "sumac", "zaatar",
            "cocoa powder", "espresso powder",
            // Seeds
            "fennel seeds", "anise seeds", "cumin seeds", "coriander seeds",
            "fenugreek seeds", "sesame seeds", "poppy seeds", "celery seed",
            "caraway seeds", "chia seeds", "hemp seeds",
            // Extracts
            "vanilla extract",
            // Vinegars & condiments
            "white vinegar", "apple cider vinegar", "balsamic vinegar",
            "red wine vinegar", "rice vinegar",
            "soy sauce", "tamari", "fish sauce", "worcestershire sauce",
            "hot sauce", "ketchup", "mustard dijon", "mustard yellow",
            "mayonnaise", "barbecue sauce", "salsa roja", "salsa verde",
            "tomato paste", "tomato sauce",
            "canned diced tomatoes", "canned crushed tomatoes",
            "tahini", "miso paste", "hummus classic",
            // Other pantry liquids
            "coconut milk canned",
            "chicken broth", "beef broth", "vegetable broth",
        ]

        var missing: [String] = []
        for name in volumeMeasurable {
            let ingredient = allIngredients.first { $0.name == name }
            if ingredient == nil {
                missing.append("\(name) (not in catalog)")
            } else if ingredient?.density == nil {
                missing.append("\(name) (no density)")
            }
        }

        #expect(missing.isEmpty, "Volume-measurable ingredients without density: \(missing.joined(separator: ", "))")
    }
}
