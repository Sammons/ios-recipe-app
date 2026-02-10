import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Recipes coming soon...")
            }
            .navigationTitle("Recipes")
        }
    }
}

#Preview {
    ContentView()
}
