import SwiftUI
import SwiftData

struct DataFoodOptionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    var item: DataFoodOption
    var modelContext: ModelContext
    
    @State private var editor: DataFoodOptionEditor
    
    init(item: DataFoodOption, modelContext: ModelContext) {
        self.item = item
        self.modelContext = modelContext
        self._editor = State(initialValue: DataFoodOptionEditor(from: item))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $editor.name)
                    TextField("Slug", text: $editor.slug)
                        .autocapitalization(.none)
                }
                
                Section("Type") {
                    Picker("Type", selection: $editor.typeRaw) {
                        Text("Boolean").tag("boolean")
                        Text("Integer").tag("integer")
                        Text("Decimal").tag("decimal")
                        Text("Text").tag("text")
                        Text("Dropdown").tag("dropdown")
                    }
                    Toggle("Is Required", isOn: $editor.isRequired)
                }
                
                Section("Usage") {
                    Toggle("Cached", isOn: $editor.cache)
                    Toggle("Archived", isOn: $editor.archived)
                }
            }
            .navigationTitle("Edit Option")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                editor.apply(to: item)
                item.markAsModified()
                try? modelContext.save()
            }
        }
    }
}
