//
//  LifeEventDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.10.2025.
//

import SwiftUI
import SwiftData

struct LifeEventDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject var viewModel: LifeEventDetailSheetViewModel
    
    @Query(filter: #Predicate<DataLogOptionMapping> { $0.isForLifeEvent && $0.archived == false }) 
    private var optionMappings: [DataLogOptionMapping]
    
    let lifeEvent: LifeEvent
    
    init(
        lifeEvent: LifeEvent,
        modelContext: ModelContext
    ) {
        self.lifeEvent = lifeEvent
        _viewModel = StateObject(wrappedValue: LifeEventDetailSheetViewModel(
            model: lifeEvent,
            modelContext: modelContext
        ))
    }
    
    var body: some View {
        NavigationView {
            Form {
                
                TimeSection(editor: $viewModel.editor)
                detailsSection
                
                HierarchySectionView(
                    model: lifeEvent,
                    hasParent: !viewModel.editor.hasNoParent(),
                    onRemoveFromParent: {
                        viewModel.editor.clearParents()
                    }
                )

            }
            .navigationTitle("Edit Life Event")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
                dismiss()
            }
        }
    }
    
    @Query(sort: \LifeEventType.name) private var lifeEventTypes: [LifeEventType]
    
    // MARK: - UI Sections
    
    private var detailsSection: some View {
        Group {
            DynamicOptionsSection(
                mappings: optionMappings,
                decodedLogDetails: $viewModel.editor.log_details
            )
            
            Section("Details") {
                NavigationLink(destination: LifeEventTypeSelectorView(selectedType: $viewModel.editor.type)) {
                    HStack {
                        Text("Type")
                        Spacer()
                        if let type = viewModel.editor.type {
                            Text(type.label)
                                .foregroundColor(.primary)
                        } else {
                            Text("Select Type")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            
            NavigationLink {
                MultiLifeContextSelector(selectedContexts: $viewModel.editor.contextRids)
            } label: {
                HStack {
                    Text("Contexts")
                    Spacer()
                    Text("\(viewModel.editor.contextRids.count) selected")
                        .foregroundStyle(viewModel.editor.contextRids.isEmpty ? .secondary : .primary)
                }
            }
            TextEditor(text: Binding(
                get: { viewModel.editor.details ?? "" },
                set: { viewModel.editor.details = $0.isEmpty ? nil : $0 }
            ))
            .lineLimit(3...)
            }
        }
    }
    
}


