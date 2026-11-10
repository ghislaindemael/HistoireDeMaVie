import SwiftUI
import SwiftData

struct DataFoodItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DataFoodItem.name) private var allItems: [DataFoodItem]
    
    var item: DataFoodItem
    var modelContext: ModelContext
    
    @StateObject var viewModel: DataFoodItemDetailSheetViewModel
    @State private var isShowingOptionSelector = false
    @State private var newUnitName = ""
    @State private var newGrams: Double? = nil
    
    private var baseUnitLabel: String {
        let u = (viewModel.editor.baseUnit ?? viewModel.editor.parent?.effectiveBaseUnit)?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return u == "ml" ? "ml" : "g"
    }
    
    private func pasteServingSizes(_ newSizes: [FoodServingSize]) {
        if viewModel.editor.servingSizes == nil { viewModel.editor.servingSizes = [] }
        for size in newSizes {
            viewModel.editor.servingSizes?.removeAll(where: { $0.unitName.lowercased() == size.unitName.lowercased() })
            viewModel.editor.servingSizes?.append(size)
        }
    }
    
    private func importParentServingSizes(_ parentSizes: [FoodServingSize]) {
        if viewModel.editor.servingSizes == nil { viewModel.editor.servingSizes = [] }
        for size in parentSizes {
            if !(viewModel.editor.servingSizes?.contains(where: { $0.unitName.lowercased() == size.unitName.lowercased() }) ?? false) {
                viewModel.editor.servingSizes?.append(size)
            }
        }
    }
    
    init(item: DataFoodItem, modelContext: ModelContext) {
        self.item = item
        self.modelContext = modelContext
        self._viewModel = StateObject(wrappedValue: DataFoodItemDetailSheetViewModel(model: item, modelContext: modelContext))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Name", text: $viewModel.editor.name)
                    
                    TextField("Details / Notes", text: Binding(
                        get: { viewModel.editor.details ?? "" },
                        set: { val in viewModel.editor.details = val.isEmpty ? nil : val }
                    ), axis: .vertical)
                    .lineLimit(2...4)
                    
                    TextField("Base Unit (g or ml)", text: Binding(
                        get: { viewModel.editor.baseUnit ?? "" },
                        set: { val in viewModel.editor.baseUnit = val.isEmpty ? nil : val }
                    ))
                    .autocapitalization(.none)
                }
                
                Section("Hierarchy") {
                    NavigationLink(destination: GenericTreeSelectorView(
                        items: allItems.filter { $0.parent == nil },
                        childrenKeyPath: \.optionalChildren,
                        selection: $viewModel.editor.parent,
                        title: "Select Parent",
                        noneButtonText: "No Parent"
                    )) {
                        HStack {
                            Text("Parent Item")
                            Spacer()
                            if let p = viewModel.editor.parent {
                                Text(p.name).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if viewModel.editor.parent != nil {
                        Button("Remove from Parent", role: .destructive) {
                            viewModel.editor.parent = nil
                            viewModel.editor.parentId = nil
                        }
                    }
                }
                
                Section("Macros (per 100 base units)") {
                    NavigationLink(destination: FoodMacrosEditView(
                        macros: $viewModel.editor.macros,
                        subtitle: "Per 100 \(viewModel.editor.baseUnit ?? "base units")"
                    )) {
                        FoodMacrosSummaryView(macros: viewModel.editor.macros)
                    }
                }
                
                Section {
                    if let sizes = viewModel.editor.servingSizes {
                        ForEach(sizes, id: \.unitName) { size in
                            HStack {
                                Text(size.unitName)
                                Spacer()
                                Text(String(format: "%.1f", size.gramsPerUnit) + " \(baseUnitLabel)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { indices in
                            viewModel.editor.servingSizes?.remove(atOffsets: indices)
                        }
                    }
                    
                    HStack {
                        TextField("Unit Name (e.g. piece, cup)", text: $newUnitName)
                        TextField("\(baseUnitLabel)", value: $newGrams, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                        
                        Button {
                            guard !newUnitName.isEmpty, let grams = newGrams else { return }
                            let newSize = FoodServingSize(unitName: newUnitName, gramsPerUnit: grams)
                            if viewModel.editor.servingSizes == nil { viewModel.editor.servingSizes = [] }
                            viewModel.editor.servingSizes?.append(newSize)
                            newUnitName = ""
                            newGrams = nil
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newUnitName.isEmpty || newGrams == nil)
                    }
                } header: {
                    Text("Serving Sizes")
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add custom units (e.g., 1 biscuit = 15g).")
                        
                        HStack(spacing: 8) {
                            if FoodClipboardManager.hasServingSizes, let sizes = FoodClipboardManager.getServingSizes() {
                                Button {
                                    pasteServingSizes(sizes)
                                } label: {
                                    Label("Paste (\(sizes.count))", systemImage: "doc.on.clipboard")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            
                            if let pSizes = viewModel.editor.parent?.servingSizes, !pSizes.isEmpty {
                                Button {
                                    importParentServingSizes(pSizes)
                                } label: {
                                    Label("Import from Parent (\(pSizes.count))", systemImage: "arrow.down.doc")
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding(.top, 4)
                        
                        // Inherited Preview
                        if let p = viewModel.editor.parent, let pSizes = p.servingSizes, !pSizes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Inherited from \(p.name):")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 4)
                                
                                ForEach(pSizes, id: \.unitName) { size in
                                    let isOverridden = viewModel.editor.servingSizes?.contains(where: { $0.unitName.lowercased() == size.unitName.lowercased() }) ?? false
                                    
                                    HStack {
                                        Text("• \(size.unitName)")
                                        Spacer()
                                        Text(String(format: "%.1f", size.gramsPerUnit) + " \(baseUnitLabel)")
                                        if isOverridden {
                                            Text("(overridden)")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(isOverridden ? .tertiary : .secondary)
                                }
                            }
                            .padding(8)
                            .background(Color.secondaryBackground)
                            .cornerRadius(6)
                        }
                    }
                }
                
                UsageSectionView(isCached: $viewModel.editor.cache, isArchived: $viewModel.editor.archived)
                
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
                viewModel.onDone()
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
