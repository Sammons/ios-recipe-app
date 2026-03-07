import Testing
@testable import RecipeApp

@Suite("UnitTextNormalizer")
struct UnitTextNormalizerTests {
    @Test func emptyStringReturnsEmpty() {
        #expect(UnitTextNormalizer.normalize("") == "")
        #expect(UnitTextNormalizer.normalize("   ") == "")
    }

    @Test func lowercasesAndTrimsWhitespace() {
        #expect(UnitTextNormalizer.normalize("  Cups  ") == "cup")
        #expect(UnitTextNormalizer.normalize("TBSP") == "tbsp")
    }

    @Test func removesPeriodsFromAbbreviations() {
        #expect(UnitTextNormalizer.normalize("oz.") == "oz")
        #expect(UnitTextNormalizer.normalize("tsp.") == "tsp")
    }

    @Test func singularizesRegularPlurals() {
        #expect(UnitTextNormalizer.normalize("cups") == "cup")
        #expect(UnitTextNormalizer.normalize("tablespoons") == "tablespoon")
        #expect(UnitTextNormalizer.normalize("grams") == "gram")
    }

    @Test func singularizesEsSuffixPlurals() {
        #expect(UnitTextNormalizer.normalize("bunches") == "bunch")
        #expect(UnitTextNormalizer.normalize("dashes") == "dash")
        #expect(UnitTextNormalizer.normalize("boxes") == "box")
    }

    @Test func singularizesIesPlurals() {
        #expect(UnitTextNormalizer.normalize("berries") == "berry")
    }

    @Test func handlesIrregularPlurals() {
        #expect(UnitTextNormalizer.normalize("loaves") == "loaf")
        #expect(UnitTextNormalizer.normalize("leaves") == "leaf")
        #expect(UnitTextNormalizer.normalize("knives") == "knife")
    }

    @Test func preservesShortTokensAndSpecialSuffixes() {
        // Words ending in "ss", "us", "is" should not be singularized
        #expect(UnitTextNormalizer.normalize("glass") == "glass")
        #expect(UnitTextNormalizer.normalize("citrus") == "citrus")
        #expect(UnitTextNormalizer.normalize("basis") == "basis")
    }

    @Test func normalizesMultiWordUnits() {
        #expect(UnitTextNormalizer.normalize("fluid ounces") == "fluid ounce")
        #expect(UnitTextNormalizer.normalize("Large Cans") == "large can")
    }

    @Test func identicalInputsNormalizeIdentically() {
        let a = UnitTextNormalizer.normalize("Cups")
        let b = UnitTextNormalizer.normalize("cups")
        let c = UnitTextNormalizer.normalize("  CUPS.  ")
        #expect(a == b)
        #expect(b == c)
    }
}
