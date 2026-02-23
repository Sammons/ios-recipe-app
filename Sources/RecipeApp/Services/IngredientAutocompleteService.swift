import Foundation
import SwiftData

enum IngredientAliasCatalog {
    // Alias coverage is intentionally explicit to keep mappings predictable.
    static let aliasesByCanonicalName: [String: [String]] = [
        "green onions": ["scallion", "scallions", "spring onion", "spring onions"],
        "eggplant": ["aubergine", "aubergines"],
        "zucchini": ["courgette", "courgettes"],
        "chickpeas": ["garbanzo", "garbanzo bean", "garbanzo beans"],
        "powdered sugar": ["confectioners sugar", "confectioner's sugar", "confectioners' sugar", "icing sugar"],
        "arugula": ["rocket"],
        "rutabaga": ["swede"],
        "bell peppers green": ["green capsicum"],
        "bell peppers red": ["red capsicum"],
        "bell peppers yellow": ["yellow capsicum"],
        "all-purpose flour": ["plain flour"],
        "cornstarch": ["corn flour"],
        "coriander ground": ["coriander powder"],
        "zaatar": ["za'atar"],
        "canola oil": ["rapeseed oil"],
        "white vinegar": ["distilled vinegar"],
        "canned diced tomatoes": ["chopped tomatoes"],
        "mushrooms cremini": ["baby bella", "baby bella mushrooms"],
        "mushrooms shiitake": ["shitake", "shitake mushrooms"],
        "onions yellow": ["brown onion", "brown onions"],
        "onions red": ["purple onion", "purple onions"],
        "canned tuna": ["tuna fish"],
    ]

    static let canonicalByAlias: [String: String] = {
        var map: [String: String] = [:]
        for (canonical, aliases) in aliasesByCanonicalName {
            for alias in aliases {
                map[alias] = canonical
            }
        }
        return map
    }()

    static func matchingCanonicalNames(for query: String) -> Set<String> {
        let lowered = query.lowercased()
        guard lowered.count >= 2 else { return [] }

        var matches: Set<String> = []
        for (alias, canonicalName) in canonicalByAlias where alias.contains(lowered) {
            matches.insert(canonicalName)
        }
        return matches
    }
}

enum IngredientAutocompleteService {
    static func suggestions(context: ModelContext, query: String, limit: Int = 12) -> [Ingredient] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let lowered = trimmed.lowercased()
        let aliasMatches = IngredientAliasCatalog.matchingCanonicalNames(for: lowered)
        let descriptor = FetchDescriptor<Ingredient>(sortBy: [SortDescriptor(\Ingredient.displayName)])
        let allIngredients = (try? context.fetch(descriptor)) ?? []

        var results: [Ingredient] = []
        results.reserveCapacity(min(limit, allIngredients.count))

        for ingredient in allIngredients {
            let isDirectMatch =
                ingredient.name.contains(lowered)
                || ingredient.displayName.lowercased().contains(lowered)
            if isDirectMatch || aliasMatches.contains(ingredient.name) {
                results.append(ingredient)
                if results.count >= limit {
                    break
                }
            }
        }

        return results
    }
}
