//
//  PersonDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 23.09.2025.
//


import SwiftUI
import SwiftData

struct PersonDisplayView: View {
    @Query private var people: [Person]
    
    private let personId: Int?
    
    private var person: Person? {
        people.first
    }

    init(personId: Int?) {
        self.personId = personId
        
        if let id = personId, id > 0 {
            _people = Query(filter: #Predicate { $0.id == id })
        } else {
            _people = Query(filter: #Predicate { _ in false })
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "person")
                .foregroundColor(
                    person != nil ? .primary :
                    (personId != nil && personId! > 0 ? .orange : .red)
                )

            if let person = person {
                Text(person.fullName)
            } else if let id = personId, id > 0 {
                Text("\(id): Uncached Person")
                    .italic()
                    .foregroundColor(.orange)
            } else {
                Text("Person unset")
                    .bold()
                    .foregroundColor(.red)
            }
        }
    }
}
