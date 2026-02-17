//
//  CityRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct CityRowView: View {
    
    let city: City
    let onToggle: (City) -> Void
    
    var body: some View {
        VStack{
            HStack {
                Label("\(city.name)", systemImage: "")
                Spacer()
                CacheToggleButton(model: city, onToggle: onToggle)
                SyncStatusIndicator(status: city.syncStatus)
            }
        }
    }
}
