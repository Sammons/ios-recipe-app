import Foundation

struct IngredientCatalogEntry {
    let name: String
    let displayName: String
    let category: String
    /// Density in g/ml for volume↔weight conversion. Nil for items sold by count or weight only.
    let density: Double?
}

enum IngredientCatalog {
    static let entries: [IngredientCatalogEntry] =
        make(proteinNames, category: IngredientCategory.protein)
        + make(vegetableNames, category: IngredientCategory.vegetable)
        + make(dairyNames, category: IngredientCategory.dairy)
        + make(grainNames, category: IngredientCategory.grain)
        + make(spiceNames, category: IngredientCategory.spice)
        + make(otherNames, category: IngredientCategory.other)

    // Protein-rich items, legumes, and nuts/seeds commonly used in meal prep.
    private static let proteinNames = [
        "chicken breast", "chicken thighs", "chicken drumsticks", "ground chicken",
        "turkey breast", "ground turkey", "beef sirloin", "beef chuck roast", "ground beef",
        "flank steak", "brisket", "pork loin", "pork shoulder", "pork chops", "bacon",
        "ham", "italian sausage", "breakfast sausage", "salmon fillet", "cod fillet",
        "tilapia fillet", "shrimp", "scallops", "canned tuna", "canned salmon", "sardines",
        "anchovies", "eggs", "egg whites", "tofu firm", "tofu extra firm", "tofu silken",
        "tempeh", "seitan", "black beans", "pinto beans", "kidney beans", "cannellini beans",
        "chickpeas", "lentils brown", "lentils red", "split peas", "edamame", "peanuts",
        "almonds", "walnuts", "pecans", "cashews", "pistachios", "sunflower seeds",
        "pumpkin seeds", "chia seeds", "hemp seeds", "peanut butter", "almond butter",
    ]

    // Common vegetables and aromatics seen in weekly meal planning.
    private static let vegetableNames = [
        "artichoke", "arugula", "asparagus", "beets", "bok choy", "broccoli", "broccoli rabe",
        "brussels sprouts", "cabbage green", "cabbage red", "carrots", "cauliflower", "celery",
        "celery root", "chard swiss", "collard greens", "corn", "cucumber", "eggplant",
        "fennel bulb", "garlic", "green beans", "kale", "leeks", "lettuce romaine",
        "lettuce iceberg", "lettuce butter", "mushrooms button", "mushrooms cremini",
        "mushrooms shiitake", "okra", "onions yellow", "onions red", "onions white", "parsnips",
        "peas green", "potatoes russet", "potatoes red", "potatoes yukon gold", "pumpkin",
        "radishes", "rutabaga", "shallots", "spinach", "squash butternut", "squash acorn",
        "zucchini", "yellow squash", "sweet potatoes", "tomatoes roma", "tomatoes cherry",
        "tomatoes heirloom", "turnips", "watercress", "bell peppers red", "bell peppers yellow",
        "bell peppers green", "jalapeno peppers", "poblano peppers", "serrano peppers",
        "habanero peppers", "cabbage napa", "snap peas", "snow peas", "broccolini",
        "cucumber english", "tomatillos", "jicama", "daikon radish", "yam", "green onions",
        "cauliflower rice", "bean sprouts",
    ]

    // Dairy staples and close substitutes used frequently in recipes.
    private static let dairyNames = [
        "milk whole", "milk 2%", "milk skim", "milk lactose free", "heavy cream", "half and half",
        "buttermilk", "evaporated milk", "condensed milk", "yogurt plain", "yogurt greek plain",
        "yogurt vanilla", "kefir", "sour cream", "cream cheese", "butter unsalted",
        "butter salted", "ghee", "cottage cheese", "ricotta", "mozzarella", "cheddar sharp",
        "parmesan", "pecorino romano", "feta", "goat cheese", "swiss cheese", "provolone",
        "monterey jack", "colby jack",
    ]

    // Grains, flours, breads, pasta, and baking bases.
    private static let grainNames = [
        "all-purpose flour", "bread flour", "whole wheat flour", "almond flour", "rice flour",
        "cornmeal", "masa harina", "rolled oats", "steel cut oats", "quinoa", "white rice",
        "brown rice", "jasmine rice", "basmati rice", "arborio rice", "wild rice", "barley",
        "farro", "bulgur", "couscous", "millet", "amaranth", "polenta", "spaghetti", "penne",
        "fusilli", "linguine", "egg noodles", "ramen noodles", "soba noodles", "udon noodles",
        "white bread", "whole wheat bread", "sourdough bread", "baguette", "flour tortillas",
        "corn tortillas", "pita bread", "naan bread", "saltine crackers", "whole grain crackers",
        "panko breadcrumbs", "italian breadcrumbs", "granola", "pancake mix",
    ]

    // Herbs, spices, seasoning blends, and flavoring powders.
    private static let spiceNames = [
        "kosher salt", "sea salt", "table salt", "black pepper", "white pepper", "garlic powder",
        "onion powder", "paprika sweet", "paprika smoked", "cayenne pepper", "chili powder",
        "cumin ground", "cumin seeds", "coriander ground", "coriander seeds", "turmeric ground",
        "ginger ground", "cinnamon ground", "cinnamon sticks", "nutmeg ground", "cloves whole",
        "cardamom ground", "allspice ground", "oregano dried", "basil dried", "thyme dried",
        "rosemary dried", "sage dried", "dill dried", "bay leaves", "parsley dried",
        "red pepper flakes", "curry powder", "garam masala", "italian seasoning",
        "taco seasoning", "poultry seasoning", "mustard powder", "fennel seeds", "anise seeds",
        "sesame seeds", "poppy seeds", "vanilla extract", "cocoa powder", "espresso powder",
        "saffron threads", "star anise", "fenugreek seeds", "sumac", "zaatar",
        "chinese five spice", "herbes de provence", "smoked salt", "celery seed",
        "caraway seeds", "chipotle powder", "cajun seasoning", "old bay seasoning",
        "ground mace", "dried mint",
    ]

    // Fruit, oils, condiments, and pantry essentials outside core categories.
    private static let otherNames = [
        "apples gala", "apples granny smith", "bananas", "oranges navel", "lemons", "limes",
        "grapefruit", "strawberries", "blueberries", "raspberries", "blackberries", "grapes red",
        "grapes green", "pineapple", "mango", "pears bartlett", "peaches", "nectarines", "plums",
        "cherries", "watermelon", "cantaloupe", "honeydew melon", "avocados", "kiwi",
        "pomegranate", "coconut", "dates", "raisins", "figs dried", "olive oil", "canola oil",
        "vegetable oil", "sesame oil", "coconut oil", "avocado oil", "white vinegar",
        "apple cider vinegar", "balsamic vinegar", "red wine vinegar", "rice vinegar", "soy sauce",
        "tamari", "fish sauce", "worcestershire sauce", "hot sauce", "ketchup", "mustard dijon",
        "mustard yellow", "mayonnaise", "barbecue sauce", "salsa roja", "salsa verde",
        "tomato paste", "tomato sauce", "canned diced tomatoes", "canned crushed tomatoes",
        "chicken broth", "vegetable broth", "beef broth", "coconut milk canned", "maple syrup",
        "honey", "molasses", "granulated sugar", "light brown sugar", "dark brown sugar",
        "powdered sugar", "cornstarch", "arrowroot powder", "baking soda", "baking powder",
        "active dry yeast", "gelatin", "pickles dill", "relish sweet", "olives kalamata",
        "capers", "tahini", "miso paste", "hummus classic", "peanut oil",
    ]

    /// Density values (g/ml) keyed by lowercased ingredient name.
    /// Sourced from USDA and standard culinary references.
    /// Items sold primarily by count or weight (proteins, produce) are omitted.
    private static let densities: [String: Double] = [
        // ── Proteins (only items commonly measured by volume) ──
        "peanut butter": 1.090, "almond butter": 1.010,
        "egg whites": 1.030,
        // ── Dairy & liquid fats ──
        "milk whole": 1.030, "milk 2%": 1.030, "milk skim": 1.033, "milk lactose free": 1.030,
        "heavy cream": 0.994, "half and half": 1.012, "buttermilk": 1.030,
        "evaporated milk": 1.066, "condensed milk": 1.310,
        "yogurt plain": 1.040, "yogurt greek plain": 1.060, "yogurt vanilla": 1.040,
        "kefir": 1.030, "sour cream": 1.010, "cream cheese": 1.010,
        "cottage cheese": 1.020, "ricotta": 1.020,
        "butter unsalted": 0.911, "butter salted": 0.911, "ghee": 0.902,
        // ── Oils ──
        "olive oil": 0.915, "canola oil": 0.915, "vegetable oil": 0.900,
        "sesame oil": 0.920, "coconut oil": 0.900, "avocado oil": 0.910, "peanut oil": 0.912,
        // ── Sweeteners ──
        "honey": 1.420, "maple syrup": 1.370, "molasses": 1.460,
        "granulated sugar": 0.845, "light brown sugar": 0.928, "dark brown sugar": 0.928,
        "powdered sugar": 0.560,
        // ── Flours ──
        "all-purpose flour": 0.529, "bread flour": 0.508, "whole wheat flour": 0.529,
        "almond flour": 0.400, "rice flour": 0.620, "cornmeal": 0.620, "masa harina": 0.620,
        // ── Oats, rice & dry grains ──
        "rolled oats": 0.430, "steel cut oats": 0.740,
        "white rice": 0.750, "brown rice": 0.750, "jasmine rice": 0.750,
        "basmati rice": 0.750, "arborio rice": 0.750, "wild rice": 0.750,
        "barley": 0.720, "quinoa": 0.720, "farro": 0.720, "bulgur": 0.650,
        "couscous": 0.630, "millet": 0.750, "amaranth": 0.740, "polenta": 0.620,
        "panko breadcrumbs": 0.240, "italian breadcrumbs": 0.480,
        "granola": 0.480, "pancake mix": 0.530,
        // ── Leaveners & starches ──
        "baking soda": 1.080, "baking powder": 0.900,
        "cornstarch": 0.600, "arrowroot powder": 0.640,
        "active dry yeast": 0.680,
        // ── Salts & cocoa ──
        "kosher salt": 1.220, "sea salt": 1.200, "table salt": 1.200,
        "cocoa powder": 0.480, "espresso powder": 0.480,
        // ── Ground spices & dried herbs ──
        "black pepper": 0.550, "white pepper": 0.550,
        "garlic powder": 0.580, "onion powder": 0.560,
        "paprika sweet": 0.530, "paprika smoked": 0.530, "cayenne pepper": 0.530,
        "chili powder": 0.530, "cumin ground": 0.530, "coriander ground": 0.450,
        "turmeric ground": 0.670, "ginger ground": 0.500,
        "cinnamon ground": 0.560, "nutmeg ground": 0.530,
        "cardamom ground": 0.500, "allspice ground": 0.520,
        "oregano dried": 0.240, "basil dried": 0.250, "thyme dried": 0.300,
        "rosemary dried": 0.290, "sage dried": 0.230, "dill dried": 0.190,
        "parsley dried": 0.240, "red pepper flakes": 0.350,
        "curry powder": 0.530, "garam masala": 0.520, "italian seasoning": 0.280,
        "taco seasoning": 0.520, "poultry seasoning": 0.360, "mustard powder": 0.560,
        "chipotle powder": 0.530, "cajun seasoning": 0.520, "old bay seasoning": 0.520,
        "ground mace": 0.530, "dried mint": 0.240,
        "chinese five spice": 0.520, "herbes de provence": 0.280, "smoked salt": 1.200,
        "sumac": 0.520, "zaatar": 0.400,
        // ── Seeds (commonly measured by tsp/tbsp) ──
        "fennel seeds": 0.480, "anise seeds": 0.480, "cumin seeds": 0.480,
        "coriander seeds": 0.400, "fenugreek seeds": 0.650,
        "sesame seeds": 0.580, "poppy seeds": 0.610, "celery seed": 0.500,
        "caraway seeds": 0.500, "chia seeds": 0.700, "hemp seeds": 0.560,
        // ── Extracts (liquid, measured by tsp) ──
        "vanilla extract": 0.880,
        // ── Vinegars & liquid condiments ──
        "white vinegar": 1.010, "apple cider vinegar": 1.010,
        "balsamic vinegar": 1.060, "red wine vinegar": 1.010, "rice vinegar": 1.010,
        "soy sauce": 1.110, "tamari": 1.110, "fish sauce": 1.060,
        "worcestershire sauce": 1.050,
        "hot sauce": 1.010, "ketchup": 1.150, "mustard dijon": 1.050,
        "mustard yellow": 1.050, "mayonnaise": 0.910, "barbecue sauce": 1.080,
        "salsa roja": 1.030, "salsa verde": 1.030,
        "tomato paste": 1.200, "tomato sauce": 1.050,
        "canned diced tomatoes": 1.050, "canned crushed tomatoes": 1.060,
        "tahini": 1.070, "miso paste": 1.200, "hummus classic": 1.050,
        // ── Other pantry liquids ──
        "coconut milk canned": 0.930,
        // ── Broths & stocks (essentially water-based, ~1.0 g/ml) ──
        "chicken broth": 1.000, "beef broth": 1.000, "vegetable broth": 1.000,
    ]

    private static func make(_ names: [String], category: String) -> [IngredientCatalogEntry] {
        names.map { name in
            IngredientCatalogEntry(
                name: name,
                displayName: displayName(for: name),
                category: category,
                density: densities[name.lowercased()]
            )
        }
    }

    private static func displayName(for name: String) -> String {
        name
            .split(separator: " ")
            .map { word in
                let raw = String(word)
                if raw == "2%" { return raw }
                return raw.prefix(1).uppercased() + raw.dropFirst()
            }
            .joined(separator: " ")
    }
}
