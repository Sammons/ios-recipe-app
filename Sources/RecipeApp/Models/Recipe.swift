import Foundation

struct Recipe: Identifiable, Codable, Sendable {
    let id: UUID
    var title: String
    var description: String
    var ingredients: [String]
    var instructions: [String]
    var prepTime: TimeInterval
    var cookTime: TimeInterval

    init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        ingredients: [String] = [],
        instructions: [String] = [],
        prepTime: TimeInterval = 0,
        cookTime: TimeInterval = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.ingredients = ingredients
        self.instructions = instructions
        self.prepTime = prepTime
        self.cookTime = cookTime
    }
}
