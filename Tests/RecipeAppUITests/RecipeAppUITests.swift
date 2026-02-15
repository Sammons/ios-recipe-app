import XCTest

final class RecipeAppUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITEST", "UITEST_INMEMORY", "UITEST_SEED"]
    }

    // MARK: - Helpers

    /// Tap a tab by name. On iOS 18+ all tabs are in a scrollable tab bar.
    /// Falls back to the legacy "More" menu for older runtimes.
    private func tapTab(_ tabName: String) {
        let tabButton = app.tabBars.buttons[tabName]
        if tabButton.waitForExistence(timeout: 3) {
            tabButton.tap()
            return
        }

        // Legacy fallback: tab behind "More" on iOS 17 and earlier
        let moreTab = app.tabBars.buttons["More"]
        if moreTab.waitForExistence(timeout: 3) {
            moreTab.tap()
            let row = app.tables.staticTexts[tabName]
            XCTAssertTrue(row.waitForExistence(timeout: 5), "\(tabName) row should exist in More")
            row.tap()
        } else {
            XCTFail("Could not find tab '\(tabName)' in tab bar or More menu")
        }
    }

    /// Capture a screenshot and attach it to the test result.
    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Tests

    func testAppLaunchShowsCalendar() {
        app.launch()

        let navBar = app.navigationBars["Calendar"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Calendar nav bar should appear on launch")

        let dayButton = app.buttons["Day"]
        XCTAssertTrue(dayButton.waitForExistence(timeout: 5), "Day/Week/Month picker should be visible")

        screenshot("01-calendar-launch")
    }

    func testTabNavigation() {
        app.launch()

        let allTabs = ["Calendar", "Recipe Book", "Shopping List", "Inventory",
                       "Recipe Builder", "Preferences", "Help"]

        for tab in allTabs {
            tapTab(tab)
            let navBar = app.navigationBars[tab]
            XCTAssertTrue(navBar.waitForExistence(timeout: 5), "\(tab) nav bar should appear")
        }

        screenshot("02-tabs-help")
    }

    func testRecipeBookShowsSeedRecipes() {
        app.launch()

        tapTab("Recipe Book")

        // Recipes are alphabetically grouped; check ones near the top
        let avocadoToast = app.staticTexts["Avocado Toast"]
        XCTAssertTrue(avocadoToast.waitForExistence(timeout: 5), "Avocado Toast should be in recipe book")

        let bananaPancakes = app.staticTexts["Banana Pancakes"]
        XCTAssertTrue(bananaPancakes.waitForExistence(timeout: 5), "Banana Pancakes should be in recipe book")

        screenshot("04-recipe-book")
    }

    func testRecipeDetail() {
        app.launch()

        tapTab("Recipe Book")

        let avocadoToast = app.staticTexts["Avocado Toast"]
        XCTAssertTrue(avocadoToast.waitForExistence(timeout: 5))
        avocadoToast.tap()

        // Wait for detail view to fully load — summary text is detail-specific
        // and confirms navigation push completed (title alone matches list cell)
        let summaryText = app.staticTexts["Simple and satisfying breakfast or snack"]
        XCTAssertTrue(summaryText.waitForExistence(timeout: 10), "Detail should show recipe summary")

        // Scroll to reveal Ingredients section (List renders cells lazily)
        app.swipeUp()

        // Verify ingredient data rendered (section headers aren't reliably
        // exposed as staticTexts on iOS 18 — assert on content instead)
        let ingredientName = app.staticTexts["Olive Oil"]
        XCTAssertTrue(ingredientName.waitForExistence(timeout: 10), "Detail should show ingredient names")

        screenshot("05-recipe-detail")
    }

    func testPreferencesNoCrash() {
        app.launch()

        tapTab("Preferences")

        // Section header uses view-based `header: { Text("Meal Slots") }` which
        // isn't exposed as staticTexts in XCTest — verify via toggle content instead
        let breakfastToggle = app.switches["Breakfast"]
        XCTAssertTrue(breakfastToggle.waitForExistence(timeout: 10), "Breakfast toggle should exist")

        let lookaheadText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Lookahead")
        ).firstMatch
        XCTAssertTrue(lookaheadText.waitForExistence(timeout: 5), "Lookahead stepper should exist")

        screenshot("06-preferences")
    }

    func testInventoryAddItem() {
        app.launch()

        tapTab("Inventory")

        let addButton = app.buttons["Add Item"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Fill ingredient name — dismiss keyboard before moving to next field
        let ingredientField = app.textFields["ingredient-field"]
        XCTAssertTrue(ingredientField.waitForExistence(timeout: 5))
        ingredientField.tap()
        ingredientField.typeText("Test Flour\n")

        // Fill quantity
        let quantityField = app.textFields["quantity-field"]
        XCTAssertTrue(quantityField.waitForExistence(timeout: 5))
        quantityField.tap()
        quantityField.typeText("500")

        // Fill unit
        let unitField = app.textFields["unit-field"]
        XCTAssertTrue(unitField.waitForExistence(timeout: 5))
        unitField.tap()
        unitField.typeText("g")

        // Save
        app.buttons["Save"].tap()

        // Verify item appears in inventory list
        let addedItem = app.staticTexts["Test Flour"]
        XCTAssertTrue(addedItem.waitForExistence(timeout: 5), "Added item should appear in inventory")

        screenshot("07-inventory-added")
    }

    func testEmptyStateNoCrash() {
        // Launch without UITEST_SEED to get empty state
        app.launchArguments = ["UITEST", "UITEST_INMEMORY"]
        app.launch()

        let navBar = app.navigationBars["Calendar"]
        XCTAssertTrue(navBar.waitForExistence(timeout: 5), "Calendar should render with empty data")

        screenshot("08-empty-state")
    }
}
