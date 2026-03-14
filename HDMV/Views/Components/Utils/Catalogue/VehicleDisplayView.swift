//
//  VehicleDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 23.09.2025.
//

import SwiftUI
import SwiftData

struct VehicleDisplayView: View {
    
    let vehicle: Vehicle?
    let vehicleRid: Int?
    
    // MARK: - Initializers
    
    init(vehicle: Vehicle?, vehicleRid: Int?) {
        self.vehicle = vehicle
        self.vehicleRid = vehicleRid
    }
    
    init(trip: Trip) {
        self.vehicle = trip.vehicle
        self.vehicleRid = trip.vehicleRid
    }
    
    // MARK: - Body
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        if let vehicle = vehicle {
            Text(vehicle.label)
                .foregroundStyle(.primary)
        } else if vehicleRid != nil {
            HStack(spacing: 4) {
                IconView(iconString: "questionmark.circle", size: 20, tint: .orange)
                Text("Uncached")
                    .bold()
                    .foregroundStyle(.orange)
            }
            
        } else {
            HStack(spacing: 4) {
                IconView(iconString: "questionmark.circle", size: 20, tint: .red)
                Text("Unset")
                    .bold()
                    .foregroundStyle(.red)
            }
        }
    }
}
