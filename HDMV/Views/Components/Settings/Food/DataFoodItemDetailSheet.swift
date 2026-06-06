import SwiftUI
import SwiftData

struct DataFoodItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DataFoodItem.name) private var allItems: [DataFoodItem]
    
    var item: DataFoodItem
    var modelContext: ModelContext
    
    @State private var editor: DataFoodItemEditor
    
    init(item: DataFoodItem, modelContext: ModelContext) {
        self.item = item
        self.modelContext = modelContext
        self._editor = State(initialValue: DataFoodItemEditor(from: item))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $editor.name)
                    
                    TextField("Base Unit (e.g. g, ml, cl)", text: Binding(
                        get: { editor.baseUnit ?? "" },
                        set: { val in editor.baseUnit = val.isEmpty ? nil : val }
                    ))
                    .autocapitalization(.none)
                }
                
                Section("Hierarchy") {
                    NavigationLink(destination: GenericTreeSelectorView(
                        items: allItems.filter { $0.parent == nil },
                        childrenKeyPath: \.optionalChildren,
                        selection: $editor.parent,
                        title: "Select Parent",
                        noneButtonText: "No Parent"
                    )) {
                        HStack {
                            Text("Parent Item")
                            Spacer()
                            if let p = editor.parent {
                                Text(p.name).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if editor.parent != nil {
                        Button("Remove from Parent", role: .destructive) {
                            editor.parent = nil
                            editor.parentId = nil
                        }
                    }
                }
                
                Section("Usage") {
                    Toggle("Cached", isOn: $editor.cache)
                    Toggle("Archived", isOn: $editor.archived)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                editor.apply(to: item)
                item.syncStatus = .unsynced
                try? modelContext.save()
            }
        }
    }
}
