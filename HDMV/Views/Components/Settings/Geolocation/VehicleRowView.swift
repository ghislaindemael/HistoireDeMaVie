//
//  VehicleRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 20.06.2025.
//


import SwiftUI

struct VehicleRowView: View {
    
    let vehicle: Vehicle
    let onCacheToggle: (Vehicle) -> Void
    
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
                CacheToggleButton(model: vehicle) { v in
                    onCacheToggle(v)
                }
                SyncStatusIndicator(status: vehicle.syncStatus)
            }
        }
    }
}
