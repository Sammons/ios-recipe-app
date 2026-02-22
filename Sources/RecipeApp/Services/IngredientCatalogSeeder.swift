import SwiftData

@MainActor
struct IngredientCatalogSeeder {
    @discardableResult
    static func seedMissing(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Ingredient>()
        let existing = (try? context.fetch(descriptor)) ?? []
        var existingNames = Set(existing.map(\.name))
        var catalogNamesSeen: Set<String> = []
        var inserted = 0

        for entry in IngredientCatalog.entries {
            let normalizedName = entry.name.lowercased()
            guard catalogNamesSeen.insert(normalizedName).inserted else {
                continue
            }
            guard !existingNames.contains(normalizedName) else {
                continue
            }

            let ingredient = Ingredient(
                name: entry.name,
                displayName: entry.displayName,
                category: entry.category
            )
            context.insert(ingredient)
            existingNames.insert(normalizedName)
            inserted += 1
        }

        if inserted > 0 {
            try? context.save()
        }

        return inserted
    }
}
