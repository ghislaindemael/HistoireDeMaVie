//
//  CityRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct CityRowView: View {
    
    let city: City
    var onToggle: ((City) -> Void)? = nil
    
    var body: some View {
        HStack {
            UnsettableTextView(
                text: city.name,
                font: .body.bold(),
                isItalicized: city.archived
            )
            Spacer()
            CatalogueRowControlsView(model: city, onToggle: onToggle)
        }
    }
}
