import SwiftData
import SwiftUI

struct ShoppingListView: View {
    @Query(sort: \ShoppingListItem.addedAt) private var items: [ShoppingListItem]
    @Query private var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddItem = false
    @State private var editingItem: ShoppingListItem?
    @State private var showChecked = false
    @State private var didEnsurePrefs = false

    private let lookaheadQuickOptions = [3, 7, 14, 30]

    private var uncheckedItems: [ShoppingListItem] {
        items.filter { !$0.isChecked }
    }

    private var checkedItems: [ShoppingListItem] {
        items.filter { $0.isChecked }
    }

    private var groupedUnchecked: [(String, [ShoppingListItem])] {
        let grouped = Dictionary(grouping: uncheckedItems) { item in
            item.ingredient?.category ?? IngredientCategory.other
        }
        return IngredientCategory.allCategories.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            let sorted = items.sorted(by: shoppingItemOrder)
            return (category, sorted)
        }
    }

    private var lookaheadDays: Int {
        preferences.first?.shoppingLookaheadDays ?? 7
    }

    private var lookaheadEndDateText: String {
        let endDate = DateHelpers.addDays(lookaheadDays, to: DateHelpers.startOfDay(Date()))
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: endDate)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Plan Window") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Next \(lookaheadDays) days (through \(lookaheadEndDateText))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("shopping-lookahead-summary")

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(lookaheadQuickOptions, id: \.self) { days in
                                    Button {
                                        setLookahead(days)
                                    } label: {
                                        Text("\(days)d")
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(
                                                        lookaheadDays == days
                                                            ? Color.accentColor
                                                            : Color.secondary.opacity(0.15)
                                                    )
                                            )
                                            .foregroundStyle(
                                                lookaheadDays == days ? Color.white : Color.primary
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityIdentifier("shopping-lookahead-\(days)")
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if items.isEmpty {
                    ContentUnavailableView(
                        "Shopping List Empty",
                        systemImage: "cart",
                        description: Text(
                            "Generate a list from your meal plan or add items manually."
                        )
                    )

                    Button("Generate Next \(lookaheadDays) Days", systemImage: "wand.and.stars") {
                        generateList()
                    }
                    .accessibilityIdentifier("shopping-generate-empty-state")
                } else {
                    ForEach(groupedUnchecked, id: \.0) { category, categoryItems in
                        Section(category) {
                            ForEach(categoryItems) { item in
                                ShoppingItemRow(item: item) {
                                    checkOff(item)
                                } onEdit: {
                                    editingItem = item
                                }
                            }
                        }
                    }

                    if !checkedItems.isEmpty {
                        Section {
                            DisclosureGroup(
                                "Purchased (\(checkedItems.count))",
                                isExpanded: $showChecked
                            ) {
                                ForEach(checkedItems) { item in
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text(item.ingredient?.displayName ?? "Unknown")
                                            .strikethrough()
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("\(item.quantity.formatted()) \(item.unit)")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }

                                Button("Clear Purchased", systemImage: "trash", role: .destructive) {
                                    clearChecked()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Generate", systemImage: "wand.and.stars") {
                        generateList()
                    }
                    .accessibilityIdentifier("shopping-generate-toolbar")
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Add", systemImage: "plus") {
                        showingAddItem = true
                    }
                    .accessibilityIdentifier("shopping-add-toolbar")
                }
            }
            .sheet(isPresented: $showingAddItem) {
                ShoppingListAddView()
            }
            .sheet(item: $editingItem) { item in
                ShoppingListAddView(itemToEdit: item)
            }
            .onAppear {
                ensurePreferences()
            }
        }
    }

    private func checkOff(_ item: ShoppingListItem) {
        item.isChecked = true
        if let ingredient = item.ingredient {
            addToInventory(ingredient: ingredient, quantity: item.quantity, unit: item.unit)
        }
    }

    private func addToInventory(ingredient: Ingredient, quantity: Double, unit: String) {
        if let existing = ingredient.inventoryItem {
            existing.quantity += quantity
            existing.lastUpdated = Date()
        } else {
            let inventoryItem = InventoryItem(
                quantity: quantity,
                unit: unit,
                ingredient: ingredient
            )
            modelContext.insert(inventoryItem)
        }
    }

    private func clearChecked() {
        for item in checkedItems {
            modelContext.delete(item)
        }
    }

    private func generateList() {
        ShoppingListGenerator.generate(context: modelContext, lookaheadDays: lookaheadDays)
    }

    private func setLookahead(_ days: Int) {
        if let existing = preferences.first {
            existing.shoppingLookaheadDays = days
        } else {
            modelContext.insert(UserPreferences(shoppingLookaheadDays: days))
        }
    }

    private func ensurePreferences() {
        guard !didEnsurePrefs else { return }
        didEnsurePrefs = true
        if preferences.isEmpty {
            modelContext.insert(UserPreferences())
            try? modelContext.save()
        }
    }

    private func shoppingItemOrder(_ lhs: ShoppingListItem, _ rhs: ShoppingListItem) -> Bool {
        let lhsName = lhs.ingredient?.displayName ?? lhs.ingredient?.name ?? ""
        let rhsName = rhs.ingredient?.displayName ?? rhs.ingredient?.name ?? ""
        let nameComparison = lhsName.localizedCaseInsensitiveCompare(rhsName)
        if nameComparison != .orderedSame {
            return nameComparison == .orderedAscending
        }

        let lhsUnit = UnitTextNormalizer.normalize(lhs.unit)
        let rhsUnit = UnitTextNormalizer.normalize(rhs.unit)
        let unitComparison = lhsUnit.localizedCaseInsensitiveCompare(rhsUnit)
        if unitComparison != .orderedSame {
            return unitComparison == .orderedAscending
        }

        return lhs.addedAt < rhs.addedAt
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingListItem
    let onCheck: () -> Void
    let onEdit: () -> Void

    @State private var showDetail = false

    private var hasRecipeDetail: Bool {
        item.isAutoGenerated && item.recipeQuantity > 0 && !item.recipeUnit.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button {
                    onCheck()
                } label: {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Button {
                    onEdit()
                } label: {
                    HStack {
                        Text(item.ingredient?.displayName ?? "Unknown")
                        Spacer()
                        Text("\(item.quantity.formatted()) \(item.unit)")
                            .foregroundStyle(.secondary)
                        if hasRecipeDetail {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showDetail.toggle()
                                }
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        } else if item.isAutoGenerated {
                            Image(systemName: "wand.and.stars")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            if showDetail && hasRecipeDetail {
                Text("\(item.recipeQuantity.formatted()) \(item.recipeUnit) needed from recipes")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 32)
                    .padding(.top, 4)
            }
        }
    }
}
