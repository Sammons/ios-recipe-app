import XCTest

final class RecipeAppJourneyTests: XCTestCase {

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

    /// Plan a recipe by tapping the first available "Tap to add" button in the Day view.
    /// Call for slots in order (Breakfast → Lunch → Dinner → Snack) so the first empty slot matches.
    private func planFirstAvailableSlot(recipeName: String) {
        let tapToAdd = app.buttons["Tap to add"].firstMatch
        XCTAssertTrue(tapToAdd.waitForExistence(timeout: 5), "Tap to add button should exist")
        tapToAdd.tap()

        // RecipePickerView appears as a sheet
        let pickerNav = app.navigationBars["Choose Recipe"]
        XCTAssertTrue(pickerNav.waitForExistence(timeout: 5), "Recipe picker should appear")

        let searchField = app.searchFields["Search recipes"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(recipeName)

        let recipeRow = app.staticTexts[recipeName].firstMatch
        XCTAssertTrue(recipeRow.waitForExistence(timeout: 5), "\(recipeName) should appear in search results")
        recipeRow.tap()

        // Allow sheet dismiss animation to complete
        Thread.sleep(forTimeInterval: 0.5)
    }

    /// Add an inventory item using the Inventory tab's Add Item form.
    /// Assumes the Inventory tab is already selected.
    private func addInventoryItem(name: String, quantity: String, unit: String) {
        let addButton = app.buttons["Add Item"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Wait for form sheet
        let formNavBar = app.navigationBars["Add Item"]
        XCTAssertTrue(formNavBar.waitForExistence(timeout: 5))

        // Type ingredient name + return to dismiss suggestions
        let ingredientField = app.textFields["ingredient-field"]
        XCTAssertTrue(ingredientField.waitForExistence(timeout: 5))
        ingredientField.tap()
        ingredientField.typeText(name + "\n")

        // Fill quantity (initial display is "0", typing appends → "0N" → parsed as N)
        let quantityField = app.textFields["quantity-field"]
        XCTAssertTrue(quantityField.waitForExistence(timeout: 5))
        quantityField.tap()
        quantityField.typeText(quantity)

        // Fill unit
        let unitField = app.textFields["unit-field"]
        XCTAssertTrue(unitField.waitForExistence(timeout: 5))
        unitField.tap()
        unitField.typeText(unit)

        // Save
        app.buttons["Save"].tap()

        // Wait for sheet to dismiss
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Should return to inventory after saving")
    }

    /// Tap the overflow/ellipsis menu in the Shopping List navigation bar,
    /// then tap a menu item by label.
    private func tapShoppingListMenuItem(_ itemLabel: String) {
        let navBar = app.navigationBars["Shopping List"]
        // Secondary action toolbar item renders as a "More" button in the nav bar
        let menuButton = navBar.buttons["More"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5), "Shopping list overflow menu should exist")
        menuButton.tap()

        let menuItem = app.buttons[itemLabel]
        XCTAssertTrue(menuItem.waitForExistence(timeout: 5), "\(itemLabel) should appear in menu")
        menuItem.tap()
    }

    // MARK: - Journey 1

    /// Plan Banana Pancakes for breakfast, generate shopping list, verify ingredients appear.
    func testPlanBreakfastAndGenerateShoppingList() {
        app.launch()

        // Start on Calendar → Day view
        let calendarNav = app.navigationBars["Calendar"]
        XCTAssertTrue(calendarNav.waitForExistence(timeout: 5))

        // Plan Banana Pancakes for Breakfast (first empty slot)
        planFirstAvailableSlot(recipeName: "Banana Pancakes")

        // Verify the recipe appears in the day view
        let planned = app.staticTexts["Banana Pancakes"]
        XCTAssertTrue(planned.waitForExistence(timeout: 5), "Banana Pancakes should appear in day view")
        screenshot("journey01-breakfast-planned")

        // Navigate to Shopping List
        app.tabBars.buttons["Shopping List"].tap()
        let shoppingNav = app.navigationBars["Shopping List"]
        XCTAssertTrue(shoppingNav.waitForExistence(timeout: 5))

        // Generate shopping list from the meal plan
        tapShoppingListMenuItem("Generate from Meal Plan")

        // Verify shopping items generated (Banana Pancakes ingredients)
        let banana = app.staticTexts["Banana"]
        XCTAssertTrue(banana.waitForExistence(timeout: 5), "Banana should appear in shopping list")
        screenshot("journey01-shopping-generated")
    }

    // MARK: - Journey 2

    /// Plan 3 meals (breakfast/lunch/dinner), verify day/week/month views.
    func testPlanFullDayAndCheckCalendarViews() {
        app.launch()

        let calendarNav = app.navigationBars["Calendar"]
        XCTAssertTrue(calendarNav.waitForExistence(timeout: 5))

        // Plan 3 meals in slot order
        planFirstAvailableSlot(recipeName: "Banana Pancakes")
        planFirstAvailableSlot(recipeName: "Greek Salad")
        planFirstAvailableSlot(recipeName: "Spaghetti Carbonara")

        // Verify all 3 in day view
        XCTAssertTrue(app.staticTexts["Banana Pancakes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Greek Salad"].exists)
        XCTAssertTrue(app.staticTexts["Spaghetti Carbonara"].exists)
        screenshot("journey02-day-3meals")

        // Switch to Week view
        app.buttons["Week"].tap()
        let threeMeals = app.staticTexts["3 meals"]
        XCTAssertTrue(threeMeals.waitForExistence(timeout: 5), "Week view should show '3 meals' for today")
        screenshot("journey02-week-view")

        // Switch to Month view
        app.buttons["Month"].tap()
        // Month view renders weekday headers
        let sunHeader = app.staticTexts["Sun"]
        XCTAssertTrue(sunHeader.waitForExistence(timeout: 5), "Month view should show weekday headers")
        screenshot("journey02-month-view")
    }

    // MARK: - Journey 3

    /// Plan meal, generate shopping list, check off item, verify it transfers to inventory.
    func testShoppingCheckOffAddsToInventory() {
        app.launch()

        // Plan Avocado Toast for breakfast
        planFirstAvailableSlot(recipeName: "Avocado Toast")
        XCTAssertTrue(app.staticTexts["Avocado Toast"].waitForExistence(timeout: 5))

        // Go to Shopping List and generate
        app.tabBars.buttons["Shopping List"].tap()
        let shoppingNav = app.navigationBars["Shopping List"]
        XCTAssertTrue(shoppingNav.waitForExistence(timeout: 5))

        tapShoppingListMenuItem("Generate from Meal Plan")

        // Wait for items to appear (Avocado Toast ingredients)
        let avocado = app.staticTexts["Avocado"]
        XCTAssertTrue(avocado.waitForExistence(timeout: 5), "Avocado should be in shopping list")

        // Check off the first item (tap the circle button on the first shopping item)
        let checkButton = app.buttons["circle"].firstMatch
        XCTAssertTrue(checkButton.waitForExistence(timeout: 5))
        checkButton.tap()

        // Verify Purchased section appears
        let purchased = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Purchased")
        ).firstMatch
        XCTAssertTrue(purchased.waitForExistence(timeout: 5), "Purchased section should appear after check-off")
        screenshot("journey03-item-checked")

        // Go to Inventory and verify the item appeared
        app.tabBars.buttons["Inventory"].tap()
        let inventoryNav = app.navigationBars["Inventory"]
        XCTAssertTrue(inventoryNav.waitForExistence(timeout: 5))

        // At least one ingredient should now be in inventory from the check-off
        let hasItems = app.cells.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(hasItems, "Inventory should have at least one item from shopping check-off")
        screenshot("journey03-inventory-updated")
    }

    // MARK: - Journey 4

    /// Create a custom recipe in Recipe Book, then plan it in Calendar.
    func testCreateRecipeThenPlanIt() {
        app.launch()

        // Go to Recipe Book
        tapMoreTab("Recipe Book")
        let recipeBookNav = app.navigationBars["Recipe Book"]
        XCTAssertTrue(recipeBookNav.waitForExistence(timeout: 5))

        // Tap Add Recipe
        app.buttons["Add Recipe"].tap()
        let newRecipeNav = app.navigationBars["New Recipe"]
        XCTAssertTrue(newRecipeNav.waitForExistence(timeout: 5))

        // Fill in recipe title
        let titleField = app.textFields["Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Garlic Butter Shrimp")

        // Save
        newRecipeNav.buttons["Save"].tap()

        // Verify recipe appears in the book
        let newRecipe = app.staticTexts["Garlic Butter Shrimp"]
        XCTAssertTrue(newRecipe.waitForExistence(timeout: 5), "New recipe should appear in recipe book")
        screenshot("journey04-recipe-created")

        // Go to Calendar and plan the recipe
        app.tabBars.buttons["Calendar"].tap()
        let calendarNav = app.navigationBars["Calendar"]
        XCTAssertTrue(calendarNav.waitForExistence(timeout: 5))

        planFirstAvailableSlot(recipeName: "Garlic Butter Shrimp")

        let planned = app.staticTexts["Garlic Butter Shrimp"]
        XCTAssertTrue(planned.waitForExistence(timeout: 5), "Custom recipe should appear in day view")
        screenshot("journey04-custom-planned")
    }

    // MARK: - Journey 5

    /// Add all Avocado Toast ingredients to inventory, verify "Can Cook Now" filter shows it.
    func testStockInventoryThenFilterCanCookNow() {
        app.launch()

        // Go to Inventory
        app.tabBars.buttons["Inventory"].tap()
        let inventoryNav = app.navigationBars["Inventory"]
        XCTAssertTrue(inventoryNav.waitForExistence(timeout: 5))

        // Add all 5 Avocado Toast ingredients with quantities exceeding recipe needs
        // Recipe needs: avocado 1, bread 2, lime 0.5, red pepper flakes 0.25, olive oil 1
        addInventoryItem(name: "avocado", quantity: "5", unit: "large")
        addInventoryItem(name: "bread", quantity: "10", unit: "slices")
        addInventoryItem(name: "lime", quantity: "3", unit: "medium")
        addInventoryItem(name: "red pepper flakes", quantity: "2", unit: "tsp")
        addInventoryItem(name: "olive oil", quantity: "5", unit: "tsp")

        screenshot("journey05-inventory-stocked")

        // Go to Recipe Book and filter "Can Cook Now"
        tapMoreTab("Recipe Book")
        let recipeBookNav = app.navigationBars["Recipe Book"]
        XCTAssertTrue(recipeBookNav.waitForExistence(timeout: 5))

        // Open the filter menu and select Can Cook Now
        app.buttons["Filter"].tap()

        let canCookButton = app.buttons["Can Cook Now"]
        XCTAssertTrue(canCookButton.waitForExistence(timeout: 5))
        canCookButton.tap()

        // Verify Avocado Toast appears (should be the only recipe we can fully cook)
        let avocadoToast = app.staticTexts["Avocado Toast"]
        XCTAssertTrue(avocadoToast.waitForExistence(timeout: 5), "Avocado Toast should appear with Can Cook Now filter")
        screenshot("journey05-can-cook-now")
    }

    // MARK: - Journey 6

    /// View Chicken Tikka detail, check ingredients/instructions, edit servings from 4 to 5.
    func testBrowseRecipeDetailAndEditServings() {
        app.launch()

        // Go to Recipe Book
        tapMoreTab("Recipe Book")

        // Tap Chicken Tikka Masala
        let chickenTikka = app.staticTexts["Chicken Tikka Masala"]
        XCTAssertTrue(chickenTikka.waitForExistence(timeout: 5))
        chickenTikka.tap()

        // Verify detail view
        let detailNav = app.navigationBars["Chicken Tikka Masala"]
        XCTAssertTrue(detailNav.waitForExistence(timeout: 5))

        // Check ingredients section exists
        let ingredientsSection = app.staticTexts["Ingredients"]
        XCTAssertTrue(ingredientsSection.waitForExistence(timeout: 5), "Ingredients section should exist")

        // Check servings badge
        let servings = app.staticTexts["4 servings"]
        XCTAssertTrue(servings.waitForExistence(timeout: 5), "Should show '4 servings'")

        // Check instructions section (may need scroll)
        app.swipeUp()
        let instructionsSection = app.staticTexts["Instructions"]
        XCTAssertTrue(instructionsSection.waitForExistence(timeout: 5), "Instructions section should exist")
        screenshot("journey06-recipe-detail")

        // Scroll back up and tap Edit
        app.swipeDown()
        app.buttons["Edit"].tap()
        let editNav = app.navigationBars["Edit Recipe"]
        XCTAssertTrue(editNav.waitForExistence(timeout: 5))

        // Find the Servings stepper and increment (4 → 5)
        let servingsStepper = app.steppers.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Servings")
        ).firstMatch
        if !servingsStepper.exists {
            app.swipeUp()
        }
        XCTAssertTrue(servingsStepper.waitForExistence(timeout: 5), "Servings stepper should exist")
        servingsStepper.buttons["Increment"].tap()

        // Save
        editNav.buttons["Save"].tap()

        // Verify the new servings count
        let newServings = app.staticTexts["5 servings"]
        XCTAssertTrue(newServings.waitForExistence(timeout: 5), "Should show '5 servings' after edit")
        screenshot("journey06-servings-edited")
    }

    // MARK: - Journey 7

    /// Add 2 manual shopping items, check both off, clear purchased.
    func testManualShoppingItemsAndClearPurchased() {
        app.launch()

        // Go to Shopping List
        app.tabBars.buttons["Shopping List"].tap()
        let shoppingNav = app.navigationBars["Shopping List"]
        XCTAssertTrue(shoppingNav.waitForExistence(timeout: 5))

        // Add first manual item
        shoppingNav.buttons["Add"].tap()
        var addItemNav = app.navigationBars["Add Item"]
        XCTAssertTrue(addItemNav.waitForExistence(timeout: 5))

        var ingredientField = app.textFields["ingredient-field"]
        ingredientField.tap()
        ingredientField.typeText("Test Apples\n")

        var unitField = app.textFields["Unit"]
        unitField.tap()
        unitField.typeText("pieces")

        addItemNav.buttons["Add"].tap()

        // Wait for sheet to dismiss
        XCTAssertTrue(shoppingNav.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        // Add second manual item
        shoppingNav.buttons["Add"].tap()
        addItemNav = app.navigationBars["Add Item"]
        XCTAssertTrue(addItemNav.waitForExistence(timeout: 5))

        ingredientField = app.textFields["ingredient-field"]
        ingredientField.tap()
        ingredientField.typeText("Test Oranges\n")

        unitField = app.textFields["Unit"]
        unitField.tap()
        unitField.typeText("kg")

        addItemNav.buttons["Add"].tap()
        XCTAssertTrue(shoppingNav.waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 0.5)

        // Verify both items appear
        XCTAssertTrue(app.staticTexts["Test Apples"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Test Oranges"].exists)
        screenshot("journey07-manual-items-added")

        // Check off first item
        var checkButton = app.buttons["circle"].firstMatch
        XCTAssertTrue(checkButton.waitForExistence(timeout: 5))
        checkButton.tap()
        Thread.sleep(forTimeInterval: 0.3)

        // Check off second item
        checkButton = app.buttons["circle"].firstMatch
        XCTAssertTrue(checkButton.waitForExistence(timeout: 5))
        checkButton.tap()

        // Verify "Purchased (2)" exists
        let purchased = app.staticTexts["Purchased (2)"]
        XCTAssertTrue(purchased.waitForExistence(timeout: 5), "Should show 'Purchased (2)'")
        screenshot("journey07-items-checked")

        // Clear purchased via overflow menu
        tapShoppingListMenuItem("Clear Purchased")

        // Verify purchased section is gone — list should be empty now
        let emptyState = app.staticTexts["Shopping List Empty"]
        XCTAssertTrue(emptyState.waitForExistence(timeout: 5), "Shopping list should be empty after clearing")
        screenshot("journey07-purchased-cleared")
    }

    // MARK: - Journey 8

    /// Toggle meal slots, change lookahead, verify preferences persist across tab switch.
    func testPreferencesRoundTrip() {
        app.launch()

        // Go to Preferences
        tapMoreTab("Preferences")
        let prefsNav = app.navigationBars["Preferences"]
        XCTAssertTrue(prefsNav.waitForExistence(timeout: 5))

        // Toggle the Snack meal slot off (all 4 slots are on by default)
        let snackToggle = app.switches["Snack"]
        XCTAssertTrue(snackToggle.waitForExistence(timeout: 5))
        let originalValue = snackToggle.value as? String
        snackToggle.tap()
        let newValue = snackToggle.value as? String
        XCTAssertNotEqual(originalValue, newValue, "Snack toggle should change state")

        // Change lookahead stepper (default 7 → 8)
        let lookaheadLabel = app.staticTexts["Lookahead: 7 days"]
        XCTAssertTrue(lookaheadLabel.waitForExistence(timeout: 5), "Lookahead should default to 7 days")

        let stepper = app.steppers.firstMatch
        XCTAssertTrue(stepper.waitForExistence(timeout: 5))
        stepper.buttons["Increment"].tap()

        // Verify new value
        let updatedLookahead = app.staticTexts["Lookahead: 8 days"]
        XCTAssertTrue(updatedLookahead.waitForExistence(timeout: 5), "Lookahead should show 8 days")
        screenshot("journey08-preferences-changed")

        // Switch to Calendar and back to verify persistence
        app.tabBars.buttons["Calendar"].tap()
        XCTAssertTrue(app.navigationBars["Calendar"].waitForExistence(timeout: 5))

        tapMoreTab("Preferences")
        XCTAssertTrue(prefsNav.waitForExistence(timeout: 5))

        // Verify settings persisted
        let snackToggleAfter = app.switches["Snack"]
        XCTAssertTrue(snackToggleAfter.waitForExistence(timeout: 5))
        XCTAssertEqual(
            snackToggleAfter.value as? String, newValue,
            "Snack toggle should retain its new state after tab switch"
        )

        let lookaheadAfter = app.staticTexts["Lookahead: 8 days"]
        XCTAssertTrue(lookaheadAfter.exists, "Lookahead should still be 8 days after tab switch")
        screenshot("journey08-preferences-persisted")
    }

    // MARK: - Journey 9

    /// Send chat message in Recipe Builder, create recipe in editor pane, find in Recipe Book.
    func testRecipeBuilderChatAndSave() {
        app.launch()

        // Go to Recipe Builder
        app.tabBars.buttons["Recipe Builder"].tap()
        let builderNav = app.navigationBars["Recipe Builder"]
        XCTAssertTrue(builderNav.waitForExistence(timeout: 5))

        // Interact with chat pane
        let chatField = app.textFields["Describe a recipe..."]
        XCTAssertTrue(chatField.waitForExistence(timeout: 5))
        chatField.tap()
        chatField.typeText("I want a fruit smoothie recipe")

        let sendButton = app.buttons["Send"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5))
        sendButton.tap()

        // Verify the user message appears
        let userMessage = app.staticTexts["I want a fruit smoothie recipe"]
        XCTAssertTrue(userMessage.waitForExistence(timeout: 5), "User message should appear in chat")

        // Verify the bot response appears
        let botResponse = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "coming soon")
        ).firstMatch
        XCTAssertTrue(botResponse.waitForExistence(timeout: 5), "Bot response should appear")
        screenshot("journey09-chat-exchange")

        // Fill in recipe title in the editor pane
        let titleField = app.textFields["Recipe Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Tropical Fruit Smoothie")

        // Scroll to Save Recipe button if needed
        let saveButton = app.buttons["Save Recipe"]
        if !saveButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        saveButton.tap()
        screenshot("journey09-recipe-saved")

        // Navigate to Recipe Book and find the recipe
        tapMoreTab("Recipe Book")
        let recipeBookNav = app.navigationBars["Recipe Book"]
        XCTAssertTrue(recipeBookNav.waitForExistence(timeout: 5))

        // Search for the recipe
        let searchField = app.searchFields["Search recipes"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Tropical")

        let recipe = app.staticTexts["Tropical Fruit Smoothie"]
        XCTAssertTrue(recipe.waitForExistence(timeout: 5), "Saved recipe should appear in Recipe Book")
        screenshot("journey09-recipe-in-book")
    }

    // MARK: - Journey 10

    /// Read Getting Started guide, search recipes, plan cookies for snack slot.
    func testOnboardingThenSearchAndPlanSnack() {
        app.launch()

        // Go to Help
        tapMoreTab("Help")
        let helpNav = app.navigationBars["Help"]
        XCTAssertTrue(helpNav.waitForExistence(timeout: 5))

        // Tap Getting Started
        let gettingStarted = app.staticTexts["Getting Started"]
        XCTAssertTrue(gettingStarted.waitForExistence(timeout: 5))
        gettingStarted.tap()

        // Verify Getting Started content renders
        let gsNav = app.navigationBars["Getting Started"]
        XCTAssertTrue(gsNav.waitForExistence(timeout: 5))

        let step1 = app.staticTexts["Add Your Recipes"]
        XCTAssertTrue(step1.waitForExistence(timeout: 5), "Getting Started should show step content")
        screenshot("journey10-getting-started")

        // Go to Recipe Book and search for cookies
        tapMoreTab("Recipe Book")
        let recipeBookNav = app.navigationBars["Recipe Book"]
        XCTAssertTrue(recipeBookNav.waitForExistence(timeout: 5))

        let searchField = app.searchFields["Search recipes"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Cookie")

        let cookies = app.staticTexts["Chocolate Chip Cookies"]
        XCTAssertTrue(cookies.waitForExistence(timeout: 5), "Chocolate Chip Cookies should appear in search")
        screenshot("journey10-search-cookies")

        // Go to Calendar and plan cookies in the Snack slot (4th slot, all empty)
        app.tabBars.buttons["Calendar"].tap()
        let calendarNav = app.navigationBars["Calendar"]
        XCTAssertTrue(calendarNav.waitForExistence(timeout: 5))

        // Tap the 4th "Tap to add" button (Snack is the 4th slot)
        let tapToAddButtons = app.buttons.matching(
            NSPredicate(format: "label == %@", "Tap to add")
        )
        let snackButton = tapToAddButtons.element(boundBy: 3)
        XCTAssertTrue(snackButton.waitForExistence(timeout: 5), "Snack slot 'Tap to add' should exist")
        snackButton.tap()

        // Pick recipe from the picker sheet
        let pickerNav = app.navigationBars["Choose Recipe"]
        XCTAssertTrue(pickerNav.waitForExistence(timeout: 5))

        let pickerSearch = app.searchFields["Search recipes"]
        XCTAssertTrue(pickerSearch.waitForExistence(timeout: 5))
        pickerSearch.tap()
        pickerSearch.typeText("Cookie")

        let cookieRow = app.staticTexts["Chocolate Chip Cookies"].firstMatch
        XCTAssertTrue(cookieRow.waitForExistence(timeout: 5))
        cookieRow.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // Verify cookies planned in day view
        XCTAssertTrue(calendarNav.waitForExistence(timeout: 5))
        let planned = app.staticTexts["Chocolate Chip Cookies"]
        XCTAssertTrue(planned.waitForExistence(timeout: 5), "Cookies should appear in Snack section")
        screenshot("journey10-snack-planned")

        // Switch to Week view and verify "1 meal"
        app.buttons["Week"].tap()
        let oneMeal = app.staticTexts["1 meal"]
        XCTAssertTrue(oneMeal.waitForExistence(timeout: 5), "Week view should show '1 meal' for today")
        screenshot("journey10-week-one-meal")
    }
}
