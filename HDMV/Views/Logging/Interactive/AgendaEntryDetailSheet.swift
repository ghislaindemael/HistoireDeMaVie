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

                Section("Daily Mood") {
                    Slider(value: $viewModel.editor.mood.toDouble(), in: 0...10, step: 1)
                    TextEditor(text: $viewModel.editor.moodComments)
                        .frame(height: 80)
                }
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
        }
    }
}

