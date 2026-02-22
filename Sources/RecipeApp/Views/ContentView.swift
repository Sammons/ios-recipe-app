import SwiftData
import SwiftUI

enum AppTab: CaseIterable {
    case calendar
    case recipeBook
    case shoppingList
    case inventory
    case recipeBuilder
    case preferences
    case help

    var tabLabel: String {
        switch self {
        case .calendar: "Calendar"
        case .recipeBook: "Recipes"
        case .shoppingList: "List"
        case .inventory: "Pantry"
        case .recipeBuilder: "Builder"
        case .preferences: "Prefs"
        case .help: "Help"
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .calendar: "Calendar"
        case .recipeBook: "Recipe Book"
        case .shoppingList: "Shopping List"
        case .inventory: "Inventory"
        case .recipeBuilder: "Recipe Builder"
        case .preferences: "Preferences"
        case .help: "Help"
        }
    }

    var icon: String {
        switch self {
        case .calendar: "calendar"
        case .recipeBook: "book"
        case .shoppingList: "cart"
        case .inventory: "refrigerator"
        case .recipeBuilder: "hammer"
        case .preferences: "gear"
        case .help: "questionmark.circle"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab: AppTab = .calendar
    @State private var didSeed = false

    var body: some View {
        TabView(selection: $selectedTab) {
            CalendarView()
                .tag(AppTab.calendar)
                .tabItem {
                    Label(AppTab.calendar.tabLabel, systemImage: AppTab.calendar.icon)
                        .accessibilityLabel(AppTab.calendar.accessibilityLabel)
                }

            RecipeBookView()
                .tag(AppTab.recipeBook)
                .tabItem {
                    Label(AppTab.recipeBook.tabLabel, systemImage: AppTab.recipeBook.icon)
                        .accessibilityLabel(AppTab.recipeBook.accessibilityLabel)
                }

            ShoppingListView()
                .tag(AppTab.shoppingList)
                .tabItem {
                    Label(AppTab.shoppingList.tabLabel, systemImage: AppTab.shoppingList.icon)
                        .accessibilityLabel(AppTab.shoppingList.accessibilityLabel)
                }

            InventoryView()
                .tag(AppTab.inventory)
                .tabItem {
                    Label(AppTab.inventory.tabLabel, systemImage: AppTab.inventory.icon)
                        .accessibilityLabel(AppTab.inventory.accessibilityLabel)
                }

            RecipeBuilderView()
                .tag(AppTab.recipeBuilder)
                .tabItem {
                    Label(AppTab.recipeBuilder.tabLabel, systemImage: AppTab.recipeBuilder.icon)
                        .accessibilityLabel(AppTab.recipeBuilder.accessibilityLabel)
                }

            PreferencesView()
                .tag(AppTab.preferences)
                .tabItem {
                    Label(AppTab.preferences.tabLabel, systemImage: AppTab.preferences.icon)
                        .accessibilityLabel(AppTab.preferences.accessibilityLabel)
                }

            HelpView()
                .tag(AppTab.help)
                .tabItem {
                    Label(AppTab.help.tabLabel, systemImage: AppTab.help.icon)
                        .accessibilityLabel(AppTab.help.accessibilityLabel)
                }
        }
        .onAppear {
            if !didSeed && AppFlags.shouldSeed {
                SeedData.seedIfEmpty(context: modelContext)
                didSeed = true
            }
        }
    }
}
