//
//  DataLogOptionDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DataLogOptionDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: DataLogOptionDetailSheetViewModel
    
    @State private var editingChoiceIndex: Int? = nil
    @State private var isShowingChoiceSheet: Bool = false

    init(option: DataLogOption, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: DataLogOptionDetailSheetViewModel(
            model: option,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name)
                    TextField("Slug", text: $viewModel.editor.slug)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section("Type") {
                    Picker("Type", selection: $viewModel.editor.type) {
                        Text("Boolean").tag(DataLogOptionType.boolean)
                        Text("Integer").tag(DataLogOptionType.integer)
                        Text("Decimal").tag(DataLogOptionType.decimal)
                        Text("Rating").tag(DataLogOptionType.rating)
                        Text("Text").tag(DataLogOptionType.text)
                        Text("Dropdown").tag(DataLogOptionType.dropdown)
                        Text("Time").tag(DataLogOptionType.time)
                    }
                    
                    Toggle("Replaces Activity Name", isOn: Binding(
                        get: { viewModel.editor.config?.replacesActivityName ?? false },
                        set: { val in
                            if viewModel.editor.config == nil { viewModel.editor.config = DataLogOptionConfig() }
                            viewModel.editor.config?.replacesActivityName = val
                        }
                    ))
                }
                
                if viewModel.editor.type == .dropdown {
                    Section("Dropdown Config") {
                        Toggle("Multiselect", isOn: Binding(
                            get: { viewModel.editor.config?.multiselect ?? false },
                            set: { val in
                                if viewModel.editor.config == nil { viewModel.editor.config = DataLogOptionConfig() }
                                viewModel.editor.config?.multiselect = val
                            }
                        ))
                        
                        
                        Picker("Default Value", selection: Binding(
                            get: { viewModel.editor.config?.defaultValue ?? "" },
                            set: { val in
                                if viewModel.editor.config == nil { viewModel.editor.config = DataLogOptionConfig() }
                                viewModel.editor.config?.defaultValue = val.isEmpty ? nil : val
                            }
                        )) {
                            Text("None").tag("")
                            ForEach(viewModel.editor.config?.choices ?? [], id: \.slug) { choice in
                                Text(choice.label).tag(choice.slug)
                            }
                        }

                        List {
                            ForEach(viewModel.editor.config?.choices?.indices ?? 0..<0, id: \.self) { index in
                                let choice = viewModel.editor.config!.choices![index]
                                Button(action: {
                                    editingChoiceIndex = index
                                    isShowingChoiceSheet = true
                                }) {
                                    HStack {
                                        if let icon = choice.icon, !icon.isEmpty {
                                            Image(systemName: icon)
                                                .frame(width: 24)
                                        }
                                        VStack(alignment: .leading) {
                                            Text(choice.label)
                                                .font(.body)
                                            Text(choice.slug)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if choice.archived == true {
                                            Text("Archived")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .foregroundColor(.primary)
                            }
                            .onDelete { indices in
                                for index in indices {
                                    viewModel.removeChoice(at: index)
                                }
                            }
                        }
                        
                        Button("Add Choice") {
                            editingChoiceIndex = nil
                            isShowingChoiceSheet = true
                        }
                    }
                }
                

                Section("Usage") {
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
                }
                
                Section("Global Mappings") {
                    Toggle("All Transactions", isOn: Binding(
                        get: { viewModel.isForTransaction },
                        set: { viewModel.isForTransaction = $0 }
                    ))
                    Toggle("All Interactions", isOn: Binding(
                        get: { viewModel.isForInteraction },
                        set: { viewModel.isForInteraction = $0 }
                    ))
                    Toggle("All Life Events", isOn: Binding(
                        get: { viewModel.isForLifeEvent },
                        set: { viewModel.isForLifeEvent = $0 }
                    ))
                }
                
                Section("Vehicle Type Mappings") {
                    ForEach(VehicleType.allCases.filter { $0 != .unset }, id: \.self) { type in
                        Toggle(isOn: Binding(
                            get: { viewModel.isForVehicleType(type) },
                            set: { viewModel.setForVehicleType(type, isOn: $0) }
                        )) {
                            type.labelView
                        }
                    }
                }
                
                Section("Conditionals (Optional)") {
                    TextField("Depends On Slug", text: Binding(
                        get: { viewModel.editor.config?.dependsOnSlug ?? "" },
                        set: { val in
                            if viewModel.editor.config == nil { viewModel.editor.config = DataLogOptionConfig() }
                            viewModel.editor.config?.dependsOnSlug = val.isEmpty ? nil : val
                        }
                    ))
                    .autocapitalization(.none)
                    
                    TextField("Show if value is (comma separated)", text: Binding(
                        get: { viewModel.editor.config?.showIfValues?.joined(separator: ", ") ?? "" },
                        set: { val in
                            if viewModel.editor.config == nil { viewModel.editor.config = DataLogOptionConfig() }
                            let values = val.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                            viewModel.editor.config?.showIfValues = values.isEmpty ? nil : values
                        }
                    ))
                    .autocapitalization(.none)
                }

            }
            .navigationTitle("Edit Option")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
            .sheet(isPresented: $isShowingChoiceSheet) {
                let choice = editingChoiceIndex != nil ? viewModel.editor.config?.choices?[editingChoiceIndex!] : nil
                
                ChoiceEditorSheet(
                    initialSlug: choice?.slug ?? "",
                    initialLabel: choice?.label ?? "",
                    initialIcon: choice?.icon ?? "",
                    initialIsArchived: choice?.archived ?? false
                ) { newSlug, newLabel, newIcon, newArchived in
                    if let index = editingChoiceIndex {
                        viewModel.editor.config?.choices?[index].slug = newSlug
                        viewModel.editor.config?.choices?[index].label = newLabel
                        viewModel.editor.config?.choices?[index].icon = newIcon
                        viewModel.editor.config?.choices?[index].archived = newArchived
                    } else {
                        viewModel.addChoice(slug: newSlug, label: newLabel, icon: newIcon)
                        // If it was added as archived
                        if newArchived, let lastIndex = viewModel.editor.config?.choices?.count {
                            viewModel.editor.config?.choices?[lastIndex - 1].archived = true
                        }
                    }
                }
            }
        }
    }
}

struct ChoiceEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let initialSlug: String
    let initialLabel: String
    let initialIcon: String
    let initialIsArchived: Bool
    
    @State private var slug: String = ""
    @State private var label: String = ""
    @State private var icon: String = ""
    @State private var isArchived: Bool = false
    
    var onSave: (String, String, String?, Bool) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section("Details") {
                    TextField("Slug", text: $slug)
                        .autocapitalization(.none)
                    TextField("Label", text: $label)
                    
                    HStack {
                        TextField("SF Symbol Icon (optional)", text: $icon)
                            .autocapitalization(.none)
                        Spacer()
                        if !icon.isEmpty {
                            IconView(iconString: icon)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                
                Section("Status") {
                    Toggle("Archived", isOn: $isArchived)
                }
            }
            .navigationTitle(slug.isEmpty ? "New Choice" : "Edit Choice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(slug, label, icon.isEmpty ? nil : icon, isArchived)
                        dismiss()
                    }
                }
            }
            .onAppear {
                self.slug = initialSlug
                self.label = initialLabel
                self.icon = initialIcon
                self.isArchived = initialIsArchived
            }
        }
    }
}
