//
//  PersonRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct PersonRowView: View {
    @Bindable var person: Person
    let onCacheToggle: (Person) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("\(person.fullName)", systemImage: "")
                Spacer()
                
                CacheToggleButton(model: person) { p in
                    onCacheToggle(p)
                }
                
                SyncStatusIndicator(status: person.syncStatus)
            }
        }
    }
}
