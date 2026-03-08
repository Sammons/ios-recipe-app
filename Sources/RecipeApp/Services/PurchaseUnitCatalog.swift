import Foundation

/// Maps ingredients to real retail shelf packaging sizes.
///
/// Instead of showing "33 oz chicken thighs", the shopping list shows "Buy: 2.5 lb".
/// Instead of "6 cups chicken broth", it shows "Buy: 2 cartons (32 oz)".
/// Quantities are snapped UP to the nearest purchasable shelf unit.
///
/// Lookup order: ingredient name → category fallback.
struct PurchaseUnitCatalog {

    // MARK: - Types

    /// A real retail package that you'd find on a store shelf.
    struct ShelfPackage {
        /// Display unit (e.g. "lb", "carton", "jar", "gallon").
        let unit: String
        /// Size of one package in the display unit (e.g. 1.0 for "1 lb", 0.5 for "half gallon").
        /// Quantities snap up to multiples of this.
        let increment: Double
        /// Optional label shown after the quantity (e.g. "32 oz" for cartons).
        /// When non-nil, display is "2 cartons (32 oz)" instead of just "2 cartons".
        let sizeLabel: String?

        init(unit: String, increment: Double, sizeLabel: String? = nil) {
            self.unit = unit
            self.increment = increment
            self.sizeLabel = sizeLabel
        }
    }

    /// Result of a shelf-unit lookup.
    struct ShelfResult {
        let quantity: Double
        let unit: String
        /// Human-readable display string (e.g. "2.5 lb", "2 cartons (32 oz)").
        let displayText: String
    }

    // MARK: - Ingredient-specific overrides

    /// Ingredient name (lowercased) → (dimension → shelf package).
    /// These override category defaults for ingredients with well-known retail packaging.
    private static let ingredientOverrides: [String: [UnitDimension: ShelfPackage]] = {
        // Liquid dairy / beverages — sold in containers
        let milkPackage: [UnitDimension: ShelfPackage] = [
            .weight: ShelfPackage(unit: "half gallon", increment: 0.5),
            .volume: ShelfPackage(unit: "half gallon", increment: 0.5),
        ]
        let brothPackage: [UnitDimension: ShelfPackage] = [
            .weight: ShelfPackage(unit: "carton", increment: 1, sizeLabel: "32 oz"),
            .volume: ShelfPackage(unit: "carton", increment: 1, sizeLabel: "32 oz"),
        ]
        let creamPackage: [UnitDimension: ShelfPackage] = [
            .weight: ShelfPackage(unit: "pint", increment: 1),
            .volume: ShelfPackage(unit: "pint", increment: 1),
        ]

        var map: [String: [UnitDimension: ShelfPackage]] = [:]

        // Milk variants
        for name in ["milk", "whole milk", "2% milk", "skim milk", "buttermilk", "oat milk", "almond milk"] {
            map[name] = milkPackage
        }

        // Broth / stock variants
        for name in ["chicken broth", "beef broth", "vegetable broth", "chicken stock", "beef stock", "vegetable stock", "broth", "stock"] {
            map[name] = brothPackage
        }

        // Cream variants
        for name in ["heavy cream", "whipping cream", "heavy whipping cream", "half and half", "half-and-half"] {
            map[name] = creamPackage
        }

        // Sour cream / yogurt — sold in containers
        for name in ["sour cream", "yogurt", "greek yogurt", "plain yogurt"] {
            map[name] = [
                .weight: ShelfPackage(unit: "container", increment: 1, sizeLabel: "16 oz"),
                .volume: ShelfPackage(unit: "container", increment: 1, sizeLabel: "16 oz"),
            ]
        }

        // Cream cheese — sold in blocks
        map["cream cheese"] = [
            .weight: ShelfPackage(unit: "block", increment: 1, sizeLabel: "8 oz"),
        ]

        // Canned goods
        for name in ["coconut milk", "coconut cream"] {
            map[name] = [
                .weight: ShelfPackage(unit: "can", increment: 1, sizeLabel: "13.5 oz"),
                .volume: ShelfPackage(unit: "can", increment: 1, sizeLabel: "13.5 oz"),
            ]
        }
        for name in ["diced tomatoes", "crushed tomatoes", "tomato sauce", "tomato paste"] {
            let pkg: [UnitDimension: ShelfPackage]
            if name == "tomato paste" {
                pkg = [.weight: ShelfPackage(unit: "can", increment: 1, sizeLabel: "6 oz")]
            } else {
                pkg = [.weight: ShelfPackage(unit: "can", increment: 1, sizeLabel: "14.5 oz")]
            }
            map[name] = pkg
        }
        for name in ["black beans", "kidney beans", "chickpeas", "pinto beans", "cannellini beans"] {
            map[name] = [
                .weight: ShelfPackage(unit: "can", increment: 1, sizeLabel: "15 oz"),
            ]
        }

        // Condiment bottles & jars
        let condimentBottle: [UnitDimension: ShelfPackage] = [
            .weight: ShelfPackage(unit: "bottle", increment: 1, sizeLabel: "20 oz"),
        ]
        let condimentSmallBottle: [UnitDimension: ShelfPackage] = [
            .weight: ShelfPackage(unit: "bottle", increment: 1, sizeLabel: "10 oz"),
        ]
        let condimentJar: [UnitDimension: ShelfPackage] = [
            .weight: ShelfPackage(unit: "jar", increment: 1, sizeLabel: "8 oz"),
        ]

        for name in ["ketchup", "barbecue sauce"] {
            map[name] = condimentBottle
        }
        for name in ["hot sauce", "soy sauce", "tamari", "fish sauce", "worcestershire sauce"] {
            map[name] = condimentSmallBottle
        }
        for name in ["mustard dijon", "mustard yellow", "mayonnaise", "salsa roja", "salsa verde"] {
            map[name] = [
                .weight: ShelfPackage(unit: "jar", increment: 1, sizeLabel: "16 oz"),
            ]
        }
        for name in ["tahini", "miso paste"] {
            map[name] = condimentJar
        }

        return map
    }()

    // MARK: - Category fallback catalog

    /// Category → dimension → shelf package mapping.
    private static let categoryCatalog: [String: [UnitDimension: ShelfPackage]] = [
        IngredientCategory.protein: [
            .weight: ShelfPackage(unit: "lb", increment: 0.5),
        ],
        IngredientCategory.vegetable: [
            .weight: ShelfPackage(unit: "lb", increment: 0.5),
        ],
        IngredientCategory.dairy: [
            .weight: ShelfPackage(unit: "oz", increment: 4),
            .volume: ShelfPackage(unit: "cup", increment: 0.5),
        ],
        IngredientCategory.grain: [
            .weight: ShelfPackage(unit: "lb", increment: 1),
            .volume: ShelfPackage(unit: "cup", increment: 0.5),
        ],
        IngredientCategory.spice: [
            .weight: ShelfPackage(unit: "jar", increment: 1, sizeLabel: "1 oz"),
            .volume: ShelfPackage(unit: "jar", increment: 1, sizeLabel: "1 oz"),
        ],
        IngredientCategory.other: [
            .weight: ShelfPackage(unit: "oz", increment: 4),
            .volume: ShelfPackage(unit: "cup", increment: 0.5),
        ],
    ]

    // MARK: - Shelf package size constants (for converting named packages to base units)

    /// Maps package unit names to their capacity in grams (for weight dimension).
    private static let packageWeightGrams: [String: Double] = [
        "half gallon": 1892.7,  // ~64 fl oz × 29.57 ml × ~1.0 g/ml (water-like)
        "gallon": 3785.4,
        "quart": 946.35,
        "pint": 473.18,
        "carton": 907.18,       // 32 oz carton
        "container": 453.59,    // 16 oz container
        "block": 226.80,        // 8 oz block
        "can": 411.07,          // 14.5 oz can (default)
        "bottle": 566.99,       // 20 oz bottle (default)
    ]

    /// Maps package unit names to their capacity in tsp (for volume dimension).
    private static let packageVolumeTsp: [String: Double] = [
        "half gallon": 384.0,   // 64 fl oz = 384 tsp
        "gallon": 768.0,
        "quart": 192.0,
        "pint": 96.0,
        "carton": 192.0,       // 32 fl oz = 192 tsp
        "container": 96.0,     // 16 fl oz = 96 tsp
        "can": 81.0,           // ~13.5 fl oz ≈ 81 tsp
        "jar": 6.0,            // ~1 oz spice jar ≈ 6 tsp (ground spice average)
    ]

    /// Resolves the actual package size in base units for the given dimension.
    ///
    /// Priority: (1) sizeLabel when its unit matches the dimension, (2) lookup tables
    /// for cross-dimension resolution (e.g. "32 oz" label for a volume carton),
    /// (3) standard UnitConverter for measurable package units (lb, cup, etc.).
    private static func packageBaseQty(for pkg: ShelfPackage, dimension: UnitDimension) -> Double? {
        // If the package is a standard measurable unit (lb, cup, etc.), use UnitConverter
        let unitDim = UnitConverter.dimension(of: pkg.unit)
        if unitDim == dimension {
            return UnitConverter.toBaseUnit(quantity: pkg.increment, unit: pkg.unit)
        }

        // 1. Parse sizeLabel first — it's the most specific and accurate for each package
        //    e.g. "15 oz" for black beans, "32 oz" for broth cartons, "1 oz" for spice jars
        if let sizeLabel = pkg.sizeLabel {
            let parts = sizeLabel.split(separator: " ")
            if parts.count == 2, let qty = Double(parts[0]) {
                let unit = String(parts[1])
                let labelDim = UnitConverter.dimension(of: unit)
                if labelDim == dimension {
                    // Label unit matches dimension — direct conversion
                    return UnitConverter.toBaseUnit(quantity: qty, unit: unit)
                }
            }
        }

        // 2. Lookup tables for cross-dimension resolution
        //    e.g. volume dimension for "carton" labeled "32 oz" → use packageVolumeTsp
        switch dimension {
        case .weight:
            if let grams = packageWeightGrams[pkg.unit] { return grams }
        case .volume:
            if let tsp = packageVolumeTsp[pkg.unit] { return tsp }
        default:
            break
        }

        return nil
    }

    // MARK: - Public API

    /// Convert a base-unit quantity to a shelf-purchasable result.
    ///
    /// - Parameters:
    ///   - baseQty: Quantity in base units (tsp for volume, g for weight).
    ///   - dimension: The unit dimension.
    ///   - category: The ingredient's category.
    ///   - ingredientName: The ingredient's name (lowercased) for specific overrides.
    /// - Returns: A `ShelfResult` with quantity, unit, and display text, or nil if no mapping exists.
    static func purchaseQuantity(
        baseQty: Double,
        dimension: UnitDimension,
        category: String,
        ingredientName: String = ""
    ) -> ShelfResult? {
        // 1. Try ingredient-specific override
        if let dimMap = ingredientOverrides[ingredientName],
           let pkg = dimMap[dimension] {
            return resolvePackage(baseQty: baseQty, dimension: dimension, package: pkg)
        }

        // 2. Fall back to category
        guard let dimMap = categoryCatalog[category],
              let pkg = dimMap[dimension] else {
            return nil
        }
        return resolvePackage(baseQty: baseQty, dimension: dimension, package: pkg)
    }

    /// Convenience that returns a simple (quantity, unit) tuple for backward compatibility.
    static func purchaseQuantitySimple(
        baseQty: Double,
        dimension: UnitDimension,
        category: String,
        ingredientName: String = ""
    ) -> (quantity: Double, unit: String)? {
        guard let result = purchaseQuantity(
            baseQty: baseQty, dimension: dimension, category: category, ingredientName: ingredientName
        ) else { return nil }
        return (result.quantity, result.unit)
    }

    // MARK: - Private

    private static func resolvePackage(
        baseQty: Double,
        dimension: UnitDimension,
        package: ShelfPackage
    ) -> ShelfResult? {
        let converted: Double

        // For named packages (carton, jar, container, etc.), figure out how many packages
        if let pkgBaseQty = packageBaseQty(for: package, dimension: dimension), pkgBaseQty > 0 {
            let unitDim = UnitConverter.dimension(of: package.unit)
            if unitDim == dimension {
                // Package unit is a real measurable unit (lb, pint, cup, etc.)
                guard let c = UnitConverter.fromBaseUnit(baseQuantity: baseQty, toUnit: package.unit) else {
                    return nil
                }
                converted = c
            } else {
                // Named package (carton, jar, can, etc.) — divide by package capacity
                let packagesNeeded = baseQty / pkgBaseQty
                let snapped = snapUp(packagesNeeded, increment: package.increment)
                return makeResult(quantity: snapped, package: package)
            }
        } else {
            // Try standard unit conversion
            guard let c = UnitConverter.fromBaseUnit(baseQuantity: baseQty, toUnit: package.unit) else {
                return nil
            }
            converted = c
        }

        let snapped = snapUp(converted, increment: package.increment)
        return makeResult(quantity: snapped, package: package)
    }

    private static func makeResult(quantity: Double, package: ShelfPackage) -> ShelfResult {
        let displayText: String
        if let sizeLabel = package.sizeLabel {
            let fmtQty = formatQuantity(quantity)
            displayText = "\(fmtQty) \(package.unit) (\(sizeLabel))"
        } else {
            let fmtQty = formatQuantity(quantity)
            displayText = "\(fmtQty) \(package.unit)"
        }
        return ShelfResult(quantity: quantity, unit: package.unit, displayText: displayText)
    }

    /// Round `value` up to the nearest multiple of `increment`.
    private static func snapUp(_ value: Double, increment: Double) -> Double {
        guard increment > 0 else { return value }
        let steps = (value / increment).rounded(.up)
        return steps * increment
    }

    private static func formatQuantity(_ qty: Double) -> String {
        if qty == qty.rounded() {
            return String(format: "%.0f", qty)
        }
        return qty.formatted(.number.precision(.fractionLength(0...2)))
    }
}
