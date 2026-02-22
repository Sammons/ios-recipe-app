import XCTest

@MainActor
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
        let aliases: [String: [String]] = [
            "Recipes": ["Recipe Book"],
            "Recipe Book": ["Recipes"],
            "List": ["Shopping List"],
            "Shopping List": ["List"],
            "Pantry": ["Inventory"],
            "Inventory": ["Pantry"],
            "Builder": ["Recipe Builder"],
            "Recipe Builder": ["Builder"],
            "Prefs": ["Preferences"],
            "Preferences": ["Prefs"],
        ]
        let candidates = [tabName] + (aliases[tabName] ?? [])
        let tabBar = app.tabBars.firstMatch

        // Try direct tab bar access first. On some runtimes, tabs are scrollable
        // and may need a short horizontal swipe to reveal hidden items.
        if tabBar.waitForExistence(timeout: 5) {
            for _ in 0..<2 {
                for candidate in candidates {
                    let tabButton = tabBar.buttons[candidate]
                    if tabButton.waitForExistence(timeout: 2) {
                        tabButton.tap()
                        return
                    }
                }
                tabBar.swipeLeft()
            }
        }

        // Legacy fallback: tab behind "More" on iOS 17 and earlier
        let moreTab = tabBar.buttons["More"]
        if moreTab.waitForExistence(timeout: 5) {
            moreTab.tap()

            // Overflow navigation may be presented as table, collection, or generic cells
            // depending on iOS/runtime behavior.
            for _ in 0..<2 {
                for candidate in candidates {
                    let tableCell = app.tables.cells.containing(.staticText, identifier: candidate).firstMatch
                    if tableCell.waitForExistence(timeout: 2) {
                        tableCell.tap()
                        return
                    }

                    let collectionCell = app.collectionViews.cells.containing(.staticText, identifier: candidate).firstMatch
                    if collectionCell.waitForExistence(timeout: 1) {
                        collectionCell.tap()
                        return
                    }

                    let genericCell = app.cells.containing(.staticText, identifier: candidate).firstMatch
                    if genericCell.waitForExistence(timeout: 1) {
                        genericCell.tap()
                        return
                    }

                    let rowStaticText = app.staticTexts[candidate]
                    if rowStaticText.waitForExistence(timeout: 1) {
                        rowStaticText.tap()
                        return
                    }

                    let rowButton = app.buttons[candidate]
                    if rowButton.waitForExistence(timeout: 1) {
                        rowButton.tap()
                        return
                    }
                }

                // Some runtimes need a second tap to expand overflow content.
                moreTab.tap()
            }

            XCTFail("\(tabName) row should exist in More")
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

        let allTabs: [(tab: String, nav: String)] = [
            ("Calendar", "Calendar"),
            ("Recipes", "Recipe Book"),
            ("List", "Shopping List"),
            ("Pantry", "Inventory"),
            ("Builder", "Recipe Builder"),
            ("Prefs", "Preferences"),
            ("Help", "Help"),
        ]

        for item in allTabs {
            tapTab(item.tab)
            let navBar = app.navigationBars[item.nav]
            XCTAssertTrue(navBar.waitForExistence(timeout: 5), "\(item.nav) nav bar should appear")
        }

        screenshot("02-tabs-help")
    }

    func testRecipeBookShowsSeedRecipes() {
        app.launch()

        tapTab("Recipes")

        // Recipes are alphabetically grouped; check ones near the top
        let avocadoToast = app.staticTexts["Avocado Toast"]
        XCTAssertTrue(avocadoToast.waitForExistence(timeout: 5), "Avocado Toast should be in recipe book")

        let bananaPancakes = app.staticTexts["Banana Pancakes"]
        XCTAssertTrue(bananaPancakes.waitForExistence(timeout: 5), "Banana Pancakes should be in recipe book")

        screenshot("04-recipe-book")
    }

    func testRecipeDetail() {
        app.launch()

        tapTab("Recipes")

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

        tapTab("Prefs")

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

        tapTab("Pantry")

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

    func testShoppingListShowsVisibleGenerateButton() {
        app.launch()

        tapTab("List")

        let generateButton = app.buttons["shopping-generate-toolbar"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5), "Generate button should be visible in toolbar")

        screenshot("09-shopping-generate-visible")
    }

    func testWeekViewRowCanBeTappedAcrossFullWidth() {
        app.launch()

        let weekSegment = app.buttons["Week"]
        XCTAssertTrue(weekSegment.waitForExistence(timeout: 5), "Week segment should exist")
        weekSegment.tap()

        let row = app.buttons["week-day-row-0"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Week row should exist")

        let rightEdge = row.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
        rightEdge.tap()

        XCTAssertEqual(row.value as? String, "selected", "Right-edge tap should still select the full row")

        screenshot("10-week-row-full-hit-target")
    }

    func testRecipeBuilderKeyboardHasDoneAction() {
        app.launch()

        tapTab("Builder")

        let titleField = app.textFields["Recipe Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Recipe title field should exist")
        titleField.tap()

        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5), "Keyboard toolbar should expose Done")
        doneButton.tap()

        screenshot("11-recipe-builder-keyboard-done")
    }
}
