//
//  NewInteractionSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.06.2025.
//

import SwiftUI

struct EditInteractionSheet: View {
    let people: [Person]
    var onSave: (PersonInteraction) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State var interaction: PersonInteraction
    @State private var showEndTime: Bool
    

    init(
        people: [Person],
        interaction: PersonInteraction,
        onSave: @escaping (PersonInteraction) -> Void
    ) {
        self.people = people
        self.onSave = onSave
        
        _interaction = State(initialValue: interaction)
        _showEndTime = State(initialValue: interaction.time_end != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basics"){
                    Picker("Person", selection: $interaction.person_id) {
                        Text("Please select a person").tag(0)
                        ForEach(people, id: \.id) { person in
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
                Section("Logistics"){
                    Toggle("In Person", isOn: $interaction.in_person)
                    
                    Slider(value: Binding(
                        get: { Double(interaction.percentage) },
                        set: { interaction.percentage = Int($0) }
                    ), in: 0...100, step: 1)
                    
                    
                    TextField("Details", text: Binding(
                        get: { interaction.details ?? "" },
                        set: { interaction.details = $0.isEmpty ? nil : $0 }
                    ))
                }

            }
            .onChange(of: showEndTime) {
                if !showEndTime {
                    interaction.time_end = nil
                }
            }
            .navigationTitle((interaction.id < 0) ? "New Interaction" : "Edit Interaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(interaction)
                        dismiss()
                    }

                }
            }
        }
    }
}

