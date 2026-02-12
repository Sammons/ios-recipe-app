import SwiftData
import SwiftUI

struct IngredientSearchField: View {
    @Binding var text: String
    let modelContext: ModelContext
    var onSelect: ((Ingredient) -> Void)?

    @State private var suggestions: [Ingredient] = []
    @State private var showSuggestions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Ingredient name", text: $text)
                .accessibilityIdentifier("ingredient-field")
                .onChange(of: text) { _, newValue in
                    updateSuggestions(query: newValue)
                }
                .onSubmit {
                    showSuggestions = false
                }

            if showSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { ingredient in
                        Button {
                            text = ingredient.displayName
                            onSelect?(ingredient)
                            showSuggestions = false
                        } label: {
                            HStack {
                                Text(ingredient.displayName)
                                Spacer()
                                Text(ingredient.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func updateSuggestions(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            suggestions = []
            showSuggestions = false
            return
        }
        let lowered = trimmed.lowercased()
        let descriptor = FetchDescriptor<Ingredient>(
            predicate: #Predicate { $0.name.contains(lowered) },
            sortBy: [SortDescriptor(\Ingredient.name)]
        )
        suggestions = (try? modelContext.fetch(descriptor)) ?? []
        showSuggestions = !suggestions.isEmpty
    }
}
