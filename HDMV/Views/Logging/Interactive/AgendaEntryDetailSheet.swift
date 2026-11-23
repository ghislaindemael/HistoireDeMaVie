//
//  AgendaDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.10.2025.
//


import SwiftUI
import SwiftData

struct AgendaEntryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AgendaEntryDetailSheetViewModel
    @State private var isShowingOptionSelector: Bool = false
    
    @Query(filter: #Predicate<DataLogOption> { $0.archived == false })
    private var allOptions: [DataLogOption]
    
    private var globalAgendaOptions: [DataLogOption] {
        allOptions.filter { $0.config?.isForAgenda == true }
    }

    init(entry: AgendaEntry, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: AgendaEntryDetailSheetViewModel(
            model: entry,
            modelContext: modelContext
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Day Summary") {
                    TextEditor(text: $viewModel.editor.daySummary)
                        .frame(minHeight: 100)
                }
                
                Section("Context") {
                    LifeContextSelectorLink(selectedContexts: $viewModel.editor.contextRids)
                }

                DynamicOptionsSection(
                    mappings: [],
                    globalOptions: globalAgendaOptions,
                    decodedLogDetails: $viewModel.editor.log_details,
                    isShowingOptionSelector: $isShowingOptionSelector,
                    groupByCategory: true
                )
            }
            .navigationTitle("Edit Agenda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.onDone()
                        dismiss()
                    }
                }
            }
            .dynamicOptionSelectorSheet(
                isPresented: $isShowingOptionSelector,
                mappings: [],
                globalOptions: globalAgendaOptions,
                decodedLogDetails: $viewModel.editor.log_details
            )
        }
    }
}

