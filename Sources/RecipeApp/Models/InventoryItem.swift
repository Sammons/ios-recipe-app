import Foundation
import SwiftData

@Model
final class InventoryItem {
    var quantity: Double
    var unit: String
    var lastUpdated: Date

    var ingredient: Ingredient?

    init(
        quantity: Double = 0,
        unit: String = "",
        ingredient: Ingredient? = nil
    ) {
        self.quantity = quantity
        self.unit = unit
        self.lastUpdated = Date()
        self.ingredient = ingredient
    }
}
