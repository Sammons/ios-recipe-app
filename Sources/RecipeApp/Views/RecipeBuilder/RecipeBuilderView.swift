import SwiftData
import SwiftUI

struct RecipeBuilderView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var editorMinimized = false
    @State private var chatMinimized = false

    var body: some View {
        NavigationStack {
            Group {
                if sizeClass == .regular {
                    HStack(spacing: 0) {
                        panes
                    }
                } else {
                    VStack(spacing: 0) {
                        panes
                    }
                }
            }
            .navigationTitle("Recipe Builder")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    @ViewBuilder
    private var panes: some View {
        MinimizablePane(
            title: "Editor",
            icon: "pencil",
            isMinimized: $editorMinimized
        ) {
            RecipeEditorPane()
        }

        Divider()

        MinimizablePane(
            title: "Chat",
            icon: "bubble.left.and.bubble.right",
            isMinimized: $chatMinimized
        ) {
            ChatPane()
        }
    }
}

struct MinimizablePane<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isMinimized: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isMinimized {
            Button {
                withAnimation { isMinimized = false }
            } label: {
                Label(title, systemImage: icon)
                    .font(.caption)
                    .padding(8)
            }
        } else {
            VStack(spacing: 0) {
                HStack {
                    Label(title, systemImage: icon)
                        .font(.subheadline.bold())
                    Spacer()
                    Button {
                        withAnimation { isMinimized = true }
                    } label: {
                        Image(systemName: "minus")
                            .font(.caption)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.bar)

                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct RecipeEditorPane: View {
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var summary = ""
    @State private var recipeType = RecipeType.dinner
    @State private var prepTimeMinutes = 0
    @State private var cookTimeMinutes = 0
    @State private var servings = 1
    @State private var ingredientRows: [IngredientRowData] = []
    @State private var instructions: [String] = [""]

    var body: some View {
        Form {
            Section("Details") {
                TextField("Recipe Title", text: $title)
                TextField("Summary", text: $summary, axis: .vertical)
                    .lineLimit(2...4)
                Picker("Type", selection: $recipeType) {
                    ForEach(RecipeType.allTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            }

            Section("Timing") {
                Stepper("Prep: \(prepTimeMinutes) min", value: $prepTimeMinutes, in: 0...480, step: 5)
                Stepper("Cook: \(cookTimeMinutes) min", value: $cookTimeMinutes, in: 0...480, step: 5)
                Stepper("Servings: \(servings)", value: $servings, in: 1...50)
            }

            Section("Ingredients") {
                ForEach($ingredientRows) { $row in
                    IngredientRowEditor(row: $row, modelContext: modelContext)
                }
                .onDelete { ingredientRows.remove(atOffsets: $0) }
                Button("Add Ingredient", systemImage: "plus.circle") {
                    ingredientRows.append(IngredientRowData())
                }
            }

            Section("Instructions") {
                ForEach($instructions.indices, id: \.self) { index in
                    InstructionStepEditor(stepNumber: index + 1, text: $instructions[index])
                }
                .onDelete { instructions.remove(atOffsets: $0) }
                .onMove { instructions.move(fromOffsets: $0, toOffset: $1) }
                Button("Add Step", systemImage: "plus.circle") {
                    instructions.append("")
                }
            }

            Section {
                Button("Save Recipe", systemImage: "checkmark") {
                    saveRecipe()
                }
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func saveRecipe() {
        let recipe = Recipe(
            title: title.trimmingCharacters(in: .whitespaces),
            summary: summary.trimmingCharacters(in: .whitespaces),
            prepTimeMinutes: prepTimeMinutes,
            cookTimeMinutes: cookTimeMinutes,
            servings: servings,
            recipeType: recipeType,
            instructions: instructions.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        )
        modelContext.insert(recipe)

        for row in ingredientRows where !row.name.trimmingCharacters(in: .whitespaces).isEmpty {
            let ingredient = row.existingIngredient ?? findOrCreateIngredient(name: row.name)
            let ri = RecipeIngredient(
                quantity: row.quantity,
                unit: row.unit,
                notes: row.notes,
                recipe: recipe,
                ingredient: ingredient
            )
            modelContext.insert(ri)
        }

        try? modelContext.save()
        resetForm()
    }

    private func findOrCreateIngredient(name: String) -> Ingredient {
        let lowered = name.lowercased()
        let descriptor = FetchDescriptor<Ingredient>(
            predicate: #Predicate { $0.name == lowered }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let ingredient = Ingredient(name: name)
        modelContext.insert(ingredient)
        return ingredient
    }

    private func resetForm() {
        title = ""
        summary = ""
        recipeType = RecipeType.dinner
        prepTimeMinutes = 0
        cookTimeMinutes = 0
        servings = 1
        ingredientRows = []
        instructions = [""]
    }
}

struct ChatPane: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            text: "I'm your recipe assistant! Describe a dish and I'll help you build a recipe.",
            isUser: false
        ),
    ]
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) {
                    if let last = messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack {
                TextField("Describe a recipe...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { sendMessage() }
                Button("Send", systemImage: "arrow.up.circle.fill") {
                    sendMessage()
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(text: text, isUser: true))
        inputText = ""
        messages.append(
            ChatMessage(
                text:
                    "Recipe AI features coming soon! For now, use the editor pane to build your recipe manually.",
                isUser: false
            )
        )
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            Text(message.text)
                .padding(10)
                .background(message.isUser ? Color.accentColor : Color.gray.opacity(0.15))
                .foregroundStyle(message.isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if !message.isUser { Spacer() }
        }
    }
}
