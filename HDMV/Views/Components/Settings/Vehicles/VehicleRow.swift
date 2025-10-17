//
//  VehicleRow.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.06.2025.
//


//
//  VehicleRow.swift
//  HDMV
//
//  Created by Ghislain Demael on 19.06.2025.
//

import SwiftUI

struct VehicleRow: View {
    @Bindable var vehicle: Vehicle
    let onCacheToggle: () -> Void
    
    var body: some View {
        HStack() {
            Text(vehicle.label)
                .font(.headline)
            
            Spacer()
            
            Toggle("Cache", isOn: $vehicle.cache)
                .labelsHidden()
                .onChange(of: vehicle.cache) {
                    onCacheToggle()
                }
            .labelsHidden()
        }
    }
}

#Preview {
    let vehicle = Vehicle(rid: 1, name: "Test", type: .car)
    VehicleRow(vehicle: vehicle, onCacheToggle: {})
}
