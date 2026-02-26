import SwiftData

@MainActor
struct IngredientCatalogSeeder {
    @discardableResult
    static func seedMissing(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Ingredient>()
        let existing = (try? context.fetch(descriptor)) ?? []
        var existingNames = Set(existing.map(\.name))
        let existingByName = Dictionary(existing.map { ($0.name, $0) }) { _, new in new }
        var catalogNamesSeen: Set<String> = []
        var inserted = 0
        var densityUpdated = 0

        for entry in IngredientCatalog.entries {
            let normalizedName = entry.name.lowercased()
            guard catalogNamesSeen.insert(normalizedName).inserted else {
                continue
            }
            guard !existingNames.contains(normalizedName) else {
                // Backfill density on existing ingredients that lack it.
                if let d = entry.density,
                   let existingIngredient = existingByName[normalizedName],
                   existingIngredient.density == nil {
                    existingIngredient.density = d
                    densityUpdated += 1
                }
                continue
            }

            let ingredient = Ingredient(
                name: entry.name,
                displayName: entry.displayName,
                category: entry.category,
                density: entry.density
            )
            context.insert(ingredient)
            existingNames.insert(normalizedName)
            inserted += 1
        }

        if inserted > 0 || densityUpdated > 0 {
            try? context.save()
        }

        return inserted
    }
}
