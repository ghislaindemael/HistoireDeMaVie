//
//  TransactionTypeDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 14.03.2026.
//


import SwiftUI
import SwiftData

struct TransactionTypeDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: TransactionTypesDetailSheetViewModel
    
    @Query var typesTree: [TransactionType]

    init(type: TransactionType, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: TransactionTypesDetailSheetViewModel(
            model: type,
            modelContext: modelContext
        ))
        let predicate = #Predicate<TransactionType> { $0.parent == nil }
        _typesTree = Query(filter: predicate, sort: \.name)
    }
    
        
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name)
                    TextField("Slug", text: $viewModel.editor.slug)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    HStack {
                        TextField("Icon", text: $viewModel.editor.icon.orEmpty())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Spacer()
                        IconView(iconString: viewModel.editor.icon ?? "")
                    }
                    NavigationLink(destination: ParentTransactionTypeSelector(
                        types: typesTree,
                        selectedParent: $viewModel.editor.parent)
                    ) {
                        HStack {
                            Text("Parent Activity")
                            Spacer()
                        }
                    }
                }
                
                Section("Usage") {
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
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
            .navigationTitle("Edit TransactionType")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
    
    
    
}


