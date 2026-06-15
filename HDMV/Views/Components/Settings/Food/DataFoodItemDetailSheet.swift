import SwiftUI
import SwiftData

struct DataFoodItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DataFoodItem.name) private var allItems: [DataFoodItem]
    
    var item: DataFoodItem
    var modelContext: ModelContext
    
    @State private var editor: DataFoodItemEditor
    @State private var isShowingOptionSelector = false
    
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
                
                Section("Custom Options") {
                    let sortedMappings = (item.optionMappings ?? []).sorted { 
                        if $0.priority == $1.priority {
                            return ($0.foodOption?.slug ?? "") < ($1.foodOption?.slug ?? "")
                        }
                        return $0.priority < $1.priority 
                    }
                    
                    List {
                        ForEach(sortedMappings) { mapping in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(mapping.foodOption?.name ?? "Unknown Option")
                                        .font(.headline)
                                    Spacer()
                                    Text("Priority: \(mapping.priority)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onMove { indices, newOffset in
                            var mappings = sortedMappings
                            mappings.move(fromOffsets: indices, toOffset: newOffset)
                            for (index, mapping) in mappings.enumerated() {
                                mapping.priority = index
                                mapping.markAsModified()
                            }
                        }
                        .onDelete { indices in
                            for index in indices {
                                let mapping = sortedMappings[index]
                                modelContext.delete(mapping)
                                item.optionMappings?.removeAll { $0.id == mapping.id }
                            }
                        }
                    }
                    
                    Button("Add Option") {
                        isShowingOptionSelector = true
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                editor.apply(to: item)
                item.markAsModified()
                try? modelContext.save()
            }
            .sheet(isPresented: $isShowingOptionSelector) {
                DataFoodOptionSelectorView { selectedOption in
                    let newMapping = DataFoodOptionMapping(
                        priority: item.optionMappings?.count ?? 0,
                        syncStatus: .unsynced
                    )
                    newMapping.foodItem = item
                    newMapping.foodOption = selectedOption
                    newMapping.foodItemRid = item.rid
                    newMapping.foodOptionRid = selectedOption.rid
                    modelContext.insert(newMapping)
                    if item.optionMappings == nil {
                        item.optionMappings = []
                    }
                    item.optionMappings?.append(newMapping)
                }
            }
        }
    }
}
