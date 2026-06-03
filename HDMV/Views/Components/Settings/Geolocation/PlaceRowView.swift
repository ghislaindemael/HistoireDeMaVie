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
                Text(place.name)
                    .bold(place.name == "Unset")
                    .foregroundStyle(place.name == "Unset" ? .red : .primary)
                Spacer()
                if let onFav = onFavoriteToggle {
                    Button {
                        onFav(place)
                    } label: {
                        Image(systemName: place.isFavorite ? "star.fill" : "star")
                            .foregroundColor(place.isFavorite ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
                CacheToggleButton(model: place) { p in
                    onCacheToggle(p)
                }
                SyncStatusIndicator(status: place.syncStatus)
            }
        }
    }
}
