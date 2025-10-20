//
//  PersonDetailSheetViewModel.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.10.2025.
//


import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@MainActor
class PersonDetailSheetViewModel: ObservableObject {
    @Published var editor: PersonEditor

    private var person: Person
    private let modelContext: ModelContext
    
    init(person: Person, modelContext: ModelContext) {
        self.person = person
        self.editor = PersonEditor(from: person)
        self.modelContext = modelContext
    }

    // MARK: - User Actions

    func onDone() {
        editor.apply(to: person)
        person.markAsModified()
        
        do {
            try modelContext.save()
            print("✅ Person \(person.id) saved to context.")
        } catch {
            print("❌ Failed to save place to context: \(error)")
        }
    }
}
