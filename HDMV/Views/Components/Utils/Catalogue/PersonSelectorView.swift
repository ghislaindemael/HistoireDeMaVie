//
//  PersonSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 25.09.2025.
//


import SwiftUI
import SwiftData

struct PersonSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedPersonId: Int?
    
    @Query(sort: [SortDescriptor(\Person.familyName), SortDescriptor(\Person.name)])
    private var people: [Person]
    
    private var person: Person? {
        return people.first(where: {$0.id == selectedPersonId})
    }
        
    var body: some View {
        Section {
            if selectedPersonId == nil || person == nil {
                HStack {
                    Text("Person")
                    Spacer()
                    if selectedPersonId == nil {
                        Label("Unset", systemImage: "person")
                            .foregroundStyle(.red)
                    } else if person == nil {
                        Label("Archived", systemImage: "person")
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Picker("Select Person", selection: $selectedPersonId) {
                Text("None").tag(nil as Int?)
                ForEach(people) { person in
                    Text(person.fullName).tag(person.id as Int?)
                }
            }
            .pickerStyle(.menu)
        }

    }
}
