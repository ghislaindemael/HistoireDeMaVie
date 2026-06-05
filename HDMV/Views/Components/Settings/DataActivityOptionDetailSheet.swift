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
    @State private var newChoiceString: String = ""

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
                        
                        List {
                            ForEach(viewModel.editor.config?.choices ?? [], id: \.self) { choice in
                                Text(choice)
                            }
                            .onDelete { indices in
                                for index in indices {
                                    viewModel.removeChoice(at: index)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("New Choice", text: $newChoiceString)
                            Button("Add") {
                                if !newChoiceString.isEmpty {
                                    viewModel.addChoice(newChoiceString)
                                    newChoiceString = ""
                                }
                            }
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
        }
    }
}
