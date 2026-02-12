import XCTest

final class RecipeAppUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITEST", "UITEST_INMEMORY", "UITEST_SEED"]
    }

    // MARK: - Helpers

    /// Tap a tab in the "More" menu (for tabs 5-7 that overflow on iPhone).
    private func tapMoreTab(_ tabName: String) {
        let moreTab = app.tabBars.buttons["More"]
        XCTAssertTrue(moreTab.waitForExistence(timeout: 5), "More tab should exist")
        moreTab.tap()

        let row = app.tables.staticTexts[tabName]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "\(tabName) row should exist in More")
        row.tap()
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

        // First 4 tabs are directly visible in the tab bar
        let directTabs = ["Calendar", "Recipe Builder", "Shopping List", "Inventory"]
        for tab in directTabs {
            app.tabBars.buttons[tab].tap()
            let navBar = app.navigationBars[tab]
            XCTAssertTrue(navBar.waitForExistence(timeout: 5), "\(tab) nav bar should appear")
        }

        screenshot("02-tabs-inventory")

        // Remaining tabs are behind "More" on iPhone
        let moreTabs = ["Recipe Book", "Preferences", "Help"]
        for tab in moreTabs {
            tapMoreTab(tab)
            let navBar = app.navigationBars[tab]
            XCTAssertTrue(navBar.waitForExistence(timeout: 5), "\(tab) nav bar should appear")
        }

        screenshot("03-tabs-help")
    }

    func testRecipeBookShowsSeedRecipes() {
        app.launch()

        tapMoreTab("Recipe Book")

        // Recipes are alphabetically grouped; check ones near the top
        let avocadoToast = app.staticTexts["Avocado Toast"]
        XCTAssertTrue(avocadoToast.waitForExistence(timeout: 5), "Avocado Toast should be in recipe book")

        let bananaPancakes = app.staticTexts["Banana Pancakes"]
        XCTAssertTrue(bananaPancakes.waitForExistence(timeout: 5), "Banana Pancakes should be in recipe book")

        screenshot("04-recipe-book")
    }

    func testRecipeDetail() {
        app.launch()

        tapMoreTab("Recipe Book")

        let avocadoToast = app.staticTexts["Avocado Toast"]
        XCTAssertTrue(avocadoToast.waitForExistence(timeout: 5))
        avocadoToast.tap()

        let detailTitle = app.staticTexts["Avocado Toast"]
        XCTAssertTrue(detailTitle.waitForExistence(timeout: 5), "Detail should show recipe title")

        let ingredientsHeader = app.staticTexts["Ingredients"]
        XCTAssertTrue(ingredientsHeader.waitForExistence(timeout: 5), "Detail should show Ingredients section")

        screenshot("05-recipe-detail")
    }

    func testPreferencesNoCrash() {
        app.launch()

        tapMoreTab("Preferences")

        let mealSlotsHeader = app.staticTexts["Meal Slots"]
        XCTAssertTrue(mealSlotsHeader.waitForExistence(timeout: 5), "Meal Slots section should exist")

        let toggle = app.switches.firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "At least one toggle should exist")

        let lookaheadText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Lookahead")
        ).firstMatch
        XCTAssertTrue(lookaheadText.waitForExistence(timeout: 5), "Lookahead stepper should exist")

        screenshot("06-preferences")
    }

    func testInventoryAddItem() {
        app.launch()

        app.tabBars.buttons["Inventory"].tap()

        let addButton = app.buttons["Add Item"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Fill ingredient name
        let ingredientField = app.textFields["ingredient-field"]
        XCTAssertTrue(ingredientField.waitForExistence(timeout: 5))
        ingredientField.tap()
        ingredientField.typeText("Test Flour")

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
