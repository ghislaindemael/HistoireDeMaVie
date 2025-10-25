//
//  VehicleRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct VehicleRowView: View {
    
    let vehicle: Vehicle
    
    var body: some View {
        VStack{
            HStack {
                if vehicle.type != .unset {
                    Text(vehicle.label)
                } else {
                    Text("Unset")
                        .bold()
                        .foregroundStyle(.red)
                }
                Spacer()
                if !vehicle.cache {
                    IconView(iconString: "iphone.gen1.slash", size: 20, tint: .red)
                }
                SyncStatusIndicator(status: vehicle.syncStatus)
            }
        }
    }
}
