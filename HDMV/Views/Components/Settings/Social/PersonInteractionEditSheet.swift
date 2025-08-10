//
//  NewInteractionSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import SwiftUI

struct PersonInteractionEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject var viewModel: PeopleInteractionsPageViewModel
    
    @Bindable var interaction: PersonInteraction
    
    @State private var showEndTime: Bool

    init(
        interaction: PersonInteraction,
        viewModel: PeopleInteractionsPageViewModel
    ) {
        self.interaction = interaction
        self.viewModel = viewModel
        _showEndTime = State(initialValue: interaction.time_end != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                basicsSection
                detailsSection
            }
            .onChange(of: showEndTime) {
                if !showEndTime {
                    interaction.time_end = nil
                }
            }
            .navigationTitle("Edit Interaction")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar(isFormValid: true) {
                interaction.syncStatus = .local
                if !showEndTime {
                    interaction.time_end = nil
                }
                try? modelContext.save()
                dismiss()
            }
        }
    }
    
    // MARK: - UI Sections
    
    private var basicsSection: some View {
        Section("Basics") {
            Picker("Person", selection: $interaction.person_id) {
                Text("Please select a person").tag(0)
                ForEach(viewModel.people, id: \.id) { person in
                    Text(person.fullName).tag(person.id)
                }
            }
            FullTimePicker(label: "Start Time", selection: $interaction.time_start)
            Toggle("End Time?", isOn: $showEndTime)
            if showEndTime {
                FullTimePicker(label: "End Time", selection: Binding(
                    get: { interaction.time_end ?? Date() },
                    set: { interaction.time_end = $0 }
                ))
            }
        }
    }
    
    private var detailsSection: some View {
        Section("Details") {
            Toggle("In Person", isOn: $interaction.in_person)
            
            Slider(value: Binding(
                get: { Double(interaction.percentage) },
                set: { interaction.percentage = Int($0) }
            ), in: 0...100, step: 1)
            TextEditor(text: Binding(
                get: { interaction.details ?? "" },
                set: { interaction.details = $0.isEmpty ? nil : $0 }
            ))
            .lineLimit(3...)
        }
    }
}

