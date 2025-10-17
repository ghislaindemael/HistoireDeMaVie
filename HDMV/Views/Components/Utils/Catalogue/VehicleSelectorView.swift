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
    
    @Binding var selectedVehicle: Vehicle?
    @Binding var amDriver: Bool
    
    @Query(FetchDescriptor<Vehicle>(
        predicate: #Predicate { $0.cache == true && $0.name != nil },
            sortBy: [SortDescriptor(\.name)]))
    private var vehicles: [Vehicle]
    
    private var isCarSelected: Bool {
        guard let vehicle = selectedVehicle else { return false }
        return vehicle.type == .car
    }
    
    var body: some View {
        VStack {
            Picker("Vehicle", selection: $selectedVehicle) {
                Text("None").tag(nil as Vehicle?)
                ForEach(vehicles) { vehicle in
                    Text(vehicle.name!).tag(vehicle as Vehicle?)
                }
            }
            if isCarSelected {
                Toggle("Am I the driver", isOn: $amDriver)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
