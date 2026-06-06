import SwiftUI
import SwiftData

struct DataFoodRecipeDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var item: DataFoodRecipe
    var modelContext: ModelContext
    
    @State private var editor: DataFoodRecipeEditor
    
    init(item: DataFoodRecipe, modelContext: ModelContext) {
        self.item = item
        self.modelContext = modelContext
        self._editor = State(initialValue: DataFoodRecipeEditor(from: item))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $editor.name)
                }
                Section("Usage") {
                    Toggle("Cached", isOn: $editor.cache)
                    Toggle("Archived", isOn: $editor.archived)
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                editor.apply(to: item)
                item.syncStatus = .unsynced
                try? modelContext.save()
            }
        }
    }
}
