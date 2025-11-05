//
//  CityRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct CityRowView: View {
    
    let city: City
    
    var body: some View {
        VStack{
            HStack {
                NamedStringDisplayView(name: "Name", value: city.name)
                Spacer()
                if !city.cache {
                    IconView(iconString: "iphone.gen1.slash", size: 20, tint: .red)
                }
                SyncStatusIndicator(status: city.syncStatus)
            }
        }
    }
}
