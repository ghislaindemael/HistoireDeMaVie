//
//  InteractionDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import SwiftUI
import SwiftData

struct InteractionDetailSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: InteractionDetailSheetViewModel
    
    let interaction: Interaction
    
    init(interaction: Interaction, modelContext: ModelContext) {
        self.interaction = interaction
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
                
                HierarchySectionView(
                    model: interaction,
                    hasParent: !viewModel.editor.hasNoParent(),
                    onRemoveFromParent: {
                        viewModel.editor.clearParents()
                    }
                )
            }
            .navigationTitle("Edit Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar(onDone: {
                viewModel.onDone()
                dismiss()
            })
        }
    }
    
    // MARK: - UI Sections
    
    private var basicsSection: some View {
        Section("Basics") {
            
            NavigationLink {
                MultiPersonSelectorView(selectedPersons: $viewModel.editor.persons)
            } label: {
                HStack {
                    Text("People")
                    Spacer()
                    Text(viewModel.editor.persons.formattedNames())
                        .foregroundStyle(viewModel.editor.persons.isEmpty ? .red : .secondary)
                        .lineLimit(1)
                }
            }
            
            FullTimePicker(label: "Start Time", selection: $viewModel.editor.time_start)
            FullTimePicker(label: "End Time", selection: $viewModel.editor.time_end, minimumDate: viewModel.editor.time_start)
            
        }
    }
    
    private var detailsSection: some View {
        Section("Details") {
            Toggle("In Person", isOn: $viewModel.editor.in_person)
            Toggle("Timed", isOn: $viewModel.editor.timed)
            
            Slider(
                value: Binding(
                    get: { Double(viewModel.editor.percentage ?? 100) },
                    set: { viewModel.editor.percentage = Int($0) }
                ),
                in: 0...100,
                step: 1
            )
            TextEditor(text: Binding(
                get: { viewModel.editor.details ?? "" },
                set: { viewModel.editor.details = $0.isEmpty ? nil : $0 }
            ))
            .frame(height: 80)
            .lineLimit(3...)
        }
    }
}
