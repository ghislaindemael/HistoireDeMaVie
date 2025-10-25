//
//  ActivityDetailSheet.swift
//  HDMV
//
//  Created by Ghislain Demael on 01.09.2025.
//


import SwiftUI
import SwiftData

struct PersonDetailSheet: View {
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: PersonDetailSheetViewModel
    let person: Person
        
    init(person: Person, modelContext: ModelContext) {
        self.person = person
        _viewModel = StateObject(wrappedValue: PersonDetailSheetViewModel(
            model: person,
            modelContext: modelContext)
        )
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basics") {
                    TextField("Name", text: $viewModel.editor.name.orEmpty())
                    TextField("Family Name", text: $viewModel.editor.familyName.orEmpty())
                    TextField("Surname", text: $viewModel.editor.familyName.orEmpty())
                    DatePicker(
                        "Birthdate",
                        selection: $viewModel.editor.birthdate.orNow(),
                        displayedComponents: .date
                    )                }

                Section("Usage") {
                    Toggle("Cached", isOn: $viewModel.editor.cache)
                    Toggle("Archived", isOn: $viewModel.editor.archived)
                }
                
            }
            .navigationTitle("Edit Person")
            .navigationBarTitleDisplayMode(.inline)
            .standardSheetToolbar() {
                viewModel.onDone()
            }
        }
    }
    
}


