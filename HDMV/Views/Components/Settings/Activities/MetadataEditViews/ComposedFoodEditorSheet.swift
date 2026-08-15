import SwiftUI
import SwiftData

struct ComposedFoodEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var item: ComposedFood
    
    var body: some View {
        NavigationStack {
            ComposedFoodEditorForm(item: $item)
                .navigationTitle("Edit Food")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            FoodClipboardManager.copy(food: item)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                }
        }
    }
}

struct ComposedFoodEditorForm: View {
    @Binding var item: ComposedFood
    
    @Query private var foodItems: [DataFoodItem]
    
    @State private var showingItemSelector = false
    
    private var availableUnits: [String] {
        var units = ["g", "ml"]
        if let firstItem = foodItems.first, let servingSizes = firstItem.servingSizes {
            units.append(contentsOf: servingSizes.map { $0.unitName })
        }
        return units
    }
    
    private func macroBinding(for keyPath: WritableKeyPath<DataFoodItemMacros, Double?>) -> Binding<Double?> {
        Binding<Double?>(
            get: { item.snapshottedMacros?[keyPath: keyPath] },
            set: { newValue in
                if item.snapshottedMacros == nil { item.snapshottedMacros = DataFoodItemMacros() }
                item.snapshottedMacros?[keyPath: keyPath] = newValue
            }
        )
    }
    
    init(item: Binding<ComposedFood>) {
        self._item = item
        
        if let rid = item.wrappedValue.foodItemRid {
            let predicate = #Predicate<DataFoodItem> { $0.rid == rid }
            _foodItems = Query(filter: predicate)
        } else {
            let predicate = #Predicate<DataFoodItem> { _ in false }
            _foodItems = Query(filter: predicate)
        }
    }
    
    var body: some View {
        Form {
            Section("Identity") {
                if item.foodItemRid == nil {
                    TextField("Food Name", text: Binding(
                        get: { item.rawText ?? "" },
                        set: { item.rawText = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.headline)
                } else {
                    Text(item.rawText ?? "Unknown Item")
                        .font(.headline)
                }
                
                Picker("Course", selection: Binding(
                    get: { item.course ?? .entree },
                    set: { item.course = $0 }
                )) {
                    ForEach(CourseType.allCases) { course in
                        Text(course.rawValue).tag(course)
                    }
                }
            }
            
            Section("Quantity") {
                HStack {
                    TextField("Amount", value: Binding(
                        get: { item.quantity ?? 0 },
                        set: { item.quantity = $0 == 0 ? nil : $0 }
                    ), format: .number)
                    .keyboardType(.decimalPad)
                    
                    Picker("Unit", selection: Binding(
                        get: { item.unit ?? "g" },
                        set: { item.unit = $0 }
                    )) {
                        ForEach(availableUnits, id: \.self) { unit in
                            Text(unit).tag(unit as String?)
                        }
                    }
                }
            }
            
            Section("Custom Macros") {
                HStack { Text("Calories"); Spacer(); TextField("kcal", value: macroBinding(for: \.calories), format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                HStack { Text("Protein"); Spacer(); TextField("g", value: macroBinding(for: \.protein), format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                HStack { Text("Carbs"); Spacer(); TextField("g", value: macroBinding(for: \.carbs), format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                HStack { Text("Fat"); Spacer(); TextField("g", value: macroBinding(for: \.fat), format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                
                DisclosureGroup("Extended Macros") {
                    HStack { Text("Fiber"); Spacer(); TextField("g", value: macroBinding(for: \.fiber), format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Sugar"); Spacer(); TextField("g", value: macroBinding(for: \.sugar), format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Saturated Fat"); Spacer(); TextField("g", value: macroBinding(for: \.saturatedFat), format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Sodium"); Spacer(); TextField("mg", value: macroBinding(for: \.sodium), format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { Text("Alcohol"); Spacer(); TextField("g", value: macroBinding(for: \.alcohol), format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                }
            }
            
            if let foodItem = foodItems.first, let mappings = foodItem.optionMappings, !mappings.isEmpty {
                let sortedMappings = mappings.sorted(by: { $0.priority < $1.priority })
                Section("Options") {
                    ForEach(sortedMappings) { mapping in
                        if let option = mapping.foodOption {
                            let optionBinding = Binding<String>(
                                get: { item.options?[option.slug] ?? "" },
                                set: { newValue in
                                    if item.options == nil { item.options = [:] }
                                    if newValue.isEmpty {
                                        item.options?[option.slug] = nil
                                    } else {
                                        item.options?[option.slug] = newValue
                                    }
                                }
                            )
                            
                            switch option.typeRaw {
                            case "boolean":
                                Toggle(option.name, isOn: Binding(
                                    get: { optionBinding.wrappedValue == "true" },
                                    set: { optionBinding.wrappedValue = $0 ? "true" : "false" }
                                ))
                            case "dropdown":
                                Picker(option.name, selection: optionBinding) {
                                    Text("None").tag("")
                                    if let values = option.enumValues {
                                        ForEach(values, id: \.self) { val in
                                            Text(val).tag(val)
                                        }
                                    }
                                }
                            default:
                                TextField(option.name, text: optionBinding)
                            }
                        }
                    }
                }
            }
            
            if let children = item.children, !children.isEmpty {
                Section("Ingredients") {
                    ForEach(children.indices, id: \.self) { idx in
                        NavigationLink(destination: ComposedFoodEditorForm(item: Binding(
                            get: { item.children![idx] },
                            set: { item.children![idx] = $0 }
                        ))
                        .navigationTitle(item.children![idx].rawText ?? "Ingredient")
                        ) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(children[idx].rawText ?? "Unknown Food")
                                        .foregroundColor(.primary)
                                    if let qty = children[idx].quantity {
                                        Text(String(format: "%.1f", qty) + " " + (children[idx].unit ?? ""))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .onDelete { indices in
                        item.children?.remove(atOffsets: indices)
                        if item.children?.isEmpty == true {
                            item.children = nil
                        }
                    }
                }
            }
            
            Section {
                Button("Add Ingredient") {
                    showingItemSelector = true
                }
            }
        }
        .sheet(isPresented: $showingItemSelector) {
            FoodItemSelectorSheet(course: nil) { newFood in
                if item.children == nil {
                    item.children = []
                }
                item.children?.append(newFood)
            }
        }
    }
}
