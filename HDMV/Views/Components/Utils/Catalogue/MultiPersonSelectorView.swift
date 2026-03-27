//
//  MultiPersonSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 27.03.2026.
//

import SwiftUI
import SwiftData

struct MultiPersonSelectorView: View {
    @Query(FetchDescriptor<Person>(
        predicate: #Predicate { $0.cache == true },
        sortBy: [SortDescriptor(\.familyName), SortDescriptor(\.name)]))
    private var allPersons: [Person]
    
    @Binding var selectedPersons: [Person]
    
    var body: some View {
        List {
            if allPersons.isEmpty {
                ContentUnavailableView("No People", systemImage: "person.slash", description: Text("Add cached people in the Contacts tab first."))
            } else {
                ForEach(allPersons) { person in
                    Button {
                        toggleSelection(for: person)
                    } label: {
                        HStack {
                            Text(person.fullName)
                                .foregroundStyle(.primary)
                            Spacer()
                            
                            if selectedPersons.contains(person) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select People")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleSelection(for person: Person) {
        if let index = selectedPersons.firstIndex(of: person) {
            selectedPersons.remove(at: index)
        } else {
            selectedPersons.append(person)
        }
    }
}
