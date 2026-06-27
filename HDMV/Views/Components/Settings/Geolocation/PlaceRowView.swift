//
//  PlaceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct PlaceRowView: View {
    
    let place: Place
    let onCacheToggle: (Place) -> Void
    var onFavoriteToggle: ((Place) -> Void)? = nil

    
    var body: some View {
        VStack{
            HStack {
                UnsettableTextView(
                    text: place.name,
                    font: .body,
                    isItalicized: place.archived
                )
                Spacer()
                CatalogueRowControlsView(
                    model: place,
                    isFavorite: place.isFavorite,
                    onFavoriteToggle: onFavoriteToggle,
                    onToggle: onCacheToggle
                )
            }
        }
    }
}
