//
//  PersonRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct PersonRowView: View {
    
    let person: Person
    
    var body: some View {
        VStack{
            HStack {
                NamedStringDisplayView(name: "Slug", value: person.slug)
                
                Spacer()
                if !person.cache {
                    IconView(iconString: "iphone.gen1.slash", size: 20, tint: .red)
                }
                SyncStatusIndicator(status: person.syncStatus)
            }
            NamedStringDisplayView(name: "Name", value: person.name)
            NamedStringDisplayView(name: "Family Name", value: person.familyName)
        }
    }
}
