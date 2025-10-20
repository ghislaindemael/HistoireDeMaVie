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
    
    @Binding var selectedPerson: Person?
    
    @Query(FetchDescriptor<Person>(
        predicate: #Predicate { $0.cache == true },
        sortBy: [SortDescriptor(\.familyName), SortDescriptor(\.name)]))
    private var people: [Person]
    
        
    var body: some View {
        Picker("Select Person", selection: $selectedPerson) {
            Text("None").tag(nil as Person?)
            ForEach(people) { person in
                Text(person.fullName).tag(person as Person)
            }
        }
        .pickerStyle(.menu)
    }
}
