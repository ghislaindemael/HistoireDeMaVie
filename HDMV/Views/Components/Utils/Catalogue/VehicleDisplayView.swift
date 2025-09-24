//
//  VehicleDisplayView.swift
//  HDMV
//
//  Created by Ghislain Demael on 23.09.2025.
//
import SwiftUI
import SwiftData

struct VehicleDisplayView: View {
    let isSmall: Bool
    
    @Query private var vehicles: [Vehicle]
    
    let vehicleId: Int?
    
    init(vehicleId: Int?, isSmall: Bool = false) {
        self.vehicleId = vehicleId
        self.isSmall = isSmall
        
        if let id = vehicleId {
            _vehicles = Query(filter: #Predicate { $0.id == id })
        } else {
            _vehicles = Query(filter: #Predicate { _ in false })
        }
    }
    
    private var vehicle: Vehicle? {
        vehicles.first
    }
        
    var body: some View {
        if isSmall {
            if vehicleId == nil {
                IconView(iconString: "questionmark.circle", size: 20, tint: .red)
            } else if vehicle == nil {
                IconView(iconString: "questionmark.circle", size: 20, tint: .orange)
            } else if let vehicle = vehicle {
                Text(String(vehicle.label.prefix(1)))
                    .fontWeight(.medium)
            } else {
                IconView(iconString: "questionmark.circle", size: 20, tint: .gray)
            }
        } else {
            HStack(spacing: 4) {
                if vehicleId == nil {
                    IconView(iconString: "questionmark.circle", size: 20, tint: .red)
                    Text("Unset")
                        .bold()
                } else if vehicle == nil {
                    IconView(iconString: "questionmark.circle", size: 20, tint: .orange)
                    Text("Uncached")
                        .bold()
                } else if let vehicle = vehicle {
                    Text(vehicle.label)
                } else {
                    Text("?")
                        .bold()
                }
            }
        }
    }

}
