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
    let isSmall: Bool
    
    // MARK: - Initializers
    
    init(vehicle: Vehicle?, vehicleRid: Int?, isSmall: Bool = false) {
        self.vehicle = vehicle
        self.vehicleRid = vehicleRid
        self.isSmall = isSmall
    }
    
    init(trip: Trip, isSmall: Bool = false) {
        self.vehicle = trip.vehicle
        self.vehicleRid = trip.vehicleRid
        self.isSmall = isSmall
    }
    
    // MARK: - Body
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        if let vehicle = vehicle {
            if isSmall {
                Text(String(vehicle.label.prefix(1)))
                    .fontWeight(.medium)
            } else {
                Text(vehicle.label)
                    .foregroundStyle(.primary)
            }
            
        } else if vehicleRid != nil {
            if isSmall {
                IconView(iconString: "questionmark.circle", size: 20, tint: .orange)
            } else {
                HStack(spacing: 4) {
                    IconView(iconString: "questionmark.circle", size: 20, tint: .orange)
                    Text("Uncached")
                        .bold()
                        .foregroundStyle(.orange)
                }
            }
            
        } else {
            if isSmall {
                IconView(iconString: "questionmark.circle", size: 20, tint: .red)
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
}
