//
//  NewInteractionSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import SwiftUI
import SwiftData

struct InteractionDetailSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: InteractionDetailSheetViewModel
        
    init(interaction: Interaction, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: InteractionDetailSheetViewModel(
            model: interaction,
            modelContext: modelContext
        ))
    }

    
    var body: some View {
        NavigationStack {
            Form {
                basicsSection
                detailsSection
            }
            .navigationTitle("Edit Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar(onDone: {
                viewModel.onDone()
                    dismiss()
                }
            )
        }
    }
    
    // MARK: - UI Sections
    
    private var basicsSection: some View {
        Section("Basics") {
            
            PersonSelectorView(selectedPerson: $viewModel.editor.person)
            FullTimePicker(label: "Start Time", selection: $viewModel.editor.time_start)
            FullTimePicker(label: "End Time", selection: $viewModel.editor.time_end)
            
        }
    }
    
    private var detailsSection: some View {
        Section("Details") {
            Toggle("In Person", isOn: $viewModel.editor.in_person)
            Toggle("Timed", isOn: $viewModel.editor.timed)
            
            Slider(
                value: $viewModel.editor.percentage.or100Double(),
                in: 0...100,
                step: 1
            )
            TextEditor(text: $viewModel.editor.details.orEmpty())
                .frame(height: 80)
            .lineLimit(3...)
        }
    }
}

