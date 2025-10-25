//
//  PlaceRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct PlaceRowView: View {
    
    let place: Place
    
    var body: some View {
        VStack{
            HStack {
                Text(place.name)
                    .bold(place.name == "Unset")
                    .foregroundStyle(place.name == "Unset" ? .red : .primary)
                Spacer()
                if !place.cache {
                    IconView(iconString: "iphone.gen1.slash", size: 20, tint: .red)
                }
                SyncStatusIndicator(status: place.syncStatus)
            }
        }
    }
}
