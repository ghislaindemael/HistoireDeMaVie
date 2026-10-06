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
        HStack {
            UnsettableTextView(
                text: person.isValid() ? person.fullName : "unset",
                font: .body.bold(),
                isItalicized: person.archived
            )
            Spacer()
            CatalogueRowControlsView(model: person) { p in
                onCacheToggle(p)
            }
        }
    }
}
