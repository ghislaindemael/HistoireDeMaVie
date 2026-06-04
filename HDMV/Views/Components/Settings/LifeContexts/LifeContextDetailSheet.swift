//
//  LifeContextDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 04.06.2026.
//


import SwiftUI
import SwiftData

struct LifeContextDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: LifeContextDetailSheetViewModel
    
    @Query var contextTree: [LifeContext]

    init(lifeContext: LifeContext, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: LifeContextDetailSheetViewModel(
            model: lifeContext,
            modelContext: modelContext
        ))
        let predicate = #Predicate<LifeContext> { $0.parent == nil }
        _contextTree = Query(filter: predicate, sort: \.name)
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
                    
                    NavigationLink(destination: ParentLifeContextSelector(
                        contexts: contextTree,
                        selectedParent: $viewModel.editor.parent)
                    ) {
                        HStack {
                            Text("Parent Context")
                            Spacer()
                            if let parentName = viewModel.editor.parent?.name {
                                Text(parentName).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Dates") {
                    DatePicker(
                        "Start Date",
                        selection: Binding(
                            get: { viewModel.editor.timeStart ?? Date() },
                            set: { viewModel.editor.timeStart = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    
                    DatePicker(
                        "End Date",
                        selection: Binding(
                            get: { viewModel.editor.timeEnd ?? Date() },
                            set: { viewModel.editor.timeEnd = $0 }
                        ),
                        displayedComponents: [.date]
                    )
                    
                    Button("Clear Dates") {
                        viewModel.editor.timeStart = nil
                        viewModel.editor.timeEnd = nil
                    }
                    .foregroundColor(.red)
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
            .navigationTitle("Edit Context")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
}
