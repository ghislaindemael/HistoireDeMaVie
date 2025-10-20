//
//  PersonDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 23.09.2025.
//


import SwiftUI
import SwiftData

struct PersonDisplayView: View {
    
    let personRid: Int?
    let person: Person?
    
    init(personRid: Int?, person: Person?){
        self.personRid = personRid
        self.person = person
    }
    
    init(interaction: PersonInteraction) {
        self.init(personRid: interaction.personRid, person: interaction.person)
    }
    
    private var iconColor: Color {
        if person != nil {
            return .primary
        } else if personRid != nil {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "person")
                .foregroundColor(iconColor)
            
            if let person = person {
                Text(person.fullName)
            } else if let id = personRid {
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
