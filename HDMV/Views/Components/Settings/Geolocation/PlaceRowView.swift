//
//  PlaceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct PlaceRowView: View {
    @Bindable var place: Place
    
    let onCacheToggle: () -> Void
    
    var body: some View {
        HStack {
            Text(place.name)
            Spacer()
            Toggle("Cache", isOn: $place.cache)
                .labelsHidden()
                .onChange(of: place.cache) { oldValue, newValue in
                    onCacheToggle()
                }
        }
    }
}
