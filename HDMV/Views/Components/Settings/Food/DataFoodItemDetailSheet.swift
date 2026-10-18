import SwiftUI
import SwiftData

struct DataFoodItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DataFoodItem.name) private var allItems: [DataFoodItem]
    
    var item: DataFoodItem
    var modelContext: ModelContext
    
    @State private var editor: DataFoodItemEditor
    @State private var isShowingOptionSelector = false
    @State private var newUnitName = ""
    @State private var newGrams: Double? = nil
    
    private var baseUnitLabel: String {
        let u = (editor.baseUnit ?? editor.parent?.effectiveBaseUnit)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return u == "ml" ? "ml" : "g"
    }
    
    private func pasteServingSizes(_ newSizes: [FoodServingSize]) {
        if editor.servingSizes == nil { editor.servingSizes = [] }
        for size in newSizes {
            editor.servingSizes?.removeAll(where: { $0.unitName.lowercased() == size.unitName.lowercased() })
            editor.servingSizes?.append(size)
        }
    }
    
    private func importParentServingSizes(_ parentSizes: [FoodServingSize]) {
        if editor.servingSizes == nil { editor.servingSizes = [] }
        for size in parentSizes {
            if !(editor.servingSizes?.contains(where: { $0.unitName.lowercased() == size.unitName.lowercased() }) ?? false) {
                editor.servingSizes?.append(size)
            }
        }
    }
    
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
                    
                    TextField("Details / Notes", text: Binding(
                        get: { editor.details ?? "" },
                        set: { val in editor.details = val.isEmpty ? nil : val }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    
                    TextField("Base Unit (g or ml)", text: Binding(
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
                
                Section("Macros (per 100 base units)") {
                    NavigationLink(destination: FoodMacrosEditView(
                        macros: $editor.macros,
                        subtitle: "Per 100 \(editor.baseUnit ?? "base units")"
                    )) {
                        FoodMacrosSummaryView(macros: editor.macros)
                    }
                }
                
                Section {
                    if let sizes = editor.servingSizes {
                        ForEach(sizes, id: \.unitName) { size in
                            HStack {
                                Text(size.unitName)
                                Spacer()
                                Text("\(size.gramsPerUnit, specifier: "%.1f") \(baseUnitLabel)")
                            }
                        }
                        .onDelete { indices in
                            editor.servingSizes?.remove(atOffsets: indices)
                            if editor.servingSizes?.isEmpty == true {
                                editor.servingSizes = nil
                            }
                        }
                    }
                    
                    HStack {
                        TextField("New Unit (e.g. slice)", text: $newUnitName)
                        TextField(baseUnitLabel == "ml" ? "ml" : "Grams", value: $newGrams, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Button("Add") {
                            if !newUnitName.isEmpty, let grams = newGrams, grams > 0 {
                                if editor.servingSizes == nil { editor.servingSizes = [] }
                                editor.servingSizes?.removeAll(where: { $0.unitName.lowercased() == newUnitName.lowercased() })
                                editor.servingSizes?.append(FoodServingSize(unitName: newUnitName, gramsPerUnit: grams))
                                newUnitName = ""
                                newGrams = nil
                            }
                        }
                        .disabled(newUnitName.isEmpty || (newGrams ?? 0) <= 0)
                    }
                } header: {
                    HStack {
                        Text("Custom Serving Sizes")
                        Spacer()
                        Menu {
                            if let sizes = editor.servingSizes, !sizes.isEmpty {
                                Button {
                                    FoodClipboardManager.copy(servingSizes: sizes)
                                } label: {
                                    Label("Copy Serving Sizes", systemImage: "doc.on.doc")
                                }
                            }
                            if FoodClipboardManager.hasServingSizes {
                                Button {
                                    if let pasted = FoodClipboardManager.getServingSizes() {
                                        pasteServingSizes(pasted)
                                    }
                                } label: {
                                    Label("Paste Serving Sizes", systemImage: "doc.on.clipboard")
                                }
                            }
                            if let parentSizes = editor.parent?.effectiveServingSizes, !parentSizes.isEmpty {
                                Button {
                                    importParentServingSizes(parentSizes)
                                } label: {
                                    Label("Copy from Parent (\(editor.parent?.name ?? "Parent"))", systemImage: "arrow.down.doc")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.subheadline)
                        }
                    }
                }
                
                if let parentSizes = editor.parent?.effectiveServingSizes, !parentSizes.isEmpty {
                    let unoverridden = parentSizes.filter { pSize in
                        !(editor.servingSizes ?? []).contains(where: { $0.unitName.lowercased() == pSize.unitName.lowercased() })
                    }
                    if !unoverridden.isEmpty {
                        Section("Inherited from \(editor.parent?.name ?? "Parent")") {
                            ForEach(unoverridden, id: \.unitName) { size in
                                HStack {
                                    Text(size.unitName)
                                    Spacer()
                                    Text("\(size.gramsPerUnit, specifier: "%.1f") \(baseUnitLabel)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Button("Copy All to Custom") {
                                importParentServingSizes(parentSizes)
                            }
                            .font(.footnote)
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
