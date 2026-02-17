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

    
    var body: some View {
        VStack{
            HStack {
                Text(place.name)
                    .bold(place.name == "Unset")
                    .foregroundStyle(place.name == "Unset" ? .red : .primary)
                Spacer()
                CacheToggleButton(model: place) { p in
                    onCacheToggle(p)
                }
                SyncStatusIndicator(status: place.syncStatus)
            }
        }
    }
}
