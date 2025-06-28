//
//  NewPersonSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 28.06.2025.
//

import SwiftUI

struct NewPersonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PeoplePageViewModel
    
    @State private var newPerson: NewPersonPayload = NewPersonPayload()
    @State private var name: String = ""
    @State private var isSaving = false
    
    private var isFormValid: Bool { !name.isEmpty }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Person Details") {
                    TextField("Name", text: $newPerson.name)
                    TextField("Family name", text: $newPerson.familyName)
                    TextField("Surname", text: Binding(
                        get: { newPerson.surname ?? "" },
                        set: { newPerson.surname = $0.isEmpty ? nil : $0 }
                    ))
                    Toggle("Set Birthdate", isOn: Binding(
                        get: { newPerson.birthdate != nil },
                        set: { hasDate in
                            if hasDate {
                                newPerson.birthdate = newPerson.birthdate ?? Date()
                            } else {
                                newPerson.birthdate = nil
                            }
                        }
                    ))
                    
                    if let unwrappedDate = newPerson.birthdate {
                        DatePicker("Birthdate", selection: Binding(
                            get: { unwrappedDate },
                            set: { newPerson.birthdate = $0 }
                        ), displayedComponents: [.date])
                    }
                }
                
                
                if isSaving {
                    Section { ProgressView() }
                }
            }
            .navigationTitle("New Place")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task {
                            isSaving = true
                            do {
                                try await viewModel.createPerson(newPerson: newPerson)
                                dismiss()
                            } catch {
                                print("Failed to create person: \(error)")
                            }
                        }
                    }
                    .disabled(!isFormValid || isSaving)
                }
            }
        }
    }
}
