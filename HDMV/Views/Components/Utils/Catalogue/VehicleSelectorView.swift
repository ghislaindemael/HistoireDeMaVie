//
//  VehicleSelectorView.swift
//  HDMV
//
//  Created by Ghislain Demael on 24.09.2025.
//


import SwiftUI
import SwiftData

struct VehicleSelectorView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var selectedVehicleId: Int?
    @Binding var amDriver: Bool
    
    @Query(sort: [SortDescriptor(\Vehicle.name)]) 
    private var vehicles: [Vehicle]
    
    private var isCarSelected: Bool {
        guard let vehicleId = selectedVehicleId,
              let vehicle = vehicles.first(where: { $0.id == vehicleId }) 
        else { return false }
        return vehicle.type == 1
    }
    
    var body: some View {
        VStack {
            Picker("Vehicle", selection: $selectedVehicleId) {
                Text("None").tag(nil as Int?)
                ForEach(vehicles) { vehicle in
                    Text(vehicle.name).tag(vehicle.id as Int?)
                }
            }
            if isCarSelected {
                Toggle("Am I the driver", isOn: $amDriver)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
