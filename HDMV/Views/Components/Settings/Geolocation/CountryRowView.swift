//
//  CountryRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 29.07.2025.
//

import SwiftUI

struct CountryRowView: View {
    
    let country: Country
    var onToggle: ((Country) -> Void)? = nil
    
    var body: some View {
        HStack {
            UnsettableTextView(
                text: country.name,
                font: .title3.bold(),
                isItalicized: country.archived
            )
            Spacer()
            CatalogueRowControlsView(model: country, onToggle: onToggle)
        }
    }
        
}
