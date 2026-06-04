//
//  DataMediaItemDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//

import SwiftUI
import SwiftData

struct DataMediaItemDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: DataMediaItemDetailSheetViewModel
    
    @Query var itemsTree: [DataMediaItem]

    init(item: DataMediaItem, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: DataMediaItemDetailSheetViewModel(
            model: item,
            modelContext: modelContext
        ))
        let predicate = #Predicate<DataMediaItem> { $0.parent == nil }
        _itemsTree = Query(filter: predicate, sort: \.name)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name)
                    
                    HStack {
                        TextField("Icon", text: Binding(
                            get: { viewModel.editor.icon ?? "" },
                            set: { viewModel.editor.icon = $0.isEmpty ? nil : $0 }
                        ))
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        
                        Spacer()
                        IconView(iconString: viewModel.editor.icon ?? "")
                    }
                    
                    NavigationLink(destination: ParentCatalogueSelector(
                        catalogueItems: itemsTree,
                        selectedParent: $viewModel.editor.parent)
                    ) {
                        HStack {
                            Text("Parent Item")
                            Spacer()
                            if let parentName = viewModel.editor.parent?.name {
                                Text(parentName).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Metadata") {
                    Stepper("Untracked Consumptions: \(viewModel.editor.untrackedConsumptions)", value: $viewModel.editor.untrackedConsumptions, in: 0...1000)
                    
                    TextField("Metadata (JSON string)", text: Binding(
                        get: { viewModel.editor.metadataString ?? "" },
                        set: { viewModel.editor.metadataString = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.caption)
                }
                
                Section("Settings") {
                    Toggle("Selectable", isOn: $viewModel.editor.selectable)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                }
                
                if viewModel.editor.parent != nil || viewModel.editor.parentRid != nil {
                    Section("Hierarchy") {
                        Button("Remove from Parent", role: .destructive) {
                            viewModel.editor.parent = nil
                            viewModel.editor.parentRid = nil
                        }
                    }
                }
                
            }
            .navigationTitle("Edit Cultural Item")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
}

// Reuse a generic selector if possible, or define a specific one
struct ParentCatalogueSelector: View {
    let catalogueItems: [DataMediaItem]
    @Binding var selectedParent: DataMediaItem?
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Button(action: {
                selectedParent = nil
                dismiss()
            }) {
                HStack {
                    Text("None")
                    Spacer()
                    if selectedParent == nil {
                        Image(systemName: "checkmark").foregroundColor(.blue)
                    }
                }
            }
            .foregroundColor(.primary)
            
            ForEach(catalogueItems) { item in
                Button(action: {
                    selectedParent = item
                    dismiss()
                }) {
                    HStack {
                        Text(item.name)
                        Spacer()
                        if selectedParent?.id == item.id {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle("Select Parent")
    }
}
