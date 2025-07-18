//
//  TripRowView.swift
//  HDMV
//
//  Created by Ghislain Demael on 22.06.2025.
//


import SwiftUI
import SwiftData

struct TripRowView: View {
    
    let displayTrip: TripDisplayModel
    let vehicleTypes: [VehicleType]
    let vehicles: [Vehicle]
    let places: [Place]
    
    private var vehicle: Vehicle? {
        vehicles.first { $0.id == displayTrip.vehicle_id }
    }
    
    private var vehicleType: VehicleType? {
        guard let vehicle = vehicle else { return nil }
        return vehicleTypes.first { $0.id == vehicle.type }
    }
    
    private var startPlace: Place? {
        places.first { $0.id == displayTrip.place_start_id }
    }
    
    private var endPlace: Place? {
        places.first { $0.id == displayTrip.place_end_id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(vehicleType?.icon ?? "")
                    .foregroundStyle(.secondary)
                Text(vehicle?.name ?? "No Vehicle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if displayTrip.isLocal {
                    Image(systemName: "icloud.and.arrow.up.fill")
                        .foregroundStyle(.orange)
                }
            }
            HStack {
                Text(displayTrip.time_start, style: .time)
                    .font(.headline)
                
                Image(systemName: "arrow.right")
                
                if let endTime = displayTrip.time_end {
                    Text(endTime, style: .time)
                        .font(.headline)
                } else {
                    Text("In Progress")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(startPlace?.localName ?? "Unknown Start")
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                        .padding(.leading, 2)
                    
                    Text(endPlace?.localName ?? (displayTrip.time_end == nil ? "Not set" : "Unknown End"))
                        
                }
            }
            .padding(.leading, 4)
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
