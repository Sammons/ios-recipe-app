import Foundation

/// Maps ingredient categories to store-purchasable parcel sizes.
///
/// Instead of showing "340 g chicken", the shopping list shows "1 lb".
/// Quantities are snapped UP to the nearest purchasable increment.
struct PurchaseUnitCatalog {

    // MARK: - Types

    struct Parcel {
        /// Target unit for display (e.g. "lb", "cup", "oz").
        let unit: String
        /// Minimum purchasable increment in that unit (e.g. 0.25 lb → quarter-pound steps).
        let increment: Double
    }

    // MARK: - Catalog

    /// Category → dimension → parcel mapping.
    /// Weight parcels are defined in grams (base unit) converted to the target unit.
    /// Volume parcels are defined in tsp (base unit) converted to the target unit.
    private static let catalog: [String: [UnitDimension: Parcel]] = [
        IngredientCategory.protein: [
            .weight: Parcel(unit: "lb", increment: 0.25),
        ],
        IngredientCategory.vegetable: [
            .weight: Parcel(unit: "lb", increment: 0.25),
        ],
        IngredientCategory.dairy: [
            .weight: Parcel(unit: "oz", increment: 1),
            .volume: Parcel(unit: "cup", increment: 0.25),
        ],
        IngredientCategory.grain: [
            .weight: Parcel(unit: "lb", increment: 0.25),
            .volume: Parcel(unit: "cup", increment: 0.25),
        ],
        IngredientCategory.spice: [
            .weight: Parcel(unit: "oz", increment: 0.5),
            .volume: Parcel(unit: "tsp", increment: 0.25),
        ],
        IngredientCategory.other: [
            .weight: Parcel(unit: "oz", increment: 1),
            .volume: Parcel(unit: "cup", increment: 0.25),
        ],
    ]

    // MARK: - Public API

    /// Convert a base-unit quantity to a purchasable (quantity, unit) pair,
    /// snapped UP to the nearest parcel increment.
    ///
    /// - Parameters:
    ///   - baseQty: Quantity in base units (tsp for volume, g for weight).
    ///   - dimension: The unit dimension.
    ///   - category: The ingredient's category (e.g. "Protein", "Dairy").
    /// - Returns: A purchasable (quantity, unit) pair, or nil if no catalog entry exists.
    static func purchaseQuantity(
        baseQty: Double,
        dimension: UnitDimension,
        category: String
    ) -> (quantity: Double, unit: String)? {
        guard let dimMap = catalog[category],
              let parcel = dimMap[dimension] else {
            return nil
        }

        // Convert from base unit to the parcel's target unit.
        guard let converted = UnitConverter.fromBaseUnit(baseQuantity: baseQty, toUnit: parcel.unit) else {
            return nil
        }

        // Snap up to nearest increment.
        let snapped = snapUp(converted, increment: parcel.increment)
        return (snapped, parcel.unit)
    }

    // MARK: - Private

    /// Round `value` up to the nearest multiple of `increment`.
    private static func snapUp(_ value: Double, increment: Double) -> Double {
        guard increment > 0 else { return value }
        let steps = (value / increment).rounded(.up)
        return steps * increment
    }
}
