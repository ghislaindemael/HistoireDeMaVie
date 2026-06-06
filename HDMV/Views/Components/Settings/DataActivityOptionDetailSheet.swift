//
//  DataActivityOptionDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 05.06.2026.
//

import SwiftUI
import SwiftData

struct DataActivityOptionDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: DataActivityOptionDetailSheetViewModel
    
    @State private var editingChoiceIndex: Int? = nil
    @State private var isShowingChoiceSheet: Bool = false

    init(option: DataActivityOption, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: DataActivityOptionDetailSheetViewModel(
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
                        Text("Boolean").tag(DataActivityOptionType.boolean)
                        Text("Integer").tag(DataActivityOptionType.integer)
                        Text("Decimal").tag(DataActivityOptionType.decimal)
                        Text("Rating").tag(DataActivityOptionType.rating)
                        Text("Text").tag(DataActivityOptionType.text)
                        Text("Dropdown").tag(DataActivityOptionType.dropdown)
                        Text("Time").tag(DataActivityOptionType.time)
                    }
                }
                
                if viewModel.editor.type == .dropdown {
                    Section("Dropdown Config") {
                        Toggle("Multiselect", isOn: Binding(
                            get: { viewModel.editor.config?.multiselect ?? false },
                            set: { val in
                                if viewModel.editor.config == nil { viewModel.editor.config = DataActivityOptionConfig() }
                                viewModel.editor.config?.multiselect = val
                            }
                        ))
                        
                        
                        Picker("Default Value", selection: Binding(
                            get: { viewModel.editor.config?.defaultValue ?? "" },
                            set: { val in
                                if viewModel.editor.config == nil { viewModel.editor.config = DataActivityOptionConfig() }
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
