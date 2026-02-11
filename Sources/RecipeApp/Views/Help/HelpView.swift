import SwiftUI

struct HelpView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Getting Started") {
                        GettingStartedView()
                    }
                    NavigationLink("Privacy") {
                        PrivacyView()
                    }
                    NavigationLink("About") {
                        AboutView()
                    }
                }

                Section("Quick Tips") {
                    DisclosureGroup("Adding Recipes") {
                        Text(
                            "Use the Recipe Book tab to add, edit, and organize your recipes. "
                                + "Each recipe has ingredients with quantities and step-by-step instructions."
                        )
                    }

                    DisclosureGroup("Meal Planning") {
                        Text(
                            "Switch to the Calendar tab to plan meals for any day. "
                                + "Choose Day, Week, or Month view to see your plan at different scales."
                        )
                    }

                    DisclosureGroup("Shopping Lists") {
                        Text(
                            "The Shopping List tab can auto-generate a list from your meal plan. "
                                + "It subtracts what you already have in your Inventory. "
                                + "Check items off as you shop — they'll be added to your inventory."
                        )
                    }

                    DisclosureGroup("Inventory Tracking") {
                        Text(
                            "Use the Inventory tab to track what ingredients you have at home. "
                                + "The app uses this to filter recipes you can cook now "
                                + "and generate accurate shopping lists."
                        )
                    }

                    DisclosureGroup("Recipe Builder") {
                        Text(
                            "The Recipe Builder tab offers a two-pane editor. "
                                + "Use the chat pane for recipe ideas (AI features coming soon) "
                                + "and the editor pane to build the recipe."
                        )
                    }
                }
            }
            .navigationTitle("Help")
        }
    }
}

struct GettingStartedView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                step(1, "Add Your Recipes",
                    "Go to the Recipe Book tab and tap + to create your first recipe. "
                        + "Add ingredients, quantities, and instructions.")

                step(2, "Plan Your Meals",
                    "Use the Calendar tab to assign recipes to meal slots for each day.")

                step(3, "Generate Shopping List",
                    "The Shopping List tab aggregates ingredients from your planned meals "
                        + "and subtracts what's in your inventory.")

                step(4, "Track Inventory",
                    "Mark items as purchased in your shopping list to add them to inventory. "
                        + "Or add items manually in the Inventory tab.")

                step(5, "Cook & Complete",
                    "When you come back to the app after a meal, you'll be prompted to mark "
                        + "it as completed. This automatically deducts ingredients from inventory.")
            }
            .padding()
        }
        .navigationTitle("Getting Started")
    }

    private func step(_ number: Int, _ title: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PrivacyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Privacy Matters")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(
                    "All your data — recipes, meal plans, shopping lists, and inventory — "
                        + "is stored locally on your device using SwiftData."
                )

                Text(
                    "No data is sent to any server. No account is required. "
                        + "No analytics or tracking of any kind."
                )

                Text(
                    "Your data is included in your device backups (iCloud or local) "
                        + "so you won't lose it when upgrading your phone."
                )

                Text("Data Collection")
                    .font(.headline)
                    .padding(.top)

                Text("This app collects zero data. Period.")
            }
            .padding()
        }
        .navigationTitle("Privacy")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            Text("Recipe App")
                .font(.title)
                .fontWeight(.bold)

            Text("Plan meals, track ingredients, cook with confidence.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Version 1.0")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding()
        .navigationTitle("About")
    }
}
