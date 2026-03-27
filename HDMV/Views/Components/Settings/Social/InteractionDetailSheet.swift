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
    
    init(interaction: Interaction, modelContext: ModelContext) {
        _viewModel = StateObject(wrappedValue: InteractionDetailSheetViewModel(
            model: interaction,
            modelContext: modelContext
        ))
    }
    
    private var groupNamesForEditor: String {
        let names = viewModel.editor.persons.map { $0.name }
        if names.isEmpty { return "None Selected" }
        if names.count == 1 { return names[0] }
        if names.count == 2 { return "\(names[0]) & \(names[1])" }
        return "\(names[0]), \(names[1]) & \(names.count - 2) others"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                basicsSection
                detailsSection
                
                if viewModel.editor.parentInstance != nil {
                    Section("Hierarchy") {
                        Button("Remove from Parent", role: .destructive) {
                            viewModel.editor.parentInstance = nil
                            viewModel.editor.parentInstanceRid = nil
                        }
                    }
                }
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
                    Text(groupNamesForEditor)
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
