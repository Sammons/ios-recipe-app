import Foundation

// MARK: - Unit Dimension

enum UnitDimension: String {
    case volume
    case weight
    case count
    case other
}

// MARK: - UnitConverter

struct UnitConverter {

    // MARK: Conversion constants

    /// Volume base unit: tsp (teaspoon). All volume amounts stored as tsp.
    private static let volumeFactors: [String: Double] = [
        // teaspoon
        "tsp": 1.0,
        // tablespoon
        "tbsp": 3.0,
        // fluid ounce (not weight oz)
        "fl oz": 6.0,
        // cup
        "cup": 48.0,
        // pint
        "pint": 96.0,
        // quart
        "quart": 192.0,
        // gallon
        "gallon": 768.0,
        // metric: 1 tsp = 4.92892 ml
        "ml": 1.0 / 4.92892,
        "l": 1000.0 / 4.92892,
    ]

    /// Weight base unit: gram. All weight amounts stored as grams.
    private static let weightFactors: [String: Double] = [
        "g": 1.0,
        "kg": 1000.0,
        "oz": 28.34952,
        "lb": 453.59237,
    ]

    // MARK: Unit normalization

    /// Map raw input strings (lowercase, trimmed) to a canonical unit name.
    private static let aliases: [String: String] = [
        // ── volume: teaspoon ──────────────────────────────────────────────
        "tsp": "tsp", "t": "tsp", "ts": "tsp",
        "teaspoon": "tsp", "teaspoons": "tsp",
        // ── volume: tablespoon ───────────────────────────────────────────
        "tbsp": "tbsp", "tbs": "tbsp", "tb": "tbsp",
        "tablespoon": "tbsp", "tablespoons": "tbsp",
        // ── volume: fluid ounce (must distinguish from weight oz) ────────
        "fl oz": "fl oz", "floz": "fl oz",
        "fluid oz": "fl oz", "fluid ozs": "fl oz",
        "fluid ounce": "fl oz", "fluid ounces": "fl oz",
        "fl. oz": "fl oz", "fl. oz.": "fl oz",
        // ── volume: cup ──────────────────────────────────────────────────
        "cup": "cup", "cups": "cup", "c": "cup",
        // ── volume: pint ─────────────────────────────────────────────────
        "pt": "pint", "pts": "pint", "pint": "pint", "pints": "pint",
        // ── volume: quart ────────────────────────────────────────────────
        "qt": "quart", "qts": "quart", "quart": "quart", "quarts": "quart",
        // ── volume: gallon ───────────────────────────────────────────────
        "gal": "gallon", "gals": "gallon", "gallon": "gallon", "gallons": "gallon",
        // ── volume: metric ───────────────────────────────────────────────
        "ml": "ml", "milliliter": "ml", "milliliters": "ml",
        "millilitre": "ml", "millilitres": "ml",
        "l": "l", "liter": "l", "liters": "l",
        "litre": "l", "litres": "l",
        // ── weight: gram ─────────────────────────────────────────────────
        "g": "g", "gram": "g", "grams": "g",
        // ── weight: kilogram ─────────────────────────────────────────────
        "kg": "kg", "kilogram": "kg", "kilograms": "kg",
        // ── weight: ounce (weight, not fluid) ────────────────────────────
        "oz": "oz", "ounce": "oz", "ounces": "oz",
        // ── weight: pound ────────────────────────────────────────────────
        "lb": "lb", "lbs": "lb", "pound": "lb", "pounds": "lb",
        // ── count: each ──────────────────────────────────────────────────
        "each": "each", "piece": "each", "pieces": "each",
        "whole": "each", "unit": "each", "units": "each",
        // ── count: size ──────────────────────────────────────────────────
        "large": "large", "lg": "large",
        "medium": "medium", "med": "medium",
        "small": "small", "sm": "small",
        // ── count: plant parts ───────────────────────────────────────────
        "clove": "clove", "cloves": "clove",
        "head": "head", "heads": "head",
        "sprig": "sprig", "sprigs": "sprig",
        "bunch": "bunch", "bunches": "bunch",
        "stalk": "stalk", "stalks": "stalk",
        "leaf": "leaf", "leaves": "leaf",
        // ── count: slices/strips ─────────────────────────────────────────
        "slice": "slice", "slices": "slice",
        "strip": "strip", "strips": "strip",
        // ── count: packaging ─────────────────────────────────────────────
        "can": "can", "cans": "can",
        "bottle": "bottle", "bottles": "bottle",
        "bag": "bag", "bags": "bag",
        "box": "box", "boxes": "box",
        "package": "package", "pkg": "package", "pack": "package",
        "stick": "stick", "sticks": "stick",
        "block": "block", "blocks": "block",
        "sheet": "sheet", "sheets": "sheet",
    ]

    // MARK: - Public API

    /// Normalize a unit string to its canonical form.
    /// Input is case-insensitive and whitespace-tolerant.
    /// Explicit aliases (e.g. "tablespoons" → "tbsp") take precedence.
    /// For unrecognized units, falls back to UnitTextNormalizer which handles
    /// English pluralization (e.g. "filets" → "filet", "bunches" → "bunch").
    static func normalize(_ unit: String) -> String {
        let key = unit.trimmingCharacters(in: .whitespaces).lowercased()
        if let alias = aliases[key] { return alias }
        return UnitTextNormalizer.normalize(key)
    }

    /// Returns the measurement dimension for a unit string.
    static func dimension(of unit: String) -> UnitDimension {
        let canonical = normalize(unit)
        if volumeFactors[canonical] != nil { return .volume }
        if weightFactors[canonical] != nil { return .weight }
        // Count units — anything recognized but not volume/weight
        let countUnits: Set<String> = [
            "each", "large", "medium", "small",
            "clove", "head", "sprig", "bunch", "stalk", "leaf",
            "slice", "strip",
            "can", "bottle", "bag", "box", "package", "stick", "block", "sheet",
        ]
        if countUnits.contains(canonical) { return .count }
        return .other
    }

    /// Returns a key used to group compatible ingredients together.
    /// Volume and weight units group by dimension (e.g., "volume", "weight")
    /// so tbsp + cups can be summed. Count and unrecognized units group by
    /// their canonical string so "large" and "medium" stay separate.
    static func aggregationKey(for unit: String) -> String {
        let dim = dimension(of: unit)
        switch dim {
        case .volume: return "volume"
        case .weight: return "weight"
        case .count, .other: return normalize(unit)
        }
    }

    /// Convert a quantity to the base unit for its dimension.
    /// Returns nil if the unit is not a recognized volume or weight unit.
    /// Base units: tsp (volume), g (weight).
    static func toBaseUnit(quantity: Double, unit: String) -> Double? {
        let canonical = normalize(unit)
        if let factor = volumeFactors[canonical] {
            return quantity * factor
        }
        if let factor = weightFactors[canonical] {
            return quantity * factor
        }
        return nil
    }

    /// Convert a base-unit quantity back to the target unit.
    /// Returns nil if the target unit is not recognized or incompatible.
    static func fromBaseUnit(baseQuantity: Double, toUnit: String) -> Double? {
        let canonical = normalize(toUnit)
        if let factor = volumeFactors[canonical] {
            return baseQuantity / factor
        }
        if let factor = weightFactors[canonical] {
            return baseQuantity / factor
        }
        return nil
    }

    /// Convert a quantity from one unit to another.
    /// Returns nil if the units are from different dimensions or not recognized.
    static func convert(quantity: Double, from: String, to: String) -> Double? {
        guard areCompatible(from, to) else { return nil }
        guard let base = toBaseUnit(quantity: quantity, unit: from) else { return nil }
        return fromBaseUnit(baseQuantity: base, toUnit: to)
    }

    /// Returns true if two units can be converted between (same measurable dimension).
    /// Count and other units are NOT compatible with each other or with volume/weight.
    static func areCompatible(_ u1: String, _ u2: String) -> Bool {
        let d1 = dimension(of: u1)
        let d2 = dimension(of: u2)
        guard d1 == d2 else { return false }
        return d1 == .volume || d1 == .weight
    }

    // MARK: - Display formatting

    /// Choose a human-readable unit for a total base quantity.
    /// Volume: tsp → tbsp → cup → quart → gallon based on magnitude.
    /// Weight: g → kg based on magnitude (US cooking convention).
    /// Count/other: returns (baseQuantity, "") — caller should use original unit.
    static func prettyDisplay(
        baseQuantity: Double,
        dimension: UnitDimension
    ) -> (quantity: Double, unit: String) {
        switch dimension {
        case .volume:
            if baseQuantity >= 768 {
                return (baseQuantity / 768, "gallon")
            } else if baseQuantity >= 192 {
                return (baseQuantity / 192, "quart")
            } else if baseQuantity >= 48 {
                return (baseQuantity / 48, "cup")
            } else if baseQuantity >= 3 {
                return (baseQuantity / 3, "tbsp")
            } else {
                return (baseQuantity, "tsp")
            }
        case .weight:
            if baseQuantity >= 1000 {
                return (baseQuantity / 1000, "kg")
            } else {
                return (baseQuantity, "g")
            }
        case .count, .other:
            return (baseQuantity, "")
        }
    }
}
